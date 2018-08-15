//
//  LYZoomingScrollView.h
//  LYPhotoBrowser
//
//  Created by yly on 2018/7/19.
//  Copyright © 2018年 yly. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LYPhotoProtocol.h"
#import "LYCaptionView.h"

@class LYPhotoBrowser, LYPhoto;

@interface LYZoomingScrollView : UIScrollView

@property () NSUInteger index;
@property (nonatomic, strong) id <LYPhoto> photo;
@property (nonatomic, weak) LYCaptionView *captionView;

- (id)initWithPhotoBrowser:(LYPhotoBrowser *)browser;
- (void)prepareForReuse;
- (void)setMaxMinZoomScalesForCurrentBounds;
- (void)displayImage;
- (void)displayImageFailure;

@end
