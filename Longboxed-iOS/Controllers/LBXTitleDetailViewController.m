//
//  LBXTitleViewController.m
//  Longboxed-iOS
//
//  Created by johnrhickey on 8/10/14.
//  Copyright (c) 2014 Longboxed. All rights reserved.
//
#import <QuartzCore/QuartzCore.h>

#import "LBXClient.h"
#import "LBXMessageBar.h"
#import "LBXPullListTableViewCell.h"
#import "LBXPullListTitle.h"
#import "LBXTitle.h"
#import "LBXTitleDetailView.h"
#import "LBXTitleDetailViewController.h"
#import "LBXTitleServices.h"

#import "UIFont+customFonts.h"
#import "NSArray+ArrayUtilities.h"

#import <SVProgressHUD.h>

@interface LBXTitleDetailViewController () <UIScrollViewDelegate>

@property (nonatomic, copy) LBXTitle *detailTitle;
@property (nonatomic, copy) LBXClient *client;
@property (nonatomic, copy) LBXTitleDetailView *detailView;
@property (nonatomic, copy) NSArray *pullListArray;
@property (nonatomic, copy) NSArray *issuesForTitleArray;

@end

@implementation LBXTitleDetailViewController

static const NSUInteger ISSUE_TABLE_HEIGHT = 88;
static BOOL addToListToggle = NO;

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Calls perferredStatusBarStyle
    [self setNeedsStatusBarAppearanceUpdate];
    
    UIBarButtonItem *actionButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"clear"] style:UIBarButtonItemStylePlain target:self action:nil];
    self.navigationItem.rightBarButtonItem = actionButton;
    self.title = _detailTitle.name;
    _client = [LBXClient new];
    
    [self createPullListArray];
    [self createIssuesArray];
    [self setOverView:self.myOverView];
    [self fetchPullList];
    [self fetchAllIssues];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.navigationController.navigationBar.backItem.backBarButtonItem setImageInsets:UIEdgeInsetsMake(40, 40, -40, 40)];
    [self.navigationController.navigationBar setBackIndicatorImage:
     [UIImage imageNamed:@"arrow"]];
    [self.navigationController.navigationBar setBackIndicatorTransitionMaskImage:
     [UIImage imageNamed:@"arrow"]];
    self.tableView.rowHeight = ISSUE_TABLE_HEIGHT;

    if (_detailView.latestIssueImageView.image.size.height > 200.0) {
        self.navigationController.navigationBar.barStyle = UIBarStyleBlackTranslucent;
        [self.navigationController.navigationBar setBackgroundImage:[UIImage new]
                                                      forBarMetrics:UIBarMetricsDefault];
        self.navigationController.navigationBar.shadowImage = [UIImage new];
        
        self.navigationController.navigationBar.translucent = YES;
        self.navigationController.view.backgroundColor = [UIColor clearColor];
    }
    else {
        self.navigationController.navigationBar.barStyle = UIBarStyleDefault;
        self.navigationController.navigationBar.tintColor = [UIColor blackColor];
        [self.navigationController.navigationBar setTitleTextAttributes:@{NSForegroundColorAttributeName : [UIColor blackColor]}];
    }

    [self setNavBarAlpha:@0];

    // Keep the section header on the top
    self.edgesForExtendedLayout = UIRectEdgeNone;
    self.tableView.contentInset = UIEdgeInsetsMake(0, 0, 64, 0);
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [self setNavBarAlpha:@1];
    self.navigationController.navigationBar.barStyle = UIBarStyleDefault;
}

- (UIView *)myOverView {
    //UIView *view = [[UIView alloc] initWithFrame:self.overView.bounds];
    _detailView = [LBXTitleDetailView new];
    _detailView.frame = self.overView.frame;
    _detailView.bounds = self.overView.bounds;
    _detailView.titleLabel.text = _detailTitle.name;
    _detailView.titleLabel.font = [UIFont titleDetailTitleFont];
    _detailView.titleLabel.numberOfLines = 2;
    [_detailView.titleLabel sizeToFit];
    _detailView.publisherLabel.text = [_detailTitle.publisher.name uppercaseString];
    _detailView.publisherLabel.font = [UIFont titleDetailPublisherFont];
    
    NSString *issuesString;
    if ([_detailTitle.issueCount isEqualToNumber:@1]) {
        issuesString = [NSString stringWithFormat:@"%@ Issue", _detailTitle.issueCount];
    }
    else {
        issuesString = [NSString stringWithFormat:@"%@ Issues", _detailTitle.issueCount];
    }
    
    NSString *subscribersString;
    if ([_detailTitle.subscribers isEqualToNumber:@1]) {
        subscribersString = [NSString stringWithFormat:@"%@ Subscriber", _detailTitle.subscribers];
    }
    else {
        subscribersString = [NSString stringWithFormat:@"%@ Subscribers", _detailTitle.subscribers];
    }
    
    _detailView.issuesAndSubscribersLabel.text = [NSString stringWithFormat:@"%@  •  %@", [issuesString uppercaseString], [subscribersString uppercaseString]];
    _detailView.issuesAndSubscribersLabel.font = [UIFont titleDetailSubscribersAndIssuesFont];
    
        _detailView.latestIssueLabel.font = [UIFont titleDetailLatestIssueFont];
    if ([LBXTitleServices lastIssueForTitle:_detailTitle] != nil) {
        LBXIssue *issue = [LBXTitleServices lastIssueForTitle:_detailTitle];
        NSString *timeSinceString = [LBXTitleServices timeSinceLastIssueForTitle:_detailTitle];

        NSString *subtitleString = [NSString stringWithFormat:@"Issue %@ released %@", issue.issueNumber, timeSinceString];
        if ([timeSinceString hasPrefix:@"in"]) {
           subtitleString = [NSString stringWithFormat:@"Issue %@ will be released %@", issue.issueNumber, timeSinceString];
        }
        _detailView.latestIssueLabel.text = subtitleString;
    }
    else if (!_issuesForTitleArray.count) {
        _detailView.latestIssueLabel.text = @"No issues released";
    }
    else {
        _detailView.latestIssueLabel.text = @"";
    }
    
    [self setPullListButton];
    _detailView.addToPullListButton.titleLabel.font = [UIFont titleDetailAddToPullListFont];
    _detailView.addToPullListButton.layer.borderWidth = 1.0f;
    _detailView.addToPullListButton.layer.cornerRadius = 19.0f;
    
    _detailView.latestIssueImageView.image = _latestIssueImage;
    [_detailView.latestIssueImageView sizeToFit];
    
    return _detailView;
}

- (BOOL)prefersStatusBarHidden {
    return NO;
}

- (UIStatusBarStyle)preferredStatusBarStyle{
    return UIStatusBarStyleLightContent;
}

#pragma mark - Private methods

- (void)setPullListButton
{
    _detailView.addToPullListButton.tag = 0;
    [_detailView.addToPullListButton addTarget:self action:@selector(onClick:) forControlEvents:UIControlEventTouchUpInside];
    LBXTitle *title = [LBXPullListTitle MR_findFirstByAttribute:@"titleID" withValue:_detailTitle.titleID];
    if (title) {
        [_detailView.addToPullListButton setTitle:@"     REMOVE FROM PULL LIST     " forState:UIControlStateNormal];
        _detailView.addToPullListButton.layer.borderColor = [[UIColor whiteColor] CGColor];
        addToListToggle = NO;
    }
    else {
        [_detailView.addToPullListButton setTitle:@"     ADD TO PULL LIST     " forState:UIControlStateNormal];
        _detailView.addToPullListButton.layer.borderColor = [[UIColor whiteColor] CGColor];
        addToListToggle = YES;
    }
}

- (IBAction)onClick:(id)sender
{
    UIButton *button = (UIButton *)sender;
    switch ([button tag]) {
        case 0: // Add title to pull list
        {
            if (addToListToggle == NO) {
                LBXTitle *title = [LBXPullListTitle MR_findFirstByAttribute:@"titleID" withValue:_detailTitle.titleID];
                if (title != nil) {
                    [[NSManagedObjectContext MR_defaultContext] deleteObject:title];
                    [[NSManagedObjectContext MR_defaultContext] saveToPersistentStoreAndWait];
                }
                [self deleteTitle:_detailTitle];
                addToListToggle = YES;
                 [_detailView.addToPullListButton setTitle:@"     ADD TO PULL LIST     " forState:UIControlStateNormal];
                [self refresh];
            }
            else if (addToListToggle == YES) {
                addToListToggle = NO;
                [self addTitle:_detailTitle];
                [_detailView.addToPullListButton setTitle:@"     REMOVE FROM PULL LIST     " forState:UIControlStateNormal];
            }
            break;
        }
    }
}

- (void)setDetailTitleWithID:(NSNumber *)ID
{
    _detailTitle = [LBXTitle MR_findFirstByAttribute:@"titleID" withValue:ID];
}

- (void)fetchPullList
{
    // Fetch pull list titles
    [_client fetchPullListWithCompletion:^(NSArray *pullListArray, RKObjectRequestOperation *response, NSError *error) {
        
        if (!error) {
            [self createPullListArray];
        }
        else {
            [LBXMessageBar displayError:error];
        }
//        [self setPullListButton];
        [self.view setNeedsDisplay];
    }];
}

- (void)createPullListArray
{
    _pullListArray = [NSMutableArray arrayWithArray:[NSArray sortedArray:[LBXPullListTitle MR_findAllSortedBy:nil ascending:YES] basedOffObjectProperty:@"name"]];
}

- (void)fetchAllIssues
{
    // Fetch pull list titles
    [_client fetchIssuesForTitle:_detailTitle.titleID withCompletion:^(NSArray *pullListArray, RKObjectRequestOperation *response, NSError *error) {
        
        if (!error) {
            [self createIssuesArray];
        }
        else {
            [LBXMessageBar displayError:error];
        }
        [self.tableView reloadData];
        [self.view setNeedsDisplay];
    }];
}

- (void)createIssuesArray
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat: @"title == %@", _detailTitle];
    _issuesForTitleArray = [LBXIssue MR_findAllSortedBy:@"releaseDate" ascending:NO withPredicate:predicate];
}

- (void)setNavBarAlpha:(NSNumber *)alpha
{
    if (_detailView.latestIssueImageView.image.size.height > 200.0) {
        [self.navigationController.navigationBar setTitleTextAttributes:@{NSForegroundColorAttributeName : [UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:[alpha doubleValue]], NSFontAttributeName : [UIFont navTitleFont]}];
    }
    else {
        [self.navigationController.navigationBar setTitleTextAttributes:@{NSForegroundColorAttributeName : [UIColor blackColor], NSFontAttributeName : [UIFont navTitleFont]}];
    }
}

- (void)addTitle:(LBXTitle *)title
{
    [self.client addTitleToPullList:title.titleID withCompletion:^(NSArray *pullListArray, RKObjectRequestOperation *response, NSError *error) {
        if (!error) {
        }
        else {
            [SVProgressHUD showErrorWithStatus:[NSString stringWithFormat:@"Unable to add %@\n%@", title.name, error.localizedDescription]];
        }
    }];
}

- (void)deleteTitle:(LBXTitle *)title
{
    // Fetch pull list titles
    [self.client removeTitleFromPullList:title.titleID withCompletion:^(NSArray *pullListArray, RKObjectRequestOperation *response, NSError *error) {
        if (!error) {
            _pullListArray = [NSMutableArray arrayWithArray:[NSArray sortedArray:[LBXPullListTitle MR_findAllSortedBy:nil ascending:YES] basedOffObjectProperty:@"name"]];
        }
        else {
            [SVProgressHUD showErrorWithStatus:[NSString stringWithFormat:@"Unable to delete %@\n%@", title.name, error.localizedDescription]];
        }
    }];
}

- (void)refresh
{
    // Fetch pull list titles
    [self.client fetchPullListWithCompletion:^(NSArray *pullListArray, RKObjectRequestOperation *response, NSError *error) {
        
        if (!error) {
            _pullListArray = [NSMutableArray arrayWithArray:[NSArray sortedArray:[LBXPullListTitle MR_findAllSortedBy:nil ascending:YES] basedOffObjectProperty:@"name"]];
        }
        else {
            [LBXMessageBar displayError:error];
        }
    }];
}

#pragma mark - Setter overrides

- (void)setTitleID:(NSNumber *)titleID
{
    _titleID = titleID;
    [self setDetailTitleWithID:titleID];
}

#pragma mark - UITableView Delegate & Datasource

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    if(section == 0)
        return [super tableView:tableView viewForHeaderInSection:section];
    
    return nil;
}

- (void)tableView:(UITableView *)tableView willDisplayHeaderView:(UIView *)view forSection:(NSInteger)section
{
    // Background color
    view.tintColor = [UIColor lightGrayColor];
    
    // Text Color
    UITableViewHeaderFooterView *header = (UITableViewHeaderFooterView *)view;
    [header.textLabel setTextColor:[UIColor blackColor]];
    
    // Another way to set the background color
    // Note: does not preserve gradient effect of original header
    // header.contentView.backgroundColor = [UIColor blackColor];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if(section == 1)
        return @"Issues";
    
    return nil;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    if(section == 0)
        return [super tableView:tableView heightForHeaderInSection:section];
    
    if(section == 1)
        return 20.0;
    
    return 0.0;
}


- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    NSInteger mySections = 1;
    
    return mySections + 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section != 1) {
        return 0;
    }
    if (_issuesForTitleArray.count <= 3) {
        return 3;
    }
    
    return _issuesForTitleArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"PullListCell";
    
    LBXPullListTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (cell == nil) {
        // Custom cell as explained here: https://medium.com/p/9bee5824e722
        [tableView registerNib:[UINib nibWithNibName:@"LBXPullListTableViewCell" bundle:nil] forCellReuseIdentifier:@"PullListCell"];
        cell = [tableView dequeueReusableCellWithIdentifier:@"PullListCell"];
        
        // Remove inset of iOS 7 separators.
        if ([cell respondsToSelector:@selector(setSeparatorInset:)]) {
            cell.separatorInset = UIEdgeInsetsZero;
        }
        
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(LBXPullListTableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Configure the cell...
    if (_issuesForTitleArray.count <= indexPath.row) {
        return;
    }

    LBXIssue *issue = [_issuesForTitleArray objectAtIndex:indexPath.row];
    
    cell.titleLabel.font = [UIFont pullListTitleFont];
    cell.titleLabel.text = issue.completeTitle;
    
    cell.titleLabel.lineBreakMode = NSLineBreakByTruncatingTail;
    cell.titleLabel.numberOfLines = 2;
    
    cell.subtitleLabel.font = [UIFont pullListSubtitleFont];
    cell.subtitleLabel.textColor = [UIColor grayColor];
    cell.subtitleLabel.numberOfLines = 2;
    
    cell.latestIssueImageView.image = nil;
    
    [LBXTitleServices setCell:cell withIssue:issue];
    
    [cell setSelectionStyle:UITableViewCellSelectionStyleGray];
    
    // Setting the background color of the cell.
    cell.contentView.backgroundColor = [UIColor whiteColor];
    
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    if (scrollView.contentOffset.y > 0) {
        [self setNavBarAlpha:@(1 - self.overView.alpha)];
    }
    else {
        [self setNavBarAlpha:@0];
    }
    return [super scrollViewDidScroll:scrollView];
}

@end