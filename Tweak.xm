#import <QuartzCore/QuartzCore.h>
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <substrate.h>
#import "ReferenceController.h"

#define kBundlePath @"/Library/PreferenceBundles/ReferenceSettings.bundle"

static BOOL enabled = NO;
static UIWindow * dragWindow;
static CGPoint firstLocation;
static CGFloat defaultCenterX;
static CGFloat newCenterY = 0.0;
static BOOL runOnce = NO;

@interface SBUIController
@end

%hook UIWindow

-(void)setFrame:(CGRect)frame {
	NSLog(@"Frame: %@",NSStringFromCGRect(frame));
	%orig;
}

%end

%hook SBWorkspace

-(void)handleReachabilityModeActivated {
	%orig;
	if (enabled && [%c(SBReachabilityManager) reachabilitySupported]) {

		if(dragWindow==nil)
		{
			dragWindow = [[UIWindow alloc] initWithFrame:CGRectMake(0,[UIScreen mainScreen].bounds.size.height*.3,768,30)];
			dragWindow.windowLevel = 2003;
			[dragWindow makeKeyAndVisible];
			defaultCenterX = dragWindow.center.x;

			if((dragWindow.center.y + newCenterY) < [UIScreen mainScreen].bounds.size.height*.3)
				newCenterY = 0.0;

			if((dragWindow.center.y + newCenterY) > [UIScreen mainScreen].bounds.size.height*.6)
				newCenterY = [UIScreen mainScreen].bounds.size.height*.3;

			dragWindow.center = CGPointMake(defaultCenterX,dragWindow.center.y+newCenterY);
			NSLog(@"Center: %@",NSStringFromCGPoint(dragWindow.center));
			
			dragWindow.backgroundColor = [UIColor redColor];
			UIPanGestureRecognizer * pangr = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
			[dragWindow addGestureRecognizer: pangr];
		}

		[self adjustFrames:dragWindow.center];
	}
}

-(void)handleReachabilityModeDeactivated {
	%orig;
	if (enabled && [%c(SBReachabilityManager) reachabilitySupported]) {
		[[ReferenceController sharedInstance] deconstructWidget];
		dragWindow.hidden = YES;
		[dragWindow release];
		dragWindow = nil;
		NSLog(@"Deconstuction and removal success.");
	}
}

%new - (UIImageView*)lastAppImageView
{
	NSBundle *bundle = [[[NSBundle alloc] initWithPath:kBundlePath] autorelease];
	NSString *imagePath = [bundle pathForResource:@"lastAppImage" ofType:@"png"];
	UIImage *image = [UIImage imageWithContentsOfFile:imagePath];
	UIImageView *imageView = [[UIImageView alloc] initWithImage: image];
	return imageView;
}

%new -(void)handlePan:(UIPanGestureRecognizer*)uigr
{
	NSLog(@"Handling pan");
	if(uigr.state==UIGestureRecognizerStateBegan)
	{
		NSLog(@"firstLocation");
		firstLocation = [uigr locationInView:dragWindow];
		firstLocation.y = newCenterY + [UIScreen mainScreen].bounds.size.height*.3;
		NSLog(@"first loc: %@",NSStringFromCGPoint(firstLocation));
	}
	else if(uigr.state==UIGestureRecognizerStateChanged)
	{
		NSLog(@"translation");
		CGPoint translation = [uigr translationInView:dragWindow];

		if((firstLocation.y + translation.y) < [UIScreen mainScreen].bounds.size.height*.3)
		{
			dragWindow.center = CGPointMake(defaultCenterX,[UIScreen mainScreen].bounds.size.height*.3);
			newCenterY = 0.0;
		}
		else if((firstLocation.y + translation.y) > [UIScreen mainScreen].bounds.size.height*.6)
		{
			dragWindow.center = CGPointMake(defaultCenterX,[UIScreen mainScreen].bounds.size.height*.6);
			newCenterY = [UIScreen mainScreen].bounds.size.height*.3;
		}
		else
		{
			dragWindow.center = CGPointMake(defaultCenterX, firstLocation.y + translation.y);
			newCenterY = translation.y;
		}

		[self adjustFrames:dragWindow.center];
	}
}

%new -(void)adjustFrames:(CGPoint)center
{
		SBWindow *effectWindow = MSHookIvar<SBWindow*>(self,"_reachabilityEffectWindow");
		CGRect newEWFrame = CGRectMake(effectWindow.frame.origin.x,effectWindow.frame.origin.y,effectWindow.frame.size.width,center.y);
		[effectWindow setFrame:newEWFrame];

		SBWindow *defaultWindow = MSHookIvar<SBWindow*>(self,"_reachabilityWindow");
		CGRect newDWFrame = CGRectMake(defaultWindow.frame.origin.x,center.y,defaultWindow.frame.size.width,defaultWindow.frame.size.height);
		[defaultWindow setFrame:newDWFrame];
		[[ReferenceController sharedInstance] adjustWidget:effectWindow setLastAppImageView:[self lastAppImageView]];
}

%end

%hook UIApplication

-(id)init
{
	NSLog(@"uiapp - Init");
	id orig = %orig;
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appWillResignActive:) name:UIApplicationWillResignActiveNotification object:nil];
    return orig;
}

%new -(void)capture{

    UIGraphicsBeginImageContext([[UIApplication sharedApplication] keyWindow].bounds.size);
    [[[UIApplication sharedApplication] keyWindow].layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *imageView = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    //UIImageWriteToSavedPhotosAlbum(imageView, nil, nil, nil); //if you need to save
    NSBundle *bundle = [[[NSBundle alloc] initWithPath:kBundlePath] autorelease];
    NSString * direc = [bundle resourcePath];
    NSString * savePath = [NSString stringWithFormat:@"%@%@",direc,@"/lastAppImage.png"];
    [UIImagePNGRepresentation(imageView) writeToFile:savePath atomically:YES];
}


%new - (void)appWillResignActive:(id)note
{
	NSLog(@"uiapp - App is going to the background.");
	[self capture];
}

-(BOOL)_saveSnapshotWithName:(id)arg1
{
	NSLog(@"_saveSnapshotWithName, %@",arg1);
	return %orig;
}

%end

%hook SBReachabilitySettings

-(void)setYOffsetFactor:(CGFloat)offset
{
	NSLog(@"setYOffsetFactor: %f",offset);
	%orig;
}

-(CGFloat)yOffsetFactor
{
	CGFloat orig = %orig;
	NSLog(@"yOffsetFactor: %f",orig);
	return orig;
}

%end

static void loadPrefs() 
{
	NSLog(@"Loading Reference prefs");
    CFPreferencesAppSynchronize(CFSTR("com.joshdoctors.reference"));

    enabled = !CFPreferencesCopyAppValue(CFSTR("enabled"), CFSTR("com.joshdoctors.reference")) ? NO : [(id)CFPreferencesCopyAppValue(CFSTR("enabled"), CFSTR("com.joshdoctors.reference")) boolValue];
    if (enabled) {
        NSLog(@"[Reference] We are enabled");
    } else {
        NSLog(@"[Reference] We are NOT enabled");
    }
}

%ctor
{
	NSLog(@"Loading Reference");
	CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(),
                                NULL,
                                (CFNotificationCallback)loadPrefs,
                                CFSTR("com.joshdoctors.reference/settingschanged"),
                                NULL,
                                CFNotificationSuspensionBehaviorDeliverImmediately);
	loadPrefs();
}