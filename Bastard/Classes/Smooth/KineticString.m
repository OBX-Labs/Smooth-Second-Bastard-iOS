//
//  KineticString.m
//  Smooth
//
//  Created by Christian Gratton on 11-07-26.
//  Copyright 2011 Christian Gratton. All rights reserved.
//

#import "KineticString.h"

#import "KineticObject.h"


@implementation KineticString

- (id) initWithString:(NSString*)aString
{
    self = [super init];
	if(self)
    {
		string = aString;
        group = -1;
	}
	return self;
}

- (void)dealloc
{	
    [super dealloc];
}

@end
