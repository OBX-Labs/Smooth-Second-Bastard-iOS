//
//  AppDelegate.h
//  Bastard
//
//  Created by Christian Gratton on 2013-04-25.
//  Copyright (c) 2013 Christian Gratton. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Appirater.h"

@class OKPoEMM;
@class EAGLView;

@interface AppDelegate : UIResponder <UIApplicationDelegate, AppiraterDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (nonatomic, retain) OKPoEMM *poemm;
@property (nonatomic, strong) EAGLView *eaglView;

- (void) setDefaultValues;
- (void) loadOKPoEMMInFrame:(CGRect)frame;
- (void) manageAppirater;

@end
