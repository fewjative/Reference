#import <UIKit/UIKit.h>

@interface SBReachabilityManager
@end

@interface SBWindow : UIWindow
@end

@interface ReferenceController : UIViewController <UIScrollViewDelegate>{
	
	SBWindow *backgroundWindow;
	UIImageView *lastAppImageView;
	UIView *wrapperView;
	UIScrollView * scrollView;
}

+(instancetype)sharedInstance;
-(void)setBackgroundWindow:(SBWindow*)window;
-(void)setupWidget;
-(void)deconstructWidget;
-(void)setLastAppImageView:(UIImageView*)imageView;
-(void)adjustWidget:(SBWindow*)window setLastAppImageView:(UIImageView*)imageView;
@end