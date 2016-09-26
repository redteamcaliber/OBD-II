//
//  ISLogView.m
//  AutoTest
//
//  Created by Rick on 13/12/26.
//  Copyright (c) 2013年 Rick. All rights reserved.
//

#import "ISLogView.h"
#import "ISSCButton.h"
#import "ISProcessController.h"

@interface UITextView(ISSCAddon)
- (void)addText:(NSString *)t;
@end

@implementation UITextView(ISSCAddon)

- (void)addText:(NSString *)t {
    if (!self.text) {
        self.text = @"";
    }
    if (self.text.length > 20000) {
        self.text = [self.text substringFromIndex:self.text.length-20000];
    }
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"HH:mm:ss.SSS"];
    [formatter setTimeZone:[NSTimeZone localTimeZone]];
    if ([t hasPrefix:@"*******"]) {
        self.text = [self.text stringByAppendingString:t];
    }
    else {
        self.text = [self.text stringByAppendingFormat:@"%@ %@\n",[formatter stringFromDate:[NSDate date]],t];
    }
    [self scrollRangeToVisible:/*[self.text rangeOfString:t options:NSBackwardsSearch]*/NSMakeRange(self.text.length-1, 1)];
}

@end

@interface ISLogView () {
    UITextView *scrollText;
    UIButton *upload;
    UIButton *done;
    NSMutableString *logText;
    UILabel *stepLabel;
}

@end
@implementation ISLogView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor colorWithWhite:0.2 alpha:0.8];
        UIView *header = [[UIView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 300.0f, 300.0f)];
        header.center = CGPointMake(self.frame.size.width/2, self.frame.size.height/2);
        header.backgroundColor = [UIColor colorWithWhite:0.1f alpha:1.0f];
        [header.layer setCornerRadius:5.0f];
        //_table.tableHeaderView = header;
        header.autoresizingMask = UIViewAutoresizingFlexibleTopMargin;
        [self addSubview:header];
        if (floor(NSFoundationVersionNumber) > NSFoundationVersionNumber_iOS_6_1) {
            NSTextStorage* textStorage = [[NSTextStorage alloc] init];
            NSLayoutManager* layoutManager = [NSLayoutManager new];
            [textStorage addLayoutManager:layoutManager];
            NSTextContainer *textContainer = [[NSTextContainer alloc] initWithSize:self.bounds.size];
            [layoutManager addTextContainer:textContainer];
            scrollText = [[UITextView alloc] initWithFrame:CGRectMake(5.0f, 5.0f, 290.0f, 290.0f) textContainer:textContainer];
        }
        else {
            scrollText = [[UITextView alloc] initWithFrame:CGRectMake(5.0f, 5.0f, 290.0f, 290.0f)];
        }
        scrollText.textAlignment = NSTextAlignmentLeft;
        scrollText.backgroundColor = [UIColor clearColor];
        scrollText.font = [UIFont boldSystemFontOfSize:12.0f];
        scrollText.textColor = [UIColor whiteColor];
        scrollText.editable = NO;
        [header addSubview:scrollText];
        /*upload = [ISSCButton buttonWithType:UIButtonTypeCustom];
        [upload setTitle:@"Upload" forState:UIControlStateNormal];
        upload.frame = CGRectMake(45.0f, self.bounds.size.height-65.0f, 100.0f, 30.0f);
        upload.autoresizingMask = UIViewAutoresizingFlexibleTopMargin;
        [upload addTarget:self action:@selector(upload:) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:upload];*/
        
       done = [ISSCButton buttonWithType:UIButtonTypeCustom];
        [done setTitle:@"Cancel" forState:UIControlStateNormal];
        done.frame = CGRectMake(110.0f, self.bounds.size.height-65.0f, 100.0f, 30.0f);
        done.autoresizingMask = UIViewAutoresizingFlexibleTopMargin;
        [self addSubview:done];
        [done addTarget:self action:@selector(cancel:) forControlEvents:UIControlEventTouchUpInside];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(log:) name:Log_Notification object:nil];
        logText = [[NSMutableString alloc] init];
        
        stepLabel = [[UILabel alloc] initWithFrame:CGRectMake(10.0f, 70.0f, 300.0f, 30.0f)];
        stepLabel.textColor = [UIColor whiteColor];
        stepLabel.backgroundColor = [UIColor clearColor];
        [self addSubview:stepLabel];
    }
    return self;
}

- (void)log:(NSNotification *)notification {
    NSDictionary *userInfo = notification.userInfo;
    if (userInfo[@"Value"]) {
        [scrollText addText:[notification.userInfo objectForKey:@"Value"]];
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        [formatter setDateFormat:@"HH:mm:ss.SSS"];
        [formatter setTimeZone:[NSTimeZone localTimeZone]];
        if ([[notification.userInfo objectForKey:@"Value"] hasPrefix:@"******"]) {
            [logText appendString:[notification.userInfo objectForKey:@"Value"]];
        }
        else {
            [logText appendFormat:@"%@ %@\n",[formatter stringFromDate:[NSDate date]],[notification.userInfo objectForKey:@"Value"]];
        }
    }
    if (userInfo[@"Step"]) {
        NSDictionary *dis = userInfo[@"Step"];
        stepLabel.text = [NSString stringWithFormat:@"Total:%@ Now:%@ Success:%@",dis[@"total"],dis[@"now"],dis[@"success"]];
    }
    if (userInfo[@"Done"]) {
        [done removeTarget:self action:@selector(cancel:) forControlEvents:UIControlEventTouchUpInside];
        [done addTarget:self action:@selector(done:) forControlEvents:UIControlEventTouchUpInside];
        [done setTitle:@"Done" forState:UIControlStateNormal];
    }
}

- (void)done:(UIButton *)sender {
    [UIView animateWithDuration:1.0 animations:^{
        self.alpha = 0.0f;
    } completion:^(BOOL finished) {
        [[ISProcessController sharedInstance] stop];
        [self removeFromSuperview];
        [[NSNotificationCenter defaultCenter] removeObserver:self name:Log_Notification object:nil];
    }];
    NSData *output_data = [logText dataUsingEncoding:NSUTF8StringEncoding];
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"'Log_'yyyyMMdd_HHmmss'.log'"];
    NSString *file = [NSString stringWithFormat:@"%@/%@",documentsDirectory,[formatter stringFromDate:[NSDate date]]];
    [output_data writeToFile:file atomically:NO];
}

- (void)cancel:(UIButton *)sender {
    [[ISProcessController sharedInstance] cancel];
}

@end
