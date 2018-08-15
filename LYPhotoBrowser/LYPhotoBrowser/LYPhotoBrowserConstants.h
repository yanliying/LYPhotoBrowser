//
//  LYPhotoBrowserConstants.h
//  LYPhotoBrowser
//
//  Created by yly on 2018/7/17.
//  Copyright © 2018年 yly. All rights reserved.
//

#define PADDING                 10

// Debug Logging
#if 1 // Set to 1 to enable debug logging
#define LYLog(x, ...) NSLog(x, ## __VA_ARGS__);
#else
#define LYLog(x, ...)
#endif
