#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <IOKit/IOKitLib.h>
#import <mach/mach.h>

@interface ProbeController : UIViewController
@property(nonatomic,strong) UITextView *output;
@property(nonatomic,strong) UIButton *runButton;
@property(nonatomic,strong) NSString *lastLog;
@end

@implementation ProbeController
- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"Kernel Service Probe";
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

@interface ProbeAppDelegate : UIResponder <UIApplicationDelegate>
@property(nonatomic,strong) UIWindow *window;
@end
@implementation ProbeAppDelegate
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    self.window = [[UIWindow alloc] initWithFrame:UIScreen.mainScreen.bounds];
    self.window.rootViewController = [[UINavigationController alloc] initWithRootViewController:[ProbeController new]];
    [self.window makeKeyAndVisible];
    return YES;
}
@end
int main(int argc, char **argv) {
    @autoreleasepool { return UIApplicationMain(argc, argv, nil, NSStringFromClass([ProbeAppDelegate class])); }
}
