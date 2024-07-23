//
//  AppDelegate.m
//  Bastard
//
//  Created by Christian Gratton on 2013-04-25.
//  Copyright (c) 2013 Christian Gratton. All rights reserved.
//

#import "AppDelegate.h"

#import "EAGLView.h"
#import "OKPoEMM.h"
#import "OKPreloader.h"
#import "OKTextManager.h"
#import "OKAppProperties.h"
#import "OKPoEMMProperties.h"
#import "OKInfoViewProperties.h"

#import "TestFlight.h"

#define IS_IPAD_2 (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad && [UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) // Or more
#define IS_IPHONE_5 (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone && [[UIScreen mainScreen] bounds].size.height == 568.0f)
#define SHOULD_MULTISAMPLE (IS_IPAD_2 || IS_IPHONE_5)

@implementation AppDelegate
@synthesize eaglView;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
#warning comment when building for store
    //[TestFlight setDeviceIdentifier:[[UIDevice currentDevice] uniqueIdentifier]];
    
    // TestFlight
    //[TestFlight takeOff:@"bf45fd34-632d-4449-81d6-1a804ae2f1b4"];
    
    if(![[NSUserDefaults standardUserDefaults] objectForKey:@"fLaunch"])
        [self setDefaultValues];
    
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    
    // Get Screen Bounds
    CGRect sBounds = [[UIScreen mainScreen] bounds];
    CGRect sFrame = CGRectMake(sBounds.origin.x, sBounds.origin.y, sBounds.size.width, sBounds.size.height); // Invert height and width to componsate for portrait launch (these values will be set to determine behaviors/dimensions in EAGLView)
    
    // Set app properties
    [OKAppProperties initWithContentsOfFile:[[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"OKAppProperties.plist"] andOptions:launchOptions];
    [OKPoEMMProperties initWithContentsOfFile:[[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"OKPoEMMProperties.plist"]];
        
    // Helper method
    //[OKPoEMMProperties listProperties];
    
    // Load texts
    BOOL canLoad = YES;
    // Get the id of the last text the user read
    NSString *textKey = [[NSUserDefaults standardUserDefaults] stringForKey:Text];
    
    // Checks if we had a loaded text
    if(textKey != nil)
    {
        //save default key, just in case
        NSString* defaultTextKey = [[OKTextManager sharedInstance] getDefaultPackage];
        
        // Fixes the bug where net.obxlabs.Know.jlewis.Know is replaced by net.obxlabs.Know.jlewis.67 when list is downloaded
        // but no poem is selected. This finds the default poem and returns the right key.
        NSString *appName = [OKAppProperties objectForKey:@"Name"];
        NSString *master = [NSString stringWithFormat:@"net.obxlabs.%@.jlewis.%@", appName, appName];
        if([textKey isEqualToString:master])
            textKey = [[OKTextManager sharedInstance] getDefaultPackage];
        
        //load the text
        if (![[OKTextManager sharedInstance] loadTextFromPackage:textKey atIndex:0]) {
            // try loading custom text
            if(![[OKTextManager sharedInstance] loadCustomTextFromPackage:textKey]) {
                if(![[OKTextManager sharedInstance] loadTextFromPackage:defaultTextKey atIndex:0]) {
                    NSLog(@"Error: could not load any text for package %@ and default package %@. Clearing cache and starting from new.", textKey, defaultTextKey);
                    
                    // Deletes existing file (last hope)
                    [OKTextManager clearCache];
                    
                    // Load new (original)
                    if(![[OKTextManager sharedInstance] loadTextFromPackage:@"net.obxlabs.Bastard.jlewis.Bastard" atIndex:0]) {
                        // Epic fail
                        NSLog(@"Error: Epic fail.");
                        canLoad = NO;
                    }
                }
            }
        }
    } else {
        // Set default text
        if(![[OKTextManager sharedInstance] loadTextFromPackage:@"net.obxlabs.Bastard.jlewis.Bastard" atIndex:0]) {
            NSLog(@"Error: could not load default package. Probably missing some objects (fonts).");
        }
    }
        
    // Show the preloader
    OKPreloader *preloader = [[OKPreloader alloc] initWithFrame:sFrame forApp:self loadOnAppear:canLoad];
    
    // If we can't load a text, show a warning to the user
    if(!canLoad)
    {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"System Error" message:@"It would appear that all app files were corrupted. Please delete and re-install the app and try again." delegate:self cancelButtonTitle:@"Dismiss" otherButtonTitles:nil];
        [alert show];
    }
    
    // Add to window
    [self.window setRootViewController:preloader];
    [self.window makeKeyAndVisible];
    
    return YES;
}

// App properties, set default
- (void) setDefaultValues
{
    [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"exhibition_preference"];
    /* There seems to be an issue with the Bundle Version being 1.0.4 instead of 1.1.4 so I set the default value instead of getting the current one
     [[NSUserDefaults standardUserDefaults] setValue:[[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"] forKey:@"version_preference"];
     */
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"fLaunch"];
    
    [[NSUserDefaults standardUserDefaults] synchronize];
}

// Load the opengl
- (void) loadOKPoEMMInFrame:(CGRect)frame
{
    // Initialize EAGLView (OpenGL)
    eaglView = [[EAGLView alloc] initWithFrame:frame multisampling:SHOULD_MULTISAMPLE andSamples:2];
    
    // Initilaize OKPoEMM (EAGLView, OKInfoView, OKRegistration... wrapper)
    self.poemm = [[OKPoEMM alloc] initWithFrame:frame EAGLView:eaglView isExhibition:[[NSUserDefaults standardUserDefaults] boolForKey:@"exhibition_preference"]];
    
    //Start EAGLView animation
    if(eaglView) [eaglView startAnimation];
    
    [self.window setRootViewController:self.poemm];
    
    if(![[NSUserDefaults standardUserDefaults] stringForKey:@"version"]) [self.poemm openMenuAtTab:MenuRegisterTab];
}

#pragma mark - Life

- (void)applicationWillResignActive:(UIApplication *)application
{
    [eaglView stopAnimation];
    
    [[UIApplication sharedApplication] setIdleTimerDisabled:NO];
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    [eaglView startAnimation];
    [self.poemm setisExhibition:[[NSUserDefaults standardUserDefaults] boolForKey:@"exhibition_preference"]];
    
    [[UIApplication sharedApplication] setIdleTimerDisabled:YES];
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    [eaglView stopAnimation];
    //device can sleep (since we leave)
	[[UIApplication sharedApplication] setIdleTimerDisabled:NO];
}

@end
