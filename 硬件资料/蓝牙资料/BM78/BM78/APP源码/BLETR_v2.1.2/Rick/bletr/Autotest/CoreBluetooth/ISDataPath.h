//
//  ISDataPath.h
//  MFi_SPP
//
//  Created by Rick on 13/10/28.
//
//

/**
 *	Overwrite - (void)internalInit for interal object alloc
 */
#import <Foundation/Foundation.h>
@protocol ISDataPathDelegate;

@interface ISDataPath : NSObject
- (BOOL)openSession;
- (void)closeSession;

- (NSUInteger)readBytesAvailable;
- (NSData *)readData:(NSUInteger)bytesToRead;
- (void)writeData:(NSData *)data;
- (void)cancelWriteData;

@property (nonatomic,weak) id<ISDataPathDelegate> delegate;
@property (nonatomic,strong,readonly) NSString *name;
@property (nonatomic,strong,readonly) NSString *hardwareRevision;
@property (nonatomic,strong,readonly) NSString *firmwareRevision;
@property (nonatomic,strong,readonly) NSString *manufacturer;
@property (nonatomic,strong,readonly) NSString *modelNumber;
@property (nonatomic,strong,readonly) NSString *serialNumber;

@end

@protocol ISDataPathDelegate <NSObject>

@required
- (void)dataReceived:(ISDataPath *)dataPath;
- (void)accessoryDidDisconnect:(ISDataPath *)dataPath;
- (void)accessoryDidConnected:(ISDataPath *)dataPath;
- (void)accessoryDidWriteData:(ISDataPath *)accessory bytes:(int)bytes complete:(BOOL)complete;
- (void)accessoryDidFailToWriteData:(ISDataPath *)accessory error:(NSError *)error;

@optional
- (void)accessoryError;         // Use for app first launch

@end
