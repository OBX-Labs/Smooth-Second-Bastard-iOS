//
//  ESRenderer.h
//  BuzzAldrin
//
//  Created by Christian Gratton on 10-12-02.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>

#import <OpenGLES/EAGL.h>
#import <OpenGLES/EAGLDrawable.h>

#import "OKTessFont.h"
#import "OKTextObject.h"

@class Smooth;

@protocol ESRenderer <NSObject>

- (id) initWithMultisampling:(BOOL)aMultiSampling andNumberOfSamples:(int)requestedSamples;
- (void) reset;
- (void) render;
- (void) setFrame:(CGRect)aFrame;
- (void) renderSmooth:(Smooth*)aSmooth;
- (BOOL) resizeFromLayer:(CAEAGLLayer *)layer;

-(UIImage *) glToUIImage;

@end
