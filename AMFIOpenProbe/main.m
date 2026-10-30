#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <CoreFoundation/CoreFoundation.h>
#import <dlfcn.h>
#import <string.h>
#import <mach/mach.h>

typedef uint32_t probe_io_object_t;
typedef uint32_t probe_io_service_t;
typedef uint32_t probe_io_connect_t;
typedef CFMutableDictionaryRef (*ProbeMatching)(const char *);
typedef probe_io_service_t (*ProbeGetService)(mach_port_t, CFDictionaryRef);
typedef kern_return_t (*ProbeOpen)(probe_io_service_t, mach_port_t, uint32_t, probe_io_connect_t *);
typedef kern_return_t (*ProbeClose)(probe_io_connect_t);
typedef kern_return_t (*ProbeRelease)(probe_io_object_t);
typedef kern_return_t (*ProbeCallStruct)(probe_io_connect_t, uint32_t, const void *, size_t, void *, size_t *);

static NSString *RunReachabilityProbe(void) {
    NSMutableArray<NSString *> *out = [NSMutableArray array];
    UIDevice *device = UIDevice.currentDevice;
    [out addObject:@"IOKit Reachability Probe v2"];
    [out addObject:[NSString stringWithFormat:@"Device: %@ | iPadOS: %@", device.model, device.systemVersion]];
    [out addObject:@"Method: exact-class matching, type-0 open, immediate close"];
    [out addObject:@"No external methods; no entitlement manipulation; no system writes."];
    [out addObject:@"---"];

    void *handle = dlopen("/System/Library/Frameworks/IOKit.framework/IOKit", RTLD_NOW | RTLD_LOCAL);
    if (!handle) {
        [out addObject:[NSString stringWithFormat:@"IOKit unavailable: %s", dlerror() ?: "unknown"]];
        return [out componentsJoinedByString:@"\n"];
    }
    ProbeMatching matching = (ProbeMatching)dlsym(handle, "IOServiceMatching");
    ProbeGetService get = (ProbeGetService)dlsym(handle, "IOServiceGetMatchingService");
    ProbeOpen openClient = (ProbeOpen)dlsym(handle, "IOServiceOpen");
    ProbeClose closeClient = (ProbeClose)dlsym(handle, "IOServiceClose");
    ProbeRelease release = (ProbeRelease)dlsym(handle, "IOObjectRelease");
    if (!matching || !get || !openClient || !closeClient || !release) {
        [out addObject:@"Missing required IOKit symbol; stopping."];
        dlclose(handle);
        return [out componentsJoinedByString:@"\n"];
    }

    // Deliberately bounded, fixed list. Only connection establishment is tested.
    const char *classes[] = {
        "AppleMobileFileIntegrity",
        "IOSurfaceRoot",
        "IOHIDSystem",
        "IOMobileFramebuffer",
        "IOAudioEngine",
        "IODTNVRAM",
        "IOUSBHostDevice"
    };
    const NSUInteger count = sizeof(classes) / sizeof(classes[0]);
    NSUInteger found = 0, opened = 0, refused = 0;
    for (NSUInteger i = 0; i < count; i++) {
        const char *name = classes[i];
        [out addObject:[NSString stringWithFormat:@"[%lu/%lu] %s", (unsigned long)(i + 1), (unsigned long)count, name]];
        CFMutableDictionaryRef query = matching(name);
        if (!query) {
            [out addObject:@"  MATCH: failed to create dictionary"];
            continue;
        }
        // IOServiceGetMatchingService consumes the matching dictionary.
        probe_io_service_t service = get(MACH_PORT_NULL, query);
        if (service == MACH_PORT_NULL) {
            [out addObject:@"  MATCH: no service visible"];
            continue;
        }
        found++;
        [out addObject:@"  MATCH: service visible"];
        probe_io_connect_t connection = MACH_PORT_NULL;
        kern_return_t result = openClient(service, mach_task_self(), 0, &connection);
        [out addObject:[NSString stringWithFormat:@"  OPEN(type=0): 0x%08x (%d)", (uint32_t)result, result]];
        if (result == KERN_SUCCESS && connection != MACH_PORT_NULL) {
            opened++;
            kern_return_t closed = closeClient(connection);
            [out addObject:[NSString stringWithFormat:@"  CLOSE: 0x%08x (%d)", (uint32_t)closed, closed]];
        } else {
            refused++;
            if (connection != MACH_PORT_NULL) {
                // Defensive cleanup if the OS returned an unexpected connection.
                kern_return_t closed = closeClient(connection);
                [out addObject:[NSString stringWithFormat:@"  CLOSE unexpected handle: 0x%08x", (uint32_t)closed]];
            }
        }
        release(service);
    }
    dlclose(handle);
    [out addObject:@"---"];
    [out addObject:[NSString stringWithFormat:@"Summary: %lu/%lu visible; %lu open success; %lu open failure",
                   (unsigned long)found, (unsigned long)count,
                   (unsigned long)opened, (unsigned long)refused]];
    [out addObject:@"Connection success is reachability evidence, NOT an exploit."];
    [out addObject:@"End of report."];
    return [out componentsJoinedByString:@"\n"];
}


/*
 * Selector 13 was audited in the exact iPadOS 26.4.2 IOSurface binary:
 * - Dispatch: 0 scalar inputs, 0 structure inputs, 40-byte structure output.
 * - Handler: 0xfffffff009c39cf0.
 * - It only reads fields and writes the output, with no state mutations.
 * - Five output bytes (33, 36..39) are not explicitly written by the handler.
 * This test checks what an ordinary caller receives; no exploitation or fuzzing.
 */
static NSString *RunPaddingProbe(void) {
    NSMutableArray<NSString *> *out = [NSMutableArray array];
    [out addObject:@"IOSurface selector-13 padding verification"];
    [out addObject:@"One audited read-only selector, exactly 3 calls, zero input."];
    [out addObject:@"Raw response contents are not logged; only five padding bytes."];
    void *handle = dlopen("/System/Library/Frameworks/IOKit.framework/IOKit", RTLD_NOW | RTLD_LOCAL);
    if (!handle) {
        [out addObject:[NSString stringWithFormat:@"IOKit dlopen failed: %s", dlerror() ?: "unknown"]];
        return [out componentsJoinedByString:@"\n"];
    }
    ProbeMatching matching = (ProbeMatching)dlsym(handle, "IOServiceMatching");
    ProbeGetService get = (ProbeGetService)dlsym(handle, "IOServiceGetMatchingService");
    ProbeOpen openClient = (ProbeOpen)dlsym(handle, "IOServiceOpen");
    ProbeClose closeClient = (ProbeClose)dlsym(handle, "IOServiceClose");
    ProbeRelease release = (ProbeRelease)dlsym(handle, "IOObjectRelease");
    ProbeCallStruct callStruct = (ProbeCallStruct)dlsym(handle, "IOConnectCallStructMethod");
    if (!matching || !get || !openClient || !closeClient || !release || !callStruct) {
        [out addObject:@"Required IOKit symbols unavailable."];
        dlclose(handle);
        return [out componentsJoinedByString:@"\n"];
    }
    CFMutableDictionaryRef query = matching("IOSurfaceRoot");
    if (!query) {
        [out addObject:@"IOSurface matching dictionary unavailable."];
        dlclose(handle);
        return [out componentsJoinedByString:@"\n"];
    }
    probe_io_service_t service = get(MACH_PORT_NULL, query);
    if (!service) {
        [out addObject:@"IOSurfaceRoot not visible."];
        dlclose(handle);
        return [out componentsJoinedByString:@"\n"];
    }
    probe_io_connect_t connection = MACH_PORT_NULL;
    kern_return_t status = openClient(service, mach_task_self(), 0, &connection);
    [out addObject:[NSString stringWithFormat:@"IOServiceOpen: 0x%08x", (uint32_t)status]];
    if (status == KERN_SUCCESS && connection != MACH_PORT_NULL) {
        const uint8_t markers[3] = {0x00, 0xa5, 0x5a};
        const unsigned positions[5] = {33, 36, 37, 38, 39};
        for (unsigned k = 0; k < 3; k++) {
            uint8_t bytes[40];
            memset(bytes, markers[k], sizeof(bytes));
            size_t outputSize = sizeof(bytes);
            kern_return_t result = callStruct(connection, 13, NULL, 0, bytes, &outputSize);
            [out addObject:[NSString stringWithFormat:@"Run %u | prefill 0x%02x | result 0x%08x | output %lu",
                            k + 1, (unsigned)markers[k], (uint32_t)result, (unsigned long)outputSize]];
            if (result == KERN_SUCCESS && outputSize == sizeof(bytes)) {
                BOOL unchanged = YES;
                NSMutableString *pad = [NSMutableString stringWithString:@"  offsets 33,36-39:"];
                for (unsigned j = 0; j < 5; j++) {
                    uint8_t value = bytes[positions[j]];
                    [pad appendFormat:@" %02x", (unsigned)value];
                    if (value != markers[k]) unchanged = NO;
                }
                [out addObject:pad];
                [out addObject:unchanged ? @"  All five match caller's prefill." :
                 @"  At least one byte differs from caller's prefill."];
            }
        }
        kern_return_t closeResult = closeClient(connection);
        [out addObject:[NSString stringWithFormat:@"IOServiceClose: 0x%08x", (uint32_t)closeResult]];
    } else {
        [out addObject:@"No connection, so selector 13 was not called."];
        if (connection != MACH_PORT_NULL) closeClient(connection);
    }
    release(service);
    dlclose(handle);
    [out addObject:@"Nonzero or changing padding alone does not prove kernel disclosure."];
    [out addObject:@"End of selector-13 test."];
    return [out componentsJoinedByString:@"\n"];
}

@interface ProbeAppDelegate : UIResponder <UIApplicationDelegate>
@property (nonatomic, strong) UIWindow *window;
@property (nonatomic, strong) UITextView *report;
@end

@implementation ProbeAppDelegate
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    self.window = [[UIWindow alloc] initWithFrame:UIScreen.mainScreen.bounds];
    UIViewController *vc = [UIViewController new];
    vc.view.backgroundColor = UIColor.systemBackgroundColor;

    UIStackView *stack = [[UIStackView alloc] initWithFrame:vc.view.bounds];
    stack.axis = UILayoutConstraintAxisVertical;
    stack.spacing = 10;
    stack.layoutMargins = UIEdgeInsetsMake(16, 16, 16, 16);
    stack.layoutMarginsRelativeArrangement = YES;
    stack.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;

    UILabel *title = [UILabel new];
    title.text = @"IOKit Reachability Probe";
    title.font = [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline];
    [stack addArrangedSubview:title];

    UILabel *subtitle = [UILabel new];
    subtitle.text = @"On-demand survey plus one individually audited read-only IOSurface method. No fuzzing.";
    subtitle.numberOfLines = 0;
    subtitle.font = [UIFont preferredFontForTextStyle:UIFontTextStyleFootnote];
    [stack addArrangedSubview:subtitle];

    UIButton *run = [UIButton buttonWithType:UIButtonTypeSystem];
    [run setTitle:@"Run read-only connection checks" forState:UIControlStateNormal];
    [run addTarget:self action:@selector(runProbe:) forControlEvents:UIControlEventTouchUpInside];
    [stack addArrangedSubview:run];

    UIButton *padding = [UIButton buttonWithType:UIButtonTypeSystem];
    [padding setTitle:@"Inspect IOSurface selector 13 (read-only)" forState:UIControlStateNormal];
    [padding addTarget:self action:@selector(runPaddingProbe:) forControlEvents:UIControlEventTouchUpInside];
    [stack addArrangedSubview:padding];

    UIButton *copy = [UIButton buttonWithType:UIButtonTypeSystem];
    [copy setTitle:@"Copy complete report" forState:UIControlStateNormal];
    [copy addTarget:self action:@selector(copyReport:) forControlEvents:UIControlEventTouchUpInside];
    [stack addArrangedSubview:copy];

    self.report = [UITextView new];
    self.report.editable = NO;
    self.report.selectable = YES;
    self.report.font = [UIFont monospacedSystemFontOfSize:12 weight:UIFontWeightRegular];
    self.report.text = @"Ready.\nSurvey: seven service open/close checks.\nSelector 13: separate read-only, three-call padding verification.\nTap a button to start; nothing runs automatically." ;
    [stack addArrangedSubview:self.report];

    [vc.view addSubview:stack];
    self.window.rootViewController = vc;
    [self.window makeKeyAndVisible];
    return YES;
}
- (void)runProbe:(id)sender {
    self.report.text = RunReachabilityProbe();
}
- (void)runPaddingProbe:(id)sender {
    self.report.text = RunPaddingProbe();
}
- (void)copyReport:(id)sender {
    UIPasteboard.generalPasteboard.string = self.report.text ?: @"";
}
@end

int main(int argc, char *argv[]) {
    @autoreleasepool {
        return UIApplicationMain(argc, argv, nil, NSStringFromClass(ProbeAppDelegate.class));
    }
}
