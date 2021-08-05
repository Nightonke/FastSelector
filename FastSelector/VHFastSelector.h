//
//  VHFastSelector.h
//  FastSelector
//
//  Created by Viktorhuang on 2021/8/3.
//

#import <UIKit/UIKit.h>

@class VHFastSelector;

@protocol VHFastSelectorDelegate <NSObject>

@required

/// Tell fastSelector whether the cell is selected according to the indexPath.
/// @param fs fastSelector
/// @param indexPath indexPath
- (BOOL)fastSelector:(VHFastSelector *)fs isTableViewCellSelectedAtIndexPath:(NSIndexPath *)indexPath;

/// FastSelector tells to select or unselect the cell according the the indexPath.
/// @param fs fastSelector
/// @param indexPath indexPath
/// @param selected selected
- (void)fastSelector:(VHFastSelector *)fs setIndexPath:(NSIndexPath *)indexPath asSelected:(BOOL)selected;

- (void)fastSelectorAutoCheck:(VHFastSelector *)fs;

@end


//multipleTouchEnabled
@interface VHFastSelector : UIView

@property (nonatomic, strong) UITableView *tableView;

@property (nonatomic, weak) id<VHFastSelectorDelegate> delegate;

- (void)tableViewDidScroll;

- (void)tableViewDidRefresh;

@end
