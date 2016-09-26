//
//  ISUUIDCompare.h
//  AutoTest
//
//  Created by Rick on 13/12/23.
//  Copyright (c) 2013年 Rick. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>

@interface ISUUIDCompare : NSObject
+ (BOOL)peripheral:(CBPeripheral *)peripheral isEqualToUUID:(NSUUID *)uuid;
@end
