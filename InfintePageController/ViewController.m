//
//  ViewController.m
//  InfintePageController
//
//  Created by Hashem on 6/2/16.
//  Copyright © 2016 FoodIran. All rights reserved.
//

#import "ViewController.h"
#import "ItemViewController.h"
#import "HAInfinitePageViewController.h"

// view
#import "HATitleSlider.h"


@interface ViewController ()<HAInfinitePageViewControllerDataSource,HATitleSliderDelegate>
@property (weak, nonatomic) IBOutlet HATitleSlider      *categorySlider;
@property (strong, nonatomic) HAInfinitePageViewController  *pageViewController;
@property (strong, nonatomic) NSMutableArray            *viewControllerArray;
@property (strong, nonatomic) NSArray                   *titles;
@property (strong, nonatomic) ItemViewController   *currentViewController;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    _viewControllerArray = [NSMutableArray new];
    _titles = [NSArray arrayWithObjects:@"Breakfast",@"Paninis",@"Salads",@"Beverages",@"Bagels", nil];
    // HACategorySlider
    self.categorySlider.titles = self.titles;
    self.categorySlider.delegate = self;
    [self setupCircularView];
}

- (void)setupCircularView
{
    _viewControllerArray = [NSMutableArray new];
    for (int i=0; i<self.titles.count; i++) {
        [_viewControllerArray addObject:[NSNull null]];
    }
    _pageViewController = (HAInfinitePageViewController *)self.childViewControllers[0];
    [_pageViewController setDataSource:self];
    [_pageViewController setDelegate:self.categorySlider];
    self.categorySlider.delegate = self;
}


#pragma mark - HAInfinitePageViewController dataSource methods
- (NSInteger)numberOfRows
{
    return self.titles.count;
}
- (UIViewController *)infinitePageViewController:(HAInfinitePageViewController *)inifinitePageController controllerAtIndex:(NSInteger)index
{
    if (self.viewControllerArray.count>0) {
        if (index >= self.viewControllerArray.count || index < 0) return nil;
        
        ItemViewController *menuVC = [self.viewControllerArray objectAtIndex:index];
        if ([menuVC isKindOfClass:[NSNull class]]) {
            ItemViewController *menuVC = [self.storyboard instantiateViewControllerWithIdentifier:@"ItemViewController"];
            
            menuVC.titleLable.text = self.titles[index];
            [self.viewControllerArray replaceObjectAtIndex:index withObject:menuVC];
            
            [self addChildViewController:menuVC];
            [menuVC didMoveToParentViewController:self];
            
            return menuVC;
        }
        // in case of update in branch category
        menuVC.titleLable.text = self.titles[index];
        return menuVC;
        
    }
    
    return nil;
    
}

#pragma mark HACategorySlider Delegate Methods
- (void)categorySlider:(HATitleSlider *)slider didSelectItemAtIndexPath:(NSIndexPath *)indexPath movingForward:(BOOL)movingForward
{
    [self.pageViewController moveToPage:indexPath.row forward:movingForward];
}

- (void)categorySlider:(HATitleSlider *)slider didMoveToIndex:(NSInteger)index
{
    self.currentViewController = self.viewControllerArray[index];
}
- (void)categorySliderWillScroll:(HATitleSlider *)slider
{
    self.pageViewController.view.userInteractionEnabled = NO;
}
- (void)categorySliderDidEndScrolling:(HATitleSlider *)slider
{
    self.pageViewController.view.userInteractionEnabled = YES;
}

@end
