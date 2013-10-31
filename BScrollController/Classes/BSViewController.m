//
//  BSViewController.m
//  BScrollController
//
//  Created by Piotr Bernad on 09.10.2013.
//  Copyright (c) 2013 Piotr Bernad. All rights reserved.
//

#import "BSViewController.h"
#import "BSCollectionViewController.h"
#import <QuartzCore/QuartzCore.h>

#define minTranslateYToSkip 0.35
#define animationTime 0.25f
#define translationAccelerate 1.3f

#define IOS_VERSION_GREATER_THAN_OR_EQUAL_TO(v)  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedAscending)

@interface BSViewController () <UIGestureRecognizerDelegate, BPullToRefreshDelegate, BScrollDataSource>

@end

typedef enum {
    BSScrollDirectionUnknown,
    BSScrollDirectionFromBottomToTop,
    BSScrollDirectionFromTopToBottom
} BSScrollDirection;

@implementation BSViewController {
    UIPanGestureRecognizer *_panGesture;
    NSMutableArray *_snapshotsArray;
    
    BOOL _collectionHasItemsToShow;
    BOOL _isOnTop;
    BOOL _disablePullToRefresh;
    
    BSScrollDirection _scrollDirection;
    UIImageView *_snapshotView;
    UIImageView *_currentlyVisibleScreenSnapshot;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    _panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panGestureRecognized:)];
    [_panGesture setDelegate:self];
    [self.view addGestureRecognizer:_panGesture];
    
    _snapshotsArray = [[NSMutableArray alloc] init];
    [self.view setBackgroundColor:[UIColor whiteColor]];
    
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}

- (void)viewWillLayoutSubviews {
    [_collectionViewController.view setFrame:self.view.frame];
}

- (void)setCollectionViewController:(BSCollectionViewController *)controller {
    if (_collectionViewController != controller) {
        _collectionViewController = controller;
        
        [self addChildViewController:_collectionViewController];
        [self.view addSubview:_collectionViewController.collectionView];
        [_collectionViewController didMoveToParentViewController:self];
        
        [_collectionViewController.collectionView setDelegate:_collectionViewDelegate];
        [_collectionViewController.collectionView setDataSource:_collectionViewDelegate];
        [_collectionViewController.collectionView setScrollEnabled:NO];
        [_collectionViewController setScollDataSource:self];
    }
}

- (BOOL)gestureRecognizerShouldBegin:(UIPanGestureRecognizer *)gestureRecognizer {
    CGPoint translation = [gestureRecognizer translationInView:self.view];
    if (abs(translation.y) + 5.0f > abs(translation.x)) {
        _currentlyVisibleScreenSnapshot = [[UIImageView alloc] initWithImage:[self makeImageFromCurrentView]];
        [_currentlyVisibleScreenSnapshot setFrame:self.view.bounds];
        [_currentlyVisibleScreenSnapshot setHidden:YES];
        [self.view addSubview:_currentlyVisibleScreenSnapshot];
        return YES;
    }
    return NO;
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
                _collectionHasItemsToShow = [_collectionViewController parentViewControllerWantsItemsForward:_scrollDirection == BSScrollDirectionFromTopToBottom ? NO : YES];
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
            if (!_collectionHasItemsToShow) {
                if (!self.collectionViewController.collectionView.isHidden) {
                    [self.collectionViewController.collectionView setHidden:YES];
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
                    if (self.collectionViewController.collectionView.isHidden) {
                        [self.collectionViewController.collectionView setHidden:NO];
                    }
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
                    [_collectionViewController parentViewControllerDidFinishAnimatingForward:YES];
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
                    [_collectionViewController parentViewControllerDidFinishAnimatingForward:NO];
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
                    if (self.collectionViewController.collectionView.isHidden) {
                        [self.collectionViewController.collectionView setHidden:NO];
                    }
                    [_collectionViewController parentViewControllerWantsRollBack];
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
    
    if (self.isPullToRefreshDisabled) {
        return;
    }
    
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
    
    // if starts refreshing data, make sure that pull to refresh is in the right place
    [UIView animateWithDuration:animationTime animations:^{
        [_pullToRefresh setProgress:1.0f];
        CGRect endRect = CGRectMake(0, 80.0f, CGRectGetWidth(self.view.bounds), CGRectGetHeight(self.view.bounds));
        [_collectionViewController.collectionView setFrame:endRect];
    }];
    [_pullToRefresh setState:BSPullToRefreshOpened];
    [self performSelector:@selector(endRefresh) withObject:nil afterDelay:2.0f];
}

- (void)endRefresh {
    [_collectionViewController parentViewControllerDidEndPullToRefresh];
    [self hidePullToRefreshAnimated:YES];
    
}

- (void)hidePullToRefreshAnimated:(BOOL)animated {
    CGRect endRect = CGRectMake(0, 0, CGRectGetWidth(self.view.frame), CGRectGetHeight(self.view.frame));
    
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
    [_pullToRefresh setDelegate:self];
    [self.view insertSubview:_pullToRefresh belowSubview:_collectionViewController.collectionView];
}

- (void)bPullToRefreshWantsReloadData:(BSPullToRefreshView *)sender {
    NSLog(@"reload");
}

- (void)addSnapshotViewOnTopWithDirection:(BSScrollDirection)direction {
    
    [self removeSnapshotViewFromSuperView];
    [self removePullToRefreshFromSuperView];
    
    switch (direction) {
        case BSScrollDirectionFromBottomToTop:
            if (_currentlyVisibleScreenSnapshot) {
                _snapshotView = _currentlyVisibleScreenSnapshot;
                [_snapshotView setHidden:NO];
                break;
            }
            _snapshotView = [[UIImageView alloc] initWithImage:[self makeImageFromCurrentView]];
            [_snapshotView setFrame:self.view.bounds];
            break;
        case BSScrollDirectionFromTopToBottom:
            if ([_snapshotsArray lastObject]) {
                _snapshotView = [[UIImageView alloc] initWithImage:[_snapshotsArray lastObject]];
                [_snapshotView setFrame:CGRectMake(0, -CGRectGetHeight(self.view.bounds), CGRectGetWidth(self.view.bounds), CGRectGetHeight(self.view.bounds))];
                [self.view addSubview:_snapshotView];
            }
            break;
        default:
            break;
    }
}

- (void)setDisablePullToRefresh:(BOOL)disablePullToRefresh {
    _disablePullToRefresh = disablePullToRefresh;
}

- (BOOL)isPullToRefreshDisabled {
    return _disablePullToRefresh;
}

- (UIImage *)makeImageFromCurrentView {
    CGSize imageSize = self.view.frame.size;

    if (IOS_VERSION_GREATER_THAN_OR_EQUAL_TO(@"7.0")) {
        UIGraphicsBeginImageContextWithOptions(imageSize, NO, 0);
    } else {
        UIGraphicsBeginImageContextWithOptions(imageSize, NO, 1);
    }
    
    CGContextRef context = UIGraphicsGetCurrentContext();

    CGContextSaveGState(context);
    CGContextTranslateCTM(context, self.view.center.x, self.view.center.y);
    CGContextConcatCTM(context, self.view.transform);
    CGContextTranslateCTM(context, -self.view.bounds.size.width * self.view.layer.anchorPoint.x, -self.view.bounds.size.height * self.view.layer.anchorPoint.y);
    if ([self.view respondsToSelector:@selector(drawViewHierarchyInRect:afterScreenUpdates:)]) {
        [self.view drawViewHierarchyInRect:self.view.bounds afterScreenUpdates:YES];
    } else {
        [self.view.layer renderInContext:context];
    }
    CGContextRestoreGState(context);
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}


@end
