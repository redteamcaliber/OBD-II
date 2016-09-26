//
//  MFi_DeviceListController.h
//  MFi_SPP
//
//  Created by Rick on 13/10/31.
//
//

#import <UIKit/UIKit.h>
@class ISDataPath;
@protocol ISDeviceProtocol;

@interface MFi_DeviceListController : UITableViewController

@property (weak) id<ISDeviceProtocol>delegate;
@end
@protocol ISDeviceProtocol <NSObject>

- (void)didSelectDevice:(ISDataPath *)accessory;

@end