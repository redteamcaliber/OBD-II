//
//  ISMFiDataPath.m
//  MFi_SPP
//
//  Created by Rick on 13/10/28.
//
//

#import "ISMFiDataPath.h"

@interface ISMFiDataPath() <NSStreamDelegate,EAAccessoryDelegate> {
    EAAccessory *_accessory;
    EASession *_session;
    NSMutableData *_writeData;
    NSMutableData *_readData;
}
@end

@implementation ISMFiDataPath

- (void)setProtocolString:(NSString *)protocolString withAccessory:(EAAccessory *)accessory{
    if (_protocolString)
        _protocolString = nil;
    if (_session) {
        [self closeSession];
    }
    if (_accessory) {
        _accessory = nil;
    }
    if (protocolString) {
        _protocolString = protocolString;
        _accessory = accessory;
        if (!_accessory) {
            if (self.delegate && [self.delegate respondsToSelector:@selector(accessoryError)])
                [self.delegate accessoryError];
        }
        else {
            _accessory.delegate = self;
            if (self.delegate && [self.delegate respondsToSelector:@selector(accessoryDidConnect:)]) {
                double delayInSeconds = 0.5;
                dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
                dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                    [self.delegate accessoryDidConnected:self];
                });
            }
        }
        
    }
}

- (EAAccessory *)obtainAccessoryForProtocol:(NSString *)protocolString
{
    NSLog(@"[obtainAccessoryForProtocol]");
    if (protocolString == nil)
        return nil;
    NSArray *accessories_array = [[EAAccessoryManager sharedAccessoryManager]
                                  connectedAccessories];
    EAAccessory *accessory = nil;
    
    for (EAAccessory *obj in accessories_array) {
        NSLog(@"[obtainAccessoryForProtocol]111 protocolStr: %@", [obj protocolStrings]);
        if ([[obj protocolStrings] containsObject:protocolString]) {
            accessory = obj;
            [accessory setDelegate:self];
            NSLog(@"[obtainAccessoryForProtocol] protocolStr: %@", [obj protocolStrings]);
            break;
        }
        
    }
    return accessory;
}

- (BOOL)openSession
{
    
    _session = [[EASession alloc] initWithAccessory:_accessory forProtocol:_protocolString];
    
    if (_session)
    {
        [[_session inputStream] setDelegate:self];
        [[_session inputStream] scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
        [[_session inputStream] open];
        
        [[_session outputStream] setDelegate:self];
        [[_session outputStream] scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
        [[_session outputStream] open];
    }
    else
    {
        NSLog(@"creating session failed");
    }
    
    return (_session != nil);
}

- (void)closeSession
{
    //  NSLog(@"[MFiDataPath] closeSession1");
    [[_session inputStream] close];
    [[_session inputStream] removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    // [[_session inputStream] setDelegate:nil];
    [[_session outputStream] close];
    [[_session outputStream] removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    //  [[_session outputStream] setDelegate:nil];
        if (_writeData) {
            NSLog(@"[MFiDataPath] _writeData release");
            _writeData = nil;
        }
    // NSLog(@"[MFiDataPath] closeSession2");
    if (_readData) {
        NSLog(@"[MFiDataPath] _readData release");
        _readData = nil;
    }
    //  NSLog(@"[MFiDataPath] closeSession3");
    NSLog(@"[MFiDataPath] closeSession");
    //there is a iOS dealloc bug in iOS 6.0/6.0.1 base on discussion in the network. (deallocated while still in use)
    _session = nil;
    
    
}

- (NSString *)name {
    return _accessory.name;
}

- (NSString *)firmwareRevision {
    return _accessory.firmwareRevision;
}

- (NSString *)hardwareRevision {
    return _accessory.hardwareRevision;
}

- (NSString *)manufacturer {
    return _accessory.manufacturer;
}

- (NSString *)modelNumber {
    return _accessory.modelNumber;
}

- (NSString *)serialNumber {
    return _accessory.serialNumber;
}

- (void)cancelWriteData {
    [_writeData replaceBytesInRange:NSMakeRange(0, [_writeData length]) withBytes:NULL length:0];
}

#pragma mark - EAAccessory Notifications
- (void)accessoryDidDisconnect:(EAAccessory *)theAccessory {
    NSLog(@"[MFiDataPath] accessoryDidDisconnect");
    if (_accessory == theAccessory) {
        if (_session) {
            [self closeSession];
        }
        [_accessory setDelegate:nil];
        _accessory = nil;
        if (self.delegate && [self.delegate respondsToSelector:@selector(accessoryDidDisconnect:)])
            [self.delegate accessoryDidDisconnect:self];
    }
}

- (void)accessoryDidConnect:(NSNotification *)notification {
    NSLog(@"[MFiDataPath] accessoryDidConnect");
    _accessory = [self obtainAccessoryForProtocol:_protocolString];
    if (_accessory) {
        if (self.delegate && [self.delegate respondsToSelector:@selector(accessoryDidConnect:)])
            [self.delegate accessoryDidConnected:self];
    }
}


#pragma mark Internal

// low level write method - write data to the accessory while there is space available and data to write
- (void)_writeData {
    //while (([[_session outputStream] hasSpaceAvailable]) && ([_writeData length] > 0))
        if (([[_session outputStream] hasSpaceAvailable]) && ([_writeData length] > 0))
        {
            
            NSInteger bytesWritten = [[_session outputStream] write:[_writeData bytes] maxLength:[_writeData length]];
            NSLog(@"_writeData length = %lu", (unsigned long)[_writeData length]);
            if (bytesWritten == -1)
            {
                NSLog(@"write error");
                //break;
            }
            else if (bytesWritten > 0)
            {
                [_writeData replaceBytesInRange:NSMakeRange(0, bytesWritten) withBytes:NULL length:0];
                if ([_writeData length] == 0) {
                    NSLog(@"write complete");
                    if (self.delegate && [self.delegate respondsToSelector:@selector(accessoryDidWriteData:bytes:complete:)]) {
                        [self.delegate accessoryDidWriteData:self bytes:(int)bytesWritten complete:YES];
                    }
                }
                else {
                    if (self.delegate && [self.delegate respondsToSelector:@selector(accessoryDidWriteData:bytes:complete:)]) {
                        [self.delegate accessoryDidWriteData:self bytes:(int)bytesWritten complete:NO];
                    }
                }
            }
        }
}

// low level read method - read data while there is data and space available in the input buffer
- (void)_readData {
#define EAD_INPUT_BUFFER_SIZE 1024
    uint8_t buf[EAD_INPUT_BUFFER_SIZE];
    if ([[_session inputStream] hasBytesAvailable])
    {
        NSInteger bytesRead = [[_session inputStream] read:buf maxLength:EAD_INPUT_BUFFER_SIZE];
        if (_readData == nil) {
            _readData = [[NSMutableData alloc] init];
        }
        [_readData appendBytes:(void *)buf length:bytesRead];
        NSLog(@"read %ld bytes from input stream, %@", (long)bytesRead, _readData);
    }
    NSLog(@"delegate = %@",self.delegate);
    if (self.delegate && [self.delegate respondsToSelector:@selector(dataReceived:)])
        [self.delegate dataReceived:self];
}

// high level write data method
- (void)writeData:(NSData *)data
{
    NSLog(@"[MFiDataPath] writeData: %@", data);
        if (_writeData == nil) {
            // NSLog(@"[MFiDataPath] writeData1: %@", data);
            _writeData = [[NSMutableData alloc] init];
        }
        
        [_writeData appendData:data];
        //NSLog(@"[MFiDataPath] _writeData: %@", _writeData);
    [self _writeData];
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

#pragma mark NSStreamDelegateEventExtensions

// asynchronous NSStream handleEvent method
- (void)stream:(NSStream *)aStream handleEvent:(NSStreamEvent)eventCode
{
    switch (eventCode) {
        case NSStreamEventNone:
            break;
        case NSStreamEventOpenCompleted:
            break;
        case NSStreamEventHasBytesAvailable:
            [self _readData];
            break;
        case NSStreamEventHasSpaceAvailable:
            // NSLog(@"NSStreamEventHasSpaceAvailable");
            [self _writeData];
            break;
        case NSStreamEventErrorOccurred:
            NSLog(@"%@",[[aStream streamError] description]);
            break;
        case NSStreamEventEndEncountered:
            break;
        default:
            break;
    }
}

- (void)dealloc {
    [self setProtocolString:nil withAccessory:nil];
}

@end
