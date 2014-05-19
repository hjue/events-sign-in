//
//  UIView+FindUIViewController.h
//  headline
//
//  Created by ZangChengwei on 14-4-16.
//  Copyright (c) 2014年 csdn_code. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIView (FindUIViewController)
- (UIViewController *) firstAvailableUIViewController;
- (id) traverseResponderChainForUIViewController;
@end
