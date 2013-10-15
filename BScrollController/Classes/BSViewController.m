//
//  BSViewController.m
//  BScrollController
//
//  Created by Piotr Bernad on 09.10.2013.
//  Copyright (c) 2013 Piotr Bernad. All rights reserved.
//

#import "BSViewController.h"
#import "BSCollectionViewController.h"
#import "BSPullToRefreshView.h"
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
    
    BSPullToRefreshView *_pullToRefresh;
    BSScrollDirection _scrollDirection;
    UIImageView *_snapshotView;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    _panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panGestureRecognized:)];
    [self.view addGestureRecognizer:_panGesture];
    
    _snapshotsArray = [[NSMutableArray alloc] init];
    [self.view setBackgroundColor:[UIColor whiteColor]];
    
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
    
    if (_pullToRefresh.state == BSPullToRefreshOpened) {
        [self hidePullToRefreshAnimated:YES];
        return;
    }
    
    switch (sender.state) {
        case UIGestureRecognizerStateBegan:
            // reset all values
            _scrollDirection = BSScrollDirectionUnknown;
            _isOnTop = NO;
            break;
            
        case UIGestureRecognizerStateChanged: {
            
            // Determinate Scroll Direction
            if (_scrollDirection == BSScrollDirectionUnknown) {
                _scrollDirection = translate.y < 0 ? BSScrollDirectionFromBottomToTop : BSScrollDirectionFromTopToBottom;
                // add snapshot on top
                [self addSnapshotViewOnTopWithDirection:_scrollDirection];
                _collectionHasItemsToShow = [_delegate parentViewController:self wantsItemsForward: _scrollDirection == BSScrollDirectionFromTopToBottom ? NO : YES];
            }
            
            // If snapshot doesnt exist -> set isOnTop
            if (!_snapshotView) {
                _isOnTop = YES;
            }
            
            // Is on top and pulling to from top to bottom, gesture is driven by handlePanGestureToPullToRefresh
            if (_isOnTop && _scrollDirection == BSScrollDirectionFromTopToBottom) {
                [self handlePanGestureToPullToRefresh:sender];
                return;
            }
            
            // pulling snapshotview
            else if (_collectionHasItemsToShow || abs(translate.y) < 50.0f) {
                
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
            // collection view has no more items to show, pangesture is available only for 50px
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
                   [self removeSnapshotViewFromSuperView];
                }];
            }
            break;
        }
        case UIGestureRecognizerStateEnded: {
            
            // pull to refresh dragging, handled by handlePanGestureToPullToRefresh
            if (_isOnTop && _scrollDirection == BSScrollDirectionFromTopToBottom) {
                [self handlePanGestureToPullToRefresh:sender];
                return;
            }
            
            // gesture is canceled and snapshot view backs to start frame
            if (!_collectionHasItemsToShow && !_isOnTop) {
                // prevents skip to next items
                translate.y = _scrollDirection == BSScrollDirectionFromBottomToTop ? -50.0f : 50.0f;
                sender.enabled = NO;
                sender.enabled = YES;
            }
            
            // finish animation when pulling from bottom to top and asbolute translation is bigger than minimum value to change page
            if (_scrollDirection == BSScrollDirectionFromBottomToTop && translate.y < - minTranslateYToSkip * boundsH) {
                
                [UIView animateWithDuration:animationTime animations:^{
                    CGRect endRect = CGRectMake(0, -boundsH, boundsW, boundsH);
                    [_snapshotView setFrame:endRect];
                } completion:^(BOOL finished) {
                    [_delegate parentViewController:self didFinishAnimatingForward:YES];
                    [_snapshotsArray addObject:_snapshotView.image];
                    [self removeSnapshotViewFromSuperView];
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
                    [self removeSnapshotViewFromSuperView];
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
                    [self removeSnapshotViewFromSuperView];
                }];
                
            }
            break;
        }
        default:
            break;
    }
}

- (void)handlePanGestureToPullToRefresh:(UIPanGestureRecognizer *)sender {
    
    // if snapshot exist remove it from super to show pull to refresh view
    if (_snapshotView) {
        [self removeSnapshotViewFromSuperView];
    }
    
    CGPoint translate = [sender translationInView:self.view];
    
    if (!_pullToRefresh && translate.y > 0.0f) {
        [self addPullToRefreshView];
    }
    
    switch (sender.state) {
        case UIGestureRecognizerStateChanged: {
            // draging from top to bottom - only 80px allowed
            if (translate.y > 0.0f && translate.y < 80.0f) {
                CGRect endRect = CGRectMake(0, translate.y, CGRectGetWidth(self.view.bounds), CGRectGetHeight(self.view.bounds));
                [_collectionViewController.collectionView setFrame:endRect];
                [_pullToRefresh setProgress:abs(translate.y) / 80.0f];
                [_pullToRefresh setState:BSPullToRefreshMoving];
            } else if (translate.y < 0.0f && _pullToRefresh.state == (BSPullToRefreshOpened || BSPullToRefreshMoving)) {
                [sender setEnabled:NO];
                [sender setEnabled:YES];
                [UIView animateWithDuration:animationTime animations:^{
                    CGRect endRect = CGRectMake(0, 0, CGRectGetWidth(self.view.bounds), CGRectGetHeight(self.view.bounds));
                    [_collectionViewController.collectionView setFrame:endRect];
                }];
            }
            break;
        }
        case UIGestureRecognizerStateEnded: {
            if (translate.y > 80.0f) {
                [self refreshData];
            } else {
                [self hidePullToRefreshAnimated:YES];
            }
            break;
        }
        default:
            break;
    }
    

}

- (void)refreshData {
    [_pullToRefresh setState:BSPullToRefreshOpened];
    [self performSelector:@selector(endRefresh) withObject:nil afterDelay:2.0f];
}

- (void)endRefresh {
    [_delegate parentViewControllerDidEndPullToRefresh:self];
    [self hidePullToRefreshAnimated:YES];
    
}

- (void)hidePullToRefreshAnimated:(BOOL)animated {
    CGRect endRect = CGRectMake(0, 0, CGRectGetWidth(self.view.bounds), CGRectGetHeight(self.view.bounds));
    
    if (!animated) {
        [_collectionViewController.collectionView setFrame:endRect];
        [self removePullToRefreshFromSuperView];
        return;
    }
    
    [UIView animateWithDuration:animationTime animations:^{
        [_collectionViewController.collectionView setFrame:endRect];
    } completion:^(BOOL finished) {
        [self removePullToRefreshFromSuperView];
    }];
}

- (void)removePullToRefreshFromSuperView {
    [_pullToRefresh setState:BSPullToRefreshClosed];
    [_pullToRefresh removeFromSuperview];
    _pullToRefresh = nil;
}

- (void)removeSnapshotViewFromSuperView {
    [_snapshotView removeFromSuperview];
    _snapshotView = nil;
}


- (void)addPullToRefreshView {
    
    if (_pullToRefresh) {
        [_pullToRefresh removeFromSuperview];
    }
    
    _pullToRefresh = [[BSPullToRefreshView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.view.bounds), 80.0f)];
    [self.view insertSubview:_pullToRefresh belowSubview:_collectionViewController.collectionView];
}

- (void)addSnapshotViewOnTopWithDirection:(BSScrollDirection)direction {
    
    [self removeSnapshotViewFromSuperView];
    [self removePullToRefreshFromSuperView];
    
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


- (UIImage *)makeImageFromCurrentView {
    UIGraphicsBeginImageContextWithOptions(self.view.bounds.size, NO, [[UIScreen mainScreen] scale]);
    [self.view.layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *viewImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return viewImage;
}



@end
