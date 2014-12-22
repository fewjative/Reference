#import "ReferenceController.h"
#import <QuartzCore/QuartzCore.h>

static bool manualMode = NO;

@implementation ReferenceController

//Shared Instance
+(instancetype)sharedInstance {
	static dispatch_once_t pred;
	static ReferenceController *shared = nil;
	 
	dispatch_once(&pred, ^{
		shared = [[ReferenceController alloc] init];
	});
	return shared;
}

//Widget setup
-(void)setBackgroundWindow:(SBWindow*)window {
	backgroundWindow = window;
}

-(void)setLastAppImageView:(UIImageView*)imageView{
	lastAppImageView = imageView;
}

-(void)setupWidget {
	NSLog(@"setupWidget");

	if (backgroundWindow && lastAppImageView) {

		UIView *wrapperView = [[UIView alloc] initWithFrame:backgroundWindow.bounds];
		UIScrollView *scrollView = [[UIScrollView alloc] initWithFrame:wrapperView.frame];

	   	[scrollView addSubview:lastAppImageView];

	    scrollView.contentSize = lastAppImageView.image.size;
	    [scrollView setScrollEnabled:YES];
	    [scrollView setUserInteractionEnabled:YES];
	    [scrollView setDelaysContentTouches:YES];
	    [scrollView setCanCancelContentTouches:NO];
		[scrollView setDelegate:self];

		[wrapperView addSubview:scrollView];
		[scrollView release];
		NSLog(@"WrapperView :%@",wrapperView);
		[wrapperView setUserInteractionEnabled:YES];
		[backgroundWindow addSubview:wrapperView];
		[backgroundWindow setUserInteractionEnabled:YES];
		wrapperView.tag = 111222;
		[wrapperView release];

		manualMode = !CFPreferencesCopyAppValue(CFSTR("manualMode"), CFSTR("com.joshdoctors.reference")) ? NO : [(id)CFPreferencesCopyAppValue(CFSTR("manualMode"), CFSTR("com.joshdoctors.reference")) boolValue];
    
		if(manualMode) {

			NSLog(@"Manual Mode Activated");
			[[objc_getClass("SBReachabilityManager") sharedInstance] disableExpirationTimerForInteraction];
		}
	}
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {

	manualMode = !CFPreferencesCopyAppValue(CFSTR("manualMode"), CFSTR("com.joshdoctors.reference")) ? NO : [(id)CFPreferencesCopyAppValue(CFSTR("manualMode"), CFSTR("com.joshdoctors.reference")) boolValue];
    
	if (!manualMode) {
		[[objc_getClass("SBReachabilityManager") sharedInstance] _setKeepAliveTimerForDuration:2.0];
	} else {
		[[objc_getClass("SBReachabilityManager") sharedInstance] disableExpirationTimerForInteraction];
	}
}

//Adios widget
-(void)deconstructWidget {

	NSLog(@"deconstructWidget");

	if (lastAppImageView) {
		[lastAppImageView removeFromSuperview];
	}

	UIView * removeWrapperView = [backgroundWindow viewWithTag:111222];
	if(removeWrapperView)
	{
		[removeWrapperView removeFromSuperview];
	}

	[lastAppImageView release];
	lastAppImageView = nil;
}

@end