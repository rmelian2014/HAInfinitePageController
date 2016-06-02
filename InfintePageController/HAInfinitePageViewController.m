//
//  HAInfinitePageViewController.m
//  Heeva
//
//  Created by Hashem on 4/3/16.
//  Copyright © 2016 FoodIran. All rights reserved.
//

#import "HAInfinitePageViewController.h"

@interface HAInfinitePageViewController ()<UIPageViewControllerDataSource,UIPageViewControllerDelegate, UIScrollViewDelegate>
@property (nonatomic, strong) UIPageViewController *pageViewController;
@property (weak, nonatomic) UIScrollView           *pagesScrollView;
@property(nonatomic) NSMutableDictionary<NSNumber *, UIViewController *> *viewControllers;
@end

@implementation HAInfinitePageViewController
{
    BOOL isSwipeLocked;
    NSInteger selectedIndex;
}
- (void)viewDidLoad {
    [super viewDidLoad];
    _viewControllers = [NSMutableDictionary new];
    
    // Do any additional setup after loading the view.
}
- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self setupPageViewController];
}

- (void)setupPageViewController
{
    self.pageViewController = [[UIPageViewController alloc] initWithTransitionStyle:UIPageViewControllerTransitionStyleScroll navigationOrientation:UIPageViewControllerNavigationOrientationHorizontal options:nil];
    
    // delegate scrollview
    for (id subView in _pageViewController.view.subviews) {
        if ([subView isKindOfClass:[UIScrollView class]]) {
            self.pagesScrollView = subView;
            self.pagesScrollView.delegate = self;
            self.pagesScrollView.panGestureRecognizer.maximumNumberOfTouches = 1;
        }
    }

    
    self.pageViewController.dataSource = self;
    self.pageViewController.delegate = self;
    self.pageViewController.view.backgroundColor = [UIColor clearColor];
    [self.pageViewController.view setFrame:self.view.frame];

    [self addChildViewController:self.pageViewController];
    [self.view addSubview:self.pageViewController.view];
    [self.pageViewController didMoveToParentViewController:self];
    
    [self loadFirstViewController];
}

- (void)loadFirstViewController {
    // Load first view controller
    NSAssert(_dataSource, @"DataSource is nil");
    
    id viewController = _viewControllers[@(selectedIndex)];
    if (!viewController) {
        viewController =
        [self.dataSource infinitePageViewController:self controllerAtIndex:selectedIndex];
    }
    _viewControllers[@(selectedIndex)] = viewController;
    [self moveToViewController:viewController direction:UIPageViewControllerNavigationDirectionForward];
    
}

- (void)moveToViewController:(UIViewController *)targetVC direction:(UIPageViewControllerNavigationDirection)direction
{
    isSwipeLocked = YES;
    [self callDelegateForTargetIndex];
    
    id completionBlock = ^(BOOL finished) {
        [self callDelegateForCurrentIndex];
        isSwipeLocked = NO;
    };

    [_pageViewController setViewControllers:@[ targetVC ]
                                  direction:direction
                                   animated:YES
                                 completion:completionBlock];
}
#pragma mark - PageViewController data source

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController
       viewControllerAfterViewController:(UIViewController *)viewController {
    
    NSInteger index = selectedIndex + 1;
    UIViewController *nextViewController = _viewControllers[@(index)];
    if (!nextViewController) {
        NSInteger numberOfRows = [self.dataSource numberOfRows];
        if (index == numberOfRows) {
            index = 0;
        }
         nextViewController = [self.dataSource infinitePageViewController:self controllerAtIndex:index];
        
        _viewControllers[@(index)] = nextViewController;
    }
    
    return nextViewController;
}

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController
      viewControllerBeforeViewController:(UIViewController *)viewController {
    
    NSInteger index = selectedIndex - 1;
    UIViewController *nextViewController = _viewControllers[@(index)];
    if (!nextViewController) {
        if (index < 0) {
            NSInteger numberOfRows = [self.dataSource numberOfRows];
            index = numberOfRows-1;
        }
        nextViewController = [self.dataSource infinitePageViewController:self controllerAtIndex:index];
        
        _viewControllers[@(index)] = nextViewController;
        
    }
    
    return nextViewController;
}

#pragma mark - UIPageViewController Delegate Methods

- (void)pageViewController:(UIPageViewController *)pageViewController
        didFinishAnimating:(BOOL)finished
   previousViewControllers:(NSArray *)previousViewControllers
       transitionCompleted:(BOOL)completed {
    
    if (completed) {
        id currentView = pageViewController.viewControllers.firstObject;
        selectedIndex = [[_viewControllers allKeysForObject:currentView].firstObject integerValue];

        [self callDelegateForCurrentIndex];
    }
}

- (void)callDelegateForTargetIndex {
    if ([_delegate respondsToSelector:@selector(pageViewControllerWillMoveAtIndex:)]) {
        //NSInteger index = self.carbonSegmentedControl.selectedSegmentIndex;
        //[_delegate pageViewControllerWillMoveAtIndex:index];
    }
}

- (void)callDelegateForCurrentIndex {
    if ([_delegate respondsToSelector:@selector(pageViewControllerDidMoveAtIndex:)]) {
        //NSInteger index = self.carbonSegmentedControl.selectedSegmentIndex;
        [_delegate pageViewControllerDidMoveAtIndex:selectedIndex];
    }
}
#pragma mark - UIScrollView Delegate Methods

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    [self.delegate pageViewControllerWillBeginDragging:scrollView];
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    if (!decelerate) {
        [self.delegate pageViewControllerDidEndDragging:scrollView];
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    [self.delegate pageViewControllerDidEndDragging:scrollView];
}
- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    CGPoint offset = scrollView.contentOffset;
    CGFloat scrollViewWidth = CGRectGetWidth(scrollView.frame);
    CGFloat progress = 0.0;
    CGFloat newX = 0.0;
    
    newX = offset.x - scrollViewWidth;
    if (newX == 0) {
        return;
    }
    progress = (newX/scrollViewWidth);
    if (fabs(progress)>1) {
        NSLog(@"");
    }
    
    
    if (!isSwipeLocked) {
        [self.delegate pageViewControllerDidScroll:scrollView withProgress:progress];
    }
}

#pragma mark - HACategorySlider Delegate Methods
/*- (void)categorySlider:(HATitleSlider *)slider didSelectItemAtIndexPath:(NSIndexPath *)indexPath movingForward:(BOOL)movingForward
{
    if (indexPath.row != selectedIndex) {
        UIPageViewControllerNavigationDirection direction = movingForward ? UIPageViewControllerNavigationDirectionForward : UIPageViewControllerNavigationDirectionReverse;

        UIViewController *targetVC = [self.dataSource infinitePageViewController:self controllerAtIndex:indexPath.row];
        
        selectedIndex = indexPath.row;
        _viewControllers[@(selectedIndex)] = targetVC;
        [self moveToViewController:targetVC direction:direction];
    }
}

- (void)categorySliderWillScroll:(HATitleSlider *)slider
{
    self.pagesScrollView.userInteractionEnabled = NO;
}
- (void)categorySliderDidEndScrolling:(HATitleSlider *)slider
{
    self.pagesScrollView.userInteractionEnabled = YES;
}*/

- (void)moveToPage:(NSInteger)pageIndex forward:(BOOL)forward
{
    UIPageViewControllerNavigationDirection direction = forward ? UIPageViewControllerNavigationDirectionForward : UIPageViewControllerNavigationDirectionReverse;
    
    UIViewController *targetVC = [self.dataSource infinitePageViewController:self controllerAtIndex:pageIndex];
    
    selectedIndex = pageIndex;
    _viewControllers[@(selectedIndex)] = targetVC;
    [self moveToViewController:targetVC direction:direction];
}
@end
