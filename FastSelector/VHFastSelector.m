//
//  VHFastSelector.m
//  FastSelector
//
//  Created by Viktorhuang on 2021/8/3.
//

#import "VHFastSelector.h"

/// TouchData stores the infomations of a UITouch.
/// Notice that we support multi-touch, so a dictionary of TouchDatas is stored in fastSelector.
@interface VHFastSelectorTouchData : NSObject

/// The indexPath when 'touchesBegan' happens. May be nil when there is no cell contains the touch point.
@property (nonatomic, strong) NSIndexPath *beginTouchIndexPath;
/// Whether the swipe action is to select or unselect? If the beginTouchIndexPath is unselected, then the swipe action is to select more cells, and vice versa.
/// Notice that the purpose of the action may be unknown when there is no cell contains the touch point.
@property (nonatomic, assign) BOOL toSelect;
/// Whether the purpose of the action is unknown.
@property (nonatomic, assign) BOOL isToSelectUnknown;

/// The point when 'touchesBegan' happens, in the local coordinate system of the tableView.
@property (nonatomic, assign) CGPoint beginLocation;
/// The touching point, in the local coordinate system of the tableView.
@property (nonatomic, assign) CGPoint touchingLocation;
/// The last touching point, in the local coordinate system of the tableView.
@property (nonatomic, assign) CGPoint touchedLocation;

/// The point when 'touchesBegan' happens, in the local coordinate system of the fastSelector.
@property (nonatomic, assign) CGPoint beginLocationInView;
/// The touching point, in the local coordinate system of the fastSelector.
@property (nonatomic, assign) CGPoint touchingLocationInView;
/// The last touching point, in the local coordinate system of the fastSelector.
@property (nonatomic, assign) CGPoint touchedLocationInView;

@property (nonatomic, assign) CGPoint beginContentOffset;

@end

@implementation VHFastSelectorTouchData

@end

@interface VHFastSelector ()

@property (nonatomic, strong) NSMutableDictionary<NSString *, VHFastSelectorTouchData *> *touchDatas;

@end

@implementation VHFastSelector

#pragma mark - Public

- (void)tableViewDidRefresh
{
    self.userInteractionEnabled = NO;
    [self.touchDatas removeAllObjects];
    self.userInteractionEnabled = YES;
}

- (void)tableViewDidScroll
{
    if (!self.tableView) return;
    [self handleTableViewScrolled];
}

#pragma mark - Interaction of fingers and tableView

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    if (!self.tableView) return;
    for (UITouch *touch in touches)
    {
        VHFastSelectorTouchData *touchData = [[VHFastSelectorTouchData alloc] init];
        
        CGPoint touchLocationInView = [touch locationInView:self];
        CGPoint touchLocation = [self convertPoint:touchLocationInView toView:self.tableView];
        
        touchData.beginLocationInView = touchLocationInView;
        touchData.touchedLocationInView = touchLocationInView;
        touchData.touchingLocationInView = touchLocationInView;
        
        touchData.beginLocation = touchLocation;
        touchData.touchedLocation = touchLocation;
        touchData.touchingLocation = touchLocation;
        
        touchData.beginTouchIndexPath = [self.tableView indexPathForRowAtPoint:touchLocation];
        if (touchData.beginTouchIndexPath == nil)
        {
            touchData.isToSelectUnknown = YES;
        }
        else
        {
            touchData.toSelect = ![self.delegate fastSelector:self isTableViewCellSelectedAtIndexPath:touchData.beginTouchIndexPath];
        }
        
        touchData.beginContentOffset = self.tableView.contentOffset;
        
        [self.touchDatas setObject:touchData forKey:[NSString stringWithFormat:@"%p", touch]];
    }
}

- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    if (!self.tableView) return;
    [self handleTouchChanged:touches];
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    [self touchesEndedOrCancelled:touches withEvent:event];
}

- (void)touchesCancelled:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    [self touchesEndedOrCancelled:touches withEvent:event];
}

- (void)touchesEndedOrCancelled:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    if (!self.tableView) return;
    [self handleTouchChanged:touches];
    for (UITouch *touch in touches)
    {
        [self.touchDatas removeObjectForKey:[NSString stringWithFormat:@"%p", touch]];
    }
}

#pragma mark - Core

- (void)handleTouchChanged:(NSSet<UITouch *> *)touches
{
    for (UITouch *touch in touches)
    {
        VHFastSelectorTouchData *touchData = [self.touchDatas objectForKey:[NSString stringWithFormat:@"%p", touch]];
        if (!touchData) continue;
        touchData.touchingLocationInView = [touch locationInView:self];
        touchData.touchingLocation = [self convertPoint:touchData.touchingLocationInView toView:self.tableView];
        [self updateToSelectIfNeeded:touchData];
        [self selectCells:touchData fromSwipe:YES];
        touchData.touchedLocation = touchData.touchingLocation;
        touchData.touchedLocationInView = touchData.touchingLocationInView;
    }
}

- (void)handleTableViewScrolled
{
    for (VHFastSelectorTouchData *touchData in self.touchDatas.allValues)
    {
        touchData.touchingLocation = [self convertPoint:touchData.touchingLocationInView toView:self.tableView];
        [self updateToSelectIfNeeded:touchData];
        [self selectCells:touchData fromSwipe:NO];
        touchData.touchedLocation = touchData.touchingLocation;
    }
}

- (void)updateToSelectIfNeeded:(VHFastSelectorTouchData *)touchData
{
    if (touchData.isToSelectUnknown)
    {
        // Only when we don't know to select or unselect, we need to update our purpose.
        NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:touchData.touchingLocation];
        if (indexPath)
        {
            touchData.toSelect = ![self.delegate fastSelector:self isTableViewCellSelectedAtIndexPath:indexPath];
            touchData.isToSelectUnknown = NO;
        }
    }
}

- (CGRect)rectMakeFromPoint:(CGPoint)point1 andPoint2:(CGPoint)point2
{
    return CGRectMake(MIN(point1.x, point2.x), MIN(point1.y, point2.y), fabs(point1.x - point2.x), fabs(point1.y - point2.y));
}

- (void)setCellsInRect:(CGRect)rect asSelected:(BOOL)selected forTouch:(VHFastSelectorTouchData *)touchData
{
    NSArray<NSIndexPath *> *indexPaths = [self indexPathsForRowsInRect:rect fromVisibleCell:YES isMovingUp:NO];
    for (NSIndexPath *indexPath in indexPaths)
    {
        NSIndexPath *beginIndexPathFromLocation = [self.tableView indexPathForRowAtPoint:touchData.beginLocation];
//        if (selected != touchData.toSelect && [indexPath isEqual:touchData.beginTouchIndexPath])
        if (selected != touchData.toSelect && [indexPath isEqual:beginIndexPathFromLocation])
        {
            continue;
        }
        
        NSIndexPath *touchingIndexPathFromLocation = [self.tableView indexPathForRowAtPoint:touchData.touchingLocation];
        if (selected != touchData.toSelect && [indexPath isEqual:touchingIndexPathFromLocation])
        {
            continue;
        }
        [self.delegate fastSelector:self setIndexPath:indexPath asSelected:selected];
    }
}

#define LessAndLess(a, b, c) ((a) >= (b) && (b) >= (c))

- (void)selectCells:(VHFastSelectorTouchData *)touchData fromSwipe:(BOOL)fromSwipe
{
    if (touchData.isToSelectUnknown)
    {
        // We don't even known whether we should select or unselect cells. Should just ignore.
        return;
    }
    
    CGRect doRect = CGRectZero, undoRect = CGRectZero;
    
    if (LessAndLess(touchData.touchingLocation.y, touchData.touchedLocation.y, touchData.beginLocation.y))
    {
        doRect = [self rectMakeFromPoint:touchData.touchingLocation andPoint2:touchData.touchedLocation];
    }
    else if (LessAndLess(touchData.touchingLocation.y, touchData.beginLocation.y, touchData.touchedLocation.y))
    {
        doRect = [self rectMakeFromPoint:touchData.beginLocation andPoint2:touchData.touchingLocation];
        undoRect = [self rectMakeFromPoint:touchData.touchedLocation andPoint2:touchData.beginLocation];
    }
    else if (LessAndLess(touchData.touchedLocation.y, touchData.touchingLocation.y, touchData.beginLocation.y))
    {
        undoRect = [self rectMakeFromPoint:touchData.touchingLocation andPoint2:touchData.touchedLocation];
    }
    else if (LessAndLess(touchData.touchedLocation.y, touchData.beginLocation.y, touchData.touchingLocation.y))
    {
        doRect = [self rectMakeFromPoint:touchData.touchingLocation andPoint2:touchData.beginLocation];
        undoRect = [self rectMakeFromPoint:touchData.beginLocation andPoint2:touchData.touchedLocation];
    }
    else if (LessAndLess(touchData.beginLocation.y, touchData.touchedLocation.y, touchData.touchingLocation.y))
    {
        doRect = [self rectMakeFromPoint:touchData.touchedLocation andPoint2:touchData.touchingLocation];
    }
    else if (LessAndLess(touchData.beginLocation.y, touchData.touchingLocation.y, touchData.touchedLocation.y))
    {
        undoRect = [self rectMakeFromPoint:touchData.touchingLocation andPoint2:touchData.touchedLocation];
    }
    
    if (!CGRectEqualToRect(CGRectZero, doRect))
    {
        [self setCellsInRect:doRect asSelected:touchData.toSelect forTouch:touchData];
    }
    
    if (!CGRectEqualToRect(CGRectZero, undoRect))
    {
        [self setCellsInRect:undoRect asSelected:!touchData.toSelect forTouch:touchData];
    }
    [self.delegate fastSelectorAutoCheck:self];
}

//- (void)selectCells:(VHFastSelectorTouchData *)touchData fromSwipe:(BOOL)fromSwipe
//{
//    if (touchData.isToSelectUnknown)
//    {
//        // We don't even known whether we should select or unselect cells. Should just ignore.
//        return;
//    }
//
//    CGFloat rectX = MIN(touchData.touchedLocation.x, touchData.touchingLocation.x);
//    CGFloat rectY = MIN(touchData.touchedLocation.y, touchData.touchingLocation.y);
//    CGFloat rectW = fabs(touchData.touchedLocation.x - touchData.touchingLocation.x);
//    CGFloat rectH = fabs(touchData.touchedLocation.y - touchData.touchingLocation.y);
//
//    CGRect changeRect = CGRectMake(rectX, rectY, rectW, rectH);
//
//    BOOL isMovingUp = touchData.touchingLocation.y < touchData.touchedLocation.y;
//    BOOL isMovingDown = touchData.touchingLocation.y > touchData.touchedLocation.y;
//    NSArray<NSIndexPath *> *changeIndexPaths = [self indexPathsForRowsInRect:changeRect fromVisibleCell:fromSwipe isMovingUp:isMovingUp];
//
//    NSLog(@"Begin index: %@", touchData.beginTouchIndexPath);
//    NSLog(@"Begin location: %@", [NSValue valueWithCGPoint:touchData.beginLocation]);
//    CGPoint nowBeginLocation = CGPointMake(touchData.beginLocationInView.x, touchData.beginLocationInView.y - (self.tableView.contentOffset.y - touchData.beginContentOffset.y));
//    touchData.beginLocation = [self convertPoint:nowBeginLocation toView:self.tableView];
//    NSLog(@"Begin location new: %@ %@", [NSValue valueWithCGPoint:nowBeginLocation], [NSValue valueWithCGPoint:touchData.beginLocation]);
//    NSLog(@"Begin index from location: %@", [self.tableView indexPathForRowAtPoint:touchData.beginLocation]);
////    NSLog(@"%@", self.tableView);
//
//
//    if (CGRectGetMinY(changeRect) <= touchData.beginLocation.y && touchData.beginLocation.y <= CGRectGetMaxY(changeRect))
//    {
//        if (isMovingUp)
//        {
//            NSLog(@"isMovingUp");
//            CGRect moreRect = CGRectMake(rectX, rectY, rectW, touchData.beginLocation.y - CGRectGetMinY(changeRect));
//            CGRect lessRect = CGRectMake(rectX, touchData.beginLocation.y, rectW, CGRectGetMaxY(changeRect) - touchData.beginLocation.y);
//
//            [self setCellsInRect:moreRect asSelected:touchData.toSelect forTouch:touchData fromSwipe:fromSwipe isMovingUp:isMovingUp];
//            [self setCellsInRect:lessRect asSelected:!touchData.toSelect forTouch:touchData fromSwipe:fromSwipe isMovingUp:isMovingUp];
//        }
//        else if (isMovingDown)
//        {
//            NSLog(@"isMovingDown");
//            CGRect lessRect = CGRectMake(rectX, rectY, rectW, touchData.beginLocation.y - CGRectGetMinY(changeRect));
//            CGRect moreRect = CGRectMake(rectX, touchData.beginLocation.y, rectW, CGRectGetMaxY(changeRect) - touchData.beginLocation.y);
//
//            [self setCellsInRect:moreRect asSelected:touchData.toSelect forTouch:touchData fromSwipe:fromSwipe isMovingUp:isMovingUp];
//            [self setCellsInRect:lessRect asSelected:!touchData.toSelect forTouch:touchData fromSwipe:fromSwipe isMovingUp:isMovingUp];
//        }
//        else
//        {
//            NSLog(@"isMovingCenter");
//            [self setCellsInRect:changeRect asSelected:touchData.toSelect forTouch:touchData fromSwipe:fromSwipe isMovingUp:isMovingUp];
//        }
//    }
//    else
//    {
//        BOOL isMore = fabs(touchData.touchingLocation.y - touchData.beginLocation.y) > fabs(touchData.touchedLocation.y - touchData.beginLocation.y);
//        if (isMore)
//        {
//            NSLog(@"isMore");
//            for (NSIndexPath *indexPath in changeIndexPaths)
//            {
//                [self.delegate fastSelector:self setIndexPath:indexPath asSelected:touchData.toSelect];
//            }
//        }
//        else
//        {
//            NSLog(@"isNotMore");
//            static NSIndexPath *kLastTouchingIndex = nil;
//            NSIndexPath *touchingIndex = [self.tableView indexPathForRowAtPoint:touchData.touchingLocation];
//            NSLog(@"%lf %lf %lf %lf", changeRect.origin.x, changeRect.origin.y, changeRect.size.width, changeRect.size.height);
//            NSLog(@"TouchingIndex: %@", touchingIndex);
//            NSLog(@"ChangeIndexs: %@", changeIndexPaths);
//            if (kLastTouchingIndex && ![kLastTouchingIndex isEqual:touchingIndex])
//            {
//                NSLog(@"xx");
//            }
//            kLastTouchingIndex = touchingIndex;
//            for (NSIndexPath *indexPath in changeIndexPaths)
//            {
//                NSIndexPath *beginIndexPathFromLocation = [self.tableView indexPathForRowAtPoint:touchData.beginLocation];
////                if (![indexPath isEqual:touchingIndex] && ![indexPath isEqual:touchData.beginTouchIndexPath])
//                if (![indexPath isEqual:touchingIndex] && ![indexPath isEqual:beginIndexPathFromLocation])
//                {
//                    [self.delegate fastSelector:self setIndexPath:indexPath asSelected:!touchData.toSelect];
//                }
//            }
//        }
//    }
//
//    [self.delegate fastSelectorAutoCheck:self];
//}

- (void)setCellsInRect:(CGRect)rect asSelected:(BOOL)selected forTouch:(VHFastSelectorTouchData *)touchData fromSwipe:(BOOL)fromSwipe isMovingUp:(BOOL)isMovingUp
{
    NSArray<NSIndexPath *> *indexPaths = [self indexPathsForRowsInRect:rect fromVisibleCell:fromSwipe isMovingUp:isMovingUp];
    for (NSIndexPath *indexPath in indexPaths)
    {
        NSIndexPath *beginIndexPathFromLocation = [self.tableView indexPathForRowAtPoint:touchData.beginLocation];
//        if (selected != touchData.toSelect && [indexPath isEqual:touchData.beginTouchIndexPath])
        if (selected != touchData.toSelect && [indexPath isEqual:beginIndexPathFromLocation])
        {
            continue;
        }
        [self.delegate fastSelector:self setIndexPath:indexPath asSelected:selected];
    }
}

#pragma mark - Getter

- (NSMutableDictionary<NSString *,VHFastSelectorTouchData *> *)touchDatas
{
    if (_touchDatas == nil)
    {
        _touchDatas = [NSMutableDictionary dictionary];
    }
    return _touchDatas;
}

#pragma mark - Utils

- (NSArray<NSIndexPath *> *)indexPathsForRowsInRect:(CGRect)rect fromVisibleCell:(BOOL)fromVisibleCell isMovingUp:(BOOL)isMovingUp
{
//    if (!fromVisibleCell)
    {
        NSIndexPath *bottomIndexPath = [self.tableView indexPathForRowAtPoint:CGPointMake(CGRectGetMaxX(rect), CGRectGetMaxY(rect))];
        NSArray<NSIndexPath *> *indexPaths = [self.tableView indexPathsForRowsInRect:rect];
        if (bottomIndexPath)
        {
            if (indexPaths)
            {
                if (![indexPaths containsObject:bottomIndexPath])
                {
                    return [indexPaths arrayByAddingObject:bottomIndexPath];
                }
                else
                {
                    return indexPaths;
                }
            }
            else
            {
                return @[bottomIndexPath];
            }
        }
        else
        {
            return indexPaths;
        }
    }
    
//    NSMutableArray<NSIndexPath *> *indexPaths = [NSMutableArray array];
//    for (UITableViewCell *cell in self.tableView.visibleCells)
//    {
//        if (CGRectIntersectsRect(rect, cell.frame))
//        {
//            [indexPaths addObject:[self.tableView indexPathForCell:cell]];
//        }
//    }
//    return indexPaths.copy;
}

@end
