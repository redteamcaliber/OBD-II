//
//  MFi_DeviceListController.m
//  MFi_SPP
//
//  Created by Rick on 13/10/31.
//
//

#import "MFi_DeviceListController.h"
#import "ISControlManager.h"
#import "ISDataPath.h"
#import "ISBLEDataPath.h"

@interface MFi_DeviceListController () <ISControlManagerDeviceList,ISControlManagerDelegate> {
    NSMutableArray *deviceList;
    NSMutableArray *connectedList;
    NSTimer *refreshDeviceListTimer;
    UIActivityIndicatorView *act;
    UILabel *scanning;
    UIButton *stop;
    UIButton *refresh;
    UIView *footer;
}

@end

@implementation MFi_DeviceListController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
        deviceList = [[NSMutableArray alloc] init];
        connectedList = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    ISControlManager *manager = [ISControlManager sharedInstance];
    [manager setDeviceList:self];
    [manager setDelegate:self];
    [manager scanDeviceList:ISControlManagerTypeCB];
    for (ISDataPath *d in manager.connectedAccessory) {
        if ([d isKindOfClass:[ISBLEDataPath class]]) {
            [connectedList addObject:d];
        }
    }
    refreshDeviceListTimer = [NSTimer scheduledTimerWithTimeInterval:15 target:self selector:@selector(refreshList) userInfo:nil repeats:YES];
    UIBarButtonItem *item = [[UIBarButtonItem alloc] initWithTitle:@"Back" style:UIBarButtonItemStyleDone target:self action:@selector(back)];
    self.navigationItem.leftBarButtonItem = item;
    footer = [[UIView alloc] initWithFrame:CGRectMake(0.0f, self.navigationController.view.bounds.size.height - 40.f, 320.0f, 40.0f)];
    footer.autoresizingMask = UIViewAutoresizingFlexibleTopMargin;
    footer.backgroundColor = [UIColor colorWithRed:183.0f/255.0f green:237.0f/255.0f blue:253.0f/255.0f alpha:1.0f];
    [self.navigationController.view addSubview:footer];
    act = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    act.frame = CGRectMake(10.0f, 5.0f, 30.0f, 30.0f);
    [footer addSubview:act];
    [act startAnimating];
    scanning = [[UILabel alloc] initWithFrame:CGRectMake(50.0f, 10.0f, 100.0f, 20.0f)];
    scanning.font = [UIFont systemFontOfSize:18.0f];
    scanning.backgroundColor = [UIColor clearColor];
    scanning.text = @"Scanning...";
    [footer addSubview:scanning];
    stop = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    stop.frame = CGRectMake(160.0f, 5.0f, 75.0f, 30.0f);
    [stop setTitle:@"Stop" forState:UIControlStateNormal];
    [stop addTarget:self action:@selector(stopAndStartScanning) forControlEvents:UIControlEventTouchUpInside];
    [footer addSubview:stop];
    refresh = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    refresh.frame = CGRectMake(240.0f, 5.0f, 75.0f, 30.0f);
    [refresh setTitle:@"Refresh" forState:UIControlStateNormal];
    [refresh addTarget:self action:@selector(refreshList) forControlEvents:UIControlEventTouchUpInside];
    [footer addSubview:refresh];
    //UIBarButtonItem *setUUID = [[UIBarButtonItem alloc] initWithTitle:@"UUID" style:UIBarButtonItemStyleBordered target:self action:@selector(setUUID:)];
    //self.navigationItem.rightBarButtonItem = setUUID;
    
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    footer.hidden = NO;
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    footer.hidden = YES;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)stopAndStartScanning {
    if (act.hidden) {
        act.hidden = NO;
        scanning.text = @"Scanning...";
        [stop setTitle:@"Stop" forState:UIControlStateNormal];
        refresh.hidden = NO;
        [deviceList removeAllObjects];
        ISControlManager *manager = [ISControlManager sharedInstance];
        [manager scanDeviceList:ISControlManagerTypeCB];
        [self.tableView reloadData];
        refreshDeviceListTimer = [NSTimer scheduledTimerWithTimeInterval:15 target:self selector:@selector(refreshList) userInfo:nil repeats:YES];
    }
    else {
        act.hidden = YES;
        scanning.text = @"Idle";
        [stop setTitle:@"Scan" forState:UIControlStateNormal];
        refresh.hidden = YES;
        if (refreshDeviceListTimer) {
            [refreshDeviceListTimer invalidate];
            refreshDeviceListTimer = nil;
        }
        [[ISControlManager sharedInstance] stopScaning];
    }
}

- (void)back {
    [[ISControlManager sharedInstance] stopScaning];
    [self.navigationController popViewControllerAnimated:YES];
    [[ISControlManager sharedInstance] setDeviceList:nil];
    [refreshDeviceListTimer invalidate];
    refreshDeviceListTimer = nil;
}

- (void)refreshList {
    [deviceList removeAllObjects];
    ISControlManager *manager = [ISControlManager sharedInstance];
    [manager stopScaning];
    [manager scanDeviceList:ISControlManagerTypeCB];
    [self.tableView reloadData];
}

-(void)actionButtonDisconnect:(UIButton *)sender {
    ISBLEDataPath *dataPath = [connectedList objectAtIndex:sender.tag];
    [[ISControlManager sharedInstance] disconnectDevice:dataPath];
}

-(void)actionButtonCancel:(UIButton *)sender {
    ISBLEDataPath *dataPath = [deviceList objectAtIndex:sender.tag];
    [[ISControlManager sharedInstance] disconnectDevice:dataPath];
}


#pragma mark - ISControlManagerDeviceList
- (void)didGetDeviceList:(NSArray *)devices andConnected:(NSArray *)connectList {
    [deviceList removeAllObjects];
    for (ISDataPath *d in devices) {
        if ([d isKindOfClass:[ISBLEDataPath class]]) {
            if ([connectList indexOfObject:d] == NSNotFound) {
                [deviceList addObject:d];
            }
        }
    }
    //[deviceList addObjectsFromArray:devices];
    [connectedList removeAllObjects];
    for (ISDataPath *d in connectList) {
        if ([d isKindOfClass:[ISBLEDataPath class]]) {
            [connectedList addObject:d];
        }
    }
    [self.tableView reloadData];
}

- (void)accessoryDidConnect:(ISDataPath *)accessory {
    ISBLEDataPath *dataPath = (ISBLEDataPath *)accessory;
    if (!dataPath.UUID) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"" message:@"Fail to get UUID" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
        [[ISControlManager sharedInstance] disconnectDevice:accessory];
        [self.tableView reloadData];
    }
    else {
        if (_delegate && [_delegate respondsToSelector:@selector(didSelectDevice:)]) {
            [[ISControlManager sharedInstance] disconnectDevice:accessory];
            [_delegate didSelectDevice:dataPath];
            [self.navigationController popViewControllerAnimated:YES];
        }
    }

}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    switch (section) {
        case 0:
            return [connectedList count];
            break;
        case 1:
            return [deviceList count];
        default:
            break;
    }
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
    }
    ISBLEDataPath *dataPath = nil;
    cell.accessoryView = nil;
    cell.detailTextLabel.text = nil;
    cell.accessoryView = nil;

    switch (indexPath.section) {
        case 0: {
            dataPath = [connectedList objectAtIndex:indexPath.row];
            cell.detailTextLabel.text = @"connected";
            UIButton *accessoryButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
            [accessoryButton addTarget:self action:@selector(actionButtonDisconnect:)  forControlEvents:UIControlEventTouchUpInside];
            accessoryButton.tag = indexPath.row;
            [accessoryButton setTitle:@"Disonnect" forState:UIControlStateNormal];
            [accessoryButton setFrame:CGRectMake(0,0,100,35)];
            cell.accessoryView  = accessoryButton;
            cell.textLabel.text = dataPath.name?dataPath.name:@"Unknow";
            break;
        }
        case 1: {
            dataPath = [deviceList objectAtIndex:indexPath.row];
            cell.textLabel.text = dataPath.advName?dataPath.advName:@"Unknow";
            if (dataPath.state == CBPeripheralStateConnecting) {
                cell.detailTextLabel.text = @"connecting";
                UIButton *accessoryButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
                [accessoryButton addTarget:self action:@selector(actionButtonCancel:)  forControlEvents:UIControlEventTouchUpInside];
                accessoryButton.tag = indexPath.row;
                [accessoryButton setTitle:@"Cancel" forState:UIControlStateNormal];
                [accessoryButton setFrame:CGRectMake(0,0,100,35)];
                cell.accessoryView  = accessoryButton;
            }
            break;
        }
        default:
            break;
    }
    // Configure the cell...
    
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
            
		default:
			break;
	}
	return title;
}

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

/*
#pragma mark - Navigation

// In a story board-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}

 */

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if (_delegate && [_delegate respondsToSelector:@selector(didSelectDevice:)]) {
        ISBLEDataPath *dataPath = [deviceList objectAtIndex:indexPath.row];
        if (!dataPath.UUID) {
            NSLog(@"UUID = nil, connect first");
            [[ISControlManager sharedInstance] connectDevice:dataPath];
            [self.tableView reloadData];
        }
        else {
            [_delegate didSelectDevice:dataPath];
            [self.navigationController popViewControllerAnimated:YES];
        }
    }
}
@end
