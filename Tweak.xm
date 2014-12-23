#import <QuartzCore/QuartzCore.h>
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <substrate.h>
#import "ReferenceController.h"

extern "C" UIImage * _UICreateScreenUIImage();

#define kBundlePath @"/Library/PreferenceBundles/ReferenceSettings.bundle"
#define kDefaultRedColor [[UIColor alloc] initWithRed:1.0f green:0.0f blue:0.0f alpha:0.3f]

static BOOL enabled = NO;
static UIWindow * dragWindow;
static CGPoint firstLocation;
static CGFloat defaultCenterX;
static CGFloat newCenterY = 0.0;
static BOOL runOnce = NO;
static BOOL adjustReachSize = NO;
static BOOL displayDragZone = NO;
static UIColor *dragZoneColor;

@interface SBUIController
@end

static UIColor* parseColorFromPreferences(NSString* string) {
	NSArray *prefsarray = [string componentsSeparatedByString: @":"];
	NSString *hexString = [prefsarray objectAtIndex:0];
	double alpha = [[prefsarray objectAtIndex:1] doubleValue];

	unsigned rgbValue = 0;
    NSScanner *scanner = [NSScanner scannerWithString:hexString];
    [scanner setScanLocation:1]; // bypass '#' character
    [scanner scanHexInt:&rgbValue];
    return [[UIColor alloc] initWithRed:((rgbValue & 0xFF0000) >> 16)/255.0 green:((rgbValue & 0xFF00) >> 8)/255.0 blue:(rgbValue & 0xFF)/255.0 alpha:alpha];
}

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

		if(adjustReachSize)
		{
			if(dragWindow==nil)
			{
				dragWindow = [[UIWindow alloc] initWithFrame:CGRectMake(0,[UIScreen mainScreen].bounds.size.height*.3,768,60)];
				dragWindow.windowLevel = 2003;
				[dragWindow makeKeyAndVisible];
				defaultCenterX = dragWindow.center.x;

				if((dragWindow.center.y + newCenterY) < [UIScreen mainScreen].bounds.size.height*.3)
					newCenterY = 0.0;

				if((dragWindow.center.y + newCenterY) > [UIScreen mainScreen].bounds.size.height*.6)
					newCenterY = [UIScreen mainScreen].bounds.size.height*.3;

				dragWindow.center = CGPointMake(defaultCenterX,dragWindow.center.y+newCenterY);
				NSLog(@"Center: %@",NSStringFromCGPoint(dragWindow.center));
				
				if(displayDragZone 	&& MSHookIvar<SBWindow*>(self,"_reachabilityWindow"))
				{
					dragWindow.backgroundColor = dragZoneColor;
				}
				else
					dragWindow.backgroundColor = [UIColor clearColor];

				UIPanGestureRecognizer * pangr = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
				[dragWindow addGestureRecognizer: pangr];
			}

			[self adjustFrames:dragWindow.center];
		}
		else
		{
			SBWindow *effectWindow = MSHookIvar<SBWindow*>(self,"_reachabilityEffectWindow");
			[[ReferenceController sharedInstance] adjustWidget:effectWindow setLastAppImageView:[self lastAppImageView]];
		}
	}
}

-(void)handleReachabilityModeDeactivated {
	%orig;
	if (enabled && [%c(SBReachabilityManager) reachabilitySupported]) {
		[[ReferenceController sharedInstance] deconstructWidget];

		if(adjustReachSize)
		{
			dragWindow.hidden = YES;
			[dragWindow release];
			dragWindow = nil;
		}
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

		[UIView animateWithDuration:0.5 animations:^(void){
			dragWindow.alpha = 0;
		}];
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
	else if(uigr.state==UIGestureRecognizerStateEnded)
	{
		[UIView animateWithDuration:0.5 animations:^(void){
			dragWindow.alpha = 1;
		}];
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
    ////UIImageWriteToSavedPhotosAlbum(imageView, nil, nil, nil); //if you need to save
    //UIImage *screenImage = _UICreateScreenUIImage();
   	// CGImageRef imageRef = CGImageCreateWithImageInRect(screenImage.CGImage, [[UIApplication sharedApplication] keyWindow].bounds);
    //UIImage * imageView = [UIImage imageWithCGImage:imageRef];
    NSBundle *bundle = [[[NSBundle alloc] initWithPath:kBundlePath] autorelease];
    NSString * direc = [bundle resourcePath];
    NSString * savePath = [NSString stringWithFormat:@"%@%@",direc,@"/lastAppImage.png"];
    [UIImagePNGRepresentation(imageView) writeToFile:savePath atomically:YES];
    //[imageRef release];
    //[screenImage release];
    [imageView release];
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

    adjustReachSize = !CFPreferencesCopyAppValue(CFSTR("adjustReachSize"), CFSTR("com.joshdoctors.reference")) ? NO : [(id)CFPreferencesCopyAppValue(CFSTR("adjustReachSize"), CFSTR("com.joshdoctors.reference")) boolValue];
    
    displayDragZone = !CFPreferencesCopyAppValue(CFSTR("displayDragZone"), CFSTR("com.joshdoctors.reference")) ? NO : [(id)CFPreferencesCopyAppValue(CFSTR("displayDragZone"), CFSTR("com.joshdoctors.reference")) boolValue];

    dragZoneColor = !CFPreferencesCopyAppValue(CFSTR("dragZoneColor"), CFSTR("com.joshdoctors.reference")) ? kDefaultRedColor : parseColorFromPreferences((id)CFPreferencesCopyAppValue(CFSTR("dragZoneColor"), CFSTR("com.joshdoctors.reference")));
    
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