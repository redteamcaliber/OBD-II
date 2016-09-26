//
//  ISBLEDataPath.h
//  MFi_SPP
//
//  Created by Rick on 13/10/28.
//
//

#import "ISDataPath.h"
#import "ReliableBurstData.h"
#import <CoreBluetooth/CoreBluetooth.h>

#define AIR_PATCH_COMMAND_VENDOR_MP_ENABLE      0x03
#define AIR_PATCH_COMMAND_XMEMOTY_READ          0x08
#define AIR_PATCH_COMMAND_XMEMOTY_WRITE         0x09
#define AIR_PATCH_COMMAND_E2PROM_READ           0x0a
#define AIR_PATCH_COMMAND_E2PROM_WRITE          0x0b
#define AIR_PATCH_COMMAND_READ                  0x24

#define AIR_PATCH_SUCCESS   0x00

#define AIR_PATCH_ACTION_CHANGE_DEVICE_NAME     0X01
#define AIR_PATCH_ACTION_READ_ADVERTISE_DATA1   0X02
#define AIR_PATCH_ACTION_READ_ADVERTISE_DATA2   0X03
#define AIR_PATCH_ACTION_UPDATE_ADVERTISE_DATA  0X04
#define AIR_PATCH_ACTION_CHANGE_DEVICE_NAME_MEMORY     0X05
#define AIR_PATCH_ACTION_READ                   0X24

#define ADVERTISE_DATA_TYPE_COMPLETE_DEVICE_NAME 0X09
#define ADVERTISE_DATA_TYPE_SHORTEN_DEVICE_NAME  0X08

typedef enum {
    UPDATE_PARAMETERS_STEP_PREPARE = 0,
    UPDATE_PARAMETERS_STEP_CHECK_RESULT,
}UPDATE_PARAMETERS_STEP;

typedef struct _AIR_PATCH_COMMAND_FORMAT
{
    unsigned char commandID;
    char parameters[19];
}__attribute__((packed)) AIR_PATCH_COMMAND_FORMAT;

typedef struct _AIR_PATCH_EVENT_FORMAT
{
    char    status;
    unsigned char commandID;
    char parameters[16];
}__attribute__((packed)) AIR_PATCH_EVENT_FORMAT;


typedef struct _WRITE_EEPROM_COMMAND_FORMAT
{
    unsigned char addr[2];
    unsigned char length;
    char    data[16];
}__attribute__((packed)) WRITE_EEPROM_COMMAND_FORMAT;

typedef struct _CONNECTION_PARAMETER_FORMAT
{
    unsigned char status;
    unsigned short minInterval;
    unsigned short maxInterval;
    unsigned short latency;
    unsigned short connectionTimeout;
}__attribute__((packed)) CONNECTION_PARAMETER_FORMAT;


@interface ISBLEDataPath : ISDataPath
@property (nonatomic,strong,readonly) CBPeripheral *peripheral;
@property (nonatomic,strong,readonly) NSString *advName;
@property (nonatomic,readonly) CBPeripheralState state;
@property (nonatomic,assign) BOOL connecting;
@property (assign) BOOL canSendData;
@property (assign) BOOL    isNotifying;


//DIS
@property(retain) CBCharacteristic *manufactureNameChar;
@property(retain) CBCharacteristic *modelNumberChar;
@property(retain) CBCharacteristic *serialNumberChar;
@property(retain) CBCharacteristic *hardwareRevisionChar;
@property(retain) CBCharacteristic *firmwareRevisionChar;
@property(retain) CBCharacteristic *softwareRevisionChar;
@property(retain) CBCharacteristic *systemIDChar;
@property(retain) CBCharacteristic *certDataListChar;
@property(retain) CBCharacteristic *specificChar1;
@property(retain) CBCharacteristic *specificChar2;

//Proprietary
@property(retain) CBCharacteristic *airPatchChar;
@property(retain) CBCharacteristic *transparentDataWriteChar;
@property(retain) CBCharacteristic *transparentDataReadChar;
@property(retain) CBCharacteristic *connectionParameterChar;
@property(assign) UPDATE_PARAMETERS_STEP   updateConnectionParameterStep;
@property(readonly) ReliableBurstData *transmit;

@property(assign) CONNECTION_PARAMETER_FORMAT connectionParameter;
@property(assign) CONNECTION_PARAMETER_FORMAT backupConnectionParameter;

@property(assign) short   airPatchAction;
@property(assign) BOOL    vendorMPEnable;

@property (assign,readonly) NSUUID *UUID;
- (void)setPeripheral:(CBPeripheral *)peripheral withAdvName:(NSString *)advName;

@end
