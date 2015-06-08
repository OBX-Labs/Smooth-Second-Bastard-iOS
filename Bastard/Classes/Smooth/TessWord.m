//
//  TessWord.m
//  Smooth
//
//  Created by Christian Gratton on 11-07-27.
//  Copyright 2011 Christian Gratton. All rights reserved.
//

#import "TessWord.h"
#import "TessSentence.h"
#import "TessGlyph.h"
#import "Smooth.h"
#import "OKWordObject.h"
#import "OKCharObject.h"
#import "OKTessFont.h"

#import "EAGLView.h"
#import "OKPoEMMProperties.h"

//constants
static float WANDER_THRESHOLD;              //proximity threshold for wander behavior to create a new target

static float EXTRACT_PUSH_STRENGTH;      //push strenght on glyphs when extracting the middle one
static float EXTRACT_PUSH_SPIN_MIN;  //minimum spin
static float EXTRACT_PUSH_SPIN_MAX;   //maximum spin
static float EXTRACT_PUSH_ANGLE;       //push angle

static float FADE_SPEED;                 //fading speed when updating color

static float MIDDLE_WORD_WANDER_RANGE;
static float MIDDLE_WORD_WANDER_SPEED;

static float BACKGROUND_GLYPH_SCALE;
static float BACKGROUND_GLYPH_SCALE_SPEED;
static float BACKGROUND_GLYPH_SCALE_FRICTION;
static int BACKGROUND_GLYPH_OPACITY;

@implementation TessWord
@synthesize glyphs, parent;

- (id) initTessWord:(OKWordObject*)aWord font:(OKTessFont*)aFont parent:(TessSentence*)aParent accuracy:(int)accuracy
{
    self = [super init];
    if(self)
    {
        WANDER_THRESHOLD = [[OKPoEMMProperties objectForKey:WordWanderThreshold] floatValue];
        
        EXTRACT_PUSH_STRENGTH = [[OKPoEMMProperties objectForKey:WordExtractPushStrength] floatValue];
        EXTRACT_PUSH_SPIN_MIN = M_PI/[[OKPoEMMProperties objectForKey:WordExtractPushSpinMin] floatValue];
        EXTRACT_PUSH_SPIN_MAX = M_PI/[[OKPoEMMProperties objectForKey:WordExtractPushSpinMax] floatValue];
        EXTRACT_PUSH_ANGLE = M_PI/[[OKPoEMMProperties objectForKey:WordExtractPushAngle] floatValue];
        
        FADE_SPEED = [[OKPoEMMProperties objectForKey:WordFadeSpeed] floatValue];
        
        MIDDLE_WORD_WANDER_RANGE = [[OKPoEMMProperties objectForKey:MiddleWordWanderRange] floatValue];
        MIDDLE_WORD_WANDER_SPEED = [[OKPoEMMProperties objectForKey:MiddleWordWanderSpeed] floatValue];
        
        BACKGROUND_GLYPH_SCALE = [[OKPoEMMProperties objectForKey:BackgroundGlyphScale] floatValue];
        BACKGROUND_GLYPH_SCALE_SPEED = [[OKPoEMMProperties objectForKey:BackgroundGlyphScaleSpeed] floatValue];
        BACKGROUND_GLYPH_SCALE_FRICTION = [[OKPoEMMProperties objectForKey:BackgroundGlyphScaleFriction] floatValue];
        BACKGROUND_GLYPH_OPACITY = [[OKPoEMMProperties objectForKey:BackgroundGlyphOpacity] intValue];        
        
        glyphs = [[NSMutableArray alloc] init];      //array of glyphs
        self.parent = aParent;   //parent sentence
        tessFont = aFont;
        
        [self build:aWord accuracy:accuracy];
        
        //color values
        clr[0] = 0.0f;
		clr[1] = 0.0f;
		clr[2] = 0.0f;
		clr[3] = 1.0f;
		
		clrTarget[0] = 0.0f;
		clrTarget[1] = 0.0f;
		clrTarget[2] = 0.0f;
		clrTarget[3] = 1.0f;
        
        //set default angular friction
        angFriction = 0.998;
        
        extractGlyphIndex = -1;
    }
    return self;
}

//tessellate the word
- (void) build:(OKWordObject*)aWord accuracy:(int)accuracy
{
    //code to get center...
    //OKPoint newPos = [aWord getCenter];
    //newPos = OKPointSub(newPos, [parent absPos]);
    OKPoint newPos = OKPointMake([aWord getX], [aWord getY], 0);
    [self setPos:newPos];
    
    //build the sentence, and assign a higher tesselation detail to the middle word    
    for(OKCharObject *okChar in aWord.charObjects)
    {
        TessGlyph *glyph = [[TessGlyph alloc] initTessGlyph:okChar font:tessFont parent:self accuracy:accuracy];
        [glyphs addObject:glyph];
        [glyph release];
    }
}

//update
- (void) update:(long)dt
{
    [super update:dt];
    
    //update color
     [self updateColor:dt];
    
    //update the glyphs
    for(TessGlyph *glyph in glyphs)
    {
        [glyph update:dt];
    }
}

//update color
- (void) updateColor:(long)dt
{
    if(clr[0] == clrTarget[0] && clr[1] == clrTarget[1] && clr[2] == clrTarget[2] && clr[3] == clrTarget[3])
		return;
        
    //fade each color element
    float diff;
    float delta;
    float direction;
    
    float newr = clr[0];
    float newg = clr[1];
    float newb = clr[2];
    float newa = clr[3];
    
    //red
    diff = (clrTarget[0] - clr[0]);
    if (diff != 0)
    {
        delta = clrRedStep * dt;
        if (delta < 1) delta = 1;
        direction = diff < 0 ? -1 : 1;
        
        if (diff*direction < delta)
            newr = clrTarget[0];
        else
            newr += delta*direction;
    }
    
    //green
    diff = (clrTarget[1] - clr[1]);
    if (diff != 0)
    {
        delta = clrGreenStep * dt;
        if (delta < 1) delta = 1;
        direction = diff < 0 ? -1 : 1;
        
        if (diff*direction < delta)
            newg = clrTarget[1];
        else
            newg += delta*direction;
    }
    
    //blue
    diff = (clrTarget[2] - clr[2]);
    if (diff != 0)
    {
        delta = clrBlueStep * dt;
        if (delta < 1) delta = 1;
        direction = diff < 0 ? -1 : 1;
        
        if (diff*direction < delta)
            newb = clrTarget[2];
        else
            newb += delta*direction;
    }
    
    //alpha
    diff = (clrTarget[3] - clr[3]);
    if (diff != 0)
    {
        delta = clrAlphaStep * dt;
        if (delta < 1) delta = 1;
        direction = diff < 0 ? -1 : 1;
        
        if (diff*direction < delta)
            newa = clrTarget[3];
        else
            newa += delta*direction;
    }
    
    clr[0] = newr;
    clr[1] = newg;
    clr[2] = newb;
    clr[3] = newa;
}

//set the color
- (void) setColor:(float*)c
{
    clr[0] = c[0];
    clr[1] = c[1];
    clr[2] = c[2];
    clr[3] = c[3];
    isSetColor = YES;
}

//get color
- (float*) getColor
{
    return clr;
}

//check if the color is set
- (BOOL) isColorSet
{    
    return isSetColor;
}

//ask to fade the words to a given color
- (void) fadeTo:(float*)c
{
    if(clr[0] == c[0] && clr[1] == c[1] && clr[2] == c[2] && clr[3] == c[3])
		return;
    
    clrRedStep = ((clrTarget[0] - clr[0]) / FADE_SPEED);
    if(clrRedStep < 0) clrRedStep *= -1;
    
    clrGreenStep = ((clrTarget[1] - clr[1]) / FADE_SPEED);
    if(clrGreenStep < 0) clrGreenStep *= -1;
    
    clrBlueStep = ((clrTarget[2] - clr[2]) / FADE_SPEED);
    if(clrBlueStep < 0) clrBlueStep *= -1;
    
    clrAlphaStep = ((clrTarget[3] - clr[3]) / FADE_SPEED);
    if(clrAlphaStep < 0) clrAlphaStep *= -1;
    
    clrTarget[0] = c[0];
    clrTarget[1] = c[1];
    clrTarget[2] = c[2];
    clrTarget[3] = c[3];
}

//get the absolute position
- (OKPoint) absPos
{
    if(!parent) return pos;
    OKPoint newPos = OKPointSet(pos);
    newPos = OKPointMultf(newPos, [parent absScale]);
    newPos = OKPointAdd(newPos, [parent absPos]);
    
    return newPos;
}

//get the absolute scale
- (float) absScale
{
    if(!parent) return sca;
    return ([parent absScale] * sca);
}

//draw the word 
- (void) draw
{
    glPushMatrix();
    
    //transform
    glTranslatef(pos.x, pos.y, pos.z);
    glRotatef(ang, 0.0, 0.0, 1.0);
    glScalef(sca, sca, 0.0);
    
    //draw glyphs
    for(TessGlyph *tg in glyphs)
    {
        [tg draw];
    }
    
    glPopMatrix();
}

//fold the word completely
- (void) fold
{
    for(TessGlyph *glyph in glyphs)
    {
        [glyph fold];
    }
}

//unfold the word
- (void) unfold:(long)dt distance:(float)distance speed:(float)aSpeed
{
    for(TessGlyph *glyph in glyphs)
    {
        [glyph unfold:dt distance:distance speed:aSpeed];
    }
}

//fold the word
- (void) fold:(long)dt distance:(float)distance speed:(float)aSpeed
{
    for(TessGlyph *glyph in glyphs)
    {
        [glyph fold:dt distance:distance speed:aSpeed];
    }
}

//make the word wander around
- (void) wander
{
    if(OKPointDist(pos, target) < WANDER_THRESHOLD)
    {        
        float angle = (((arc4random() % 101)/100.0f) * (M_PI*2));
        [self approachX:(pos.x + (cos(angle) * MIDDLE_WORD_WANDER_RANGE)) y:(pos.y + (sin(angle) * MIDDLE_WORD_WANDER_RANGE)) z:pos.z s:MIDDLE_WORD_WANDER_SPEED];
    }
}

//extract the glyph at the specified index and push the rest out
- (TessGlyph*) extract:(int)index
{
    if(index < 0) return nil;
    else if (index >= [glyphs count]) return nil;
    
    //make sure the index is within bounds
    int i = 0;
    TessGlyph *extractedGlyph;
    NSMutableArray *removables = [[NSMutableArray alloc] init];
    //go through the words
    for(TessGlyph *aGlyph in glyphs)
    {
        //if we reached the word to extract, then extract it
        if(i == index)
        {
            extractedGlyph = aGlyph;
            [extractedGlyph retain];
            [removables addObject:aGlyph];
        }
        //if we are before the word we are looking for, push to the left
        else if(i < index)
        {
            float angle = [self arc4randomf:(M_PI - EXTRACT_PUSH_ANGLE) :(M_PI + EXTRACT_PUSH_ANGLE)];
            [aGlyph push:OKPointMake((cos(angle) * EXTRACT_PUSH_STRENGTH), (sin(angle) * EXTRACT_PUSH_STRENGTH), -1)];
            [aGlyph spin:[self arc4randomf:EXTRACT_PUSH_SPIN_MIN :EXTRACT_PUSH_SPIN_MAX]];
        }
        //if after, push to the right
        else if(i > index)
        {
            float angle = [self arc4randomf:-EXTRACT_PUSH_ANGLE :EXTRACT_PUSH_ANGLE];
            [aGlyph push:OKPointMake((cos(angle) * EXTRACT_PUSH_STRENGTH), (sin(angle) * EXTRACT_PUSH_STRENGTH), -1)];
            [aGlyph spin:[self arc4randomf:-EXTRACT_PUSH_SPIN_MAX :-EXTRACT_PUSH_SPIN_MIN]];
        }        
        i++;
    }
    
    //remove glyphs
    [glyphs removeObjectsInArray:removables];
    //for(TessGlyph *aGlyph in removables)
    //{
    //    [glyphs removeObject:aGlyph];
    //}
    
    [removables release];
        
    //set the new properties for the extracted glyph
    [extractedGlyph setPos:[extractedGlyph absPos]];
    [extractedGlyph setScale:[extractedGlyph absScale]];
    [extractedGlyph approachScale:BACKGROUND_GLYPH_SCALE speed:BACKGROUND_GLYPH_SCALE_SPEED friction:BACKGROUND_GLYPH_SCALE_FRICTION];
    [extractedGlyph setColor:[self getColor]];
        
    [extractedGlyph fadeTo:[parent.smooth createPaletteColor:BACKGROUND_GLYPH_OPACITY layer:parent.smooth.BACK]];
    
    //detach
    extractedGlyph.parent = nil;
    
    return extractedGlyph;
}

//get glyph count
- (int) glyphCount
{
    return [glyphs count];
}

//check if the word is outside bounds
- (BOOL) isOutside:(CGRect)b
{
    for(TessGlyph *glyph in glyphs)
    {        
        if(![glyph isOutside:b]) return NO;
    }
    
    return YES;
}

//get the absolute bounds
- (CGRect) getAbsoluteBounds
{
    CGRect bnds;
    
    for(TessGlyph *glyph in glyphs)
    {
        if(CGRectIsNull(bnds)) bnds = [glyph getAbsoluteBounds];
        else bnds = CGRectUnion(bnds, [glyph getAbsoluteBounds]);
    }
    
    return bnds;
}

- (void) setExtractIndex:(int)g
{
    extractGlyphIndex = g;
}

- (int) extractGlyphIndex
{
    return extractGlyphIndex;
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
    [glyphs release];
    [parent release];
	
    [super dealloc];
}

@end
