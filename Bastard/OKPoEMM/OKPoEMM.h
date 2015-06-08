//
//  OKPoEMM.h
//  OKPoEMM
//
//  Created by Christian Gratton on 2013-02-04.
//  Copyright (c) 2013 Christian Gratton. All rights reserved.
//

#import <UIKit/UIKit.h>

@class OKInfoView;

typedef enum
{
    MenuInfoViewTab=0,
    MenuRegisterTab=1,
    MenuShareTab=2,
} MenuTab;

@interface OKPoEMM : UIViewController
{
    // Info View
    OKInfoView *infoView;
    
    // Info View Buttons
    UIButton *lB;
    UIButton *rB;
    NSTimeInterval touchBeganTime;
    NSTimer *toggleViewTimer;
    
    // Exhibition
    BOOL isExhibition;
}

- (id) initWithFrame:(CGRect)aFrame EAGLView:(UIView*)aEAGLView isExhibition:(BOOL)flag;
- (void) openMenuAtTab:(MenuTab)menuTab;
- (void) setisExhibition:(BOOL)flag;

@end
