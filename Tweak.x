#import <dlfcn.h>
#import "Shortcuts.h"

@interface WFManager : NSObject{
	WFWorkflowController *_controller;
	WFConcreteUIKitUserInterface *_ui;
	WFDatabase *_database;
}
@property (nonatomic, assign) WFConcreteUIKitUserInterface *ui;
@property (nonatomic, assign) WFDatabase *database;
@end

NSString *docs;

@implementation WFManager
+(WFManager *)sharedManager{
    static WFManager *sharedManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedManager = [WFManager new];
    });
    return sharedManager;
}
-(id)init{
	if(self == [super init]){
		_controller = [%c(WFWorkflowController) new];
        _ui = [%c(WFConcreteUIKitUserInterface) new];
        WFRealmDatabaseConfiguration *config = [%c(WFRealmDatabaseConfiguration) systemShortcutsConfiguration];
        //We need write access to ~/Library/Shortcuts, this is a bad workaround.
        /*NSString *readableRealm = [docs stringByAppendingPathComponent:@"Shortcuts/Shortcuts.realm"];
        config.realmConfiguration.fileURL = [NSURL fileURLWithPath:readableRealm];*/
        _database = [[%c(WFDatabase) alloc] initWithBackingStore:[[%c(WFRealmDatabase) alloc] initWithConfiguration:config mainThreadOnly:false error:nil]];
	}
	return self;
}
-(void)runWorkflow:(WFWorkflowReference *)reference{
	if([_controller isRunning]){
        _controller = nil;
        _controller = [%c(WFWorkflowController) new];
    }
	[_controller setWorkflow:[%c(WFWorkflow) workflowWithReference:reference storageProvider:_database error:nil]];
	[_controller run];
}
-(void)runWorkflowWithIdentifier:(NSString *)identifier{
	for(WFWorkflowReference *reference in [self workflows])
		if([reference.identifier isEqualToString:identifier])
			[self runWorkflow:reference];
}
-(NSDictionary *)infoTest{
	for(WFWorkflowReference *workflow in [self workflows])
		if([workflow.name isEqualToString:@"Test"])
			return [workflow infoDictionary];
	return nil;
}
-(void)runTest{
	for(WFWorkflowReference *workflow in [self workflows])
		if([workflow.name isEqualToString:@"Test"])
			[self runWorkflow:workflow];
}
-(WFConcreteUIKitUserInterface *)ui{
	return _ui;
}
-(void)setUi:(WFConcreteUIKitUserInterface *)ui{
	_ui = ui;
}
-(WFDatabase *)database{
	return _database;
}
-(void)setDatabase:(WFDatabase *)database{
	_database = database;
}
-(NSArray *)workflows{
	NSArray *refs = [[[_database backingStore] sortedVisibleWorkflows] descriptors];
	return refs;
}
@end

%group SpringBoard

%hook WFAction
-(void)runWithInput:(id)input userInterface:(id)ui parameterInputProvider:(id)provider variableSource:(id)source completionHandler:(id)completion{
	if(!ui)
		ui = [WFManager sharedManager].ui;
	%orig;
}
%end

%hook WFDatabase
+(WFDatabase *)defaultDatabase{
	WFDatabase *orig = %orig;
	if(!orig)
		return [[WFManager sharedManager] database];
	return orig;
}
%end

%hook WFConcreteUIKitUserInterface
-(UIView *)view{
	UIView *orig = %orig;
	if(!orig)
		return [UIApplication sharedApplication].keyWindow;
	return orig;
}
-(UIViewController *)viewController{
	UIViewController *orig = %orig;
	if(!orig){
		UIViewController *topController = [UIApplication sharedApplication].keyWindow.rootViewController;
	    while(topController.presentedViewController){
	        topController = topController.presentedViewController;
	    }
		return topController;
	}
	return orig;
}
%end

%hook WFWorkflowReference
%new
-(NSDictionary *)infoDictionary{
	NSString *identifier = self.identifier;
	NSString *name = self.name;
	WFWorkflowIcon *icon = self.icon;
	UIImage *glyph = [%c(WFWorkflowIconDrawer) glyphImageWithIcon:icon size:CGSizeMake(60, 60)];
	UIImage *image = [%c(WFWorkflowIconDrawer) imageWithIcon:icon size:CGSizeMake(60, 60)].UIImage;
	UIColor *baseColor = icon.backgroundColor.paletteGradient.baseColor.UIColor;
	return @{@"identifier": identifier, @"name": name, @"icon": icon,@"glyph": glyph, @"image": image, @"baseColor": baseColor};
}
%new
-(void)run{
	[[WFManager sharedManager] runWorkflow:self];
}
-(NSString *)description{
	return [NSString stringWithFormat:@"%@ %@", self.name, %orig];
}
%end

%end

%group Shortcuts

%hook WFCloudKitSyncSession
-(BOOL)saveIncomingChanges:(id)arg1 incomingDeletes:(id)arg2 conflicts:(id)arg3 mergedOrderedWorkflowIDs:(id)arg4 sentChanges:(id)arg5 sentDeletes:(id)arg6 sentOrdering:(BOOL)arg7 saveOrderingLocally:(BOOL)arg8 isOrderingEnabled:(BOOL)arg9 localWorkflowsToDelete:(id)arg10 workflowIDsToRename:(id)arg11 preSyncHashes:(id)arg12 serverChangeToken:(id)arg13 inDatabase:(id)arg14{
	BOOL orig = %orig;
	//Save changes to readable path
	/*NSString *origPath = @"/var/mobile/Library/Shortcuts";
	NSString *readPath = [docs stringByAppendingPathComponent:@"Shortcuts"];
	NSFileManager *fm = [NSFileManager defaultManager];
	[fm removeItemAtPath:readPath error:nil];
	[fm copyItemAtPath:origPath toPath:readPath error:nil];*/
    return orig;
}
%end

%end

%ctor{
	dlopen("/System/Library/PrivateFrameworks/WorkflowKit.framework/WorkflowKit", RTLD_NOW);
	dlopen("/System/Library/PrivateFrameworks/WorkflowUI.framework/WorkflowUI", RTLD_NOW);
	dlopen("/System/Library/PrivateFrameworks/ActionKit.framework/ActionKit", RTLD_NOW);
	dlopen("/System/Library/PrivateFrameworks/ActionKitUI.framework/ActionKitUI", RTLD_NOW);
	if([[NSBundle mainBundle].bundleIdentifier isEqualToString:@"com.apple.springboard"]){
		docs = [[%c(LSApplicationProxy) applicationProxyForIdentifier:@"com.apple.shortcuts"].containerURL.path stringByAppendingPathComponent:@"Documents"];
		%init(SpringBoard);
	}
	else{
		docs = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
		%init(Shortcuts);
	}
}