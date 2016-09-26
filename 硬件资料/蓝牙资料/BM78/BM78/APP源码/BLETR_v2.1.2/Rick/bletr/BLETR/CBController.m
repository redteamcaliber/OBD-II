//
//  CBController.m
//  BLETR
//
//  Created by user D500 on 12/2/15.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import "CBController.h"
#import "MyPeripheral.h"

@interface CBController()
{
    CBCentralManager *manager;
 //   NSMutableArray *devicesList;
    BOOL    notifyState;
    CBUUID *_transServiceUUID;
    CBUUID *_transTxUUID;
    CBUUID *_transRxUUID;
    CBUUID *_disUUID1;
    CBUUID *_disUUID2;
    BOOL    isISSCPeripheral;
    BOOL    _waitingBtPowerOnToScan;
    NSArray *_scanningUUID;
}
- (void)storeMyPeripheral: (CBPeripheral *)aPeripheral;
- (MyPeripheral *)retrieveMyPeripheral: (CBPeripheral *)aPeripheral From:(NSArray *)database;
- (BOOL) isLECapableHardware;
//- (void)addDiscoverPeripheral:(CBPeripheral *)aPeripheral advName:(NSString *)advName;
- (void)addDiscoverPeripheral:(CBPeripheral *)aPeripheral advData:(NSDictionary *)advData;
@end

@implementation CBController
@synthesize delegate;
@synthesize devicesList;
@synthesize connectedList;
@synthesize connectingList;
@synthesize isScanning;

- (id)init
{
    self = [super init];
    if (self) {
        // Custom initialization
        
        devicesList = [[NSMutableArray alloc] init];
        connectingList = [[NSMutableArray alloc] init];
        connectedList = [[NSMutableArray alloc] init];
        _transServiceUUID = nil;
        _transTxUUID = nil;
        _transRxUUID = nil;
        _disUUID1 = nil;
        _disUUID2 = nil;
        isScanning = NO;
        manager = [CBCentralManager alloc];
        if ([manager respondsToSelector:@selector(initWithDelegate:queue:options:)]) {
            manager = [manager initWithDelegate:self queue:nil options:@{CBCentralManagerOptionRestoreIdentifierKey: ISSC_RestoreIdentifierKey}];
        }
        else {
            manager = [manager initWithDelegate:self queue:nil];
        }
    }
    return self;
}



#pragma mark - View lifecycle

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}


- (void)dealloc {
    NSLog(@"CBController dealloc");
    for (MyPeripheral *p in devicesList) {
        [self disconnectDevice:p];
    }
    //[super dealloc];
}

- (void) startScanWithUUID:(NSArray *)uuids
{
    _waitingBtPowerOnToScan = NO;
    _scanningUUID = uuids;
    if ([self isLECapableHardware] == NO) {
        _waitingBtPowerOnToScan = YES;
    }
    else {
        NSLog(@"[CBController] start scan with uuid, %@", uuids);
        [manager scanForPeripheralsWithServices:uuids options:nil];
        isScanning = YES;
        [devicesList removeAllObjects];
        if ([connectingList count] > 0) {
            for (int i=0; i< [connectingList count]; i++) {
                MyPeripheral *connectingPeripheral = [connectingList objectAtIndex:i];
                
                if (connectingPeripheral.connectStatus == MYPERIPHERAL_CONNECT_STATUS_CONNECTING) {
                    [devicesList addObject:connectingPeripheral];
                }
                else {
                    [connectingList removeObjectAtIndex:i];
                }
            }
        }
    }
}

/*
- (void) startScan 
{
    NSLog(@"[CBController] start scan");
    [manager scanForPeripheralsWithServices:nil options:nil];
    [devicesList removeAllObjects];
    
}*/

/*
 Request CBCentralManager to stop scanning for heart rate peripherals
 */
- (void) stopScan 
{
    NSLog(@"[CBController] stop scan");
    isScanning = NO;
    [manager stopScan];
}

- (void)connectDevice:(MyPeripheral *) myPeripheral{
    NSLog(@"[CBController] connectDevice: %@", myPeripheral.advName);
    if (myPeripheral.connectStatus != MYPERIPHERAL_CONNECT_STATUS_IDLE)
        return;
     NSLog(@"[CBController] connectDevice2: %@", myPeripheral.advName);
    MyPeripheral *connectingPeripheral = nil;
    connectingPeripheral = [self retrieveMyPeripheral:myPeripheral.peripheral From:connectingList];
    if (connectingPeripheral)
        return;
    NSLog(@"[CBController] connectDevice3: %@", myPeripheral.advName);
    myPeripheral.connectStatus = MYPERIPHERAL_CONNECT_STATUS_CONNECTING;
    [connectingList addObject:myPeripheral];
    [manager connectPeripheral:myPeripheral.peripheral options:nil];  //connect to device
}

- (void)connectDeviceWithIdentifier:(NSUUID *)identifier {
    if ([manager respondsToSelector:@selector(retrievePeripheralsWithIdentifiers::)]) {
        NSArray *array = [manager retrievePeripheralsWithIdentifiers:@[identifier]];
        if ([array count]>0) {
            CBPeripheral *peripheral = [array objectAtIndex:0];
            MyPeripheral *myPeripheral = nil;
            myPeripheral = [self retrieveMyPeripheral:peripheral From:connectedList];
            if (!myPeripheral) {
                myPeripheral = [self addMyPeripheral:peripheral To:devicesList];
                [self connectDevice:myPeripheral];
            }
            
        }
    }
    else {
        CFUUIDRef uuid = CFUUIDCreateFromString(NULL, (__bridge  CFStringRef)[identifier UUIDString]);
        [manager retrievePeripherals:@[(__bridge_transfer id) uuid]];
    }
}

- (void)disconnectDevice: (MyPeripheral *)myPeripheral {
    NSLog(@"[CBController] disconnectDevice");
    myPeripheral.canSendData = NO;
    [myPeripheral setTransDataNotification:NO];
    dispatch_async(dispatch_queue_create("temp", NULL), ^{
        NSLog(@"[CBController] disconnectDevice : Wait for data clear");
        int count = 0;
        while (![myPeripheral.transmit canDisconnect] || myPeripheral.isNotifying) {
            //[NSThread sleepForTimeInterval:0.1];
            sleep(1);
            count++;
            if (count >= 10) {
                break;
            }
        }
        //dispatch_async(dispatch_get_main_queue(), ^{
        [manager cancelPeripheralConnection: myPeripheral.peripheral];
        //});
    });
}

- (void)addDiscoverPeripheral:(CBPeripheral *)aPeripheral advData:(NSDictionary *)advData {
    MyPeripheral *myPeripheral = nil;

    myPeripheral = [self addMyPeripheral:aPeripheral To:devicesList];
    myPeripheral.connectStatus = MYPERIPHERAL_CONNECT_STATUS_IDLE;
    [myPeripheral setAdvertiseData:advData];
   // NSLog(@"[CBController] deviceList count = %d", [devicesList count]);
    if (delegate &&[(NSObject *)delegate respondsToSelector:@selector(CBController:didUpdateDiscoveredPeripherals:)]) {
   //     NSLog(@"1");
        [delegate CBController:self didUpdateDiscoveredPeripherals:devicesList];
    }
}

- (void)storeMyPeripheral: (CBPeripheral *)aPeripheral {
    NSLog(@"storeMyPeripheral");
    MyPeripheral *myPeripheral = nil;

    myPeripheral = [self retrieveMyPeripheral:aPeripheral From:devicesList];
    if(!myPeripheral) {
        myPeripheral = [[MyPeripheral alloc] init];
        myPeripheral.peripheral = aPeripheral;
        NSLog(@"storeMyPeripheral new");
    }
   // if (myPeripheral.peripheral.state == CBPeripheralStateConnected) {
        myPeripheral.connectStatus = MYPERIPHERAL_CONNECT_STATUS_CONNECTED;
   //     NSLog(@"already connected");
   // }
   // else {
   //     myPeripheral.connectStatus = MYPERIPHERAL_CONNECT_STATUS_IDLE;
    //}
    [connectedList addObject:myPeripheral];
}

- (MyPeripheral *)addMyPeripheral:(CBPeripheral *)aPeripheral To:(NSMutableArray *)database {
    MyPeripheral *myPeripheral = nil;
    NSLog(@"addMyPeripheral1: %@", database);
    myPeripheral = [self retrieveMyPeripheral:aPeripheral From:database];
    if (!myPeripheral) {
        NSLog(@"addMyPeripheral3");
        myPeripheral = [[MyPeripheral alloc] init];
        myPeripheral.peripheral = aPeripheral;
        [database addObject:myPeripheral];
    }
    NSLog(@"addMyPeripheral2: %@", database);
    return myPeripheral;
}

- (MyPeripheral *)retrieveMyPeripheral:(CBPeripheral *)aPeripheral From:(NSArray *)database {
    MyPeripheral *myPeripheral = nil;
    for (uint8_t i = 0; i < [database count]; i++) {
        MyPeripheral *tmp = [database objectAtIndex:i];
        if (tmp.peripheral == aPeripheral) {
            myPeripheral = tmp;
            NSLog(@"retrieveMyPeripheral found");
            break;
        }
    }
    return myPeripheral;
}

/*
- (MyPeripheral *)retrieveMyPeripheral:(CBPeripheral *)aPeripheral {
    MyPeripheral *myPeripheral = nil;
    for (uint8_t i = 0; i < [connectedList count]; i++) {
        myPeripheral = [connectedList objectAtIndex:i];
        if (myPeripheral.peripheral == aPeripheral) {
            NSLog(@"retrieveMyPeripheral found");
            break;
        }
    }
    return myPeripheral;
}*/

- (void)removeMyPeripheral: (CBPeripheral *) aPeripheral {
    MyPeripheral *myPeripheral = nil;

    myPeripheral = [self retrieveMyPeripheral:aPeripheral From:connectingList];
    if (myPeripheral)
        [connectingList removeObject:myPeripheral];
    
    myPeripheral = [self retrieveMyPeripheral:aPeripheral From:connectedList];
    if (myPeripheral) {
        myPeripheral.connectStatus = MYPERIPHERAL_CONNECT_STATUS_IDLE;
        if (delegate && [(NSObject *)delegate respondsToSelector:@selector(CBController:didDisconnectedPeripheral:)])
            [delegate CBController:self didDisconnectedPeripheral:myPeripheral];
        //[self updateMyPeripheralForDisconnect:myPeripheral];
        [connectedList removeObject:myPeripheral];
        return;
    }
    
    myPeripheral = [self retrieveMyPeripheral:aPeripheral From:devicesList];
    if (myPeripheral) {
        myPeripheral.connectStatus = MYPERIPHERAL_CONNECT_STATUS_IDLE;
        if (delegate && [(NSObject *)delegate respondsToSelector:@selector(CBController:didDisconnectedPeripheral:)])
            [delegate CBController:self didDisconnectedPeripheral:myPeripheral];
    }
}

- (void)configureTransparentServiceUUID: (NSString *)serviceUUID txUUID:(NSString *)txUUID rxUUID:(NSString *)rxUUID {
    if (serviceUUID) {
        _transServiceUUID = [CBUUID UUIDWithString:serviceUUID];
        //[_transServiceUUID retain];
        _transTxUUID = [CBUUID UUIDWithString:txUUID];
        //[_transTxUUID retain];
        _transRxUUID = [CBUUID UUIDWithString:rxUUID];
        //[_transRxUUID retain];
    }
    else {
        _transServiceUUID = nil;
        _transTxUUID = nil;
        _transRxUUID = nil;
    }
}

- (void)configureDeviceInformationServiceUUID:(NSString *)UUID1 UUID2:(NSString *)UUID2{
    if (UUID1 || UUID2) {
        if (UUID1 != nil) {
            _disUUID1 = [CBUUID UUIDWithString:UUID1];
            //[_disUUID1 retain];
        }
        else _disUUID1 = nil;
        
        if (UUID2 != nil) {
            _disUUID2 = [CBUUID UUIDWithString:UUID2];
            //[_disUUID2 retain];
        }
        else _disUUID2 = nil;
    }
    else {
        _disUUID1 = nil;
        _disUUID2 = nil;
    }
}

/*
 Uses CBCentralManager to check whether the current platform/hardware supports Bluetooth LE. An alert is raised if Bluetooth LE is not enabled or is not supported.
 */
- (BOOL) isLECapableHardware
{
    NSString * state = nil;
    
    switch ([manager state]) 
    {
        case CBCentralManagerStateUnsupported:
            state = @"The platform/hardware doesn't support Bluetooth Low Energy.";
            break;
        case CBCentralManagerStateUnauthorized:
            state = @"The app is not authorized to use Bluetooth Low Energy.";
            break;
        case CBCentralManagerStatePoweredOff:
            state = @"Bluetooth is currently powered off.";
            break;
        case CBCentralManagerStatePoweredOn:
            NSLog(@"Bluetooth power on");
            if (_waitingBtPowerOnToScan) {
                [self startScanWithUUID:_scanningUUID];
            }
            return TRUE;
        case CBCentralManagerStateUnknown:
        default:
            return FALSE;
            
    }
    
    NSLog(@"Central manager state: %@", state);
    
    
  /*  UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Bluetooth alert"  message:state delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles: nil];
    [alertView show];*/
    //[alertView release];
    return FALSE;
}

#pragma mark - CBCentralManager delegate methods
/*
 Invoked whenever the central manager's state is updated.
 */
- (void) centralManagerDidUpdateState:(CBCentralManager *)central 
{
    [self isLECapableHardware];
}

- (void) centralManager:(CBCentralManager *)central willRestoreState:(NSDictionary *)dict {
    NSLog(@"willRestoreState %@",[dict description]);
}

/*
 Invoked when the central discovers heart rate peripheral while scanning.
 */
- (void) centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)aPeripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI 
{    
    NSLog(@"<---------\n[CBController] didDiscoverPeripheral, %@, count=%u, RSSI=%d, count=%d", aPeripheral.UUID, (int)[advertisementData count], [RSSI intValue], (int)[devicesList count]);

    NSLog(@"adv data = %@", advertisementData);
    NSLog(@"-------->");

    [self addDiscoverPeripheral:aPeripheral advData:advertisementData];
}

/*
 Invoked when the central manager retrieves the list of known peripherals.
 Automatically connect to first known peripheral
 */
- (void)centralManager:(CBCentralManager *)central didRetrievePeripherals:(NSArray *)peripherals
{
    NSLog(@"Retrieved peripheral: %u - %@", (int)[peripherals count], peripherals);
    if([peripherals count] >=1)
    {
        CBPeripheral *peripheral = [peripherals objectAtIndex:0];
        MyPeripheral *myPeripheral = nil;
        myPeripheral = [self retrieveMyPeripheral:peripheral From:connectedList];
        if (!myPeripheral) {
            myPeripheral = [self addMyPeripheral:peripheral To:devicesList];
            [self connectDevice:myPeripheral];
        }
    }
}

/*
 Invoked whenever a connection is succesfully created with the peripheral. 
 Discover available services on the peripheral
 */
- (void) centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)aPeripheral 
{    
    NSLog(@"[CBController] didConnectPeripheral, uuid=%@", aPeripheral.UUID);

    [aPeripheral setDelegate:self];

    [self storeMyPeripheral:aPeripheral];
    
    isISSCPeripheral = FALSE;
    NSMutableArray *uuids = [[NSMutableArray alloc] initWithObjects:[CBUUID UUIDWithString:UUIDSTR_DEVICE_INFO_SERVICE], [CBUUID UUIDWithString:UUIDSTR_ISSC_PROPRIETARY_SERVICE], [CBUUID UUIDWithString:UUIDSTR_ISSC_AIR_PATCH_SERVICE], nil];
    if (_transServiceUUID)
        [uuids addObject:_transServiceUUID];
    [aPeripheral discoverServices:uuids];
    //[uuids release];
}

/*
 Invoked whenever an existing connection with the peripheral is torn down. 
 Reset local variables
 */
- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)aPeripheral error:(NSError *)error
{
    NSLog(@"[CBController] didDisonnectPeripheral uuid = %@, error msg:%d, %@, %@", aPeripheral.UUID, (int)error.code ,[error localizedFailureReason], [error localizedDescription]);

    [self removeMyPeripheral:aPeripheral];
    
}

/*
 Invoked whenever the central manager fails to create a connection with the peripheral.
 */
- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)aPeripheral error:(NSError *)error
{
    NSLog(@"[CBController] Fail to connect to peripheral: %@ with error = %@", aPeripheral, [error localizedDescription]);
    [self removeMyPeripheral:aPeripheral];
}

#pragma mark - CBPeripheral delegate methods
/*
 Invoked upon completion of a -[discoverServices:] request.
 Discover available characteristics on interested services
 */
- (void) peripheral:(CBPeripheral *)aPeripheral didDiscoverServices:(NSError *)error 
{
    for (CBService *aService in aPeripheral.services) 
    {
        NSLog(@"[CBController] Service found with UUID: %@", aService.UUID);
      //  NSArray *uuids = [[NSArray alloc] initWithObjects:[CBUUID UUIDWithString:@"2A4D"], nil];
        [aPeripheral discoverCharacteristics:nil forService:aService];
      //  [uuids release];
    }
}

/*
 Invoked upon completion of a -[discoverCharacteristics:forService:] request.
 Perform appropriate operations on interested characteristics
 */
- (void) peripheral:(CBPeripheral *)aPeripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error
{
    NSLog(@"\n[CBController] didDiscoverCharacteristicsForService: %@", service.UUID);
    CBCharacteristic *aChar = nil;
    MyPeripheral *myPeripheral = [self retrieveMyPeripheral:aPeripheral From:connectedList];
    if (myPeripheral == nil) {
        return;
    }

    if (_transServiceUUID && [service.UUID isEqual:_transServiceUUID]) {
        isISSCPeripheral = TRUE;
        myPeripheral.canSendData = YES;
        for (aChar in service.characteristics)
        {
            if ([aChar.UUID isEqual:_transRxUUID]) {
                [myPeripheral setTransparentDataWriteChar:aChar];
                NSLog(@"found custom TRANS_RX");
            }
            else if ([aChar.UUID isEqual:_transTxUUID]) {
                NSLog(@"found custome TRANS_TX");
                [myPeripheral setTransparentDataReadChar:aChar];
              //  [aPeripheral setNotifyValue:TRUE forCharacteristic:aChar];
            }
        }
    }
    else if ([service.UUID isEqual:[CBUUID UUIDWithString:UUIDSTR_ISSC_PROPRIETARY_SERVICE]] || [service.UUID isEqual:[CBUUID UUIDWithString:UUIDSTR_ISSC_AIR_PATCH_SERVICE]]) {
        isISSCPeripheral = TRUE;
        myPeripheral.canSendData = YES;
        for (aChar in service.characteristics)
        {
            if ((_transServiceUUID == nil) && [aChar.UUID isEqual:[CBUUID UUIDWithString:UUIDSTR_ISSC_TRANS_RX]]) {
                [myPeripheral setTransparentDataWriteChar:aChar];
                NSLog(@"found TRANS_RX");
                
            }
            else if ((_transServiceUUID == nil) && [aChar.UUID isEqual:[CBUUID UUIDWithString:UUIDSTR_ISSC_TRANS_TX]]) {
                 NSLog(@"found TRANS_TX");
                [myPeripheral setTransparentDataReadChar:aChar];
                //[aPeripheral setNotifyValue:TRUE forCharacteristic:aChar];
            }
            else if ([aChar.UUID isEqual:[CBUUID UUIDWithString:UUIDSTR_CONNECTION_PARAMETER_CHAR]]) {
                [myPeripheral setConnectionParameterChar:aChar];
                 NSLog(@"found CONNECTION_PARAMETER_CHAR");
            }
            else if ([aChar.UUID isEqual:[CBUUID UUIDWithString:UUIDSTR_AIR_PATCH_CHAR]]) {
                [myPeripheral setAirPatchChar:aChar];
                NSLog(@"found UUIDSTR_AIR_PATCH_CHAR");
                [myPeripheral.transmit enableReliableBurstTransmit:myPeripheral.peripheral andAirPatchCharacteristic:myPeripheral.airPatchChar];
            }
        }
    }
    else if([service.UUID isEqual:[CBUUID UUIDWithString:UUIDSTR_DEVICE_INFO_SERVICE]]) {

        for (aChar in service.characteristics)
        {
            if ([aChar.UUID isEqual:[CBUUID UUIDWithString:UUIDSTR_MANUFACTURE_NAME_CHAR]]) {
                [myPeripheral setManufactureNameChar:aChar];
                NSLog(@"found manufacture name char");
            }
            else if ([aChar.UUID isEqual:[CBUUID UUIDWithString:UUIDSTR_MODEL_NUMBER_CHAR]]) {
                [myPeripheral setModelNumberChar:aChar];
                    NSLog(@"found model number char");

            }
            else if ([aChar.UUID isEqual:[CBUUID UUIDWithString:UUIDSTR_SERIAL_NUMBER_CHAR]]) {
                [myPeripheral setSerialNumberChar:aChar];
                NSLog(@"found serial number char");
            }
            else if ([aChar.UUID isEqual:[CBUUID UUIDWithString:UUIDSTR_HARDWARE_REVISION_CHAR]]) {
                [myPeripheral setHardwareRevisionChar:aChar];
                NSLog(@"found hardware revision char");
            }
            else if ([aChar.UUID isEqual:[CBUUID UUIDWithString:UUIDSTR_FIRMWARE_REVISION_CHAR]]) {
                [myPeripheral setFirmwareRevisionChar:aChar];
                NSLog(@"found firmware revision char");
            }
            else if ([aChar.UUID isEqual:[CBUUID UUIDWithString:UUIDSTR_SOFTWARE_REVISION_CHAR]]) {
                [myPeripheral setSoftwareRevisionChar:aChar];
                NSLog(@"found software revision char");
            }
            else if ([aChar.UUID isEqual:[CBUUID UUIDWithString:UUIDSTR_SYSTEM_ID_CHAR]]) {
                [myPeripheral setSystemIDChar:aChar];
                NSLog(@"[CBController] found system ID char");
            }
            else if ([aChar.UUID isEqual:[CBUUID UUIDWithString:UUIDSTR_IEEE_11073_20601_CHAR]]) {
                [myPeripheral setCertDataListChar:aChar];
                NSLog(@"found certification data list char");
            }
            else if (_disUUID1 && [aChar.UUID isEqual:_disUUID1]) {
                [myPeripheral setSpecificChar1:aChar];
                NSLog(@"found specific char1");
            }
            else if (_disUUID2 && [aChar.UUID isEqual:_disUUID2]) {
                [myPeripheral setSpecificChar2:aChar];
                NSLog(@"found specific char2");
            }
        }
    }
    
    if (isISSCPeripheral == TRUE) {
        for (int idx =0; idx< [connectingList count]; idx++) {
            MyPeripheral *tmpPeripheral = [connectingList objectAtIndex:idx];
            if (tmpPeripheral == myPeripheral) {
                NSLog(@"connectingList removeObject:%@",tmpPeripheral.advName);
                [connectingList removeObjectAtIndex:idx];
                break;
            }
        }
        
        for (int idx =0; idx< [devicesList count]; idx++) {
            MyPeripheral *tmpPeripheral = [devicesList objectAtIndex:idx];
            if (tmpPeripheral == myPeripheral) {
                NSLog(@"devicesList removeObject:%@",tmpPeripheral.advName);
                [devicesList removeObjectAtIndex:idx];
                break;
            }
        }
        if (delegate && [(NSObject *)delegate respondsToSelector:@selector(CBController:didConnectedPeripheral:)])
            [delegate CBController:self didConnectedPeripheral:myPeripheral];
        //[self updateMyPeripheralForNewConnected:myPeripheral];
    }
}

/*
 Invoked upon completion of a -[readValueForCharacteristic:] request or on the reception of a notification/indication.
 */
- (void) peripheral:(CBPeripheral *)aPeripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error 
{
    MyPeripheral *myPeripheral = [self retrieveMyPeripheral:aPeripheral From:connectedList];
    if (myPeripheral == nil) {
        return;
    }
    NSLog(@"[CBController] didUpdateValueForCharacteristic %@",[characteristic  value]);
    
    if ([characteristic.service.UUID isEqual:[CBUUID UUIDWithString:UUIDSTR_DEVICE_INFO_SERVICE]]) {
        if (myPeripheral.deviceInfoDelegate == nil)
            return;
        if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:UUIDSTR_MANUFACTURE_NAME_CHAR]]) {
            NSLog(@"[CBController] update manufacture name");
            
            if ([(NSObject *)myPeripheral.deviceInfoDelegate respondsToSelector:@selector(MyPeripheral:didUpdateManufactureName:error:)]) {
                [[myPeripheral deviceInfoDelegate] MyPeripheral:myPeripheral didUpdateManufactureName:[[NSString alloc] initWithData:characteristic.value encoding:NSUTF8StringEncoding] error:error];
            }
        }
        else if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:UUIDSTR_MODEL_NUMBER_CHAR]]) {
            NSLog(@"[CBController] update model number");

            
            if ([(NSObject *)myPeripheral.deviceInfoDelegate respondsToSelector:@selector(MyPeripheral:didUpdateModelNumber:error:)]) {
                [myPeripheral.deviceInfoDelegate MyPeripheral:myPeripheral didUpdateModelNumber:[[NSString alloc] initWithData:characteristic.value encoding:NSUTF8StringEncoding] error:error];
            }
        }
        else if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:UUIDSTR_SERIAL_NUMBER_CHAR]]) {
            NSLog(@"[CBController] update serial number");
            
            if ([(NSObject *)myPeripheral.deviceInfoDelegate respondsToSelector:@selector(MyPeripheral:didUpdateSerialNumber:error:)]) {
                [myPeripheral.deviceInfoDelegate MyPeripheral:myPeripheral didUpdateSerialNumber:[[NSString alloc] initWithData:characteristic.value encoding:NSUTF8StringEncoding] error:error];
            }
        }
        else if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:UUIDSTR_HARDWARE_REVISION_CHAR]]) {
            NSLog(@"[CBController] update hardware revision");

            
            if ([(NSObject *)myPeripheral.deviceInfoDelegate respondsToSelector:@selector(MyPeripheral:didUpdateHardwareRevision:error:)]){
                [myPeripheral.deviceInfoDelegate MyPeripheral:myPeripheral didUpdateHardwareRevision:[[NSString alloc] initWithData:characteristic.value encoding:NSUTF8StringEncoding] error:error];
            }
        }
        else if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:UUIDSTR_FIRMWARE_REVISION_CHAR]]) {
            NSLog(@"[CBController] update firmware revision");

            
            if ([(NSObject *)myPeripheral.deviceInfoDelegate respondsToSelector:@selector(MyPeripheral:didUpdateFirmwareRevision:error:)]){
                [myPeripheral.deviceInfoDelegate MyPeripheral:myPeripheral didUpdateFirmwareRevision:[[NSString alloc] initWithData:characteristic.value encoding:NSUTF8StringEncoding] error:error];
            }
        }
        else if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:UUIDSTR_SOFTWARE_REVISION_CHAR]]) {

            NSLog(@"[CBController] update software revision");

            if ([(NSObject *)myPeripheral.deviceInfoDelegate respondsToSelector:@selector(MyPeripheral:didUpdateSoftwareRevision:error:)]){
                [myPeripheral.deviceInfoDelegate MyPeripheral:myPeripheral didUpdateSoftwareRevision:[[NSString alloc] initWithData:characteristic.value encoding:NSUTF8StringEncoding] error:error];
            }
        }
        else if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:UUIDSTR_SYSTEM_ID_CHAR]]) {
            NSLog(@"[CBController] update system ID");

            if ([(NSObject *)myPeripheral.deviceInfoDelegate respondsToSelector:@selector(MyPeripheral:didUpdateSystemId:error:)]){
                
                [myPeripheral.deviceInfoDelegate MyPeripheral:myPeripheral didUpdateSystemId:characteristic.value error:error];
                
            }
        }
        else if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:UUIDSTR_IEEE_11073_20601_CHAR]]) {
            NSLog(@"[CBController] update IEEE_11073_20601: %@",characteristic.value);
            
            if ([(NSObject *)myPeripheral.deviceInfoDelegate respondsToSelector:@selector(MyPeripheral:didUpdateIEEE_11073_20601:error:)]){
                
                [myPeripheral.deviceInfoDelegate MyPeripheral:myPeripheral didUpdateIEEE_11073_20601:characteristic.value error:error];
                
            }
        }
        else if (_disUUID1 && [characteristic.UUID isEqual:_disUUID1]) {
            NSLog(@"[CBController] update specific UUID 1: %@",characteristic.value);
            
            if ([(NSObject *)myPeripheral.deviceInfoDelegate respondsToSelector:@selector(MyPeripheral:didUpdateSpecificUUID1:error:)]){
                [myPeripheral.deviceInfoDelegate MyPeripheral:myPeripheral didUpdateSpecificUUID1:characteristic.value error:error];
            }
        }
        else if (_disUUID2 && [characteristic.UUID isEqual:_disUUID2]) {
            NSLog(@"[CBController] update specific UUID 2: %@",characteristic.value);
            
            if ([(NSObject *)myPeripheral.deviceInfoDelegate respondsToSelector:@selector(MyPeripheral:didUpdateSpecificUUID2:error:)]){
                [myPeripheral.deviceInfoDelegate MyPeripheral:myPeripheral didUpdateSpecificUUID2:characteristic.value error:error];
            }
        }
    }
    else if ([characteristic.service.UUID isEqual:[CBUUID UUIDWithString:UUIDSTR_ISSC_PROPRIETARY_SERVICE]] || [characteristic.service.UUID isEqual:[CBUUID UUIDWithString:UUIDSTR_ISSC_AIR_PATCH_SERVICE]]) {
        if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:UUIDSTR_CONNECTION_PARAMETER_CHAR]]) {
            NSLog(@"[CBController] update connection parameter: %@", characteristic.value);
            unsigned char buf[10];
            CONNECTION_PARAMETER_FORMAT *parameter;
            
            [characteristic.value getBytes:&buf[0] length:sizeof(CONNECTION_PARAMETER_FORMAT)];
            parameter = (CONNECTION_PARAMETER_FORMAT *)&buf[0];

            //NSLog(@"[CBController] %02X, %02x, %02x, %02x, %02X, %02x, %02x, %02x, %02x,status= %d, min= %f,max= %f, latency=%d, timeout=%d", buf[0],buf[1],buf[2],buf[3],buf[4],buf[5],buf[6],buf[7],buf[8],parameter->status, parameter->minInterval*1.25, parameter->maxInterval*1.25, parameter->latency, parameter->connectionTimeout*10);
            
            //first time read
            if ([myPeripheral retrieveBackupConnectionParameter]->status == 0xff) {
                [myPeripheral updateBackupConnectionParameter:parameter];
            }
            else {
                switch (myPeripheral.updateConnectionParameterStep) {
                    case UPDATE_PARAMETERS_STEP_PREPARE:
                        if ((myPeripheral.proprietaryDelegate != nil) && ([(NSObject *)myPeripheral.proprietaryDelegate respondsToSelector:@selector(MyPeripheral:didUpdateConnectionParameterAllowStatus:)]))
                            [myPeripheral.proprietaryDelegate MyPeripheral:myPeripheral didUpdateConnectionParameterAllowStatus:(buf[0] == 0x00)];
                            break;
                    case UPDATE_PARAMETERS_STEP_CHECK_RESULT:
                        if (buf[0] != 0x00) {
                            NSLog(@"[CBController] check connection parameter status again");
                            [myPeripheral checkConnectionParameterStatus];
                        }
                        else {
                            if ((myPeripheral.proprietaryDelegate != nil) && ([(NSObject *)myPeripheral.proprietaryDelegate respondsToSelector:@selector(MyPeripheral:didUpdateConnectionParameterStatus:interval:timeout:latency:)])){
                                if ([myPeripheral compareBackupConnectionParameter:parameter] == TRUE) {
                                    NSLog(@"[CBController] connection parameter no change");
                                    [myPeripheral.proprietaryDelegate MyPeripheral:myPeripheral didUpdateConnectionParameterStatus:FALSE interval:parameter->maxInterval*1.25 timeout:parameter->connectionTimeout*10 latency:parameter->latency];
                                }
                                else {
                                    //NSLog(@"connection parameter update success");
                                    [myPeripheral.proprietaryDelegate MyPeripheral:myPeripheral didUpdateConnectionParameterStatus:TRUE interval:parameter->maxInterval*1.25 timeout:parameter->connectionTimeout*10 latency:parameter->latency];
                                    [myPeripheral updateBackupConnectionParameter:parameter];
                                }
                            }
                        }
                    default:
                        break;
                }
           }
        }
        else if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:UUIDSTR_AIR_PATCH_CHAR]]) {
            [myPeripheral updateAirPatchEvent:characteristic.value];
        }
        else if ((_transServiceUUID == nil) && [characteristic.UUID isEqual:[CBUUID UUIDWithString:UUIDSTR_ISSC_TRANS_TX]]) {
            if ((myPeripheral.transDataDelegate != nil) && ([(NSObject *)myPeripheral.transDataDelegate respondsToSelector:@selector(MyPeripheral:didReceiveTransparentData:)])) {
                [myPeripheral.transDataDelegate MyPeripheral:myPeripheral didReceiveTransparentData:characteristic.value];
            }
        }
    }
    else if (_transServiceUUID && [characteristic.service.UUID isEqual:_transServiceUUID]) {
        if ([characteristic.UUID isEqual:_transTxUUID]) {
            if ((myPeripheral.transDataDelegate != nil) && ([(NSObject *)myPeripheral.transDataDelegate respondsToSelector:@selector(MyPeripheral:didReceiveTransparentData:)])) {
                [myPeripheral.transDataDelegate MyPeripheral:myPeripheral didReceiveTransparentData:characteristic.value];
            }
        }
    }
}

- (void) peripheral:(CBPeripheral *)aPeripheral didWriteValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error 
{
    NSLog(@"[CBController] didWriteValueForCharacteristic error msg:%d, %@, %@", (int)error.code ,[error localizedFailureReason], [error localizedDescription]);
    NSLog(@"characteristic data = %@ id = %@",characteristic.value,characteristic.UUID);
    MyPeripheral *myPeripheral = [self retrieveMyPeripheral:aPeripheral From:connectedList];
    if (myPeripheral == nil) {
        return;
    }
    if ([myPeripheral.transmit isReliableBurstTransmit:characteristic]) {
        return;
    }
    if ((_transServiceUUID == nil) && [characteristic.UUID isEqual:[CBUUID UUIDWithString:UUIDSTR_ISSC_TRANS_RX]]) {
        if ((myPeripheral.transDataDelegate != nil) && ([(NSObject *)myPeripheral.transDataDelegate respondsToSelector:@selector(MyPeripheral:didSendTransparentDataStatus:)])) {
            [myPeripheral.transDataDelegate MyPeripheral:myPeripheral didSendTransparentDataStatus:error];
        }
    }
    else if (_transServiceUUID && [characteristic.UUID isEqual:_transRxUUID]) {
        if ((myPeripheral.transDataDelegate != nil) && ([(NSObject *)myPeripheral.transDataDelegate respondsToSelector:@selector(MyPeripheral:didSendTransparentDataStatus:)])) {
            [myPeripheral.transDataDelegate MyPeripheral:myPeripheral didSendTransparentDataStatus:error];
        }
    }
}

- (void) peripheral:(CBPeripheral *)aPeripheral didDiscoverDescriptorsForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    NSLog(@"[CBController] didDiscoverDescriptorsForCharacteristic error msg:%d, %@, %@", (int)error.code ,[error localizedFailureReason], [error localizedDescription]);
}

- (void) peripheral:(CBPeripheral *)peripheral didUpdateValueForDescriptor:(CBDescriptor *)descriptor error:(NSError *)error
{
    NSLog(@"[CBController] didUpdateValueForDescriptor");
}

-(void) peripheral:(CBPeripheral *)peripheral didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    NSLog(@"[CBController] didUpdateNotificationStateForCharacteristic, UUID = %@", characteristic.UUID);
    MyPeripheral *myPeripheral = [self retrieveMyPeripheral:peripheral From:connectedList];
    if (myPeripheral == nil) {
        return;
    }
    if ((myPeripheral.transDataDelegate != nil) && ([(NSObject *)myPeripheral.transDataDelegate respondsToSelector:@selector(MyPeripheral:didUpdateTransDataNotifyStatus:)])) {
        [myPeripheral.transDataDelegate MyPeripheral:myPeripheral didUpdateTransDataNotifyStatus:characteristic.isNotifying];
        myPeripheral.isNotifying = characteristic.isNotifying;
    }
    
}

@end
