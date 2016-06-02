//
//  HAInfinitePageViewControllerDelegate.h
//  Heeva
//
//  Created by Hashem on 4/8/16.
//  Copyright © 2016 FoodIran. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol HAInfinitePageViewControllerDelegate <NSObject>
- (void)pageViewControllerWillMoveAtIndex:(NSInteger)index;
- (void)pageViewControllerDidMoveAtIndex:(NSInteger)index;
- (void)pageViewControllerWillBeginDragging:(UIScrollView *)scrollView;
- (void)pageViewControllerDidEndDragging:(UIScrollView *)scrollView;
- (void)pageViewControllerDidScroll:(UIScrollView *)scrollView withProgress:(CGFloat)progress;

@end
