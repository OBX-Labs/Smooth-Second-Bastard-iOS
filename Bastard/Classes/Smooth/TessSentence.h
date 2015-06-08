//
//  TessSentence.h
//  Smooth
//
//  Created by Christian Gratton on 11-07-27.
//  Copyright 2011 Christian Gratton. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "KineticObject.h"

@class TessWord;
@class Smooth;
@class OKSentenceObject;
@class OKWordObject;
@class OKCharObject;
@class OKTessFont;

@interface TessSentence : KineticObject
{    
    //sentence states  
    int IDLE;                           //idle state, nothing to do
    int FOLD;                           //folding
    int UNFOLD;                         //unfolding
    int SNAP;                           //snapping
    int EXTRACT;                        //extracting
    
    int state;                 //default state
    
    NSMutableArray *words;                  //array of words
    float clr[4];                      //sentence color
        
    //folding/unfolding threshold
    float foldWidth;
    float origFoldWidth;
    
    //string attributes
    float stringWidth;
    float stringHeight;
    
    //control points
    NSMutableDictionary *ctrlPts;
    OKTessFont *tessFont;
    
    int extractWordIndex;
}

@property int IDLE;
@property int FOLD;
@property int UNFOLD;
@property int SNAP;
@property int EXTRACT;
@property (nonatomic, retain) Smooth *smooth;

@property (nonatomic, retain) NSMutableArray *words;

- (id) initTessSentence:(OKSentenceObject*)aSentence font:(OKTessFont*)aFont accuracyLow:(int)low accuracyHigh:(int)high;

- (void) setCtrlPoint:(int)aID x:(int)aX y:(int)aY;
- (void) update:(long)dt;
- (void) setColor:(float*)c;
- (float*) getColor;
- (void) setState:(int)s;
- (int) getState;
- (int) wordCount;
- (int) glyphCount;
- (TessWord*) extract:(int)index;
- (void) decFoldRadius:(long)dt;
- (void) incFoldRadius:(long)dt;
- (void) approachX:(float)aX y:(float)aY;
- (BOOL) isUnfolded;
- (BOOL) isFolded;
- (BOOL) isSnapped;
- (void) unfold:(long)dt;
- (void) fold;
- (void) fold:(long)dt;
- (OKPoint) getCenterPt;
- (void) snap:(long)dt;
- (OKPoint) absPos;
- (float) absScale;
- (void) draw;
- (void) build:(OKSentenceObject*)aSentence accuracyLow:(int)low accuracyHigh:(int)high;
- (BOOL) isOutside:(CGRect)b;
- (CGRect) getAbsoluteBounds;
- (int) middleWordIndex;

- (void) setExtractIndexesWord:(int)w glyph:(int)g;
- (int) extractWordIndex;

- (float) floatRandom;
- (float) arc4randomf:(float)max :(float)min;

@end
