//
//  ViewController.m
//  LYPhotoBrowser
//
//  Created by yly on 2018/7/17.
//  Copyright © 2018年 yly. All rights reserved.
//

#import "ViewController.h"
#import "LYPhotoBrowser.h"
#import <SDImageCache.h>

@interface ViewController ()<UITableViewDelegate, UITableViewDataSource, LYPhotoBrowserDelegate>

@property (nonatomic, strong) NSMutableArray *photos;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    self.title = @"LYPhotoBrowser";
    
    UITableView *tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height) style:UITableViewStylePlain];
    tableView.delegate = self;
    tableView.dataSource = self;
    [self.view addSubview:tableView];
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"清除缓存" style:UIBarButtonItemStylePlain target:self action:@selector(clearAllCaches)];
}

- (void)clearAllCaches {
    [[SDImageCache sharedImageCache] clearMemory];
    [[SDImageCache sharedImageCache] clearDiskOnCompletion:^{
        NSLog(@"done");
    }];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"UITableViewCell"];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"UITableViewCell"];
    }
    cell.textLabel.text = @"web resources";
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    NSMutableArray *photos = [NSMutableArray array];
    LYPhoto *photo;
    
    NSArray *urls = @[
                      @"http://img2.iartdream.com/ios/63204a59b6b1c5956b0fd917184140ef.jpeg",
                      @"http://img2.iartdream.com/ios/45c55585672dd60495b49b0a338315b5.jpeg?x-oss-process=image/resize,w_450",
                      @"http://img1.iartdream.com/ios/cf92454ec8f805264743636bcd6299a7.jpeg?x-oss-process=image/resize,m_fill,w_1080,h_1920",
                      @"http://img2.iartdream.com/ios/77ac3076117c4082eae165a8da49bd45.mp4",
                      @"http://img2.iartdream.com/ios/c7c9a6e5a7e288650f005333e5206901.jpeg",
                      @"http://img2.iartdream.com/ios/25abcf12885b053edc3ad0e82181076d.jpeg",
                      @"http://img2.iartdream.com/ios/uhinmzxkpxiyiahdw4ib5w==.mp4",
                      @"http://img2.iartdream.com/ios/b5c6be617e10341b3992284ad2fac20f.png",
                      @"http://img2.iartdream.com/ios/7a97a242532b81894ae0225984239a88.jpeg",
                      @"http://img2.iartdream.com/ios/d2edd5b2e161b067574c260ec6d017ef.gif"
                      ];
    NSArray *captions = @[
                      @"http://img2.iartdream.com/ios/63204a59b6b1c5956b0fd917184140ef.jpeg",
                      @"http://img2.iartdream.com/ios/45c55585672dd60495b49b0a338315b5.jpeg?x-oss-process=image/resize,w_450",
                      @"",
                      @"http://img2.iartdream.com/ios/77ac3076117c4082eae165a8da49bd45.mp4",
                      @"http://img2.iartdream.com/ios/c7c9a6e5a7e288650f005333e5206901.jpeg",
                      @"http://img2.iartdream.com/ios/25abcf12885b053edc3ad0e82181076d.jpeg",
                      @"http://img2.iartdream.com/ios/uhinmzxkpxiyiahdw4ib5w==.mp4",
                      @"/b5c6be617e10341b3992284ad2fac20f.png",
                      @"http://img2.iartdream.com/ios/7a97a242532b81894ae0225984239a88.jpeg罗中立的《父亲》以创造性的思维和深刻的内涵不仅震动了美术界，也波及于社会，并引起了一场关于形象的真实性和典型性、形式与审美的讨论。画家借鉴照相写实主义的手法，尽精刻微地塑造了一位典型的农民形象。老人枯黑的脸上满是皱纹，鼻旁长着“苦命痣”，干裂的嘴唇，只剩下了一颗牙，已经破伤的双手捧着一个旧瓷碗。这一切是那样的真实而清晰地展现在人们面前，强烈地冲击着观众的视觉，震撼着人们的心灵——这就是我们的父亲！",
                      @"http://img2.iartdream.com/ios/d2edd5b2e161b067574c260ec6d017ef.gif"
                      ];
    for (NSInteger i = 0; i < urls.count; i++) {
        NSString *url = urls[i];
        if ([url hasSuffix:@".mp4"]) {
            photo = [LYPhoto photoWithURL:[NSURL URLWithString:[url stringByAppendingString:@"?x-oss-process=video/snapshot,t_00000,m_fast"]]];
            photo.videoURL = [NSURL URLWithString:url];
        }else {
            photo = [LYPhoto photoWithURL:[NSURL URLWithString:url]];
        }
        photo.caption = captions[i];
        
        [photos addObject:photo];
    }
    self.photos = photos;
    
    LYPhotoBrowser *browser = [[LYPhotoBrowser alloc] initWithDelegate:self];
    [browser setCurrentPhotoIndex:1];
//    [self.navigationController pushViewController:browser animated:YES];
//    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:browser];
    [self presentViewController:browser animated:YES completion:nil];
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - LYPhotoBrowserDelegate
- (NSUInteger)numberOfPhotosInPhotoBrowser:(LYPhotoBrowser *)photoBrowser {
    return self.photos.count;
}

- (id<LYPhoto>)photoBrowser:(LYPhotoBrowser *)photoBrowser photoAtIndex:(NSUInteger)index {
    if (index < _photos.count) return [_photos objectAtIndex:index];
    return nil;
}

- (UIView *)photoBrowser:(LYPhotoBrowser *)photoBrowser toolbarForPhotoAtIndex:(NSUInteger)index {
    return [[UIToolbar alloc] init];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
