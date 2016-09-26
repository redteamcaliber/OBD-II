//
//  MyPeripheral.m
//  BLETR
//
//  Created by D500 user on 13/5/30.
//  Copyright (c) 2013年 ISSC. All rights reserved.
//

#import "MyPeripheral.h"
#import "ISError.h"
#import "ReliableBurstData.h"
@interface MyPeripheral () {
    BOOL isEndableTransparent;
}
@end

@implementation MyPeripheral
@synthesize peripheral;
@synthesize transDataDelegate;
@synthesize proprietaryDelegate;
@synthesize deviceInfoDelegate;

@synthesize airPatchChar;
@synthesize transparentDataWriteChar;
@synthesize transparentDataReadChar;
@synthesize connectionParameterChar;
@synthesize backupConnectionParameter;
@synthesize connectionParameter;

@synthesize manufactureNameChar;
@synthesize modelNumberChar;
@synthesize serialNumberChar;
@synthesize hardwareRevisionChar;
@synthesize firmwareRevisionChar;
@synthesize softwareRevisionChar;
@synthesize systemIDChar;
@synthesize certDataListChar;
@synthesize specificChar1;
@synthesize specificChar2;

@synthesize advName;

- (MyPeripheral *)init {
    self = [super init];
    if (self) {
        transDataDelegate = nil;
        proprietaryDelegate = nil;
        deviceInfoDelegate = nil;
        queuedTask = [[NSMutableArray alloc] init];
        self.transparentDataWriteChar = nil;
        self.transparentDataReadChar = nil;
        self.connectStatus = MYPERIPHERAL_CONNECT_STATUS_IDLE;
        _canSendData = NO;
        _transmit = [[ReliableBurstData alloc] init];
        //NSLog(@"%@",[_transmit version]);
    }
    return self;
}

-(void)dealloc {
    //[queuedTask release];
    //[_transmit release];
    _transmit = nil;
    //[super dealloc];
}

- (NSString *)advName {
    NSString *name = nil;
    name = [self.advertiseData valueForKey:CBAdvertisementDataLocalNameKey];
    if (name == nil || [name length] == 0) {
        name = [peripheral name];
    }
    return name;
}

- (NSString *)deviceName {
    return [peripheral name];
}

- (NSData *)manuData {
    return [self.advertiseData objectForKey:CBAdvertisementDataManufacturerDataKey];
}

- (NSArray *)serviceUUIDs {
    return [self.advertiseData objectForKey:CBAdvertisementDataServiceUUIDsKey];
}

- (NSDictionary *)serviceData {
    return [self.advertiseData objectForKey:CBAdvertisementDataServiceDataKey];
}

- (NSString *)uuidString {
    NSString *str = nil;
    if ([peripheral respondsToSelector:@selector(identifier)]) {
        NSLog(@"uuidString iOS 7 later, %@, %@", peripheral.identifier, [peripheral.identifier UUIDString]);
        str = [peripheral.identifier UUIDString];
    }
    else {
        str = (__bridge_transfer NSString*)CFUUIDCreateString(NULL, peripheral.UUID);
        NSLog(@"uuidString iOS 6");
    }
    return str;
}

//DIS
- (void)readManufactureName {
    // NSLog(@"[MyPeripheral] readManufactureName");
    if (manufactureNameChar == nil) {
    }
    [peripheral readValueForCharacteristic:manufactureNameChar];
}

- (void)readModelNumber {
    // NSLog(@"[MyPeripheral] readModelNumber");
    [peripheral readValueForCharacteristic:modelNumberChar];
    
}

- (void)readSerialNumber {
    // NSLog(@"[MyPeripheral] readSerialNumber");
    [peripheral readValueForCharacteristic:serialNumberChar];
}

- (void)readHardwareRevision {
    //NSLog(@"[MyPeripheral] readHardwareRevision");
    [peripheral readValueForCharacteristic:hardwareRevisionChar];
}

- (void)readFirmwareRevision {
    //NSLog(@"[MyPeripheral] readFirmwareRevision");
    [peripheral readValueForCharacteristic:firmwareRevisionChar];
}

- (void)readSoftwareRevison {
    //NSLog(@"[MyPeripheral] readSoftwareRevison");
    [peripheral readValueForCharacteristic:softwareRevisionChar];
}

- (void)readSystemID {
    //NSLog(@"[MyPeripheral] readSystemID");
    [peripheral readValueForCharacteristic:systemIDChar];
}

- (void)readCertificationData {
    //NSLog(@"[MyPeripheral] readCertificationData");
    [peripheral readValueForCharacteristic:certDataListChar];
}

- (void)readSpecificUUID1 {
    //NSLog(@"[MyPeripheral] readCertificationData");
    [peripheral readValueForCharacteristic:specificChar1];
}

- (void)readSpecificUUID2 {
    //NSLog(@"[MyPeripheral] readCertificationData");
    [peripheral readValueForCharacteristic:specificChar2];
}

//Proprietary
- (CBCharacteristicWriteType)sendTransparentData:(NSData *)data type:(CBCharacteristicWriteType)type {
    NSLog(@"[MyPeripheral] sendTransparentData:%@", data);
    if (!_canSendData) {
        return CBCharacteristicWriteWithResponse;
    }
    if (transparentDataWriteChar == nil) {
        return CBCharacteristicWriteWithResponse;
    }
    CBCharacteristicWriteType actualType = type;
    if (type == CBCharacteristicWriteWithResponse) {
        if (!(transparentDataWriteChar.properties & CBCharacteristicPropertyWrite))
            actualType = CBCharacteristicWriteWithoutResponse;
    }
    else {
        if (!(transparentDataWriteChar.properties & CBCharacteristicPropertyWriteWithoutResponse))
            actualType = CBCharacteristicWriteWithResponse;
    }
    if (actualType == CBCharacteristicWriteWithoutResponse) {
        [_transmit reliableBurstTransmit:data withTransparentCharacteristic:transparentDataWriteChar];
    }
    else {
        [peripheral writeValue:data forCharacteristic:transparentDataWriteChar type:actualType];
    }

    return actualType;
}

- (void)setTransDataNotification:(BOOL)notify {
    NSLog(@"[MyPeripheral] setTransDataNotification UUID = %@",transparentDataReadChar.UUID);
    if (transparentDataReadChar != nil && (_isNotifying != notify)) {
        [peripheral setNotifyValue:notify forCharacteristic:transparentDataReadChar];
    }
}

- (void)checkIsAllowUpdateConnectionParameter {
    [self setUpdateConnectionParameterStep:UPDATE_PARAMETERS_STEP_PREPARE];
    [self readConnectionParameters];
}

- (NSError *)setMaxConnectionInterval:(unsigned short)maxInterval connectionTimeout:(unsigned short)connectionTimeout connectionLatency:(unsigned short)connectionLatency{
    if (backupConnectionParameter.status == 0x01) {
        ISError *error = [[ISError alloc] initWithDomain:@"Last operation does not complete yet!" code:-1 userInfo:nil];
        [error setErrorDescription:@"Last operation does not complete yet!"];
        return error;
    }
    if (self.connectionParameterChar == nil) {
        ISError *error = [[ISError alloc] initWithDomain:@"Can't get the characteristic!" code:-1 userInfo:nil];
        [error setErrorDescription:@"Can't get the characteristic!"];
        return error;
    }
    
    if (maxInterval < 20) {
        ISError *error = [[ISError alloc] initWithDomain:@"Max Connection Interval must not be less than 20 ms!" code:-1 userInfo:nil];
        [error setErrorDescription:@"Max Connection Interval must not be less than 20 ms!"];
        return error;
    }
    else if (maxInterval > 2000) {
        ISError *error = [[ISError alloc] initWithDomain:@"Max Connection Interval must be less than 2000 ms!" code:-2 userInfo:nil];
        [error setErrorDescription:@"Max Connection Interval must be less than 2000 ms!"];
        return error;
    }
    else if (connectionTimeout < 500) {
        ISError *error = [[ISError alloc] initWithDomain:@"Connection Timeout must not be less than 500 ms!" code:-3 userInfo:nil];
        [error setErrorDescription:@"Connection Timeout must not be less than 500 ms!"];
        return error;
    }
    else if (connectionTimeout > 6000) {
        ISError *error = [[ISError alloc] initWithDomain:@"Connection Timeout must be less than 6000 ms!" code:-4 userInfo:nil];
        [error setErrorDescription:@"Connection Timeout must be less than 6000 ms!"];
        return error;
    }
    else if (connectionTimeout < maxInterval*3) {
        ISError *error = [[ISError alloc] initWithDomain:@"Connection Timeout must greater than three times Max Connection Interval!" code:-4 userInfo:nil];
        [error setErrorDescription:@"Connection Timeout must greater than three times Max Connection Interval!"];
        return error;
    }
    if (backupConnectionParameter.status != 0xff) {
        backupConnectionParameter.status = 0x01;
    }
    connectionParameter.status = 0xff;
    connectionParameter.maxInterval = maxInterval/1.25 + 0.5; //unit:1.25ms
    if (connectionParameter.maxInterval*1.25 > 2000) {
        connectionParameter.maxInterval--;
    }
    connectionParameter.minInterval = (maxInterval - 20)/1.25;
    if (connectionParameter.minInterval < 8) {
        connectionParameter.minInterval = 8;
    }
    connectionParameter.connectionTimeout = connectionTimeout/10; //unit:10ms
    int latency = 0;
    for (latency = 4; latency >= 0; latency--) {
        if (maxInterval * (latency+1) > 2000) {
            continue;
        }
        else if(connectionTimeout >= (maxInterval * (latency+1) *3)) {
            connectionParameter.latency = latency;
            break;
        }
    }
    
    if(connectionParameter.latency > connectionLatency){
        connectionParameter.latency = connectionLatency;
    }
    char *p = (char *)&connectionParameter;
    NSData *data = [[NSData alloc] initWithBytes:p length:sizeof(connectionParameter)];
    
    [peripheral writeValue:data forCharacteristic:self.connectionParameterChar type:CBCharacteristicWriteWithResponse];
    
    [self setUpdateConnectionParameterStep:UPDATE_PARAMETERS_STEP_CHECK_RESULT];
    [self checkConnectionParameterStatus];
    
    //  }
    
    return nil;
}

- (void)readConnectionParameters {
    [peripheral readValueForCharacteristic:self.connectionParameterChar];
}

- (void)checkConnectionParameterStatus {
    //NSLog(@"[MyPeripheral] checkConnectionParameterStatus");
    [NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(readConnectionParameters) userInfo:nil repeats:NO];
}

- (CONNECTION_PARAMETER_FORMAT *)retrieveBackupConnectionParameter {
    return &backupConnectionParameter;
}

- (BOOL)compareBackupConnectionParameter:(CONNECTION_PARAMETER_FORMAT *)parameter {
    backupConnectionParameter.status = 0x00; //set result to success for comapre because only compare when success
    if (memcmp(&backupConnectionParameter, parameter, sizeof(CONNECTION_PARAMETER_FORMAT)))
        return FALSE;
    else
        return TRUE;
}

- (void)updateBackupConnectionParameter:(CONNECTION_PARAMETER_FORMAT *)parameter {
    backupConnectionParameter.status = parameter->status;
    backupConnectionParameter.minInterval = parameter->minInterval;
    backupConnectionParameter.maxInterval = parameter->maxInterval;
    backupConnectionParameter.latency = parameter->latency;
    backupConnectionParameter.connectionTimeout = parameter->connectionTimeout;
}

- (void)sendVendorMPEnable {
    if (self.airPatchChar == nil) {
        return;
    }
    [peripheral setNotifyValue:TRUE forCharacteristic:self.airPatchChar];
    struct _AIR_PATCH_COMMAND_FORMAT command;
    command.commandID = AIR_PATCH_COMMAND_VENDOR_MP_ENABLE;
    NSData *data = [[NSData alloc] initWithBytes:&command length:1];
    //NSLog(@"[MyPeripheral] vendorMPEnable data = %@", data);
    [peripheral writeValue:data forCharacteristic:self.airPatchChar type:CBCharacteristicWriteWithResponse];
    self.vendorMPEnable = true;
}

- (void)writeE2promValue: (short)address length:(short)length data:(char *)data {
    if (self.airPatchChar == nil) {
        return;
    }
    if (self.vendorMPEnable ==false)
        [self sendVendorMPEnable];
    struct _AIR_PATCH_COMMAND_FORMAT command;
    command.commandID = AIR_PATCH_COMMAND_E2PROM_WRITE;
    struct _WRITE_EEPROM_COMMAND_FORMAT *parameter = (struct _WRITE_EEPROM_COMMAND_FORMAT *)command.parameters;
    parameter->addr[0] = address >> 8;
    parameter->addr[1] = address & 0xff;
    int dataLen = (length > 16) ? 16 : length;
    parameter->length = dataLen;
    memcpy(parameter->data, data, dataLen);
    
    NSData *commandData = [[NSData alloc] initWithBytes:&command length:length+4];
    //NSLog(@"[MyPeripheral] writeE2promValue address = %x, data = %@", address, commandData);
    [peripheral writeValue:commandData forCharacteristic:self.airPatchChar type:CBCharacteristicWriteWithResponse];
}

- (void)readE2promValue: (short)address length:(short)length {
    if (self.airPatchChar == nil) {
        return;
    }
    if (self.vendorMPEnable ==false)
        [self sendVendorMPEnable];
    struct _AIR_PATCH_COMMAND_FORMAT command;
    command.commandID = AIR_PATCH_COMMAND_E2PROM_READ;
    struct _WRITE_EEPROM_COMMAND_FORMAT *parameter = (struct _WRITE_EEPROM_COMMAND_FORMAT *)command.parameters;
    parameter->addr[0] = address >> 8;
    parameter->addr[1] = address & 0xff;
    parameter->length = length;
    NSData *data = [[NSData alloc] initWithBytes:&command length:4];
    [peripheral writeValue:data forCharacteristic:self.airPatchChar type:CBCharacteristicWriteWithResponse];
}

- (void)writeMemoryValue: (short)address length:(short)length data:(char *)data {
    if (self.airPatchChar == nil) {
        return;
    }
    if (self.vendorMPEnable ==false)
        [self sendVendorMPEnable];
    struct _AIR_PATCH_COMMAND_FORMAT command;
    command.commandID = AIR_PATCH_COMMAND_XMEMOTY_WRITE;
    struct _WRITE_EEPROM_COMMAND_FORMAT *parameter = (struct _WRITE_EEPROM_COMMAND_FORMAT *)command.parameters;
    parameter->addr[0] = address >> 8;
    parameter->addr[1] = address & 0xff;
    int dataLen = (length > 16) ? 16 : length;
    parameter->length = dataLen;
    memcpy(parameter->data, data, dataLen);
    
    NSData *commandData = [[NSData alloc] initWithBytes:&command length:length+4];
    //NSLog(@"[MyPeripheral] writeE2promValue address = %x, data = %@", address, commandData);
    [peripheral writeValue:commandData forCharacteristic:self.airPatchChar type:CBCharacteristicWriteWithResponse];
}

- (void)readMemoryValue: (short)address length:(short)length {
    if (self.airPatchChar == nil) {
        return;
    }
    if (self.vendorMPEnable ==false)
        [self sendVendorMPEnable];
    struct _AIR_PATCH_COMMAND_FORMAT command;
    command.commandID = AIR_PATCH_COMMAND_XMEMOTY_READ;
    struct _WRITE_EEPROM_COMMAND_FORMAT *parameter = (struct _WRITE_EEPROM_COMMAND_FORMAT *)command.parameters;
    parameter->addr[0] = address >> 8;
    parameter->addr[1] = address & 0xff;
    parameter->length = length;
    NSData *data = [[NSData alloc] initWithBytes:&command length:4];
    [peripheral writeValue:data forCharacteristic:self.airPatchChar type:CBCharacteristicWriteWithResponse];
}

- (void)changePeripheralName: (NSString *)name {
    if (self.airPatchChar == nil) {
        return;
    }
    
    if (self.vendorMPEnable ==false) {
        [self sendVendorMPEnable];
        NSMethodSignature *sgn = [[self class] instanceMethodSignatureForSelector:@selector(changePeripheralName:)];
        NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:sgn];
        [invocation setTarget:self];
        [invocation setSelector:@selector(changePeripheralName:)];
        [invocation setArgument:&name atIndex:2];
        [invocation retainArguments];
        [queuedTask addObject:invocation];
        return;
    }
        
    struct _AIR_PATCH_COMMAND_FORMAT command;
    command.commandID = AIR_PATCH_COMMAND_E2PROM_WRITE;
    struct _WRITE_EEPROM_COMMAND_FORMAT *parameter = (struct _WRITE_EEPROM_COMMAND_FORMAT *)command.parameters;
    parameter->addr[0] = 0x00;
    parameter->addr[1] = 0x0b;
    parameter->length = 16;
    memset(parameter->data, 0x00, 16);
    memset(deviceName, 0x20, 16);
    int dataLen = ([name length] > 16) ? 16 : (int)[name length];
    memcpy(parameter->data, [name UTF8String], dataLen);
    memcpy(deviceName, parameter->data, dataLen);
    
    NSData *data = [[NSData alloc] initWithBytes:&command length:20];
    NSLog(@"[MyPeripheral] changePeripheralName data = %@, %x %x %x %x, %@", data, parameter->data[0], parameter->data[1], parameter->data[2], parameter->data[3], name);
    [peripheral writeValue:data forCharacteristic:self.airPatchChar type:CBCharacteristicWriteWithResponse];
    self.airPatchAction = AIR_PATCH_ACTION_CHANGE_DEVICE_NAME;
    //[data release];
    NSMethodSignature *sgn = [[self class] instanceMethodSignatureForSelector:@selector(changePeripheralNameMemory:)];
    NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:sgn];
    [invocation setTarget:self];
    [invocation setSelector:@selector(changePeripheralNameMemory:)];
    [invocation setArgument:&name atIndex:2];
    [invocation retainArguments];
    [queuedTask addObject:invocation];
}

- (void)changePeripheralNameMemory:(NSString *)name{
    if (self.airPatchChar == nil) {
        return;
    }
    
    if (self.vendorMPEnable ==false)
        [self sendVendorMPEnable];
    struct _AIR_PATCH_COMMAND_FORMAT command;
    command.commandID = AIR_PATCH_COMMAND_XMEMOTY_WRITE;
    struct _WRITE_EEPROM_COMMAND_FORMAT *parameter = (struct _WRITE_EEPROM_COMMAND_FORMAT *)command.parameters;
    parameter->addr[0] = 0x4E;
    parameter->addr[1] = 0x0b;
    parameter->length = 16;
    memset(parameter->data, 0x00, 16);
    int dataLen = ([name length] > 16) ? 16 : (int)[name length];
    memcpy(parameter->data, [name UTF8String], dataLen);
    NSData *data = [[NSData alloc] initWithBytes:&command length:20];
    NSLog(@"[MyPeripheral] changePeripheralNameMemory data = %@, %x %x %x %x, len=%d", data, parameter->data[0], parameter->data[1], parameter->data[2], parameter->data[3], dataLen);
    
    [peripheral writeValue:data forCharacteristic:self.airPatchChar type:CBCharacteristicWriteWithResponse];
    //[data release];
    self.airPatchAction = AIR_PATCH_ACTION_CHANGE_DEVICE_NAME_MEMORY;
}


- (void)checkQueuedTask {
    if ([queuedTask count]) {
        NSInvocation *invocation = [queuedTask objectAtIndex:0];
        [invocation invoke];
        [queuedTask removeObjectAtIndex:0];
    }
}

- (void)updateAirPatchEvent: (NSData *)returnEvent {
    [_transmit decodeReliableBurstTransmitEvent:returnEvent];
    char buf[20];
    //NSLog(@"[MyPeripheral] updateAirPatchEvent, %@", returnEvent);
    [returnEvent getBytes:buf length:[returnEvent length]];
    AIR_PATCH_EVENT_FORMAT *receivedEvent = (AIR_PATCH_EVENT_FORMAT *)buf;
    switch (receivedEvent->commandID) {
        case AIR_PATCH_COMMAND_VENDOR_MP_ENABLE: {
            if (receivedEvent->status == AIR_PATCH_SUCCESS) {
                [self checkQueuedTask];
            }
        }
            break;
        case AIR_PATCH_COMMAND_E2PROM_WRITE:
            if (self.airPatchAction == AIR_PATCH_ACTION_CHANGE_DEVICE_NAME) {
                if (receivedEvent->status == AIR_PATCH_SUCCESS) {
                    [self checkQueuedTask];
                }
                else {
                    if (proprietaryDelegate && [(NSObject *)proprietaryDelegate respondsToSelector:@selector(MyPeripheral:didChangePeripheralName:)]) {
                        ISError *error = [[ISError alloc] initWithDomain:@"Change peripheral name fail!" code:-2 userInfo:nil];
                        [error setErrorDescription:@"Write device name to EEPROM fail!"];
                        [proprietaryDelegate MyPeripheral:self didChangePeripheralName:error];
                    }
                }
            }
            break;
        case AIR_PATCH_COMMAND_XMEMOTY_WRITE:
            if(self.airPatchAction == AIR_PATCH_ACTION_CHANGE_DEVICE_NAME_MEMORY){
                ISError *error =nil;
                if (receivedEvent->status != AIR_PATCH_SUCCESS) {
                    error = [[ISError alloc] initWithDomain:@"Change peripheral name fail!" code:-3 userInfo:nil];
                    [error setErrorDescription:@"Write device name to Xmemory fail!"];
                }
                if (proprietaryDelegate&&[(NSObject *)proprietaryDelegate respondsToSelector:@selector(MyPeripheral:didChangePeripheralName:)]) {
                    [proprietaryDelegate MyPeripheral:self didChangePeripheralName:error];
                }
            }
            else {
                ISError *error =nil;
                if (receivedEvent->status != AIR_PATCH_SUCCESS) {
                    error = [[ISError alloc] initWithDomain:@"Write Memory Address fail!" code:-3 userInfo:nil];
                    [error setErrorDescription:@"Write to Xmemory fail!"];
                }
                if ([proprietaryDelegate respondsToSelector:@selector(MyPeripheral:didWriteMemoryAddress:)]) {
                    [proprietaryDelegate MyPeripheral:self didWriteMemoryAddress:error];
                }
            }
            break;
        case AIR_PATCH_COMMAND_XMEMOTY_READ:
            if (receivedEvent->status == AIR_PATCH_SUCCESS) {
                if ([proprietaryDelegate respondsToSelector:@selector(MyPeripheral:didReceiveMemoryAddress:length:data:)]) {
                    short length = 0;
                    [returnEvent getBytes:&length range:NSMakeRange(4, 1)];
                    [proprietaryDelegate MyPeripheral:self didReceiveMemoryAddress:[returnEvent subdataWithRange:NSMakeRange(2, 2)] length:length data:[returnEvent subdataWithRange:NSMakeRange(5, length)]];
                }
            }
            break;
        /*case AIR_PATCH_COMMAND_READ:
            if (receivedEvent->status == AIR_PATCH_SUCCESS) {
                [_transmit decodeReliableBurstTransmitEvent:returnEvent];
               }
            break;*/
        default:
            break;
    }
    
}
@end
