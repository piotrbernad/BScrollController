//
//  GSCollectionViewController.h
//  GroupedScrollController
//
//  Created by Piotr Bernad on 08.10.2013.
//  Copyright (c) 2013 Piotr Bernad. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface BSCollectionViewController : UIViewController

@property (strong, nonatomic) UICollectionView *collectionView;
@property (strong, nonatomic) NSArray *items;
@property (readonly, nonatomic) NSInteger currentPage;
@property (assign, nonatomic) NSInteger itemsPerPage;

- (id)initWithCollectionViewLayout:(UICollectionViewLayout *)layout;

- (NSArray *)visibleItems;
- (BOOL)parentViewControllerWantsItemsForward:(BOOL)forward;
- (void)parentViewControllerWantsRollBack;
- (void)parentViewControllerDidFinishAnimatingForward:(BOOL)forward;
- (void)parentViewControllerDidEndPullToRefresh;
- (void)setItems:(NSArray *)items;

@end
