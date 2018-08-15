//
//  LYTapDetectingImageView.m
//  LYPhotoBrowser
//
//  Created by yly on 2018/7/19.
//  Copyright © 2018年 yly. All rights reserved.
//

#import "LYTapDetectingImageView.h"

@implementation LYTapDetectingImageView

- (id)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {
    }
    return self;
}

- (id)initWithImage:(UIImage *)image {
    if ((self = [super initWithImage:image])) {
    }
    return self;
}

- (id)initWithImage:(UIImage *)image highlightedImage:(UIImage *)highlightedImage {
    if ((self = [super initWithImage:image highlightedImage:highlightedImage])) {
    }
    return self;
}


/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
