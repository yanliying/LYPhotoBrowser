//
//  LYPhoto.h
//  LYPhotoBrowser
//
//  Created by yly on 2018/7/19.
//  Copyright © 2018年 yly. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LYPhotoProtocol.h"

@interface LYPhoto : NSObject <LYPhoto>

// Progress download block, used to update the progress
typedef void (^LYProgressUpdateBlock)(CGFloat progress);

@property (nonatomic, copy) LYProgressUpdateBlock progressUpdateBlock;

@property (nonatomic, strong) NSURL *photoURL;
@property (nonatomic, strong) NSURL *videoURL;
@property (nonatomic) BOOL isVideo;
@property (nonatomic, strong) NSString *caption;

+ (LYPhoto *)photoWithImage:(UIImage *)image;
+ (LYPhoto *)photoWithURL:(NSURL *)url;
//+ (LYPhoto *)photoWithAsset:(PHAsset *)asset targetSize:(CGSize)targetSize;
+ (LYPhoto *)videoWithURL:(NSURL *)url; // Initialise video with no poster image

- (id)initWithImage:(UIImage *)image;
- (id)initWithURL:(NSURL *)url;
//- (id)initWithAsset:(PHAsset *)asset targetSize:(CGSize)targetSize;
- (id)initWithVideoURL:(NSURL *)url;

@end
