//
//  BSViewController.h
//  BScrollController
//
//  Created by Piotr Bernad on 09.10.2013.
//  Copyright (c) 2013 Piotr Bernad. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BSPullToRefreshView.h"
#import "BSCollectionViewController.h"

@interface BSViewController : UIViewController

- (void)setCollectionViewController:(BSCollectionViewController *)controller;

// to override
- (void)addPullToRefreshView;
@property (assign, nonatomic, getter = isPullToRefreshDisabled) BOOL disablePullToRefresh;
@property (strong, nonatomic) BSCollectionViewController *collectionViewController;
@property (strong, nonatomic) BSPullToRefreshView *pullToRefresh;
@property (strong, nonatomic) id<UICollectionViewDelegate, UICollectionViewDataSource> collectionViewDelegate;
@end
