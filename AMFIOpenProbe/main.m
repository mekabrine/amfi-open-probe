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
 * Tweak Examples (app-local only).
 *
 * All effects below are implemented with ordinary UIKit. The overlay is
 * installed as a non-interactive view in THIS app's own UIWindow. It never
 * appears in SpringBoard, the system compositor, or other applications.
 * No private API, kernel selectors, entitlements, or cross-app writes.
 */
static NSInteger const kExampleOverlayTag = 0x4f564c59;
static NSString *const kExampleOverlayEnabled = @"ExampleOverlayEnabled";
static NSString *const kExampleTintEnabled = @"ExampleTintEnabled";

@interface AppTweakExamples : NSObject
+ (void)restoreInNavigation:(UINavigationController *)navigation;
+ (void)showOverlayInNavigation:(UINavigationController *)navigation;
+ (void)removeOverlayInNavigation:(UINavigationController *)navigation;
+ (void)applyTintInNavigation:(UINavigationController *)navigation;
+ (NSURL *)imageURL;
@end

@implementation AppTweakExamples
+ (NSURL *)imageURL {
    NSURL *documents = [[[NSFileManager defaultManager]
        URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] firstObject];
    return [documents URLByAppendingPathComponent:@"tweak-example-image.png"];
}
+ (UIImage *)defaultIcon {
    UIGraphicsImageRenderer *renderer =
        [[UIGraphicsImageRenderer alloc] initWithSize:CGSizeMake(128, 128)];
    return [renderer imageWithActions:^(UIGraphicsImageRendererContext *ctx) {
        [[UIColor systemPurpleColor] setFill];
        [[UIBezierPath bezierPathWithRoundedRect:CGRectMake(0, 0, 128, 128)
                                   cornerRadius:28] fill];
        NSString *mark = @"✦";
        NSDictionary *attrs = @{
            NSFontAttributeName:[UIFont systemFontOfSize:88 weight:UIFontWeightBold],
            NSForegroundColorAttributeName:UIColor.whiteColor
        };
        CGSize size = [mark sizeWithAttributes:attrs];
        [mark drawAtPoint:CGPointMake((128-size.width)/2, (128-size.height)/2-4)
          withAttributes:attrs];
    }];
}
+ (UIImage *)fitImage:(UIImage *)image {
    if (!image) return nil;
    UIGraphicsImageRendererFormat *format = [UIGraphicsImageRendererFormat defaultFormat];
    format.scale = 1;
    UIGraphicsImageRenderer *renderer =
        [[UIGraphicsImageRenderer alloc] initWithSize:CGSizeMake(128, 128) format:format];
    return [renderer imageWithActions:^(UIGraphicsImageRendererContext *ctx) {
        CGFloat ratio = MIN(128.0/image.size.width, 128.0/image.size.height);
        if (!isfinite(ratio) || ratio <= 0) return;
        CGSize scaled = CGSizeMake(image.size.width*ratio, image.size.height*ratio);
        [image drawInRect:CGRectMake((128-scaled.width)/2,
                                     (128-scaled.height)/2, scaled.width, scaled.height)];
    }];
}
+ (void)removeOverlayInNavigation:(UINavigationController *)navigation {
    UIWindow *window = navigation.view.window;
    [[window viewWithTag:kExampleOverlayTag] removeFromSuperview];
}
+ (void)showOverlayInNavigation:(UINavigationController *)navigation {
    UIWindow *window = navigation.view.window;
    if (!window) return;
    [self removeOverlayInNavigation:navigation];
    UIImage *image = [UIImage imageWithContentsOfFile:[self imageURL].path];
    if (!image) image = [self defaultIcon];
    UIImageView *badge = [[UIImageView alloc] initWithImage:image];
    badge.translatesAutoresizingMaskIntoConstraints = NO;
    badge.tag = kExampleOverlayTag;
    badge.contentMode = UIViewContentModeScaleAspectFit;
    badge.userInteractionEnabled = NO;
    badge.layer.cornerRadius = 12;
    badge.clipsToBounds = YES;
    badge.accessibilityLabel = @"App-only floating image example";
    [window addSubview:badge];
    [NSLayoutConstraint activateConstraints:@[
        [badge.widthAnchor constraintEqualToConstant:68],
        [badge.heightAnchor constraintEqualToConstant:68],
        [badge.topAnchor constraintEqualToAnchor:window.safeAreaLayoutGuide.topAnchor constant:72],
        [badge.trailingAnchor constraintEqualToAnchor:window.safeAreaLayoutGuide.trailingAnchor constant:-12]
    ]];
}
+ (void)applyTintInNavigation:(UINavigationController *)navigation {
    BOOL active = [[NSUserDefaults standardUserDefaults] boolForKey:kExampleTintEnabled];
    navigation.view.window.tintColor = active ? UIColor.systemPinkColor : nil;
    navigation.navigationBar.tintColor = active ? UIColor.systemPinkColor : nil;
}
+ (void)restoreInNavigation:(UINavigationController *)navigation {
    [self applyTintInNavigation:navigation];
    if ([[NSUserDefaults standardUserDefaults] boolForKey:kExampleOverlayEnabled]) {
        [self showOverlayInNavigation:navigation];
    }
}
@end

@interface TweakExamplesController : UIViewController <UIDocumentPickerDelegate>
@property(nonatomic,strong) UIButton *overlayButton;
@property(nonatomic,strong) UIButton *tintButton;
@property(nonatomic,strong) UILabel *messageLabel;
@end

@implementation TweakExamplesController
- (UILabel *)textLine:(NSString *)value font:(UIFont *)font {
    UILabel *label = [UILabel new];
    label.text = value;
    label.font = font;
    label.numberOfLines = 0;
    return label;
}
- (UIButton *)actionButton:(NSString *)title action:(SEL)action {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
    [button setTitle:title forState:UIControlStateNormal];
    button.titleLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
    button.titleLabel.numberOfLines = 2;
    button.titleLabel.textAlignment = NSTextAlignmentCenter;
    button.backgroundColor = UIColor.secondarySystemBackgroundColor;
    button.layer.cornerRadius = 11;
    [button addTarget:self action:action forControlEvents:UIControlEventTouchUpInside];
    [button.heightAnchor constraintGreaterThanOrEqualToConstant:46].active = YES;
    return button;
}
- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"Possible Tweaks";
    self.view.backgroundColor = UIColor.systemBackgroundColor;
    UIScrollView *scroll = [UIScrollView new];
    scroll.translatesAutoresizingMaskIntoConstraints = NO;
    UIStackView *stack = [UIStackView new];
    stack.translatesAutoresizingMaskIntoConstraints = NO;
    stack.axis = UILayoutConstraintAxisVertical;
    stack.spacing = 13;
    [self.view addSubview:scroll];
    [scroll addSubview:stack];
    UILayoutGuide *guide = self.view.safeAreaLayoutGuide;
    [NSLayoutConstraint activateConstraints:@[
        [scroll.topAnchor constraintEqualToAnchor:guide.topAnchor],
        [scroll.bottomAnchor constraintEqualToAnchor:guide.bottomAnchor],
        [scroll.leadingAnchor constraintEqualToAnchor:guide.leadingAnchor],
        [scroll.trailingAnchor constraintEqualToAnchor:guide.trailingAnchor],
        [stack.topAnchor constraintEqualToAnchor:scroll.contentLayoutGuide.topAnchor constant:14],
        [stack.bottomAnchor constraintEqualToAnchor:scroll.contentLayoutGuide.bottomAnchor constant:-26],
        [stack.leadingAnchor constraintEqualToAnchor:scroll.contentLayoutGuide.leadingAnchor constant:18],
        [stack.trailingAnchor constraintEqualToAnchor:scroll.contentLayoutGuide.trailingAnchor constant:-18],
        [stack.widthAnchor constraintEqualToAnchor:scroll.frameLayoutGuide.widthAnchor constant:-36]
    ]];

    [stack addArrangedSubview:[self textLine:@"Working visual examples — this app only"
           font:[UIFont preferredFontForTextStyle:UIFontTextStyleTitle2]]];
    [stack addArrangedSubview:[self textLine:
        @"These use standard UIKit. Neither example modifies other apps, SpringBoard, or the kernel. The floating image remains visible when moving between screens inside this app."
           font:[UIFont preferredFontForTextStyle:UIFontTextStyleBody]]];

    self.overlayButton = [self actionButton:@"Show floating image in this app"
                                    action:@selector(toggleOverlay:)];
    [stack addArrangedSubview:self.overlayButton];
    [stack addArrangedSubview:[self actionButton:@"Choose custom image from Files"
                                            action:@selector(chooseImage:)]];
    self.tintButton = [self actionButton:@"Apply pink tint inside this app"
                                 action:@selector(toggleTint:)];
    [stack addArrangedSubview:self.tintButton];
    [stack addArrangedSubview:[self actionButton:@"Open existing File Change Test"
                                            action:@selector(openFileChange:)]];
    [stack addArrangedSubview:[self textLine:
        @"Try navigating back to HID Check or File Test: the image stays over THIS app. Opening another app hides it. You can remove the image or reset the tint here."
           font:[UIFont preferredFontForTextStyle:UIFontTextStyleFootnote]]];

    [stack addArrangedSubview:[self textLine:@"Exploit research — evidence, not demos"
           font:[UIFont preferredFontForTextStyle:UIFontTextStyleHeadline]]];
    [stack addArrangedSubview:[self textLine:
        @"CONFIRMED ON YOUR DEVICE\n"
        "• FastPath type-2 connection: OPEN on AOPTouchHIDDriver. No kernel privilege or tweak injection.\n"
        "• Standard HID manager opens: DENIED for four tested representative classes.\n"
        "• Cross-app data-file changes: demonstrated previously with Erosion; app preferences/assets only where supported.\n\n"
        "RESEARCH LEADS — NOT WORKING EXPLOITS\n"
        "• CVE-2026-28992: FastPath race. Public demos cause panics, not controlled kernel read/write.\n"
        "• CVE-2026-86966: copyfile protected-file-write advisory; no verified method or writable UI target.\n"
        "• CVE-2026-112477: IOSurface kernel race; no reliable primitive.\n"
        "• CVE-2026-112646: SpringBoard process-memory corruption; no identified usable trigger.\n\n"
        "A persistent image over unrelated apps still requires a different privilege or system UI capability."
           font:[UIFont preferredFontForTextStyle:UIFontTextStyleFootnote]]];
    self.messageLabel = [self textLine:@"All example modifications are local and reversible."
                                 font:[UIFont preferredFontForTextStyle:UIFontTextStyleFootnote]];
    [stack addArrangedSubview:self.messageLabel];
    [self updateLabels];
}
- (void)updateLabels {
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    [self.overlayButton setTitle:
        [prefs boolForKey:kExampleOverlayEnabled] ?
        @"Remove floating image" : @"Show floating image in this app"
        forState:UIControlStateNormal];
    [self.tintButton setTitle:
        [prefs boolForKey:kExampleTintEnabled] ?
        @"Reset app tint" : @"Apply pink tint inside this app"
        forState:UIControlStateNormal];
}
- (void)toggleOverlay:(id)sender {
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    BOOL enabled = ![prefs boolForKey:kExampleOverlayEnabled];
    [prefs setBool:enabled forKey:kExampleOverlayEnabled];
    if (enabled) [AppTweakExamples showOverlayInNavigation:self.navigationController];
    else [AppTweakExamples removeOverlayInNavigation:self.navigationController];
    self.messageLabel.text = enabled ? @"App-only image enabled." : @"App-only image removed.";
    [self updateLabels];
}
- (void)toggleTint:(id)sender {
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    [prefs setBool:![prefs boolForKey:kExampleTintEnabled] forKey:kExampleTintEnabled];
    [AppTweakExamples applyTintInNavigation:self.navigationController];
    self.messageLabel.text = @"App-only tint setting updated.";
    [self updateLabels];
}
- (void)chooseImage:(id)sender {
    UIDocumentPickerViewController *picker =
        [[UIDocumentPickerViewController alloc] initWithDocumentTypes:@[@"public.image"]
                                                              inMode:UIDocumentPickerModeImport];
    picker.delegate = self;
    picker.allowsMultipleSelection = NO;
    [self presentViewController:picker animated:YES completion:nil];
}
- (void)documentPicker:(UIDocumentPickerViewController *)controller
 didPickDocumentsAtURLs:(NSArray<NSURL *> *)urls {
    NSURL *url = urls.firstObject;
    if (!url) return;
    NSNumber *fileSize = nil;
    [url getResourceValue:&fileSize forKey:NSURLFileSizeKey error:nil];
    if (fileSize.unsignedLongLongValue > 12ULL*1024*1024) {
        self.messageLabel.text = @"Image too large. Please choose one under 12 MB.";
        return;
    }
    BOOL scoped = [url startAccessingSecurityScopedResource];
    NSData *data = [NSData dataWithContentsOfURL:url];
    if (scoped) [url stopAccessingSecurityScopedResource];
    if (data.length == 0 || data.length > 12ULL*1024*1024) {
        self.messageLabel.text = @"Unable to load the chosen image (12 MB limit).";
        return;
    }
    UIImage *fitted = [AppTweakExamples fitImage:[UIImage imageWithData:data]];
    NSData *png = fitted ? UIImagePNGRepresentation(fitted) : nil;
    NSError *error = nil;
    BOOL saved = png && [png writeToURL:[AppTweakExamples imageURL]
                                 options:NSDataWritingAtomic error:&error];
    if (!saved) {
        self.messageLabel.text = [NSString stringWithFormat:@"Image not saved: %@",
                                   error.localizedDescription ?: @"unsupported format"];
        return;
    }
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:kExampleOverlayEnabled];
    [AppTweakExamples showOverlayInNavigation:self.navigationController];
    self.messageLabel.text = @"Your custom image is now over this app only.";
    [self updateLabels];
}
- (void)openFileChange:(id)sender {
    [self.navigationController pushViewController:[ContainerChangeController new] animated:YES];
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
@interface HIDReachabilityController : UIViewController
@property(nonatomic,strong) UITextView *output;
@property(nonatomic,strong) UIButton *runButton;
@property(nonatomic,strong) UIButton *inventoryButton;
@property(nonatomic,strong) UIButton *classCheckButton;
@property(nonatomic,strong) UIButton *fastPathButton;
@property(nonatomic,copy) NSString *lastLog;
@end

@implementation HIDReachabilityController
- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"HID Reachability";
    self.view.backgroundColor = UIColor.systemBackgroundColor;

    UILabel *description = [UILabel new];
    description.translatesAutoresizingMaskIntoConstraints = NO;
    description.numberOfLines = 0;
    description.font = [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline];
    description.text = @"Inventory HID providers or check one representative of the three remaining device classes. A standard connection opens and immediately closes; no external-method selectors or HID reports.";

    self.runButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.runButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.runButton setTitle:@"Run HID check once" forState:UIControlStateNormal];
    [self.runButton addTarget:self action:@selector(runCheck:) forControlEvents:UIControlEventTouchUpInside];

    UIButton *copyButton = [UIButton buttonWithType:UIButtonTypeSystem];
    copyButton.translatesAutoresizingMaskIntoConstraints = NO;
    [copyButton setTitle:@"Copy results" forState:UIControlStateNormal];
    [copyButton addTarget:self action:@selector(copyLog:) forControlEvents:UIControlEventTouchUpInside];

    self.inventoryButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.inventoryButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.inventoryButton setTitle:@"Inventory HID providers" forState:UIControlStateNormal];
    [self.inventoryButton addTarget:self action:@selector(inventoryProviders:) forControlEvents:UIControlEventTouchUpInside];

    self.classCheckButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.classCheckButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.classCheckButton setTitle:@"Check other 3 HID classes once" forState:UIControlStateNormal];
    [self.classCheckButton addTarget:self action:@selector(checkOtherHIDClasses:) forControlEvents:UIControlEventTouchUpInside];

    self.fastPathButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.fastPathButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.fastPathButton setTitle:@"Check FastPath type 2 once (no selectors)" forState:UIControlStateNormal];
    [self.fastPathButton addTarget:self action:@selector(checkFastPathOnce:) forControlEvents:UIControlEventTouchUpInside];

    self.output = [UITextView new];
    self.output.translatesAutoresizingMaskIntoConstraints = NO;
    self.output.editable = NO;
    self.output.selectable = YES;
    self.output.backgroundColor = UIColor.secondarySystemBackgroundColor;
    self.output.layer.cornerRadius = 10;
    self.output.font = [UIFont monospacedSystemFontOfSize:12 weight:UIFontWeightRegular];
    self.output.text = @"No checks have run.\n\nIOHIDFamily CVE-2026-112515 describes a kernel out-of-bounds read, but its affected user-client and reachability are not known. Discovery or an open connection is NOT evidence of that vulnerability.";

    [self.view addSubview:description];
    [self.view addSubview:self.runButton];
    [self.view addSubview:copyButton];
    [self.view addSubview:self.inventoryButton];
    [self.view addSubview:self.classCheckButton];
    [self.view addSubview:self.fastPathButton];
    [self.view addSubview:self.output];

    UILayoutGuide *guide = self.view.safeAreaLayoutGuide;
    [NSLayoutConstraint activateConstraints:@[
        [description.topAnchor constraintEqualToAnchor:guide.topAnchor constant:16],
        [description.leadingAnchor constraintEqualToAnchor:guide.leadingAnchor constant:16],
        [description.trailingAnchor constraintEqualToAnchor:guide.trailingAnchor constant:-16],
        [self.runButton.topAnchor constraintEqualToAnchor:description.bottomAnchor constant:16],
        [self.runButton.leadingAnchor constraintEqualToAnchor:description.leadingAnchor],
        [copyButton.centerYAnchor constraintEqualToAnchor:self.runButton.centerYAnchor],
        [copyButton.trailingAnchor constraintEqualToAnchor:description.trailingAnchor],
        [self.inventoryButton.topAnchor constraintEqualToAnchor:self.runButton.bottomAnchor constant:12],
        [self.inventoryButton.leadingAnchor constraintEqualToAnchor:description.leadingAnchor],
        [self.inventoryButton.trailingAnchor constraintEqualToAnchor:description.trailingAnchor],
        [self.classCheckButton.topAnchor constraintEqualToAnchor:self.inventoryButton.bottomAnchor constant:12],
        [self.classCheckButton.leadingAnchor constraintEqualToAnchor:description.leadingAnchor],
        [self.classCheckButton.trailingAnchor constraintEqualToAnchor:description.trailingAnchor],
        [self.fastPathButton.topAnchor constraintEqualToAnchor:self.classCheckButton.bottomAnchor constant:12],
        [self.fastPathButton.leadingAnchor constraintEqualToAnchor:description.leadingAnchor],
        [self.fastPathButton.trailingAnchor constraintEqualToAnchor:description.trailingAnchor],
        [self.output.topAnchor constraintEqualToAnchor:self.fastPathButton.bottomAnchor constant:12],
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
@property(nonatomic,strong) UIButton *examplesButton;
@property(nonatomic,strong) NSString *lastLog;
@end

@implementation ProbeController
- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"Kernel Service Probe";
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"File Test" style:UIBarButtonItemStylePlain target:self action:@selector(openFileTest:)];
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"HID Check" style:UIBarButtonItemStylePlain target:self action:@selector(openHIDCheck:)];
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

    self.examplesButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.examplesButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.examplesButton setTitle:@"Possible Tweaks / Examples" forState:UIControlStateNormal];
    self.examplesButton.backgroundColor = UIColor.secondarySystemBackgroundColor;
    self.examplesButton.layer.cornerRadius = 10;
    [self.examplesButton addTarget:self action:@selector(openExamples:)
                forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.examplesButton];

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
        [self.examplesButton.topAnchor constraintEqualToAnchor:self.runButton.bottomAnchor constant:12],
        [self.examplesButton.leadingAnchor constraintEqualToAnchor:heading.leadingAnchor],
        [self.examplesButton.trailingAnchor constraintEqualToAnchor:heading.trailingAnchor],
        [self.examplesButton.heightAnchor constraintEqualToConstant:44],
        [self.output.topAnchor constraintEqualToAnchor:self.examplesButton.bottomAnchor constant:10],
        [self.output.leadingAnchor constraintEqualToAnchor:heading.leadingAnchor],
        [self.output.trailingAnchor constraintEqualToAnchor:heading.trailingAnchor],
        [self.output.bottomAnchor constraintEqualToAnchor:guide.bottomAnchor constant:-12]
    ]];
}
- (void)openExamples:(id)sender {
    [self.navigationController pushViewController:[TweakExamplesController new] animated:YES];
}
- (void)openHIDCheck:(id)sender {
    [self.navigationController pushViewController:[HIDReachabilityController new] animated:YES];
}
- (void)openFileTest:(id)sender {
    [self.navigationController pushViewController:[ContainerChangeController new] animated:YES];
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
    [AppTweakExamples restoreInNavigation:(UINavigationController *)self.window.rootViewController];
    return YES;
}
@end
int main(int argc, char **argv) {
    @autoreleasepool { return UIApplicationMain(argc, argv, nil, NSStringFromClass([ProbeAppDelegate class])); }
}
