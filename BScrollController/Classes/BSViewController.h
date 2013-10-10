//
//  BSViewController.h
//  BScrollController
//
//  Created by Piotr Bernad on 09.10.2013.
//  Copyright (c) 2013 Piotr Bernad. All rights reserved.
//


@protocol BScrollProtocol;

#import <UIKit/UIKit.h>

@interface BSViewController : UIViewController

- (void)setCollectionViewController:(UICollectionViewController<BScrollProtocol> *)controller;

@property (strong, nonatomic) id<BScrollProtocol> delegate;
@end

@protocol BScrollProtocol <NSObject>

- (BOOL)parentViewController:(BSViewController *)parent wantsItemsForward:(BOOL)forward;
- (void)parentViewControllerWantsRollBack:(BSViewController *)parent;
- (void)parentViewController:(BSViewController *)parent didFinishAnimatingForward:(BOOL)forward;
- (void)parentViewControllerDidPullToRefresh:(BSViewController *)parent;

@end