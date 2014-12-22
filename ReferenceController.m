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
-(void)setupWidget {
	NSLog(@"setupWidget");

	if (backgroundWindow && lastAppImageView) {

		if(!wrapperView)
			wrapperView = [[UIView alloc] initWithFrame:backgroundWindow.bounds];
		else
			[wrapperView setFrame:backgroundWindow.bounds];

		if(!scrollView)
			scrollView = [[UIScrollView alloc] initWithFrame:wrapperView.frame];
		else
			[scrollView setFrame:wrapperView.frame];

		NSLog(@"wrapperView: %@",wrapperView);
		NSLog(@"scrollView: %@",scrollView);
		NSLog(@"lastAppImageView: %@", lastAppImageView);

	   	[scrollView addSubview:lastAppImageView];

	    scrollView.contentSize = lastAppImageView.image.size;
	    [scrollView setScrollEnabled:YES];
	    [scrollView setUserInteractionEnabled:YES];
	    [scrollView setDelaysContentTouches:YES];
	    [scrollView setCanCancelContentTouches:NO];
		[scrollView setDelegate:self];

		wrapperView.tag = 111222;
		[wrapperView addSubview:scrollView];

		[backgroundWindow addSubview:wrapperView];

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

-(void)adjustWidget:(SBWindow*)window setLastAppImageView:(UIImageView*)imageView
{
	NSLog(@"Adjusting widget");
	backgroundWindow = window;

	if (lastAppImageView) {
		[lastAppImageView removeFromSuperview];
	}
	else
	{
		lastAppImageView = imageView;
	}

	if (scrollView) {
		[scrollView removeFromSuperview];
	}

	if (wrapperView) {
		[wrapperView removeFromSuperview];
	}
	[self setupWidget];
}

//Adios widget
-(void)deconstructWidget {

	NSLog(@"deconstructWidget");

	if (lastAppImageView) {
		[lastAppImageView removeFromSuperview];
		[lastAppImageView release];
		lastAppImageView = nil;
	}

	if (scrollView) {
		[scrollView removeFromSuperview];
		[scrollView release];
		scrollView = nil;
	}

	if (wrapperView) {
		[wrapperView removeFromSuperview];
		[wrapperView release];
		wrapperView = nil;
	}
}

@end