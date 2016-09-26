//
//  ISUUIDCompare.m
//  AutoTest
//
//  Created by Rick on 13/12/23.
//  Copyright (c) 2013年 Rick. All rights reserved.
//

#import "ISUUIDCompare.h"
@implementation ISUUIDCompare

+ (BOOL)peripheral:(CBPeripheral *)peripheral isEqualToUUID:(NSUUID *)uuid {
    if ([peripheral respondsToSelector:@selector(identifier)]) {
        if ([peripheral.identifier isEqual:uuid]) {
            return YES;
        }
        return NO;
    }
    else {
        if (peripheral.UUID) {
            NSString *uuidStr = (__bridge NSString *)CFUUIDCreateString(NULL, peripheral.UUID);
            if ([uuid.UUIDString isEqualToString:uuidStr]) {
                return YES;
            }
        }
         return NO;
    }
}
@end
