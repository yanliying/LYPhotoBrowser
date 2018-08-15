//
//  LYPhotoBrowser.m
//  LYPhotoBrowser
//
//  Created by yly on 2018/7/17.
//  Copyright © 2018年 yly. All rights reserved.
//

#import "LYPhotoBrowser.h"
#import "LYPhotoBrowserConstants.h"
#import "LYZoomingScrollView.h"

@interface LYPhotoBrowser ()<UIScrollViewDelegate>
{
    UIScrollView *_pagingScrollView;
    UIView *_toolbar;
    UIView *_naviBar;
    UILabel *_counterLabel;
    UIButton *_doneButton;
    
    // Data
    NSMutableArray *_photos;
    NSMutableArray *_thumbPhotos;
    NSMutableSet *_visiblePages, *_recycledPages;
    NSUInteger _currentPageIndex;
    
    // Misc
    BOOL _performingLayout;
    BOOL _viewIsActive; // active as in it's in the view heirarchy
    BOOL _autoHide;
    NSInteger _initalPageIndex;
    CGFloat _statusBarHeight;
    
    // Control
    NSTimer *_controlVisibilityTimer;
}

@end

@implementation LYPhotoBrowser

- (instancetype)init {
    if (self = [super init]) {
        
        _photos = [NSMutableArray array];
        _thumbPhotos = [NSMutableArray array];
        _visiblePages = [NSMutableSet set];
        _recycledPages = [NSMutableSet set];
        _currentPageIndex = 0;
        
        _performingLayout = NO; // Reset on view did appear
        _viewIsActive = NO;
        
        if ([self respondsToSelector:@selector(automaticallyAdjustsScrollViewInsets)]) {
            self.automaticallyAdjustsScrollViewInsets = NO;
        }
        
        // Listen for Photo notifications
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handlePhotoLoadingDidEndNotification:) name:LYPHOTO_LOADING_DID_END_NOTIFICATION object:nil];
        
    }
    return self;
}

- (id)initWithDelegate:(id<LYPhotoBrowserDelegate>)delegate {
    if (self = [self init]) {
        _delegate = delegate;
    }
    return self;
}

- (id)initWithPhotos:(NSArray *)photosArray {
    if (self = [self init]) {
        _photos = [NSMutableArray arrayWithArray:photosArray];
    }
    return self;
}

#pragma mark - View Loading
- (void)viewDidLoad {
    self.navigationController.navigationBarHidden = YES;
    self.view.backgroundColor = [UIColor blackColor];
    self.view.clipsToBounds = YES;
    
    CGRect pagingScrollViewFrame = [self frameForPagingScrollView];
    UIScrollView *scrollView = [[UIScrollView alloc] initWithFrame:pagingScrollViewFrame];
    scrollView.pagingEnabled = YES;
    scrollView.showsHorizontalScrollIndicator = NO;
    scrollView.showsVerticalScrollIndicator = NO;
//    scrollView.backgroundColor = [UIColor blackColor];
    scrollView.contentSize = [self contentSizeForPagingScrollView];
    scrollView.delegate = self;
    [self.view addSubview:scrollView];
    _pagingScrollView = scrollView;
    
    // Toolbar
    UIInterfaceOrientation currentOrientation = [UIApplication sharedApplication].statusBarOrientation;
    UIView *toolbar = [[UIView alloc] initWithFrame:[self frameForToolbarAtOrientation:currentOrientation]];
    _toolbar = toolbar;
    
    UIView *naviBar = [[UIView alloc] initWithFrame:[self frameForNaviBarAtOrientation:currentOrientation]];
    naviBar.backgroundColor = [UIColor colorWithWhite:0 alpha:0.3];
    [self.view addSubview:naviBar];
    _naviBar = naviBar;
    
    // Counter Label
    UILabel *counterLabel = [[UILabel alloc] initWithFrame:[self frameForCounterLabelAtOrientation:currentOrientation]];
    counterLabel.textColor = [UIColor whiteColor];
    counterLabel.textAlignment = NSTextAlignmentCenter;
    counterLabel.backgroundColor = [UIColor clearColor];
    [naviBar addSubview:counterLabel];
    _counterLabel = counterLabel;
    
    UIButton *doneButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [doneButton setTitle:@"done" forState:UIControlStateNormal];
    doneButton.titleLabel.textAlignment = NSTextAlignmentRight;
    [doneButton setFrame:[self frameForDoneButtonAtOrientation:currentOrientation]];
    [doneButton sizeToFit];
    [doneButton setAlpha:1.0f];
    [doneButton addTarget:self action:@selector(doneButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    [naviBar addSubview:doneButton];
    _doneButton = doneButton;
    
    // super
    [super viewDidLoad];
    
    [self reloadData];
}

- (void)viewWillAppear:(BOOL)animated {
    
    [super viewWillAppear:animated];
    
    // Update UI
    [self hideControlsAfterDelay];
    
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    _viewIsActive = YES;
}

- (void)viewWillDisappear:(BOOL)animated {
    
    [self setControlsHidden:NO animated:NO permanent:YES];
    
    [super viewWillDisappear:animated];
}

#pragma mark - Data
- (NSUInteger)numberOfPhotos {
    NSUInteger photoCount = _photos.count;
    if ([_delegate respondsToSelector:@selector(numberOfPhotosInPhotoBrowser:)]) {
        photoCount = [_delegate numberOfPhotosInPhotoBrowser:self];
    }
    return photoCount;
}

- (void)reloadData {
    // Get data
    [self releaseAllUnderlyingPhotos];
    
    [_photos removeAllObjects];
    [_thumbPhotos removeAllObjects];
    for (int i = 0; i < [self numberOfPhotos]; i++) {
        [_photos addObject:[NSNull null]];
        [_thumbPhotos addObject:[NSNull null]];
    }
    
    // Update
    [self performLayout];
    
    // Layout
    [self.view setNeedsLayout];
}

#pragma mark - Layout
- (void)performLayout {
    
    // Setup
    _performingLayout = YES;
    
    // Setup pages
    [_visiblePages removeAllObjects];
    [_recycledPages removeAllObjects];
    
    // Navigation buttons
//    if ([self.navigationController.viewControllers objectAtIndex:0] == self) {
//        // We're first on stack so show done button
//        UIBarButtonItem *_doneButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Done", nil) style:UIBarButtonItemStylePlain target:self action:@selector(doneButtonPressed:)];
//        self.navigationItem.rightBarButtonItem = _doneButton;
//    } else {
//        // We're not first so show back button
//        UIViewController *previousViewController = [self.navigationController.viewControllers objectAtIndex:self.navigationController.viewControllers.count-2];
//        UIBarButtonItem *newBackButton = [[UIBarButtonItem alloc] initWithTitle:@"返回" style:UIBarButtonItemStylePlain target:nil action:nil];
//        previousViewController.navigationItem.backBarButtonItem = newBackButton;
//    }
    
    // Toolbar
//    if ([self.delegate respondsToSelector:@selector(photoBrowser:toolbarForPhotoAtIndex:)]) {
//        UIView *toolbar = [self.delegate photoBrowser:self toolbarForPhotoAtIndex:_currentPageIndex];
//        _toolbar = toolbar;
//        [self.view addSubview:_toolbar];
//    } else {
//        [_toolbar removeFromSuperview];
//    }
    
    // Close button
//    if(_displayDoneButton && !self.navigationController.navigationBar)
//        [self.view addSubview:_doneButton];
    
    // Update nav
    [self updateNavigation];
    
    // Content offset
    _pagingScrollView.contentOffset = [self contentOffsetForPageAtIndex:_currentPageIndex];
    
    // pages
    [self tilePages];
    
    _performingLayout = NO;
    
}

- (void)viewWillLayoutSubviews {
    // Flag
    _performingLayout = YES;
    
    UIInterfaceOrientation currentOrientation = [UIApplication sharedApplication].statusBarOrientation;
    
    // Toolbar
    _toolbar.frame = [self frameForToolbarAtOrientation:currentOrientation];
    _naviBar.frame = [self frameForNaviBarAtOrientation:currentOrientation];
    _counterLabel.frame = [self frameForCounterLabelAtOrientation:currentOrientation];
    _doneButton.frame = [self frameForDoneButtonAtOrientation:currentOrientation];
    
    // Get paging scroll view frame to determine if anything needs changing
    CGRect pagingScrollViewFrame = [self frameForPagingScrollView];
    
    // Frame needs changing
    _pagingScrollView.frame = pagingScrollViewFrame;
    
    // Recalculate contentSize based on current orientation
    _pagingScrollView.contentSize = [self contentSizeForPagingScrollView];
    
    // Adjust frames and configuration of each visible page
    for (LYZoomingScrollView *page in _visiblePages) {
        NSUInteger index = page.index;
        page.frame = [self frameForPageAtIndex:index];
        page.captionView.frame = [self frameForCaptionView:page.captionView atIndex:index];
        [page setMaxMinZoomScalesForCurrentBounds];
    }
    
    // Adjust contentOffset to preserve page location based on values collected prior to location
    _pagingScrollView.contentOffset = [self contentOffsetForPageAtIndex:_currentPageIndex];
//    [self didStartViewingPageAtIndex:_currentPageIndex]; // initial
    
    // Reset
    _performingLayout = NO;
    
    // Super
    [super viewWillLayoutSubviews];
}

#pragma mark - Properties
- (void)setCurrentPhotoIndex:(NSUInteger)index {
    // Validate
    if (index >= [self numberOfPhotos])
    index = [self numberOfPhotos]-1;
    _currentPageIndex = index;
    if ([self isViewLoaded]) {
        [self jumpToPageAtIndex:index animated:NO];
        if (!_viewIsActive)
        [self tilePages]; // Force tiling if view is not visible
    }
}

- (void)jumpToPageAtIndex:(NSUInteger)index animated:(BOOL)animated {
    // Change page
    if (index < [self numberOfPhotos]) {
        CGRect pageFrame = [self frameForPageAtIndex:index];
        [_pagingScrollView setContentOffset:CGPointMake(pageFrame.origin.x - PADDING, 0) animated:animated];
        [self updateNavigation];
    }
    
    // Update timer to give more time
    [self hideControlsAfterDelay];
    
}

#pragma mark - Interactions
- (void)doneButtonPressed:(id)sender {
    // Only if we're modal and there's a done button
    // Dismiss view controller
    //    if ([_delegate respondsToSelector:@selector(photoBrowserDidFinishModalPresentation:)]) {
    //        // Call delegate method and let them dismiss us
    //        [_delegate photoBrowserDidFinishModalPresentation:self];
    //    } else  {
    if (self.presentingViewController) {
        [self dismissViewControllerAnimated:YES completion:nil];
    }else {
        [self.navigationController popViewControllerAnimated:YES];
        self.navigationController.navigationBarHidden = NO;
    }
    
    //    }
}

#pragma mark - Paging
- (void)tilePages {
    
    // Calculate which pages should be visible
    // Ignore padding as paging bounces encroach on that
    // and lead to false page loads
    CGRect visibleBounds = _pagingScrollView.bounds;
    NSInteger iFirstIndex = (NSInteger)floorf((CGRectGetMinX(visibleBounds)+PADDING*2) / CGRectGetWidth(visibleBounds));
    NSInteger iLastIndex  = (NSInteger)floorf((CGRectGetMaxX(visibleBounds)-PADDING*2-1) / CGRectGetWidth(visibleBounds));
    if (iFirstIndex < 0) iFirstIndex = 0;
    if (iFirstIndex > [self numberOfPhotos] - 1) iFirstIndex = [self numberOfPhotos] - 1;
    if (iLastIndex < 0) iLastIndex = 0;
    if (iLastIndex > [self numberOfPhotos] - 1) iLastIndex = [self numberOfPhotos] - 1;
    
    // Recycle no longer needed pages
    NSInteger pageIndex;
    for (LYZoomingScrollView *page in _visiblePages) {
        pageIndex = page.index;
        if (pageIndex < (NSUInteger)iFirstIndex || pageIndex > (NSUInteger)iLastIndex) {
            [_recycledPages addObject:page];
//            [page.captionView removeFromSuperview];
//            [page.playButton removeFromSuperview];
            [page prepareForReuse];
            [page removeFromSuperview];
            LYLog(@"Removed page at index %lu", (unsigned long)pageIndex);
        }
    }
    [_visiblePages minusSet:_recycledPages];
    while (_recycledPages.count > 2) // Only keep 2 recycled pages
        [_recycledPages removeObject:[_recycledPages anyObject]];
    
    // Add missing pages
    for (NSUInteger index = (NSUInteger)iFirstIndex; index <= (NSUInteger)iLastIndex; index++) {
        if (![self isDisplayingPageForIndex:index]) {
            
            // Add new page
            LYZoomingScrollView *page = [self dequeueRecycledPage];
            if (!page) {
                page = [[LYZoomingScrollView alloc] initWithPhotoBrowser:self];
            }
            [_visiblePages addObject:page];
            
            [self configurePage:page forIndex:index];
            
            [_pagingScrollView addSubview:page];
            LYLog(@"Added page at index %lu", (unsigned long)index);
            
            // Add caption
            LYCaptionView *captionView = [self captionViewForPhotoAtIndex:index];
            if (captionView) {
                captionView.frame = [self frameForCaptionView:captionView atIndex:index];
                [_pagingScrollView addSubview:captionView];
                page.captionView = captionView;
            }
            
        }
    }
    
}

- (BOOL)isDisplayingPageForIndex:(NSUInteger)index {
    for (LYZoomingScrollView *page in _visiblePages)
        if (page.index == index) return YES;
    return NO;
}

- (LYZoomingScrollView *)dequeueRecycledPage {
    LYZoomingScrollView *page = [_recycledPages anyObject];
    if (page) {
        [_recycledPages removeObject:page];
    }
    return page;
}

- (void)configurePage:(LYZoomingScrollView *)page forIndex:(NSUInteger)index {
    page.frame = [self frameForPageAtIndex:index];
    page.index = index;
    page.photo = [self photoAtIndex:index];
}

- (id<LYPhoto>)photoAtIndex:(NSUInteger)index {
    id <LYPhoto> photo = nil;
    if (index < _photos.count) {
        if ([_photos objectAtIndex:index] == [NSNull null]) {
            if ([_delegate respondsToSelector:@selector(photoBrowser:photoAtIndex:)]) {
                photo = [_delegate photoBrowser:self photoAtIndex:index];
            }
            if (photo) [_photos replaceObjectAtIndex:index withObject:photo];
        } else {
            photo = [_photos objectAtIndex:index];
        }
    }
    return photo;
}

- (LYZoomingScrollView *)pageDisplayingPhoto:(id<LYPhoto>)photo {
    LYZoomingScrollView *thePage = nil;
    for (LYZoomingScrollView *page in _visiblePages) {
        if (page.photo == photo) {
            thePage = page; break;
        }
    }
    return thePage;
}

- (LYCaptionView *)captionViewForPhotoAtIndex:(NSUInteger)index {
    LYCaptionView *captionView = nil;
    if ([_delegate respondsToSelector:@selector(photoBrowser:captionViewForPhotoAtIndex:)]) {
        captionView = [_delegate photoBrowser:self captionViewForPhotoAtIndex:index];
    } else {
        id <LYPhoto> photo = [self photoAtIndex:index];
        if ([photo respondsToSelector:@selector(caption)]) {
            if ([photo caption]) captionView = [[LYCaptionView alloc] initWithPhoto:photo];
        }
    }
    captionView.alpha = [self areControlsHidden] ? 0 : 1; // Initial alpha
    
    return captionView;
}

#pragma mark - Navigation
- (void)updateNavigation {
    if ([self numberOfPhotos] > 1) {
        _counterLabel.text = [NSString stringWithFormat:@"%lu %@ %lu", (unsigned long)(_currentPageIndex+1), NSLocalizedString(@"of", @"Used in the context: 'Showing 1 of 3 items'"), (unsigned long)[self numberOfPhotos]];
    } else {
        _counterLabel.text = nil;
    }
}

#pragma mark - Control Hiding / Showing
// Enable/disable control visiblity timer
- (void)hideControlsAfterDelay {
    if (![self areControlsHidden]) {
        [self cancelControlHiding];
        _controlVisibilityTimer = [NSTimer scheduledTimerWithTimeInterval:5 target:self selector:@selector(hideControls) userInfo:nil repeats:NO];
    }
}

- (BOOL)areControlsHidden { return (_toolbar.alpha == 0); }

- (void)cancelControlHiding {
    // If a timer exists then cancel and release
    if (_controlVisibilityTimer) {
        [_controlVisibilityTimer invalidate];
        _controlVisibilityTimer = nil;
    }
}

- (void)hideControls { [self setControlsHidden:YES animated:YES permanent:NO]; }
- (void)toggleControls { [self setControlsHidden:![self areControlsHidden] animated:YES permanent:NO]; }

// If permanent then we don't set timers to hide again
- (void)setControlsHidden:(BOOL)hidden animated:(BOOL)animated permanent:(BOOL)permanent {
    // Cancel any timers
    [self cancelControlHiding];
    
    // Captions
    NSMutableSet *captionViews = [[NSMutableSet alloc] initWithCapacity:_visiblePages.count];
    for (LYZoomingScrollView *page in _visiblePages) {
        if (page.captionView) [captionViews addObject:page.captionView];
    }
    
    // Hide/show bars
    [UIView animateWithDuration:(animated ? 0.3 : 0) animations:^(void) {
        CGFloat alpha = hidden ? 0 : 1;
        [self->_naviBar setAlpha:alpha];
        [self->_toolbar setAlpha:alpha];
//        [_doneButton setAlpha:alpha];
        for (UIView *v in captionViews) v.alpha = alpha;
    } completion:^(BOOL finished) {}];
    
    // Control hiding timer
    // Will cancel existing timer but only begin hiding if they are visible
    if (!permanent) {
        [self hideControlsAfterDelay];
    }
    
    [self setNeedsStatusBarAppearanceUpdate];
}

#pragma mark - UIScrollView Delegate
- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    
    // Checks
    if (!_viewIsActive || _performingLayout) return;
    
    // Tile pages
    [self tilePages];
    
    // Calculate current page
    CGRect visibleBounds = _pagingScrollView.bounds;
    NSInteger index = (NSInteger) (floorf(CGRectGetMidX(visibleBounds) / CGRectGetWidth(visibleBounds)));
    if (index < 0) index = 0;
    if (index > [self numberOfPhotos] - 1) index = [self numberOfPhotos] - 1;
    NSUInteger previousCurrentPage = _currentPageIndex;
    _currentPageIndex = index;
    if (_currentPageIndex != previousCurrentPage) {
//        [self didStartViewingPageAtIndex:index];
        
        
    }
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    // Hide controls when dragging begins
    [self setControlsHidden:YES animated:YES permanent:NO];
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    // Update nav when page changes
    [self updateNavigation];
}

#pragma mark - Frame
- (CGRect)frameForPagingScrollView {
    CGRect frame = self.view.bounds;
    frame.origin.x -= PADDING;
    frame.size.width += (2 * PADDING);
    frame = [self adjustForSafeArea:frame adjustForStatusBar:false];
    return CGRectIntegral(frame);
}

- (CGSize)contentSizeForPagingScrollView {
    // We have to use the paging scroll view's bounds to calculate the contentSize, for the same reason outlined above.
    CGRect bounds = _pagingScrollView.bounds;
    return CGSizeMake(bounds.size.width * [self numberOfPhotos], bounds.size.height);
}

- (CGRect)frameForToolbarAtOrientation:(UIInterfaceOrientation)orientation {
    CGFloat height = 44;
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone &&
        UIInterfaceOrientationIsLandscape(orientation)) {
        height = 32;
    }
    CGRect frame = CGRectMake(0, self.view.bounds.size.height - height, self.view.bounds.size.width, height);
    frame = [self adjustForSafeArea:frame adjustForStatusBar:true];
    return frame;
}

- (CGRect)frameForNaviBarAtOrientation:(UIInterfaceOrientation)orientation {
    CGFloat height = 64;
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone &&
        UIInterfaceOrientationIsLandscape(orientation)) {
        height = 32;
    }
    
    CGRect screenBound = self.view.bounds;
    CGFloat screenWidth = screenBound.size.width;
    
    CGRect frame = CGRectMake(0, 0, screenWidth, height);
    frame = [self adjustForSafeArea:frame adjustForStatusBar:false];
    return frame;
}

- (CGRect)frameForCounterLabelAtOrientation:(UIInterfaceOrientation)orientation {
    CGFloat height = 44;
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone &&
        UIInterfaceOrientationIsLandscape(orientation)) {
        height = 32;
    }
    
    CGRect screenBound = self.view.bounds;
    CGFloat screenWidth = screenBound.size.width;
    
    CGRect frame = CGRectMake(0, _naviBar.bounds.size.height-height, screenWidth, height);

    return frame;
}

- (CGRect)frameForDoneButtonAtOrientation:(UIInterfaceOrientation)orientation {
    CGRect screenBound = self.view.bounds;
    CGFloat screenWidth = screenBound.size.width;
    
    CGRect frame = CGRectMake(screenWidth - 15 - _doneButton.intrinsicContentSize.width, _counterLabel.center.y-15, _doneButton.intrinsicContentSize.width, 30);
    return frame;
}

- (CGPoint)contentOffsetForPageAtIndex:(NSUInteger)index {
    CGFloat pageWidth = _pagingScrollView.bounds.size.width;
    CGFloat newOffset = index * pageWidth;
    return CGPointMake(newOffset, 0);
}

- (CGRect)frameForPageAtIndex:(NSUInteger)index {
    // We have to use our paging scroll view's bounds, not frame, to calculate the page placement. When the device is in
    // landscape orientation, the frame will still be in portrait because the pagingScrollView is the root view controller's
    // view, so its frame is in window coordinate space, which is never rotated. Its bounds, however, will be in landscape
    // because it has a rotation transform applied.
    CGRect bounds = _pagingScrollView.bounds;
    CGRect pageFrame = bounds;
    pageFrame.size.width -= (2 * PADDING);
    pageFrame.origin.x = (bounds.size.width * index) + PADDING;
    return CGRectIntegral(pageFrame);
}

- (CGRect)frameForCaptionView:(LYCaptionView *)captionView atIndex:(NSUInteger)index {
    CGRect pageFrame = [self frameForPageAtIndex:index];
    
    CGSize captionSize = [captionView sizeThatFits:CGSizeMake(pageFrame.size.width, 0)];
    CGRect captionFrame = CGRectMake(pageFrame.origin.x, pageFrame.size.height - captionSize.height - (_toolbar.superview?_toolbar.frame.size.height:0), pageFrame.size.width, captionSize.height);
    
    return captionFrame;
}

- (CGRect)adjustForSafeArea:(CGRect)rect adjustForStatusBar:(BOOL)adjust {
    if (@available(iOS 11.0, *)) {
        return [self adjustRect:rect forSafeAreaInsets:self.view.safeAreaInsets forBounds:self.view.bounds adjustForStatusBar:adjust statusBarHeight:20];
//        return [self adjustForSafeArea:rect adjustForStatusBar:adjust forInsets:self.view.safeAreaInsets];
    }
    UIEdgeInsets insets = UIEdgeInsetsMake(_statusBarHeight, 0, 0, 0);
    return [self adjustRect:rect forSafeAreaInsets:insets forBounds:self.view.bounds adjustForStatusBar:adjust statusBarHeight:20];
//    return [self adjustForSafeArea:rect adjustForStatusBar:adjust forInsets:insets];
}

- (CGRect)adjustRect:(CGRect)rect forSafeAreaInsets:(UIEdgeInsets)insets forBounds:(CGRect)bounds adjustForStatusBar:(BOOL)adjust statusBarHeight:(int)statusBarHeight {
    BOOL isLeft = rect.origin.x <= insets.left;
    // If the safe area is not specified via insets we should fall back to the
    // status bar height
    CGFloat insetTop = insets.top > 0 ? insets.top : statusBarHeight;
    // Don't adjust for y positioning when adjustForStatusBar is false
    BOOL isAtTop = (rect.origin.y <= insetTop);
    BOOL isRight = rect.origin.x + rect.size.width >= bounds.size.width - insets.right;
    BOOL isAtBottom = rect.origin.y + rect.size.height >= bounds.size.height - insets.bottom;
    if ((isLeft) && (isRight)) {
        rect.origin.x += insets.left;
        rect.size.width -= insets.right + insets.left;
    } else if (isLeft) {
        rect.origin.x += insets.left;
    } else if (isRight) {
        rect.origin.x -= insets.right;
    }
    // if we're adjusting for status bar then we should move the view out of
    // the inset
    if ((adjust) && (isAtTop) && (isAtBottom)) {
        rect.origin.y += insetTop;
        rect.size.height -= insets.bottom + insetTop;
    } else if ((adjust) && (isAtTop)) {
        rect.origin.y += insetTop;
    } else if ((isAtTop) && (isAtBottom)) {
        rect.size.height -= insets.bottom;
    } else if (isAtBottom) {
        rect.origin.y -= insets.bottom;
    }
    return rect;
}

#pragma mark - Photo Loading Notification
- (void)handlePhotoLoadingDidEndNotification:(NSNotification *)notification {
    id <LYPhoto> photo = [notification object];
    LYZoomingScrollView *page = [self pageDisplayingPhoto:photo];
    if (page) {
        if ([photo underlyingImage]) {
            // Successful load
            [page displayImage];
            [self loadAdjacentPhotosIfNecessary:photo];
        } else {
            // Failed to load
            [page displayImageFailure];
        }
        // Update nav
//        [self updateNavigation];
    }
}

- (void)loadAdjacentPhotosIfNecessary:(id<LYPhoto>)photo {
    LYZoomingScrollView *page = [self pageDisplayingPhoto:photo];
    if (page) {
        // If page is current page then initiate loading of previous and next pages
        NSUInteger pageIndex = page.index;
        if (_currentPageIndex == pageIndex) {
            if (pageIndex > 0) {
                // Preload index - 1
                id <LYPhoto> photo = [self photoAtIndex:pageIndex-1];
                if (![photo underlyingImage]) {
                    [photo loadUnderlyingImageAndNotify];
                    LYLog(@"Pre-loading image at index %lu", (unsigned long)pageIndex-1);
                }
            }
            if (pageIndex < [self numberOfPhotos] - 1) {
                // Preload index + 1
                id <LYPhoto> photo = [self photoAtIndex:pageIndex+1];
                if (![photo underlyingImage]) {
                    [photo loadUnderlyingImageAndNotify];
                    LYLog(@"Pre-loading image at index %lu", (unsigned long)pageIndex+1);
                }
            }
        }
    }
}

#pragma mark - release
- (void)releaseAllUnderlyingPhotos {
    for (id p in _photos) { if (p != [NSNull null]) [p unloadUnderlyingImage]; } // Release photos
    for (id p in _thumbPhotos) { if (p != [NSNull null]) [p unloadUnderlyingImage]; }
}

- (void)dealloc {
    _pagingScrollView.delegate = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self releaseAllUnderlyingPhotos];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
