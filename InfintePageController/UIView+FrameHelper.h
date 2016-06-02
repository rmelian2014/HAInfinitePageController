//
//  UIView+FrameHelper.h
//  SimPay
//
//  Created by Hashem Aboonajmi on 5/6/15.
//  Copyright (c) 2015 Hashem Aboonajmi. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIView (FrameHelper)

@property CGPoint position;
@property CGFloat x;
@property CGFloat y;
@property (readonly) CGFloat midX;
@property (readonly) CGFloat midY;
@property CGFloat top;
@property CGFloat bottom;
@property CGFloat left;
@property CGFloat right;

// Setting size keeps the position (top-left corner) constant
@property CGSize size;
@property CGFloat width;
@property CGFloat height;

@end
