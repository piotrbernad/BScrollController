//
//  BSViewController.m
//  BScrollController
//
//  Created by Piotr Bernad on 09.10.2013.
//  Copyright (c) 2013 Piotr Bernad. All rights reserved.
//

#import "BSViewController.h"
#import "BSCollectionViewController.h"
#import "BPullToRefreshView.h"
#import <QuartzCore/QuartzCore.h>

#define minTranslateYToSkip 0.35
#define animationTime 0.25f
#define translationAccelerate 1.5f

@interface BSViewController ()

@end

typedef enum {
    BSScrollDirectionUnknown,
    BSScrollDirectionFromBottomToTop,
    BSScrollDirectionFromTopToBottom
} BSScrollDirection;

@implementation BSViewController {
    UICollectionViewController *_collectionViewController;
    UIPanGestureRecognizer *_panGesture;
    NSMutableArray *_snapshotsArray;
    
    BOOL _collectionHasItemsToShow;
    BOOL _isOnTop;
    
    BPullToRefreshView *_pullToRefresh;
    BSScrollDirection _scrollDirection;
    UIImageView *_snapshotView;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    _panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panGestureRecognized:)];
    [self.view addGestureRecognizer:_panGesture];
    
    _snapshotsArray = [[NSMutableArray alloc] init];
    
}

- (void)setCollectionViewController:(UICollectionViewController<BScrollProtocol> *)controller {
    if (_collectionViewController != controller) {
        _collectionViewController = controller;
        
        [self addChildViewController:_collectionViewController];
        [self.view addSubview:_collectionViewController.collectionView];
        [_collectionViewController didMoveToParentViewController:self];
        _delegate = _collectionViewController;
    }
}

- (void)panGestureRecognized:(UIPanGestureRecognizer *)sender {
    
    CGPoint translate = [sender translationInView:self.view];
    translate.y = translate.y * translationAccelerate;
    CGFloat boundsW = CGRectGetWidth(self.view.bounds);
    CGFloat boundsH = CGRectGetHeight(self.view.bounds);
    
    switch (sender.state) {
        case UIGestureRecognizerStateBegan:
            // reset all values
            [self panGestureDidBegan];
            break;
            
        case UIGestureRecognizerStateChanged: {
            
            // Determinate Scroll Direction
            if (_scrollDirection == BSScrollDirectionUnknown) {
                _scrollDirection = translate.y < 0 ? BSScrollDirectionFromBottomToTop : BSScrollDirectionFromTopToBottom;
                [self addSnapshotViewOnTopWithDirection:_scrollDirection];
                _collectionHasItemsToShow = [_delegate parentViewController:self wantsItemsForward: _scrollDirection == BSScrollDirectionFromTopToBottom ? NO : YES];
            }
            
            // Is On top so add pull to refresh above snapshotview
            if (!_snapshotView) {
                [self addSnapshotViewOnTopWithDirection:BSScrollDirectionFromBottomToTop];
                [self addPullToRefreshView];
                _isOnTop = YES;
            }
            
            // Is on top and pulling to refresh
            if (_isOnTop && _scrollDirection == BSScrollDirectionFromTopToBottom && abs(translate.y) < 80.0f) {
                [_pullToRefresh setProgress:translate.y/80.0f];
                CGRect newRect = CGRectMake(0, translate.y, boundsW, boundsH);
                [_snapshotView setFrame:newRect];
                
            // pulling snapshotview
            } else if (_collectionHasItemsToShow || abs(translate.y) < 50.0f) {
                
                if (_scrollDirection == BSScrollDirectionFromTopToBottom) {
                    CGRect newRect = CGRectMake(0, -boundsH + translate.y, boundsW, boundsH);
                    [_snapshotView setFrame:newRect];
                } else {
                    CGRect newRect = CGRectMake(0, translate.y, boundsW, boundsH);
                    [_snapshotView setFrame:newRect];
                }
                
            }
            break;
            
        }
        case UIGestureRecognizerStateCancelled : {
            
            // gesture was canceled - snapshot view backs to start position
            if (!_collectionHasItemsToShow) {
                [UIView animateWithDuration:animationTime animations:^{
                    if (_scrollDirection == BSScrollDirectionFromBottomToTop) {
                        CGRect endRect = CGRectMake(0, 0, boundsW, boundsH);
                        [_snapshotView setFrame:endRect];
                    } else {
                        CGRect endRect = CGRectMake(0, -boundsH, boundsW, boundsH);
                        [_snapshotView setFrame:endRect];
                    }
                } completion:^(BOOL finished) {
                    [_snapshotView removeFromSuperview];
                    _snapshotView = nil;
                }];
            }
            break;
        }
        case UIGestureRecognizerStateEnded: {
            
            // gesture is canceled and snapshot view backs to start frame
            if (!_collectionHasItemsToShow && !_isOnTop) {
                // prevents skip to next items
                translate.y = _scrollDirection == BSScrollDirectionFromBottomToTop ? -50.0f : 50.0f;
                sender.enabled = NO;
                sender.enabled = YES;
            }
            
            // pull to refresh end
            if(_isOnTop) {
                 if (abs(translate.y) >= 75.0f) {
                     [_pullToRefresh setProgress:1.0f];
                 }
                [UIView animateWithDuration:animationTime animations:^{
                    CGRect endRect = CGRectMake(0.0f, 0.0f, boundsW, boundsH);
                    [_snapshotView setFrame:endRect];
                } completion:^(BOOL finished) {
                    if (abs(translate.y) >= 75.0f) {
                        [_delegate parentViewControllerDidPullToRefresh:self];
                        [_pullToRefresh removeFromSuperview];
                        _pullToRefresh = nil;
                    }
                }];
                return;
            }

            // finish animation when pulling from bottom to top and asbolute translation is bigger than minimum value to change page
            if (_scrollDirection == BSScrollDirectionFromBottomToTop && translate.y < - minTranslateYToSkip * boundsH) {
                
                [UIView animateWithDuration:animationTime animations:^{
                    CGRect endRect = CGRectMake(0, -boundsH, boundsW, boundsH);
                    [_snapshotView setFrame:endRect];
                } completion:^(BOOL finished) {
                    [_delegate parentViewController:self didFinishAnimatingForward:YES];
                    [_snapshotsArray addObject:_snapshotView.image];
                    [_snapshotView removeFromSuperview];
                    _snapshotView = nil;
                }];
                
            }
            
            // finish animation when pulling from top to bottom and asbolute translation is bigger than minimum value to change page
            else if(_scrollDirection == BSScrollDirectionFromTopToBottom && translate.y > minTranslateYToSkip * boundsH) {
                
                [UIView animateWithDuration:animationTime animations:^{
                    CGRect endRect = CGRectMake(0, 0, boundsW, boundsH);
                    [_snapshotView setFrame:endRect];
                } completion:^(BOOL finished) {
                    [_delegate parentViewController:self didFinishAnimatingForward:NO];
                    [_snapshotsArray removeLastObject];
                    [_snapshotView removeFromSuperview];
                    _snapshotView = nil;
                }];
                
            }
            // finish animation when absolute translation is smaller than minimum value, snapshotview backs to start frame
            else {
                [UIView animateWithDuration:animationTime animations:^{
                    if (_scrollDirection == BSScrollDirectionFromBottomToTop) {
                        CGRect endRect = CGRectMake(0, 0, boundsW, boundsH);
                        [_snapshotView setFrame:endRect];
                    } else {
                        CGRect endRect = CGRectMake(0, -boundsH, boundsW, boundsH);
                        [_snapshotView setFrame:endRect];
                    }
                } completion:^(BOOL finished) {
                    [_delegate parentViewControllerWantsRollBack:self];
                    [_snapshotView removeFromSuperview];
                    _snapshotView = nil;
                }];
                
            }
            break;
        }
        default:
            break;
    }
}

- (void)addPullToRefreshView {
    _pullToRefresh = [[BPullToRefreshView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.view.bounds), 80.0f)];
    [self.view insertSubview:_pullToRefresh belowSubview:_snapshotView];
}

- (void)addSnapshotViewOnTopWithDirection:(BSScrollDirection)direction {
    
    [_pullToRefresh removeFromSuperview];
    _pullToRefresh = nil;
    
    [_snapshotView removeFromSuperview];
    _snapshotView = nil;
    
    switch (direction) {
        case BSScrollDirectionFromBottomToTop:
            _snapshotView = [[UIImageView alloc] initWithImage:[self makeImageFromCurrentView]];
            [_snapshotView setFrame:self.view.bounds];
            break;
        case BSScrollDirectionFromTopToBottom:
            if ([_snapshotsArray lastObject]) {
                _snapshotView = [[UIImageView alloc] initWithImage:[_snapshotsArray lastObject]];
                [_snapshotView setFrame:CGRectMake(0, -CGRectGetHeight(self.view.bounds), CGRectGetWidth(self.view.bounds), CGRectGetHeight(self.view.bounds))];
            }
            break;
        default:
            break;
    }
    [self.view addSubview:_snapshotView];
    
}

- (void)panGestureDidBegan {
    
    _scrollDirection = BSScrollDirectionUnknown;
    _isOnTop = NO;
    
    if (_pullToRefresh) {
        [_pullToRefresh removeFromSuperview];
        _pullToRefresh = nil;
    }
    
}


- (UIImage *)makeImageFromCurrentView {
    UIGraphicsBeginImageContextWithOptions(self.view.bounds.size, NO, [[UIScreen mainScreen] scale]);
    [self.view.layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *viewImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return viewImage;
}



@end
