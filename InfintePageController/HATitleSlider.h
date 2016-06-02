//
//  HATitleSlider.h
//  Heeva
//
//  Created by Hashem on 4/4/16.
//  Copyright © 2016 FoodIran. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "HAInfinitePageViewControllerDelegate.h"

typedef enum
{
    HAScrollDirectionCrazy,
    HAScrollDirectionL2R,
    HAScrollDirectionR2L
}HAScrollDirection;

@class HATitleSlider;
@protocol HATitleSliderDelegate <NSObject>

- (void)categorySliderWillScroll:(HATitleSlider *)slider;
- (void)categorySliderDidEndScrolling:(HATitleSlider *)slider;
- (void)categorySlider:(HATitleSlider *)slider didSelectItemAtIndexPath:(NSIndexPath *)indexPath movingForward:(BOOL)movingForward;
- (void)categorySlider:(HATitleSlider *)slider didMoveToIndex:(NSInteger)index;
@end
@interface HATitleSlider : UIView <HAInfinitePageViewControllerDelegate>

@property (weak, nonatomic) id<HATitleSliderDelegate> delegate;
@property (strong, nonatomic) NSArray          *titles;
@property (strong, nonatomic) UIColor *notCenterButtonTextColor;
@property (strong, nonatomic) UIColor *centerButtonTextColor;
@property (strong, nonatomic) UIColor *notCenterButtonBackgroundColor;
@property (strong, nonatomic) UIColor *centerButtonBackgroundColor;

@end
