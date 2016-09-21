//
//  BLEDeviceViewController.h
//  BuleToothText
//
//  Created by try on 14-12-29.
//  Copyright (c) 2014年 TRY. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SerialGATT.h"

#define RSSI_THRESHOLD -60
#define WARNING_MESSAGE @"z"

@class CBPeripheral;
@class SerialGATT;

@interface BLEDeviceViewController : UIViewController<BTSmartSensorDelegate>
@property (weak, nonatomic) IBOutlet UILabel *count;

@property (strong, nonatomic) CBPeripheral *peripheral;
@property (strong, nonatomic) SerialGATT *sensor;

//@property (strong, nonatomic) NSTimer *timer;

@property (strong, nonatomic) NSMutableArray *rssi_container; // used for contain the indexers of the lower rssi value

@property (weak, nonatomic) IBOutlet UILabel *textFromAdruino;
- (IBAction)TrackingSwitch:(id)sender;
@property (weak, nonatomic) IBOutlet UISwitch *theTrackingSwitch;
- (IBAction)sendMsgToArduino:(id)sender;
@property (weak, nonatomic) IBOutlet UITextField *MsgToArduino;
@property (weak, nonatomic) IBOutlet UITextView *tvRecv;
@property (weak, nonatomic) IBOutlet UILabel *lbDevice;




@end
