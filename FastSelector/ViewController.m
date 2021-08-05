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

@property (nonatomic, assign) NSInteger section;
@property (nonatomic, assign) NSInteger row;

@end

@implementation ViewController

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        _selectedIndexPathes = [NSMutableSet set];
        _section = 1;
        _row = 1000;
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
    
    self.navigationItem.rightBarButtonItems = @[
        [[UIBarButtonItem alloc] initWithTitle:@"Adjust Table" style:UIBarButtonItemStylePlain target:self action:@selector(adjustTableButtonDidClick:)],
        [[UIBarButtonItem alloc] initWithTitle:@"Unselect All" style:UIBarButtonItemStylePlain target:self action:@selector(unselectAllButtonDidClick:)]
    ];
    
    [self refreshTitle];
}

- (void)refreshTitle
{
    [self setTitle:[NSString stringWithFormat:@"%ld Selected", self.selectedIndexPathes.count]];
}

#pragma mark - VHFastSelectorDelegate

- (BOOL)fastSelector:(VHFastSelector *)fs isTableViewCellSelectedAtIndexPath:(NSIndexPath *)indexPath
{
    return [self.selectedIndexPathes containsObject:indexPath];
}

- (void)fastSelector:(VHFastSelector *)fs setIndexPath:(NSIndexPath *)indexPath asSelected:(BOOL)selected
{
    if ([[self.tableView indexPathsForVisibleRows] containsObject:indexPath])
    {
        VHTableViewCell *cell = (VHTableViewCell *)[self.tableView cellForRowAtIndexPath:indexPath];
        [cell setCustomSelected:selected];
    }
    
    if (selected)
    {
        if (![self.selectedIndexPathes containsObject:indexPath])
        {
            [self.selectedIndexPathes addObject:indexPath];
            [self triggerImpactLightFeedback];
        }
    }
    else
    {
        if ([self.selectedIndexPathes containsObject:indexPath])
        {
            [self.selectedIndexPathes removeObject:indexPath];
            [self triggerImpactLightFeedback];
        }
    }
    
    [self refreshTitle];
}

#pragma mark - Action

- (void)adjustTableButtonDidClick:(UIButton *)button
{
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:nil message:@"Adjust the tableView:" preferredStyle:UIAlertControllerStyleAlert];
    __weak UIAlertController *weakAlertController = alertController;
    [alertController addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.placeholder = @"Number of sections";
        textField.keyboardType = UIKeyboardTypeNumberPad;
    }];
    [alertController addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.placeholder = @"Number of rows/section";
        textField.keyboardType = UIKeyboardTypeNumberPad;
    }];
    [alertController addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleDefault handler:nil]];
    [alertController addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        UITextField *sectionTextField = weakAlertController.textFields.firstObject;
        UITextField *rowTextField = weakAlertController.textFields.lastObject;
        NSInteger section = -1;
        NSInteger row = -1;
        if (sectionTextField.text.length > 0 && [sectionTextField.text integerValue] > 0)
        {
            section = [sectionTextField.text integerValue];
        }
        if (rowTextField.text.length > 0 && [rowTextField.text integerValue] >= 0)
        {
            row = [rowTextField.text integerValue];
        }
        if (section >= 0 && row >= 0)
        {
            self.section = section;
            self.row = row;
            [self unselectAllAndRefresh];
        }
    }]];
    [self presentViewController:alertController animated:YES completion:nil];
}

- (void)unselectAllButtonDidClick:(UIButton *)button
{
    [self unselectAllAndRefresh];
}

- (void)unselectAllAndRefresh
{
    [self.selectedIndexPathes removeAllObjects];
    [self.tableView reloadData];
    [self.fastSelector tableViewDidRefresh];
    [self refreshTitle];
}

- (void)triggerImpactLightFeedback
{
    if (@available(iOS 10.0, *))
    {
        UIImpactFeedbackGenerator *imp = [[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleLight];
        [imp prepare];
        [imp impactOccurred];
    }
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
    return self.section;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.row;
}

#pragma mark - UITableViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    [self.fastSelector tableViewDidScroll];
}

@end
