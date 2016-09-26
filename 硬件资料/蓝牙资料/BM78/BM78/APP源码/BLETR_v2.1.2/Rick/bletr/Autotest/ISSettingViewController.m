//
//  ISSettingViewController.m
//  AutoTest
//
//  Created by Rick on 13/12/23.
//  Copyright (c) 2013年 Rick. All rights reserved.
//

#import "ISSettingViewController.h"
#import "MFi_DeviceListController.h"
#import "ISBLEDataPath.h"
#import "UIAlertView+BlockExtensions.h"
#import "ISProcessController.h"

@interface ISSettingViewController () <UITableViewDelegate,UITableViewDataSource,ISDeviceProtocol>{
    UITableView *_tableView;
    NSUUID *_selectUUID;
    NSString *_selectName;
}

@end

@implementation ISSettingViewController

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
    if ([[NSUserDefaults standardUserDefaults] objectForKey:@"selectDevice"]) {
        NSDictionary *device = [[NSUserDefaults standardUserDefaults] objectForKey:@"selectDevice"];
        _selectName = [device objectForKey:@"name"];
        _selectUUID = [[NSUUID alloc] initWithUUIDString:device[@"UUID"]];
    }
    self.wantsFullScreenLayout = YES;
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(done)];
    _tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStyleGrouped];
    _tableView.dataSource = self;
    _tableView.delegate = self;
    _tableView.autoresizingMask = UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:_tableView];
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)done {
    NSDictionary *device = [[NSUserDefaults standardUserDefaults] objectForKey:@"selectDevice"];
    if (_selectUUID && ![device[@"UUID"] isEqualToString:_selectUUID.UUIDString]) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"" message:@"Target Device not save, do you want to save now?" completionBlock:^(NSUInteger buttonIndex, UIAlertView *alertView) {
            if (buttonIndex != [alertView cancelButtonIndex]) {
                [self save];
            }
            [self.navigationController dismissViewControllerAnimated:YES completion:nil];
        } cancelButtonTitle:@"NO,Thanks" otherButtonTitles:@"YES",nil];
        [alert show];
    }
    else {
        [self.navigationController dismissViewControllerAnimated:YES completion:nil];
    }
}

- (void)save {
    NSUserDefaults *def = [NSUserDefaults standardUserDefaults];
    NSDictionary *device = @{@"name": _selectName,
                             @"UUID":_selectUUID.UUIDString};
    [def setObject:device forKey:@"selectDevice"];
    [def synchronize];
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    NSDictionary *conf = @{@"create_time": [formatter stringFromDate:[NSDate date]],
                           @"application_version":[[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"],
                           @"os_type":[UIDevice currentDevice].systemName,
                           /*@"target_device_uuid":_selectUUID.UUIDString,
                           @"target_device_name":_selectName,*/
                           @"preferences":@{@"test_case_transfer":[def objectForKey:@"TestCase_Transfer"],
                                            @"test_case_connect":[def objectForKey:@"TestCase_Connect"]}};
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *file = [NSString stringWithFormat:@"%@/%@",documentsDirectory,
                      @"configuration.json"];
    NSData *output_data = [NSJSONSerialization  dataWithJSONObject:conf options:NSJSONWritingPrettyPrinted error:nil];
    [output_data writeToFile:file atomically:NO];
}

- (void)setAutoUpload:(UISwitch *)sw {
    [[NSUserDefaults standardUserDefaults] setBool:sw.on forKey:@"AutoUpload"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)setStopWhenFail:(UISwitch *)sw {
    [[NSUserDefaults standardUserDefaults] setBool:sw.on forKey:@"StopWhenFail"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

#pragma mark - UITableViewDataSource
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 3;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    switch (section) {
        case 0:
            return 2;
            break;
        case 1:
            return 1;
            break;
        case 2:
            return 2;
            break;
        case 3:
            return 1;
            break;
        default:
            break;
    }
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *identifier = [NSString stringWithFormat:@"Cell%ld",(long)indexPath.section];
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    if (!cell) {
        switch (indexPath.section) {
            case 0:
                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:identifier];
                break;
            case 1:
            case 2:
                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];
                break;
   
            default:
                break;
        }
            //cell.selectionStyle = UITableViewCellSelectionStyleNone;
     }
    switch (indexPath.section) {
        case 0:
            switch (indexPath.row) {
                case 0:
                    cell.textLabel.text = @"Target Device Name";
                    cell.detailTextLabel.text = _selectName?_selectName: @"NA";
                    break;
                case 1:
                    cell.textLabel.text = @"Target Device UUID";
                    cell.detailTextLabel.text = _selectUUID?_selectUUID.UUIDString: @"NA";
                    break;
                    
                default:
                    break;
            }
            break;
        case 1:
            switch (indexPath.row) {
                case 0: {
                    cell.textLabel.text = @"Stop When Fail";
                    UISwitch *sw = [[UISwitch alloc] init];
                    sw.on = [[NSUserDefaults standardUserDefaults] boolForKey:@"StopWhenFail"];
                    [sw addTarget:self action:@selector(setStopWhenFail:) forControlEvents:UIControlEventValueChanged];
                    cell.accessoryView = sw;
                }
                    break;
                 default:
                    break;
            }
            break;
        case 2:
            switch (indexPath.row) {
                case 0:
                    cell.textLabel.text = @"Save Configuration";
                    break;
                case 1:
                    cell.textLabel.text = @"Load Configuration";
                    break;
                default:
                    break;
            }
            break;
        default:
            break;
    }
    return cell;
}

#pragma mark - UITableViewDelegate
-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    switch (indexPath.section) {
        case 0: {
            MFi_DeviceListController *deviceList = [[MFi_DeviceListController alloc] initWithStyle:UITableViewStyleGrouped];
            deviceList.delegate = self;
            [self.navigationController pushViewController:deviceList animated:YES];
        }
            break;
        case 1: {
            if (indexPath.row == 1) {
                //[self didPressLink];
            }
        }
            break;
        case 2: {
            if (indexPath.row == 0) {  // save
                [self save];
            }
            else {  //load
                NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
                NSString *documentsDirectory = [paths objectAtIndex:0];
                NSString *file = [NSString stringWithFormat:@"%@/%@",documentsDirectory,
                                  @"configuration.json"];
                NSData *load_conf = [NSData dataWithContentsOfFile:file];
                if (file) {
                    NSDictionary *dis = [NSJSONSerialization JSONObjectWithData:load_conf options:NSJSONReadingAllowFragments error:nil];
                    if (dis) {
                        NSUserDefaults *def = [NSUserDefaults standardUserDefaults];
                        /*if (dis[@"os_type"] && [dis[@"os_type"] isEqualToString:[UIDevice currentDevice].systemName]) {
                            _selectName = dis[@"target_device_name"];
                            _selectUUID = [[NSUUID alloc] initWithUUIDString:dis[@"target_device_uuid"]];
                            NSDictionary *device = @{@"name": _selectName,
                                                     @"UUID":_selectUUID.UUIDString};
                            [def setObject:device forKey:@"selectDevice"];
                        }
                        else {
                            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"" message:@"The config file is not for iOS, we will only load test cases configuration." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
                            [alert show];
                        }*/
                        [def setObject:dis[@"preferences"][@"test_case_transfer"] forKey:@"TestCase_Transfer"];
                        [def setObject:dis[@"preferences"][@"test_case_connect"] forKey:@"TestCase_Connect"];
                        [def synchronize];
                    }
                }
            }
        }
            break;
        default:
            break;
    }
}

#pragma mark - ISDeviceProtocol
- (void)didSelectDevice:(ISDataPath *)accessory {
    if ([accessory isKindOfClass:[ISBLEDataPath class]]) {
        ISBLEDataPath *d =(ISBLEDataPath *)accessory;
        _selectUUID = d.UUID;
        _selectName = d.name;
        [_tableView reloadData];
    }
}

@end
