//
//  GSImageCell.m
//  GroupedScrollController
//
//  Created by Piotr Bernad on 08.10.2013.
//  Copyright (c) 2013 Piotr Bernad. All rights reserved.
//

#import "BSImageCell.h"

@implementation BSImageCell

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        _imageView = [[UIImageView alloc] init];
        [self addSubview:_imageView];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    [_imageView setFrame:self.bounds];
}

@end
