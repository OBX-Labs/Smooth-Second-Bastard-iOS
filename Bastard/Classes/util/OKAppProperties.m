//
//  OKAppProperties.m
//  ObxKit
//
//  Created by Bruno Nadeau on 10-11-12.
//  Copyright 2010 Obx Labs. All rights reserved.
//

#import "OKAppProperties.h"

NSString* const OKAppName = @"AppName";
NSString* const OKAppVersion = @"AppVersion";

//the shared instance
static OKAppProperties *sharedInstance = nil;

@implementation OKAppProperties

@synthesize properties;
@synthesize pad;
@synthesize scale;
@synthesize pushed;

+ (OKAppProperties*)sharedInstance
{
	@synchronized(self)
	{
		if (sharedInstance == nil) {
			sharedInstance = [[OKAppProperties alloc] init];
			sharedInstance.pad = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad);
			sharedInstance.pushed = FALSE;
			sharedInstance.scale = 1;
            
            //detect if we have a retina device
            if([[UIScreen mainScreen] respondsToSelector:NSSelectorFromString(@"scale")])
            {
                if ([[UIScreen mainScreen] scale] > 1.9){
                    [sharedInstance setScale:2];
                }
            }
		}
	}
	return sharedInstance;
}

+ (id)allocWithZone:(NSZone*)zone
{
	@synchronized(self)
	{
		if (sharedInstance == nil) {
			sharedInstance = [super allocWithZone:zone];
			sharedInstance.pad = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad);
			sharedInstance.pushed = FALSE;
			sharedInstance.scale = 1;
            
            //detect if we have a retina device
            if([[UIScreen mainScreen] respondsToSelector:NSSelectorFromString(@"scale")])
            {
                if ([[UIScreen mainScreen] scale] > 1.9){
                    [sharedInstance setScale:2];
                }
            }
            
			return sharedInstance;
		}
	}
	return nil;
}

- (id)copyWithZone:(NSZone*) zone
{
	return self;
}

- (id)retain
{
	return self;
}

- (unsigned)retainCount
{
	return UINT_MAX;
}

- (void)release
{
	//do nothing
}

- (id)autorelease
{
	return self;
}

+ (void)initWithContentsOfFile:(NSString*)path andOptions:(NSDictionary*)options
{
	[OKAppProperties sharedInstance].properties = [[NSMutableDictionary alloc] initWithContentsOfFile:path];
    
    //check if app was lauched with remote notification
    NSDictionary *remoteNotif = [options objectForKey:UIApplicationLaunchOptionsRemoteNotificationKey];
	[OKAppProperties sharedInstance].pushed = (remoteNotif != nil);
}

+ (id)objectForKey:(id)aKey
{
	return [[OKAppProperties sharedInstance].properties objectForKey:aKey];
}

+ (void)setObject:(id)anObject forKey:(id)aKey
{
	[[OKAppProperties sharedInstance].properties setObject:anObject forKey:aKey];
}

+ (BOOL)osGreaterOrEqualThan:(NSString*)version
{
    NSString* currVersion = [[UIDevice currentDevice] systemVersion];
    return ([currVersion compare:version options:NSNumericSearch] != NSOrderedAscending);
}

+ (NSString*)appNameAndVersion
{
    NSString* appName = [(NSString*)[OKAppProperties objectForKey:OKAppName] stringByAppendingString:@"_"];
    NSString* appVersion = (NSString*)[OKAppProperties objectForKey:OKAppVersion];
    return [appName stringByAppendingString:appVersion];
}

+ (BOOL)isPad
{
    return [[OKAppProperties sharedInstance] isPad];
}

@end
