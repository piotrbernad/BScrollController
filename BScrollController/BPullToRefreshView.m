//
//  BPullToRefreshView.m
//  BScrollController
//
//  Created by Piotr Bernad on 10.10.2013.
//  Copyright (c) 2013 Piotr Bernad. All rights reserved.
//

#import "BPullToRefreshView.h"
#import <QuartzCore/QuartzCore.h>

#define beginRed 0.80f
#define beginGreen 0.80f
#define beginBlue 0.80f

#define destinationRed 0.88f
#define destinationGreen 0.07f
#define destinationBlue 0.44f

@implementation BPullToRefreshView {
    UILabel *_textLabel;
    CABasicAnimation *anim;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        [self setBackgroundColor:[UIColor whiteColor]];
        
        _textLabel = [[UILabel alloc] init];
        [_textLabel setFrame:CGRectMake(0, 5.0f, CGRectGetWidth(self.bounds), 20.0f)];
        [_textLabel setText:@"Pull to refresh"];
        [_textLabel setTextColor:[UIColor darkGrayColor]];
        [_textLabel setFont:[UIFont boldSystemFontOfSize:20.0f]];
        [_textLabel setTextAlignment:NSTextAlignmentCenter];
        [_textLabel setBackgroundColor:[UIColor clearColor]];
        [self addSubview:_textLabel];
        
    }
    return self;
}

- (void)setProgress:(CGFloat)progress {
    
    CGFloat currentRed = beginRed + (destinationRed - beginRed) * progress;
    CGFloat currentGreen = beginGreen + (destinationGreen - beginGreen) * progress;
    CGFloat currentBlue = beginBlue + (destinationBlue - beginBlue) * progress;
    
    [_textLabel setTextColor:[UIColor colorWithRed:currentRed green:currentGreen blue:currentBlue alpha:1.0f]];
    [_textLabel setFrame:CGRectMake(0, floorf(5.0f + (30.0f * progress)), CGRectGetWidth(self.bounds), 20.0f)];
    
    if (progress > 0.95f) {
        [_textLabel setTextColor:[UIColor colorWithRed:0.38f green:0.13f blue:0.50f alpha:1.00f]];
    }
    
    [_textLabel setNeedsDisplay];
    
}

@end
