//
//  ISMFiDataPath.h
//  MFi_SPP
//
//  Created by Rick on 13/10/28.
//
//

#import "ISDataPath.h"
#import <ExternalAccessory/ExternalAccessory.h>

@interface ISMFiDataPath : ISDataPath
@property (nonatomic,strong,readonly) NSString *protocolString;

- (void)setProtocolString:(NSString *)protocolString withAccessory:(EAAccessory *)accessory;

@end
