//
//  GSCollectionViewController.m
//  GroupedScrollController
//
//  Created by Piotr Bernad on 08.10.2013.
//  Copyright (c) 2013 Piotr Bernad. All rights reserved.
//

#import "BSCollectionViewController.h"
#import "BSImageCell.h"

@interface BSCollectionViewController ()

@end

@implementation BSCollectionViewController {
    NSArray *_items;
    
    NSInteger _beforeChangeIndex;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    _items = @[[UIImage imageNamed:@"kawa.jpg"],
               [UIImage imageNamed:@"man.jpg"],
               [UIImage imageNamed:@"3.png"],
               [UIImage imageNamed:@"1.jpg"],
               [UIImage imageNamed:@"2.png"],
               [UIImage imageNamed:@"3.png"],
               [UIImage imageNamed:@"1.jpg"],
               [UIImage imageNamed:@"2.png"],
               [UIImage imageNamed:@"3.png"],
               [UIImage imageNamed:@"1.jpg"],
               [UIImage imageNamed:@"2.png"],
               [UIImage imageNamed:@"3.png"],
               [UIImage imageNamed:@"man2 blur.jpg"],
               [UIImage imageNamed:@"kawa.jpg"],
               [UIImage imageNamed:@"man.jpg"],
               [UIImage imageNamed:@"3.png"]];
    
    _currentPage = 0;
    
    [self.collectionView registerClass:[BSImageCell class] forCellWithReuseIdentifier:@"ImageCell"];
    [self.collectionView setBackgroundColor:[UIColor whiteColor]];
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return [self currentItems].count;
}

- (BSImageCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    BSImageCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"ImageCell" forIndexPath:indexPath];
    [cell.imageView setImage:[[self currentItems] objectAtIndex:indexPath.item]];
    [cell.imageView setContentMode:UIViewContentModeScaleAspectFill];
    [cell.imageView setClipsToBounds:YES];
    return cell;
}

- (NSArray *)currentItems {
    NSIndexSet *indexes;
    
    if ((_currentPage * _itemsPerPage) + _itemsPerPage < [_items count]) {
        indexes = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(_currentPage * _itemsPerPage, _itemsPerPage)];
    } else {
        NSInteger _itemsOnPage = _items.count - _currentPage * _itemsPerPage;
        indexes = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(_currentPage * _itemsPerPage, _itemsOnPage)];
    }
    
    return [_items objectsAtIndexes:indexes];
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    return CGSizeMake(CGRectGetWidth(self.view.bounds), floorf(CGRectGetHeight(self.view.bounds)/[collectionView numberOfItemsInSection:0]));
}

#pragma mark - BScroll Delegate 

- (BOOL)parentViewController:(BSViewController *)parent wantsItemsForward:(BOOL)forward {
    
    _beforeChangeIndex = _currentPage;
    switch (forward) {
        case YES:
            if ((_currentPage + 1) * _itemsPerPage < [_items count]) {
                _currentPage++;
                [self.collectionView reloadData];
                break;
            } else {
                return NO;
            }
        case NO:
            if (_currentPage - 1 >= 0) {
                _currentPage--;
                break;
            } else {
                return NO;
            }
    }
    
    
    return YES;
}

- (void)parentViewControllerWantsRollBack:(BSViewController *)parent {
    _currentPage = _beforeChangeIndex;
    [self.collectionView reloadData];
}

- (void)parentViewController:(BSViewController *)parent didFinishAnimatingForward:(BOOL)forward {
    
    if (forward == NO) {
        [self.collectionView reloadData];
    }
}
- (void)parentViewControllerDidPullToRefresh:(BSViewController *)parent {
    NSLog(@"pull to refresh");
    [self.collectionView reloadData];
}

@end
