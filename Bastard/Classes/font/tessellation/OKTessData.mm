//
//  OKTessData.m
//  OKBitmapFontSample
//
//  Created by Christian Gratton on 11-07-11.
//  Copyright 2011 Christian Gratton. All rights reserved.
//

#import "OKTessData.h"


@implementation OKTessData
@synthesize ID, /*shapes, ends, vertices,*/ shapesCount, endsCount, verticesCount, verticesAr, typesAr, endsAr;

- (id) initWithID:(int)aID
{
    self = [self init];
	if (self != nil)
    {
		ID = aID;
	}
	return self;
}

- (void) fillVertices:(NSMutableArray*)aArray
{
    verticesCount = [aArray count]; 
    verticesAr = new GLfloat[(verticesCount*2)];
    int iterator = 0;
    
    for(int i = 0; i < verticesCount; i++)
    {
        NSArray *vertX = [NSArray arrayWithArray:[aArray objectAtIndex:i]];
        NSArray *vertY = [NSArray arrayWithArray:[aArray objectAtIndex:i]];
        
        verticesAr[iterator] = ([[vertX objectAtIndex:0] doubleValue]);
        verticesAr[(iterator + 1)] = ([[vertY objectAtIndex:1] doubleValue]);
        
        iterator += 2;
    }
}

- (void) fillShapes:(NSMutableArray*)aArray
{
    shapesCount = [aArray count];
    typesAr = new GLint[shapesCount];
    
    for(int i = 0; i < shapesCount; i++)
    {
        if([[aArray objectAtIndex:i] isEqualToString:@"t"])
            typesAr[i] = GL_TRIANGLES;
        else if([[aArray objectAtIndex:i] isEqualToString:@"f"])
            typesAr[i] = GL_TRIANGLE_FAN;
        else if([[aArray objectAtIndex:i] isEqualToString:@"s"])
            typesAr[i] = GL_TRIANGLE_STRIP;
    }
}

- (void) fillEnds:(NSMutableArray*)aArray
{
    endsCount = [aArray count];
    endsAr = new GLint[endsCount];
    
    for(int i = 0; i < endsCount; i++)
    {
        endsAr[i] = [[aArray objectAtIndex:i] intValue];
    }
}

//copy
- (id) initWithCopy:(OKTessData*)aTessData
{
    self = [self init];
	if (self != nil)
    {
		ID = aTessData.ID;
        verticesCount = aTessData.verticesCount;
        shapesCount = aTessData.shapesCount;
        endsCount = aTessData.endsCount;
        
        int numVertices = verticesCount;
        verticesAr = new GLfloat[(numVertices*2)];
        memcpy(verticesAr, [aTessData getVertices], numVertices*2);
        
        int numTypes = shapesCount;
        typesAr = new GLint[numTypes];
        memcpy(typesAr, [aTessData getTypes], numTypes);
        
        int numEnds = endsCount;
        endsAr = new GLint[numEnds];
        memcpy(endsAr, [aTessData getEnds], numEnds);
	}
	return self;
}

- (id)copyWithZone:(NSZone *)zone
{
	OKTessData *copy = [[[self class] allocWithZone: zone] init];
    
    copy.ID = [self ID];
    copy.verticesCount = [self verticesCount];
    copy.shapesCount = [self shapesCount];
    copy.endsCount = [self endsCount];
   
    int numVertices = [self verticesCount];
    copy.verticesAr = new GLfloat[(numVertices*2)];
    memcpy(copy.verticesAr, verticesAr, numVertices*2*sizeof(GLfloat));
    
    int numTypes = [self shapesCount];
    copy.typesAr = new GLint[numTypes];
    memcpy(copy.typesAr, typesAr, numTypes*sizeof(GLint));
    
    int numEnds = [self endsCount];
    copy.endsAr = new GLint[numEnds];
    memcpy(copy.endsAr, endsAr, numEnds*sizeof(GLint));
    
    return copy;
}

- (GLfloat*) getVertices { return verticesAr; }

- (GLfloat*) getVertices:(int)aShape
{
    return &verticesAr[(aShape == 0 ? 0 : (endsAr[(aShape - 1)] * 2))];
}

- (GLint*) getTypes { return typesAr; }
- (GLint) getType:(int)aShape { return typesAr[aShape]; }
- (GLint) numVertices { return verticesCount; }
- (GLint) numVertices:(int)aShape
{
    int shapeEnd = endsAr[aShape];
    int shapeStart = aShape == 0 ? 0 : endsAr[(aShape - 1)];
    return shapeEnd - shapeStart;
}

- (GLint*) getEnds { return endsAr; }
- (GLint) getEnds:(int)aShape { return endsAr[aShape]; }

- (void) dealloc
{
    delete [] verticesAr;
    delete [] typesAr;
    delete [] endsAr;
    [super dealloc];
}

@end
