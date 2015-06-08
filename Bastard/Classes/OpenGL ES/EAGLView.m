//
//  EAGLView.m
//  FingerTextTest_iPad
//
//  Created by Christian Gratton on 11-05-17.
//  Copyright 2011 Christian Gratton. All rights reserved.
//

#import "EAGLView.h"

#import "OKTessFont.h"
#import "OKTextObject.h"
#import "ES1Renderer.h"

#import "Smooth.h"

#import "OKBitmapFont.h"
#import "OKPoEMMProperties.h"
#import "OKTextManager.h"

#define IS_IPAD_RETINA (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad && [[UIScreen mainScreen] scale] > 1.9f) // iPad 3 or more
#define IS_IPHONE_5 (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone && [[UIScreen mainScreen] bounds].size.height == 568.0f)
#define CAN_RENDER_FULL_FPS (IS_IPAD_RETINA || IS_IPHONE_5)

static BOOL DEBUG_FRAMERATE = NO;
static BOOL SHOULD_RENDER_FULL_FPS = YES;
static EAGLView * openglView = nil;

@interface EAGLView ()
@property (nonatomic, getter=isAnimating) BOOL animating;
@end

@implementation EAGLView

@synthesize animating, animationFrameInterval, displayLink, animationTimer, smooth, windowFrame, stopLayout;

// You must implement this method
+ (Class)layerClass
{
    return [CAEAGLLayer class];
}

- (id) initWithFrame:(CGRect)aFrame multisampling:(BOOL)canMultisample andSamples:(int)aSamples
{
    self = [super initWithFrame:aFrame];
    if (self)
    {
        // Get the layer
        CAEAGLLayer *eaglLayer = (CAEAGLLayer *)self.layer;
        
        eaglLayer.opaque = TRUE;
        eaglLayer.drawableProperties = [NSDictionary dictionaryWithObjectsAndKeys:
                                        [NSNumber numberWithBool:FALSE], kEAGLDrawablePropertyRetainedBacking, kEAGLColorFormatRGBA8, kEAGLDrawablePropertyColorFormat, nil];
        
        [self setContentScaleFactor:[[UIScreen mainScreen] scale]]; // sets the scale based on the device
        [self setMultipleTouchEnabled:YES];
        
        lbl_frameRate = [[UILabel alloc] initWithFrame:CGRectMake((self.frame.size.width - 50), (self.frame.size.height - 20), 50, 20)];
        
        if(DEBUG_FRAMERATE)
        {
            [lbl_frameRate setTextColor:[UIColor orangeColor]];
            [lbl_frameRate setBackgroundColor:[UIColor clearColor]];
            [lbl_frameRate setFont:[UIFont boldSystemFontOfSize:15]];
            [lbl_frameRate setTextAlignment:NSTextAlignmentCenter];
            [self addSubview:lbl_frameRate];
            [lbl_frameRate release];
        }
        
        bool canMultiSample = NO;
        
        if(canMultisample)
        {
            NSString *reqVer = @"4.0.0";
            NSString *currVer = [[UIDevice currentDevice] systemVersion];
            if ([currVer compare:reqVer options:NSNumericSearch] != NSOrderedAscending)
                canMultiSample = YES;
        }
		
		//ES1Renderer (no shaders)
		renderer = [[ES1Renderer alloc] initWithMultisampling:canMultiSample andNumberOfSamples:aSamples];
        [renderer setFrame:self.frame];
        
		if (!renderer)
		{
			[self release];
			return nil;
		}
                
        [self setup];
        
        animating = FALSE;
        displayLinkSupported = FALSE;
        animationFrameInterval = ((CAN_RENDER_FULL_FPS && SHOULD_RENDER_FULL_FPS) ? 1 : 2);
        displayLink = nil;
        animationTimer = nil;
        
        // A system version of 3.1 or greater is required to use CADisplayLink. The NSTimer
        // class is used as fallback when it isn't available.
        NSString *reqSysVer = @"3.1";
        NSString *currSysVer = [[UIDevice currentDevice] systemVersion];
        if ([currSysVer compare:reqSysVer options:NSNumericSearch] != NSOrderedAscending)
            displayLinkSupported = TRUE;
        
        // Add NSNotificationCenter observers for OKInfoView
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(infoViewWillAppear) name:@"OKInfoViewWillAppear" object:self.window];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(infoViewWillDisappear) name:@"OKInfoViewWillDisappear" object:self.window];
    }
    return self;
}

- (void) setup
{
    // Reset renderer
    [renderer reset];
    
    // Text path
    NSString *textPath = [OKTextManager textPathForFile:[OKPoEMMProperties objectForKey:TextFile] inPackage:[OKPoEMMProperties objectForKey:Text]];
    NSMutableString *textFile = [NSMutableString stringWithContentsOfFile:textPath encoding:NSUTF8StringEncoding error:nil];
    NSString *fontName = [OKPoEMMProperties objectForKey:FontFile];
    
    // Clean text
    //replace em dash (charID 8212) with - (charID 45)
    unichar emdash = 8212;
    [textFile replaceOccurrencesOfString:[NSString stringWithFormat:@"%C", emdash] withString:@"-" options:NSCaseInsensitiveSearch range:NSMakeRange(0, [textFile length])];
    
    tessFont = [[OKTessFont alloc] initWithControlFile:fontName scale:1.0 filter:GL_LINEAR];
    [tessFont setColourFilterRed:0.0 green:0.0 blue:0.0 alpha:1.0];
    
    smoothText = [[OKTextObject alloc] initWithText:textFile withFont:tessFont andCanvasSize:CGSizeMake(windowFrame.size.width, windowFrame.size.height)];
    smooth = [[Smooth alloc] initWithFont:tessFont andText:smoothText];
}

- (void) infoViewWillAppear { [self stopAnimation]; }
- (void) infoViewWillDisappear  { [self startAnimation]; }

- (void) toggleAnimation {
    
    if([self isAnimating]) [self stopAnimation];
    else [self startAnimation];
}

+ (EAGLView*)openglView { return openglView; }

- (UIImage*)screenCapture
{
    //grab screen for screen shot
    return [renderer glToUIImage];
}

- (void) touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{            
    switch ([[event allTouches] count]) 
    {
        case 1: //Single touch
        {
            UITouch *touch = [[event allTouches] anyObject];	
            CGPoint touchBegan = [touch locationInView:self];
            
            [smooth touchesBeganID:1 at:touchBegan];
            
            break;
        }
        default: //Double touch
        {
            UITouch *touch = [[[event allTouches] allObjects] objectAtIndex:0];	
            CGPoint touchBegan1 = [touch locationInView:self];
            
            UITouch *multitouch = [[[event allTouches] allObjects] objectAtIndex:1];	
            CGPoint touchBegan2 = [multitouch locationInView:self];
            
            [smooth touchesBeganID:1 at:touchBegan1];
            [smooth touchesBeganID:2 at:touchBegan2];
            
            break;
        }
    }
    
    [super touchesBegan:touches withEvent:event];
}

- (void) touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    switch ([[event allTouches] count]) 
    {
        case 1: //Single touch
        {
            UITouch *touch = [[event allTouches] anyObject];	
            CGPoint touchMoved = [touch locationInView:self];
            
            [smooth touchesMovedID:1 at:touchMoved];
            
            break;
        }
        default: //Double touch
        {
            UITouch *touch = [[[event allTouches] allObjects] objectAtIndex:0];	
            CGPoint touchMoved1 = [touch locationInView:self];
            
            UITouch *multitouch = [[[event allTouches] allObjects] objectAtIndex:1];	
            CGPoint touchMoved2 = [multitouch locationInView:self];
            
            [smooth touchesMovedID:1 at:touchMoved1];
            [smooth touchesMovedID:2 at:touchMoved2];
            
            break;
        }
    }
    
    [super touchesMoved:touches withEvent:event];
}

- (CGPoint) convertTouch:(CGPoint)aPoint withZ:(float)z
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

- (void) touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    switch ([[event allTouches] count]) 
    {
        case 1: //Single touch
        {
            [smooth touchesEndedID:1];
            
            break;
        }
        default: //Double touch
        {           
            [smooth touchesEndedID:1];
            [smooth touchesEndedID:2];
            
            break;
        }
    }
    
    [super touchesEnded:touches withEvent:event];
}

- (void) touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    switch ([[event allTouches] count]) 
    {
        case 1: //Single touch
        {
            [smooth touchesEndedID:1];
            
            break;
        }
        default: //Double touch
        {
            [smooth touchesEndedID:1];
            [smooth touchesEndedID:2];
            
            break;
        }
    }
    
    [super touchesCancelled:touches withEvent:event];
}

- (void)drawView:(id)sender
{
    NSDate *startDate = [NSDate date];
    
    glPushMatrix();
    
	glGetFloatv(GL_MODELVIEW_MATRIX, modelview);        // Retrieve The Modelview Matrix
	
	glPopMatrix();
	
	glGetFloatv(GL_PROJECTION_MATRIX, projection);    // Retrieve The Projection Matrix
	
	//rendering etc in here
    [renderer renderSmooth:smooth];
    
    if(DEBUG_FRAMERATE)
        [self getFrameRate:[[NSDate date] timeIntervalSinceDate:startDate]];
}

- (void)getFrameRate:(float)withInterval
{	
	lbl_frameRate.text = [NSString stringWithFormat:@"%.1f", 60-(withInterval*1000)];	
}

- (void)layoutSubviews
{
    if(stopLayout) { stopLayout = NO; return; }
    [renderer resizeFromLayer:(CAEAGLLayer*)self.layer];
    [self drawView:nil];
}

- (NSInteger)animationFrameInterval
{
    return animationFrameInterval;
}

- (void)setAnimationFrameInterval:(NSInteger)frameInterval
{
    // Frame interval defines how many display frames must pass between each time the
    // display link fires. The display link will only fire 30 times a second when the
    // frame internal is two on a display that refreshes 60 times a second. The default
    // frame interval setting of one will fire 60 times a second when the display refreshes
    // at 60 times a second. A frame interval setting of less than one results in undefined
    // behavior.
    if (frameInterval >= 1)
    {
        animationFrameInterval = frameInterval;
        
        if (animating)
        {
            [self stopAnimation];
            [self startAnimation];
        }
    }
}

- (void)startAnimation
{
    if (!animating)
    {
        NSLog(@"start animation");
        if (displayLinkSupported)
        {
            // CADisplayLink is API new to iPhone SDK 3.1. Compiling against earlier versions will result in a warning, but can be dismissed
            // if the system version runtime check for CADisplayLink exists in -initWithCoder:. The runtime check ensures this code will
            // not be called in system versions earlier than 3.1.
            
            self.displayLink = [NSClassFromString(@"CADisplayLink") displayLinkWithTarget:self selector:@selector(drawView:)];
            [displayLink setFrameInterval:animationFrameInterval];
            [displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
        }
        else
            self.animationTimer = [NSTimer scheduledTimerWithTimeInterval:(NSTimeInterval)((1.0 / 60.0) * animationFrameInterval) target:self selector:@selector(drawView:) userInfo:nil repeats:TRUE];
        
        self.animating = TRUE;
    }
}

- (void)stopAnimation
{
    if (animating)
    {
        NSLog(@"stop animation");
        if (displayLinkSupported)
        {
            [displayLink invalidate];
            self.displayLink = nil;
        }
        else
        {
            [animationTimer invalidate];
            self.animationTimer = nil;
        }
        
        self.animating = FALSE;
    }
}

// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationLandscapeRight || interfaceOrientation == UIInterfaceOrientationLandscapeLeft);
}

- (void)dealloc
{
    [renderer release];
    [displayLink release];
	[tessFont release];
    [smooth release];
	
    [super dealloc];
}

@end
