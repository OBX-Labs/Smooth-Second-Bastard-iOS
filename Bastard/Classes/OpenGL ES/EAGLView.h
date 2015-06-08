//
//  EAGLView.h
//  FingerTextTest_iPad
//
//  Created by Christian Gratton on 11-05-17.
//  Copyright 2011 Christian Gratton. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>

#import "ESRenderer.h"

@class Smooth;
@class InfoController;

// This class wraps the CAEAGLLayer from CoreAnimation into a convenient UIView subclass.
// The view content is basically an EAGL surface you render your OpenGL scene into.
// Note that setting the view non-opaque will only work if the EAGL surface has an alpha channel.
@interface EAGLView : UIView
{    
@private
    id <ESRenderer> renderer;
    
    BOOL animating;
    BOOL displayLinkSupported;
    NSInteger animationFrameInterval;
    // Use of the CADisplayLink class is the preferred method for controlling your animation timing.
    // CADisplayLink will link to the main display and fire every vsync when added to a given run-loop.
    // The NSTimer class is used only as fallback when running on a pre 3.1 device where CADisplayLink
    // isn't available.
    id displayLink;
    NSTimer *animationTimer;
	
	//Font Object
	OKTessFont *tessFont;
    //Text Object
    OKTextObject *smoothText;
    //Smooth Object
    Smooth *smooth;
    
    BOOL isHorizontal;
    
    //3d points in 2d space arrays
	GLfloat modelview[16];
	GLfloat projection[16];
    
	//frame rate (should be removed for final)
    UILabel *lbl_frameRate;
    
    //window frame
    CGRect windowFrame;
    
    BOOL stopLayout;
}

@property (readonly, nonatomic, getter=isAnimating) BOOL animating;
@property (nonatomic) NSInteger animationFrameInterval;
@property (nonatomic, retain) id displayLink;
@property (nonatomic, assign) NSTimer *animationTimer;
@property (nonatomic, retain) Smooth *smooth;
@property (nonatomic) CGRect windowFrame;
@property (nonatomic, readwrite) BOOL stopLayout;

- (id) initWithFrame:(CGRect)aFrame multisampling:(BOOL)canMultisample andSamples:(int)aSamples;

- (void) setup;

- (void)startAnimation;
- (void)stopAnimation;
- (void)drawView:(id)sender;
- (UIImage*) screenCapture;

+ (EAGLView*)openglView;

- (void)getFrameRate:(float)withInterval;

- (CGPoint) convertTouch:(CGPoint)aPoint withZ:(float)z;

// InfoView

- (void) infoViewWillAppear;
- (void) infoViewWillDisappear;

// Performance

- (void) toggleAnimation;

@end
