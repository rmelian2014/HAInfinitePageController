//
//  HATitleCell.m
//  Heeva
//
//  Created by Hashem on 3/12/16.
//  Copyright © 2016 FoodIran. All rights reserved.
//

#import "HATitleCell.h"
#import "UIView+FrameHelper.h"

@interface HATitleCell ()


@end
@implementation HATitleCell

- (void)awakeFromNib
{
    [super awakeFromNib];
    self.contentView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
}
- (void)configureWithTitle:(NSString *)title textColor:(UIColor *)textColor
{
    self.titleLabel.text = title;
    self.titleLabel.textColor = textColor;
    [self.titleLabel sizeToFit];
    self.titleLabel.center = CGPointMake(self.width/2.0f, self.height/2.0f);
}

- (void)setTextColor:(UIColor *)textColor
{
    [UIView animateWithDuration:0.2 animations:^{
       self.titleLabel.textColor = textColor; 
    }];
}

- (CGSize)preferredLayoutSize
{
    [self setNeedsLayout];
    [self layoutIfNeeded];
    
    CGSize preferredSize = [self.contentView systemLayoutSizeFittingSize:UILayoutFittingCompressedSize];
    return preferredSize;
}

@end
