//
//  TessSentence.m
//  Smooth
//
//  Created by Christian Gratton on 11-07-27.
//  Copyright 2011 Christian Gratton. All rights reserved.
//

#import "TessSentence.h"

#import "TessWord.h"
#import "Smooth.h"
#import "OKSentenceObject.h"
#import "OKWordObject.h"
#import "OKCharObject.h"
#import "OKTessFont.h"

#import "EAGLView.h"
#import "OKPoEMMProperties.h"

#define ARC4RANDOM_MAX 0x100000000

//constants
static float APPROACH_SPEED;              //speed to approach to touch
static int APPROACH_THRESHOLD;            //approach threshold distance (hit distance)
static float UNFOLD_REPEAT;                //number of times the unfold method is called per frame
static float UNFOLD_SPEED_DECAY;      //speed decay of unfolding behaviour
static float FOLD_REPEAT;                  //number of times the fold method is called per frame
static float FOLD_SPEED_DECAY;         //speed decay of folding behaviour
static float UNFOLD_SPEED;
static float FOLD_SPEED;

static float EXTRACT_PUSH_STRENGTH;     //push strength on words when extracting the middle one
static float EXTRACT_PUSH_SPIN_MIN;  //minimum spin push
static float EXTRACT_PUSH_SPIN_MAX;  //maximum spin push
static float EXTRACT_PUSH_ANGLE;       //maximum push angle

static float CTRL_PT_FRICTION;           //friction of control points
static float CTRL_PT_SPEED;                //speed of control points

static float SNAP_FRICTION;             //friction of control points when snapping
static float SNAP_SPEED;                   //speed of snapping control points

static float MIDDLE_WORD_SCALE;
static float MIDDLE_WORD_SCALE_SPEED;
static float MIDDLE_WORD_SCALE_FRICTION;
static int MIDDLE_WORD_OPACITY;

@implementation TessSentence
@synthesize IDLE, FOLD, UNFOLD, SNAP, EXTRACT, words, smooth;

- (id) initTessSentence:(OKSentenceObject*)aSentence font:(OKTessFont*)aFont accuracyLow:(int)low accuracyHigh:(int)high
{
    self = [super init];
    if(self)
    {
        APPROACH_SPEED = [[OKPoEMMProperties objectForKey:ApproachSpeed] floatValue];
        APPROACH_THRESHOLD = [[OKPoEMMProperties objectForKey:ApproachThreshold] intValue];
        UNFOLD_REPEAT = [[OKPoEMMProperties objectForKey:UnfoldRepeat] floatValue];
        UNFOLD_SPEED_DECAY = [[OKPoEMMProperties objectForKey:UnfoldSpeedDecay] floatValue];
        FOLD_REPEAT = [[OKPoEMMProperties objectForKey:FoldRepeat] floatValue];
        FOLD_SPEED_DECAY = [[OKPoEMMProperties objectForKey:FoldSpeedDecay] floatValue];
        
        UNFOLD_SPEED = [[OKPoEMMProperties objectForKey:UnfoldSpeed] floatValue];
        FOLD_SPEED = [[OKPoEMMProperties objectForKey:FoldSpeed] floatValue];
        
        EXTRACT_PUSH_STRENGTH = [[OKPoEMMProperties objectForKey:SentenceExtractPushStrength] floatValue];
        EXTRACT_PUSH_SPIN_MIN = M_PI/[[OKPoEMMProperties objectForKey:SentenceExtractPushSpinMin] floatValue];
        EXTRACT_PUSH_SPIN_MAX = M_PI/[[OKPoEMMProperties objectForKey:SentenceExtractPushSpinMax] floatValue];
        EXTRACT_PUSH_ANGLE = M_PI/[[OKPoEMMProperties objectForKey:SentenceExtractPushAngle] floatValue];

        CTRL_PT_FRICTION = [[OKPoEMMProperties objectForKey:CtrlPtFriction] floatValue];
        CTRL_PT_SPEED = [[OKPoEMMProperties objectForKey:CtrlPtSpeed] floatValue];
        
        SNAP_FRICTION = [[OKPoEMMProperties objectForKey:SnapFriction] floatValue];
        SNAP_SPEED = [[OKPoEMMProperties objectForKey:SnapSpeed] floatValue];
        
        MIDDLE_WORD_SCALE = [[OKPoEMMProperties objectForKey:MiddleWordScale] floatValue];
        MIDDLE_WORD_SCALE_SPEED = [[OKPoEMMProperties objectForKey:MiddleWordScaleSpeed] floatValue];
        MIDDLE_WORD_SCALE_FRICTION = [[OKPoEMMProperties objectForKey:MiddleWordScaleFriction] floatValue];
        MIDDLE_WORD_OPACITY = [[OKPoEMMProperties objectForKey:MiddleWordOpacity] intValue];
        
        //sentence states  
        IDLE = 0;
        FOLD = 1;
        UNFOLD = 2;
        SNAP = 3;
        EXTRACT = 4;
        
        state = IDLE;
        
        words = [[NSMutableArray alloc] init];      
                       
        tessFont = aFont;
        
        //color values
        clr[0] = 0.0f;
		clr[1] = 0.0f;
		clr[2] = 0.0f;
		clr[3] = 1.0f;
                
        //build tesselated sentence
        [self build:aSentence accuracyLow:low accuracyHigh:high];
        
        //set defaults        
        stringHeight = [aSentence getHeight];
        stringWidth = [aSentence getWitdh];
        
        origFoldWidth = stringWidth/2 + 50;
        foldWidth = origFoldWidth;
        friction = 0.80;   
        
        ctrlPts = [[NSMutableDictionary alloc] init];
        
        extractWordIndex = -1;
    }
    return self;
}

- (void) setCtrlPoint:(int)aID x:(int)aX y:(int)aY
{
    KineticObject *pt = [ctrlPts objectForKey:[NSString stringWithFormat:@"%i", aID]];
    
    //if there is no control point for this touch id
    //then we need to create one
    if(!pt)
    {
        KineticObject *ko = [[KineticObject alloc] init];
        ko.friction = CTRL_PT_FRICTION;
        
        //if it's the first control point then
        //we can set it at the touch location
        if ([ctrlPts count] == 0)
            [ko setPos:OKPointMake(aX, aY, 0.0)];
        //but if it's not the first, then it needs to
        //be set at the location of the first and approach
        //the touch location
        else
        {
            NSEnumerator *keyEnum = [ctrlPts keyEnumerator];
            KineticObject *ctrlPt1 = [ctrlPts objectForKey:[keyEnum nextObject]];
            
            [ko setPos:ctrlPt1.pos];
            [ko approachX:aX y:aY z:0.0 s:CTRL_PT_SPEED];
        }
        
        [ctrlPts setObject:ko forKey:[NSString stringWithFormat:@"%i", aID]];
        [ko release];
    }
    else
    {
        [pt approachX:aX y:aY z:0.0 s:CTRL_PT_SPEED];
    } 
}

- (void) update:(long)dt
{
    [super update:dt];
    
    for(NSString *aKey in ctrlPts)
    {
        KineticObject *ko = [ctrlPts objectForKey:aKey];
        [ko update:dt];  
    }
    
    if(state == UNFOLD)
        [self unfold:(1000/60)];
    else if(state == FOLD)
        [self fold:(1000/60)];
    else if(state == SNAP)
        [self snap:dt];
        
    for(TessWord *word in words)
    {
        [word update:dt];
    }
}

//set the color
- (void) setColor:(float*)c
{
    clr[0] = c[0];
    clr[1] = c[1];
    clr[2] = c[2];
    clr[3] = c[3];
}

//get color
- (float*) getColor
{
    return clr;
}

- (void) setState:(int)s
{
    state = s;
}

- (int) getState
{
    return state;
}

- (int) wordCount
{
    return [words count];
}

- (int) glyphCount
{
    int total = 0;
    for(TessWord *word in words)
    {
        total += [word glyphCount];
    }
    return total;
}

//extract the sentence's middle word
- (TessWord*) extract:(int)index
{
    if(index < 0) return nil;
    else if (index >= [words count]) return nil;
    //make sure the index is within bounds
    int i = 0;
    TessWord *extractedWord;
    NSMutableArray *removables = [[NSMutableArray alloc] init];
    //go through the words    
    for(TessWord *aWord in words)
    {
        //if we reached the word to extract, then extract it
        if(i == index)
        {
            aWord.parent = nil;
            extractedWord = aWord;
            [extractedWord retain];
            [removables addObject:aWord];
        }
        //if we are before the word we are looking for, push to the left
        else if(i < index)
        {
            float angle = [self arc4randomf:(M_PI - EXTRACT_PUSH_ANGLE) :(M_PI + EXTRACT_PUSH_ANGLE)];
            [aWord push:OKPointMake((cos(angle) * EXTRACT_PUSH_STRENGTH), (sin(angle) * EXTRACT_PUSH_STRENGTH), 0.0)];
            [aWord spin:[self arc4randomf:EXTRACT_PUSH_SPIN_MIN :EXTRACT_PUSH_SPIN_MAX]];
        }
        //if after, push to the right
        else if(i > index)
        {
            float angle = [self arc4randomf:-EXTRACT_PUSH_ANGLE :EXTRACT_PUSH_ANGLE];
            [aWord push:OKPointMake((cos(angle) * EXTRACT_PUSH_STRENGTH), (sin(angle) * EXTRACT_PUSH_STRENGTH), 0.0)];
            [aWord spin:[self arc4randomf:-EXTRACT_PUSH_SPIN_MAX :-EXTRACT_PUSH_SPIN_MIN]];
        }
        i++;
    }
    
    //words to remove
    [words removeObjectsInArray:removables];

    [removables release];
    
    //set the sentences position where the control points snapped
    NSEnumerator *keyEnum = [ctrlPts keyEnumerator];
    KineticObject *ctrlPt1 = [ctrlPts objectForKey:[keyEnum nextObject]];
    ctrlPt1.acc = OKPointMake(0.0, 0.0, 0.0);
    ctrlPt1.vel = OKPointMake(0.0, 0.0, 0.0);
    
    //remove the second control point
    if([ctrlPts count] > 1)
    {
        [ctrlPts removeObjectForKey:[keyEnum nextObject]];
    }
            
    [extractedWord moveBy:OKPointMake(pos.x + ctrlPt1.pos.x, pos.y + ctrlPt1.pos.y, pos.z + ctrlPt1.pos.z)];
    [extractedWord push:OKPointMake(0, -0.5, 0)];
    [extractedWord approachScale:MIDDLE_WORD_SCALE speed:MIDDLE_WORD_SCALE_SPEED friction:MIDDLE_WORD_SCALE_FRICTION];
    [extractedWord setColor:[self getColor]];
    [extractedWord fadeTo:[smooth createPaletteColor:MIDDLE_WORD_OPACITY layer:smooth.MIDDLE]];
    
    // set parent
    [extractedWord setParent:self];
    
    return extractedWord;
}

//decrease the folding radius
- (void) decFoldRadius:(long)dt
{
    if(foldWidth == 0) return;
    
    foldWidth -= dt * UNFOLD_SPEED/UNFOLD_REPEAT;
    if(foldWidth < 0) foldWidth = 0;
}

//increase the folding radius
- (void) incFoldRadius:(long)dt
{
    if(foldWidth == origFoldWidth) return;
    
    foldWidth += dt * FOLD_SPEED/FOLD_REPEAT;
    if(foldWidth > origFoldWidth) foldWidth = origFoldWidth;
}

//approach towards x,y point
- (void) approachX:(float)aX y:(float)aY
{
    float dx = aX - screenPos.x;
    float dy = aY - screenPos.y;
    float d = sqrtf(dx*dx + dy*dy);
    
    if(d > APPROACH_THRESHOLD)
    {
        acc.x += dx/d * APPROACH_SPEED;
        acc.y += dy/d * APPROACH_SPEED;
    }
}

//check if the sentence is done unfolding
- (BOOL) isUnfolded
{        
    return foldWidth == 0;
}

//check if the sentence is done folding
- (BOOL) isFolded
{    
    return foldWidth == origFoldWidth;
}

//check if the sentence is done snapping
- (BOOL) isSnapped
{
    if([ctrlPts count] < 2) return YES;
    
    NSEnumerator *keyEnum = [ctrlPts keyEnumerator];
    KineticObject *ctrlPt1 = [ctrlPts objectForKey:[keyEnum nextObject]];
    KineticObject *ctrlPt2 = [ctrlPts objectForKey:[keyEnum nextObject]];
    
    return (OKPointDist(ctrlPt1.pos, ctrlPt2.pos) < 4);
}

//unfold the sentence
- (void) unfold:(long)dt
{
    for(int i = 0; i < UNFOLD_REPEAT; i++)
    {
        for(TessWord *word in words)
        {
            [word unfold:dt distance:foldWidth speed:UNFOLD_SPEED/UNFOLD_REPEAT];
        }
        [self decFoldRadius:dt];
    }
    
    if(UNFOLD_SPEED/UNFOLD_REPEAT > 2/1000.f)
        UNFOLD_SPEED *= UNFOLD_SPEED_DECAY;
}

//fold sentence complete
- (void) fold
{
    for(TessWord *word in words)
    {
        [word fold];
    }
}

//fold sentence
- (void) fold:(long)dt
{
    for(int i = 0; i < FOLD_REPEAT; i++)
    {
        for(TessWord *word in words)
        {
            [word fold:dt distance:foldWidth speed:FOLD_SPEED/FOLD_REPEAT];
        }
        [self incFoldRadius:dt];
    }
    
    if(FOLD_SPEED/FOLD_REPEAT > 2/1000.f)
        FOLD_SPEED *= FOLD_SPEED_DECAY;
}

//get the sentence's center point (middle of two control point)
- (OKPoint) getCenterPt
{
    if([ctrlPts count] == 0) return pos;
    else if([ctrlPts count] == 1)
    {
        NSEnumerator *keyEnum = [ctrlPts keyEnumerator];
        KineticObject *ctrlPt1 = [ctrlPts objectForKey:[keyEnum nextObject]];
        
        return ctrlPt1.pos;
    }
    else if([ctrlPts count] == 2)
    {
        NSEnumerator *keyEnum = [ctrlPts keyEnumerator];
        KineticObject *ctrlPt1 = [ctrlPts objectForKey:[keyEnum nextObject]];
        KineticObject *ctrlPt2 = [ctrlPts objectForKey:[keyEnum nextObject]];
        
        return OKPointMake((ctrlPt1.pos.x + ctrlPt2.pos.x) / 2, (ctrlPt1.pos.y + ctrlPt2.pos.y) / 2, 0);
    }
    
    return OKPointMake(0, 0, 0);
}

//snap sentence (bring control points together)
- (void) snap:(long)dt
{
    if ([ctrlPts count] < 2) return; 
    
    //get control points
    NSEnumerator *keyEnum = [ctrlPts keyEnumerator];
    KineticObject *ctrlPt1 = [ctrlPts objectForKey:[keyEnum nextObject]];
    KineticObject *ctrlPt2 = [ctrlPts objectForKey:[keyEnum nextObject]];
    
    //if the control points are already really close, then we're done
    if (OKPointDist(ctrlPt1.pos, ctrlPt2.pos) < 4) return;
    
    //bring them closer
    OKPoint ctrlTarget = OKPointMake((ctrlPt1.pos.x + ctrlPt2.pos.x) / 2, (ctrlPt1.pos.y + ctrlPt2.pos.y) / 2, 0);
    ctrlPt1.friction = ctrlPt2.friction = SNAP_FRICTION;
    [ctrlPt1 approachX:ctrlTarget.x y:ctrlTarget.y z:ctrlTarget.z s:SNAP_SPEED];
    [ctrlPt2 approachX:ctrlTarget.x y:ctrlTarget.y z:ctrlTarget.z s:SNAP_SPEED];
}

//get the absolute position
- (OKPoint) absPos
{
    return pos;
}

//get the absolute scale
- (float) absScale 
{
    return sca;
}

//draw
- (void) draw
{
    //we need at least one control point to draw
    if ([ctrlPts count] == 0) return;
    
    //if there is less than 2 control points,
    //then we are drawing the whole sentence in one place
    if ([ctrlPts count] < 2)
    {
        //get the control point
        NSEnumerator *keyEnum = [ctrlPts keyEnumerator];
        KineticObject *ctrlPt1 = [ctrlPts objectForKey:[keyEnum nextObject]];
        
        //transform
        glPushMatrix();
        glTranslatef(pos.x, pos.y, pos.z);
        glTranslatef(ctrlPt1.pos.x, ctrlPt1.pos.y, ctrlPt1.pos.z);
        glRotatef(ang, 1.0, 0.0, 0.0);
        
        //draw words
        for(TessWord *tw in words)
        {
            if([tw isColorSet])
            {
                float *tClr = [tw getColor];
                glColor4f(tClr[0], tClr[1], tClr[2], tClr[3]);
            }
                
            [tw draw];  
        }
        
        glPopMatrix();    
    }
    //if we are two control points, then draw the halves separately
    else
    {
        //get the control points
        NSEnumerator *keyEnum = [ctrlPts keyEnumerator];
        KineticObject *ctrlPt1 = [ctrlPts objectForKey:[keyEnum nextObject]];
        KineticObject *ctrlPt2 = [ctrlPts objectForKey:[keyEnum nextObject]];
        
        //draw the left side
        int glyphCount = [self glyphCount];
        
        //tranform      
        glPushMatrix();
        glTranslatef(pos.x, pos.y, pos.z);
        glRotatef(ang, 1.0, 0.0, 0.0);
        
        //draw the words
        int count = 0;
        for(TessWord *tw in words)
        {
            if([tw isColorSet])
            {
                float *tClr = [tw getColor];
                glColor4f(tClr[0], tClr[1], tClr[2], tClr[3]);
            }
            
            glPushMatrix();
            
            glTranslatef(tw.pos.x, tw.pos.y, tw.pos.z);
            glRotatef(ang, 0.0, 0.0, 1.0);
            glScalef(tw.sca, tw.sca, 0.0);
            
            for(TessGlyph *tg in tw.glyphs)
            {
                //if we are in the first half, use the first control point
                if(count <= (glyphCount/2))
                {
                    glPushMatrix();
                    glTranslatef(ctrlPt1.pos.x, ctrlPt1.pos.y, ctrlPt1.pos.z);
                    [tg draw];
                    glPopMatrix();
                }
                //in the second half, use the second control point
                else
                {
                    glPushMatrix();    
                    glTranslatef(ctrlPt2.pos.x, ctrlPt2.pos.y, ctrlPt2.pos.z);
                    [tg draw];
                    glPopMatrix();
                }
                
                count++;
            }
            glPopMatrix();
        }
        glPopMatrix();
    }
}

//build the tesselated sentence
- (void) build:(OKSentenceObject*)aSentence accuracyLow:(int)low accuracyHigh:(int)high
{
    //code to get center...
    pos = OKPointMake([aSentence getX], [aSentence getY], 0);
        
    //count how many glyphs there are in this group
    int totalCount = [[aSentence.sentence stringByReplacingOccurrencesOfString:@" " withString:@""] length];
    
    //find the point of the word that contans the middle glyph
    OKWordObject *middleWord;
    int count = 0;
    for(OKWordObject *okWord in aSentence.wordObjects)
    {
        for(OKCharObject *okChar in okWord.charObjects)
        {
            if(count > (totalCount/2))
                middleWord = okWord;
            
            count++;
        }
    }
    
    //build the sentence, and assign a higher tesselation detail to the middle word    
    for(OKWordObject *okWord in aSentence.wordObjects)
    {
        TessWord *word = [[TessWord alloc] initTessWord:okWord font:tessFont parent:self accuracy:(okWord == middleWord ? high : low)];
        [words addObject:word];
        [word release];
    }
}

//check if sentence is outside of bounds
- (BOOL) isOutside:(CGRect)b
{
    for(TessWord *word in words)
    {
        if(![word isOutside:b]) return NO;
    }
    
    return YES;
}

//get absolute bounds
- (CGRect) getAbsoluteBounds
{
    CGRect bnds;
    
    for(TessWord *word in words)
    {
        if(CGRectIsNull(bnds)) bnds = [word getAbsoluteBounds];
        else bnds = CGRectUnion(bnds, [word getAbsoluteBounds]);
    }
    
    return bnds;
}

//get the index of the word with the middle glyph
- (int) middleWordIndex
{
    int halfTotal = [self glyphCount]/2;
    int count = 0;
    int index = 0;
    
    for(TessWord *word in words)
    {
        count += [word glyphCount];
        if(count > halfTotal) return index;
        index++;
    }
    
    return ([self wordCount] - 1);
}

- (void) setExtractIndexesWord:(int)w glyph:(int)g
{
    extractWordIndex = w;
    [[words objectAtIndex:w] setExtractIndex:g];
}

- (int) extractWordIndex
{
    return extractWordIndex;
}

- (float) floatRandom
{
    return (float)arc4random()/ARC4RANDOM_MAX;
}

- (float) arc4randomf:(float)max :(float)min
{
    return ((max - min) * [self floatRandom]) + min;
}

- (void)dealloc
{
    [words release];
    [smooth release];
    [ctrlPts release];
	
    [super dealloc];
}

@end
