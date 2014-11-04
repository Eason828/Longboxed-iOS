//
//  LBXIssueScrollViewController.m
//  Longboxed-iOS
//
//  Created by johnrhickey on 8/23/14.
//  Copyright (c) 2014 Longboxed. All rights reserved.
//

#import "LBXIssueScrollViewController.h"
#import "LBXIssueDetailViewController.h"
#import "LBXControllerServices.h"
#import "LBXClient.h"
#import "LBXMessageBar.h"

#import <Shimmer/FBShimmeringView.h>

@interface LBXIssueScrollViewController ()

@property (nonatomic) NSArray *issues;
@property (nonatomic) UIScrollView *scrollView;
@property (nonatomic) UIImage *issueImage;
@property (nonatomic) LBXIssueDetailViewController *titleViewController;

@end

@implementation LBXIssueScrollViewController

CGRect screenRect;

- (instancetype)initWithIssues:(NSArray *)issues andImage:(UIImage *)image {
    if(self = [super init]) {
        _issues = issues;
        _issueImage = image;
    }
    return self;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    CGRect viewFrame = self.view.frame;
    int navAndStatusHeight = [UIApplication sharedApplication].statusBarFrame.size.height + self.navigationController.navigationBar.frame.size.height;
    viewFrame.origin.y -= navAndStatusHeight;
    viewFrame.size.height += navAndStatusHeight;
    _scrollView = [[UIScrollView alloc] initWithFrame:viewFrame];
    _scrollView.backgroundColor = [UIColor blackColor];
    _scrollView.pagingEnabled = YES;
    _scrollView.bounces = NO;
    _scrollView.indicatorStyle = UIScrollViewIndicatorStyleWhite;
    [self.view addSubview:_scrollView];
    
    screenRect = self.view.bounds;
    CGRect bigRect = screenRect;
    screenRect.origin.x -= screenRect.size.width;
    bigRect.size.width *= (_issues.count);
    _scrollView.contentSize = bigRect.size;
    
    // Set up the first issue
    [self setupIssueViewsWithIssuesArray:@[_issues.firstObject]];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [LBXControllerServices setViewWillAppearClearNavigationController:self];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [LBXControllerServices setViewDidAppearClearNavigationController:self];
    // Set up the rest of the issue variants
    [self setupIssueViewsWithIssuesArray:[_issues subarrayWithRange:NSMakeRange(1, _issues.count-1)]];
}

#pragma mark Private Methods

- (void)setupIssueViewsWithIssuesArray:(NSArray *)issuesArray
{
    for (LBXIssue *issue in issuesArray) {
        screenRect.origin.x += screenRect.size.width;
        _titleViewController = [[LBXIssueDetailViewController alloc] initWithFrame:screenRect andIssue:issue];
        
        if (screenRect.origin.x < screenRect.size.width) {
            _titleViewController.alternativeCoversArrowView.hidden = NO;
            
            FBShimmeringView *shimmeringView = [[FBShimmeringView alloc] initWithFrame:_titleViewController.alternativeCoversArrowView.bounds];
            [_titleViewController.alternativeCoversArrowView addSubview:shimmeringView];
            
            UILabel *loadingLabel = [[UILabel alloc] initWithFrame:_titleViewController.alternativeCoversArrowView.bounds];
            loadingLabel.textColor = [UIColor whiteColor];
            loadingLabel.font = [UIFont fontWithName:@"Mishafi" size:32];
            loadingLabel.text = @"<<<";
            shimmeringView.contentView = loadingLabel;
            
            shimmeringView.shimmeringDirection = FBShimmerDirectionLeft;
            shimmeringView.shimmeringSpeed = 30;
            shimmeringView.shimmeringPauseDuration = 1.8;
            
            // Start shimmering.
            shimmeringView.shimmering = YES;
        }
        
        // Add to the scroll view
        [self addChildViewController:_titleViewController];
        [_scrollView addSubview:_titleViewController.view];
        [_titleViewController didMoveToParentViewController:self];
    }
}

@end
