//
//  LYZoomingScrollView.m
//  LYPhotoBrowser
//
//  Created by yly on 2018/7/19.
//  Copyright © 2018年 yly. All rights reserved.
//

#import "LYZoomingScrollView.h"
#import "LYPhotoBrowser.h"
#import "LYTapDetectingImageView.h"
#import <DACircularProgressView.h>
#import <AVKit/AVKit.h>
#import <AVFoundation/AVFoundation.h>

// Declare private methods of browser
@interface LYPhotoBrowser ()
- (void)cancelControlHiding;
- (void)hideControlsAfterDelay;
- (void)toggleControls;
@end

@interface LYZoomingScrollView ()<UIScrollViewDelegate>
{
    LYPhotoBrowser __weak *_photoBrowser;
    LYTapDetectingImageView *_photoImageView;
    DACircularProgressView *_loadingIndicator;
    UIImageView *_loadingError;
    
    // Video
    AVPlayerViewController *_currentVideoPlayerViewController;
    NSUInteger _currentVideoIndex;
    UIActivityIndicatorView *_currentVideoLoadingIndicator;
}

@property (nonatomic, weak) UIButton *playButton;

@property (nonatomic) CGFloat maximumDoubleTapZoomScale;

@end

@implementation LYZoomingScrollView

- (id)initWithPhotoBrowser:(LYPhotoBrowser *)browser {
    if (self = [super init]) {
        
        // Setup
        _index = NSUIntegerMax;
        _photoBrowser = browser;
        
//        self.backgroundColor = [UIColor clearColor];
        self.delegate = self;
        self.showsHorizontalScrollIndicator = NO;
        self.showsVerticalScrollIndicator = NO;
        
        // Image view
        LYTapDetectingImageView *photoImageView = [[LYTapDetectingImageView alloc] initWithFrame:CGRectZero];
        [self addSubview:photoImageView];
        _photoImageView = photoImageView;
        
        // Loading indicator
        DACircularProgressView *loadingIndicator = [[DACircularProgressView alloc] initWithFrame:CGRectMake(0, 0, 40.0f, 40.0f)];
        loadingIndicator.center = [UIApplication sharedApplication].keyWindow.center;
        loadingIndicator.progress = 0;
        loadingIndicator.thicknessRatio = 0.1;
        loadingIndicator.roundedCorners = NO;
        [self addSubview:loadingIndicator];
        _loadingIndicator = loadingIndicator;
        
        _currentVideoIndex = NSUIntegerMax;
        
    }
    return self;
}

#pragma mark - Image
- (void)setPhoto:(id<LYPhoto>)photo {
    _photoImageView.image = nil; // Release image
    if (_photo != photo) {
        _photo = photo;
    }
    [self displayImage];
}

- (void)displayImage {
    if (_photo) {
        // Reset
        self.maximumZoomScale = 1;
        self.minimumZoomScale = 1;
        self.zoomScale = 1;
        
        self.contentSize = CGSizeMake(0, 0);
        
        UIImage *img = [self imageForPhoto:_photo];
        if (img) {
            // Hide indicator
            _loadingIndicator.alpha = 0;
            _loadingIndicator.progress = 0;
//            [_loadingIndicator removeFromSuperview];
            
            // Set image
            _photoImageView.image = img;
            _photoImageView.hidden = NO;
            
            // Setup photo frame
            CGRect photoImageViewFrame;
            photoImageViewFrame.origin = CGPointZero;
            photoImageViewFrame.size = img.size;
            
            _photoImageView.frame = photoImageViewFrame;
            self.contentSize = photoImageViewFrame.size;
            
            // Set zoom to minimum zoom
            [self setMaxMinZoomScalesForCurrentBounds];
        } else {
            // Hide image view
            _photoImageView.hidden = YES;
            [self hideImageFailure];
            _loadingIndicator.hidden = NO;
            _loadingIndicator.alpha = 1.0f;
            
            typeof(self) __weak weakSelf = self;
            LYPhoto *photo = (LYPhoto *)_photo;
            photo.progressUpdateBlock = ^(CGFloat progress){
                dispatch_async(dispatch_get_main_queue(), ^{
                    [weakSelf setProgress:progress forPhoto:self->_photo];
                });
            };
            
        }
        
        [self.playButton removeFromSuperview];
        self.playButton = nil;
        if (_photo.isVideo) {
            UIButton *playButton = [UIButton buttonWithType:UIButtonTypeCustom];
            [playButton setImage:[UIImage imageNamed:@"Resource.bundle/Assets/PlayButtonOverlayLarge"] forState:UIControlStateNormal];
            [playButton addTarget:self action:@selector(playButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
            [playButton sizeToFit];
            playButton.center = [UIApplication sharedApplication].keyWindow.center;
            [self addSubview:playButton];
            self.playButton = playButton;
        }
        
        [self setNeedsLayout];
    }
}

- (UIImage *)imageForPhoto:(id<LYPhoto>)photo {
    if (photo) {
        // Get image or obtain in background
        if ([photo underlyingImage]) {
            return [photo underlyingImage];
        }else {
            [photo loadUnderlyingImageAndNotify];
        }
    }
    return nil;
}

#pragma mark - video
- (void)playButtonTapped:(id)sender {
    // Ignore if we're already playing a video
    if (_currentVideoIndex != NSUIntegerMax) {
        return;
    }
    if (_index != NSUIntegerMax) {
        if (!_currentVideoPlayerViewController) {
            [self playVideoAtIndex:_index];
        }
    }
}

- (void)playVideoAtIndex:(NSUInteger)index {
    id photo = _photo/*[self photoAtIndex:index]*/;
    if ([photo respondsToSelector:@selector(getVideoURL:)]) {
    
        // Valid for playing
        [self clearCurrentVideo];
        _currentVideoIndex = index;
        [self setVideoLoadingIndicatorVisible:YES atPageIndex:index];
        
        // Get video and play
        typeof(self) __weak weakSelf = self;
        [photo getVideoURL:^(NSURL *url) {
            dispatch_async(dispatch_get_main_queue(), ^{
                // If the video is not playing anymore then bail
                typeof(self) strongSelf = weakSelf;
                if (!strongSelf) return;
                //                if (strongSelf->_currentVideoIndex != index) {
                //                    return;
                //                }
                if (url) {
                    [weakSelf _playVideo:url atPhotoIndex:index];
                } else {
                    [weakSelf setVideoLoadingIndicatorVisible:NO atPageIndex:index];
                }
            });
        }];
        
    }
}

- (void)_playVideo:(NSURL *)videoURL atPhotoIndex:(NSUInteger)index {
    
    // Setup player
    _currentVideoPlayerViewController = [[AVPlayerViewController alloc] init];
    _currentVideoPlayerViewController.player = [[AVPlayer alloc]initWithURL:videoURL];
    [_currentVideoPlayerViewController.player play];
    _currentVideoPlayerViewController.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    
    // Remove the movie player view controller from the "playback did finish" notification observers
    // Observe ourselves so we can get it to use the crossfade transition
    [[NSNotificationCenter defaultCenter] removeObserver:_currentVideoPlayerViewController
                                                    name:AVPlayerItemDidPlayToEndTimeNotification
                                                  object:_currentVideoPlayerViewController.player.currentItem];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(videoFinishedCallback:)
                                                 name:AVPlayerItemDidPlayToEndTimeNotification
                                               object:_currentVideoPlayerViewController.player.currentItem];
    
    // Show
    [_photoBrowser presentViewController:_currentVideoPlayerViewController animated:YES completion:^{
        [self clearCurrentVideo];
    }];
    
}

- (void)videoFinishedCallback:(NSNotification*)notification {
    
    // Remove observer
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:AVPlayerItemDidPlayToEndTimeNotification
                                                  object:_currentVideoPlayerViewController.player.currentItem];
    
    // Clear up
    [self clearCurrentVideo];
    
    // Dismiss
    BOOL error = [[[notification userInfo] objectForKey:AVPlayerItemFailedToPlayToEndTimeErrorKey] intValue];
    if (error) {
        // Error occured so dismiss with a delay incase error was immediate and we need to wait to dismiss the VC
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self->_photoBrowser dismissViewControllerAnimated:YES completion:nil];
        });
    } else {
        [_photoBrowser dismissViewControllerAnimated:YES completion:nil];
    }
    
}

- (void)clearCurrentVideo {
    
    [_currentVideoPlayerViewController.player seekToTime:kCMTimeZero];
    [_currentVideoLoadingIndicator removeFromSuperview];
    _currentVideoPlayerViewController = nil;
    _currentVideoLoadingIndicator = nil;
    self.playButton.hidden = NO;
    _currentVideoIndex = NSUIntegerMax;
    
}

- (void)setVideoLoadingIndicatorVisible:(BOOL)visible atPageIndex:(NSUInteger)pageIndex {
    if (_currentVideoLoadingIndicator && !visible) {
        [_currentVideoLoadingIndicator removeFromSuperview];
        _currentVideoLoadingIndicator = nil;
        self.playButton.hidden = NO;
    } else if (!_currentVideoLoadingIndicator && visible) {
        _currentVideoLoadingIndicator = [[UIActivityIndicatorView alloc] initWithFrame:CGRectZero];
        [_currentVideoLoadingIndicator sizeToFit];
        [_currentVideoLoadingIndicator startAnimating];
        [self addSubview:_currentVideoLoadingIndicator];
        [self positionVideoLoadingIndicator];
        self.playButton.hidden = YES;
    }
}

- (void)positionVideoLoadingIndicator {
    if (_currentVideoLoadingIndicator && _currentVideoIndex != NSUIntegerMax) {
        _currentVideoLoadingIndicator.center = [UIApplication sharedApplication].keyWindow.center;
    }
}

#pragma mark - ZoomScales
- (void)setMaxMinZoomScalesForCurrentBounds {
    // Reset
    self.maximumZoomScale = 1;
    self.minimumZoomScale = 1;
    self.zoomScale = 1;
    
    // Bail
    if (_photoImageView.image == nil) return;
    
    // Sizes
    CGSize boundsSize = self.bounds.size;
    CGSize imageSize = _photoImageView.frame.size;
    
    // Calculate Min
    CGFloat xScale = boundsSize.width / imageSize.width;    // the scale needed to perfectly fit the image width-wise
    CGFloat yScale = boundsSize.height / imageSize.height;  // the scale needed to perfectly fit the image height-wise
    CGFloat minScale = MIN(xScale, yScale);                 // use minimum of these to allow the image to become fully visible
    
    // If image is smaller than the screen then ensure we show it at
    // min scale of 1
    if (xScale > 1 && yScale > 1) {
        minScale = 1.0;
    }
    
    // Calculate Max
    CGFloat maxScale = 4.0; // Allow double scale
    // on high resolution screens we have double the pixel density, so we will be seeing every pixel if we limit the
    // maximum zoom scale to 0.5.
    if ([UIScreen instancesRespondToSelector:@selector(scale)]) {
        maxScale = maxScale / [[UIScreen mainScreen] scale];
        
        if (maxScale < minScale) {
            maxScale = minScale * 2;
        }
    }
    
    // Calculate Max Scale Of Double Tap
    CGFloat maxDoubleTapZoomScale = 4.0 * minScale; // Allow double scale
    // on high resolution screens we have double the pixel density, so we will be seeing every pixel if we limit the
    // maximum zoom scale to 0.5.
    if ([UIScreen instancesRespondToSelector:@selector(scale)]) {
        maxDoubleTapZoomScale = maxDoubleTapZoomScale / [[UIScreen mainScreen] scale];
        
        if (maxDoubleTapZoomScale < minScale) {
            maxDoubleTapZoomScale = minScale * 2;
        }
    }
    
    // Make sure maxDoubleTapZoomScale isn't larger than maxScale
    maxDoubleTapZoomScale = MIN(maxDoubleTapZoomScale, maxScale);
    
    // Set
    self.maximumZoomScale = maxScale;
    self.minimumZoomScale = minScale;
    self.zoomScale = minScale;
    self.maximumDoubleTapZoomScale = maxDoubleTapZoomScale;
    
    // Reset position
    _photoImageView.frame = CGRectMake(0, 0, _photoImageView.frame.size.width, _photoImageView.frame.size.height);
    
    // Disable scrolling initially until the first pinch to fix issues with swiping on an initally zoomed in photo
    self.scrollEnabled = NO;
    
    // If it's a video then disable zooming
    if (_photo.isVideo) {
        self.maximumZoomScale = self.zoomScale;
        self.minimumZoomScale = self.zoomScale;
    }
    
    [self setNeedsLayout];
}

#pragma mark - Progress
- (void)setProgress:(CGFloat)progress forPhoto:(LYPhoto *)photo {
    LYPhoto *p = (LYPhoto *)self.photo;
    
    if ([photo.photoURL.absoluteString isEqualToString:p.photoURL.absoluteString]) {
        if (_loadingIndicator.progress < progress) {
            [_loadingIndicator setProgress:progress animated:YES];
        }
    }
}

// Image failed
- (void)displayImageFailure {
    _loadingIndicator.hidden = YES;
    _photoImageView.image = nil;
    if (![_photo underlyingImage]) {
        if (!_loadingError) {
            _loadingError = [UIImageView new];
            _loadingError.image = [UIImage imageNamed:@"Resource.bundle/Assets/ImageError"];
            _loadingError.userInteractionEnabled = NO;
//            _loadingError.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleTopMargin |
//            UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleRightMargin;
            [_loadingError sizeToFit];
            [self addSubview:_loadingError];
        }
        _loadingError.center = self.center;
    }
}

- (void)hideImageFailure {
    if (_loadingError) {
        [_loadingError removeFromSuperview];
        _loadingError = nil;
    }
}

#pragma mark - Layout
- (void)layoutSubviews {
    // Super
    [super layoutSubviews];
    
    _loadingIndicator.center = [UIApplication sharedApplication].keyWindow.center;
    self.playButton.center = [UIApplication sharedApplication].keyWindow.center;
    _loadingError.center = self.center;
    
    // Center the image as it becomes smaller than the size of the screen
    CGSize boundsSize = self.bounds.size;
    CGRect frameToCenter = _photoImageView.frame;
    
    // Horizontally
    if (frameToCenter.size.width < boundsSize.width) {
        frameToCenter.origin.x = floorf((boundsSize.width - frameToCenter.size.width) / 2.0);
    } else {
        frameToCenter.origin.x = 0;
    }
    
    // Vertically
    if (frameToCenter.size.height < boundsSize.height) {
        frameToCenter.origin.y = floorf((boundsSize.height - frameToCenter.size.height) / 2.0);
    } else {
        frameToCenter.origin.y = 0;
    }
    
    // Center
    if (!CGRectEqualToRect(_photoImageView.frame, frameToCenter))
    _photoImageView.frame = frameToCenter;
}

#pragma mark - prepareForReuse
- (void)prepareForReuse {
    [self hideImageFailure];
    self.photo = nil;
    [_captionView removeFromSuperview];
    self.captionView = nil;
//    [_playButton removeFromSuperview];
//    self.playButton = nil;
}


#pragma mark - UIScrollViewDelegate

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
    return _photoImageView;
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    [_photoBrowser cancelControlHiding];
}

- (void)scrollViewWillBeginZooming:(UIScrollView *)scrollView withView:(UIView *)view {
    self.scrollEnabled = YES; // reset
    [_photoBrowser cancelControlHiding];
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    [_photoBrowser hideControlsAfterDelay];
}

- (void)scrollViewDidZoom:(UIScrollView *)scrollView {
    [self setNeedsLayout];
    [self layoutIfNeeded];
}

#pragma mark - Tap Detection
- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    UITouch *touch = [touches anyObject];
    NSUInteger tapCount = touch.tapCount;
    switch (tapCount) {
        case 1:
            [self handleSingleTap:[touch locationInView:_photoImageView]];
            break;
        case 2:
            [self handleDoubleTap:[touch locationInView:_photoImageView]];
            break;
        default:
            break;
    }
}

- (void)handleSingleTap:(CGPoint)touchPoint {
    [_photoBrowser performSelector:@selector(toggleControls) withObject:nil afterDelay:0.2];
}

- (void)handleDoubleTap:(CGPoint)touchPoint {
    
    // Dont double tap to zoom if showing a video
    if (_photo.isVideo) return;
    
    // Cancel any single tap handling
    [NSObject cancelPreviousPerformRequestsWithTarget:_photoBrowser];
    
    // Zoom
    if (self.zoomScale != self.minimumZoomScale) {
        
        // Zoom out
        [self setZoomScale:self.minimumZoomScale animated:YES];
        
    } else {
        
        // Zoom in
        CGSize targetSize = CGSizeMake(self.frame.size.width / self.maximumDoubleTapZoomScale, self.frame.size.height / self.maximumDoubleTapZoomScale);
        CGPoint targetPoint = CGPointMake(touchPoint.x - targetSize.width / 2, touchPoint.y - targetSize.height / 2);
        
        [self zoomToRect:CGRectMake(targetPoint.x, targetPoint.y, targetSize.width, targetSize.height) animated:YES];
        
    }
    
    // Delay controls
    [_photoBrowser hideControlsAfterDelay];
    
}


- (void)dealloc {
//    if ([_photo respondsToSelector:@selector(cancelAnyLoading)]) {
//        [_photo cancelAnyLoading];
//    }
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
