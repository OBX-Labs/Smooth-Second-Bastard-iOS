//
//  TessGlyph.m
//  Smooth
//
//  Created by Christian Gratton on 11-07-27.
//  Copyright 2011 Christian Gratton. All rights reserved.
//

#import "TessGlyph.h"

#import "OKCharDef.h"
#import "TessWord.h"
#import "OKTessData.h"
#import "Smooth.h"
#import "OKCharObject.h"
#import "OKTessFont.h"

#import "EAGLView.h"
#import "OKPoEMMProperties.h"

//constants
static float WANDER_THRESHOLD;    //proximity threshold for wander to create a new target
static float WANDER_FRICTION;  //wandering friction
static float FADE_SPEED;       //color fading speed

static float BACKGROUND_GLYPH_WANDER_RANGE;
static float BACKGROUND_GLYPH_WANDER_SPEED;

@implementation TessGlyph
@synthesize parent;

- (id) initTessGlyph:(OKCharObject*)aChar font:(OKTessFont*)aFont parent:(TessWord*)aParent accuracy:(int)accuracy
{
    self = [super init];
    if(self)
    {
        WANDER_THRESHOLD = [[OKPoEMMProperties objectForKey:GlyphWanderThreshold] floatValue];
        WANDER_FRICTION = [[OKPoEMMProperties objectForKey:GlyphWanderFriction] floatValue];
        FADE_SPEED = [[OKPoEMMProperties objectForKey:GlyphFadeSpeed] floatValue];
        
        BACKGROUND_GLYPH_WANDER_RANGE = [[OKPoEMMProperties objectForKey:BackgroundGlyphWanderRange] floatValue];
        BACKGROUND_GLYPH_WANDER_SPEED = [[OKPoEMMProperties objectForKey:BackgroundGlyphWanderSpeed] floatValue];
        
        self.parent = aParent;
        tessFont = aFont;
        
        //color values
        clr[0] = 0.0f;
		clr[1] = 0.0f;
		clr[2] = 0.0f;
		clr[3] = 1.0f;
		
		clrTarget[0] = 0.0f;
		clrTarget[1] = 0.0f;
		clrTarget[2] = 0.f;
		clrTarget[3] = 1.0f;
        
        [self build:aChar accuracy:accuracy];
    }
    return self;
}

- (void) build:(OKCharObject*)aChar accuracy:(int)accuracy
{
    //get the center of the glyph and use that as positoin
    OKPoint newPoint = [aChar getPositionAbsolute];
    CGRect gBounds = [aChar getLocalBoundingBox];
    OKPoint gCenter = OKPointMake(gBounds.origin.x + gBounds.size.width/2, gBounds.origin.y + gBounds.size.height/2, 0.0);
    
    newPoint = OKPointAdd(newPoint, gCenter);
    [self setPos:newPoint];
        
    //tessalate text in original form
    origData = [self tesselate:[tessFont getCharDefForChar:aChar.charObj] accuracy:accuracy];
        
    //offset the vertices so that they are relative to the glyph's position
    if(origData.endsCount > 0)
    {
        GLfloat *vertices = [origData getVertices];
        int numVertices = [origData numVertices];
        
        for(int i = 0; i < numVertices; i++) {
            vertices[i*2 + 0] -= gCenter.x;
            vertices[i*2 + 1] -= gCenter.y;
        }
    }
    
    //clone to deformed data
    dfrmData = [origData copy];
    
    test = [[NSString alloc] initWithString:aChar.charObj];
}

- (OKTessData*) tesselate:(OKCharDef*)aCharDef accuracy:(int)accuracy
{
    return [[aCharDef.tessData objectForKey:[NSString stringWithFormat:@"%i", accuracy]] copy];
}

- (void) update:(long)dt
{
    [super update:dt];
    
    //update color
    [self updateColor:dt];
}

- (void) draw
{
    glPushMatrix();
    glTranslatef(pos.x, pos.y, pos.z);
    glRotatef(ang, 0.0, 0.0, 1.0);
    glScalef(sca, sca, 0.0);
    
    //keep track of bounding box
    float minX = CGFLOAT_MAX;
    float maxX = CGFLOAT_MIN;
    float minY = CGFLOAT_MAX;
    float maxY = CGFLOAT_MIN;
    
    //not a space
        //if we have deformed data then draw it
    //if we have deformed data then draw it
    if (dfrmData)
    {
        OKTessData *data = dfrmData;
        
        if(data.endsCount > 0)
        {
            for(int i = 0; i < data.shapesCount; i++)
            {                    
                glVertexPointer(2, GL_FLOAT, 0, [data getVertices:i]);
                glEnableClientState(GL_VERTEX_ARRAY);
                glDrawArrays([data getType:i], 0, [data numVertices:i]);
            }
            
            GLfloat *vertices = [origData getVertices:0];
            
            for(int i = 0; i < origData.verticesCount; i++)
            {            
                if(vertices[i * 2 + 0] < minX) minX = vertices[i * 2 + 0];
                if(vertices[i * 2 + 0] > maxX) maxX = vertices[i * 2 + 0];
                if(vertices[i * 2 + 1] < minY) minY = vertices[i * 2 + 1];
                if(vertices[i * 2 + 1] > maxY) maxY = vertices[i * 2 + 1];
            }
        }
    }
    
    //update the bounds   
    bounds = CGRectMake(minX, minY, maxX-minX, maxY-minY);
    
    glPushMatrix();
    
	glGetFloatv(GL_MODELVIEW_MATRIX, modelview);        // Retrieve The Modelview Matrix
	
	glPopMatrix();
	
	glGetFloatv(GL_PROJECTION_MATRIX, projection);    // Retrieve The Projection Matrix
    
    //might need to offset to absPos of glyph
    CGPoint aPointMin = [self convertPoint:CGPointMake(minX, minY) withZ:0.0];
    CGPoint aPointMax = [self convertPoint:CGPointMake(maxX, maxY) withZ:0.0];
    
    absBounds = CGRectMake(aPointMin.x, aPointMin.y, aPointMax.x-aPointMin.x, aPointMax.y-aPointMin.y);
    
    if(absBounds.size.width < 1) absBounds.size.width++;
    if(absBounds.size.height < 1) absBounds.size.height++;

    if([test isEqualToString:@" "])
        NSLog(@"%@", test);
    
//    //debug bounding box
//    const GLfloat line[] =
//    {
//        minX, minY, //point A
//        minX, maxY, //point B
//        maxX, maxY, //point C
//        maxX, minY, //point D
//    };
//
//    glVertexPointer(2, GL_FLOAT, 0, line);
//    glEnableClientState(GL_VERTEX_ARRAY);
//    glDrawArrays(GL_LINE_LOOP, 0, 4);

    glPopMatrix();
}

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

- (BOOL) isColorSet
{
    return isSetColor;
}

//set the color to fade to
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

//fold the glyph so that it's in the middle of the sentence
- (void) fold
{
    OKTessData *data = dfrmData;
    
    if(data.endsCount > 0)
    {
        for(int i = 0; i < data.shapesCount; i++)
        {        
            GLfloat *vertices = [data getVertices:i];
            for(int j = 0; j < [data numVertices:i]; j++)
            {
                vertices[j * 2 + 0] = -(parent.pos.x + pos.x);
            }
        }
    }             
}

//fold the glyph towards the middle of the sentence
- (void) fold:(long)dt distance:(float)aDistance speed:(float)aSpeed
{
    if (origData)
    { 
        //go through vertices
        for(int i = 0; i < origData.shapesCount; i++)
        {                
            GLfloat *vertices = [origData getVertices:i];
            int numVertices = [origData numVertices:i];
            GLfloat *dfrmVertices = [dfrmData getVertices:i];
            
            //loop through all the vertices of this shape
            for(int j = 0; j < numVertices; j++) {
                //get the distance between the original position and the middle of the sentence 
                float d = parent.pos.x + pos.x + vertices[j*2 + 0];
                if(d < 0) d *= -1;
                
                //if the vertex is closer than the threshold distance
                //that affects vertices then attract vertex towards middle         
                if (d < aDistance)
                {
                    float dx = -(parent.pos.x + pos.x) - dfrmVertices[j*2 + 0];
                    float dy = 0;
                    float dd = sqrtf((dx * dx) + (dy * dy));
                    
                    if(dd < (dt * aSpeed))
                    {
                        //change vertices
                        dfrmVertices[j*2 + 0] += dx;
                        dfrmVertices[j*2 + 1] += dy;
                    }
                    else
                    {
                        dfrmVertices[j*2 + 0] += dx/dd * dt * aSpeed;
                        dfrmVertices[j*2 + 1] += dy/dd * dt * aSpeed;
                    }
                }
            }
        }
    }
}

//unfold the glyph towards its original state
- (void) unfold:(long)dt distance:(float)aDistance speed:(float)aSpeed
{
    if (origData)
    { 
        //go through vertices
        for(int i = 0; i < origData.shapesCount; i++)
        {  
            GLfloat *vertices = [origData getVertices:i];
            int numVertices = [origData numVertices:i];
            GLfloat *dfrmVertices = [dfrmData getVertices:i];
            
            //loop through all the vertices of this shape
            for(int j = 0; j < numVertices; j++) {
            
                //get the distance between the original position and the middle of the sentence 
                float d = parent.pos.x + pos.x + vertices[j*2 + 0];
                if(d < 0) d *= -1;
                
                //if the vertex is closer than the threshold distance
                //that affects vertices then attract vertex towards middle         
                if (d > aDistance)
                {
                    float dx = vertices[j*2 + 0] - dfrmVertices[j*2 + 0];
                    float dy = vertices[j*2 + 1] - dfrmVertices[j*2 + 1];
                    float dd = sqrtf((dx * dx) + (dy * dy));
                    
                    if(dd < (dt * aSpeed))
                    {
                        //change vertices
                        dfrmVertices[j*2 + 0] += dx;
                        dfrmVertices[j*2 + 1] += dy;
                    }
                    else
                    {
                        dfrmVertices[j*2 + 0] += dx/dd * dt * aSpeed;
                        dfrmVertices[j*2 + 1] += dy/dd * dt * aSpeed;
                    }
                }
            }
        }
    }
}

//make glyph wander around
- (void) wander
{
    if(OKPointDist(pos, target) < WANDER_THRESHOLD)
    {        
        float angle = [self floatRandom] * (M_PI*2);
        [self approachX:(pos.x + (cos(angle) * BACKGROUND_GLYPH_WANDER_RANGE)) y:([UIScreen mainScreen].bounds.size.height/2 + (sin(angle) * BACKGROUND_GLYPH_WANDER_RANGE)) z:pos.z s:BACKGROUND_GLYPH_WANDER_SPEED f:WANDER_FRICTION];
    }
}

//check if the word is outside bounds
- (BOOL) isOutside:(CGRect)b
{    
    if(CGRectIntersectsRect(b, absBounds))
        return NO;
    else
        return YES;
    
    return YES;
}

//get local bounds
- (CGRect) getBounds
{
    return bounds;
}

//get the absolute bounds
- (CGRect) getAbsoluteBounds
{    
    return absBounds;
}

- (CGPoint) convertPoint:(CGPoint)aPoint withZ:(float)z
{
    float ax = ((modelview[0] * aPoint.x) + (modelview[4] * aPoint.y) + (modelview[8] * z) + modelview[12]);
	float ay = ((modelview[1] * aPoint.x) + (modelview[5] * aPoint.y) + (modelview[9] * z) + modelview[13]);
	float az = ((modelview[2] * aPoint.x) + (modelview[6] * aPoint.y) + (modelview[10] * z) + modelview[14]);
	float aw = ((modelview[3] * aPoint.x) + (modelview[7] * aPoint.y) + (modelview[11] * z) + modelview[15]);
	
	float ox = ((projection[0] * ax) + (projection[4] * ay) + (projection[8] * az) + (projection[12] * aw));
	float oy = ((projection[1] * ax) + (projection[5] * ay) + (projection[9] * az) + (projection[13] * aw));
	float ow = ((projection[3] * ax) + (projection[7] * ay) + (projection[11] * az) + (projection[15] * aw));
	
	if(ow != 0)
		ox /= ow;
	
	if(ow != 0)
		oy /= ow;
	
	return CGPointMake(([UIScreen mainScreen].bounds.size.height * (1 + ox) / 2.0f), ([UIScreen mainScreen].bounds.size.width * (1 + oy) / 2.0f));
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
    [parent release];
    
    [super dealloc];
}

- (void) drawDeprec
{
    //NSLog(@"%f %f %f", pos.x, pos.y, pos.z);
    glPushMatrix();
    glTranslatef(pos.x, pos.y, pos.z);
    glRotatef(ang, 0.0, 0.0, 1.0);
    glScalef(sca, sca, 0.0);
    
    //keep track of bounding box
    float minX = CGFLOAT_MAX;
    float maxX = CGFLOAT_MIN;
    float minY = CGFLOAT_MAX;
    float maxY = CGFLOAT_MIN;
    
    //if we have deformed data then draw it
    if (dfrmData)
    {
        OKTessData *data = dfrmData;
        
        if(data.endsCount > 0)
        {
            for(int i = 0; i < data.shapesCount; i++)
            {
                GLfloat *vertices = [data getVertices:i];
                if(vertices[i * 2 + 0] < minX) minX = vertices[i * 2 + 0];
                if(vertices[i * 2 + 0] > maxX) maxX = vertices[i * 2 + 0];
                if(vertices[i * 2 + 1] < minY) minY = vertices[i * 2 + 1];
                if(vertices[i * 2 + 1] > maxY) maxY = vertices[i * 2 + 1];
                
                glVertexPointer(2, GL_FLOAT, 0, [data getVertices:i]);
                glEnableClientState(GL_VERTEX_ARRAY);
                glDrawArrays([data getType:i], 0, [data numVertices:i]);
            }
        }
    }
    
    //update the bounds   
    bounds = CGRectMake(minX, minY, maxX-minX, maxY-minY);
    
    glPushMatrix();
    
	glGetFloatv(GL_MODELVIEW_MATRIX, modelview);        // Retrieve The Modelview Matrix
	
	glPopMatrix();
	
	glGetFloatv(GL_PROJECTION_MATRIX, projection);    // Retrieve The Projection Matrix
    
    //might need to offset to absPos of glyph
    CGPoint aPointMin = [self convertPoint:CGPointMake(minX, minY) withZ:0.0];
    CGPoint aPointMax = [self convertPoint:CGPointMake(maxX, maxY) withZ:0.0];
    
    absBounds = CGRectMake(aPointMin.x, aPointMin.y, aPointMax.x-aPointMin.x, aPointMax.y-aPointMin.y);
    
    if(absBounds.size.width < 1) absBounds.size.width++;
    if(absBounds.size.height < 1) absBounds.size.height++;
    
    //debug bounding box
    //    const GLfloat line[] =
    //    {
    //        minX, minY, //point A
    //        minX, maxY, //point B
    //        maxX, maxY, //point C
    //        maxX, minY, //point D
    //    };
    //    
    //    glVertexPointer(2, GL_FLOAT, 0, line);
    //    glEnableClientState(GL_VERTEX_ARRAY);
    //    glDrawArrays(GL_LINE_LOOP, 0, 4);
    
    glPopMatrix();
}

@end
