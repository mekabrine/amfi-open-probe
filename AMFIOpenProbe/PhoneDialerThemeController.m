#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <stdint.h>

/*
 * Phone dialer theme ZIP generator.
 *
 * Produces 24 original PNG assets (12 keys, mask and white variants)
 * in a stored ZIP. Erosion's documented iOS 26 "Dialer Themer"
 * imports this format and applies it to the separate Phone app using
 * the bad_query sandbox escape. This app NEVER writes into another
 * app's container or pretends to have obtained that capability.
 *
 * The resulting theme is an artifact for user-directed import.
 * No restoration, system modifications or IPC occur here.
 */
static void TPAppendU16(NSMutableData *d, uint16_t x) {
    uint8_t v[2] = {(uint8_t)x, (uint8_t)(x >> 8)};
    [d appendBytes:v length:2];
}
static void TPAppendU32(NSMutableData *d, uint32_t x) {
    uint8_t v[4] = {
        (uint8_t)x, (uint8_t)(x >> 8),
        (uint8_t)(x >> 16), (uint8_t)(x >> 24)
    };
    [d appendBytes:v length:4];
}
static uint32_t TPCrc32(NSData *d) {
    const uint8_t *b = d.bytes;
    uint32_t crc = 0xFFFFFFFFu;
    for (NSUInteger i = 0; i < d.length; ++i) {
        crc ^= b[i];
        for (unsigned j = 0; j < 8; ++j)
            crc = (crc >> 1) ^ (0xEDB88320u & (0u - (crc & 1u)));
    }
    return ~crc;
}
static NSData *TPStoredZIP(NSDictionary<NSString *, NSData *> *files) {
    NSArray<NSString *> *paths = [[files allKeys] sortedArrayUsingSelector:@selector(compare:)];
    NSMutableData *archive = [NSMutableData new];
    NSMutableData *directory = [NSMutableData new];
    for (NSString *path in paths) {
        NSData *name = [path dataUsingEncoding:NSUTF8StringEncoding];
        NSData *data = files[path];
        if (!name || !data || !name.length || name.length > UINT16_MAX ||
            data.length > UINT32_MAX || archive.length > UINT32_MAX) return nil;
        const uint32_t size = (uint32_t)data.length;
        const uint32_t crc = TPCrc32(data);
        const uint32_t offset = (uint32_t)archive.length;

        TPAppendU32(archive, 0x04034B50u);
        TPAppendU16(archive, 20);  TPAppendU16(archive, 0);
        TPAppendU16(archive, 0);   TPAppendU16(archive, 0);
        TPAppendU16(archive, 0);   TPAppendU32(archive, crc);
        TPAppendU32(archive, size);TPAppendU32(archive, size);
        TPAppendU16(archive, (uint16_t)name.length);
        TPAppendU16(archive, 0);
        [archive appendData:name];
        [archive appendData:data];

        TPAppendU32(directory, 0x02014B50u);
        TPAppendU16(directory, 20);TPAppendU16(directory, 20);
        TPAppendU16(directory, 0); TPAppendU16(directory, 0);
        TPAppendU16(directory, 0); TPAppendU16(directory, 0);
        TPAppendU32(directory, crc);
        TPAppendU32(directory, size);TPAppendU32(directory, size);
        TPAppendU16(directory, (uint16_t)name.length);
        TPAppendU16(directory, 0);TPAppendU16(directory, 0);
        TPAppendU16(directory, 0);TPAppendU16(directory, 0);
        TPAppendU32(directory, 0);TPAppendU32(directory, offset);
        [directory appendData:name];
    }
    if (paths.count > UINT16_MAX ||
        archive.length > UINT32_MAX || directory.length > UINT32_MAX ||
        archive.length + directory.length > UINT32_MAX) return nil;
    const uint32_t dirOffset = (uint32_t)archive.length;
    const uint32_t dirSize = (uint32_t)directory.length;
    [archive appendData:directory];
    TPAppendU32(archive, 0x06054B50u);
    TPAppendU16(archive, 0);TPAppendU16(archive, 0);
    TPAppendU16(archive, (uint16_t)paths.count);
    TPAppendU16(archive, (uint16_t)paths.count);
    TPAppendU32(archive, dirSize);TPAppendU32(archive, dirOffset);
    TPAppendU16(archive, 0);
    return archive;
}

static NSData *TPDrawKey(NSString *key, BOOL dark, BOOL purple) {
    CGSize size = CGSizeMake(180, 180);
    UIGraphicsImageRendererFormat *fmt = [UIGraphicsImageRendererFormat defaultFormat];
    fmt.scale = 1.0;
    fmt.opaque = NO;
    UIGraphicsImageRenderer *renderer =
        [[UIGraphicsImageRenderer alloc] initWithSize:size format:fmt];
    UIImage *image = [renderer imageWithActions:^(UIGraphicsImageRendererContext * _Nonnull ctx) {
        CGContextRef c = ctx.CGContext;
        UIColor *accent = purple ?
            [UIColor colorWithRed:0.96 green:0.33 blue:0.90 alpha:1] :
            [UIColor colorWithRed:0.17 green:0.82 blue:0.91 alpha:1];
        UIColor *interior = dark ?
            [UIColor colorWithRed:0.12 green:0.11 blue:0.19 alpha:1] :
            [UIColor colorWithRed:0.92 green:0.98 blue:1 alpha:1];

        CGContextSetFillColorWithColor(c, interior.CGColor);
        CGContextFillEllipseInRect(c, CGRectMake(4, 4, 172, 172));
        CGContextSetStrokeColorWithColor(c, accent.CGColor);
        CGContextSetLineWidth(c, 8);
        CGContextStrokeEllipseInRect(c, CGRectMake(6, 6, 168, 168));

        UIColor *textColor = dark ? UIColor.whiteColor :
            [UIColor colorWithRed:0.08 green:0.15 blue:0.23 alpha:1];
        UIFont *font = [UIFont systemFontOfSize:92 weight:UIFontWeightMedium];
        NSDictionary *attrs = @{
            NSFontAttributeName: font,
            NSForegroundColorAttributeName: textColor
        };
        CGSize text = [key sizeWithAttributes:attrs];
        CGRect r = CGRectMake((180 - text.width)/2.0,
                              (180 - text.height)/2.0 - 3,
                              text.width, text.height);
        [key drawInRect:r withAttributes:attrs];
    }];
    return UIImagePNGRepresentation(image);
}

@interface PhoneDialerThemeController : UIViewController
@property(nonatomic,strong) UISegmentedControl *colorChoice;
@property(nonatomic,strong) UIButton *exportButton;
@property(nonatomic,strong) UILabel *instructions;
@end
@implementation PhoneDialerThemeController
- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"Phone Dialer Theme";
    self.view.backgroundColor = UIColor.systemBackgroundColor;

    UILabel *heading = [UILabel new];
    heading.translatesAutoresizingMaskIntoConstraints = NO;
    heading.numberOfLines = 0;
    heading.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
    heading.text = @"Generate a real Phone-app keypad theme for iPadOS 26. "
        "The exported ZIP is applied through Erosion's existing bad_query "
        "exploit; this screen itself does not modify other apps.";
    [self.view addSubview:heading];

    self.colorChoice = [[UISegmentedControl alloc]
        initWithItems:@[@"Cyan", @"Magenta"]];
    self.colorChoice.selectedSegmentIndex = 0;
    self.colorChoice.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.colorChoice];

    self.exportButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.exportButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.exportButton setTitle:@"Create and share dialer theme ZIP"
                       forState:UIControlStateNormal];
    [self.exportButton addTarget:self
                          action:@selector(exportTheme:)
                forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.exportButton];

    UILabel *instructions = [UILabel new];
    instructions.translatesAutoresizingMaskIntoConstraints = NO;
    instructions.numberOfLines = 0;
    instructions.font =
        [UIFont preferredFontForTextStyle:UIFontTextStyleFootnote];
    instructions.text = @"How to test the real tweak:\n"
        "1. Export and save the ZIP to Files.\n"
        "2. Open Erosion → Tweaks → Dialer Themer → Import.\n"
        "3. Choose this ZIP, then tap Apply in Erosion.\n"
        "4. Open the separate Phone app and check the keypad.\n\n"
        "Changes can require a Phone appearance refresh or reboot. "
        "If it looks wrong, use Erosion's Reset Keys option. "
        "Back up any existing custom dialer theme first.\n\n"
        "No partial restore, kernel probes or SpringBoard injection. "
        "Erosion and the Phone app must be installed. "
        "This does not demonstrate a new sandbox exploit.";
    [self.view addSubview:instructions];

    UILayoutGuide *g = self.view.safeAreaLayoutGuide;
    [NSLayoutConstraint activateConstraints:@[
        [heading.topAnchor constraintEqualToAnchor:g.topAnchor constant:18],
        [heading.leadingAnchor constraintEqualToAnchor:g.leadingAnchor constant:18],
        [heading.trailingAnchor constraintEqualToAnchor:g.trailingAnchor constant:-18],
        [self.colorChoice.topAnchor constraintEqualToAnchor:heading.bottomAnchor constant:20],
        [self.colorChoice.leadingAnchor constraintEqualToAnchor:heading.leadingAnchor],
        [self.colorChoice.trailingAnchor constraintEqualToAnchor:heading.trailingAnchor],
        [self.exportButton.topAnchor constraintEqualToAnchor:self.colorChoice.bottomAnchor constant:16],
        [self.exportButton.leadingAnchor constraintEqualToAnchor:heading.leadingAnchor],
        [instructions.topAnchor constraintEqualToAnchor:self.exportButton.bottomAnchor constant:26],
        [instructions.leadingAnchor constraintEqualToAnchor:heading.leadingAnchor],
        [instructions.trailingAnchor constraintEqualToAnchor:heading.trailingAnchor]
    ]];
}
- (void)exportTheme:(id)sender {
    self.exportButton.enabled = NO;
    BOOL purple = self.colorChoice.selectedSegmentIndex == 1;
    NSMutableDictionary<NSString *, NSData *> *files = [NSMutableDictionary new];
    NSArray<NSString *> *keys = @[@"1",@"2",@"3",@"4",@"5",@"6",@"7",@"8",@"9",@"*",@"0",@"#"];
    for (NSString *key in keys) {
        for (NSNumber *variant in @[@NO, @YES]) {
            BOOL dark = variant.boolValue;
            NSString *suffix = dark ? @"white" : @"mask";
            NSString *name = [NSString stringWithFormat:
                @"TelephonyUI-10/Research-%@-art-%@.png", key, suffix];
            NSData *png = TPDrawKey(key, dark, purple);
            if (!png) {
                [self showError:@"Could not render keypad artwork."];
                self.exportButton.enabled = YES;
                return;
            }
            files[name] = png;
        }
    }
    NSData *zip = TPStoredZIP(files);
    if (!zip) {
        [self showError:@"Could not package keypad images."];
        self.exportButton.enabled = YES;
        return;
    }
    NSURL *folder = [[[NSFileManager defaultManager]
        URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] firstObject];
    NSString *name = [NSString stringWithFormat:
        @"ResearchDialer-%@-%@.zip",
        purple ? @"Magenta" : @"Cyan", NSUUID.UUID.UUIDString];
    NSURL *url = [folder URLByAppendingPathComponent:name isDirectory:NO];
    NSError *error = nil;
    if (![zip writeToURL:url options:NSDataWritingAtomic error:&error]) {
        [self showError:error.localizedDescription ?: @"Could not save the theme."];
        self.exportButton.enabled = YES;
        return;
    }
    UIActivityViewController *share =
        [[UIActivityViewController alloc] initWithActivityItems:@[url]
                                         applicationActivities:nil];
    share.popoverPresentationController.sourceView = self.exportButton;
    [self presentViewController:share animated:YES completion:nil];
    self.exportButton.enabled = YES;
}
- (void)showError:(NSString *)message {
    UIAlertController *alert = [UIAlertController
        alertControllerWithTitle:@"Theme export failed" message:message
                 preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"OK"
                       style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}
@end
