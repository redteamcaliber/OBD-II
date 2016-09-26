//
//  ISDataPath.m
//  MFi_SPP
//
//  Created by Rick on 13/10/28.
//
//

#import "ISDataPath.h"

@implementation ISDataPath
- (id)init {
    self = [super init];
    if (self) {
        [self internalInit];
    }
    return self;
}

- (void)internalInit {
    
}

- (BOOL)openSession {
    return YES;
}

- (void)closeSession {
    
}

- (NSUInteger)readBytesAvailable {
    return 0;
}

- (NSData *)readData:(NSUInteger)bytesToRead {
    return nil;
}

- (void)writeData:(NSData *)data {
    
}

- (void)cancelWriteData {
    
}

@end
