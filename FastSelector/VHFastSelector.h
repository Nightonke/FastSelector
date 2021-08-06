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

@end

/// Fast selector for UITableView.
/// Wiki: https://github.com/Nightonke/FastSelector
@interface VHFastSelector : UIView

/// The corresponding tableView.
@property (nonatomic, strong) UITableView *tableView;

/// Delegate
@property (nonatomic, weak) id<VHFastSelectorDelegate> delegate;

/// Call this method to select or unselect cells when the corresponding tableView is scrolling.
- (void)tableViewDidScroll;

/// Call this method to cancel current touch events when the corresponding tableView 'reloadData'.
- (void)tableViewDidRefresh;

@end
