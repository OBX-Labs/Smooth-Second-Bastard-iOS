//
//  TessWord.h
//  Smooth
//
//  Created by Christian Gratton on 11-07-27.
//  Copyright 2011 Christian Gratton. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "KineticObject.h"

@class TessSentence;
@class TessGlyph;
@class Smooth;
@class OKWordObject;
@class OKCharObject;
@class OKTessFont;

#define ARC4RANDOM_MAX 0x100000000

@interface TessWord : KineticObject
{
//    //constants
//    float WANDER_THRESHOLD;              //proximity threshold for wander behavior to create a new target
//    
//    float EXTRACT_PUSH_STRENGTH;      //push strenght on glyphs when extracting the middle one
//    float EXTRACT_PUSH_SPIN_MIN;  //minimum spin
//    float EXTRACT_PUSH_SPIN_MAX;   //maximum spin
//    float EXTRACT_PUSH_ANGLE;       //push angle
//    
//    float BG_LETTER_SCALE_SPEED;   //scaling speed of background glyphs
//    float BG_LETTER_SCALE_FRICTION;  //scaling friction of background glyphs
//    
//    float FADE_SPEED;                 //fading speed when updating color
    
    NSMutableArray *glyphs;      //array of glyphs
    TessSentence *parent;   //parent sentence
    
    float clr[4]; //color
    float clrTarget[4]; //target color

    float clrRedStep, clrGreenStep, clrBlueStep, clrAlphaStep;  //step for fading color
    
    OKTessFont *tessFont;
    BOOL isSetColor;
    
    int extractGlyphIndex;
}

@property (nonatomic, retain) NSMutableArray *glyphs;
@property (nonatomic, retain) TessSentence *parent;

- (id) initTessWord:(OKWordObject*)aWord font:(OKTessFont*)aFont parent:(TessSentence*)aParent accuracy:(int)accuracy;

- (void) build:(OKWordObject*)aWord accuracy:(int)accuracy;
- (void) update:(long)dt;
- (void) updateColor:(long)dt;
- (void) setColor:(float*)c;
- (float*) getColor;
- (BOOL) isColorSet;
- (void) fadeTo:(float*)c;
- (OKPoint) absPos;
- (float) absScale;
- (void) draw;
- (void) fold;
- (void) unfold:(long)dt distance:(float)distance speed:(float)aSpeed;
- (void) fold:(long)dt distance:(float)distance speed:(float)aSpeed;
- (void) wander;
- (TessGlyph*) extract:(int)index;
- (int) glyphCount;
- (BOOL) isOutside:(CGRect)b;
- (CGRect) getAbsoluteBounds;

- (void) setExtractIndex:(int)g;
- (int) extractGlyphIndex;

- (float) floatRandom;
- (float) arc4randomf:(float)max :(float)min;

@end