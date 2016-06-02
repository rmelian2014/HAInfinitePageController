//
//  HAInfinitePageViewController.h
//  Heeva
//
//  Created by Hashem on 4/3/16.
//  Copyright © 2016 FoodIran. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "HAInfinitePageViewControllerDelegate.h"

@class HAInfinitePageViewController;

@protocol HAInfinitePageViewControllerDataSource <NSObject>
@required
- (NSInteger)numberOfRows;
- (UIViewController *)infinitePageViewController:(HAInfinitePageViewController *)inifinitePageController controllerAtIndex:(NSInteger)index;
@end


@interface HAInfinitePageViewController : UIViewController
@property (assign, nonatomic) id<HAInfinitePageViewControllerDataSource> dataSource;
@property (assign, nonatomic) id<HAInfinitePageViewControllerDelegate> delegate;

- (void)moveToPage:(NSInteger)pageIndex forward:(BOOL)forward;
@end
