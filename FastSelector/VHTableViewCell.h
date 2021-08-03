//
//  VHTableViewCell.h
//  FastSelector
//
//  Created by Viktorhuang on 2021/8/3.
//

#import <UIKit/UIKit.h>

@interface VHTableViewCell : UITableViewCell

- (void)setCustomSelected:(BOOL)selected;

- (void)setCustomSelected:(BOOL)selected title:(NSString *)title;

@end
