//
//  ES1Renderer.h
//  BuzzAldrin
//
//  Created by Christian Gratton on 10-12-02.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "ESRenderer.h"

#import <OpenGLES/ES1/gl.h>
#import <OpenGLES/ES1/glext.h>

#import "OKTessFont.h"
#import "OKTextObject.h"

@class Smooth;

@interface ES1Renderer : NSObject <ESRenderer>
{
@private
    EAGLContext *context;
    
    // The pixel dimensions of the CAEAGLLayer
    GLint backingWidth;
    GLint backingHeight;
    
    // The OpenGL ES names for the framebuffer and renderbuffer used to render to this view
    GLuint defaultFramebuffer, colorRenderbuffer;
    
	//buffers for MSAA
	GLuint msaaFramebuffer, msaaColorbuffer;
    
	BOOL glInitialised;
    BOOL multiSampling;
    
    int samplesToUse;
    int pixelFormat;
    
    //window frame
    CGRect wFrame;
}

- (id) initWithMultisampling:(BOOL)aMultiSampling andNumberOfSamples:(int)requestedSamples;
- (void) reset;
- (void) render;
- (void) setFrame:(CGRect)aFrame;
- (void) renderSmooth:(Smooth*)aSmooth;
- (BOOL) resizeFromLayer:(CAEAGLLayer *)layer;

- (void) initOpenGL;

-(UIImage *) glToUIImage;

@end
