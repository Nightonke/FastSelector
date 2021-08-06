//
//  VHTableViewCell.m
//  FastSelector
//
//  Created by Viktorhuang on 2021/8/3.
//

#import "VHTableViewCell.h"

@interface VHTableViewCell ()

@property (nonatomic, strong) UIImageView *selectImageView;
@property (nonatomic, strong) UILabel *label;

@end

@implementation VHTableViewCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self)
    {
        self.backgroundColor = UIColor.clearColor;
        
        _selectImageView = [[UIImageView alloc] init];
        [self.contentView addSubview:_selectImageView];
        
        _label = [[UILabel alloc] init];
        _label.textColor = UIColor.blackColor;
        _label.textAlignment = NSTextAlignmentLeft;
        [self.contentView addSubview:_label];
    }
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    self.selectImageView.frame = CGRectMake(20, (self.frame.size.height - 30) / 2, 30, 30);
    self.label.frame = CGRectMake(70, (self.frame.size.height - 30) / 2, 100, 30);
}

- (void)setCustomSelected:(BOOL)selected
{
    [self setCustomSelected:selected title:self.label.text];
}

- (void)setCustomSelected:(BOOL)selected title:(NSString *)title
{
    if (selected)
    {
        self.selectImageView.image = [UIImage imageNamed:@"cell_checked"];
    }
    else
    {
        self.selectImageView.image = [UIImage imageNamed:@"cell_unchecked"];
    }
    self.label.text = title;
}

@end
