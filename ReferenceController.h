#import <UIKit/UIKit.h>

@interface SBReachabilityManager
@end

@interface SBWindow : UIWindow
@end

@interface ReferenceController : UIViewController <UIScrollViewDelegate>{
	
	SBWindow *backgroundWindow;
	UIImageView *lastAppImageView;
}

+(instancetype)sharedInstance;
-(void)setBackgroundWindow:(SBWindow*)window;
-(void)setupWidget;
-(void)deconstructWidget;
-(void)setLastAppImageView:(UIImageView*)imageView;
@end