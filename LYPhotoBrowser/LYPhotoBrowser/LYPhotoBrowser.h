//
//  LYPhotoBrowser.h
//  LYPhotoBrowser
//
//  Created by yly on 2018/7/17.
//  Copyright © 2018年 yly. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LYPhoto.h"
#import "LYCaptionView.h"

@class LYPhotoBrowser;
@protocol LYPhotoBrowserDelegate <NSObject>

- (NSUInteger)numberOfPhotosInPhotoBrowser:(LYPhotoBrowser *)photoBrowser;
- (id <LYPhoto>)photoBrowser:(LYPhotoBrowser *)photoBrowser photoAtIndex:(NSUInteger)index;

@optional
- (LYCaptionView *)photoBrowser:(LYPhotoBrowser *)photoBrowser captionViewForPhotoAtIndex:(NSUInteger)index;

@end

@interface LYPhotoBrowser : UIViewController

// Properties
@property (nonatomic, strong) id <LYPhotoBrowserDelegate> delegate;

// Init
- (id)initWithDelegate:(id <LYPhotoBrowserDelegate>)delegate;
- (id)initWithPhotos:(NSArray *)photosArray;

// Set page that photo browser starts on
- (void)setCurrentPhotoIndex:(NSUInteger)index;


@end
