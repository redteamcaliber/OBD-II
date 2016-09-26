//
//  ISBLEDataPath.m
//  MFi_SPP
//
//  Created by Rick on 13/10/28.
//
//

#import "ISBLEDataPath.h"
#import "UUID.h"

#define BM77SPP_HW @"353035305f535050"
#define BM77SPP_FW @"32303233303230"
#define BM77SPP_AD 0xd97e

#define BLETR_HW @"353035305f424c455452"
#define BLETR_FW @"32303032303130"
#define BLETR_AD 0x4833

@interface NSString (HexString)
+ (NSString *)stringFromHexString:(NSString *)hexString;
@end

@implementation NSString(HexString)

+ (NSString *)stringFromHexString:(NSString *)hexString {
    
    // The hex codes should all be two characters.
    if (([hexString length] % 2) != 0)
        return nil;
    
    NSMutableString *string = [NSMutableString string];
    
    for (NSInteger i = 0; i < [hexString length]; i += 2) {
        
        NSString *hex = [hexString substringWithRange:NSMakeRange(i, 2)];
        NSInteger decimalValue = 0;
        sscanf([hex UTF8String], "%x", &decimalValue);
        [string appendFormat:@"%c", decimalValue];
    }
    
    return string;
}

@end

@interface ISBLEDataPath() <CBPeripheralDelegate> {
    NSMutableData *_writeData;
    NSMutableData *_readData;
    NSString *_hardwareRevision;
    NSString *_firmwareRevision;
    NSString *_manufacturer;
    NSString *_modelNumber;
    NSString *_serialNumber;
    BOOL isPatch;

}
@end

@implementation ISBLEDataPath
- (void)internalInit {
    _connecting = NO;
    _vendorMPEnable = NO;
    isPatch = NO;
    _transmit = [[ReliableBurstData alloc] init];
}

- (void)setPeripheral:(CBPeripheral *)peripheral withAdvName:(NSString *)advName {
    if (_peripheral != peripheral) {
        _peripheral = peripheral;
        _peripheral.delegate = self;
    }
    _advName = advName;
}

- (BOOL)openSession {
    _connecting = NO;
    _peripheral.delegate = self;
    NSMutableArray *uuids = [[NSMutableArray alloc] initWithObjects:[CBUUID UUIDWithString:UUIDSTR_DEVICE_INFO_SERVICE], [CBUUID UUIDWithString:UUIDSTR_ISSC_PROPRIETARY_SERVICE], [CBUUID UUIDWithString:UUIDSTR_ISSC_AIR_PATCH_SERVICE], nil];
    [_peripheral discoverServices:uuids];
    [self sendLog:@"Discover Services"];
     return YES;
}

- (void)closeSession
{
    if (_writeData) {
        _writeData = nil;
    }
    _peripheral.delegate = nil;
    /*if (self.delegate && [self.delegate respondsToSelector:@selector(accessoryDidDisconnect:)])
        [self.delegate accessoryDidDisconnect:self];*/
}

- (NSString *)description {
    return [NSString stringWithFormat:@"%@ %@",[super description],[_peripheral description]];
}

- (NSString *)name {
    return _peripheral.name;
}

- (NSString *)firmwareRevision {
    return _firmwareRevision;
}

- (NSString *)hardwareRevision {
    return _hardwareRevision;
}

- (NSString *)manufacturer {
    return _manufacturer;
}

- (NSString *)modelNumber {
    return _modelNumber;
}

- (NSString *)serialNumber {
    return _serialNumber;
}

- (NSUUID *)UUID {
    if ([_peripheral respondsToSelector:@selector(identifier)]) {
        return _peripheral.identifier;
    }
    if (!_peripheral.UUID) {
        return nil;
    }
    NSString *uuidStr = (__bridge NSString *)CFUUIDCreateString(NULL, _peripheral.UUID);
    return [[NSUUID alloc] initWithUUIDString:uuidStr];
}

- (CBPeripheralState)state {
    if (floor(NSFoundationVersionNumber) > NSFoundationVersionNumber_iOS_6_1) {
        return _peripheral.state;
    }
    else {
        if ([_peripheral isConnected]) {
            return CBPeripheralStateConnected;
        }
        else if (_connecting){
            return CBPeripheralStateConnecting;
        }
        else {
            return CBPeripheralStateDisconnected;
        }
    }
}

- (void)writeData:(NSData *)data {
    if (!self.transparentDataWriteChar) {
        if (self.delegate && [self.delegate respondsToSelector:@selector(accessoryDidFailToWriteData:error:)]) {
            [self.delegate accessoryDidFailToWriteData:self error:[NSError errorWithDomain:@"transparentDataWriteChar not find" code:-1 userInfo:nil]];
        }
        return;
    }
    if (!_writeData) {
        _writeData = [[NSMutableData alloc] init];
    }
    if (!_canSendData) {
        return;
    }
    if (data) {
        [_writeData appendData:data];
    }
    NSUserDefaults *def =[NSUserDefaults standardUserDefaults];
    CBCharacteristicWriteType actualType = [def boolForKey:@"writeWithResponse"]?CBCharacteristicWriteWithResponse:CBCharacteristicWriteWithoutResponse;

    if (actualType == CBCharacteristicWriteWithoutResponse && ![_transmit canSendReliableBurstTransmit]) {
        [self performSelector:@selector(writeData:) withObject:nil afterDelay:0.1];
        return;
    }
     int length;
    if ([_writeData length]>=[_transmit transmitSize]) {
        length = (int)[_transmit transmitSize];
    }
    else {
        length = (int)[_writeData length];
    }
    if (length > 0) {
        if (actualType == CBCharacteristicWriteWithoutResponse) {
            [_transmit reliableBurstTransmit:[_writeData subdataWithRange:NSMakeRange(0, length)] withTransparentCharacteristic:self.transparentDataWriteChar];
        }
        else {
            [_peripheral writeValue:[_writeData subdataWithRange:NSMakeRange(0, length)] forCharacteristic:self.transparentDataWriteChar type:actualType];
        }
    }
    if (![def boolForKey:@"writeWithResponse"]) {
        static int b = 0;
        [_writeData replaceBytesInRange:NSMakeRange(0, length) withBytes:NULL length:0];
        b+=length;
        int cont;
        BOOL complete = NO;
        if ([_writeData length]>=[_transmit transmitSize]) {
            cont = (int)[_transmit transmitSize];
        }
        else {
            cont = (int)[_writeData length];
        }
        if (cont != 0) {
            //[NSTimer scheduledTimerWithTimeInterval:0.0001 target:self selector:@selector(writeData:) userInfo:nil repeats:NO];
            [self performSelector:@selector(writeData:) withObject:nil afterDelay:0.0001];
        }
        else {
            complete = YES;
        }
        if (self.delegate && [self.delegate respondsToSelector:@selector(accessoryDidWriteData:bytes:complete:)]) {
            [self.delegate accessoryDidWriteData:self bytes:b complete:complete];
        }
        if (complete) {
            b = 0;
        }
    }
}

- (void)cancelWriteData {
    [_writeData replaceBytesInRange:NSMakeRange(0, [_writeData length]) withBytes:NULL length:0];
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    if (_transparentDataReadChar) {
        [_peripheral setNotifyValue:NO forCharacteristic:_transparentDataReadChar];
    }
}

// high level read method
- (NSData *)readData:(NSUInteger)bytesToRead
{
    NSData *data = nil;
    if ([_readData length] >= bytesToRead) {
        NSRange range = NSMakeRange(0, bytesToRead);
        data = [_readData subdataWithRange:range];
        [_readData replaceBytesInRange:range withBytes:NULL length:0];
    }
    return data;
}

// get number of bytes read into local buffer
- (NSUInteger)readBytesAvailable
{
    return [_readData length];
}

- (void)readConnectionParameters {
    [_peripheral readValueForCharacteristic:self.connectionParameterChar];
}

- (void)checkConnectionParameterStatus {
    //NSLog(@"[MyPeripheral] checkConnectionParameterStatus");
    [NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(readConnectionParameters) userInfo:nil repeats:NO];
}

- (CONNECTION_PARAMETER_FORMAT *)retrieveBackupConnectionParameter {
    return &_backupConnectionParameter;
}

- (BOOL)compareBackupConnectionParameter:(CONNECTION_PARAMETER_FORMAT *)parameter {
    _backupConnectionParameter.status = 0x00; //set result to success for comapre because only compare when success
    if (memcmp(&_backupConnectionParameter, parameter, sizeof(CONNECTION_PARAMETER_FORMAT)))
        return FALSE;
    else
        return TRUE;
}

- (void)updateBackupConnectionParameter:(CONNECTION_PARAMETER_FORMAT *)parameter {
    _backupConnectionParameter.status = parameter->status;
    _backupConnectionParameter.minInterval = parameter->minInterval;
    _backupConnectionParameter.maxInterval = parameter->maxInterval;
    _backupConnectionParameter.latency = parameter->latency;
    _backupConnectionParameter.connectionTimeout = parameter->connectionTimeout;
}

//DIS
- (void)readManufactureName {
    // NSLog(@"[MyPeripheral] readManufactureName");
    if (_manufactureNameChar == nil) {
    }
    [_peripheral readValueForCharacteristic:_manufactureNameChar];
}

- (void)readModelNumber {
    // NSLog(@"[MyPeripheral] readModelNumber");
    [_peripheral readValueForCharacteristic:_modelNumberChar];
    
}

- (void)readSerialNumber {
    // NSLog(@"[MyPeripheral] readSerialNumber");
    [_peripheral readValueForCharacteristic:_serialNumberChar];
}

- (void)readHardwareRevision {
    //NSLog(@"[MyPeripheral] readHardwareRevision");
    [_peripheral readValueForCharacteristic:_hardwareRevisionChar];
}

- (void)readFirmwareRevision {
    //NSLog(@"[MyPeripheral] readFirmwareRevision");
    [_peripheral readValueForCharacteristic:_firmwareRevisionChar];
}

- (void)readSoftwareRevison {
    //NSLog(@"[MyPeripheral] readSoftwareRevison");
    [_peripheral readValueForCharacteristic:_softwareRevisionChar];
}

- (void)readSystemID {
    //NSLog(@"[MyPeripheral] readSystemID");
    [_peripheral readValueForCharacteristic:_systemIDChar];
}

- (void)readCertificationData {
    //NSLog(@"[MyPeripheral] readCertificationData");
    [_peripheral readValueForCharacteristic:_certDataListChar];
}

- (void)setTransDataNotification:(BOOL)notify {
    NSLog(@"[MyPeripheral] setTransDataNotification UUID = %@",_transparentDataReadChar.UUID);
    [_peripheral setNotifyValue:notify forCharacteristic:_transparentDataReadChar];
    isPatch = YES;
}

- (void)sendVendorMPEnable {
    if (self.airPatchChar == nil) {
        return;
    }
    [_peripheral setNotifyValue:TRUE forCharacteristic:self.airPatchChar];
    struct _AIR_PATCH_COMMAND_FORMAT command;
    command.commandID = AIR_PATCH_COMMAND_VENDOR_MP_ENABLE;
    NSData *data = [[NSData alloc] initWithBytes:&command length:1];
    //NSLog(@"[MyPeripheral] vendorMPEnable data = %@", data);
    [_peripheral writeValue:data forCharacteristic:self.airPatchChar type:CBCharacteristicWriteWithResponse];
    _vendorMPEnable = true;
}

- (void)writeMemoryValue: (short)address length:(short)length data:(char *)data {
    if (self.airPatchChar == nil) {
        return;
    }
    if (_vendorMPEnable ==false)
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
    [_peripheral writeValue:commandData forCharacteristic:self.airPatchChar type:CBCharacteristicWriteWithResponse];
}

- (void)readMemoryValue: (short)address length:(short)length {
    if (self.airPatchChar == nil) {
        return;
    }
    if (_vendorMPEnable ==false)
        [self sendVendorMPEnable];
    struct _AIR_PATCH_COMMAND_FORMAT command;
    command.commandID = AIR_PATCH_COMMAND_XMEMOTY_READ;
    struct _WRITE_EEPROM_COMMAND_FORMAT *parameter = (struct _WRITE_EEPROM_COMMAND_FORMAT *)command.parameters;
    parameter->addr[0] = address >> 8;
    parameter->addr[1] = address & 0xff;
    parameter->length = length;
    NSData *data = [[NSData alloc] initWithBytes:&command length:4];
    [_peripheral writeValue:data forCharacteristic:self.airPatchChar type:CBCharacteristicWriteWithResponse];
}

- (void)updateAirPatchEvent: (NSData *)returnEvent {
    char buf[20];
    //NSLog(@"[MyPeripheral] updateAirPatchEvent, %@", returnEvent);
    [returnEvent getBytes:buf length:[returnEvent length]];
    AIR_PATCH_EVENT_FORMAT *receivedEvent = (AIR_PATCH_EVENT_FORMAT *)buf;
    switch (receivedEvent->commandID) {
        case AIR_PATCH_COMMAND_VENDOR_MP_ENABLE: {
            if (receivedEvent->status == AIR_PATCH_SUCCESS) {
                //[self checkQueuedTask];
            }
        }
        case AIR_PATCH_COMMAND_E2PROM_WRITE:
            if (self.airPatchAction == AIR_PATCH_ACTION_CHANGE_DEVICE_NAME) {
                if (receivedEvent->status == AIR_PATCH_SUCCESS) {
                    //[self checkQueuedTask];
                }
                else {
                    /*if (proprietaryDelegate && [(NSObject *)proprietaryDelegate respondsToSelector:@selector(MyPeripheral:didChangePeripheralName:)]) {
                        ISError *error = [[ISError alloc] initWithDomain:@"Change peripheral name fail!" code:-2 userInfo:nil];
                        [error setErrorDescription:@"Write device name to EEPROM fail!"];
                        [proprietaryDelegate MyPeripheral:self didChangePeripheralName:error];
                    }*/
                }
            }
            break;
        case AIR_PATCH_COMMAND_XMEMOTY_WRITE:
            if(self.airPatchAction == AIR_PATCH_ACTION_CHANGE_DEVICE_NAME_MEMORY){
                /*ISError *error =nil;
                if (receivedEvent->status != AIR_PATCH_SUCCESS) {
                    error = [[ISError alloc] initWithDomain:@"Change peripheral name fail!" code:-3 userInfo:nil];
                    [error setErrorDescription:@"Write device name to Xmemory fail!"];
                }
                if (proprietaryDelegate&&[(NSObject *)proprietaryDelegate respondsToSelector:@selector(MyPeripheral:didChangePeripheralName:)]) {
                    [proprietaryDelegate MyPeripheral:self didChangePeripheralName:error];
                }*/
            }
            else {
                if (receivedEvent->status == AIR_PATCH_SUCCESS) {
                    [self setTransDataNotification:TRUE];
                }
                /*ISError *error =nil;
                if (receivedEvent->status != AIR_PATCH_SUCCESS) {
                    error = [[ISError alloc] initWithDomain:@"Write Memory Address fail!" code:-3 userInfo:nil];
                    [error setErrorDescription:@"Write to Xmemory fail!"];
                }
                if ([proprietaryDelegate respondsToSelector:@selector(MyPeripheral:didWriteMemoryAddress:)]) {
                    [proprietaryDelegate MyPeripheral:self didWriteMemoryAddress:error];
                }*/
            }
            break;
        case AIR_PATCH_COMMAND_XMEMOTY_READ:
            if (receivedEvent->status == AIR_PATCH_SUCCESS) {
                /*if ([proprietaryDelegate respondsToSelector:@selector(MyPeripheral:didReceiveMemoryAddress:length:data:)]) {
                    short length = 0;
                    [returnEvent getBytes:&length range:NSMakeRange(4, 1)];
                    [proprietaryDelegate MyPeripheral:self didReceiveMemoryAddress:[returnEvent subdataWithRange:NSMakeRange(2, 2)] length:length data:[returnEvent subdataWithRange:NSMakeRange(5, length)]];
                }*/
                short length = 0;
                [returnEvent getBytes:&length range:NSMakeRange(4, 1)];
                unsigned short int add;
                [returnEvent getBytes:&add range:NSMakeRange(2, 2)];
                add = NSSwapBigShortToHost(add);
                unsigned short int d;
                [returnEvent getBytes:&d range:NSMakeRange(5, length)];
                d = NSSwapBigShortToHost(d);
                NSLog(@"%x = %x",add,d);
                if ([_hardwareRevision hasPrefix:[NSString stringFromHexString:BM77SPP_HW]] && [_firmwareRevision hasPrefix:[NSString stringFromHexString:BM77SPP_FW]] && add == BM77SPP_AD) {
                    if (d != 0x0017) {
                        char w[2];
                        w[0] = 0x00;
                        w[1] = 0x17;
                        [self writeMemoryValue:BM77SPP_AD length:2 data:w];
                    }
                    else {
                        [self setTransDataNotification:TRUE];
                    }
                }
                else if ([_hardwareRevision hasPrefix:[NSString stringFromHexString:BLETR_HW]] && [_firmwareRevision hasPrefix:[NSString stringFromHexString:BLETR_FW]] && add == BLETR_AD) {
                    if (d != 0x17) {
                        char w[2];
                        w[0] = 0x00;
                        w[1] = 0x17;
                        [self writeMemoryValue:BLETR_AD length:2 data:w];
                    }
                    else {
                        [self setTransDataNotification:TRUE];
                    }
                }
            }
            break;
        case AIR_PATCH_COMMAND_READ: {
            if (receivedEvent->status == AIR_PATCH_SUCCESS) {
                [_transmit decodeReliableBurstTransmitEvent:returnEvent];
            }
        }
            break;
        default:
            break;
    }
    
}

#define Log_Notification @"Log_Notification"
- (void)sendLog:(NSString *)string {
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:Log_Notification object:nil userInfo:@{@"Value":string}];
    });
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
    BOOL isISSCPeripheral = NO;
    if ([service.UUID isEqual:[CBUUID UUIDWithString:UUIDSTR_ISSC_PROPRIETARY_SERVICE]] || [service.UUID isEqual:[CBUUID UUIDWithString:UUIDSTR_ISSC_AIR_PATCH_SERVICE]]) {
        isISSCPeripheral = TRUE;
        for (aChar in service.characteristics)
        {
            if ([aChar.UUID isEqual:[CBUUID UUIDWithString:UUIDSTR_ISSC_TRANS_RX]]) {
                _transparentDataWriteChar = aChar;
                NSLog(@"found TRANS_RX");
                double delayInSeconds = 2;
                dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
                dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                    [self.delegate accessoryDidConnected:self];
                });
            }
            else if ([aChar.UUID isEqual:[CBUUID UUIDWithString:UUIDSTR_ISSC_TRANS_TX]]) {
                NSLog(@"found TRANS_TX");
                _transparentDataReadChar=aChar;
                //[aPeripheral setNotifyValue:TRUE forCharacteristic:aChar];
            }
            else if ([aChar.UUID isEqual:[CBUUID UUIDWithString:UUIDSTR_CONNECTION_PARAMETER_CHAR]]) {
                _connectionParameterChar=aChar;
                NSLog(@"found CONNECTION_PARAMETER_CHAR");
            }
            else if ([aChar.UUID isEqual:[CBUUID UUIDWithString:UUIDSTR_AIR_PATCH_CHAR]]) {
                _airPatchChar=aChar;
                NSLog(@"found UUIDSTR_AIR_PATCH_CHAR");
                [_transmit enableReliableBurstTransmit:_peripheral andAirPatchCharacteristic:self.airPatchChar];
            }
        }
    }
    else if([service.UUID isEqual:[CBUUID UUIDWithString:UUIDSTR_DEVICE_INFO_SERVICE]]) {
        
        for (aChar in service.characteristics)
        {
            if ([aChar.UUID isEqual:[CBUUID UUIDWithString:UUIDSTR_MANUFACTURE_NAME_CHAR]]) {
                _manufactureNameChar=aChar;
                NSLog(@"found manufacture name char");
                [self readManufactureName];

            }
            else if ([aChar.UUID isEqual:[CBUUID UUIDWithString:UUIDSTR_MODEL_NUMBER_CHAR]]) {
                _modelNumberChar=aChar;
                NSLog(@"found model number char");
                [self readModelNumber];
                
            }
            else if ([aChar.UUID isEqual:[CBUUID UUIDWithString:UUIDSTR_SERIAL_NUMBER_CHAR]]) {
                _serialNumberChar=aChar;
                NSLog(@"found serial number char");
                [self readSerialNumber];

            }
            else if ([aChar.UUID isEqual:[CBUUID UUIDWithString:UUIDSTR_HARDWARE_REVISION_CHAR]]) {
                _hardwareRevisionChar=aChar;
                NSLog(@"found hardware revision char");
                [self readHardwareRevision];
            }
            else if ([aChar.UUID isEqual:[CBUUID UUIDWithString:UUIDSTR_FIRMWARE_REVISION_CHAR]]) {
                _firmwareRevisionChar=aChar;
                NSLog(@"found firmware revision char");
                [self readFirmwareRevision];
            }
            else if ([aChar.UUID isEqual:[CBUUID UUIDWithString:UUIDSTR_SOFTWARE_REVISION_CHAR]]) {
                _softwareRevisionChar=aChar;
                NSLog(@"found software revision char");
                [self readSoftwareRevison];
            }
            else if ([aChar.UUID isEqual:[CBUUID UUIDWithString:UUIDSTR_SYSTEM_ID_CHAR]]) {
                _systemIDChar=aChar;
                NSLog(@"[CBController] found system ID char");
                [self readSystemID];
            }
            else if ([aChar.UUID isEqual:[CBUUID UUIDWithString:UUIDSTR_IEEE_11073_20601_CHAR]]) {
                _certDataListChar=aChar;
                NSLog(@"found certification data list char");
                [self readCertificationData];
            }
        }
    }
    
    if (isISSCPeripheral == TRUE) {

    }
    if ([service.UUID isEqual:[CBUUID UUIDWithString:@"1802"]]) {
        for (aChar in service.characteristics)
        {
            [_peripheral setNotifyValue:YES forCharacteristic:aChar];
        }

    }
    if ([service.UUID isEqual:[CBUUID UUIDWithString:@"1803"]]) {
        for (aChar in service.characteristics)
        {
            //[NSTimer scheduledTimerWithTimeInterval:2.0 target:_peripheral selector:@selector(readValueForCharacteristic:) userInfo:aChar repeats:YES];
            [_peripheral  readValueForCharacteristic:aChar];
            /*char d = 0x01;
            NSData *data = [NSData dataWithBytes:&d length:1];
            [_peripheral writeValue:data forCharacteristic:aChar type:CBCharacteristicWriteWithResponse];*/
        }
        
    }

}

/*
 Invoked upon completion of a -[readValueForCharacteristic:] request or on the reception of a notification/indication.
 */
- (void) peripheral:(CBPeripheral *)aPeripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
     NSLog(@"[CBController] didUpdateValueForCharacteristic UUID = %@  %@",characteristic.UUID,[characteristic  value]);
    /*if ([characteristic.service.UUID isEqual:[CBUUID UUIDWithString:@"1803"]]) {
        [_peripheral  performSelector:@selector(readValueForCharacteristic:) withObject:characteristic afterDelay:2.0];
    }*/
    if ([characteristic.service.UUID isEqual:[CBUUID UUIDWithString:UUIDSTR_DEVICE_INFO_SERVICE]]) {
        if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:UUIDSTR_MANUFACTURE_NAME_CHAR]]) {
            NSLog(@"[CBController] update manufacture name");
            _manufacturer = [[NSString alloc] initWithData:characteristic.value encoding:NSUTF8StringEncoding];
        }
        else if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:UUIDSTR_MODEL_NUMBER_CHAR]]) {
            NSLog(@"[CBController] update model number");
            _modelNumber = [[NSString alloc] initWithData:characteristic.value encoding:NSUTF8StringEncoding];
        }
        else if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:UUIDSTR_SERIAL_NUMBER_CHAR]]) {
            NSLog(@"[CBController] update serial number");
            _serialNumber = [[NSString alloc] initWithData:characteristic.value encoding:NSUTF8StringEncoding];
        }
        else if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:UUIDSTR_HARDWARE_REVISION_CHAR]]) {
            NSLog(@"[CBController] update hardware revision");
            _hardwareRevision = [[NSString alloc] initWithData:characteristic.value encoding:NSUTF8StringEncoding];
        }
        else if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:UUIDSTR_FIRMWARE_REVISION_CHAR]]) {
            NSLog(@"[CBController] update firmware revision");
            _firmwareRevision = [[NSString alloc] initWithData:characteristic.value encoding:NSUTF8StringEncoding];
        }
        else if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:UUIDSTR_SOFTWARE_REVISION_CHAR]]) {
            NSLog(@"[CBController] update software revision, V%@",[[NSString alloc] initWithData:characteristic.value encoding:NSUTF8StringEncoding]);
         }
        else if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:UUIDSTR_SYSTEM_ID_CHAR]]) {
            NSLog(@"[CBController] update system ID , ID = %@",[[NSString alloc] initWithData:characteristic.value encoding:NSUTF8StringEncoding]);
        }
        else if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:UUIDSTR_IEEE_11073_20601_CHAR]]) {
            NSLog(@"[CBController] update IEEE_11073_20601: %@",characteristic.value);
        }
        if (_hardwareRevision && _firmwareRevision && !isPatch) {
            if ([_hardwareRevision hasPrefix:[NSString stringFromHexString:BM77SPP_HW]] && [_firmwareRevision hasPrefix:[NSString stringFromHexString:BM77SPP_FW]]) {
                //BM77SPP
                [self readMemoryValue:BM77SPP_AD length:2];
            }
            else if ([_hardwareRevision hasPrefix:[NSString stringFromHexString:BLETR_HW]] && [_firmwareRevision hasPrefix:[NSString stringFromHexString:BLETR_FW]]) {
                //BLETR
                [self readMemoryValue:BLETR_AD length:2];
            }
            else {
                [self setTransDataNotification:TRUE];
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
            if ([self retrieveBackupConnectionParameter]->status == 0xff) {
                [self updateBackupConnectionParameter:parameter];
            }
            else {
                switch (_updateConnectionParameterStep) {
                    case UPDATE_PARAMETERS_STEP_PREPARE:
                       break;
                    case UPDATE_PARAMETERS_STEP_CHECK_RESULT:
                        if (buf[0] != 0x00) {
                            NSLog(@"[CBController] check connection parameter status again");
                            [self checkConnectionParameterStatus];
                        }
                        else {
                            if ([self compareBackupConnectionParameter:parameter] == TRUE) {
                                NSLog(@"[CBController] connection parameter no change");
                            }
                            else {
                                NSLog(@"connection parameter update success");
                                [self updateBackupConnectionParameter:parameter];
                            }
                        }
                    default:
                        break;
                }
            }
        }
        else if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:UUIDSTR_AIR_PATCH_CHAR]]) {
            [self updateAirPatchEvent:characteristic.value];
        }
        else if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:UUIDSTR_ISSC_TRANS_TX]]) {
            if (_readData == nil) {
                _readData = [[NSMutableData alloc] init];
            }
            [_readData appendData:characteristic.value];
            //[_readData appendBytes:(void *)characteristic.value length:[characteristic.value length]];
            if (self.delegate && [self.delegate respondsToSelector:@selector(dataReceived:)])
                [self.delegate dataReceived:self];
        }
    }
}

- (void) peripheral:(CBPeripheral *)aPeripheral didWriteValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    NSLog(@"[CBController] didWriteValueForCharacteristic error msg:%ld, %@, %@", (long)error.code ,[error localizedFailureReason], [error localizedDescription]);
    NSLog(@"characteristic data = %@ id = %@",characteristic.value,characteristic.UUID);
    if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:UUIDSTR_ISSC_TRANS_RX]]) {
        static int b = 0;
        if (!error) {
            int length;
            NSUserDefaults *def =[NSUserDefaults standardUserDefaults];
             if ([_writeData length]>=[_transmit transmitSize]) {
                length = (int)[_transmit transmitSize];
            }
            else {
                length = (int)[_writeData length];
            }
            [_writeData replaceBytesInRange:NSMakeRange(0, length) withBytes:NULL length:0];
            b+=length;
            int cont;
            BOOL complete = NO;
            if ([_writeData length]>=[_transmit transmitSize]) {
                cont = (int)[_transmit transmitSize];
            }
            else {
                cont = (int)[_writeData length];
            }
           if (cont != 0) {
               if ([def boolForKey:@"writeWithResponse"]) {
                   [_peripheral writeValue:[_writeData subdataWithRange:NSMakeRange(0, cont)] forCharacteristic:self.transparentDataWriteChar type:CBCharacteristicWriteWithResponse];
               }
               else {
                   [_transmit reliableBurstTransmit:[_writeData subdataWithRange:NSMakeRange(0, cont)] withTransparentCharacteristic:self.transparentDataWriteChar];
               }
            }
            else {
                complete = YES;
            }
            if (self.delegate && [self.delegate respondsToSelector:@selector(accessoryDidWriteData:bytes:complete:)]) {
                [self.delegate accessoryDidWriteData:self bytes:b complete:complete];
            }
            if (complete) {
                b = 0;
            }
        }
        else {
            b = 0;

            if (self.delegate && [self.delegate respondsToSelector:@selector(accessoryDidFailToWriteData:error:)]) {
                [self.delegate accessoryDidFailToWriteData:self error:error];
            }

        }
    }
}

- (void) peripheral:(CBPeripheral *)aPeripheral didDiscoverDescriptorsForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    NSLog(@"[CBController] didDiscoverDescriptorsForCharacteristic error msg:%ld, %@, %@", (long)error.code ,[error localizedFailureReason], [error localizedDescription]);
}

- (void) peripheral:(CBPeripheral *)peripheral didUpdateValueForDescriptor:(CBDescriptor *)descriptor error:(NSError *)error
{
    NSLog(@"[CBController] didUpdateValueForDescriptor");
}

-(void) peripheral:(CBPeripheral *)peripheral didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    NSLog(@"[CBController] didUpdateNotificationStateForCharacteristic, UUID = %@ ,isNotifying = %hhd", characteristic.UUID,characteristic.isNotifying);
    self.isNotifying = characteristic.isNotifying;
}
@end
