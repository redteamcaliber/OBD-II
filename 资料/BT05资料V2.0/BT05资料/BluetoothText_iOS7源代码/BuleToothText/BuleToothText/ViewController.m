//
//  ViewController.m
//  BuleToothText
//
//  Created by try on 14-12-29.
//  Copyright (c) 2014年 TRY. All rights reserved.
//

#import <CoreBluetooth/CoreBluetooth.h>
#import "BLEDeviceViewController.h"
#import "ViewController.h"
#import "SerialGATT.h"
#import "MJRefresh.h"

#define kHIGHT [UIScreen mainScreen].bounds.size.height
#define kWIGTH [UIScreen mainScreen].bounds.size.width

@interface ViewController ()<UITableViewDataSource,UITableViewDelegate,MJRefreshBaseViewDelegate,CBPeripheralManagerDelegate,UIAlertViewDelegate,BTSmartSensorDelegate>

@property (nonatomic,strong) UISwitch * swi;
@property (nonatomic,strong) UILabel * L1;
@property (nonatomic,strong) UITableView * mainTableView;
@property (nonatomic,strong) MJRefreshHeaderView *headerRefreshView;
@property (nonatomic,strong) CBPeripheralManager * centralManager;
@property (nonatomic,strong) UIButton * Scan;

@end

@implementation ViewController

@synthesize sensor;
@synthesize peripheralViewControllerArray;


-(void)dealloc{
    [self.headerRefreshView free];
    
}

// GET方法
-(MJRefreshHeaderView *)headerRefreshView{
    if (!_headerRefreshView) {
        _headerRefreshView = [[MJRefreshHeaderView alloc] init];
        _headerRefreshView.scrollView = _mainTableView;
        _headerRefreshView.delegate = self;
    }
    return _headerRefreshView;
}

#pragma mark MJRefreshBaseViewDelegate
// 松手触发
-(void)refreshViewBeginRefreshing:(MJRefreshBaseView *)refreshView{
    // 发起网络请求
    // endRefreshing写在数据请求完毕时
        
        [self scaning:_Scan];
        
        [self performSelector:@selector(endRefreshing:) withObject:refreshView afterDelay:3];
 
    
}

-(void)endRefreshing:(MJRefreshBaseView *)refreshView{
    if (refreshView == self.headerRefreshView) {
        
        [self.headerRefreshView endRefreshing];
    }
    [_mainTableView reloadData];
}

- (void)peripheralManagerDidUpdateState:(CBPeripheralManager *)peripheral{
    
    switch (peripheral.state) {
            //蓝牙开启且可用
        case CBPeripheralManagerStatePoweredOn:
            break;
        default:
            break;
    }
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
    
    sensor = [[SerialGATT alloc] init];
    [sensor setup];
    sensor.delegate = self;
    
    peripheralViewControllerArray = [[NSMutableArray alloc] init];

    self.centralManager = [[CBPeripheralManager alloc] initWithDelegate:self queue:nil];
    
    // Do any additional setup after loading the view from its nib.
    [self AddNavigationItemThing];//布局界面
    
    self.automaticallyAdjustsScrollViewInsets = NO;
    _mainTableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 64, kWIGTH, kHIGHT-80) style:UITableViewStylePlain];
    _mainTableView.delegate = self;
    _mainTableView.dataSource = self;
    [self.view addSubview:_mainTableView];
    _mainTableView.tableHeaderView = [self creatView];

    [self.headerRefreshView endRefreshing];
    
}

//布局界面
- (void)AddNavigationItemThing {
    
    UIView * view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 260, 44)];
    UILabel * label = [[UILabel alloc] initWithFrame:CGRectMake(80, 10, 100, 44)];
    label.text = @"Bolutek";
    label.textAlignment = UITextAlignmentCenter;
    [view addSubview:label];
    self.navigationItem.titleView = view;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (UIView *)creatView {
    
    UIView * view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 80)];
    UIButton * but = [UIButton buttonWithType:UIButtonTypeSystem];
    but.frame = CGRectMake(30, 30, 60, 30);
    [but setTitle:@"版本升级" forState:UIControlStateNormal];
    [but setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
    [but addTarget:self action:@selector(but) forControlEvents:UIControlEventTouchUpInside];
    [but setTintColor:[UIColor blackColor]];
    [view addSubview:but];
    
    _Scan = [UIButton buttonWithType:UIButtonTypeSystem];
    _Scan.frame = CGRectMake(130, 30, 60, 30);
    [_Scan setTitle:@"搜索设备" forState:UIControlStateNormal];
    [_Scan setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
    [_Scan addTarget:self action:@selector(scaning:) forControlEvents:UIControlEventTouchUpInside];
    [_Scan setTintColor:[UIColor blackColor]];
    [view addSubview:_Scan];
    
    UIButton * about = [UIButton buttonWithType:UIButtonTypeSystem];
    about.frame = CGRectMake(230, 30, 60, 30);
    [about setTitle:@"关于我们" forState:UIControlStateNormal];
    [about setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
    [about addTarget:self action:@selector(about) forControlEvents:UIControlEventTouchUpInside];
    [about setTintColor:[UIColor blackColor]];
    [view addSubview:about];
    return view;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    return [self.peripheralViewControllerArray count];
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [sensor.manager stopScan];
    NSUInteger row = [indexPath row];
   [self.headerRefreshView endRefreshing];
    BLEDeviceViewController *controller = [peripheralViewControllerArray objectAtIndex:row];
    if (sensor.activePeripheral && sensor.activePeripheral != controller.peripheral) {
        [sensor disconnect:sensor.activePeripheral];
    }
    
    sensor.activePeripheral = controller.peripheral;
    
    [sensor connect:sensor.activePeripheral];
    
    [self.navigationController pushViewController:controller animated:YES];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *cellId = @"peripheral";
    UITableViewCell * cell = [tableView dequeueReusableCellWithIdentifier:cellId];
    if ( cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellId];
    }
    // Configure the cell
    NSUInteger row = [indexPath row];
    BLEDeviceViewController *controller = [peripheralViewControllerArray objectAtIndex:row];
    CBPeripheral *peripheral = [controller peripheral];
    cell.textLabel.text = peripheral.name;
    //cell.detailTextLabel.text = [NSString stringWithFormat:<#(NSString *), ...#>
    cell.accessoryType = UITableViewCellAccessoryDetailDisclosureButton;
    return cell;
}

#pragma mark - BLKSoftSensorDelegate
-(void)sensorReady
{
    //TODO: it seems useless right now.
}

-(void) peripheralFound:(CBPeripheral *)peripheral
{
    BLEDeviceViewController *controller = [[BLEDeviceViewController alloc] init];
    controller.peripheral = peripheral;
    controller.sensor = sensor;
    [peripheralViewControllerArray addObject:controller];
    [_mainTableView reloadData];
}

- (void)but {
    
    UIAlertView * alert = [[UIAlertView alloc] initWithTitle:@"通知" message:@"此功能正在上线，敬请等待，谢谢" delegate:self cancelButtonTitle:@"返回" otherButtonTitles: nil];
    [alert show];
}
- (void)scaning:(UIButton *)Scan {
    
        if ([sensor activePeripheral]) {
            if ([sensor.activePeripheral isConnected]) {
                [sensor.manager cancelPeripheralConnection:sensor.activePeripheral];
                sensor.activePeripheral = nil;
            }
        }
        
        if ([sensor peripherals]) {
            
            sensor.peripherals = nil;
            [peripheralViewControllerArray removeAllObjects];
            [_mainTableView reloadData];
        }
        
        sensor.delegate = self;
        printf("now we are searching device...\n");
        [Scan setTitle:@"正在搜索" forState:UIControlStateNormal];
        [NSTimer scheduledTimerWithTimeInterval:5 target:self selector:@selector(scanTimer:) userInfo:nil repeats:NO];
        
        [sensor findBLKSoftPeripherals:5];
    
}
-(void) scanTimer:(NSTimer *)timer
{
    [_Scan setTitle:@"搜索设备" forState:UIControlStateNormal];
}


- (void)about {
    
    UIAlertView * alert = [[UIAlertView alloc] initWithTitle:@"欢迎您的支持" message:@"   我们是一家高科技无线智能产品开发公司。专业致力于蓝牙/WIFI等无线技术的相关智能产品的研发设计及生产，诚信协作是我们的团队精神。\n我们的网址:http://www.bolutek.cn/。" delegate:self cancelButtonTitle:@"谢谢您的支持" otherButtonTitles: nil];
    [alert show];
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
