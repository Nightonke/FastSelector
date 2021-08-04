//
//  VHFastSelector.m
//  FastSelector
//
//  Created by Viktorhuang on 2021/8/3.
//

#import "VHFastSelector.h"

@interface VHFastSelectorTouchData : NSObject

@property (nonatomic, assign) CGPoint touchingLocation;
@property (nonatomic, assign) CGPoint touchBeganLocation;
@property (nonatomic, strong) NSIndexPath *touchBeganIndexPath;
@property (nonatomic, assign) CGPoint lastTouchingLocation;
@property (nonatomic, strong) NSIndexPath *lastTouchingIndexPath;

@property (nonatomic, assign) BOOL toSelect;

@property (nonatomic, assign) CGPoint beginLocation;
@property (nonatomic, assign) CGPoint touchedLocation;

@end

@implementation VHFastSelectorTouchData

@end

@interface VHFastSelector ()

@property (nonatomic, strong) NSMutableDictionary<NSString *, VHFastSelectorTouchData *> *touchDatas;

@end

@implementation VHFastSelector

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        self.multipleTouchEnabled = YES;
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        self.multipleTouchEnabled = YES;
    }
    return self;
}

- (void)tableViewDidRefresh
{
    
}

- (NSMutableDictionary<NSString *,VHFastSelectorTouchData *> *)touchDatas
{
    if (_touchDatas == nil)
    {
        _touchDatas = [NSMutableDictionary dictionary];
    }
    return _touchDatas;
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    if (!self.tableView) return;
    
    for (UITouch *touch in touches)
    {
        VHFastSelectorTouchData *touchData = [[VHFastSelectorTouchData alloc] init];
        touchData.touchBeganLocation = [touch locationInView:self];
        touchData.touchingLocation = touchData.touchBeganLocation;
        touchData.lastTouchingLocation = touchData.touchBeganLocation;
        CGPoint point = [self convertPoint:touchData.touchingLocation toView:self.tableView];
        touchData.touchBeganIndexPath = [self.tableView indexPathForRowAtPoint:point];
        BOOL isSelected = [self.delegate fastSelector:self isTableViewCellSelectedAtIndexPath:touchData.touchBeganIndexPath];
        touchData.toSelect = !isSelected;
        
        touchData.beginLocation = point;
        touchData.touchedLocation = point;
        touchData.touchingLocation = point;
        
        [self.touchDatas setObject:touchData forKey:[NSString stringWithFormat:@"%p", touch]];
    }
}

- (NSArray<NSIndexPath *> *)indexPathsForRowsInRect:(CGRect)rect
{
    NSMutableArray<NSIndexPath *> *indexPaths = [NSMutableArray array];
    for (UITableViewCell *cell in self.tableView.visibleCells)
    {
        if (CGRectIntersectsRect(rect, cell.frame))
        {
            [indexPaths addObject:[self.tableView indexPathForCell:cell]];
        }
    }
    return indexPaths.copy;
}

- (void)setCellsInRect:(CGRect)rect asSelected:(BOOL)selected forTouch:(VHFastSelectorTouchData *)touchData
{
    NSArray<NSIndexPath *> *indexPaths = [self indexPathsForRowsInRect:rect];
    
    NSLog(@"SetCells: %lf %lf %lf %lf, %ld, %@",
          rect.origin.x,
          rect.origin.y,
          rect.origin.x + rect.size.width,
          rect.origin.y + rect.size.height,
          (long)selected,
          indexPaths);
    
    for (NSIndexPath *indexPath in indexPaths)
    {
        if (selected != touchData.toSelect && [indexPath isEqual:touchData.touchBeganIndexPath])
        {
            continue;
        }
        [self.delegate fastSelector:self setIndexPath:indexPath asSelected:selected];
    }
}

- (void)handleTouchChanged:(NSSet<UITouch *> *)touches
{
    for (UITouch *touch in touches)
    {
        VHFastSelectorTouchData *touchData = [self.touchDatas objectForKey:[NSString stringWithFormat:@"%p", touch]];
        if (!touchData) continue;
        
        CGPoint point = [self convertPoint:[touch locationInView:self] toView:self.tableView];
        touchData.touchingLocation = point;
        
        CGFloat rectX = MIN(touchData.touchedLocation.x, touchData.touchingLocation.x);
        CGFloat rectY = MIN(touchData.touchedLocation.y, touchData.touchingLocation.y);
        CGFloat rectW = MAX(fabs(touchData.touchedLocation.x - touchData.touchingLocation.x), 1);
        CGFloat rectH = MAX(fabs(touchData.touchedLocation.y - touchData.touchingLocation.y), 1);
        
        CGRect changeRect = CGRectMake(rectX, rectY, rectW, rectH);
        
        NSArray<NSIndexPath *> *changeIndexPaths = [self indexPathsForRowsInRect:changeRect];
        
        BOOL isMovingUp = touchData.touchingLocation.y < touchData.touchedLocation.y;
        BOOL isMovingDown = touchData.touchingLocation.y > touchData.touchedLocation.y;
        
        if (CGRectGetMinY(changeRect) <= touchData.beginLocation.y && touchData.beginLocation.y <= CGRectGetMaxY(changeRect))
        {
            if (isMovingUp)
            {
                CGRect moreRect = CGRectMake(rectX, rectY, rectW, touchData.beginLocation.y - CGRectGetMinY(changeRect));
                CGRect lessRect = CGRectMake(rectX, touchData.beginLocation.y, rectW, CGRectGetMaxY(changeRect) - touchData.beginLocation.y);
                
                [self setCellsInRect:moreRect asSelected:touchData.toSelect forTouch:touchData];
                [self setCellsInRect:lessRect asSelected:!touchData.toSelect forTouch:touchData];
            }
            else if (isMovingDown)
            {
                CGRect lessRect = CGRectMake(rectX, rectY, rectW, touchData.beginLocation.y - CGRectGetMinY(changeRect));
                CGRect moreRect = CGRectMake(rectX, touchData.beginLocation.y, rectW, CGRectGetMaxY(changeRect) - touchData.beginLocation.y);
                
                [self setCellsInRect:moreRect asSelected:touchData.toSelect forTouch:touchData];
                [self setCellsInRect:lessRect asSelected:!touchData.toSelect forTouch:touchData];
            }
        }
        else
        {
            BOOL isMore = fabs(touchData.touchingLocation.y - touchData.beginLocation.y) > fabs(touchData.touchedLocation.y - touchData.beginLocation.y);
            if (isMore)
            {
                NSLog(@"select(%ld) indexPaths: %@", (long)touchData.toSelect, changeIndexPaths);
                for (NSIndexPath *indexPath in changeIndexPaths)
                {
                    [self.delegate fastSelector:self setIndexPath:indexPath asSelected:touchData.toSelect];
                }
            }
            else
            {
                NSLog(@"select(%ld) indexPaths: %@", (long)!touchData.toSelect, changeIndexPaths);
                NSIndexPath *touchingIndex = [self.tableView indexPathForRowAtPoint:point];
                for (NSIndexPath *indexPath in changeIndexPaths)
                {
                    if (![indexPath isEqual:touchingIndex] && ![indexPath isEqual:touchData.touchBeganIndexPath])
                    {
                        [self.delegate fastSelector:self setIndexPath:indexPath asSelected:!touchData.toSelect];
                    }
                }
            }
        }
        
        touchData.touchedLocation = touchData.touchingLocation;
        
//
//        touchData.touchingLocation = [touch locationInView:self];
//        CGPoint point = [self convertPoint:touchData.touchingLocation toView:self.tableView];
//        NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:point];
//
//        BOOL isMore = fabs(touchData.touchingLocation.y - touchData.touchBeganLocation.y) > fabs(touchData.lastTouchingLocation.y - touchData.touchBeganLocation.y);
//        CGFloat rectX = self.tableView.bounds.origin.x;
//        CGFloat rectY = MIN(touchData.touchingLocation.y, touchData.lastTouchingLocation.y);
//        CGFloat rectW = self.tableView.bounds.size.width;
//        CGFloat rectH = MAX(touchData.touchingLocation.y, touchData.lastTouchingLocation.y) - rectY;
////        if (rectH < 1)
////        {
////            rectH = 1;
////        }
//        CGRect rect = CGRectMake(rectX, rectY, rectW, rectH);
//        rect = [self convertRect:rect toView:self.tableView];
//        NSArray<NSIndexPath *> *indexPaths = [self indexPathsForRowsInRect:rect];
//
//        if (indexPaths.count == 0)
//        {
//            NSMutableArray<NSIndexPath *> *xxxIndexPaths = [NSMutableArray array];
//            if ([self.tableView indexPathForRowAtPoint:CGPointMake(point.x, rect.origin.y)])
//            {
//                [xxxIndexPaths addObject:[self.tableView indexPathForRowAtPoint:CGPointMake(point.x, rect.origin.y)]];
//            }
//            else if ([self.tableView indexPathForRowAtPoint:CGPointMake(point.x, rect.origin.y + rect.size.height)])
//            {
//                [xxxIndexPaths addObject:[self.tableView indexPathForRowAtPoint:CGPointMake(point.x, rect.origin.y + rect.size.height)]];
//            }
//            indexPaths = xxxIndexPaths.copy;
//        }
//
//        if (isMore)
//        {
//            for (NSIndexPath *indexPath in indexPaths)
//            {
//                [self.delegate fastSelector:self setIndexPath:indexPath asSelected:touchData.toSelect];
//            }
//        }
//        else
//        {
//            NSIndexPath *touchingIndex = [self.tableView indexPathForRowAtPoint:point];
//            if (touchingIndex == nil)
//            {
//                NSLog(@"sss %ld %lf %lf %lf", (long)indexPaths.count, rect.size.height, rect.origin.y, self.tableView.contentOffset.y);
//            }
//            for (NSIndexPath *indexPath in indexPaths)
//            {
//                if (![indexPath isEqual:touchingIndex] && ![indexPath isEqual:touchData.touchBeganIndexPath])
//                {
//                    [self.delegate fastSelector:self setIndexPath:indexPath asSelected:!touchData.toSelect];
//                }
//            }
//        }
        
//        if (indexPath == nil)
//        {
//            CGFloat lastDistance = fabs(touchData.lastTouchingLocation.y - touchData.touchBeganLocation.y);
//            CGFloat distance = fabs(touchData.touchingLocation.y - touchData.touchBeganLocation.y);
//
//            if (distance > lastDistance)
//            {
//
//            }
//            else if (distance < lastDistance)
//            {
//                if (![touchData.lastTouchingIndexPath isEqual:touchData.touchBeganIndexPath])
//                {
//                    [self.delegate fastSelector:self setIndexPath:touchData.lastTouchingIndexPath asSelected:!touchData.toSelect];
//                }
//            }
//        }
//        else
//        {
//            NSInteger lastDistance = [self distanceBetweenIndexPath:touchData.touchBeganIndexPath and:touchData.lastTouchingIndexPath];
//            NSInteger distance = [self distanceBetweenIndexPath:touchData.touchBeganIndexPath and:indexPath];
//
//            if (distance > lastDistance)
//            {
//                // Sometimes the tableview is scrolling so fast. Some indexes may be skipped.
//                for (NSInteger i = distance - lastDistance - 1; i >= 0; i--)
//                {
//                    NSIndexPath *toChangeIndexPath = [NSIndexPath indexPathForRow:indexPath.row - i inSection:indexPath.section];
//                    [self.delegate fastSelector:self setIndexPath:toChangeIndexPath asSelected:touchData.toSelect];
//                }
//            }
//            else if (distance < lastDistance)
//            {
//                for (NSInteger i = 0; i < lastDistance - distance; i++)
//                {
//                    NSIndexPath *toChangeIndexPath = [NSIndexPath indexPathForRow:touchData.lastTouchingIndexPath.row - i inSection:indexPath.section];
//                    [self.delegate fastSelector:self setIndexPath:toChangeIndexPath asSelected:!touchData.toSelect];
//                }
//            }
//            touchData.lastTouchingIndexPath = indexPath;
//        }
        touchData.lastTouchingLocation = touchData.touchingLocation;
    }
}

- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    if (!self.tableView) return;
    
    [self handleTouchChanged:touches];
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    if (!self.tableView) return;
    
    [self handleTouchChanged:touches];
    
    for (UITouch *touch in touches)
    {
        [self.touchDatas removeObjectForKey:[NSString stringWithFormat:@"%p", touch]];
    }
}

- (void)touchesCancelled:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    if (!self.tableView) return;
    
    [self handleTouchChanged:touches];
    
    for (UITouch *touch in touches)
    {
        [self.touchDatas removeObjectForKey:[NSString stringWithFormat:@"%p", touch]];
    }
}

- (void)tableViewDidScroll
{
    if (!self.tableView) return;
    
    for (VHFastSelectorTouchData *touchData in self.touchDatas.allValues)
    {
        CGPoint point = touchData.touchingLocation;
        NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:point];
        
        NSInteger lastDistance = [self distanceBetweenIndexPath:touchData.touchBeganIndexPath and:touchData.lastTouchingIndexPath];
        NSInteger distance = [self distanceBetweenIndexPath:touchData.touchBeganIndexPath and:indexPath];
        
        if (distance > lastDistance)
        {
            // Sometimes the tableview is scrolling so fast. Some indexes may be skipped.
            for (NSInteger i = distance - lastDistance - 1; i >= 0; i--)
            {
                NSIndexPath *toChangeIndexPath = [NSIndexPath indexPathForRow:indexPath.row - i inSection:indexPath.section];
                [self.delegate fastSelector:self setIndexPath:toChangeIndexPath asSelected:touchData.toSelect];
            }
        }
        else if (distance < lastDistance)
        {
            for (NSInteger i = 0; i < lastDistance - distance; i++)
            {
                NSIndexPath *toChangeIndexPath = [NSIndexPath indexPathForRow:touchData.lastTouchingIndexPath.row - i inSection:indexPath.section];
                [self.delegate fastSelector:self setIndexPath:toChangeIndexPath asSelected:!touchData.toSelect];
            }
        }
        touchData.lastTouchingIndexPath = indexPath;
    }
}

- (NSInteger)distanceBetweenIndexPath:(NSIndexPath *)indexPath1 and:(NSIndexPath *)indexPath2
{
    if (!indexPath1 || !indexPath2) return -1;
    
    NSInteger row1 = [self absoluteRowForIndexPath:indexPath1];
    NSInteger row2 = [self absoluteRowForIndexPath:indexPath2];
    
    return labs(row1 - row2);
}

- (NSInteger)absoluteRowForIndexPath:(NSIndexPath *)indexPath
{
    NSInteger row = 0;
    for (NSInteger section = 0; section < indexPath.section; section++)
    {
        row += [self.tableView.dataSource tableView:self.tableView numberOfRowsInSection:section];
    }
    row += indexPath.row;
    return row;
}

@end
