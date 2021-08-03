//
//  VHFastSelector.m
//  FastSelector
//
//  Created by Viktorhuang on 2021/8/3.
//

#import "VHFastSelector.h"

@interface VHFastSelectorTouchData : NSObject

@property (nonatomic, assign) CGPoint touchingLocation;
@property (nonatomic, strong) NSIndexPath *touchBeganIndexPath;
@property (nonatomic, strong) NSIndexPath *lastTouchingIndexPath;
@property (nonatomic, assign) BOOL toSelect;

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
        touchData.touchingLocation = [touch locationInView:self];
        CGPoint point = [self convertPoint:touchData.touchingLocation toView:self.tableView];
        touchData.touchBeganIndexPath = [self.tableView indexPathForRowAtPoint:point];
        BOOL isSelected = [self.delegate fastSelector:self isTableViewCellSelectedAtIndexPath:touchData.touchBeganIndexPath];
        touchData.toSelect = !isSelected;
        
        [self.touchDatas setObject:touchData forKey:[NSString stringWithFormat:@"%p", touch]];
    }
}

- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    if (!self.tableView) return;
    
    for (UITouch *touch in touches)
    {
        VHFastSelectorTouchData *touchData = [self.touchDatas objectForKey:[NSString stringWithFormat:@"%p", touch]];
        if (!touchData) continue;
        
        touchData.touchingLocation = [touch locationInView:self];
        CGPoint point = [self convertPoint:touchData.touchingLocation toView:self.tableView];
        NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:point];
        
        if (indexPath == nil)
        {
            continue;  // TODO:V
        }
        
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

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    if (!self.tableView) return;
    
    for (UITouch *touch in touches)
    {
        VHFastSelectorTouchData *touchData = [self.touchDatas objectForKey:[NSString stringWithFormat:@"%p", touch]];
        if (!touchData) continue;
        
        touchData.touchingLocation = [touch locationInView:self];
        CGPoint point = [self convertPoint:touchData.touchingLocation toView:self.tableView];
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
        
        [self.touchDatas removeObjectForKey:[NSString stringWithFormat:@"%p", touch]];
    }
}

- (void)tableViewDidScroll
{
    if (!self.tableView) return;
    
    for (VHFastSelectorTouchData *touchData in self.touchDatas.allValues)
    {
        CGPoint point = [self convertPoint:touchData.touchingLocation toView:self.tableView];
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
