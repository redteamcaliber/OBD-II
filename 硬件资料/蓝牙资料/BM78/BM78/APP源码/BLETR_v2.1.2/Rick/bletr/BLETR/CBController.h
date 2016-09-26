//
//  CBController.h
//  BLETR
//
//  Created by user D500 on 12/2/15.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreBluetooth/CoreBluetooth.h>
#import "UUID.h"
#import "MyPeripheral.h"
/*
enum {
    LE_STATUS_IDLE = 0,
    LE_STATUS_SCANNING,
    LE_STATUS_CONNECTING,
    LE_STATUS_CONNECTED
};
*/

@protocol CBControllerDelegate;
@interface CBController : NSObject<CBCentralManagerDelegate, CBPeripheralDelegate,ReliableBurstDataDelegate>
{

}

@property(assign) id<CBControllerDelegate> delegate;
@property (retain) NSMutableArray *devicesList;
@property (retain) NSMutableArray *connectingList;
@property (retain) NSMutableArray *connectedList;
@property (readonly) BOOL isScanning;

//- (void) startScan;
- (void) startScanWithUUID:(NSArray *)uuids;
- (void) stopScan;
- (void)connectDevice:(MyPeripheral *) myPeripheral;
- (void)connectDeviceWithIdentifier:(NSUUID *)identifier;
- (void)disconnectDevice:(MyPeripheral *) aPeripheral;

//- (void)updateDiscoverPeripherals;
//- (void)updateMyPeripheralForDisconnect:(MyPeripheral *)myPeripheral;
//- (void)updateMyPeripheralForNewConnected:(MyPeripheral *)myPeripheral;
//

- (void)removeMyPeripheral: (CBPeripheral *) aPeripheral;
- (void)configureTransparentServiceUUID: (NSString *)serviceUUID txUUID:(NSString *)txUUID rxUUID:(NSString *)rxUUID;
- (void)configureDeviceInformationServiceUUID: (NSString *)UUID1 UUID2:(NSString *)UUID2;
@end

@protocol CBControllerDelegate
@required
- (void)CBController:(CBController *)cbController didUpdateDiscoveredPeripherals:(NSArray *)peripherals;
- (void)CBController:(CBController *)cbController didConnectedPeripheral:(MyPeripheral *)peripheral;
- (void)CBController:(CBController *)cbController didDisconnectedPeripheral:(MyPeripheral *)peripheral;
@end