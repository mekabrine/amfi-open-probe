#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <UniformTypeIdentifiers/UniformTypeIdentifiers.h>
#import <AVFoundation/AVFoundation.h>
#import <AVKit/AVKit.h>
#import <CoreVideo/CoreVideo.h>
#import <CoreMedia/CoreMedia.h>
#import <math.h>


@interface BrowserController : UIViewController <UITableViewDataSource,UITableViewDelegate,UITextFieldDelegate,UIDocumentPickerDelegate>
@property(nonatomic,strong) UITextField *pathField;
@property(nonatomic,strong) UITableView *table;
@property(nonatomic,strong) UITextView *preview;
@property(nonatomic,strong) UILabel *status;
@property(nonatomic,copy) NSString *path;
@property(nonatomic,copy) NSArray<NSString *> *entries;
@property(nonatomic,strong) NSURL *pickedURL;
@property(nonatomic,assign) BOOL hasScopedAccess;
@end
@implementation BrowserController
- (void)viewDidLoad {
 [super viewDidLoad];
 self.title=@"Read-only Files";
 self.view.backgroundColor=UIColor.systemBackgroundColor;
 UIStackView *stack=[UIStackView new];stack.axis=UILayoutConstraintAxisVertical;stack.spacing=8;
 stack.translatesAutoresizingMaskIntoConstraints=NO;[self.view addSubview:stack];
 [NSLayoutConstraint activateConstraints:@[
  [stack.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor constant:8],
  [stack.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:12],
  [stack.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-12],
  [stack.bottomAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.bottomAnchor constant:-8]]];
 UIStackView *bar=[UIStackView new];bar.axis=UILayoutConstraintAxisHorizontal;bar.spacing=8;[stack addArrangedSubview:bar];
 self.pathField=[UITextField new];self.pathField.borderStyle=UITextBorderStyleRoundedRect;
 self.pathField.font=[UIFont monospacedSystemFontOfSize:13 weight:UIFontWeightRegular];
 self.pathField.autocapitalizationType=UITextAutocapitalizationTypeNone;
 self.pathField.autocorrectionType=UITextAutocorrectionTypeNo;self.pathField.delegate=self;
 self.pathField.returnKeyType=UIReturnKeyGo;self.pathField.placeholder=@"/absolute/path";
 [bar addArrangedSubview:self.pathField];
 UIButton *go=[UIButton buttonWithType:UIButtonTypeSystem];[go setTitle:@"Go" forState:UIControlStateNormal];
 [go addTarget:self action:@selector(go:) forControlEvents:UIControlEventTouchUpInside];[bar addArrangedSubview:go];
 UIStackView *nav=[UIStackView new];nav.axis=UILayoutConstraintAxisHorizontal;nav.spacing=22;[stack addArrangedSubview:nav];
 UIButton *up=[UIButton buttonWithType:UIButtonTypeSystem];[up setTitle:@"↑ Parent" forState:UIControlStateNormal];
 [up addTarget:self action:@selector(up:) forControlEvents:UIControlEventTouchUpInside];[nav addArrangedSubview:up];
 UIButton *home=[UIButton buttonWithType:UIButtonTypeSystem];[home setTitle:@"App folder" forState:UIControlStateNormal];
 [home addTarget:self action:@selector(home:) forControlEvents:UIControlEventTouchUpInside];[nav addArrangedSubview:home];
 UIButton *chooseFolder=[UIButton buttonWithType:UIButtonTypeSystem];
 [chooseFolder setTitle:@"Browse Files: choose folder" forState:UIControlStateNormal];
 [chooseFolder addTarget:self action:@selector(chooseFolder:) forControlEvents:UIControlEventTouchUpInside];
 [stack addArrangedSubview:chooseFolder];
 UIButton *chooseFile=[UIButton buttonWithType:UIButtonTypeSystem];
 [chooseFile setTitle:@"Browse Files: choose file" forState:UIControlStateNormal];
 [chooseFile addTarget:self action:@selector(chooseFile:) forControlEvents:UIControlEventTouchUpInside];
 [stack addArrangedSubview:chooseFile];
 self.status=[UILabel new];self.status.font=[UIFont preferredFontForTextStyle:UIFontTextStyleFootnote];
 self.status.textColor=UIColor.secondaryLabelColor;self.status.numberOfLines=2;[stack addArrangedSubview:self.status];
 self.table=[[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
 self.table.dataSource=self;self.table.delegate=self;[stack addArrangedSubview:self.table];
 self.preview=[UITextView new];self.preview.editable=NO;self.preview.selectable=YES;
 self.preview.font=[UIFont monospacedSystemFontOfSize:12 weight:UIFontWeightRegular];
 self.preview.layer.borderWidth=0.5;self.preview.layer.borderColor=UIColor.separatorColor.CGColor;
 self.preview.hidden=YES;[stack addArrangedSubview:self.preview];
 [self.preview.heightAnchor constraintEqualToConstant:240].active=YES;
 [self visit:NSHomeDirectory()];
}
- (void)dealloc {
 if(self.hasScopedAccess) [self.pickedURL stopAccessingSecurityScopedResource];
}
- (void)chooseFolder:(id)sender {
 UIDocumentPickerViewController *picker=[[UIDocumentPickerViewController alloc]
  initForOpeningContentTypes:@[UTTypeFolder] asCopy:NO];
 picker.delegate=self;picker.allowsMultipleSelection=NO;
 [self presentViewController:picker animated:YES completion:nil];
}
- (void)chooseFile:(id)sender {
 UIDocumentPickerViewController *picker=[[UIDocumentPickerViewController alloc]
  initForOpeningContentTypes:@[UTTypeItem] asCopy:NO];
 picker.delegate=self;picker.allowsMultipleSelection=NO;
 [self presentViewController:picker animated:YES completion:nil];
}
- (void)documentPicker:(UIDocumentPickerViewController *)controller didPickDocumentsAtURLs:(NSArray<NSURL *> *)urls {
 NSURL *url=urls.firstObject;if(!url)return;
 if(self.hasScopedAccess) [self.pickedURL stopAccessingSecurityScopedResource];
 self.pickedURL=url;self.hasScopedAccess=[url startAccessingSecurityScopedResource];
 NSNumber *isDirectory=nil;
 [url getResourceValue:&isDirectory forKey:NSURLIsDirectoryKey error:NULL];
 if(isDirectory.boolValue) [self visit:url.path]; else [self previewFile:url.path];
}
- (BOOL)textFieldShouldReturn:(UITextField *)field {[self go:nil];return YES;}
- (void)go:(id)sender {[self.pathField resignFirstResponder];[self visit:self.pathField.text?:@""];}
- (void)up:(id)sender {[self visit:[self.path stringByDeletingLastPathComponent]];}
- (void)home:(id)sender {[self visit:NSHomeDirectory()];}
- (void)visit:(NSString *)target {
 if (![target hasPrefix:@"/"]) {self.status.text=@"Enter an absolute path beginning with /";return;}
 NSString *normalized=target.stringByStandardizingPath;
 __block NSArray *items=nil;
 __block NSError *readError=nil;
 NSError *coordinateError=nil;
 NSFileCoordinator *coordinator=[[NSFileCoordinator alloc] initWithFilePresenter:nil];
 [coordinator coordinateReadingItemAtURL:[NSURL fileURLWithPath:normalized isDirectory:YES]
  options:0 error:&coordinateError byAccessor:^(NSURL *coordinatedURL) {
    items=[[NSFileManager defaultManager] contentsOfDirectoryAtPath:coordinatedURL.path error:&readError];
  }];
 NSError *err=readError?:coordinateError;
 self.path=normalized;self.pathField.text=normalized;self.preview.hidden=YES;
 self.entries=items?[items sortedArrayUsingSelector:@selector(localizedStandardCompare:)]:@[];
 self.status.text=items?[NSString stringWithFormat:@"%lu items • read-only",(unsigned long)items.count]:
   [NSString stringWithFormat:@"Access failed: %@ (code %ld)",err.localizedDescription?:@"Permission denied",(long)err.code];
 [self.table reloadData];
}
- (NSInteger)tableView:(UITableView *)table numberOfRowsInSection:(NSInteger)section{return self.entries.count;}
- (UITableViewCell *)tableView:(UITableView *)table cellForRowAtIndexPath:(NSIndexPath *)idx {
 UITableViewCell *cell=[table dequeueReusableCellWithIdentifier:@"entry"];
 if(!cell)cell=[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"entry"];
 NSString *name=self.entries[(NSUInteger)idx.row];
 NSString *full=[self.path stringByAppendingPathComponent:name];BOOL isDir=NO;
 [[NSFileManager defaultManager] fileExistsAtPath:full isDirectory:&isDir];
 cell.textLabel.text=[NSString stringWithFormat:@"%@ %@",isDir?@"Folder:":@"File:",name];
 cell.textLabel.font=[UIFont systemFontOfSize:14];cell.accessoryType=isDir?UITableViewCellAccessoryDisclosureIndicator:UITableViewCellAccessoryNone;
 return cell;
}
- (void)tableView:(UITableView *)table didSelectRowAtIndexPath:(NSIndexPath *)idx {
 [table deselectRowAtIndexPath:idx animated:YES];
 NSString *full=[self.path stringByAppendingPathComponent:self.entries[(NSUInteger)idx.row]];
 BOOL isDir=NO;[[NSFileManager defaultManager] fileExistsAtPath:full isDirectory:&isDir];
 if(isDir){[self visit:full];return;}
 [self previewFile:full];
}
- (void)previewFile:(NSString *)full {
 __block NSData *data=nil;
 __block NSError *readError=nil;
 NSError *coordinateError=nil;
 NSFileCoordinator *coordinator=[[NSFileCoordinator alloc] initWithFilePresenter:nil];
 [coordinator coordinateReadingItemAtURL:[NSURL fileURLWithPath:full]
  options:0 error:&coordinateError byAccessor:^(NSURL *coordinatedURL) {
    NSFileHandle *handle=[NSFileHandle fileHandleForReadingFromURL:coordinatedURL error:&readError];
    if(handle){data=[handle readDataOfLength:65536];[handle closeFile];}
  }];
 NSError *err=readError?:coordinateError;
 if(!data){self.status.text=[NSString stringWithFormat:@"Cannot open: %@ (code %ld)",err.localizedDescription?:@"Denied",(long)err.code];return;}
 NSString *display=[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
 if(!display){
  NSMutableString *hex=[NSMutableString stringWithString:@"Binary file (first 2 KiB):\n"];
  const uint8_t *bytes=data.bytes;NSUInteger count=MIN(data.length,2048);
  for(NSUInteger i=0;i<count;i++){if(i%16==0)[hex appendFormat:@"\n%04lx: ",(unsigned long)i];[hex appendFormat:@"%02x ",bytes[i]];}
  display=hex;
 }
 self.preview.text=[NSString stringWithFormat:@"%@\n\n%@",full,display?:@""];
 self.preview.hidden=NO;self.status.text=@"Read-only preview; up to 64 KiB";
}
@end

// A normal, user-initiated iPadOS Picture in Picture demo.
// It displays an original bouncing graphic above other apps via the OS.
// No cross-process code injection, sandbox escape, or privileged API use.
@interface FloatingDemoController : UIViewController <AVPictureInPictureControllerDelegate>
@property(nonatomic,strong) UILabel *statusLabel;
@property(nonatomic,strong) UIView *videoView;
@property(nonatomic,strong) AVQueuePlayer *player;
@property(nonatomic,strong) AVPlayerLooper *looper;
@property(nonatomic,strong) AVPlayerLayer *playerLayer;
@property(nonatomic,strong) AVPictureInPictureController *pipController;
@property(nonatomic,assign) BOOL generatingVideo;
@end

@implementation FloatingDemoController
- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"Floating Graphic";
    self.view.backgroundColor = UIColor.systemBackgroundColor;
    UIStackView *stack = [UIStackView new];
    stack.translatesAutoresizingMaskIntoConstraints = NO;
    stack.axis = UILayoutConstraintAxisVertical;
    stack.spacing = 14;
    stack.alignment = UIStackViewAlignmentFill;
    [self.view addSubview:stack];
    [NSLayoutConstraint activateConstraints:@[
        [stack.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor constant:20],
        [stack.leadingAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.leadingAnchor constant:20],
        [stack.trailingAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.trailingAnchor constant:-20]
    ]];

    UILabel *heading = [UILabel new];
    heading.text = @"A floating image over other apps";
    heading.font = [UIFont preferredFontForTextStyle:UIFontTextStyleTitle2];
    heading.numberOfLines = 0;
    [stack addArrangedSubview:heading];

    UILabel *explain = [UILabel new];
    explain.text = @"An animated graphic plays in Apple's Picture in Picture window. It can stay visible when you open another app. This is not tweak injection.";
    explain.numberOfLines = 0;
    explain.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
    [stack addArrangedSubview:explain];

    self.videoView = [UIView new];
    self.videoView.backgroundColor = [UIColor colorWithRed:0.07 green:0.08 blue:0.14 alpha:1];
    self.videoView.layer.cornerRadius = 12;
    self.videoView.clipsToBounds = YES;
    [self.videoView.heightAnchor constraintEqualToConstant:210].active = YES;
    [stack addArrangedSubview:self.videoView];

    self.statusLabel = [UILabel new];
    self.statusLabel.numberOfLines = 0;
    self.statusLabel.font = [UIFont monospacedSystemFontOfSize:13 weight:UIFontWeightRegular];
    self.statusLabel.text = @"Preparing animation...";
    [stack addArrangedSubview:self.statusLabel];

    UIButton *start = [UIButton buttonWithType:UIButtonTypeSystem];
    [start setTitle:@"Start floating picture" forState:UIControlStateNormal];
    [start addTarget:self action:@selector(startPiP:) forControlEvents:UIControlEventTouchUpInside];
    [stack addArrangedSubview:start];

    UIButton *browser = [UIButton buttonWithType:UIButtonTypeSystem];
    [browser setTitle:@"Open read-only file browser" forState:UIControlStateNormal];
    [browser addTarget:self action:@selector(openBrowser:) forControlEvents:UIControlEventTouchUpInside];
    [stack addArrangedSubview:browser];

    if (![AVPictureInPictureController isPictureInPictureSupported]) {
        self.statusLabel.text = @"Picture in Picture is not supported by this device.";
        return;
    }

    NSError *audioError = nil;
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback
                                    withOptions:AVAudioSessionCategoryOptionMixWithOthers
                                          error:&audioError];
    [[AVAudioSession sharedInstance] setActive:YES error:NULL];
    if (audioError) NSLog(@"Audio session setup: %@", audioError);

    NSURL *url = [self animationURL];
    if ([[NSFileManager defaultManager] fileExistsAtPath:url.path]) {
        [self configurePlayerWithURL:url];
    } else {
        [self generateAnimationAtURL:url];
    }
}
- (NSURL *)animationURL {
    return [NSURL fileURLWithPath:[NSTemporaryDirectory() stringByAppendingPathComponent:@"floating-demo.mp4"]];
}
- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    self.playerLayer.frame = self.videoView.bounds;
}
- (void)openBrowser:(id)sender {
    [self.navigationController pushViewController:[BrowserController new] animated:YES];
}
- (void)configurePlayerWithURL:(NSURL *)url {
    self.player = [AVQueuePlayer new];
    self.player.actionAtItemEnd = AVPlayerActionAtItemEndNone;
    AVPlayerItem *item = [AVPlayerItem playerItemWithURL:url];
    self.looper = [AVPlayerLooper playerLooperWithPlayer:self.player templateItem:item];
    self.playerLayer = [AVPlayerLayer playerLayerWithPlayer:self.player];
    self.playerLayer.videoGravity = AVLayerVideoGravityResizeAspect;
    self.playerLayer.frame = self.videoView.bounds;
    [self.videoView.layer addSublayer:self.playerLayer];
    self.pipController = [[AVPictureInPictureController alloc] initWithPlayerLayer:self.playerLayer];
    self.pipController.delegate = self;
    self.pipController.canStartPictureInPictureAutomaticallyFromInline = YES;
    [self.player play];
    self.statusLabel.text = @"Animation playing. Tap Start floating picture. If PiP is not ready yet, tap again after playback begins.";
}
- (void)startPiP:(id)sender {
    if (!self.pipController) {
        self.statusLabel.text = self.generatingVideo ? @"The animation is being created on device." : @"PiP player unavailable.";
        return;
    }
    if (self.pipController.isPictureInPictureActive) {
        self.statusLabel.text = @"Already floating. Switch to another app to see it.";
        return;
    }
    if (!self.pipController.isPictureInPicturePossible) {
        self.statusLabel.text = @"PiP isn't possible yet. Check Settings → Multitasking & Gestures → Picture in Picture, then let the preview play and try again.";
        return;
    }
    [self.pipController startPictureInPicture];
}
- (void)pictureInPictureControllerDidStartPictureInPicture:(AVPictureInPictureController *)controller {
    self.statusLabel.text = @"PiP started. Now go to Home or switch to any other app.";
}
- (void)pictureInPictureController:(AVPictureInPictureController *)controller failedToStartPictureInPictureWithError:(NSError *)error {
    self.statusLabel.text = [NSString stringWithFormat:@"PiP failed: %@ (%ld)", error.localizedDescription, (long)error.code];
}
- (void)pictureInPictureControllerDidStopPictureInPicture:(AVPictureInPictureController *)controller {
    self.statusLabel.text = @"PiP closed. You can start it again.";
}
- (void)generateAnimationAtURL:(NSURL *)url {
    self.generatingVideo = YES;
    self.statusLabel.text = @"Generating a short original video locally (first launch only)...";
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
        [[NSFileManager defaultManager] removeItemAtURL:url error:nil];
        NSError *error = nil;
        AVAssetWriter *writer = [[AVAssetWriter alloc] initWithURL:url fileType:AVFileTypeMPEG4 error:&error];
        if (!writer) {
            dispatch_async(dispatch_get_main_queue(), ^{ weakSelf.generatingVideo=NO;weakSelf.statusLabel.text=[NSString stringWithFormat:@"Video writer error: %@",error.localizedDescription];});
            return;
        }
        const NSInteger width = 640, height = 360;
        const NSInteger frames = 120, fps = 30;
        NSDictionary *settings = @{
            AVVideoCodecKey:AVVideoCodecTypeH264,
            AVVideoWidthKey:@(width),
            AVVideoHeightKey:@(height),
            AVVideoCompressionPropertiesKey:@{AVVideoAverageBitRateKey:@(950000)}
        };
        AVAssetWriterInput *input = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeVideo outputSettings:settings];
        input.expectsMediaDataInRealTime = NO;
        NSDictionary *pixelAttributes = @{
            (NSString *)kCVPixelBufferPixelFormatTypeKey:@(kCVPixelFormatType_32BGRA),
            (NSString *)kCVPixelBufferWidthKey:@(width),
            (NSString *)kCVPixelBufferHeightKey:@(height),
            (NSString *)kCVPixelBufferIOSurfacePropertiesKey:@{}
        };
        AVAssetWriterInputPixelBufferAdaptor *adaptor = [[AVAssetWriterInputPixelBufferAdaptor alloc]
            initWithAssetWriterInput:input sourcePixelBufferAttributes:pixelAttributes];
        if (![writer canAddInput:input]) {
            dispatch_async(dispatch_get_main_queue(), ^{ weakSelf.generatingVideo=NO;weakSelf.statusLabel.text=@"Cannot add video writer input."; });
            return;
        }
        [writer addInput:input];
        if (![writer startWriting]) {
            dispatch_async(dispatch_get_main_queue(), ^{ weakSelf.generatingVideo=NO;weakSelf.statusLabel.text=[NSString stringWithFormat:@"Video encoder failed: %@",writer.error.localizedDescription]; });
            return;
        }
        [writer startSessionAtSourceTime:kCMTimeZero];
        BOOL ok = YES;
        for (NSInteger frame = 0; frame < frames; frame++) {
            while (!input.readyForMoreMediaData && writer.status == AVAssetWriterStatusWriting) {
                [NSThread sleepForTimeInterval:0.01];
            }
            if (writer.status != AVAssetWriterStatusWriting) { ok = NO; break; }
            CVPixelBufferRef pixel = NULL;
            if (!adaptor.pixelBufferPool ||
                CVPixelBufferPoolCreatePixelBuffer(kCFAllocatorDefault, adaptor.pixelBufferPool, &pixel) != kCVReturnSuccess) {
                ok = NO; break;
            }
            CVPixelBufferLockBaseAddress(pixel, 0);
            CGContextRef ctx = CGBitmapContextCreate(
                CVPixelBufferGetBaseAddress(pixel), width, height, 8,
                CVPixelBufferGetBytesPerRow(pixel),
                CGColorSpaceCreateDeviceRGB(),
                kCGImageAlphaPremultipliedFirst | kCGBitmapByteOrder32Little
            );
            if (!ctx) {
                CVPixelBufferUnlockBaseAddress(pixel, 0);
                CVPixelBufferRelease(pixel);
                ok = NO; break;
            }
            CGContextSetRGBFillColor(ctx, 0.035, 0.05, 0.105, 1);
            CGContextFillRect(ctx, CGRectMake(0, 0, width, height));
            // A loopable bouncing cyan-and-white emblem.
            double phase = 2.0 * M_PI * ((double)frame / (double)frames);
            CGFloat centerX = 100.0 + 440.0 * (0.5 + 0.5 * sin(phase));
            CGFloat centerY = 75.0 + 210.0 * (0.5 + 0.5 * cos(2.0 * phase));
            CGContextSetRGBFillColor(ctx, 0.06, 0.75, 0.94, 1);
            CGContextFillEllipseInRect(ctx, CGRectMake(centerX - 54, centerY - 54, 108, 108));
            CGContextSetRGBFillColor(ctx, 1, 1, 1, 1);
            CGContextFillEllipseInRect(ctx, CGRectMake(centerX - 19, centerY - 19, 38, 38));
            CGContextSetRGBStrokeColor(ctx, 0.33, 0.9, 1, 0.7);
            CGContextSetLineWidth(ctx, 5);
            CGContextStrokeRect(ctx, CGRectMake(15, 15, 610, 330));
            CGContextFlush(ctx);
            CGContextRelease(ctx);
            CVPixelBufferUnlockBaseAddress(pixel, 0);
            BOOL appended = [adaptor appendPixelBuffer:pixel withPresentationTime:CMTimeMake(frame, (int32_t)fps)];
            CVPixelBufferRelease(pixel);
            if (!appended) { ok = NO; break; }
        }
        [input markAsFinished];
        if (!ok) {
            [writer cancelWriting];
            dispatch_async(dispatch_get_main_queue(), ^{
                weakSelf.generatingVideo=NO;
                weakSelf.statusLabel.text=[NSString stringWithFormat:@"Video generation failed: %@",writer.error.localizedDescription?:@"encoder/buffer issue"];
            });
            return;
        }
        [writer finishWritingWithCompletionHandler:^{
            dispatch_async(dispatch_get_main_queue(), ^{
                FloatingDemoController *strongSelf = weakSelf;
                if (!strongSelf) return;
                strongSelf.generatingVideo = NO;
                if (writer.status == AVAssetWriterStatusCompleted) {
                    [strongSelf configurePlayerWithURL:url];
                } else {
                    strongSelf.statusLabel.text = [NSString stringWithFormat:@"Video export failed: %@",writer.error.localizedDescription?:@"unknown error"];
                }
            });
        }];
    });
}
@end

@interface ExplorerAppDelegate : UIResponder <UIApplicationDelegate>
@property(nonatomic,strong) UIWindow *window;
@end
@implementation ExplorerAppDelegate
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)options {
 self.window=[[UIWindow alloc] initWithFrame:UIScreen.mainScreen.bounds];
 self.window.rootViewController=[[UINavigationController alloc] initWithRootViewController:[FloatingDemoController new]];
 [self.window makeKeyAndVisible];return YES;
}
@end
int main(int argc,char **argv){@autoreleasepool{return UIApplicationMain(argc,argv,nil,NSStringFromClass([ExplorerAppDelegate class]));}}
