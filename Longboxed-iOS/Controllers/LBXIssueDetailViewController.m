//
//  LBXIssueDetailViewController.m
//  Longboxed-iOS
//
//  Created by johnrhickey on 8/19/14.
//  Copyright (c) 2014 Longboxed. All rights reserved.
//

#import "LBXIssueDetailViewController.h"

#import "LBXTitleServices.h"

#import "UIImageView+LBBlurredImage.h"
#import "UIFont+customFonts.h"
#import "UIImage+ImageEffects.h"
#import "PaperButton.h"

#import <FontAwesomeKit/FontAwesomeKit.h>
#import <JTSImageViewController.h>

@interface LBXIssueDetailViewController ()

@property (nonatomic) IBOutlet UIImageView *backgroundCoverImageView;
@property (nonatomic) IBOutlet UITextView *descriptionTextView;
@property (nonatomic) IBOutlet UIImageView *coverImageView;
@property (nonatomic) IBOutlet UILabel *titleLabel;
@property (nonatomic) IBOutlet UILabel *publisherLabel;
@property (nonatomic) IBOutlet UILabel *releaseDateLabel;
@property (nonatomic) IBOutlet UILabel *priceLabel;
@property (nonatomic) IBOutlet UILabel *distributorCodeLabel;
@property (nonatomic) IBOutlet UIButton *imageButton;
@property (nonatomic) PaperButton *closeButton;
@property (nonatomic, copy) UIImage *issueImage;
@property (nonatomic, copy) LBXIssue *issue;

@end

@implementation LBXIssueDetailViewController

- (instancetype)initWithMainImage:(UIImage *)image {
    if(self = [super init]) {
        _issueImage = [image copy];
        _backgroundCoverImageView = [UIImageView new];
        _descriptionTextView = [UITextView new];
        _coverImageView = [UIImageView new];
        
        // Set up pop close button
        _closeButton = [PaperButton button];
        _closeButton.frame = CGRectMake(_closeButton.frame.origin.x, _closeButton.frame.origin.y, 66, 66);
        _closeButton.tintColor = [UIColor whiteColor];
        [_closeButton addTarget:self action:@selector(buttonPressed:) forControlEvents:UIControlEventTouchUpInside];
        _closeButton.tag = 0;
        [self.view insertSubview:_closeButton aboveSubview:_imageButton];
        [_closeButton animateToClose];
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

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    self.navigationController.navigationBar.barStyle = UIBarStyleBlackTranslucent;
    
    [_backgroundCoverImageView setImageToBlur:_issueImage blurRadius:kLBBlurredImageDefaultBlurRadius completionBlock:nil];
    [_issueImage applyDarkEffect];
    
    UIImage *blurredImage = [_issueImage applyBlurWithRadius:0.0
                                             tintColor:[UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:0.3]
                                 saturationDeltaFactor:0.5
                                             maskImage:nil];
    
    [_coverImageView setImage:blurredImage];
    
    
    _issue = [LBXIssue MR_findFirstByAttribute:@"issueID" withValue:_issueID];
    NSLog(@"Selected issue %@", _issue.issueID);
    
    _titleLabel.text = _issue.completeTitle;
    _publisherLabel.text = _issue.publisher.name.uppercaseString;
    _releaseDateLabel.text = [LBXTitleServices localTimeZoneStringWithDate:_issue.releaseDate].uppercaseString;
    _priceLabel.text = [NSString stringWithFormat:@"$%.02f", [_issue.price floatValue]].uppercaseString;
    _distributorCodeLabel.text = _issue.diamondID.uppercaseString;
    
    NSString *string = _issue.issueDescription;
    NSError *error = nil;
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"&#[0-9]+;" options:NSRegularExpressionCaseInsensitive error:&error];
    NSString *modifiedString = [regex stringByReplacingMatchesInString:string options:0 range:NSMakeRange(0, [string length]) withTemplate:@""];
    _descriptionTextView.text = modifiedString;
    
    CGRect boundingRect = [modifiedString boundingRectWithSize:CGSizeMake(self.view.frame.size.width - 20, CGFLOAT_MAX)
                                             options:NSStringDrawingUsesLineFragmentOrigin
                                                    attributes: @{NSFontAttributeName : [UIFont titleDetailSubscribersAndIssuesFont]}
                                             context:nil];
    
    [_descriptionTextView setTranslatesAutoresizingMaskIntoConstraints:NO];
    [_descriptionTextView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:[NSString stringWithFormat:@"V:[_descriptionTextView(==%d)]", (int)boundingRect.size.height+20]
                                                                                 options:0
                                                                                 metrics:nil
                                                                                   views:NSDictionaryOfVariableBindings(_descriptionTextView)]];
    
    [_imageButton addTarget:self action:@selector(buttonPressed:) forControlEvents:UIControlEventTouchUpInside];
    _imageButton.tag = 1;

}

- (void)viewDidLoad
{
    [super viewDidLoad];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    self.navigationController.navigationBar.topItem.title = _issue.title.name;
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)buttonPressed:(UIButton *)sender
{
    UIButton *button = (UIButton *)sender;
    
    switch ([button tag]) {
        case 0: // First actor button
        {
            [self dismissViewControllerAnimated:YES completion:nil];
            break;
        }
            
        case 1: // Second actor button
        {
            // Create image info
            JTSImageInfo *imageInfo = [[JTSImageInfo alloc] init];
            imageInfo.image = _coverImageView.image;
            imageInfo.referenceRect = _imageButton.frame;
            imageInfo.referenceView = _imageButton.superview;
            
            // Setup view controller
            JTSImageViewController *imageViewer = [[JTSImageViewController alloc]
                                                   initWithImageInfo:imageInfo
                                                   mode:JTSImageViewControllerMode_Image
                                                   backgroundStyle:JTSImageViewControllerBackgroundStyle_ScaledDimmedBlurred];
            
            // Present the view controller.
            [imageViewer showFromViewController:self transition:JTSImageViewControllerTransition_FromOriginalPosition];
            break;
        }
    }
}

@end
