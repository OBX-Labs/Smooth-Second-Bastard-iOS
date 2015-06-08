//
//  OKPoEMMProperties.h
//  OKPoEMM
//
//  Created by Christian Gratton on 2013-02-18.
//  Copyright (c) 2013 Christian Gratton. All rights reserved.
//

#import "OKAppProperties.h"

// Properties name constants of static parameters (plist)
// These values can be used throughout different poemm apps, they should not change
extern NSString* const Text; // current package
extern NSString* const Title;
extern NSString* const Default;
extern NSString* const TextFile;
extern NSString* const TextVersion;
extern NSString* const AuthorImage;
extern NSString* const FontFile;
extern NSString* const FontOutlineFile;
extern NSString* const FontTessellationFile;

// This will be unique to each poemm app, you will need to create a unique property for each different value that appears in the plist

// Smooth.mm
extern NSString* const TessDetailLow;
extern NSString* const TessDetailHigh;
extern NSString* const FontSentenceOpacity;
extern NSString* const TotalBackgroundGlyphs;
extern NSString* const TouchOffset;
// TessSentence.m
extern NSString* const ApproachSpeed;
extern NSString* const ApproachThreshold;
extern NSString* const UnfoldRepeat;
extern NSString* const UnfoldSpeedDecay;
extern NSString* const UnfoldSpeed;
extern NSString* const FoldRepeat;
extern NSString* const FoldSpeedDecay;
extern NSString* const FoldSpeed;
extern NSString* const SentenceExtractPushStrength;
extern NSString* const SentenceExtractPushSpinMin;
extern NSString* const SentenceExtractPushSpinMax;
extern NSString* const SentenceExtractPushAngle;
extern NSString* const CtrlPtFriction;
extern NSString* const CtrlPtSpeed;
extern NSString* const SnapFriction;
extern NSString* const SnapSpeed;
extern NSString* const MiddleWordScale;
extern NSString* const MiddleWordScaleSpeed;
extern NSString* const MiddleWordScaleFriction;
extern NSString* const MiddleWordOpacity;
// TessWord.m
extern NSString* const WordWanderThreshold;
extern NSString* const WordExtractPushStrength;
extern NSString* const WordExtractPushSpinMin;
extern NSString* const WordExtractPushSpinMax;
extern NSString* const WordExtractPushAngle;
extern NSString* const WordFadeSpeed;
extern NSString* const MiddleWordWanderRange;
extern NSString* const MiddleWordWanderSpeed;
extern NSString* const BackgroundGlyphScale;
extern NSString* const BackgroundGlyphScaleSpeed;
extern NSString* const BackgroundGlyphScaleFriction;
extern NSString* const BackgroundGlyphOpacity;
// TessGlyph.m
extern NSString* const GlyphWanderThreshold;
extern NSString* const GlyphWanderFriction;
extern NSString* const GlyphFadeSpeed;
extern NSString* const BackgroundGlyphWanderRange;
extern NSString* const BackgroundGlyphWanderSpeed;

// Property name constant of dynamic paramaters
extern NSString* const Orientation;
extern NSString* const UprightAngle;

@interface OKPoEMMProperties : OKAppProperties

// Get the device orientation
+ (UIDeviceOrientation) orientation;

// Keep track of the device orientation (only the ones supported by the app)
+ (void) setOrientation:(UIDeviceOrientation)aOrientation;

// Get the upright angle which is recomputed when the orientation is set
+ (int) uprightAngle;

+ (void) initWithContentsOfFile:(NSString *)aPath;

+ (id) objectForKey:(id)aKey;

+ (void) setObject:(id)aObject forKey:(id)aKey;

// Fills the properties with a loaded package dictionary (Properties-iPhone, Properties-iPhone-Retina, Properties-iPhone-568h, Properties-iPad, Properties-iPad-Retina)
+ (void) fillWith:(NSDictionary*)aTextDict;

+ (void) listProperties;

@end
