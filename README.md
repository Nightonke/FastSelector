# FastSelector

>Supports 'swipe and scroll' selection for UITableView like App 'Files'.

https://user-images.githubusercontent.com/7379793/134856311-c00d2744-5a10-4468-ab46-9b357a257d3e.mp4

### Usage

Copy `VHFastSelector.h&m` to your project.

```objective-c
#import "VHFastSelector.h"

- (void)loadView
{
    // ...
    CGRect frame = tableView.frame;
    frame.size.width = 70;
    VHFastSelector *fastSelector = [[VHFastSelector alloc] initWithFrame:frame];
    fastSelector.tableView = tableView;
    fastSelector.delegate = self;
    [self.view addSubview:fastSelector];
}

- (BOOL)fastSelector:(VHFastSelector *)fs isTableViewCellSelectedAtIndexPath:(NSIndexPath *)indexPath
{
    // Tell fastSelector whether the indexPath is selected.
}

- (void)fastSelector:(VHFastSelector *)fs setIndexPath:(NSIndexPath *)indexPath asSelected:(BOOL)selected
{
    if (selected)
    {
        // Select the data and cell of the indexPath.
    }
    else
    {
        // Unselect the data and cell of the indexPath.
    }
}

```

Notice that the fastSelector must on the top of the tableView. So it can receive the touch events.



###How it works

