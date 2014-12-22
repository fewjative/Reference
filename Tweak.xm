#import <QuartzCore/QuartzCore.h>
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <substrate.h>
#import "ReferenceController.h"

#define kBundlePath @"/Library/PreferenceBundles/ReferenceSettings.bundle"

static BOOL enabled = NO;

@interface SBUIController
@end

%hook SBWorkspace

-(void)handleReachabilityModeActivated {
	%orig;
	if (enabled && [%c(SBReachabilityManager) reachabilitySupported]) {

		SBWindow *backgroundView = MSHookIvar<SBWindow*>(self,"_reachabilityEffectWindow");
		[[ReferenceController sharedInstance] setBackgroundWindow:backgroundView];
		[[ReferenceController sharedInstance] setLastAppImageView:[self lastAppImageView]];
		[[ReferenceController sharedInstance] setupWidget];
		NSLog(@"Creation and addition success.");
	}
}

-(void)handleReachabilityModeDeactivated {
	%orig;
	if (enabled && [%c(SBReachabilityManager) reachabilitySupported]) {
		[[ReferenceController sharedInstance] deconstructWidget];
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