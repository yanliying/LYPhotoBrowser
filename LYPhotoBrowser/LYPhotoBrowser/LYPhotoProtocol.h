//
//  LYPhotoProtocol.h
//  LYPhotoBrowser
//
//  Created by yly on 2018/7/19.
//  Copyright © 2018年 yly. All rights reserved.
//

#import <UIKit/UIKit.h>

// Name of notification used when a photo has completed loading process
// Used to notify browser display the image
#define LYPHOTO_LOADING_DID_END_NOTIFICATION @"LYPHOTO_LOADING_DID_END_NOTIFICATION"

// If you wish to use your own data models for photo then they must conform
// to this protocol. See instructions for details on each method.
// Otherwise you can use the LYPhoto object or subclass it yourself to
// store more information per photo.
//
// You can see the LYPhoto class for an example implementation of this protocol
//
@protocol LYPhoto <NSObject>

@required

// Return underlying UIImage to be displayed
// Return nil if the image is not immediately available (loaded into memory, preferably
// already decompressed) and needs to be loaded from a source (cache, file, web, etc)
// IMPORTANT: You should *NOT* use this method to initiate
// fetching of images from any external of source. That should be handled
// in -loadUnderlyingImageAndNotify: which may be called by the photo browser if this
// methods returns nil.
@property (nonatomic, strong) UIImage *underlyingImage;

// Called when the browser has determined the underlying images is not
// already loaded into memory but needs it.
// You must load the image asyncronously (and decompress it for better performance).
// It is recommended that you use SDWebImageDecoder to perform the decompression.
// See LYPhoto object for an example implementation.
// When the underlying UIImage is loaded (or failed to load) you should post the following
// notification:
// [[NSNotificationCenter defaultCenter] postNotificationName:LYPHOTO_LOADING_DID_END_NOTIFICATION
//                                                     object:self];
- (void)loadUnderlyingImageAndNotify;

// This is called when the photo browser has determined the photo data
// is no longer needed or there are low memory conditions
// You should release any underlying (possibly large and decompressed) image data
// as long as the image can be re-loaded (from cache, file, or URL)
- (void)unloadUnderlyingImage;

@optional

// Video
@property (nonatomic) BOOL isVideo;
- (void)getVideoURL:(void (^)(NSURL *url))completion;

// Return a caption string to be displayed over the image
// Return nil to display no caption
- (NSString *)caption;

// Cancel any background loading of image data
//- (void)cancelAnyLoading;

@end
