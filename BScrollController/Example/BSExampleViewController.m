//
//  BSExampleViewController.m
//  BScrollController
//
//  Created by Piotr Bernad on 15.10.2013.
//  Copyright (c) 2013 Piotr Bernad. All rights reserved.
//

#import "BSExampleViewController.h"
#import "BSCollectionViewController.h"
#import "BSCollectionLayout.h"
#import "BSImageCell.h"

@interface BSExampleViewController ()

@end

@implementation BSExampleViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    BSCollectionLayout *layout = [[BSCollectionLayout alloc] init];
    BSCollectionViewController *_collectionViewController = [[BSCollectionViewController alloc] initWithCollectionViewLayout:layout];
    [_collectionViewController setItemsPerPage:3];
    [self setCollectionViewDelegate:self];
    [self setCollectionViewController:_collectionViewController];
    
    [self.collectionViewController setItems:[self exampleImages]];
    [self.collectionViewController.collectionView registerClass:[BSImageCell class] forCellWithReuseIdentifier:@"ImageCell"];
}
#pragma mark - Collection View Delegate

- (NSArray *)exampleImages {
    return @[[UIImage imageNamed:@"kawa.jpg"],
             [UIImage imageNamed:@"man.jpg"],
             [UIImage imageNamed:@"3.png"],
             [UIImage imageNamed:@"1.jpg"],
             [UIImage imageNamed:@"2.png"],
             [UIImage imageNamed:@"3.png"],
             [UIImage imageNamed:@"1.jpg"],
             [UIImage imageNamed:@"man2 blur.jpg"],
             [UIImage imageNamed:@"kawa.jpg"],
             [UIImage imageNamed:@"man.jpg"],
             [UIImage imageNamed:@"3.png"]];
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return [self.collectionViewController visibleItems].count;
}

- (BSImageCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    BSImageCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"ImageCell" forIndexPath:indexPath];
    [cell.imageView setImage:[[self.collectionViewController visibleItems] objectAtIndex:indexPath.item]];
    [cell.imageView setContentMode:UIViewContentModeScaleAspectFill];
    [cell.imageView setClipsToBounds:YES];
    return cell;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    return CGSizeMake(CGRectGetWidth(self.view.frame), CGRectGetHeight(self.view.frame)/[collectionView numberOfItemsInSection:0]);
}

@end
