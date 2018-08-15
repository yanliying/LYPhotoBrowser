//
//  LYCaptionView.m
//  LYPhotoBrowser
//
//  Created by yly on 2018/7/23.
//  Copyright © 2018年 yly. All rights reserved.
//

#import "LYCaptionView.h"

static const CGFloat labelPadding = 10;

@interface LYCaptionView ()
{
    id <LYPhoto> _photo;
    UILabel *_label;
}

@end

@implementation LYCaptionView

- (id)initWithPhoto:(id<LYPhoto>)photo {
    CGRect screenBound = [[UIScreen mainScreen] bounds];
    CGFloat screenWidth = screenBound.size.width;
    
    if ([[UIDevice currentDevice] orientation] == UIDeviceOrientationLandscapeLeft ||
        [[UIDevice currentDevice] orientation] == UIDeviceOrientationLandscapeRight) {
        screenWidth = screenBound.size.height;
    }
    
    self = [super initWithFrame:CGRectMake(0, 0, screenWidth, 44)]; // Random initial frame
    if (self) {
        _photo = photo;
        self.opaque = NO;
        
        [self setBackground];
        
        [self setupCaption];
    }
    
    return self;
}

- (void)setBackground {
    UIView *fadeView = [[UIView alloc] initWithFrame:CGRectMake(0, -100, 10000, 123+100)]; // Static width, autoresizingMask is not working
    CAGradientLayer *gradient = [CAGradientLayer layer];
    gradient.frame = fadeView.bounds;
    gradient.colors = [NSArray arrayWithObjects:(id)[[UIColor colorWithWhite:0 alpha:0.0] CGColor], (id)[[UIColor colorWithWhite:0 alpha:0.8] CGColor], nil];
    [fadeView.layer insertSublayer:gradient atIndex:0];
    fadeView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight; //UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleTopMargin|UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleRightMargin;
    [self addSubview:fadeView];
}

- (void)setupCaption {
    _label = [[UILabel alloc] initWithFrame:CGRectMake(labelPadding, 0, self.bounds.size.width-labelPadding*2, self.bounds.size.height)];
    _label.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
    _label.opaque = NO;
    _label.backgroundColor = [UIColor clearColor];
    _label.textAlignment = NSTextAlignmentCenter;
    _label.lineBreakMode = NSLineBreakByWordWrapping;
    _label.numberOfLines = 5;
    _label.textColor = [UIColor whiteColor];
    _label.shadowColor = [UIColor colorWithWhite:0 alpha:0.5];
    _label.shadowOffset = CGSizeMake(0, 1);
    _label.font = [UIFont systemFontOfSize:17];
    if ([_photo respondsToSelector:@selector(caption)]) {
        _label.text = [_photo caption] ? [_photo caption] : @" ";
    }
    
    [self addSubview:_label];
}

- (CGSize)sizeThatFits:(CGSize)size {
    if (_label.text.length == 0) return CGSizeZero;
    
    CGFloat maxHeight = 9999;
    if (_label.numberOfLines > 0) maxHeight = _label.font.leading*_label.numberOfLines;
    
    CGFloat width = size.width - labelPadding*2;
    
    CGFloat height = [_label sizeThatFits:CGSizeMake(width, CGFLOAT_MAX)].height;
    return CGSizeMake(size.width, height + labelPadding * 2);
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
