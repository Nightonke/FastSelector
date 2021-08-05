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
        touchData.touchedLocationInView = touchData.touchingLocationInView;
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

- (void)selectCells:(VHFastSelectorTouchData *)touchData
{
    if (touchData.isToSelectUnknown)
    {
        // We don't even known whether we should select or unselect cells. Should just ignore.
        return;
    }
    
    CGFloat rectX = MIN(touchData.touchedLocation.x, touchData.touchingLocation.x);
    CGFloat rectY = MIN(touchData.touchedLocation.y, touchData.touchingLocation.y);
    CGFloat rectW = MAX(fabs(touchData.touchedLocation.x - touchData.touchingLocation.x), 1);
    CGFloat rectH = MAX(fabs(touchData.touchedLocation.y - touchData.touchingLocation.y), 1);
    
    CGRect changeRect = CGRectMake(rectX, rectY, rectW, rectH);
    
    NSArray<NSIndexPath *> *changeIndexPaths = [self.tableView indexPathsForRowsInRect:changeRect];
    
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
        else
        {
            [self setCellsInRect:changeRect asSelected:touchData.toSelect forTouch:touchData];
        }
    }
    else
    {
        BOOL isMore = fabs(touchData.touchingLocation.y - touchData.beginLocation.y) > fabs(touchData.touchedLocation.y - touchData.beginLocation.y);
        if (isMore)
        {
            for (NSIndexPath *indexPath in changeIndexPaths)
            {
                [self.delegate fastSelector:self setIndexPath:indexPath asSelected:touchData.toSelect];
            }
        }
        else
        {
            NSIndexPath *touchingIndex = [self.tableView indexPathForRowAtPoint:touchData.touchingLocationInView];
            for (NSIndexPath *indexPath in changeIndexPaths)
            {
                if (![indexPath isEqual:touchingIndex] && ![indexPath isEqual:touchData.beginTouchIndexPath])
                {
                    [self.delegate fastSelector:self setIndexPath:indexPath asSelected:!touchData.toSelect];
                }
            }
        }
    }
}

- (void)setCellsInRect:(CGRect)rect asSelected:(BOOL)selected forTouch:(VHFastSelectorTouchData *)touchData
{
    NSArray<NSIndexPath *> *indexPaths = [self.tableView indexPathsForRowsInRect:rect];
    for (NSIndexPath *indexPath in indexPaths)
    {
        if (selected != touchData.toSelect && [indexPath isEqual:touchData.beginTouchIndexPath])
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

@end
