//
//  BPullToRefreshView.h
//  BScrollController
//
//  Created by Piotr Bernad on 10.10.2013.
//  Copyright (c) 2013 Piotr Bernad. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef enum {
    BSPullToRefreshClosed,
    BSPullToRefreshMoving,
    BSPullToRefreshOpened
} BSPullToRefreshState;

@class BSPullToRefreshView;

@protocol BPullToRefreshDelegate <NSObject>
- (void)bPullToRefreshWantsReloadData:(BSPullToRefreshView *)sender;
@end

@interface BSPullToRefreshView : UIView {
    BSPullToRefreshState _state;
}

@property (strong, nonatomic) UILabel *textLabel;
@property (strong, nonatomic) UIView *iconView;
@property (strong, nonatomic) id <BPullToRefreshDelegate> delegate;

// progress value from 0 to 1 
- (void)setProgress:(CGFloat)progress;

#pragma mark - state getter and setter

- (BSPullToRefreshState)state;
- (void)setState:(BSPullToRefreshState)state;

@end

