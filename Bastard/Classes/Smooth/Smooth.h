//
//  Smooth.h
//  Smooth
//
//  Created by Christian Gratton on 11-07-27.
//  Copyright 2011 Christian Gratton. All rights reserved.
//

#import <Foundation/Foundation.h>

@class TessSentence;
@class OKTessFont;
@class OKTextObject;
@class OKSentenceObject;
@class OKWordObject;
@class OKCharObject;

@interface Smooth : NSObject
{    
    //Spotlights
    int currentSpot;            //current spotlight tied to the active or next front sentence
    
    //Background
    float bgColor[3];            //current background color
    float bgColorTarget[3];      //target background color
    float bgColorSpeed[3];       //background color fading speed
    
    //text properties
    int stringIndex;            //index of the next string
    CGRect bounds;   //bounds of the display to find when words get out
    
    TessSentence *tessSentence;  //active front sentence (null if none)
    NSMutableArray *doneTessSentences; //the sentences we are done with (exploding)
    NSMutableArray *middleWords;     //list of floating middle words
    NSMutableArray *doneMiddleWords; //list of done floating middle words
    NSMutableArray *bgLetters;       //list of floating letters in the background
    
    //animation time tracking
    NSDate *lastUpdate;        //last time the sketch was updated
    NSDate *now;               //current time
    long DT;                    //time difference between draw calls
    long lastTouch;
    
    //text properties
    OKTessFont *tessFont;
    OKTextObject *textObject;
    NSMutableArray *textStrings;
    
    //touches
    NSMutableDictionary *touches;
    
    float touchOffset;
}

@property (nonatomic) int FRONT;
@property (nonatomic) int MIDDLE;
@property (nonatomic) int BACK;

- (id) initWithFont:(OKTessFont*)aFont andText:(OKTextObject*)aText;

- (void) draw;
- (void) updateStrings:(long)dt;
- (void) drawStrings;
- (void) updateMiddleWords:(long)dt;
- (void) drawMiddleWords;
- (void) updateBackground:(long)dt;
- (void) updateBgLetters:(long)dt;
- (void) drawBgLetters;
- (void) updateIdle:(long)dt;
- (TessSentence*) createSentence;
- (float*) createPaletteColor:(int)a layer:(int)layer;

- (void) touchesBeganID:(int)aID at:(CGPoint)aPoint;
- (void) touchesMovedID:(int)aID at:(CGPoint)aPoint;
- (void) touchesEndedID:(int)aID;
- (void) touchesCancelledID:(int)aID;

@end
