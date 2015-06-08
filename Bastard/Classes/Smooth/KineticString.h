//
//  KineticString.h
//  Smooth
//
//  Created by Christian Gratton on 11-07-26.
//  Copyright 2011 Christian Gratton. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface KineticString : NSObject
{
    NSString *string;
    int group;
}

- (id) initWithString:(NSString*)aString;

@end
