//
//  TessGlyph.h
//  Smooth
//
//  Created by Christian Gratton on 11-07-27.
//  Copyright 2011 Christian Gratton. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "KineticObject.h"
#import "ESRenderer.h"

@class OKCharDef;
@class TessWord;
@class OKTessData;
@class Smooth;
@class OKCharObject;
@class OKTessFont;

#define ARC4RANDOM_MAX 0x100000000

@interface TessGlyph : KineticObject
{    
    OKTessData *origData;      //tesselated data of the original glyph
    OKTessData *dfrmData;      //tesselated data of the deformed glyph
    TessWord *parent;        //parent word
    
    CGRect bounds;    //local bounds
    CGRect absBounds; //absolute bounds
    
    float clr[4]; //color
    float clrTarget[4]; //target color
    
    float clrRedStep, clrGreenStep, clrBlueStep, clrAlphaStep;  //fading speed
    
    OKTessFont *tessFont;
    
    //3d points in 2d space arrays
	GLfloat modelview[16];
	GLfloat projection[16];
    
    BOOL isSetColor;
    
    NSString *test;
}

@property (nonatomic, retain) TessWord *parent;

- (id) initTessGlyph:(OKCharObject*)aChar font:(OKTessFont*)aFont parent:(TessWord*)aParent accuracy:(int)accuracy;

- (void) build:(OKCharObject*)aChar accuracy:(int)accuracy;
- (OKTessData*) tesselate:(OKCharDef*)aCharDef accuracy:(int)accuracy;
- (void) update:(long)dt;
- (void) draw;
- (void) updateColor:(long)dt;
- (void) setColor:(float*)c;
- (float*) getColor;
- (BOOL) isColorSet;
- (void) fadeTo:(float*)c;
- (OKPoint) absPos;
- (float) absScale;
- (void) fold;
- (void) fold:(long)dt distance:(float)aDistance speed:(float)aSpeed;
- (void) unfold:(long)dt distance:(float)aDistance speed:(float)aSpeed;
- (void) wander;
- (BOOL) isOutside:(CGRect)b;
- (CGRect) getBounds;
- (CGRect) getAbsoluteBounds;

- (CGPoint) convertPoint:(CGPoint)aPoint withZ:(float)z;

- (float) floatRandom;
- (float) arc4randomf:(float)max :(float)min;

- (void)drawDeprec;

@end
