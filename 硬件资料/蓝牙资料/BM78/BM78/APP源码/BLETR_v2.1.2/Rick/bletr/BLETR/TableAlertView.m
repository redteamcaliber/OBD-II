//
//  TableAlertView.m
//  BLEDKAPP
//
//  Created by d500_MacMini on 12/9/28.
//  Copyright (c) 2012 ISSC Technologies Corporation. All rights reserved.
//

#import "TableAlertView.h"

#define MAX_VISIBLE_ROWS 5

@implementation TableAlertView

@synthesize  caller, context, data;

-(id)initWithCaller:(id<TableAlertViewDelegate>)_caller data:(NSArray*)_data
              title:(NSString*)_title buttonTitle:(NSString *) _buttonTitle andContext:(id)_context{
    tableHeight = 0;
    NSMutableString *msgString = [NSMutableString string];
    if([_data count] >= MAX_VISIBLE_ROWS){
        tableHeight = 225;
        msgString = (NSMutableString *)@"\n\n\n\n\n\n\n\n\n\n";
    }
    else{
        tableHeight = [_data count]*50;
        for(id value in _data){
            [msgString appendString:@"\n\n"];
        }
        if([_data count] == 1){
            tableHeight +=5;
        }
        if([_data count] == MAX_VISIBLE_ROWS-1){
            tableHeight -=15;
        }
    }
    if(self = [super initWithTitle:_title message:msgString
                          delegate:self cancelButtonTitle:_buttonTitle
                 otherButtonTitles:nil]){
        self.caller = _caller;
        self.context = _context;
        self.data = _data;
        [self prepare];
    }
    return self;
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
  //  [self.caller didSelectRowAtIndex:-1 withContext:self.context];
}

-(void)show{
    self.hidden = YES;
    [NSTimer scheduledTimerWithTimeInterval:.1 target:self
                                   selector:@selector(myTimer:) userInfo:nil repeats:NO];
    [super show];
}

-(void)myTimer:(NSTimer*)_timer{
    self.hidden = NO;
    if([data count] > MAX_VISIBLE_ROWS){
        [myTableView flashScrollIndicators];
    }
}

-(void)prepare{
    myTableView = [[UITableView alloc] initWithFrame:CGRectMake(15, 35, 255, tableHeight)
                                               style:UITableViewStyleGrouped];
    myTableView.backgroundColor = [UIColor clearColor];
    if([data count] < MAX_VISIBLE_ROWS){
        myTableView.scrollEnabled = NO;
    }
    myTableView.delegate = self;
    myTableView.dataSource = self;
    [self addSubview:myTableView];
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
    cell.textLabel.text = [[data objectAtIndex:indexPath.row] description];
    return cell;
}

- (void)dismissWithClickedButtonIndex:(NSInteger)buttonIndex animated:(BOOL)animated {
    if (buttonIndex == 0) {
        [self.caller didSelectRowAtIndex:-1 withContext:self.context];
    }
    [super dismissWithClickedButtonIndex:0 animated:animated];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    [self dismissWithClickedButtonIndex:5 animated:YES];
    [self.caller didSelectRowAtIndex:indexPath.row withContext:self.context];
}

- (NSInteger)tableView:(UITableView *)tableView
 numberOfRowsInSection:(NSInteger)section {
	return [data count];
}

-(void)dealloc{
    self.data = nil;
    self.caller = nil;
    self.context = nil;
    [myTableView release];
    [super dealloc];
}

@end
