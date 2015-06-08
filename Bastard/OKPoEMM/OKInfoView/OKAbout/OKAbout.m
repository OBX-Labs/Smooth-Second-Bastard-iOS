//
//  OKAbout.m
//  OKPoEMM
//
//  Created by Christian Gratton on 2013-02-06.
//  Copyright (c) 2013 Christian Gratton. All rights reserved.
//

#import "OKAbout.h"
#import "OKAppProperties.h"
#import "OKInfoViewProperties.h"

#import "OKInfoView.h"
#import "OKInfoText.h"
#import "OKMoreApps.h"

static float FRAME_PADDING = 25.0f;
static float PADDING = 10.0f;
static float HEADER_HEIGHT = 85.0f;
static float LIMITEDEDITION_HEIGHT = 25.0f;
static float SCROLLVIEW_HEIGHT = 302.0f;
static float MOREAPPS_HEIGHT = 100.0f;

@interface OKAbout ()
- (void) setLimitedEditionVersion;
- (void) formatForIpad;
- (void) formatForIphone;
@end

@implementation OKAbout

- (id) initWithTitle:(NSString *)aTitle icon:(UIImage *)aIcon
{
    self = [super init];
    if (self)
    {
        [self setTitle:aTitle];
        [self.tabBarItem setImage:aIcon];
        [self.view setBackgroundColor:[UIColor whiteColor]];
    }
    return self;
}

// Sets limited edition version
- (void) setLimitedEditionVersion
{
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    int maxVersions = [[OKAppProperties objectForKey:@"LimitedEditionMaxVersions"] intValue];
        
    if(![prefs stringForKey:@"version"]) [limitedEdition setText:@"Not Registered"];
    else [limitedEdition setText:[NSString stringWithFormat:@"%@", ([[prefs stringForKey:@"version"] isEqualToString:@"DEMO"] ? @"DEMO" : [NSString stringWithFormat:@"Limited Edition %@ out of %i.", [prefs stringForKey:@"version"], maxVersions])]];
}

// Formats view for iPad
- (void) formatForIpad
{
    // Header
    UIImageView *header = [[UIImageView alloc] initWithFrame:CGRectMake(FRAME_PADDING, PADDING, self.view.frame.size.width - (FRAME_PADDING * 2.0f), HEADER_HEIGHT)];
    [header setImage:[UIImage imageNamed:[[[OKInfoViewProperties objectForKey:@"Style"] objectForKey:@"Images"] objectForKey:@"header"]]];
    [header setBackgroundColor:[UIColor clearColor]];
    [self.view addSubview:header];
    
    // Info Text
    // ScrollView
    scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0.0f, header.frame.origin.y + header.frame.size.height + PADDING, self.view.frame.size.width, SCROLLVIEW_HEIGHT)];
    [scrollView setBackgroundColor:[UIColor clearColor]];
    [scrollView setCanCancelContentTouches:NO];
    
    NSString *textPath = [[NSBundle mainBundle] pathForResource:@"OKInfoView_Description" ofType:@"txt"];
    NSString *infoText = [NSString stringWithContentsOfFile:textPath encoding:NSUTF8StringEncoding error:nil];
    UIFont *font = [UIFont fontWithName:@"Museo-500" size:14.0f];
    
    // Get starting y of label
    float y = 0.0f; //header.frame.origin.y + header.frame.size.height + PADDING
    
    // Check if limited edition
    BOOL isLimitedEdition = [[OKAppProperties objectForKey:@"LimitedEdition"] boolValue];
    
    if(isLimitedEdition)
    {
        limitedEdition = [[UILabel alloc] initWithFrame:CGRectMake(FRAME_PADDING, y, self.view.frame.size.width - (FRAME_PADDING * 2.0f), LIMITEDEDITION_HEIGHT)];
        [limitedEdition setFont:[UIFont fontWithName:@"Dosis-Bold" size:16.0f]];
        [limitedEdition setBackgroundColor:[UIColor clearColor]];
        
        // Set text
        [self setLimitedEditionVersion];
        
        [scrollView addSubview:limitedEdition];
        
        // Update y so text can start with right padding
        y = limitedEdition.frame.origin.y + limitedEdition.frame.size.height + PADDING;
    }
    
    float lHeight = [infoText sizeWithFont:font constrainedToSize:CGSizeMake(scrollView.frame.size.width - (FRAME_PADDING * 2.0f), CGFLOAT_MAX) lineBreakMode:NSLineBreakByWordWrapping].height;
    
    UILabel *text = [[UILabel alloc] initWithFrame:CGRectMake(FRAME_PADDING, y, scrollView.frame.size.width - (FRAME_PADDING * 2.0f), lHeight)];
    [text setLineBreakMode:NSLineBreakByWordWrapping];
    [text setBackgroundColor:[UIColor clearColor]];
    [text setNumberOfLines:0];
    [text setText:infoText];
    [text setFont:font];
    [scrollView addSubview:text];
    
    // ScrollView
    [scrollView setContentSize:CGSizeMake(self.view.frame.size.width, y + lHeight)];
    [self.view addSubview:scrollView];
    
    // More Apps
    OKMoreApps *mApps = [[OKMoreApps alloc] initWithFrame:CGRectMake(FRAME_PADDING, scrollView.frame.origin.y + scrollView.frame.size.height + PADDING, self.view.frame.size.width - (FRAME_PADDING * 2.0f), MOREAPPS_HEIGHT)];
    [mApps setItems:[OKInfoViewProperties objectForKey:@"MoreApps"]];
    [self.view addSubview:mApps];
}

// Format view for iPhone
- (void) formatForIphone
{
    // ScrollView
    scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, self.view.frame.size.width, self.view.frame.size.height)];
    [scrollView setBackgroundColor:[UIColor clearColor]];
    [scrollView setCanCancelContentTouches:NO];
    
    // Header
    UIImageView *header = [[UIImageView alloc] initWithFrame:CGRectMake(FRAME_PADDING, PADDING, self.view.frame.size.width - (FRAME_PADDING * 2.0f), HEADER_HEIGHT)];
    [header setImage:[UIImage imageNamed:[[[OKInfoViewProperties objectForKey:@"Style"] objectForKey:@"Images"] objectForKey:@"header"]]];
    [header setBackgroundColor:[UIColor clearColor]];
    [scrollView addSubview:header];
    
    // Info Text
    NSString *textPath = [[NSBundle mainBundle] pathForResource:@"OKInfoView_Description" ofType:@"txt"];
    NSString *infoText = [NSString stringWithContentsOfFile:textPath encoding:NSUTF8StringEncoding error:nil];
    UIFont *font = [UIFont fontWithName:@"Museo-500" size:14.0f];
    
    // Get starting y of label
    float y = header.frame.origin.y + header.frame.size.height + PADDING;
    
    // Check if limited edition
    BOOL isLimitedEdition = [[OKAppProperties objectForKey:@"LimitedEdition"] boolValue];
    
    if(isLimitedEdition)
    {
        limitedEdition = [[UILabel alloc] initWithFrame:CGRectMake(FRAME_PADDING, y, self.view.frame.size.width - (FRAME_PADDING * 2.0f), 25.0f)];
        [limitedEdition setFont:[UIFont fontWithName:@"Dosis-Bold" size:16.0f]];
        [limitedEdition setBackgroundColor:[UIColor clearColor]];
        
        // Set text
        [self setLimitedEditionVersion];
        
        [scrollView addSubview:limitedEdition];
        
        // Update y so text can start with right padding
        y = limitedEdition.frame.origin.y + limitedEdition.frame.size.height + PADDING;
    }
    
    float lHeight = [infoText sizeWithFont:font constrainedToSize:CGSizeMake(self.view.frame.size.width - (FRAME_PADDING * 2.0f), CGFLOAT_MAX) lineBreakMode:NSLineBreakByWordWrapping].height;
    
    UILabel *text = [[UILabel alloc] initWithFrame:CGRectMake(FRAME_PADDING, y, self.view.frame.size.width - (FRAME_PADDING * 2.0f), lHeight)];
    [text setLineBreakMode:NSLineBreakByWordWrapping];
    [text setBackgroundColor:[UIColor clearColor]];
    [text setNumberOfLines:0];
    [text setText:infoText];
    [text setFont:font];
    [scrollView addSubview:text];
    
    // More Apps
    OKMoreApps *mApps = [[OKMoreApps alloc] initWithFrame:CGRectMake(FRAME_PADDING, text.frame.origin.y + text.frame.size.height + PADDING, self.view.frame.size.width - (FRAME_PADDING * 2.0f), MOREAPPS_HEIGHT)];
    [mApps setItems:[OKInfoViewProperties objectForKey:@"MoreApps"]];
    [scrollView addSubview:mApps];
    
    // ScrollView
    [scrollView setContentSize:CGSizeMake(self.view.frame.size.width, mApps.frame.origin.y + mApps.frame.size.height + PADDING)];
    [self.view addSubview:scrollView];
}

- (void) viewWillAppear:(BOOL)animated
{
    // Check if limited edition and set edition
    if([[OKAppProperties objectForKey:@"LimitedEdition"] boolValue]) [self setLimitedEditionVersion];
}

- (void) viewDidAppear:(BOOL)animated
{
    if([OKAppProperties isiPad] && !scrollView) [self formatForIpad];
    if(![OKAppProperties isiPad] && !scrollView) [self formatForIphone];
    
    [scrollView flashScrollIndicators];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
