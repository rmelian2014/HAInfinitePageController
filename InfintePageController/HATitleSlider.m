//
//  HATitleSlider.m
//  Heeva
//
//  Created by Hashem on 4/4/16.
//  Copyright © 2016 FoodIran. All rights reserved.
//

#import "HATitleSlider.h"
#import "HATitleCell.h"
#import "UIView+FrameHelper.h"

static const CGFloat kIndicatorHeight = 3;
@interface HATitleSlider () <UICollectionViewDelegate, UICollectionViewDataSource>

@property (strong, nonatomic) UICollectionView  *collectionView;
@property (assign, nonatomic) BOOL              movingForward;
//@property (strong, nonatomic) NSMutableArray   *cellWidths; // contains width of cells with their corresponding indexPath.
@property (assign, nonatomic) CGFloat          totalCellWidths; // total section width, includes inset between section
@property (assign, nonatomic) HAScrollDirection scrollDirection;
@property (strong, nonatomic) UIView            *indicatorLine;
@property (strong, nonatomic) NSIndexPath       *selectedIndexPath;
@property (strong, nonatomic) NSIndexPath       *centeredCellIndexPath;
@property (strong, nonatomic) NSIndexPath       *previousCenteredCellIndexPath;
@end
@implementation HATitleSlider
{
    
    BOOL cellSizesCalculated;
    BOOL initiallyLayoutedSubviews;
    BOOL didSelectCell;
    BOOL jumped;
    BOOL swipeIsLocked;
    CGFloat startingOffset;
    CGFloat previousOffset;
}
- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super initWithCoder:aDecoder]) {
        [self commonSetup];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        [self commonSetup];
    }
    return self;
}

- (void)commonSetup
{
    _previousCenteredCellIndexPath = _centeredCellIndexPath = _selectedIndexPath = [NSIndexPath indexPathForRow:0 inSection:1];
    
    self.notCenterButtonTextColor = [UIColor lightGrayColor];
    self.centerButtonTextColor = [UIColor orangeColor];
    //_cellWidths = [NSMutableArray new];
    _indicatorLine = [UIView new];
    _indicatorLine.frame = CGRectMake(0, 0, 50, kIndicatorHeight);
    _indicatorLine.backgroundColor = self.centerButtonTextColor;
    _indicatorLine.layer.cornerRadius = _indicatorLine.height/2.0f;
    _indicatorLine.alpha = 0;
    
    [self setupCollectionView]
    ;
    [self addSubview:self.collectionView];
    [self addSubview:self.indicatorLine];
    
}

- (void)setupCollectionView
{
    UICollectionViewFlowLayout *horizontalLayout = [UICollectionViewFlowLayout new];
    horizontalLayout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
    horizontalLayout.minimumLineSpacing = 0.0f;
    horizontalLayout.minimumInteritemSpacing = 0;
    //horizontalLayout.sectionInset = UIEdgeInsetsMake(-20, 0, 0, 0);
    
    _collectionView = [[UICollectionView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth([UIScreen mainScreen].bounds), 57) collectionViewLayout:horizontalLayout];
    [_collectionView registerNib:[UINib nibWithNibName:@"HATitleCell" bundle:nil] forCellWithReuseIdentifier:@"cell"];
    _collectionView.delegate = self;
    _collectionView.dataSource = self;
    
    _collectionView.backgroundColor = [UIColor clearColor];
    _collectionView.decelerationRate = UIScrollViewDecelerationRateFast;
    _collectionView.clipsToBounds = NO;
    
    [_collectionView setShowsHorizontalScrollIndicator:NO];
    [_collectionView setShowsVerticalScrollIndicator:NO];
    
    [_collectionView addObserver:self forKeyPath:@"contentSize" options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld context:NULL];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context
{
    if ([keyPath isEqualToString:@"contentSize"]) {
        CGSize newContentSize = [[change valueForKey:@"new"] CGSizeValue];
        CGSize oldContentSize = [[change valueForKey:@"old"] CGSizeValue];
        if (newContentSize.width>2*self.width && newContentSize.width != oldContentSize.width) {
            self.totalCellWidths = self.collectionView.contentSize.width/self.collectionView.numberOfSections;
            // scrolling to the middle item

            [self.collectionView scrollToItemAtIndexPath:self.selectedIndexPath atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally animated:NO];
        }
    }
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    if (!initiallyLayoutedSubviews) {
        
        NSIndexPath *firstItemIndexPath = [NSIndexPath indexPathForRow:0 inSection:1];
        [self setSelectedIndexPath:firstItemIndexPath];
        [self setCenteredCellIndexPath:firstItemIndexPath];
        
        HATitleCell *firstCell = (HATitleCell *)[self.collectionView cellForItemAtIndexPath:firstItemIndexPath];
        CGFloat currentCellTextSize = [firstCell.titleLabel.text
                                      boundingRectWithSize:firstCell.titleLabel.size
                                      options:NSStringDrawingUsesLineFragmentOrigin
                                      attributes:@{
                                                   NSFontAttributeName :
                                                       firstCell.titleLabel.font
                                                   }
                                      context:nil].size.width;
        
        _indicatorLine.width = currentCellTextSize;
        // update indicator center
        // I have added it here because this where view frame has measured correctly
        _indicatorLine.center = CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMaxY(self.bounds)-2);
        _indicatorLine.alpha = 1;
        
        initiallyLayoutedSubviews = YES;
    }
}

#pragma mark - Custom Setters
- (void)setTitles:(NSArray *)titles
{
    NSArray *oldTitles = _titles;
    NSArray *newTitles = titles;
    __block BOOL equal = YES;
    [newTitles enumerateObjectsUsingBlock:^(NSString *newTitle, NSUInteger idx, BOOL * _Nonnull stop) {
        if(![oldTitles[idx] isEqualToString:newTitle])
        {
            equal = NO;
            *stop = YES;
        }
    }];
    if (oldTitles.count != newTitles.count) {
        equal = NO;
    }
    // we do this checking because reloading ASCollectionView cause flicker
    if (equal == NO) {
        _titles = titles;
        [self.collectionView performBatchUpdates:^{
            [self.collectionView reloadData];
        } completion:^(BOOL finished) {
            // reselect center cell to selected cell will be colored
            //[self setCenteredCellIndex:self.centeredCellIndex];
        }];
    }
}

- (void)setSelectedIndexPath:(NSIndexPath *)selectedIndexPath
{
    NSLog(@"selected section:%ld, index:%ld",selectedIndexPath.section, selectedIndexPath.row);
    _selectedIndexPath = selectedIndexPath;
}
- (void)setCenteredCellIndexPath:(NSIndexPath *)centeredCellIndexPath
{

    // moving backward after partially moving to the next indexPath
    if (centeredCellIndexPath.row == self.previousCenteredCellIndexPath.row) {

        
        HATitleCell *previousSelectedCell = (HATitleCell *)[self.collectionView cellForItemAtIndexPath:_centeredCellIndexPath];
        [previousSelectedCell setTextColor:self.notCenterButtonTextColor];
        
        HATitleCell *newSelectedCell = (HATitleCell *)[self.collectionView cellForItemAtIndexPath:centeredCellIndexPath];
        if (!newSelectedCell) {
            [self.collectionView layoutIfNeeded];
            newSelectedCell = (HATitleCell *)[self.collectionView cellForItemAtIndexPath:centeredCellIndexPath];
        }
        [newSelectedCell setTextColor:self.centerButtonTextColor];
         _centeredCellIndexPath = centeredCellIndexPath;
        //NSLog(@"Centered- Section:%ld, index:%ld",_centeredCellIndexPath.section, _centeredCellIndexPath.row);
    }
    else if (centeredCellIndexPath.row != _centeredCellIndexPath.row || centeredCellIndexPath.section != _centeredCellIndexPath.section) {
        
        self.previousCenteredCellIndexPath  = _centeredCellIndexPath;
        _centeredCellIndexPath = centeredCellIndexPath;
        
        HATitleCell *previousSelectedCell = (HATitleCell *)[self.collectionView cellForItemAtIndexPath:self.previousCenteredCellIndexPath];
        [previousSelectedCell setTextColor:self.notCenterButtonTextColor];
        
        HATitleCell *newSelectedCell = (HATitleCell *)[self.collectionView cellForItemAtIndexPath:centeredCellIndexPath];
        if (!newSelectedCell) {
            [self.collectionView layoutIfNeeded];
            newSelectedCell = (HATitleCell *)[self.collectionView cellForItemAtIndexPath:centeredCellIndexPath];
        }
        [newSelectedCell setTextColor:self.centerButtonTextColor];
        //NSLog(@"Centered- Section:%ld, index:%ld",_centeredCellIndexPath.section, _centeredCellIndexPath.row);
    }
}
#pragma mark - UICollectionViewDataSource
- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 3;
}
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return self.titles.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    HATitleCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"cell" forIndexPath:indexPath];
    [cell configureWithTitle:self.titles[indexPath.row] textColor:self.notCenterButtonTextColor];
    cell.backgroundColor = [UIColor clearColor];
    /*if (indexPath.section == 0) {
        cell.backgroundColor = [UIColor blackColor];
    }else if (indexPath.section == 2)
    {
        cell.backgroundColor = [UIColor lightGrayColor];
    }*/
    
    return cell;
}

#pragma mark UICollectionViewDelegateFlowLayout
- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    CGFloat width = [self widthForBasicCellAtIndexPath:indexPath];
    return CGSizeMake(width, 57);
}

- (CGFloat)widthForBasicCellAtIndexPath:(NSIndexPath *)indexPath {
    static HATitleCell *sizingCell = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sizingCell = (HATitleCell *)[[[NSBundle mainBundle] loadNibNamed:@"HATitleCell" owner:self options:nil] objectAtIndex:0];
    });
    
    [sizingCell configureWithTitle:self.titles[indexPath.row] textColor:[UIColor cyanColor]];
    
    CGFloat width = [self calculateWidthForConfiguredSizingCell:sizingCell];
    
    return width;
}

- (CGFloat)calculateWidthForConfiguredSizingCell:(HATitleCell *)sizingCell {
    
    CGSize size = [sizingCell preferredLayoutSize];
    
    return size.width;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    if(indexPath != self.selectedIndexPath)
    {
        didSelectCell = YES;
        // we don't want user continusely select next cell
        self.userInteractionEnabled = NO;
        self.centeredCellIndexPath = indexPath;
        UICollectionViewCell *selectedCell = [self.collectionView cellForItemAtIndexPath:indexPath];
        // center align the selected cell
        CGPoint centerPoint = CGPointMake(self.collectionView.contentOffset.x+self.collectionView.midX, 0);
        CGFloat offsetAdjustment;
        CGFloat horizontalCenter = centerPoint.x;
        CGFloat centeredCellMidX = selectedCell.midX;
        offsetAdjustment = ABS(centeredCellMidX - horizontalCenter);
        
        CGPoint targetOffset;
        // if centeredCell is at the right side of mid point
        if (centeredCellMidX > horizontalCenter) {
            // we scroll to the right
            targetOffset = CGPointMake(self.collectionView.contentOffset.x + offsetAdjustment, 0);
            
        }
        else
        {
            targetOffset = CGPointMake(self.collectionView.contentOffset.x - offsetAdjustment, 0);
            
        }
        
        // call delegate
        BOOL movingForward = NO;
        if (selectedCell.midX>centerPoint.x)
        {
            movingForward = YES;
        }
        if ([self.delegate respondsToSelector:@selector(categorySlider:didSelectItemAtIndexPath:movingForward:)]) {
            //[self updateSelectedIndexPath:indexPath];
            [self.delegate categorySlider:self didSelectItemAtIndexPath:indexPath movingForward:movingForward];
        }
        [self.collectionView setContentOffset:targetOffset animated:YES];
    }
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    static CGFloat lastContentOffsetX = FLT_MIN;
    // We can ignore the first time scroll,
    // because it is caused by the call scrollToItemAtIndexPath: in ViewWillAppear
    if (FLT_MIN == lastContentOffsetX) {
        lastContentOffsetX = scrollView.contentOffset.x;
        return;
    }
    
    if (swipeIsLocked == NO) {
        if (previousOffset == 0) {
            previousOffset = self.collectionView.contentOffset.x;
        }
        
        NSIndexPath *targetIndexPath;
        
        if (jumped) {
            [self.collectionView layoutIfNeeded];
            jumped = NO;
        }
        CGPoint centerPoint = CGPointMake(self.collectionView.contentOffset.x + self.width/2.0f, self.height/2.0f);
        // selected cell is not necessary the highlighted cell, when we completly moved to the next page
        UICollectionViewCell *selectedCell = [self.collectionView cellForItemAtIndexPath:self.selectedIndexPath];
        UICollectionViewCell *targetCell;
        
        if (selectedCell.midX>centerPoint.x) {
            // we are moving back
            targetIndexPath = [self indexPathBeforeIndexPath:self.selectedIndexPath];
            targetCell = [self.collectionView cellForItemAtIndexPath:targetIndexPath];
            
            if ( ceilf(targetCell.midX)>=ceilf(centerPoint.x)) {
                // selected indexPath should change
                self.selectedIndexPath = targetIndexPath;
                // so we update selected cell and target cell base on new indexPath
                selectedCell = [self.collectionView cellForItemAtIndexPath:self.selectedIndexPath];
                // indexPath before targetIndexPath
                targetIndexPath = [self indexPathBeforeIndexPath:self.selectedIndexPath];
            }
        }
        else if (selectedCell.midX<centerPoint.x)
        {
            // we are moving forward
            targetIndexPath = [self indexPathAfterIndexPath:self.selectedIndexPath];
            targetCell = [self.collectionView cellForItemAtIndexPath:targetIndexPath];
            // targetCell is positioned in selectedCell, means we swiped for one page
            if ( (int)targetCell.midX<=(int)centerPoint.x) {
                // selected indexPath should changed
                self.selectedIndexPath = targetIndexPath;
                // so we update selected cell and target cell base on new indexPath
                selectedCell = [self.collectionView cellForItemAtIndexPath:self.selectedIndexPath];
                targetIndexPath = [self indexPathAfterIndexPath:targetIndexPath];
            }
        }
        
        CGFloat distance = (selectedCell.width + targetCell.width)/2.0f;
        CGFloat newX = centerPoint.x - selectedCell.midX;
        NSLog(@"%f", newX);
        CGFloat progress = newX/distance;
        CGFloat progressPercentage = progress * 100;
        if ((int)progressPercentage > 0) {
            self.movingForward = YES;
        }
        else if ((int)progressPercentage < 0)
        {
            self.movingForward = NO;
        }
        //NSLog(@"p:%f",progress);
        if (selectedCell && targetCell) {
            [self updateIndicatorLineWidthBasedOnCurrentCell:(HATitleCell *)selectedCell targetCell:(HATitleCell *)targetCell progress:progress];
            
        }
    }
    
    else
    {
        //[self updateSelectedIndexPath:self.selectedIndexPath];
    }
    
    if (scrollView.contentOffset.x<(self.totalCellWidths - scrollView.width))
    {
        [self jumpFromLeftToRight:scrollView];
    }
    else if (scrollView.contentOffset.x>2*self.totalCellWidths)
    {
        [self jumpFromRighToLeft:scrollView];
    }
}
// this is called when we change content offset animated
- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView
{
    self.userInteractionEnabled = YES;
    didSelectCell = NO;
}
- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView withVelocity:(CGPoint)velocity targetContentOffset:(inout CGPoint *)targetContentOffset
{
    CGPoint targetOffset = [self targetContentOffsetForFinalOffset:*targetContentOffset];
    *targetContentOffset = targetOffset;
}

- (CGPoint)targetContentOffsetForFinalOffset:(CGPoint)finalOffset
{
    UICollectionViewFlowLayout *horizontalLayout = (UICollectionViewFlowLayout *)self.collectionView.collectionViewLayout;
    
    CGRect targetRect = CGRectMake(finalOffset.x, 0, self.width, self.height);
    NSArray *inBoundCellsAttributes = [horizontalLayout layoutAttributesForElementsInRect:targetRect];
    
    CGFloat targetRectMidX = CGRectGetMidX(targetRect);
    
    CGFloat offsetAdjustment = CGFLOAT_MAX;
    CGFloat horizontalCenter = targetRectMidX;
    
    for (UICollectionViewLayoutAttributes *attributes in inBoundCellsAttributes) {
        CGRect segmentRect = attributes.frame;
        CGFloat distanceFromCenter = CGRectGetMidX(segmentRect) - horizontalCenter;
        if (ABS(distanceFromCenter) < ABS(offsetAdjustment)) {
            offsetAdjustment = distanceFromCenter;
        }
    }

    //resulted content offset should not be out of collectionView contentsize bounds
    CGPoint targetContentOffset;
    if (finalOffset.x + offsetAdjustment < 0) {
        targetContentOffset = CGPointMake(0,
                                           finalOffset.y);
    } else {
        targetContentOffset = CGPointMake(finalOffset.x + offsetAdjustment, finalOffset.y);
    }

    return targetContentOffset;
}
- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    [self.delegate categorySliderWillScroll:self];
}
- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
    if (!decelerate) {
        [self scrollViewDidRest];
    }
}
- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    [self scrollViewDidRest];
}

- (void)scrollViewDidRest
{
    [self.delegate categorySliderDidEndScrolling:self];
    CGPoint centerPoint = CGPointMake(self.collectionView.contentOffset.x + self.width/2.0f, self.height/2.0f);
    NSIndexPath *newCenteredCellIndexPath = [self.collectionView indexPathForItemAtPoint:centerPoint];
    [self updateSelectedIndexPath:newCenteredCellIndexPath];
    [self.delegate categorySlider:self didSelectItemAtIndexPath:self.selectedIndexPath movingForward:self.movingForward];
    
    CGPoint targetOffset = [self targetContentOffsetForFinalOffset:self.collectionView.contentOffset];
    [self.collectionView setContentOffset:targetOffset animated:YES];
}

- (void)jumpFromLeftToRight:(UIScrollView *)scrollView
{
    startingOffset = 0;
    jumped = YES;
    self.selectedIndexPath = [NSIndexPath indexPathForRow:self.selectedIndexPath.row inSection:1];
    self.previousCenteredCellIndexPath = [NSIndexPath indexPathForRow:self.previousCenteredCellIndexPath.row inSection:1];
    
    CGFloat targetOffsetX = 2*self.totalCellWidths - scrollView.width;
    scrollView.contentOffset = CGPointMake(targetOffsetX, 0);

    if (didSelectCell) {
        self.centeredCellIndexPath = [NSIndexPath indexPathForRow:self.centeredCellIndexPath.row inSection:1];
    }
}

- (void)jumpFromRighToLeft:(UIScrollView *)scrollView
{
    startingOffset = 0;
    jumped = YES;
    self.selectedIndexPath = [NSIndexPath indexPathForRow:self.selectedIndexPath.row inSection:1];
    self.previousCenteredCellIndexPath = [NSIndexPath indexPathForRow:self.centeredCellIndexPath.row inSection:1];
    
    CGFloat targetOffsetX = self.totalCellWidths;
    scrollView.contentOffset = CGPointMake(targetOffsetX, 0);

    if (didSelectCell) {
        self.centeredCellIndexPath = [NSIndexPath indexPathForRow:self.centeredCellIndexPath.row inSection:1];
    }
}
- (NSIndexPath *)indexPathBeforeIndexPath:(NSIndexPath *)indexPath
{
    NSInteger currentSection = self.selectedIndexPath.section;
    NSInteger backIndex = self.selectedIndexPath.row;
    NSInteger backSection = self.selectedIndexPath.section;
    if (--backIndex<0) {
        backIndex = [self.collectionView numberOfItemsInSection:0]-1;
        backSection = currentSection - 1;
        // back section should be 0 or 1
        backSection = backSection <0 ? 1 : backSection;
    }
    
    NSIndexPath *targetIndexPath = [NSIndexPath indexPathForRow:backIndex inSection:backSection];
    
    return targetIndexPath;
}
- (NSIndexPath *)indexPathAfterIndexPath:(NSIndexPath *)indexPath
{
    NSInteger currentSection = self.selectedIndexPath.section;
    NSInteger nextIndex = self.selectedIndexPath.row;
    NSInteger nextSection = currentSection;
    NSInteger totalSections = 2;
    NSInteger numberOfItems =[self.collectionView numberOfItemsInSection:0];
    if (++nextIndex>=numberOfItems) {
        nextIndex = 0;
        nextSection = currentSection +1;
        // nextSection should not be more than total sections
        nextSection = nextSection > totalSections ? 1 : nextSection;
    }
    NSIndexPath *targetIndexPath = [NSIndexPath indexPathForRow:nextIndex inSection:nextSection];
    return targetIndexPath;
}
/*- (NSIndexPath *)centerCellIndexPathInScrollView:(UIScrollView *)scrollView targetOffsetX:(CGFloat)targetOffsetX
{
    CGPoint targetRectMidX = CGPointMake(targetOffsetX +scrollView.width/2.0f, 0);
    return [self.collectionView indexPathForItemAtPoint:targetRectMidX];
}*/
#pragma mark - HAInfintePageViewController Delegate
- (void)pageViewControllerWillMoveAtIndex:(NSInteger)index
{
    
}
- (void)pageViewControllerDidMoveAtIndex:(NSInteger)targetIndex
{
    startingOffset = 0;
    
    NSInteger currentSection = self.selectedIndexPath.section;
    NSInteger currentIndex = self.selectedIndexPath.row;
    NSInteger numberOfRows = [self.collectionView numberOfItemsInSection:0];
    NSIndexPath *targetIndexPath;
    if (currentIndex == 0 && targetIndex == numberOfRows - 1) {
        if (currentSection == 1) {
            // moved from center section to left section
            targetIndexPath = [NSIndexPath indexPathForRow:targetIndex inSection:0];
        }
        else
            // moved from right section to center section
            targetIndexPath = [NSIndexPath indexPathForRow:targetIndex inSection:1];
        
    }
    else if (targetIndex == 0 && currentIndex == numberOfRows - 1)
    {
        if (currentSection == 1) {
            // moved from center section to right section
            targetIndexPath = [NSIndexPath indexPathForRow:targetIndex inSection:2];
        }
        else
            // moved from left section to center section
            targetIndexPath = [NSIndexPath indexPathForRow:targetIndex inSection:1];
    }
    else
        targetIndexPath = [NSIndexPath indexPathForRow:targetIndex inSection:currentSection];
    if (targetIndexPath.section == 0 &&targetIndexPath.row == 5) {
        NSLog(@"");
    }
    NSLog(@"moved: section:%ld , row:%ld",targetIndexPath.section, targetIndexPath.row);
    [self updateSelectedIndexPath:targetIndexPath];
    [self.delegate categorySlider:self didMoveToIndex:targetIndex];
    //if (pageControllerIsScrolling == NO) {
    // correct cell position, if it is not centered
    CGFloat targetOffset = [self targetContentOffsetForFinalOffset:self.collectionView.contentOffset].x;
    
    if (initiallyLayoutedSubviews) {
        [UIView animateWithDuration:0.2 animations:^{
            [self.collectionView setContentOffset:CGPointMake(targetOffset, 0) animated:YES];
        } completion:^(BOOL finished) {
            // [self updateSelectedIndexPath:targetIndexPath];
        }];
    }
    //}

}
- (void)pageViewControllerWillBeginDragging:(UIScrollView *)scrollView
{
    self.userInteractionEnabled = NO;
}
- (void)pageViewControllerDidEndDragging:(UIScrollView *)scrollView
{
    self.centeredCellIndexPath = self.selectedIndexPath;
    swipeIsLocked = NO;
    self.userInteractionEnabled = YES;
    startingOffset = 0;
}
- (void)pageViewControllerDidScroll:(UIScrollView *)scrollView withProgress:(CGFloat)progress
{
    swipeIsLocked = YES;
    
    NSIndexPath *targetIndexPath;
    
    UICollectionViewCell *currentCell = [self.collectionView cellForItemAtIndexPath:self.selectedIndexPath];
    NSInteger currentSection = self.selectedIndexPath.section;
    
    if (progress<0) {
        // we are moving back
        NSInteger backIndex = self.selectedIndexPath.row;
        NSInteger backSection = currentSection;
        if (--backIndex<0) {
            backIndex = [self.collectionView numberOfItemsInSection:0]-1;
            backSection = currentSection - 1;
        }
        
        targetIndexPath = [NSIndexPath indexPathForRow:backIndex inSection:backSection];
    }
    else {
        // we are moving forward
        NSInteger nextIndex = self.selectedIndexPath.row;
        NSInteger nextSection = currentSection;
        NSInteger numberOfItems =[self.collectionView numberOfItemsInSection:0];
        if (++nextIndex>=numberOfItems) {
            nextIndex = 0;
            nextSection = currentSection + 1;
        }
        targetIndexPath = [NSIndexPath indexPathForRow:nextIndex inSection:nextSection];
    }
    
    UICollectionViewCell *targetCell = [self.collectionView cellForItemAtIndexPath:targetIndexPath];
    if (!targetCell) {
        [self.collectionView layoutIfNeeded];
        targetCell = [self.collectionView cellForItemAtIndexPath:targetIndexPath];
    }
    if (!currentCell) {
        currentCell = [self.collectionView cellForItemAtIndexPath:targetIndexPath];
    }
    if (targetCell && currentCell) {
        [self updateIndicatorLineWidthBasedOnCurrentCell:(HATitleCell *)currentCell targetCell:(HATitleCell *)targetCell progress:progress];
    }
    
    // distance between center of two cells
    CGFloat distance = (targetCell.width/2.0f+currentCell.width/2.0f);
    CGFloat offsetToTravel = distance*progress;
    
    if (startingOffset == 0) {
        startingOffset = self.collectionView.contentOffset.x;
        if (jumped) {
            // moving backward
            
            startingOffset = startingOffset - offsetToTravel;
            jumped = NO;
        }
    }
    
    CGFloat targetOffset =  startingOffset + offsetToTravel;
    
    // update collectionView offset
    [self.collectionView setContentOffset:CGPointMake(targetOffset, 0)];
    
    if (ABS(progress) > 0.50) {
        self.centeredCellIndexPath = targetIndexPath;
    }
    else
    {
        self.centeredCellIndexPath = self.previousCenteredCellIndexPath;
    }

}
/*#pragma mark - HACircularSlider Delegate Methods
- (void)circularSliderWillBeginDragging:(HACircularSlider *)slider
{
    self.userInteractionEnabled = NO;
}

- (void)circularSliderDidEndDragging:(HACircularSlider *)slider
{
    self.centeredCellIndexPath = self.selectedIndexPath;
    swipeIsLocked = NO;
    self.userInteractionEnabled = YES;
    startingOffset = 0;
}

- (void)circularSliderDidScrollat:(CGPoint)visibleOffset progress:(CGFloat)progress
{
    swipeIsLocked = YES;

    NSIndexPath *targetIndexPath;

    UICollectionViewCell *currentCell = [self.collectionView cellForItemAtIndexPath:self.selectedIndexPath];
    NSInteger currentSection = self.selectedIndexPath.section;
    
    if (progress<0) {
        // we are moving back
        NSInteger backIndex = self.selectedIndexPath.row;
        NSInteger backSection = currentSection;
        if (--backIndex<0) {
            backIndex = [self.collectionView numberOfItemsInSection:0]-1;
            backSection = currentSection - 1;
        }
        
        targetIndexPath = [NSIndexPath indexPathForRow:backIndex inSection:backSection];
    }
    else {
        // we are moving forward
        NSInteger nextIndex = self.selectedIndexPath.row;
        NSInteger nextSection = currentSection;
        NSInteger numberOfItems =[self.collectionView numberOfItemsInSection:0];
        if (++nextIndex>=numberOfItems) {
            nextIndex = 0;
            nextSection = currentSection + 1;
        }
        targetIndexPath = [NSIndexPath indexPathForRow:nextIndex inSection:nextSection];
    }
    
    UICollectionViewCell *targetCell = [self.collectionView cellForItemAtIndexPath:targetIndexPath];
    if (!targetCell) {
        [self.collectionView layoutIfNeeded];
        targetCell = [self.collectionView cellForItemAtIndexPath:targetIndexPath];
    }
    if (!currentCell) {
        currentCell = [self.collectionView cellForItemAtIndexPath:targetIndexPath];
    }
    if (targetCell && currentCell) {
        [self updateIndicatorLineWidthBasedOnCurrentCell:(HATitleCell *)currentCell targetCell:(HATitleCell *)targetCell progress:progress];
    }
    
    // distance between center of two cells
    CGFloat distance = (targetCell.width/2.0f+currentCell.width/2.0f);
    CGFloat offsetToTravel = distance*progress;
    
    if (startingOffset == 0) {
        startingOffset = self.collectionView.contentOffset.x;
        if (jumped) {
            // moving backward
            
            startingOffset = startingOffset - offsetToTravel;
            jumped = NO;
        }
    }
    
    CGFloat targetOffset =  startingOffset + offsetToTravel;
    
    // update collectionView offset
    [self.collectionView setContentOffset:CGPointMake(targetOffset, 0)];
    
    if (ABS(progress) > 0.50) {
        self.centeredCellIndexPath = targetIndexPath;
    }
    else
    {
        self.centeredCellIndexPath = self.previousCenteredCellIndexPath;
    }

}

- (void)circularSlider:(HACircularSlider *)slider currentPageChanged:(NSInteger)targetIndex
{
    startingOffset = 0;

    NSInteger currentSection = self.selectedIndexPath.section;
    NSInteger currentIndex = self.selectedIndexPath.row;
    NSInteger numberOfRows = [self.collectionView numberOfItemsInSection:0];
    NSIndexPath *targetIndexPath;
    if (currentIndex == 0 && targetIndex == numberOfRows - 1) {
        if (currentSection == 1) {
            // moved from center section to left section
            targetIndexPath = [NSIndexPath indexPathForRow:targetIndex inSection:0];
        }
        else
            // moved from right section to center section
            targetIndexPath = [NSIndexPath indexPathForRow:targetIndex inSection:1];
        
    }
    else if (targetIndex == 0 && currentIndex == numberOfRows - 1)
    {
        if (currentSection == 1) {
            // moved from center section to right section
            targetIndexPath = [NSIndexPath indexPathForRow:targetIndex inSection:2];
        }
        else
            // moved from left section to center section
            targetIndexPath = [NSIndexPath indexPathForRow:targetIndex inSection:1];
    }
    else
        targetIndexPath = [NSIndexPath indexPathForRow:targetIndex inSection:currentSection];
    if (targetIndexPath.section == 0 &&targetIndexPath.row == 5) {
        NSLog(@"");
    }
    NSLog(@"moved: section:%ld , row:%ld",targetIndexPath.section, targetIndexPath.row);
    [self updateSelectedIndexPath:targetIndexPath];
    [self.delegate categorySlider:self didMoveToIndex:targetIndex];
    //if (pageControllerIsScrolling == NO) {
    // correct cell position, if it is not centered
    CGFloat targetOffset = [self targetContentOffsetForFinalOffset:self.collectionView.contentOffset].x;
    
    if (initiallyLayoutedSubviews) {
        [UIView animateWithDuration:0.2 animations:^{
            [self.collectionView setContentOffset:CGPointMake(targetOffset, 0) animated:YES];
        } completion:^(BOOL finished) {
            // [self updateSelectedIndexPath:targetIndexPath];
        }];
    }
    //}

}*/

- (void)updateSelectedIndexPath:(NSIndexPath *)indexPath
{
    self.selectedIndexPath = indexPath;
    self.previousCenteredCellIndexPath = [NSIndexPath indexPathForRow:indexPath.row inSection:self.selectedIndexPath.section];
    if (!didSelectCell) {
        self.centeredCellIndexPath = [NSIndexPath indexPathForRow:indexPath.row inSection:self.selectedIndexPath.section];
    }
}
// scrollView can be pageController scrollView or this slider collectionView, based on which method is calling this method
- (void)updateIndicatorLineWidthBasedOnCurrentCell:(HATitleCell *)currentCell targetCell:(HATitleCell *)targetCell progress:(CGFloat)progress
{
    CGFloat currentCellTextSize = [currentCell.titleLabel.text
                        boundingRectWithSize:currentCell.titleLabel.size
                        options:NSStringDrawingUsesLineFragmentOrigin
                        attributes:@{
                                     NSFontAttributeName :
                                         currentCell.titleLabel.font
                                     }
                        context:nil].size.width;
    
    CGFloat targetCellTextSize = [targetCell.titleLabel.text
                                  boundingRectWithSize:targetCell.titleLabel.size
                                  options:NSStringDrawingUsesLineFragmentOrigin
                                  attributes:@{
                                               NSFontAttributeName :
                                                   targetCell.titleLabel.font
                                               }
                                  context:nil].size.width;
    
    CGFloat widthDiff = progress < 0 ? (currentCellTextSize - targetCellTextSize) : (targetCellTextSize - currentCellTextSize);
    CGFloat indicatorNewWidth = currentCellTextSize + progress * widthDiff;
    
    CGPoint indicatorCenter = self.indicatorLine.center;
    self.indicatorLine.width = indicatorNewWidth;
    self.indicatorLine.center = indicatorCenter;
}
- (void)dealloc
{
    [self.collectionView removeObserver:self forKeyPath:@"contentSize"];
}

@end
