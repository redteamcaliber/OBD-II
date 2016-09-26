//
//  ConnectViewController.m
//  BLETR
//
//  Created by D500 user on 12/9/26.
//  Copyright (c) 2012 ISSC Technologies Corporation. All rights reserved.
//
#import "AppDelegate.h"
#import "ConnectViewController.h"
#import "SettingAlertView.h"
#import "ISSCButton.h"
#import "ISRootViewController.h"

@interface ConnectViewController ()
{
    CBController *_cbController;
}
@end

@implementation ConnectViewController

//@synthesize actionButton;
@synthesize activityIndicatorView;
@synthesize statusLabel;
//@synthesize connectionStatus;
@synthesize versionLabel;




- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        if (floor(NSFoundationVersionNumber) > NSFoundationVersionNumber_iOS_6_1) {
            self.edgesForExtendedLayout = UIRectEdgeNone;
        }
        _cbController = [[CBController alloc] init];
        [_cbController setDelegate:self];
        
        UIBarButtonItem *backButton = [[UIBarButtonItem alloc] init];
        backButton.title = @"Back";
        self.navigationItem.backBarButtonItem = backButton;
        
        
        UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(200, 28, 57, 57)];
        [titleLabel setBackgroundColor:[UIColor colorWithPatternImage:[UIImage imageNamed:@"Icon_old"]]];
        [titleLabel setTextAlignment:NSTextAlignmentCenter];//aaa
        self.navigationItem.titleView = titleLabel;
        [titleLabel release];
        
        ISSCButton *button = [ISSCButton buttonWithType:UIButtonTypeCustom];
        button.frame = CGRectMake(0.0f, 0.0f, 80.0f, 30.0f);
        [button addTarget:self action:@selector(refreshDeviceList:) forControlEvents:UIControlEventTouchUpInside];
        [button setTitle:@"Refresh" forState:UIControlStateNormal];
        refreshButton = [[UIBarButtonItem alloc] initWithCustomView:button];
        //refreshButton = [[UIBarButtonItem alloc] initWithTitle:@"Refresh" style:UIBarButtonItemStyleBordered target:self action:@selector(refreshDeviceList:)];
        button = [ISSCButton buttonWithType:UIButtonTypeCustom];
        button.frame = CGRectMake(0.0f, 0.0f, 80.0f, 30.0f);
        [button addTarget:self action:@selector(startScan) forControlEvents:UIControlEventTouchUpInside];
        [button setTitle:@"  Scan  " forState:UIControlStateNormal];
        scanButton = [[UIBarButtonItem alloc] initWithCustomView:button];
        //scanButton = [[UIBarButtonItem alloc] initWithTitle:@"  Scan  " style:UIBarButtonItemStyleBordered target:self action:@selector(actionButtonStartScan:)];
        button = [ISSCButton buttonWithType:UIButtonTypeCustom];
        button.frame = CGRectMake(0.0f, 0.0f, 80.0f, 30.0f);
        [button addTarget:self action:@selector(actionButtonCancelScan:) forControlEvents:UIControlEventTouchUpInside];
        [button setTitle:@"Cancel" forState:UIControlStateNormal];
        cancelButton = [[UIBarButtonItem alloc] initWithCustomView:button];
        //cancelButton = [[UIBarButtonItem alloc] initWithTitle:@"Cancel" style:UIBarButtonItemStyleBordered target:self action:@selector(actionButtonCancelScan:)];
        button = [ISSCButton buttonWithType:UIButtonTypeCustom];
        button.frame = CGRectMake(0.0f, 0.0f, 90.0f, 30.0f);
        [button addTarget:self action:@selector(manualUUIDSetting:) forControlEvents:UIControlEventTouchUpInside];
        [button setTitle:@"UUID Setting" forState:UIControlStateNormal];
        button.titleLabel.adjustsFontSizeToFitWidth = YES;
        uuidSettingButton = [[UIBarButtonItem alloc] initWithCustomView:button];
        //uuidSettingButton = [[UIBarButtonItem alloc] initWithTitle:@"UUID Setting" style:UIBarButtonItemStyleBordered target:self action:@selector(manualUUIDSetting:)];
        
        //refreshButton = [[UIBarButtonItem alloc] initWithTitle:@"Refresh" style:UIBarButtonItemStyleBordered target:self action:@selector(refreshDeviceList:)];
        //scanButton = [[UIBarButtonItem alloc] initWithTitle:@"  Scan  " style:UIBarButtonItemStyleBordered target:self action:@selector(startScan)];
        //cancelButton = [[UIBarButtonItem alloc] initWithTitle:@"Cancel" style:UIBarButtonItemStyleBordered target:self action:@selector(actionButtonCancelScan:)];

        connectedDeviceInfo = [NSMutableArray new];
       // connectingList = [NSMutableArray new];
        
        NSDictionary *record = [[NSUserDefaults standardUserDefaults] objectForKey:@"deviceRecord"];
        if (record == nil) {
            deviceRecord = [[NSMutableDictionary alloc] init];
        }
        else {
            deviceRecord = [record mutableCopy];
        }
        

        deviceInfo = [[DeviceInfo alloc]init];
        refreshDeviceListTimer = nil;
        uuidSettingViewController = nil;
        
        UIBarButtonItem *right = [[UIBarButtonItem alloc] initWithTitle:@"AutoTest" style:UIBarButtonItemStyleBordered target:self action:@selector(showAutotest:)];
        self.navigationItem.rightBarButtonItem = right;
        [right release];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Do any additional setup after loading the view from its nib.
   // [self setConnectionStatus:LE_STATUS_IDLE];
    ReliableBurstData *data = [[ReliableBurstData alloc] init];
    [versionLabel setText:[NSString stringWithFormat:@"BLETR %@, library %@, %s",[[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"],[data version], __DATE__]];
    [data release];
}

- (void)viewDidAppear:(BOOL)animated {
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    [[appDelegate navigationController] setToolbarHidden:NO animated:NO];
    if([connectedDeviceInfo count] == 0) {
        if (uuidSettingViewController.isUUIDAvailable) {
            [_cbController configureTransparentServiceUUID:uuidSettingViewController.transServiceUUIDStr txUUID:uuidSettingViewController.transTxUUIDStr rxUUID:uuidSettingViewController.transRxUUIDStr];
        }
        else
            [_cbController configureTransparentServiceUUID:nil txUUID:nil rxUUID:nil];
        
        if (uuidSettingViewController.isDISUUIDAvailable) {
            if (uuidSettingViewController.disUUID2Str) {
                [_cbController configureDeviceInformationServiceUUID:uuidSettingViewController.disUUID1Str UUID2:uuidSettingViewController.disUUID2Str];
            }
            else
                [_cbController configureDeviceInformationServiceUUID:uuidSettingViewController.disUUID1Str UUID2:nil];

        }
        else
            [_cbController configureDeviceInformationServiceUUID:nil UUID2:nil];
        
    }
    [self performSelector:@selector(startScan) withObject:nil afterDelay:0.1];
}

- (void)viewDidUnload
{
    [devicesTableView release];
    devicesTableView = nil;
    [self setVersionLabel:nil];
    [refreshButton release];
    refreshButton = nil;
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    NSLog(@"[ConnectViewController] didReceiveMemoryWarning");
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

- (void)dealloc {
    [devicesTableView release];
    [versionLabel release];
    [refreshButton release];
    [cancelButton release];
    [scanButton release];
    [uuidSettingViewController release];
    [uuidSettingButton release];
    [super dealloc];
}

- (void) displayDevicesList {
    [devicesTableView reloadData];
}

- (void) switchToMainFeaturePage {
    NSLog(@"[ConnectViewController] switchToMainFeaturePage");

    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    if ([[[appDelegate navigationController] viewControllers] containsObject:[deviceInfo mainViewController]] == FALSE) {
        [[appDelegate navigationController] pushViewController:[deviceInfo mainViewController] animated:YES];
    }
}

//- (int) connectionStatus {
//    return connectionStatus;
//}
/*
- (void) setConnectionStatus:(int)status {
    if (status == LE_STATUS_IDLE) {
        statusLabel.textColor = [UIColor redColor];
    }
    else {
        statusLabel.textColor = [UIColor blackColor];
    }
    connectionStatus = status;

    switch (status) {
        case LE_STATUS_IDLE:
            statusLabel.text = @"Idle";
            [activityIndicatorView stopAnimating];
            break;
        case LE_STATUS_SCANNING:
            [devicesTableView reloadData];
            statusLabel.text = @"Scanning...";
            [activityIndicatorView startAnimating];
            break;
        default:
            break;
    }
    [self updateButtonType];
}*/

- (IBAction)actionButtonCancelScan:(id)sender {
    NSLog(@"[ConnectViewController] actionButtonCancelScan");
    [self stopScan];
    //[self setConnectionStatus:LE_STATUS_IDLE];
}

- (void)startScan {
    [_cbController startScanWithUUID:nil];
    statusLabel.textColor = [UIColor blackColor];
    [devicesTableView reloadData];
    statusLabel.text = @"Scanning...";
    [activityIndicatorView startAnimating];
    [self updateButtonType];
/*    if ([connectingList count] > 0) {
        for (int i=0; i< [connectingList count]; i++) {
            MyPeripheral *connectingPeripheral = [connectingList objectAtIndex:i];
            
            if (connectingPeripheral.connectStaus == MYPERIPHERAL_CONNECT_STATUS_CONNECTING) {
                //NSLog(@"startScan add connecting List: %@",connectingPeripheral.advName);
                [devicesList addObject:connectingPeripheral];
            }
            else {
                [connectingList removeObjectAtIndex:i];
                //NSLog(@"startScan remove connecting List: %@",connectingPeripheral.advName);
            }
        }
    }
    [self setConnectionStatus:LE_STATUS_SCANNING];*/
}

- (void)stopScan {
    [_cbController stopScan];
    statusLabel.textColor = [UIColor redColor];
    statusLabel.text = @"Idle";
    [activityIndicatorView stopAnimating];
    [self updateButtonType];
    if (refreshDeviceListTimer) {
        [refreshDeviceListTimer invalidate];
        refreshDeviceListTimer = nil;
    }
}

-(void)popToRootPage {
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    if (appDelegate.pageTransition == FALSE) {
        [[appDelegate navigationController] popToRootViewControllerAnimated:NO];
    }
    else {
        [NSTimer scheduledTimerWithTimeInterval:0.2 target:self selector:@selector(popToRootPage) userInfo:nil repeats:NO];
    }
}


// <-- CBController delegate
- (void)CBController:(CBController *)cbController didUpdateDiscoveredPeripherals:(NSArray *)peripherals {
    NSLog(@"didUpdateDiscoveredPeripherals");
    [devicesTableView reloadData];
}
/*
- (void)updateDiscoverPeripherals {
    [super updateDiscoverPeripherals];
    [devicesTableView reloadData];
}*/

- (void)CBController:(CBController *)cbController didDisconnectedPeripheral:(MyPeripheral *)myPeripheral {
    NSLog(@"updateMyPeripheralForDisconnect");//, %@", myPeripheral.advName);
    if (myPeripheral == controlPeripheral) {
        [NSTimer scheduledTimerWithTimeInterval:0.03 target:self selector:@selector(popToRootPage) userInfo:nil repeats:NO];
    }
    
    for (int idx =0; idx< [connectedDeviceInfo count]; idx++) {
        DeviceInfo *tmpDeviceInfo = [connectedDeviceInfo objectAtIndex:idx];
        if (tmpDeviceInfo.myPeripheral == myPeripheral) {
            [connectedDeviceInfo removeObjectAtIndex:idx];
            //NSLog(@"updateMyPeripheralForDisconnect1");
            break;
        }
    }
    
    [self displayDevicesList];
    [self updateButtonType];
    
    if(cbController.isScanning == YES){
        [self stopScan];
        [self startScan];
        [devicesTableView reloadData];
    }
}

- (void)CBController:(CBController *)cbController didConnectedPeripheral:(MyPeripheral *)myPeripheral {
    NSLog(@"[ConnectViewController] updateMyPeripheralForNewConnected");
    DeviceInfo *tmpDeviceInfo = [[DeviceInfo alloc]init];
    tmpDeviceInfo.mainViewController = [[ViewController alloc] initWithNibName:@"ViewController" bundle:nil];
    tmpDeviceInfo.mainViewController.connectedPeripheral = myPeripheral;
    tmpDeviceInfo.myPeripheral = myPeripheral;
    tmpDeviceInfo.myPeripheral.connectStatus = myPeripheral.connectStatus;
    //  deviceRecord setObject:myPeripheral.advName forKey:myPeripheral.
    
    [deviceRecord setObject:[myPeripheral advName] forKey:[myPeripheral uuidString]];
    NSUserDefaults *def = [NSUserDefaults standardUserDefaults];
    [def setObject:deviceRecord forKey:@"deviceRecord"];
    [def synchronize];
    
    /*Connected List Filter*/
    bool b = FALSE;
    for (int idx =0; idx< [connectedDeviceInfo count]; idx++) {
        DeviceInfo *tmpDeviceInfo = [connectedDeviceInfo objectAtIndex:idx];
        if (tmpDeviceInfo.myPeripheral == myPeripheral) {
            b = TRUE;
            break;
        }
    }
    if (!b) {
        [connectedDeviceInfo addObject:tmpDeviceInfo];
    }
    else{
        NSLog(@"Connected List Filter!");
    }
    
    [self displayDevicesList];
    [self updateButtonType];
}

// DataSource methods
- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    //NSLog(@"[ConnectViewController] numberOfRowsInSection,device count = %d", [devicesList count]);
    switch (section) {
        case 0:
            return [connectedDeviceInfo count];
        case 1:
            return [_cbController.devicesList count];
        case 2:
            return [deviceRecord count];
        default:
            return 0;
        }
    }

- (UITableViewCell *) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {

    UITableViewCell *cell;
    
    switch (indexPath.section) {
        case 0:
        {
            //NSLog(@"[ConnectViewController] CellForRowAtIndexPath section 0, Row = %d",[indexPath row]);
            cell = [tableView dequeueReusableCellWithIdentifier:@"connectedList"];
            if (cell == nil) {
                cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"connectedList"] autorelease];
            }
            DeviceInfo *tmpDeviceInfo = [connectedDeviceInfo objectAtIndex:indexPath.row];
            
            cell.textLabel.text = tmpDeviceInfo.myPeripheral.advName;
            cell.detailTextLabel.text = @"connected";
            cell.accessoryView = nil;
            if (cell.textLabel.text == nil)
                cell.textLabel.text = @"Unknow";
            
            UIButton *accessoryButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
            [accessoryButton addTarget:self action:@selector(actionButtonDisconnect:)  forControlEvents:UIControlEventTouchUpInside];
            accessoryButton.tag = indexPath.row;
            [accessoryButton setTitle:@"Disconnect" forState:UIControlStateNormal];
            [accessoryButton setFrame:CGRectMake(0,0,100,35)];
            cell.accessoryView  = accessoryButton;           
        }
            break;
            
        case 1:
        {
            //NSLog(@"[ConnectViewController] CellForRowAtIndexPath section 1, Row = %d",[indexPath row]);
            
            cell = [tableView dequeueReusableCellWithIdentifier:@"devicesList"];
            if (cell == nil) {
                cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"devicesList"] autorelease];
            }
            MyPeripheral *tmpPeripheral = [_cbController.devicesList objectAtIndex:indexPath.row];
            cell.textLabel.text = tmpPeripheral.advName;
            cell.detailTextLabel.text = @"";
            cell.accessoryView = nil;
            if (tmpPeripheral.connectStatus == MYPERIPHERAL_CONNECT_STATUS_CONNECTING) {
                cell.detailTextLabel.text = @"connecting...";
                UIButton *accessoryButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
                [accessoryButton addTarget:self action:@selector(actionButtonCancelConnect:)  forControlEvents:UIControlEventTouchUpInside];
                accessoryButton.tag = indexPath.row;
                [accessoryButton setTitle:@"Cancel" forState:UIControlStateNormal];
                [accessoryButton setFrame:CGRectMake(0,0,100,35)];
                cell.accessoryView  = accessoryButton;
                
            }
            
            if (cell.textLabel.text == nil)
                cell.textLabel.text = @"Unknow";
        }
            break;
        case 2:
        {
            //NSLog(@"[ConnectViewController] CellForRowAtIndexPath section 1, Row = %d",[indexPath row]);
            
            cell = [tableView dequeueReusableCellWithIdentifier:@"deviceRecord"];
            if (cell == nil) {
                cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"deviceRecord"] autorelease];
            }
            NSArray *keys = [deviceRecord allKeys];
            NSString *name = [deviceRecord objectForKey:[keys objectAtIndex:indexPath.row]];
            cell.textLabel.text = name;
            cell.detailTextLabel.text = [keys objectAtIndex:indexPath.row];
            [cell.detailTextLabel setFont:[UIFont systemFontOfSize:8]];
            UIButton *accessoryButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
            [accessoryButton addTarget:self action:@selector(actionButtonDeleteRecord:)  forControlEvents:UIControlEventTouchUpInside];
            accessoryButton.tag = indexPath.row;
            [accessoryButton setTitle:@"Delete" forState:UIControlStateNormal];
            [accessoryButton setFrame:CGRectMake(0,0,100,35)];
            cell.accessoryView  = accessoryButton;
        }
    }
    
    return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	
	NSString *title = nil;
	switch (section) {
        case 0:
            title = @"Connected Device:";
            break;
		case 1:
			title = @"Discovered Devices:";
			break;
        case 2:
            title = @"Device Record:";
            break;
		default:
			break;
	}
	return title;
}


-(NSInteger) numberOfSectionsInTableView:(UITableView *)tableView{
    return 3;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    switch (indexPath.section) {
        case 0:
        {
            //NSLog(@"[ConnectViewController] didSelectRowAtIndexPath section 0, Row = %d",[indexPath row]);
            deviceInfo = [connectedDeviceInfo objectAtIndex:indexPath.row];
            controlPeripheral = deviceInfo.myPeripheral;
            [self stopScan];
            //[self setConnectionStatus:LE_STATUS_IDLE];
            [activityIndicatorView stopAnimating];
            if (refreshDeviceListTimer) {
                [refreshDeviceListTimer invalidate];
                refreshDeviceListTimer = nil;
            }
            [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(switchToMainFeaturePage) userInfo:nil repeats:NO];
        }
            break;
        case 1:
        {
            //Derek
            NSLog(@"[ConnectViewController] didSelectRowAtIndexPath section 0, Row = %d",(int)[indexPath row]);
            int count = (int)[_cbController.devicesList count];
            if ((count != 0) && count > indexPath.row) {
                MyPeripheral *tmpPeripheral = [_cbController.devicesList objectAtIndex:indexPath.row];
                if (tmpPeripheral.connectStatus != MYPERIPHERAL_CONNECT_STATUS_IDLE) {
                    //NSLog(@"Device is not idle - break");
                    break;
                }
                [_cbController connectDevice:tmpPeripheral];
              //  tmpPeripheral.connectStatus = MYPERIPHERAL_CONNECT_STATUS_CONNECTING;
              //  [_cbController.devicesList replaceObjectAtIndex:indexPath.row withObject:tmpPeripheral];
              //  [_cbController.connectingList addObject:tmpPeripheral];
                [self displayDevicesList];
                [self updateButtonType];
            }
            break;
        }
        case 2:
        {
            NSArray *keys = [deviceRecord allKeys];
            NSUUID *uuid = [[NSUUID alloc] initWithUUIDString:[keys objectAtIndex:indexPath.row]];
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [_cbController connectDeviceWithIdentifier:uuid];
            });
            break;
        }
        default:
            break;
    }
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (IBAction)refreshDeviceList:(id)sender {
    NSLog(@"[ConnectViewController] refreshDeviceList");
        [self stopScan];
        [self startScan];
        [devicesTableView reloadData];
}

- (IBAction)manualUUIDSetting:(id)sender {
    if (uuidSettingViewController == nil) {
        uuidSettingViewController = [[UUIDSettingViewController alloc] initWithNibName:@"UUIDSettingViewController" bundle:nil];
    }
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    if ([[[appDelegate navigationController] viewControllers] containsObject:uuidSettingViewController] == FALSE) {
        [[appDelegate navigationController] pushViewController:uuidSettingViewController animated:YES];
    }
}

//Derek
- (IBAction)actionButtonDisconnect:(id)sender {
    //NSLog(@"[ConnectViewController] actionButtonDisconnect idx = %d",[sender tag]);
    int idx = (int)[sender tag];
    DeviceInfo *tmpDeviceInfo = [connectedDeviceInfo objectAtIndex:idx];
    [_cbController disconnectDevice:tmpDeviceInfo.myPeripheral];
}

//Derek
- (IBAction)actionButtonCancelConnect:(id)sender {
    //NSLog(@"[ConnectViewController] actionButtonCancelConnect idx = %d",[sender tag]);
    int idx = (int)[sender tag];
    MyPeripheral *tmpPeripheral = [_cbController.devicesList objectAtIndex:idx];
    tmpPeripheral.connectStatus = MYPERIPHERAL_CONNECT_STATUS_IDLE;
    [_cbController.devicesList replaceObjectAtIndex:idx withObject:tmpPeripheral];
    
    for (int idx =0; idx< [_cbController.connectingList count]; idx++) {
        MyPeripheral *tmpConnectingPeripheral = [_cbController.connectingList objectAtIndex:idx];
        if (tmpConnectingPeripheral == tmpPeripheral) {
            [_cbController.connectingList removeObjectAtIndex:idx];
            break;
        }
    }
    
    [_cbController disconnectDevice:tmpPeripheral];
    [self displayDevicesList];
    [self updateButtonType];
}

- (IBAction)actionButtonDeleteRecord:(id)sender {
    NSLog(@"actionButtonDeleteRecord");
    int idx = (int)[sender tag];
    NSArray *keys = [deviceRecord allKeys];
    [deviceRecord removeObjectForKey:[keys objectAtIndex:idx]];
    [self displayDevicesList];
    NSUserDefaults *def = [NSUserDefaults standardUserDefaults];
    [def setObject:deviceRecord forKey:@"deviceRecord"];
    [def synchronize];
}


- (void) updateButtonType {
    NSArray *toolbarItems = nil;
    if (!_cbController.isScanning) {
        if (([connectedDeviceInfo count] > 0)||([_cbController.connectingList count] > 0)) {
            toolbarItems = [[NSArray alloc] initWithObjects:scanButton, nil];
        }
        else {
            toolbarItems = [[NSArray alloc] initWithObjects:scanButton, uuidSettingButton, nil];
        }
        [self setToolbarItems:toolbarItems animated:NO];
        [toolbarItems release];
    }
    else {
        if (([connectedDeviceInfo count] > 0)||([_cbController.connectingList count] > 0)) {
            toolbarItems = [[NSArray alloc] initWithObjects:refreshButton,cancelButton , nil];
        }
        else {
            toolbarItems = [[NSArray alloc] initWithObjects: refreshButton,cancelButton, uuidSettingButton, nil];
        }
        [self setToolbarItems:toolbarItems animated:NO];
        [toolbarItems release];
    }
}

- (void)showAutotest:(id)sender {
    [self stopScan];
    for (DeviceInfo *tmpDeviceInfo in connectedDeviceInfo) {
        [_cbController disconnectDevice:tmpDeviceInfo.myPeripheral];
    }
    ISRootViewController *test = [[ISRootViewController alloc] init];
    [self presentViewController:test animated:YES completion:nil];
    [test release];
}
@end











