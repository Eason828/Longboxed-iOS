//
//  LBXTitleServices.m
//  Longboxed-iOS
//
//  Created by johnrhickey on 8/10/14.
//  Copyright (c) 2014 Longboxed. All rights reserved.
//

#import "LBXControllerServices.h"
#import "UIFont+customFonts.h"

#import "NSDate+DateUtilities.h"
#import "UIColor+customColors.h"

#import <UIImageView+AFNetworking.h>
#import <SVProgressHUD.h>
#import <CommonCrypto/CommonDigest.h>

@interface LBXControllerServices ()

@end

@implementation LBXControllerServices

+ (NSDate *)getLocalDate
{
    return [NSDate dateWithTimeInterval:[[NSTimeZone systemTimeZone] secondsFromGMT] sinceDate:[NSDate date]];
}

// This is for the pull list view
+ (NSString *)timeSinceLastIssueForTitle:(LBXTitle *)title
{
    LBXIssue *issue = [self closestIssueForTitle:title];
    
    if (issue != nil) {
        return [NSString stringWithFormat:@"%@", [NSDate fuzzyTimeBetweenStartDate:issue.releaseDate andEndDate:[self getLocalDate]]];
    }
    return @"";
}

// This is for the pull list view
+ (LBXIssue *)closestIssueForTitle:(LBXTitle *)title
{
    if ([title.titleID  isEqual: @586]) {
        
    }
    NSPredicate *predicate = [NSPredicate predicateWithFormat: @"title.titleID == %@", title.titleID];
    NSArray *issuesArray = [LBXIssue MR_findAllSortedBy:@"releaseDate" ascending:NO withPredicate:predicate];
    
    if (issuesArray.count != 0) {
        
        LBXIssue *newestIssue = issuesArray[0];
        
        if (issuesArray.count > 1) {
            LBXIssue *secondNewestIssue = issuesArray[1];
            // Check if the latest issue is next week and the second latest issue is this week
            
            // If the second newest issues release date is more recent than 4 days ago
            if ([secondNewestIssue.releaseDate timeIntervalSinceDate:[self getLocalDate]] > -4*DAY) {
                return secondNewestIssue;
            }
            return newestIssue;
        }
        return newestIssue;
    }
    return nil;
}

+ (NSString *)localTimeZoneStringWithDate:(NSDate *)date
{
    NSDateFormatter *formatter = [NSDateFormatter new];
    [formatter setTimeZone:[NSTimeZone timeZoneWithName:@"GMT"]];
    [formatter setDateStyle:NSDateFormatterLongStyle];
    
    NSNumberFormatter *numFormatter = [[NSNumberFormatter alloc] init];
    [numFormatter setNumberStyle:NSNumberFormatterDecimalStyle];
    [numFormatter setMinimumFractionDigits:2];
    return [formatter stringFromDate:date];
}

+ (NSString *)getSubtitleStringWithTitle:(LBXTitle *)title uppercase:(BOOL)uppercase
{
    NSString *subtitleString = [NSString new];
    switch ([title.subscribers integerValue]) {
        case 1: {
            subtitleString = [NSString stringWithFormat:@"%@ Subscriber", title.subscribers];
            break;
        }
        default: {
            subtitleString = [NSString stringWithFormat:@"%@ Subscribers", title.subscribers];
            break;
        }
    }
    if (uppercase) {
        return subtitleString.uppercaseString;
    }
    return subtitleString;
}

// This is for the publisher list
+ (void)setPublisherCell:(LBXPullListTableViewCell *)cell withTitle:(LBXTitle *)title
{
    cell.titleLabel.text = title.name;
    
    NSString *subtitleString = [self getSubtitleStringWithTitle:title uppercase:YES];
    
    if (title.latestIssue != nil) {
        cell.subtitleLabel.text = subtitleString;
        
        // Get the image from the URL and set it
        [cell.latestIssueImageView setImageWithURLRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:title.latestIssue.coverImage]] placeholderImage:[UIImage imageNamed:@"loadingCoverTransparent"] success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {
            
            [UIView transitionWithView:cell.imageView
                              duration:0.5f
                               options:UIViewAnimationOptionTransitionCrossDissolve
                            animations:^{[cell.latestIssueImageView setImage:image];}
                            completion:NULL];
            
        } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error) {
            cell.latestIssueImageView.image = [UIImage imageNamed:@"NotAvailable.jpeg"];
        }];
    }
    else if (!title.publisher.name) {
        cell.subtitleLabel.text = [[NSString stringWithFormat:@"Loading..."] uppercaseString];
        cell.latestIssueImageView.image = [UIImage imageNamed:@"loadingCoverTransparent"];
    }
    else if (title.latestIssue.title.issueCount == 0) {
        cell.latestIssueImageView.image = [UIImage imageNamed:@"NotAvailable.jpeg"];
        cell.subtitleLabel.text = subtitleString;
    }
    else {
        cell.latestIssueImageView.image = [UIImage imageNamed:@"loadingCoverTransparent"];
        cell.subtitleLabel.text = subtitleString;
    }
}

// This is for the pull list
+ (void)setPullListCell:(LBXPullListTableViewCell *)cell
              withTitle:(LBXTitle *)title
{
    cell.titleLabel.text = title.name;
    if (title.latestIssue) {
        NSString *subtitleString = [NSString stringWithFormat:@"%@  •  %@", title.latestIssue.publisher.name, [LBXControllerServices timeSinceLastIssueForTitle:title]];
        
        cell.subtitleLabel.text = [subtitleString uppercaseString];
        
        // Get the image from the URL and set it
        [cell.latestIssueImageView setImageWithURLRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:title.latestIssue.coverImage]] placeholderImage:[UIImage imageNamed:@"loadingCoverTransparent"] success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {
            
            [UIView transitionWithView:cell.imageView
                              duration:0.5f
                               options:UIViewAnimationOptionTransitionCrossDissolve
                            animations:^{[cell.latestIssueImageView setImage:image];}
                            completion:NULL];
            
        } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error) {
            cell.latestIssueImageView.image = [UIImage imageNamed:@"NotAvailable.jpeg"];
        }];
    }
    else if (!title.publisher.name) {
        cell.subtitleLabel.text = [[NSString stringWithFormat:@"Loading..."] uppercaseString];
        cell.latestIssueImageView.image = [UIImage imageNamed:@"loadingCoverTransparent"];
    }
    else if (!title.latestIssue) {
        cell.subtitleLabel.text = [[NSString stringWithFormat:@"%@", title.publisher.name] uppercaseString];
        cell.latestIssueImageView.image = [UIImage imageNamed:@"NotAvailable.jpeg"];
    }
    else {
        cell.subtitleLabel.text = [[NSString stringWithFormat:@"%@", title.publisher.name] uppercaseString];
        cell.latestIssueImageView.image = [UIImage imageNamed:@"loadingCoverTransparent"];
    }
}

+ (void)darkenCell:(LBXPullListTableViewCell *)cell
{
    // Darken the image
    UIView *overlay = [[UIView alloc] initWithFrame:CGRectMake(0, 0, cell.latestIssueImageView.frame.size.width, cell.latestIssueImageView.frame.size.height*2)];
    [overlay setBackgroundColor:[UIColor colorWithRed:0 green:0 blue:0 alpha:0.3]];
    [cell.latestIssueImageView addSubview:overlay];
    [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
}

// This is for the adding to the pull list
+ (void)setAddToPullListSearchCell:(LBXPullListTableViewCell *)cell
                         withTitle:(LBXTitle *)title
                       darkenImage:(BOOL)darken
{
    cell.titleLabel.text = title.name;
    if (title.latestIssue) {
        NSString *subtitleString = [NSString stringWithFormat:@"%@  •  %@", title.latestIssue.publisher.name, [LBXControllerServices getSubtitleStringWithTitle:title uppercase:YES]];
        
        cell.subtitleLabel.text = [subtitleString uppercaseString];
        
        // Get the image from the URL and set it
        [cell.latestIssueImageView setImageWithURLRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:title.latestIssue.coverImage]] placeholderImage:[UIImage imageNamed:@"loadingCoverTransparent"] success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {
            
            [UIView transitionWithView:cell.imageView
                              duration:0.5f
                               options:UIViewAnimationOptionTransitionCrossDissolve
                            animations:^{[cell.latestIssueImageView setImage:image];}
                            completion:NULL];
            
            if (darken) [self darkenCell:cell];
            
        } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error) {
            cell.latestIssueImageView.image = [UIImage imageNamed:@"NotAvailable.jpeg"];
            if (darken) [self darkenCell:cell];
        }];
    }
    else if (!title.publisher.name) {
        cell.subtitleLabel.text = [[NSString stringWithFormat:@"Loading..."] uppercaseString];
        cell.latestIssueImageView.image = [UIImage imageNamed:@"loadingCoverTransparent"];
    }
    else if (!title.latestIssue) {
        cell.subtitleLabel.text = [[NSString stringWithFormat:@"%@", title.publisher.name] uppercaseString];
        cell.latestIssueImageView.image = [UIImage imageNamed:@"NotAvailable.jpeg"];
    }
    else {
        cell.subtitleLabel.text = [[NSString stringWithFormat:@"%@", title.publisher.name] uppercaseString];
        cell.latestIssueImageView.image = [UIImage imageNamed:@"loadingCoverTransparent"];
    }
    if (darken) [self darkenCell:cell];
}


// This is for the title view
+ (void)setTitleCell:(LBXPullListTableViewCell *)cell withIssue:(LBXIssue *)issue
{
    NSString *subtitleString = [NSString stringWithFormat:@"%@", [self localTimeZoneStringWithDate:issue.releaseDate]];
    
    NSError *error = nil;
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"&#?[a-zA-Z0-9z]+;" options:NSRegularExpressionCaseInsensitive error:&error];
    NSString *modifiedTitleString = [regex stringByReplacingMatchesInString:issue.completeTitle options:0 range:NSMakeRange(0, [issue.completeTitle length]) withTemplate:@""];
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat: @"(issueNumber == %@) AND (title == %@)", issue.issueNumber, issue.title];
    NSArray *initialFind = [LBXIssue MR_findAllSortedBy:@"releaseDate" ascending:NO withPredicate:predicate];
    
    cell.subtitleLabel.text = [NSString stringWithFormat:@"%@  •  %@ variant covers", subtitleString, [NSNumber numberWithLong:initialFind.count - 1]].uppercaseString;
    if (initialFind.count == 1) {
        cell.subtitleLabel.text = [NSString stringWithFormat:@"%@", subtitleString].uppercaseString;
    }
    else if (initialFind.count == 2) {
        cell.subtitleLabel.text = [NSString stringWithFormat:@"%@  •  %@ variant cover", subtitleString, [NSNumber numberWithLong:initialFind.count - 1]].uppercaseString;
    }
    
    cell.titleLabel.text = [NSString stringWithFormat:@"%@", modifiedTitleString];
    
    
    // For issues without a release date
    if ([subtitleString isEqualToString:@"(null)"]) {
        cell.subtitleLabel.text = @"Release Date Unknown";
    }
    
    // Get the image from the URL and set it
    [cell.latestIssueImageView setImageWithURLRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:issue.coverImage]] placeholderImage:[UIImage imageNamed:@"loadingCoverTransparent"] success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {
        
        [UIView transitionWithView:cell.imageView
                          duration:0.5f
                           options:UIViewAnimationOptionTransitionCrossDissolve
                        animations:^{[cell.latestIssueImageView setImage:image];}
                        completion:NULL];
        
    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error) {
        cell.latestIssueImageView.image = [UIImage imageNamed:@"NotAvailable.jpeg"];
    }];
}

+ (void)setLabel:(UILabel *)textView
      withString:(NSString *)string
            font:(UIFont *)font
  inBoundsOfView:(UIView *)view
{
    textView.font = font;
    
    NSMutableParagraphStyle *textStyle = [[NSMutableParagraphStyle defaultParagraphStyle] mutableCopy];
    textStyle.lineBreakMode = NSLineBreakByWordWrapping;
    textStyle.alignment = NSTextAlignmentCenter;
    
    NSDictionary *attributes = @{NSFontAttributeName:font, NSParagraphStyleAttributeName: textStyle};
    CGRect bound = [string boundingRectWithSize:CGSizeMake(view.bounds.size.width-30, view.bounds.size.height) options:NSStringDrawingUsesLineFragmentOrigin attributes:attributes context:nil];
    
    textView.numberOfLines = 2;
    textView.bounds = bound;
    textView.text = string;
}

+ (UIImage *)generateImageForPublisher:(LBXPublisher *)publisher size:(CGSize)size
{
    // Set the background color to the gradient
    UIColor *primaryColor;
    if (publisher.primaryColor) {
        primaryColor = [UIColor colorWithHex:publisher.primaryColor];
    }
    else {
        primaryColor = [UIColor lightGrayColor];
    }
    
    UIColor *secondaryColor;
    if (publisher.secondaryColor) {
        secondaryColor = [UIColor colorWithHex:publisher.secondaryColor];
    }
    else {
        secondaryColor = [UIColor lightGrayColor];
    }
    
    UIGraphicsBeginImageContext(size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGColorSpaceRef colorspace = CGColorSpaceCreateDeviceRGB();
    size_t gradientNumberOfLocations = 2;
    CGFloat gradientLocations[2] = { 0.0, 1.0 };
    CGFloat gradientComponents[8] = {CGColorGetComponents(primaryColor.CGColor)[0], CGColorGetComponents(primaryColor.CGColor)[1], CGColorGetComponents(primaryColor.CGColor)[2], 1.0,     // Start color
        CGColorGetComponents(secondaryColor.CGColor)[0], CGColorGetComponents(secondaryColor.CGColor)[1], CGColorGetComponents(secondaryColor.CGColor)[2], 1.0, };  // End color
    CGGradientRef gradient = CGGradientCreateWithColorComponents (colorspace, gradientComponents, gradientLocations, gradientNumberOfLocations);
    CGContextDrawLinearGradient(context, gradient, CGPointMake(0, 0), CGPointMake(0, size.height), 0);
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

+ (NSString *)getHashOfImage:(UIImage *)image
{
    unsigned char result[CC_MD5_DIGEST_LENGTH];
    NSData *imageData = [NSData dataWithData:UIImagePNGRepresentation(image)];
    CC_MD5([imageData bytes], (uint)[imageData length], result);
    return [NSString stringWithFormat:
            @"%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X",
            result[0], result[1], result[2], result[3],
            result[4], result[5], result[6], result[7],
            result[8], result[9], result[10], result[11],
            result[12], result[13], result[14], result[15]
            ];
}

+ (NSArray *)refreshTableView:(UITableView *)tableView withOldSearchResults:(NSArray *)oldResultsArray
                   newResults:(NSArray *)newResultsArray
                    animation:(UITableViewRowAnimation)animation
{
    NSArray *returnArray = [NSArray new];
    // If rows are removed
    if (newResultsArray.count < oldResultsArray.count && oldResultsArray.count) {
        NSMutableArray *diferentIndexes = [NSMutableArray new];
        for (int i = 0; i < newResultsArray.count; i++) {
            if (oldResultsArray[i] != newResultsArray[i]) { //Maybe add "&& newSearchResultsArray.count" here
                [diferentIndexes addObject:[NSIndexPath indexPathForRow:i inSection:0]];
            }
        }
        
        NSMutableArray *oldIndexes = [NSMutableArray new];
        if (newResultsArray.count < oldResultsArray.count) {
            for (NSUInteger i = newResultsArray.count; i < oldResultsArray.count; i++) {
                [oldIndexes addObject:[NSIndexPath indexPathForRow:i inSection:0]];
            }
        }
        
        // Update the table view
        [tableView beginUpdates];
        [tableView numberOfRowsInSection:newResultsArray.count];
        [tableView deleteRowsAtIndexPaths:oldIndexes withRowAnimation:animation];
        
        returnArray = [[NSArray alloc] initWithArray:newResultsArray];
        [tableView endUpdates];
    }
    
    
    // If rows are added
    else if (newResultsArray.count > oldResultsArray.count && oldResultsArray.count != 0) {
        NSMutableArray *diferentIndexes = [NSMutableArray new];
        for (int i = 0; i < oldResultsArray.count; i++) {
            if (oldResultsArray[i] != newResultsArray[i]) { //Maybe add "&& newSearchResultsArray.count" here
                [diferentIndexes addObject:[NSIndexPath indexPathForRow:i inSection:0]];
            }
        }
        NSMutableArray *newIndexes = [NSMutableArray new];
        if (newResultsArray.count > oldResultsArray.count) {
            NSUInteger index;
            if (!oldResultsArray.count) index = 0; else index = oldResultsArray.count;
            for (NSUInteger i = index; i < newResultsArray.count; i++) {
                [newIndexes addObject:[NSIndexPath indexPathForRow:i inSection:0]];
            }
        }
        
        // Update the table view
        [tableView beginUpdates];
        [tableView insertRowsAtIndexPaths:newIndexes withRowAnimation:animation];
        returnArray = [[NSArray alloc] initWithArray:newResultsArray];
        [tableView endUpdates];
    }
    
    // Rows are just changed
    else if (newResultsArray.count == oldResultsArray.count && oldResultsArray.count != 0) {
        NSMutableArray *diferentIndexes = [NSMutableArray new];
        for (int i = 0; i < oldResultsArray.count; i++) {
            if (oldResultsArray[i] != newResultsArray[i]) { //Maybe add "&& newSearchResultsArray.count" here
                [diferentIndexes addObject:[NSIndexPath indexPathForRow:i inSection:0]];
            }
        }
        
        // Update the table view
        [tableView beginUpdates];
        [tableView reloadRowsAtIndexPaths:diferentIndexes withRowAnimation:animation];
        returnArray = [[NSArray alloc] initWithArray:newResultsArray];
        [tableView endUpdates];
    }
    
    // If entire view needs refreshed
    else if (oldResultsArray.count == 0) {
        dispatch_async(dispatch_get_main_queue(),^{
            [tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:animation];
        });
        returnArray = [[NSArray alloc] initWithArray:newResultsArray];
    }
    
    return returnArray;
}

@end