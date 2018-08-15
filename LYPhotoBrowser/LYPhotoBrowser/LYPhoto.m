//
//  LYPhoto.m
//  LYPhotoBrowser
//
//  Created by yly on 2018/7/19.
//  Copyright © 2018年 yly. All rights reserved.
//

#import "LYPhoto.h"
#import <SDWebImageManager.h>
#import <SDWebImage/UIImage+GIF.h>
#import <SDImageCache.h>

@interface LYPhoto ()

// Methods
- (void)imageLoadingComplete;

@end

@implementation LYPhoto

@synthesize underlyingImage = _underlyingImage; // synth property from protocol

#pragma mark - Class Methods
+ (LYPhoto *)photoWithImage:(UIImage *)image {
    return [[LYPhoto alloc] initWithImage:image];
}
+ (LYPhoto *)photoWithURL:(NSURL *)url {
    return [[LYPhoto alloc] initWithURL:url];
}
//+ (LYPhoto *)photoWithAsset:(PHAsset *)asset targetSize:(CGSize)targetSize;
+ (LYPhoto *)videoWithURL:(NSURL *)url {
    return [[LYPhoto alloc] initWithVideoURL:url];
}

#pragma mark - init
- (id)initWithImage:(UIImage *)image {
    if ((self = [super init])) {
        self.underlyingImage = image;
    }
    return self;
}

- (id)initWithURL:(NSURL *)url {
    if ((self = [super init])) {
        _photoURL = [url copy];
    }
    return self;
}

- (id)initWithVideoURL:(NSURL *)url {
    if ((self = [super init])) {
        self.videoURL = [url copy];
        self.isVideo = YES;
    }
    return self;
}

- (void)setup {
//    _assetRequestID = PHInvalidImageRequestID;
//    _assetVideoRequestID = PHInvalidImageRequestID;
}

#pragma mark - LYPhoto Protocol Methods
- (UIImage *)underlyingImage {
    return _underlyingImage;
}

- (void)loadUnderlyingImageAndNotify {
    NSAssert([[NSThread currentThread] isMainThread], @"This method must be called on the main thread.");
    if (self.underlyingImage) {
        // Image already loaded
        [self imageLoadingComplete];
    } else {
        if (_photoURL) {
            // Load async from web (using SDWebImageManager)
            [[SDWebImageManager sharedManager] loadImageWithURL:_photoURL options:SDWebImageRetryFailed progress:^(NSInteger receivedSize, NSInteger expectedSize, NSURL * _Nullable targetURL) {
                CGFloat progress = ((CGFloat)receivedSize)/((CGFloat)expectedSize);
                
                if (self.progressUpdateBlock) {
                    self.progressUpdateBlock(progress);
                }
                
            } completed:^(UIImage * _Nullable image, NSData * _Nullable data, NSError * _Nullable error, SDImageCacheType cacheType, BOOL finished, NSURL * _Nullable imageURL) {
                if (image) {
                    self.underlyingImage = image;
                    if (data) {
                        [[SDImageCache sharedImageCache] storeImage:nil imageData:data forKey:imageURL.absoluteString toDisk:NO completion:nil];
                        self.underlyingImage = [UIImage sd_animatedGIFWithData:data];
                    }else {
                        [[SDImageCache sharedImageCache] queryCacheOperationForKey:imageURL.absoluteString options:SDImageCacheQueryDataWhenInMemory done:^(UIImage * _Nullable image, NSData * _Nullable data, SDImageCacheType cacheType) {
                            if (data) {
                                self.underlyingImage = [UIImage sd_animatedGIFWithData:data];
                            }
                        }];
                    }
                }
                
                [self performSelectorOnMainThread:@selector(imageLoadingComplete) withObject:nil waitUntilDone:NO];
            }];
        } else {
            // Failed - no source
            self.underlyingImage = nil;
            [self imageLoadingComplete];
        }
    }
}

// Release if we can get it again from path or url
- (void)unloadUnderlyingImage {
    self.underlyingImage = nil;
}

// Called on main
- (void)imageLoadingComplete {
    NSAssert([[NSThread currentThread] isMainThread], @"This method must be called on the main thread.");
    // Complete so notify
    [[NSNotificationCenter defaultCenter] postNotificationName:LYPHOTO_LOADING_DID_END_NOTIFICATION object:self];
}

#pragma mark - Video
- (void)setVideoURL:(NSURL *)videoURL {
    _videoURL = videoURL;
    self.isVideo = YES;
}

- (void)getVideoURL:(void (^)(NSURL *))completion {
    if (_videoURL) {
        completion(_videoURL);
    }
}

- (void)dealloc {
    
}

@end
