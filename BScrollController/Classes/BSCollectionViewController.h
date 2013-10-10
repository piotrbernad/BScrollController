//
//  GSCollectionViewController.h
//  GroupedScrollController
//
//  Created by Piotr Bernad on 08.10.2013.
//  Copyright (c) 2013 Piotr Bernad. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BSViewController.h"

@interface BSCollectionViewController : UICollectionViewController<BScrollProtocol>
@property (readonly, nonatomic) NSInteger currentPage;
@property (assign, nonatomic) NSInteger itemsPerPage;
@end
