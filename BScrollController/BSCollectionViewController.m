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
               [UIImage imageNamed:@"man2 blur.jpg"]];
    
    _currentPage = 0;
    
    [self.collectionView registerClass:[BSImageCell class] forCellWithReuseIdentifier:@"ImageCell"];
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return _itemsPerPage;
}

- (BSImageCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    BSImageCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"ImageCell" forIndexPath:indexPath];
    [cell.imageView setImage:[[self currentItems] objectAtIndex:indexPath.item]];
    [cell.imageView setContentMode:UIViewContentModeScaleAspectFill];
    [cell.imageView setClipsToBounds:YES];
    return cell;
}

- (NSArray *)currentItems {
    NSIndexSet *indexes = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(_currentPage * _itemsPerPage, _itemsPerPage)];
    NSArray *items = [_items objectsAtIndexes:indexes];
    return items;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    NSLog(@"tap");
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    return CGSizeMake(320, floorf(CGRectGetHeight(self.view.bounds)/3.0f));
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

@end
