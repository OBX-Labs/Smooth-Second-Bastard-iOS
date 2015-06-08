//
//  OKAppProperties.h
//  ObxKit
//
//  Created by Bruno Nadeau on 10-11-12.
//  Copyright 2010 Obx Labs. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString* const OKAppName;
extern NSString* const OKAppVersion;

//
// Generic utility to load device specific properties.
// The idea is to store two (or more) plist files, one for iPhone/iPod
// and one for iPad, load them as soon as the application
// finished loading, and then access the values from anywhere.
//
@interface OKAppProperties : NSObject {
	NSMutableDictionary* properties;    //the properties
	BOOL pad;                           //true if the app is running on the pad
	BOOL pushed;                        //true if the app was launched by a push
	float scale;                        //scale factor of the device (for retina check)
}

@property (nonatomic, retain) NSMutableDictionary* properties;
@property (nonatomic, getter=isPad) BOOL pad;
@property (nonatomic, getter=wasPushed) BOOL pushed;
@property (nonatomic) float scale;

//init and memory management
+ (OKAppProperties*)sharedInstance;
+ (id)allocWithZone:(NSZone*)zone;
- (id)copyWithZone:(NSZone*) zone;
- (id)retain;
- (unsigned)retainCount;
- (void)release;
- (id)autorelease;

//init the properties with a plist
+ (void)initWithContentsOfFile:(NSString*)path andOptions:(NSDictionary*)options ;

//retreive a property value from the singleton
+ (id)objectForKey:(id)aKey;
+ (void)setObject:(id)anObject forKey:(id)aKey;

//check if the os is above or equal to the passed version
+ (BOOL)osGreaterOrEqualThan:(NSString*)version;

//get the app name string concatenated with the app version string
+ (NSString*)appNameAndVersion;

//check if the app is running on the pad
+ (BOOL)isPad;

@end
