//
//  ISRootViewController.m
//  AutoTest
//
//  Created by Rick on 13/12/18.
//  Copyright (c) 2013年 Rick. All rights reserved.
//

#import "ISRootViewController.h"
#import "SlidingTabsControl.h"
#import "ISSCButton.h"
#import "ISSettingViewController.h"
#import "ISLogView.h"
#import "ISProcessController.h"
#import "ISControlManager.h"

static int connectTable[5] = {10,50,100,500,5000};
static int dataTable[4] = {100,1024,10240,51200};

@interface ISRootViewController () <SlidingTabsControlDelegate,UITableViewDataSource,UITableViewDelegate> {
    UIView *_currentSettingView;
    UIView *_connectView;
    UIView *_dataView;
    UIView *_specialView;
    NSMutableDictionary *_connectData;
    NSMutableDictionary *_transferData;
    NSMutableDictionary *_specialData;
}

@end

@implementation ISRootViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        self.wantsFullScreenLayout = YES;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor whiteColor];
    if (![[NSUserDefaults standardUserDefaults] objectForKey:@"TestCase_Connect"]) {
        NSArray *array = [NSArray array];
        [[NSUserDefaults standardUserDefaults] setObject:array forKey:@"TestCase_Connect"];
        [[NSUserDefaults standardUserDefaults] setObject:array forKey:@"TestCase_Transfer"];
        [[NSUserDefaults standardUserDefaults] setObject:array forKey:@"TestCase_Special"];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
    if (![[NSUserDefaults standardUserDefaults] objectForKey:@"StopWhenFail"]) {
        [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"StopWhenFail"];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
    _connectData = [NSMutableDictionary dictionary];
    _transferData = [NSMutableDictionary dictionary];
    _specialData = [NSMutableDictionary dictionary];
    /*NSArray *array = [[NSUserDefaults standardUserDefaults] objectForKey:@"TestCase_Connect"];
    for (NSNumber *number in array) {
        [_connectData setObject:@(YES) forKey:[number stringValue]];
    }
    array = [[NSUserDefaults standardUserDefaults] objectForKey:@"TestCase_Transfer"];
    for (NSDictionary *dis in array) {
        [_transferData setObject:@(YES) forKey:[[dis objectForKey:@"Size"] stringValue]];
    }*/
    SlidingTabsControl *tab = [[SlidingTabsControl alloc] initWithTabCount:3 delegate:self];
    UIScrollView *scroll = [[UIScrollView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 320.0f, 60.0f)];
    scroll.contentSize = CGSizeMake(tab.bounds.size.width, scroll.bounds.size.height);
    scroll.bounces = NO;
    [scroll addSubview:tab];
    [self.view addSubview:scroll];
    _currentSettingView = [[UIView alloc] initWithFrame:CGRectMake(0.0f, 60.0f, self.view.bounds.size.width, self.view.bounds.size.height-60.0f-40.0f)];
    _currentSettingView.autoresizingMask = UIViewAutoresizingFlexibleHeight;
    _currentSettingView.tag = 1;
    [self.view addSubview:_currentSettingView];
    UITableView *_table = [[UITableView alloc] initWithFrame:_currentSettingView.bounds style:UITableViewStylePlain];
    _table.dataSource = self;
    _table.delegate = self;
    _table.autoresizingMask = UIViewAutoresizingFlexibleHeight;
    _table.tag = 1;
    [_currentSettingView addSubview:_table];
    
    _connectView = [[UIView alloc] initWithFrame:CGRectMake(0.0f, 60.0f, self.view.bounds.size.width, self.view.bounds.size.height-60.0f-40.0f)];
    _connectView.autoresizingMask = UIViewAutoresizingFlexibleHeight;
    _connectView.tag = 2;
    _connectView.hidden = YES;
    _connectView.backgroundColor = [UIColor redColor];
    _table = [[UITableView alloc] initWithFrame:_connectView.bounds style:UITableViewStylePlain];
    _table.dataSource = self;
    _table.delegate = self;
    _table.autoresizingMask = UIViewAutoresizingFlexibleHeight;
    _table.tag = 2;
    [_connectView addSubview:_table];
    [self.view addSubview:_connectView];
    
    _dataView = [[UIView alloc] initWithFrame:CGRectMake(0.0f, 60.0f, self.view.bounds.size.width, self.view.bounds.size.height-60.0f-40.0f)];
    _dataView.autoresizingMask = UIViewAutoresizingFlexibleHeight;
    _dataView.tag = 3;
    _dataView.hidden = YES;
    _dataView.backgroundColor = [UIColor yellowColor];
    _table = [[UITableView alloc] initWithFrame:_dataView.bounds style:UITableViewStylePlain];
    _table.dataSource = self;
    _table.delegate = self;
    _table.autoresizingMask = UIViewAutoresizingFlexibleHeight;
    _table.tag = 3;
    [_dataView addSubview:_table];
    [self.view addSubview:_dataView];

    _specialView = [[UIView alloc] initWithFrame:CGRectMake(0.0f, 60.0f, self.view.bounds.size.width, self.view.bounds.size.height-60.0f-40.0f)];
    _specialView.autoresizingMask = UIViewAutoresizingFlexibleHeight;
    _specialView.tag = 4;
    _specialView.hidden = YES;
    _specialView.backgroundColor = [UIColor yellowColor];
    _table = [[UITableView alloc] initWithFrame:_specialView.bounds style:UITableViewStylePlain];
    _table.dataSource = self;
    _table.delegate = self;
    _table.autoresizingMask = UIViewAutoresizingFlexibleHeight;
    _table.tag = 4;
    [_specialView addSubview:_table];
    [self.view addSubview:_specialView];

    UIButton *run = [ISSCButton buttonWithType:UIButtonTypeCustom];
    [run setTitle:@"Run" forState:UIControlStateNormal];
    run.frame = CGRectMake(111.0f, self.view.bounds.size.height-35.0f, 100.0f, 30.0f);
    run.autoresizingMask = UIViewAutoresizingFlexibleTopMargin;
    [run addTarget:self action:@selector(run:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:run];
    
    UIButton *setting = [ISSCButton buttonWithType:UIButtonTypeCustom];
    [setting setTitle:@"Setting" forState:UIControlStateNormal];
    setting.frame = CGRectMake(216.0f, self.view.bounds.size.height-35.0f, 100.0f, 30.0f);
    setting.autoresizingMask = UIViewAutoresizingFlexibleTopMargin;
    [self.view addSubview:setting];
    [setting addTarget:self action:@selector(setting:) forControlEvents:UIControlEventTouchUpInside];
    
    UIButton *back = [ISSCButton buttonWithType:UIButtonTypeCustom];
    [back setTitle:@"Back" forState:UIControlStateNormal];
    back.frame = CGRectMake(5.0f, self.view.bounds.size.height-35.0f, 100.0f, 30.0f);
    back.autoresizingMask = UIViewAutoresizingFlexibleTopMargin;
    [self.view addSubview:back];
    [back addTarget:self action:@selector(back) forControlEvents:UIControlEventTouchUpInside];

    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)setting:(UIButton *)sender {
    [self saveTestCase];
    ISSettingViewController *stView = [[ISSettingViewController alloc] init];
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:stView];
    [nav.view setBackgroundColor:[UIColor whiteColor]];
    [self presentViewController:nav animated:YES completion:nil];
}

- (void)back {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)saveTestCase {
    NSMutableArray *array = [NSMutableArray array];
    for (NSString *s in [_connectData allKeys]) {
        [array addObject:[NSNumber numberWithInt:[s intValue]]];
    }
    [array sortUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        if ([obj1 integerValue] > [obj2 integerValue])
            return NSOrderedDescending;
        else if ([obj1 integerValue] < [obj2 integerValue])
            return NSOrderedAscending;
        else
            return NSOrderedSame;
    }];
    [[NSUserDefaults standardUserDefaults] setObject:array forKey:@"TestCase_Connect"];
    //[[NSUserDefaults standardUserDefaults] synchronize];
    array = [NSMutableArray array];
    for (NSString *s in [_transferData allKeys]) {
        [array addObject:@{@"Size":[NSNumber numberWithInt:[s intValue]],
                           @"writeWithResponse":@(YES)}];
    }
    [array sortUsingComparator:^NSComparisonResult(NSDictionary *obj1, NSDictionary *obj2) {
        if ([obj1[@"Size"] integerValue] > [obj2[@"Size"] integerValue])
            return NSOrderedDescending;
        else if ([obj1[@"Size"] integerValue] < [obj2[@"Size"] integerValue])
            return NSOrderedAscending;
        else
            return NSOrderedSame;
    }];
    [[NSUserDefaults standardUserDefaults] setObject:array forKey:@"TestCase_Transfer"];
    array = [NSMutableArray array];
    for (NSString *s in [_specialData allKeys]) {
        if ([s isEqualToString:@"1"]) {
            [array addObject:@{@"ID":@"1",
                               @"count":@(10),
                               @"writeWithResponse":@(NO)}];
        }
        if ([s isEqualToString:@"2"]) {
            [array addObject:@{@"ID":@"1",
                               @"count":@(1000),
                               @"writeWithResponse":@(NO)}];
        }
        if ([s isEqualToString:@"3"]) {
            [array addObject:@{@"ID":@"2",
                               @"count":@(10),
                               @"writeWithResponse":@(YES)}];
        }
        if ([s isEqualToString:@"4"]) {
            [array addObject:@{@"ID":@"2",
                               @"count":@(100),
                               @"writeWithResponse":@(YES)}];
        }

    }
    [array sortUsingComparator:^NSComparisonResult(NSDictionary *obj1, NSDictionary *obj2) {
        if ([obj1[@"ID"] integerValue] > [obj2[@"ID"] integerValue])
            return NSOrderedDescending;
        else if ([obj1[@"ID"] integerValue] < [obj2[@"ID"] integerValue])
            return NSOrderedAscending;
        else
            return NSOrderedSame;
    }];
    [[NSUserDefaults standardUserDefaults] setObject:array forKey:@"TestCase_Special"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)run:(UIButton *)sender {
    [self saveTestCase];
    //[[ISControlManager sharedInstance] scanDeviceList:ISControlManagerTypeCB];
    ISLogView *log = [[ISLogView alloc] initWithFrame:self.view.bounds];
    log.alpha = 0.0f;
    log.userInteractionEnabled = YES;
    [self.view addSubview:log];
    [UIView animateWithDuration:1.0 animations:^{
        log.alpha = 1.0f;
    } completion:^(BOOL finished) {
        [[ISProcessController sharedInstance] start];
    }];
    
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    UITableView *_table = (UITableView *)[[_currentSettingView subviews] objectAtIndex:0];
    if (_table) {
        [_table reloadData];
    }
    [_connectData removeAllObjects];
    [_transferData removeAllObjects];
    [_specialData removeAllObjects];
    NSArray *array = [[NSUserDefaults standardUserDefaults] objectForKey:@"TestCase_Connect"];
    for (NSNumber *number in array) {
        [_connectData setObject:@(YES) forKey:[number stringValue]];
    }
    array = [[NSUserDefaults standardUserDefaults] objectForKey:@"TestCase_Transfer"];
    for (NSDictionary *dis in array) {
        [_transferData setObject:@(YES) forKey:[[dis objectForKey:@"Size"] stringValue]];
    }
    array = [[NSUserDefaults standardUserDefaults] objectForKey:@"TestCase_Special"];
    for (NSDictionary *dis in array) {
        if ([[dis objectForKey:@"ID"] isEqualToString:@"1"] && [[dis objectForKey:@"count"] integerValue] == 10) {
            [_specialData setObject:@(YES) forKey:@"1"];
        }
        if ([[dis objectForKey:@"ID"] isEqualToString:@"1"] && [[dis objectForKey:@"count"] integerValue] == 1000) {
            [_specialData setObject:@(YES) forKey:@"2"];
        }
        if ([[dis objectForKey:@"ID"] isEqualToString:@"2"] && [[dis objectForKey:@"count"] integerValue] == 10) {
            [_specialData setObject:@(YES) forKey:@"3"];
        }
        if ([[dis objectForKey:@"ID"] isEqualToString:@"2"] && [[dis objectForKey:@"count"] integerValue] == 100) {
            [_specialData setObject:@(YES) forKey:@"4"];
        }

    }
    _table = (UITableView *)[[_connectView subviews] objectAtIndex:0];
    if (_table) {
        [_table reloadData];
    }
    _table = (UITableView *)[[_dataView subviews] objectAtIndex:0];
    if (_table) {
        [_table reloadData];
    }
    _table = (UITableView *)[[_specialView subviews] objectAtIndex:0];
    if (_table) {
        [_table reloadData];
    }

}

#pragma mark - SlidingTabsControlDelegate
- (UILabel*) labelFor:(SlidingTabsControl*)slidingTabsControl atIndex:(NSUInteger)tabIndex {
    UILabel *lable = [[UILabel alloc] init];
    switch (tabIndex) {
        case 0:
            lable.text = @"Current Setting";
            break;
        case 1:
            lable.text = @"Connect";
            break;
        case 2:
            lable.text = @"Data";
            break;
        case 3:
            lable.text = @"Special";
            break;
        default:
            break;
    }
    return lable;
}

- (void) touchUpInsideTabIndex:(NSUInteger)tabIndex {
    [UIView animateWithDuration:1 animations:^{
        _currentSettingView.hidden = YES;
        _connectView.hidden = YES;
        _dataView.hidden = YES;
        _specialView.hidden = YES;
        [self.view viewWithTag:tabIndex+1].hidden = NO;
    }];
}

#pragma mark - UITableViewDataSource
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    switch (tableView.tag) {
        case 1:
            return 1;
            break;
        case 2:
            return 1;
            break;
        case 3:
            return 1;
            break;
        case 4:
            return 1;
            break;
            
        default:
            break;
    }
    return 0;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    switch (tableView.tag) {
        case 1:
            return 3;
            break;
        case 2:
            return 4;
            break;
        case 3:
            return 4;
            break;
        case 4:
            return 4;
            break;
        default:
            break;
    }
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *identifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    if (!cell) {
        if (tableView.tag == 1) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:identifier];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
        }
        else {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];
            cell.textLabel.adjustsFontSizeToFitWidth = YES;
            //cell.selectionStyle = UITableViewCellSelectionStyleNone;
        }
    }
    switch (tableView.tag) {
        case 1: {
            NSDictionary *device = [[NSUserDefaults standardUserDefaults] objectForKey:@"selectDevice"];
            switch (indexPath.row) {
                case 0:
                    cell.textLabel.text = @"Target Device UUID";
                    cell.detailTextLabel.text = device?device[@"UUID"]:@"NA";
                    break;
                case 1:
                    cell.textLabel.text = @"App Version";
                    cell.detailTextLabel.text = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
                    break;
                case 2:
                    cell.textLabel.text = @"Stop When Fail";
                    cell.detailTextLabel.text = [[NSUserDefaults standardUserDefaults] boolForKey:@"StopWhenFail"]?@"YES":@"NO";
                    break;
                default:
                    break;
            }
        }
            break;
        /*case 2: {
            int times = connectTable[indexPath.row];
            cell.textLabel.text = [NSString stringWithFormat:@"Connect/Disconnect %d Times",times];
            if ([_connectData objectForKey:[NSString stringWithFormat:@"%ld",(long)times]]) {
                cell.accessoryType = UITableViewCellAccessoryCheckmark;
            }
            else {
                cell.accessoryType = UITableViewCellAccessoryNone;
            }
            break;
        }*/
        case 3: {
            /*switch (indexPath.row) {
                case 0:
                    cell.textLabel.text = @"Transfer 1k";
                    cell.accessoryType = UITableViewCellAccessoryCheckmark;
                    break;
                 default:
                    break;
            }*/
            int dataSize = dataTable[indexPath.row];
            if ([_transferData objectForKey:[NSString stringWithFormat:@"%ld",(long)dataSize]]) {
                cell.accessoryType = UITableViewCellAccessoryCheckmark;
            }
            else {
                cell.accessoryType = UITableViewCellAccessoryNone;
            }

            if (dataSize/1024.0<1) {
                cell.textLabel.text = [NSString stringWithFormat:@"Transfer %d Bytes",dataSize];
            }
            else {
                dataSize = dataSize/1024;
                cell.textLabel.text = [NSString stringWithFormat:@"Transfer %d KB",dataSize];
            }
         }
            break;
        case 2: {

            if ([_specialData objectForKey:[NSString stringWithFormat:@"%ld",indexPath.row+1]]) {
                cell.accessoryType = UITableViewCellAccessoryCheckmark;
            }
            else {
                cell.accessoryType = UITableViewCellAccessoryNone;
            }
            switch (indexPath.row) {
                case 0:
                    cell.textLabel.text = @"Connect 10 time wtih random disconnect";
                    break;
                case 1:
                    cell.textLabel.text = @"Connect 1000 time wtih random disconnect";
                    break;
                case 2:
                    cell.textLabel.text = @"Connect 10 time wtih random disconnect (r)";
                    break;
                case 3:
                    cell.textLabel.text = @"Connect 100 time wtih random disconnect (r)";
                    break;
                 
                default:
                    break;
            }

        }
            break;

        default:
            break;
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    switch (tableView.tag) {
        case 1: {

        }
            break;
        /*case 2: {
            int times = connectTable[indexPath.row];
            UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];

            if ([_connectData objectForKey:[NSString stringWithFormat:@"%d",times]]) {
                [_connectData removeObjectForKey:[NSString stringWithFormat:@"%d",times]];
                cell.accessoryType = UITableViewCellAccessoryNone;
            }
            else {
                [_connectData setObject:@(YES) forKey:[NSString stringWithFormat:@"%d",times]];
                cell.accessoryType = UITableViewCellAccessoryCheckmark;
            }
            break;
        }*/
        case 3: {
            int dataSize = dataTable[indexPath.row];

            UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
            
            if ([_transferData objectForKey:[NSString stringWithFormat:@"%d",dataSize]]) {
                [_transferData removeObjectForKey:[NSString stringWithFormat:@"%d",dataSize]];
                cell.accessoryType = UITableViewCellAccessoryNone;
            }
            else {
                [_transferData setObject:@(YES) forKey:[NSString stringWithFormat:@"%d",dataSize]];
                cell.accessoryType = UITableViewCellAccessoryCheckmark;
            }
        }
             break;
        case 2: {
            
            UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
            
            if ([_specialData objectForKey:[NSString stringWithFormat:@"%ld",indexPath.row+1]]) {
                [_specialData removeObjectForKey:[NSString stringWithFormat:@"%ld",indexPath.row+1]];
                cell.accessoryType = UITableViewCellAccessoryNone;
            }
            else {
                [_specialData setObject:@(YES) forKey:[NSString stringWithFormat:@"%ld",indexPath.row+1]];
                cell.accessoryType = UITableViewCellAccessoryCheckmark;
            }
        }
            break;
        default:
            break;
    }
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}
@end
