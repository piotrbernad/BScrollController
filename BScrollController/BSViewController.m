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
    UIImageView *_snapshotView;
    BSScrollDirection _scrollDirection;
    BOOL _collectionHasItemsToShow;
    NSMutableArray *_snapshotsArray;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    _panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panGestureRecognized:)];
    [self.view addGestureRecognizer:_panGesture];
    
    _snapshotsArray = [[NSMutableArray alloc] init];
    
}

- (void)panGestureRecognized:(UIPanGestureRecognizer *)sender {
    
    CGPoint translate = [sender translationInView:self.view];
    CGFloat boundsW = CGRectGetWidth(self.view.bounds);
    CGFloat boundsH = CGRectGetHeight(self.view.bounds);
    
    switch (sender.state) {
        case UIGestureRecognizerStateBegan:
            
            _scrollDirection = BSScrollDirectionUnknown;
            break;
            
        case UIGestureRecognizerStateChanged: {
            
            if (_scrollDirection == BSScrollDirectionUnknown) {
                _scrollDirection = translate.y < 0 ? BSScrollDirectionFromBottomToTop : BSScrollDirectionFromTopToBottom;
                [self addSnapshotViewOnTopWithDirection:_scrollDirection];
                _collectionHasItemsToShow = [_delegate parentViewController:self wantsItemsForward: _scrollDirection == BSScrollDirectionFromTopToBottom ? NO : YES];
            }
            
            if (_collectionHasItemsToShow || abs(translate.y) < 50.0f) {
                
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
            if (!_collectionHasItemsToShow) {
                // prevents skip to next items
                translate.y = _scrollDirection == BSScrollDirectionFromBottomToTop ? -50.0f : 50.0f;
                sender.enabled = NO;
                sender.enabled = YES;
            }
            

            if (_scrollDirection == BSScrollDirectionFromBottomToTop && translate.y < - minTranslateYToSkip * boundsH) {
                
                [UIView animateWithDuration:animationTime animations:^{
                    CGRect endRect = CGRectMake(0, -boundsH, boundsW, boundsH);
                    [_snapshotView setFrame:endRect];
                } completion:^(BOOL finished) {
                    [_snapshotsArray addObject:_snapshotView.image];
                    [_snapshotView removeFromSuperview];
                    _snapshotView = nil;
                }];
                
            }

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
                    if (_scrollDirection == BSScrollDirectionFromTopToBottom) {
                        [_snapshotView removeFromSuperview];
                        _snapshotView = nil;
                    } else {
                        [_snapshotView removeFromSuperview];
                        _snapshotView = nil;
                    }
                }];
                
            }
            break;
        }
        default:
            break;
    }
}

- (void)addSnapshotViewOnTopWithDirection:(BSScrollDirection)direction {
    
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
            } else {
                #warning TODO - if image not exist
                _snapshotView = [[UIImageView alloc] initWithImage:[[UIImage alloc] init]];
            }
            
            [_snapshotView setFrame:CGRectMake(0, -CGRectGetHeight(self.view.bounds), CGRectGetWidth(self.view.bounds), CGRectGetHeight(self.view.bounds))];
            break;
        default:
            break;
    }
    /* to discuss, if shadow is needed, because of performance decrease
    _snapshotView.layer.shadowColor = [[UIColor blackColor] CGColor];
    _snapshotView.layer.shadowOffset = CGSizeMake(-5.0f, 10.0f);
    _snapshotView.layer.shadowOpacity = 1.0f;
    _snapshotView.layer.shadowRadius = 40.0f;
     */
    [self.view addSubview:_snapshotView];
    
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

- (UIImage *)makeImageFromCurrentView {
    UIGraphicsBeginImageContextWithOptions(self.view.bounds.size, NO, [[UIScreen mainScreen] scale]);
    [self.view.layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *viewImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return viewImage;
}



@end
