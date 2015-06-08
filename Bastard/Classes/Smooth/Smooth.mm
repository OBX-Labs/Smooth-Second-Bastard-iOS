//
//  Smooth.m
//  Smooth
//
//  Created by Christian Gratton on 11-07-27.
//  Copyright 2011 Christian Gratton. All rights reserved.
//

#import "Smooth.h"

#import "TessSentence.h"
#import "TessWord.h"
#import "TessGlyph.h"
#import "OKTessFont.h"

#import "OKTextObject.h"
#import "OKSentenceObject.h"
#import "OKWordObject.h"
#import "OKCharObject.h"

#import "OKTouch.h"

#import "OKPoEMMProperties.h"

#define alpha(rgbValue) ((rgbValue & 0xFF000000) >> 24)
#define red(rgbValue) ((rgbValue & 0x00FF0000) >> 16)
#define green(rgbValue) ((rgbValue & 0x0000FF00) >> 8)
#define blue(rgbValue) (rgbValue & 0x000000FF)
#define argb(a, r, g, b) ((a & 0xFF) << 24 | (r & 0xFF) << 16 | (g & 0xFF) << (8 & 0xFF) | b)

#define random_minus1_1() ((random() / (float)0x3fffffff )-1.0f)

static int PALETTE_FG[] = {0xFFFFFF};
static int PALETTE_MG[] = {0xdc6626, 0xad3a25, 0xe5b43d, 0xdf9529};
static int PALETTE_BG[] = {0x231e55, 0x671e16, 0x8c191b, 0xc97525};

static int PALETTE_FG_COUNT = 1;
static int PALETTE_MG_COUNT = 4;
static int PALETTE_BG_COUNT = 4;

static int PALETTE_RED_OFFSET = 10;
static int PALETTE_GREEN_OFFSET = 5;
static int PALETTE_BLUE_OFFSET = 5;

static int WORD_INDEXES[] = {0, 4, 2, 0, 1, 2, 2, 3, 7, 1, 0, 1, 2, 5, 3, 8, 4, 2, 11, 0, 0, 1, 1, 2, 1, 1, 2, 2, 1, 1, 0, 0, 0};
static int GLYPH_INDEXES[] = {0, 2, 2, 2, 0, 1, 3, 4, 1, 3, 0, 1, 3, 1, 4, 3, 1, 0, 4, 3, 1, 2, 0, 1, 0, 1, 6, 4, 7, 5, 0, 0, 0};

static int TESS_DETAIL_LOW;
static int TESS_DETAIL_HIGH;

static int FONT_SENTENCE_OPACITY;
static int TOTAL_BACKGROUND_GLYPHS;

static float TOUCH_OFFSET;

static long IDLE_TIMEOUT = 20*60;

@implementation Smooth
@synthesize FRONT, MIDDLE, BACK;

- (id) initWithFont:(OKTessFont *)aFont andText:(OKTextObject *)aText
{
    self = [super init];
    if(self)
    {
        FRONT = 1;
        MIDDLE = 2;
        BACK = 3;
        
        TESS_DETAIL_LOW = [[OKPoEMMProperties objectForKey:TessDetailLow] intValue];
        TESS_DETAIL_HIGH = [[OKPoEMMProperties objectForKey:TessDetailHigh] intValue];
        
        FONT_SENTENCE_OPACITY = [[OKPoEMMProperties objectForKey:FontSentenceOpacity] intValue];
        TOTAL_BACKGROUND_GLYPHS = [[OKPoEMMProperties objectForKey:TotalBackgroundGlyphs] intValue];
        
        TOUCH_OFFSET = [[OKPoEMMProperties objectForKey:TouchOffset] floatValue];
        
        //Background
        bgColor[0] = bgColor[1] = bgColor[2] = 0;
        bgColorTarget[0] = bgColorTarget[1] = bgColorTarget[2] = 0;
        bgColorSpeed[0] = bgColorSpeed[1] = bgColorSpeed[2] = 0.00005;
        
        //text properties
        bounds = CGRectMake([UIScreen mainScreen].bounds.origin.x, [UIScreen mainScreen].bounds.origin.y, [UIScreen mainScreen].bounds.size.height, [UIScreen mainScreen].bounds.size.width);
        
        //tessSentence = nil;
        doneTessSentences = [[NSMutableArray alloc] init];
        middleWords = [[NSMutableArray alloc] init];
        doneMiddleWords = [[NSMutableArray alloc] init];
        bgLetters = [[NSMutableArray alloc] init];
        
        now = [[NSDate alloc] init];
        lastUpdate = [[NSDate alloc] init];
               
        tessFont = aFont;
        textObject = aText;
        textStrings = [[NSMutableArray alloc] initWithArray:textObject.sentenceObjects];
        
        touches = [[NSMutableDictionary alloc] init];
        
        lastTouch = 0;
        
        //Touch offset
        touchOffset = 32.5;
    }
    return self;
}

- (void) draw
{
    //millis since last draw
    DT = (long)([now timeIntervalSinceDate:lastUpdate]*1000);
    [lastUpdate release];
    
    //clear
    //draw bg color here (open gl)
    glClearColor(bgColor[0], bgColor[1], bgColor[2], 1.0);
    glClear(GL_COLOR_BUFFER_BIT);
    
    glEnable(GL_BLEND);
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    
    //draw bg letters
    [self drawBgLetters];
    
    //middle layer
    [self drawMiddleWords];
    
    //draw tess string
    [self drawStrings];
    
    //update background color
    [self updateBackground:DT];
    
    //update background letters
    [self updateBgLetters:DT];
    
    //update middle word
    [self updateMiddleWords:DT];
    
    //update strings
    [self updateStrings:DT];
    
    //update idle
    [self updateIdle:DT];
    
    glDisable(GL_BLEND);
    
    //keep track of time
    lastUpdate = [[NSDate alloc] initWithTimeIntervalSince1970:[now timeIntervalSince1970]];
    [now release];
    now = [[NSDate alloc] init];
}

- (void) updateStrings:(long)dt
{    
    if(tessSentence)
        [tessSentence update:dt];
    
    TessWord *explodingWord = nil;
    NSMutableArray* sentencesToRemove = [[NSMutableArray alloc] init];
    
    for(TessSentence *ts in doneTessSentences)
    {
        [ts update:dt];
        
        if([ts getState] == ts.FOLD && [ts isFolded])
        {
            [sentencesToRemove addObject:ts];
        }
        else if([ts getState] == ts.SNAP && [ts isSnapped])
        {
            if([middleWords count] > 2)
            {
                explodingWord = [middleWords objectAtIndex:0];
                TessGlyph *tg = [explodingWord extract:[explodingWord extractGlyphIndex]];
                [bgLetters addObject:tg];
            }
            
            TessWord *tw = [ts extract:[ts extractWordIndex]];
            [middleWords addObject:tw];
            
            [ts setState:4];
            
            stringIndex++;
            if(stringIndex >= [textStrings count]) stringIndex = 0;
        }
        else if([ts isOutside:bounds])
        {
            //[doneTessSentences removeObject:ts];
            [sentencesToRemove addObject:ts];
        }
    }
    
    if(explodingWord)
    {
        [middleWords removeObject:explodingWord];
        [doneMiddleWords addObject:explodingWord];
    }
    //remove sentence (if any)
    [doneTessSentences removeObjectsInArray:sentencesToRemove];
    [sentencesToRemove release];
}

- (void) drawStrings
{
    if(tessSentence)
    {
        float *clr = [tessSentence getColor];
        glColor4f(clr[0], clr[1], clr[2], clr[3]);
        
        [tessSentence draw];
    }
    
    for(TessSentence *ts in doneTessSentences)
    {
        float *clr = [ts getColor];
        glColor4f(clr[0], clr[1], clr[2], clr[3]);
        
        [ts draw];
    }
}

- (void) updateMiddleWords:(long)dt
{
    //go through the floating words and make them wander
    for(TessWord *tw in middleWords)
    {
        [tw wander];
        [tw update:dt];
    }
    
    //keep track of words to remove
    NSMutableArray* wordsToRemove = [[NSMutableArray alloc] init];
    
    //go through the exploding words and remove them
    //if they get out of bounds
    for(TessWord *tw in doneMiddleWords)
    {
        [tw wander];
        [tw update:dt];
        
        if([tw isOutside:bounds])
            [wordsToRemove addObject:tw];
    }
    
    //remove words
    [doneMiddleWords removeObjectsInArray:wordsToRemove];
    [wordsToRemove release];
}

- (void) drawMiddleWords
{
    for(TessWord *tw in middleWords)
    {
        if([tw isColorSet])
        {
            float *clr = [tw getColor];
            glColor4f(clr[0], clr[1], clr[2], clr[3]);
        }
        
        [tw draw];
    }
    
    //draw the exploding words
    for(TessWord *tw in doneMiddleWords)
    {
        if([tw isColorSet])
        {
            float *clr = [tw getColor];
            glColor4f(clr[0], clr[1], clr[2], clr[3]);
        }
        
        [tw draw];
    }
}

- (void) updateBackground:(long)dt
{
    //if we hit the target, create a new one
    if (bgColor[0] == bgColorTarget[0] && bgColor[1] == bgColorTarget[1] && bgColor[2] == bgColorTarget[2])
    {
        float *clr = [self createPaletteColor:255 layer:BACK];

        bgColorTarget[0] = clr[0];
        bgColorTarget[1] = clr[1];
        bgColorTarget[2] = clr[2];
    }    

    //fade each color element
    float diff;
    float delta;
    int direction;
    for (int i = 0; i < 3; i++)
    {
        diff = bgColorTarget[i] - bgColor[i];
        if (diff != 0)
        {
            delta = bgColorSpeed[i] * dt;
            direction = diff < 0 ? -1 : 1;
            
            if ((diff * direction) < delta)
                bgColor[i] = bgColorTarget[i];
            else
                bgColor[i] += delta*direction;
        }
    }
}

- (void) updateBgLetters:(long)dt
{
    //letters to remove
    NSMutableArray* lettersToRemove = [[NSMutableArray alloc] init];
    
    //udpate letters
    int count = 0;
    for(TessGlyph *tg in bgLetters)
    {
        [tg wander];
        
        if(count < (int)([bgLetters count] - TOTAL_BACKGROUND_GLYPHS))
        {
            float *clr = [tg getColor];
            float newAlpha = clr[3] - (1.0f/255.0f);
            float *color = new float[4];
            
            color[0] = clr[0];
            color[1] = clr[1];
            color[2] = clr[2];
            color[3] = (newAlpha > 0.0f ? newAlpha : 0.0f);
            
            [tg fadeTo:color];
        }
        
        [tg update:dt];
        
        float *clr = [tg getColor];
        
        if(clr[3] <= 0.0f)
            [lettersToRemove addObject:tg];
        
        count++;
    }
    
    //remove letters
    [bgLetters removeObjectsInArray:lettersToRemove];
    [lettersToRemove release];
}

- (void) drawBgLetters
{
    for(TessGlyph *tg in bgLetters)
    {        
        float *clr = [tg getColor];
        glColor4f(clr[0], clr[1], clr[2], clr[3]);
        
        [tg draw];
    }
}

- (void) updateIdle:(long)dt
{
    //check if we've been idle for a while
    //if so explode all floating words
    //and reset the poem
    if ([middleWords count] == 0) return;
    if ([[NSDate date] timeIntervalSince1970] - lastTouch < IDLE_TIMEOUT) return;
    
    //words to remove
    NSMutableArray *removeObj = [[NSMutableArray alloc] init];
    
    for(TessWord *aWord in middleWords)
    {
        TessGlyph *tg = [aWord extract:[aWord extractGlyphIndex]];
        [bgLetters addObject:tg];
        
        [doneMiddleWords addObject:aWord];
        [removeObj addObject:aWord];
    }
    
    //remove words
    [middleWords removeObjectsInArray:removeObj];    
    
    [removeObj release];
    
    stringIndex = 0;
}

- (TessSentence*) createSentence
{
    OKSentenceObject *grp = [textStrings objectAtIndex:stringIndex];
        
    TessSentence *ts = [[TessSentence alloc] initTessSentence:grp font:tessFont accuracyLow:TESS_DETAIL_LOW accuracyHigh:TESS_DETAIL_HIGH];
    [ts setSmooth:self];
    float *clr = [self createPaletteColor:FONT_SENTENCE_OPACITY layer:FRONT];
    [ts setColor:clr];
    [ts setExtractIndexesWord:WORD_INDEXES[stringIndex] glyph:GLYPH_INDEXES[stringIndex]];
    delete [] clr;
    
    [ts fold];
    [ts setState:2];
    
    return ts;
}

- (float*) createPaletteColor:(int)a layer:(int)layer
{    
    //get the right palette
    int* palette = nil;
    float *color = new float[4];
    int paletteLength = 0;
    
    if(layer == FRONT) {
        palette = PALETTE_FG;
        paletteLength = PALETTE_FG_COUNT;
    } else if(layer == MIDDLE) {
        palette = PALETTE_MG;
        paletteLength = PALETTE_MG_COUNT;
    } else if(layer == BACK) {
        palette = PALETTE_BG;
        paletteLength = PALETTE_BG_COUNT;
    }
    
    color[0] = 0.0f;
    color[1] = 0.0f;
    color[2] = 0.0f;
    color[3] = 0.0f;
    
    //if no palette was found, return black
    if (!palette) return color;
    
    //get a random color from the palette
    int index = arc4random() % paletteLength;
    int theColor = palette[index];
    int r = red(theColor);
    int g = green(theColor);
    int b = blue(theColor);
    
    //don't offset front layer
    
    color[0] = r/255.0f;
    color[1] = g/255.0f;
    color[2] = b/255.0f;
    color[3] = a/255.0f;
    
    if (layer == FRONT) return color;
    
    //offset color so that it's not always the same few
    r += (int)(random_minus1_1()*PALETTE_RED_OFFSET);
    if (r < 0) r = 0;
    else if (r > 255) r = 255;
    
    g += (int)(random_minus1_1()*PALETTE_GREEN_OFFSET);
    if (g < 0) g = 0;
    else if (g > 255) g = 255;
    
    b += (int)(random_minus1_1()*PALETTE_BLUE_OFFSET);
    if (b < 0) b = 0;
    else if (b > 255) b = 255;
    
    color[0] = r/255.0f;
    color[1] = g/255.0f;
    color[2] = b/255.0f;
    color[3] = a/255.0f;
    
    return color;
}

- (void) touchesBeganID:(int)aID at:(CGPoint)aPoint
{
    OKTouch *touch = [[OKTouch alloc] initWithId:aID andPos:aPoint];
    [touches setObject:touch forKey:[NSString stringWithFormat:@"%i", aID]];
    [touch release];
    
    if(!tessSentence)
    {
        TessSentence *ts = [[self createSentence] retain]; 
        [ts setCtrlPoint:aID x:aPoint.x y:(bounds.size.height-aPoint.y) + TOUCH_OFFSET];
        tessSentence = ts;
    }
    else
    {
        [tessSentence setCtrlPoint:aID x:aPoint.x y:(bounds.size.height-aPoint.y) + TOUCH_OFFSET];
    }
    
    lastTouch = [[NSDate date] timeIntervalSince1970];
}

- (void) touchesMovedID:(int)aID at:(CGPoint)aPoint
{
    OKTouch *touch = [touches objectForKey:[NSString stringWithFormat:@"%i", aID]];
    
    if(touch)
    {
        touch.pos = CGPointMake(aPoint.x, (bounds.size.height-aPoint.y) + TOUCH_OFFSET);
        [touches setObject:touch forKey:[NSString stringWithFormat:@"%i", aID]];
    }

    if(tessSentence)
        [tessSentence setCtrlPoint:aID x:aPoint.x y:(bounds.size.height-aPoint.y) + TOUCH_OFFSET];
}

- (void) touchesEndedID:(int)aID
{
    //remove touches
    [touches removeObjectForKey:[NSString stringWithFormat:@"%i", aID]];
    
    //if there is not active sentences, then nothing to do
    if(!tessSentence) return;
    
    //move active sentence to non-interactive list   
    [doneTessSentences addObject:tessSentence];
    
    //if the string is not completely unfolded, then fold it back
    if (![tessSentence isUnfolded])
        [tessSentence setState:1];
    //if it's unfolded then set its state to snap
    else
        [tessSentence setState:3];
    
    //no more active sentence
    tessSentence = nil;
    [tessSentence release];
}

- (void) touchesCancelledID:(int)aID
{
    //remove touches
    [touches removeObjectForKey:[NSString stringWithFormat:@"%i", aID]];
    
    //if there is not active sentences, then nothing to do
    if(!tessSentence) return;
    
    //move active sentence to non-interactive list   
    [doneTessSentences addObject:tessSentence];
    
    //if the string is not completely unfolded, then fold it back
    if (![tessSentence isUnfolded])
        [tessSentence setState:tessSentence.FOLD];
    
    //if it's unfolded then set its state to snap
    else
        [tessSentence setState:tessSentence.SNAP];
    
    //no more active sentence
    tessSentence = nil;
    [tessSentence release];
}

- (void)dealloc
{	
    [doneTessSentences release];
    [middleWords release];
    [doneMiddleWords release];
    [bgLetters release];
    [now release];
    [lastUpdate release];
    [textStrings release];
    [touches release];    
    
    [super dealloc];
}

@end
