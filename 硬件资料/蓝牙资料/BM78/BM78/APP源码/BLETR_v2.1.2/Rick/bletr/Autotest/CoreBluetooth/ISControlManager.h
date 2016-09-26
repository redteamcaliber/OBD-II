//
//  ISControlManager.h
//  MFi_SPP
//
//  Created by Rick on 13/10/28.
//
//

#import <Foundation/Foundation.h>
typedef enum {
  ISControlManagerTypeEA,
  ISControlManagerTypeCB
}ISControlManagerType;

@protocol ISControlManagerDelegate;
@protocol ISControlManagerDeviceList;
@class ISDataPath;

@interface ISControlManager : NSObject
@property (assign,nonatomic,getter = isConnect) BOOL connect;
@property (strong,nonatomic,readonly) NSArray *connectedAccessory;
@property (assign) id<ISControlManagerDelegate> delegate;
@property (assign) id<ISControlManagerDeviceList> deviceList;

- (void)scanDeviceList:(ISControlManagerType)type;
- (void)connectDevice:(ISDataPath *)device;
- (void)connectDeviceWithUUID:(NSUUID *)uuid;
- (void)disconnectDevice:(ISDataPath *)device;
- (void)disconnectAllDevices;
- (void)stopScaning;
- (void)writeData:(NSData *)data;
- (void)writeData:(NSData *)data withAccessory:(ISDataPath *)accessory;
- (void)cancelWriteData;
+ (id)sharedInstance;

@end

@protocol ISControlManagerDelegate<NSObject>
@optional
- (void)accessoryDidDisconnect:(ISDataPath *)accessory error:(NSError *)error;
- (void)accessoryDidConnect:(ISDataPath *)accessory;
- (void)accessoryDidReadData:(ISDataPath *)accessory data:(NSData *)data;
- (void)accessoryDidWriteData:(ISDataPath *)accessory bytes:(int)bytes complete:(BOOL)complete;
- (void)accessoryDidFailToConnect:(ISDataPath *)accessory error:(NSError *)error;
- (void)accessoryDidFailToWriteData:(ISDataPath *)accessory error:(NSError *)error;

@end

@protocol ISControlManagerDeviceList<NSObject>
- (void)didGetDeviceList:(NSArray *)devices andConnected:(NSArray *)connectList;
@end
