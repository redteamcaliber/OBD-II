//
//  ISSCTableAlertView.m
//  MFiAudioAPP
//
//  Created by Rick on 13/10/4.
//  Copyright (c) 2013年 ISSC. All rights reserved.
//

#import "ISSCTableAlertView.h"
#import "ILAlertView.h"

#define MAX_VISIBLE_ROWS 5

@interface ISSCTableAlertView ()<UITableViewDelegate, UITableViewDataSource> {
    UIAlertView *_alertView;
    ILAlertView *_alertView7;
    NSUInteger tableHeight;
}
@end

@implementation ISSCTableAlertView
-(id)initWithCaller:(id<TableAlertViewDelegate>)caller data:(NSArray*)data
              title:(NSString*)title buttonTitle:(NSString *)buttonTitle andContext:(id)context{
    self = [super init];
    tableHeight = 0;
    NSMutableString *msgString = [NSMutableString string];
    if([data count] >= MAX_VISIBLE_ROWS){
        tableHeight = 225;
        msgString = (NSMutableString *)@"\n\n\n\n\n\n\n\n\n\n\n\n";
    }
    else{
        tableHeight = [data count]*50;
        [msgString appendString:@"\n\n"];
        for(id value in data){
            [msgString appendString:@"\n\n"];
        }
        if([data count] == 1){
            tableHeight +=5;
        }
        if([data count] == MAX_VISIBLE_ROWS-1){
            tableHeight -=15;
        }
    }
    if (floor(NSFoundationVersionNumber) > NSFoundationVersionNumber_iOS_6_1) {
        NSLog(@"%d",self.retainCount);
        __block ISSCTableAlertView *weak_self = self;
        NSLog(@"%d",self.retainCount);

        _alertView7 = [[ILAlertView alloc] initWithTitle:title message:msgString closeButtonTitle:buttonTitle secondButtonTitle:nil tappedSecondButton:^(NSInteger index){
            if (_caller && [_caller respondsToSelector:@selector(didSelectRowAtIndex:withContext:)])
                [_caller didSelectRowAtIndex:-1 withContext:_context];
            [weak_self performSelector:@selector(release) withObject:nil afterDelay:0.5];
            NSLog(@"%d",weak_self.retainCount);
        }];
    }
    else {
       _alertView = [[UIAlertView alloc] initWithTitle:title message:msgString
                    delegate:self cancelButtonTitle:buttonTitle
                                     otherButtonTitles:nil];
    }
    self.caller = caller;
    self.context = context;
    self.data = data;
    [self prepare];
    return self;
}

- (void)show {
    if (floor(NSFoundationVersionNumber) > NSFoundationVersionNumber_iOS_6_1) {
        [_alertView7 showAlertAnimated:YES];
    }
    else {
        _alertView.hidden = YES;
        [NSTimer scheduledTimerWithTimeInterval:.1 target:self
                                       selector:@selector(myTimer:) userInfo:nil repeats:NO];
        [_alertView show];
    }
    [self retain];
}

-(void)myTimer:(NSTimer*)_timer{
    _alertView.hidden = NO;
    if([_data count] > MAX_VISIBLE_ROWS){
        [_myTableView flashScrollIndicators];
    }
}

-(void)prepare{
    if (floor(NSFoundationVersionNumber) > NSFoundationVersionNumber_iOS_6_1) {
        _myTableView = [[UITableView alloc] initWithFrame:CGRectMake(15, 45, 255, tableHeight)
                                                    style:UITableViewStylePlain];
        [_myTableView setSeparatorInset:UIEdgeInsetsZero];
    }
    else {
    _myTableView = [[UITableView alloc] initWithFrame:CGRectMake(15, 50, 255, tableHeight+10)
                                               style:UITableViewStyleGrouped];
    }
    _myTableView.backgroundColor = [UIColor clearColor];
    if([_data count] < MAX_VISIBLE_ROWS){
        _myTableView.scrollEnabled = NO;
    }
    _myTableView.delegate = self;
    _myTableView.dataSource = self;
    if (floor(NSFoundationVersionNumber) > NSFoundationVersionNumber_iOS_6_1) {
        [_alertView7 addSubview:_myTableView];
    }
    else {
        [_alertView addSubview:_myTableView];
    }
}

- (void)dismissWithClickedButtonIndex:(NSInteger)buttonIndex animated:(BOOL)animated {
    if (floor(NSFoundationVersionNumber) > NSFoundationVersionNumber_iOS_6_1) {
        [_alertView7 dismissAlertAnimated:animated];
        [self performSelector:@selector(release) withObject:nil afterDelay:0.5];
    }
    else {
        [_alertView dismissWithClickedButtonIndex:buttonIndex animated:animated];
    }

}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    NSLog(@"clickedButtonAtIndex = %d", buttonIndex);
    if (buttonIndex == [alertView cancelButtonIndex]) {
        if (_caller && [_caller respondsToSelector:@selector(didSelectRowAtIndex:withContext:)])
            [_caller didSelectRowAtIndex:-1 withContext:_context];
    }
    [self performSelector:@selector(release) withObject:nil afterDelay:0.5];
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    static NSString  *cellID = @"ABC";
    UITableViewCell *cell =
    (UITableViewCell*) [tableView dequeueReusableCellWithIdentifier:cellID];
	if (cell == nil) {
		cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                       reuseIdentifier:cellID] autorelease];
		cell.selectionStyle = UITableViewCellSelectionStyleBlue;
    }
    cell.textLabel.text = [[_data objectAtIndex:indexPath.row] description];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    if (floor(NSFoundationVersionNumber) > NSFoundationVersionNumber_iOS_6_1) {
        [_alertView7 dismiss];
    }
    else {
        [_alertView dismissWithClickedButtonIndex:5 animated:YES];
    }
    [self performSelector:@selector(release) withObject:nil afterDelay:0.5];
    if (_caller && [_caller respondsToSelector:@selector(didSelectRowAtIndex:withContext:)])
        [_caller didSelectRowAtIndex:indexPath.row withContext:_context];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return [_data count];
}

-(void)dealloc{
    self.data = nil;
    self.caller = nil;
    self.context = nil;
    [_myTableView release];
    if (floor(NSFoundationVersionNumber) > NSFoundationVersionNumber_iOS_6_1) {
        [_alertView7 release];
    }
    else {
        [_alertView release];
    }
    [super dealloc];
}

@end
