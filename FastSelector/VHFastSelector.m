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

/// Whether the swipe action is to select or unselect? If the indexPath while 'touchBegan' is unselected, then the swipe action is to select more cells, and vice versa.
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

/// The touching point, in the local coordinate system of the fastSelector.
@property (nonatomic, assign) CGPoint touchingLocationInView;

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
        
        touchData.touchingLocationInView = touchLocationInView;
        touchData.beginLocation = touchData.touchedLocation = touchData.touchingLocation = touchLocation;
        
        NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:touchLocation];
        if (indexPath == nil)
        {
            touchData.isToSelectUnknown = YES;
        }
        else
        {
            touchData.toSelect = ![self.delegate fastSelector:self isTableViewCellSelectedAtIndexPath:indexPath];
        }
        
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
        [self selectCells:touchData];
        touchData.touchedLocation = touchData.touchingLocation;
    }
}

- (void)handleTableViewScrolled
{
    for (VHFastSelectorTouchData *touchData in self.touchDatas.allValues)
    {
        touchData.touchingLocation = [self convertPoint:touchData.touchingLocationInView toView:self.tableView];
        [self updateToSelectIfNeeded:touchData];
        [self selectCells:touchData];
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

#define SameOrder(a, b, c) (((a) >= (b) && (b) >= (c)) || ((a) <= (b) && (b) <= (c)))

- (void)selectCells:(VHFastSelectorTouchData *)touchData
{
    if (touchData.isToSelectUnknown)
    {
        // We don't even known whether we should select or unselect cells. Should just ignore.
        return;
    }
    
    CGRect doRect = CGRectZero, undoRect = CGRectZero;
    
    if (SameOrder(touchData.touchingLocation.y, touchData.touchedLocation.y, touchData.beginLocation.y))
    {
        doRect = [self rectMakeFromPoint:touchData.touchingLocation andPoint2:touchData.touchedLocation];
    }
    else if (SameOrder(touchData.touchingLocation.y, touchData.beginLocation.y, touchData.touchedLocation.y))
    {
        doRect = [self rectMakeFromPoint:touchData.beginLocation andPoint2:touchData.touchingLocation];
        undoRect = [self rectMakeFromPoint:touchData.touchedLocation andPoint2:touchData.beginLocation];
    }
    else if (SameOrder(touchData.touchedLocation.y, touchData.touchingLocation.y, touchData.beginLocation.y))
    {
        undoRect = [self rectMakeFromPoint:touchData.touchingLocation andPoint2:touchData.touchedLocation];
    }
    else
    {
        NSAssert(0, @"Unexpected case");
    }
    
    [self setCellsInRect:doRect asSelected:touchData.toSelect forTouch:touchData];
    [self setCellsInRect:undoRect asSelected:!touchData.toSelect forTouch:touchData];
}

- (CGRect)rectMakeFromPoint:(CGPoint)point1 andPoint2:(CGPoint)point2
{
    return CGRectMake(MIN(point1.x, point2.x), MIN(point1.y, point2.y), fabs(point1.x - point2.x), fabs(point1.y - point2.y));
}

- (void)setCellsInRect:(CGRect)rect asSelected:(BOOL)selected forTouch:(VHFastSelectorTouchData *)touchData
{
    if (CGRectEqualToRect(rect, CGRectZero)) return;
    for (NSIndexPath *indexPath in [self indexPathsForRowsInRect:rect])
    {
        if (selected != touchData.toSelect)
        {
            if ([indexPath isEqual:[self.tableView indexPathForRowAtPoint:touchData.beginLocation]]) continue;
            if ([indexPath isEqual:[self.tableView indexPathForRowAtPoint:touchData.touchingLocation]]) continue;
        }
        [self.delegate fastSelector:self setIndexPath:indexPath asSelected:selected];
    }
}

#pragma mark - Getter

- (NSMutableDictionary<NSString *,VHFastSelectorTouchData *> *)touchDatas
{
    if (_touchDatas == nil) _touchDatas = [NSMutableDictionary dictionary];
    return _touchDatas;
}

#pragma mark - Utils

- (NSArray<NSIndexPath *> *)indexPathsForRowsInRect:(CGRect)rect
{
    NSIndexPath *bottomIndexPath = [self.tableView indexPathForRowAtPoint:CGPointMake(CGRectGetMaxX(rect), CGRectGetMaxY(rect))];
    NSArray<NSIndexPath *> *indexPaths = [self.tableView indexPathsForRowsInRect:rect];
    if (indexPaths && bottomIndexPath && ![indexPaths containsObject:bottomIndexPath])
    {
        return [indexPaths arrayByAddingObject:bottomIndexPath];
    }
    else
    {
        return indexPaths ? indexPaths : (bottomIndexPath ? @[bottomIndexPath] : nil);
    }
}

@end
