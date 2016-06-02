//
//  HATitleCell.h
//  Heeva
//
//  Created by Hashem on 3/12/16.
//  Copyright © 2016 FoodIran. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface HATitleCell : UICollectionViewCell

@property (strong, nonatomic) UIColor           *textColor;
@property (weak, nonatomic) IBOutlet UILabel    *titleLabel;

- (void)configureWithTitle:(NSString *)title textColor:(UIColor *)textColor;

- (CGSize)preferredLayoutSize;
- (void)setTextColor:(UIColor *)textColor;

@end
