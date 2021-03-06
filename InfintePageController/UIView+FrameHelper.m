//
//  UIView+FrameHelper.m
//  SimPay
//
//  Created by Hashem Aboonajmi on 5/6/15.
//  Copyright (c) 2015 Hashem Aboonajmi. All rights reserved.
//

#import "UIView+FrameHelper.h"

@implementation UIView (FrameHelper)

- (CGPoint)position {
    return self.frame.origin;
}
- (void)setPosition:(CGPoint)position {
    CGRect rect = self.frame;
    rect.origin = position;
    [self setFrame:rect];
}
- (CGFloat)x {
    return self.frame.origin.x;
}
- (void)setX:(CGFloat)x {
    CGRect rect = self.frame;
    rect.origin.x = x;
    [self setFrame:rect];
}
- (CGFloat)y {
    return self.frame.origin.y;
}
- (void)setY:(CGFloat)y {
    CGRect rect = self.frame;
    rect.origin.y = y;
    [self setFrame:rect];
}
- (CGFloat)midX {
    return self.x + CGRectGetWidth(self.frame)/2.0f;
}
- (CGFloat)midY {
    return self.y + CGRectGetHeight(self.frame)/2.0f;
}
- (CGFloat)left {
    return self.frame.origin.x;
}
- (void)setLeft:(CGFloat)x {
    CGRect frame = self.frame;
    frame.origin.x = x;
    self.frame = frame;
}
- (CGFloat)top {
    return self.frame.origin.y;
}
- (void)setTop:(CGFloat)y {
    CGRect frame = self.frame;
    frame.origin.y = y;
    self.frame = frame;
}
- (CGFloat)right {
    return self.frame.origin.x + self.frame.size.width;
}
- (void)setRight:(CGFloat)right {
    CGRect frame = self.frame;
    frame.origin.x = right - frame.size.width;
    self.frame = frame;
}
- (CGFloat)bottom {
    return self.frame.origin.y + self.frame.size.height;
}
- (void)setBottom:(CGFloat)bottom {
    CGRect frame = self.frame;
    frame.origin.y = bottom - frame.size.height;
    self.frame = frame;
}


#pragma mark Size
- (CGSize)size {
    return [self frame].size;
}
- (void)setSize:(CGSize)size {
    CGRect rect = self.frame;
    rect.size = size;
    [self setFrame:rect];
}
- (CGFloat)width {
    return self.frame.size.width;
}
- (void)setWidth:(CGFloat)width {
    CGRect rect = self.frame;
    rect.size.width = width;
    [self setFrame:rect];
}
- (CGFloat)height {
    return self.frame.size.height;
}
- (void)setHeight:(CGFloat)height {
    CGRect rect = self.frame;
    rect.size.height = height;
    [self setFrame:rect];
}

@end
