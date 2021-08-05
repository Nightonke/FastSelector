//
//  VHFastSelector.h
//  FastSelector
//
//  Created by Viktorhuang on 2021/8/3.
//

#import <UIKit/UIKit.h>

@class VHFastSelector;

@protocol VHFastSelectorDelegate <NSObject>

- (BOOL)fastSelector:(VHFastSelector *)fs isTableViewCellSelectedAtIndexPath:(NSIndexPath *)indexPath;

- (void)fastSelector:(VHFastSelector *)fs setIndexPath:(NSIndexPath *)indexPath asSelected:(BOOL)selected;

@end


//multipleTouchEnabled
@interface VHFastSelector : UIView

@property (nonatomic, weak) UITableView *tableView;

@property (nonatomic, weak) id<VHFastSelectorDelegate> delegate;

- (void)tableViewDidScroll;

- (void)tableViewDidRefresh;

@end
