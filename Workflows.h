@interface LSBundleProxy
@property (nonatomic, readonly) NSURL *containerURL;
@end

@interface LSApplicationProxy : LSBundleProxy
+(LSApplicationProxy *)applicationProxyForIdentifier:(NSString *)bundleIdentifier;
@end

@interface WFGradient : NSObject
@end

@interface WFColor : NSObject
@property (nonatomic, readonly) UIColor *UIColor;
@property (nonatomic, readonly) NSString *hexValue;
@property (nonatomic, readonly) WFGradient *paletteGradient;
@end

@interface WFGradient (Base)
@property (nonatomic, readonly) WFColor *baseColor;
@end

@interface WFImage : NSObject
@property (nonatomic, readonly) UIImage *UIImage;
@end

@interface WFWorkflowIcon : NSObject
@property (nonatomic, readonly) WFColor *backgroundColor;
@end

@interface WFWorkflowIconDrawer : NSObject
+(UIImage *)glyphImageWithIcon:(WFWorkflowIcon *)icon size:(CGSize)size;
+(WFImage *)imageWithIcon:(WFWorkflowIcon *)icon size:(CGSize)size;
@end

@interface WFConcreteUIKitUserInterface : NSObject
-(id)initWithViewController:(UIViewController *)viewController;
@end

@interface RLMRealm : NSObject
+(RLMRealm *)defaultRealm;
@end

@interface RLMRealmConfiguration : NSObject
@property (nonatomic, assign) NSURL *fileURL;
@end

@interface WFRealmDatabaseConfiguration : NSObject
@property (nonatomic, assign) RLMRealmConfiguration *realmConfiguration;
+(WFRealmDatabaseConfiguration *)systemShortcutsConfiguration;
@end

@interface WFRealmDatabaseResult : NSObject
-(NSArray *)descriptors;
@end

@interface WFRealmDatabase : NSObject
-(WFRealmDatabaseResult *)sortedVisibleWorkflows;
-(id)initWithConfiguration:(id)config mainThreadOnly:(BOOL)main error:(NSError *)error;
@end

@interface WFDatabase : NSObject
+(WFDatabase *)defaultDatabase;
-(WFRealmDatabase *)backingStore;
-(id)initWithBackingStore:(WFRealmDatabase *)backingStore;
@end

@interface WFDatabaseObjectDescriptor : NSObject
@property (nonatomic, readonly) NSString *identifier;
@end

@interface WFWorkflowReference : WFDatabaseObjectDescriptor
@property (nonatomic, readonly) NSString *name;
@property (nonatomic, readonly) NSString *subtitle;
@property (nonatomic, readonly) WFWorkflowIcon *icon;
-(NSDictionary *)infoDictionary;
@end

@interface WFWorkflow : NSObject
+(WFWorkflow *)workflowWithReference:(id)reference storageProvider:(WFDatabase *)provider error:(NSError *)error;
@end

@interface WFWorkflowController : NSObject
@property (nonatomic, assign) WFWorkflow *workflow;
-(BOOL)isRunning;
-(void)run;
@end
