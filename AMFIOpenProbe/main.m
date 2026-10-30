#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <CoreFoundation/CoreFoundation.h>
#import <dlfcn.h>
#import <mach/mach.h>

typedef uint32_t io_object_t;
typedef io_object_t io_service_t;
typedef uint32_t io_connect_t;
typedef CFMutableDictionaryRef (*ServiceMatchingFn)(const char *);
typedef io_service_t (*GetMatchingServiceFn)(mach_port_t, CFDictionaryRef);
typedef kern_return_t (*ServiceOpenFn)(io_service_t, mach_port_t, uint32_t, io_connect_t *);
typedef kern_return_t (*ServiceCloseFn)(io_connect_t);
typedef kern_return_t (*ObjectReleaseFn)(io_object_t);

static NSString *Probe(void) {
    NSMutableArray<NSString *> *lines = [NSMutableArray array];
    [lines addObject:@"AMFI user-client reachability probe"];
    [lines addObject:@"Read-only: matching -> locate -> open -> close"];
    [lines addObject:@"No externalMethod calls; no security-state changes."];
    void *lib = dlopen("/System/Library/Frameworks/IOKit.framework/IOKit", RTLD_NOW | RTLD_LOCAL);
    if (!lib) {
        [lines addObject:[NSString stringWithFormat:@"IOKit dlopen failed: %s", dlerror() ?: "unknown"]];
        return [lines componentsJoinedByString:@"\n"];
    }
    ServiceMatchingFn matching = (ServiceMatchingFn)dlsym(lib, "IOServiceMatching");
    GetMatchingServiceFn getService = (GetMatchingServiceFn)dlsym(lib, "IOServiceGetMatchingService");
    ServiceOpenFn openService = (ServiceOpenFn)dlsym(lib, "IOServiceOpen");
    ServiceCloseFn closeService = (ServiceCloseFn)dlsym(lib, "IOServiceClose");
    ObjectReleaseFn releaseObject = (ObjectReleaseFn)dlsym(lib, "IOObjectRelease");
    if (!matching || !getService || !openService || !closeService || !releaseObject) {
        [lines addObject:@"Required IOKit symbol unavailable."];
        dlclose(lib);
        return [lines componentsJoinedByString:@"\n"];
    }
    CFMutableDictionaryRef match = matching("AppleMobileFileIntegrity");
    if (!match) {
        [lines addObject:@"IOServiceMatching returned NULL."];
        dlclose(lib);
        return [lines componentsJoinedByString:@"\n"];
    }
    io_service_t service = getService(MACH_PORT_NULL, match);
    if (service == MACH_PORT_NULL) {
        [lines addObject:@"AMFI service not found or not visible."];
        dlclose(lib);
        return [lines componentsJoinedByString:@"\n"];
    }
    [lines addObject:[NSString stringWithFormat:@"AMFI service located: 0x%08x", service]];
    io_connect_t connection = MACH_PORT_NULL;
    kern_return_t result = openService(service, mach_task_self(), 0, &connection);
    [lines addObject:[NSString stringWithFormat:@"IOServiceOpen(type=0): 0x%08x (%d)", (uint32_t)result, result]];
    if (result == KERN_SUCCESS && connection != MACH_PORT_NULL) {
        [lines addObject:@"Connection opened; closing immediately."];
        kern_return_t closeResult = closeService(connection);
        [lines addObject:[NSString stringWithFormat:@"IOServiceClose: 0x%08x", (uint32_t)closeResult]];
    } else {
        [lines addObject:@"No usable connection opened."];
    }
    releaseObject(service);
    dlclose(lib);
    [lines addObject:@"Probe finished; not evidence of an exploit."];
    return [lines componentsJoinedByString:@"\n"];
}

@interface ProbeAppDelegate : UIResponder <UIApplicationDelegate>
@property (nonatomic, strong) UIWindow *window;
@end

@implementation ProbeAppDelegate
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    self.window = [[UIWindow alloc] initWithFrame:UIScreen.mainScreen.bounds];
    UIViewController *vc = [UIViewController new];
    vc.view.backgroundColor = UIColor.systemBackgroundColor;
    UITextView *view = [[UITextView alloc] initWithFrame:vc.view.bounds];
    view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    view.editable = NO;
    view.selectable = YES;
    view.font = [UIFont monospacedSystemFontOfSize:14 weight:UIFontWeightRegular];
    view.textContainerInset = UIEdgeInsetsMake(30, 16, 20, 16);
    view.text = Probe();
    [vc.view addSubview:view];
    self.window.rootViewController = vc;
    [self.window makeKeyAndVisible];
    return YES;
}
@end

int main(int argc, char *argv[]) {
    @autoreleasepool {
        return UIApplicationMain(argc, argv, nil, NSStringFromClass(ProbeAppDelegate.class));
    }
}
