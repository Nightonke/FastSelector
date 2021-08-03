//
//  ViewController.m
//  FastSelector
//
//  Created by Viktorhuang on 2021/8/3.
//

#import "ViewController.h"
#import "VHTableViewCell.h"
#import "VHFastSelector.h"

@interface ViewController ()<UITableViewDataSource, UITableViewDelegate, VHFastSelectorDelegate>

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) VHFastSelector *fastSelector;
@property (nonatomic, strong) NSMutableSet<NSIndexPath *> *selectedIndexPathes;

@end

@implementation ViewController

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        _selectedIndexPathes = [NSMutableSet set];
    }
    return self;
}

- (void)loadView
{
    [super loadView];
    self.view.backgroundColor = UIColor.whiteColor;
    
    UITableView *tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStyleGrouped];
    [tableView registerClass:VHTableViewCell.class forCellReuseIdentifier:@"VHTableViewCell"];
    tableView.dataSource = self;
    tableView.delegate = self;
    tableView.allowsSelection = NO;
    [self.view addSubview:tableView];
    self.tableView = tableView;
    
    VHFastSelector *fastSelector = [[VHFastSelector alloc] initWithFrame:CGRectMake(tableView.frame.origin.x,
                                                                                    tableView.frame.origin.y,
                                                                                    70,
                                                                                    tableView.frame.size.height)];
    fastSelector.tableView = tableView;
    fastSelector.delegate = self;
    [self.view addSubview:fastSelector];
    self.fastSelector = fastSelector;
}

#pragma mark - VHFastSelectorDelegate

- (BOOL)fastSelector:(VHFastSelector *)fs isTableViewCellSelectedAtIndexPath:(NSIndexPath *)indexPath
{
    return [self.selectedIndexPathes containsObject:indexPath];
}

- (void)fastSelector:(VHFastSelector *)fs setIndexPath:(NSIndexPath *)indexPath asSelected:(BOOL)selected
{
    VHTableViewCell *cell = (VHTableViewCell *)[self.tableView cellForRowAtIndexPath:indexPath];
    [cell setCustomSelected:selected];
    
    if (selected)
    {
        if (![self.selectedIndexPathes containsObject:indexPath])
        {
            [self.selectedIndexPathes addObject:indexPath];
        }
    }
    else
    {
        if ([self.selectedIndexPathes containsObject:indexPath])
        {
            [self.selectedIndexPathes removeObject:indexPath];
        }
    }
    
    [self setTitle:[NSString stringWithFormat:@"%ld Selected", self.selectedIndexPathes.count]];
}

#pragma mark - UITableViewDataSource

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    VHTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"VHTableViewCell"
                                                            forIndexPath:indexPath];
    [cell setCustomSelected:[self.selectedIndexPathes containsObject:indexPath]
                      title:[NSString stringWithFormat:@"%2ld     %5ld", (long)indexPath.section, (long)indexPath.row]];
    return cell;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 3;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 200;
}

#pragma mark - UITableViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    [self.fastSelector tableViewDidScroll];
}

@end
