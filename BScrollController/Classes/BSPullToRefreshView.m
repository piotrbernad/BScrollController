//
//  BPullToRefreshView.m
//  BScrollController
//
//  Created by Piotr Bernad on 10.10.2013.
//  Copyright (c) 2013 Piotr Bernad. All rights reserved.
//

#import "BSPullToRefreshView.h"
#import <QuartzCore/QuartzCore.h>

@implementation BSPullToRefreshView {
    BOOL _isAnimating;
    NSTimer *_rotationTimer;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        [self setBackgroundColor:[UIColor whiteColor]];
        
        _textLabel = [[UILabel alloc] init];
        [_textLabel setFrame:CGRectMake(0, 15.0f, CGRectGetWidth(self.bounds), 20.0f)];
        [_textLabel setText:@"Pociągnij w dół aby odświeżyć"];
        [_textLabel setFont:[UIFont boldSystemFontOfSize:10.0f]];
        [_textLabel setTextAlignment:NSTextAlignmentCenter];
        [_textLabel setBackgroundColor:[UIColor clearColor]];
        [self addSubview:_textLabel];
        
        _iconView = [[UIView alloc] init];
        [self addSubview:_iconView];
        
        
    }
    return self;
}

- (void)layoutSubviews {
    [_iconView setCenter:CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds) - 10.0f)];
}

- (void)setProgress:(CGFloat)progress {
    
    [_textLabel setFrame:CGRectMake(0, floorf(15.0f + (30.0f * progress)), CGRectGetWidth(self.bounds), 20.0f)];
    
    if (progress >= 1.0f) {
        [_textLabel setText:@"Upuść aby odświeżyć"];
    }
    [_textLabel setNeedsDisplay];
}

- (void)startAnimating {
    _rotationTimer  = [NSTimer scheduledTimerWithTimeInterval:0.005f target:self selector:@selector(animateRotation) userInfo:nil repeats:YES];
    [_rotationTimer fire];
}

- (void)stopAnimating {
    [_rotationTimer invalidate];
}

- (void)animateRotation {
    [UIView animateWithDuration:0.005f animations:^{
        CGAffineTransform transform = CGAffineTransformRotate(_iconView.transform, M_PI/180);
        [_iconView setTransform:transform];
    }];
}

- (void)setState:(BSPullToRefreshState)state {
    _state = state;
    
    if (state == BSPullToRefreshOpened) {
        [_textLabel setText:@"Odświeżanie"];
        [self startAnimating];
        _isAnimating = YES;
    } else if (_isAnimating == YES) {
        [self stopAnimating];
    }
}

- (BSPullToRefreshState)state {
    return _state;
}

- (void)setIconView:(UIView *)iconView {
    if (_iconView != iconView) {
        [iconView removeFromSuperview];
        
        _iconView = iconView;
        [self addSubview:_iconView];
        [self setNeedsDisplay];
    }
}


@end
