#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <UniformTypeIdentifiers/UniformTypeIdentifiers.h>

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
 NSError *err=nil;
 NSArray *items=[[NSFileManager defaultManager] contentsOfDirectoryAtPath:normalized error:&err];
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
 NSError *err=nil;
 NSFileHandle *handle=[NSFileHandle fileHandleForReadingFromURL:[NSURL fileURLWithPath:full] error:&err];
 if(!handle){self.status.text=[NSString stringWithFormat:@"Cannot open: %@ (code %ld)",err.localizedDescription?:@"Denied",(long)err.code];return;}
 NSData *data=[handle readDataOfLength:65536];[handle closeFile];
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
@interface ExplorerAppDelegate : UIResponder <UIApplicationDelegate>
@property(nonatomic,strong) UIWindow *window;
@end
@implementation ExplorerAppDelegate
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)options {
 self.window=[[UIWindow alloc] initWithFrame:UIScreen.mainScreen.bounds];
 self.window.rootViewController=[[UINavigationController alloc] initWithRootViewController:[BrowserController new]];
 [self.window makeKeyAndVisible];return YES;
}
@end
int main(int argc,char **argv){@autoreleasepool{return UIApplicationMain(argc,argv,nil,NSStringFromClass([ExplorerAppDelegate class]));}}
