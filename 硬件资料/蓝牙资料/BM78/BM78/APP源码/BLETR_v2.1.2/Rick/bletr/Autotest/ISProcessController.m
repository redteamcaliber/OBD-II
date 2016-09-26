//
//  ISProcessController.m
//  AutoTest
//
//  Created by Rick on 13/12/26.
//  Copyright (c) 2013年 Rick. All rights reserved.
//

#import "ISProcessController.h"
#import "ISControlManager.h"
#import "ISBLEDataPath.h"


@interface NSMutableData(Random)
+(id)randomDataWithLength:(NSUInteger)length;
@end

@implementation NSMutableData(Random)
+(id)randomDataWithLength:(NSUInteger)length
{
    /*NSMutableData* data=[NSMutableData dataWithLength:length];
    [[NSInputStream inputStreamWithFileAtPath:@"/dev/random"] read:(uint8_t*)[data mutableBytes] maxLength:length];
    return data;*/
    NSMutableData* data = [NSMutableData data];
    for (int i = 0 ; i < length; i++) {
        if (i == SHRT_MAX) {
            i = 0;
        }
        [data appendData:[[NSString stringWithFormat:@"%d",i] dataUsingEncoding:NSASCIIStringEncoding]];
        if (data.length >= length) {
            break;
        }
     }
    if (data.length > length) {
        [data replaceBytesInRange:NSMakeRange(length -1, data.length-length) withBytes:NULL length:0];
    }
    /*int err = SecRandomCopyBytes(kSecRandomDefault, length, [data mutableBytes]);
    if (err) {
        return nil;
    }*/
    return data;
}
@end

@interface ISProcessController () <ISControlManagerDelegate,ISControlManagerDeviceList> {
    int step;
    int sub_step;
    NSArray *testCaseArray;
    int counter;
    NSUserDefaults *def;
    NSUUID *uuid;
    dispatch_queue_t backgroundQueue;
    NSMutableData *data;
    int success_count;
    NSMutableDictionary *output;
    NSMutableData *receiveData;
    NSMutableArray *failData;
    BOOL isCancel;
}
@end

/*!
 *  step 0 : ready
 *  step 1 : get special UUID
 *  step 2 : connect test
 *  step 3 : transfer test
 *  step 4 : Special case
 */
@implementation ISProcessController
__strong static id _sharedObject = nil;
+ (ISProcessController *)sharedInstance
{
    static dispatch_once_t pred = 0;
    dispatch_once(&pred, ^{
        _sharedObject = [[self alloc] init];
    });
    return _sharedObject;
}

+ (id)allocWithZone:(NSZone *)zone {
    if (_sharedObject) {
        return _sharedObject;
    }
    else {
        return [super allocWithZone:zone];
    }
}

- (id)init {
    if (_sharedObject) {
        return _sharedObject;
    }
    else {
        self = [super init];
        if (self) {
            def = [NSUserDefaults standardUserDefaults];
            backgroundQueue = dispatch_queue_create("com.issc-tech.backgroundQueue", nil);
            isCancel = NO;
        }
        return self;
    }
}

- (void)start {
    if (![def objectForKey:@"selectDevice"]) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"" message:@"Please set device first!" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
        [self sendDone];
        return;
    }
    isCancel = NO;
    step = 1;
    // Try to connect first time
    uuid = [[NSUUID alloc] initWithUUIDString:[[def objectForKey:@"selectDevice"] objectForKey:@"UUID"]];
    [[ISControlManager sharedInstance] setDelegate:self];
    [[ISControlManager sharedInstance] stopScaning];
    [[ISControlManager sharedInstance] connectDeviceWithUUID:uuid];
    [self sendLog:[NSString stringWithFormat:@"Try to find target device"]];
    output = [[NSMutableDictionary alloc] init];
    [output setObject:[[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"] forKey:@"app_version"];
    [output setObject:[UIDevice currentDevice].systemName forKey:@"os_type"];
    [output setObject:[UIDevice currentDevice].systemVersion forKey:@"os_version"];
    [output setObject:uuid.UUIDString forKey:@"dev_uuid"];
    [output setObject:[NSMutableArray array] forKey:@"results"];
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    [output setObject:[formatter stringFromDate:[NSDate date]] forKey:@"start_time"];
    NSLog(@"%@",[output description]);
    failData = [[NSMutableArray alloc] init];
}

- (void)cancel {
    isCancel = YES;
}

- (void)stop {
    step = 0;
    [[ISControlManager sharedInstance] disconnectAllDevices];
    [[ISControlManager sharedInstance] stopScaning];
    [[ISControlManager sharedInstance] setDelegate:nil];
    [[ISControlManager sharedInstance] setDeviceList:nil];
    output = nil;
    receiveData = nil;
}

- (void)connectTestCase {
    counter++;
    [self sendLog:[NSString stringWithFormat:@"Connecting test case %d:%d/%d",sub_step+1,counter,[testCaseArray[sub_step] intValue]]];
    [[ISControlManager sharedInstance] setDeviceList:self];
    [[ISControlManager sharedInstance] scanDeviceList:ISControlManagerTypeCB];
    [self performSelector:@selector(scanTimeout) withObject:nil afterDelay:60.0];
}

- (void)transferTestCase {
    int size = [[testCaseArray[sub_step] objectForKey:@"Size"] intValue];
    [self sendLog:[NSString stringWithFormat:@"Transfer test case %d:size %d, write with response %@",sub_step+1,size,[[testCaseArray[sub_step] objectForKey:@"writeWithResponse"] boolValue]?@"YES":@"NO"]];
    [[ISControlManager sharedInstance] setDeviceList:self];
    [[ISControlManager sharedInstance] scanDeviceList:ISControlManagerTypeCB];
    [self performSelector:@selector(scanTimeout) withObject:nil afterDelay:60.0];

}

- (void)specialTestCase {
    int case_id = [[testCaseArray[sub_step] objectForKey:@"ID"] intValue];
    switch (case_id) {
        case 1: {
            counter++;
            [self sendLog:[NSString stringWithFormat:@"Special test case %d:%d/%d Type: %d, send data and disconnect in random time (10 s to 30 s), write with response %@",sub_step+1,counter,[testCaseArray[sub_step][@"count"] intValue],case_id,[[testCaseArray[sub_step] objectForKey:@"writeWithResponse"] boolValue]?@"YES":@"NO"]];
        }
            break;
        case 2: {
            counter++;
            [self sendLog:[NSString stringWithFormat:@"Special test case %d:%d/%d Type: %d, send data and disconnect in random time (10 s to 30 s), write with response %@",sub_step+1,counter,[testCaseArray[sub_step][@"count"] intValue],case_id,[[testCaseArray[sub_step] objectForKey:@"writeWithResponse"] boolValue]?@"YES":@"NO"]];
        }
            break;
    
        default:
            break;
    }
    [[ISControlManager sharedInstance] setDeviceList:self];
    [[ISControlManager sharedInstance] scanDeviceList:ISControlManagerTypeCB];
    [self performSelector:@selector(scanTimeout) withObject:nil afterDelay:60.0];
    
}

- (void)runTestCase {
    switch (step) {
        case 2: {
            if (!testCaseArray || [testCaseArray count] == 0) {
                [self sendLog:[NSString stringWithFormat:@"No connecting test case select%@",@""]];
                step = 3;
                sub_step = 0;
                counter = 0;
                success_count = 0;
                testCaseArray  = [def objectForKey:@"TestCase_Transfer"];
                receiveData = [[NSMutableData alloc] init];
                [self runTestCase];
                return;
            }
            int total = [testCaseArray[sub_step] intValue];
            [self sendLog:@"*********************************************\n"];
            if (counter >= total || isCancel) {
                [self sendLog:total now:counter andSuccessTime:success_count];
                [self sendLog:[NSString stringWithFormat:@"Success Time:%d",success_count]];
                NSDictionary *dis;
                if (isCancel) {
                    dis = @{@"case_name": [NSString stringWithFormat:@"Connect%d",total],
                            @"case_results":@[@{@"success_times": @(success_count),
                                                @"total_times":@(total),
                                                @"failed_times":@(counter-success_count),
                                                @"results":@"Cancel"}]};
                }
                else {
                    dis = @{@"case_name": [NSString stringWithFormat:@"Connect%d",total],
                            @"case_results":@[@{@"success_times": @(success_count),
                                                @"total_times":@(total),
                                                @"failed_times":@(total-success_count),
                                                @"results":(total-success_count)>0?@"Failed":@"Pass"}]};
                }
                NSMutableArray *array = [output objectForKey:@"results"];
                [array addObject:dis];
                sub_step++;
                success_count = 0;
                counter = 0;
                if (sub_step >= [testCaseArray count]|| isCancel) {
                    [self sendLog:[NSString stringWithFormat:@"Connecting test case complete%@",@""]];
                    step = 3;
                    sub_step = 0;
                    testCaseArray  = [def objectForKey:@"TestCase_Transfer"];
                    receiveData = [[NSMutableData alloc] init];
                    [self runTestCase];
                    return;
                }
            }
            [self sendLog:total now:counter+1 andSuccessTime:success_count];
            [self connectTestCase];
        }
            break;
        case 3: {
            if (!testCaseArray || [testCaseArray count] == 0) {
                [self sendLog:[NSString stringWithFormat:@"No transfer test case select%@",@""]];
                step = 4;
                sub_step = 0;
                counter = 0;
                testCaseArray = [def objectForKey:@"TestCase_Special"];
                [self runTestCase];
                return;
            }
            [self sendLog:@"*********************************************\n"];
            if (sub_step >= [testCaseArray count]  || isCancel) {
                [self sendLog:(int)[testCaseArray count] now:sub_step andSuccessTime:(int)[receiveData length]];
                [self sendLog:[NSString stringWithFormat:@"Transfer test case complete%@",@""]];
                step = 4;
                sub_step = 0;
                counter = 0;
                testCaseArray = [def objectForKey:@"TestCase_Special"];
                [self runTestCase];
                return;
            }
            [self sendLog:(int)[testCaseArray count] now:sub_step+1 andSuccessTime:(int)[receiveData length]];
            if ([[testCaseArray[sub_step] objectForKey:@"writeWithResponse"] boolValue]) {
                [def setBool:YES forKey:@"writeWithResponse"];
            }
            else {
                [def setBool:NO forKey:@"writeWithResponse"];
            }
            [def synchronize];
            [self transferTestCase];
        }
            break;
        case 4: {
            if (!testCaseArray || [testCaseArray count] == 0) {
                [self sendLog:[NSString stringWithFormat:@"No special test case select%@",@""]];
                step = 5;
                sub_step = 0;
                counter = 0;
                testCaseArray  = nil;
                [self runTestCase];
                return;
            }
            int total = [testCaseArray[sub_step][@"count"] intValue];
            [self sendLog:@"*********************************************\n"];
            if (counter >= total || isCancel) {
                [self sendLog:total now:counter andSuccessTime:success_count];
                [self sendLog:[NSString stringWithFormat:@"Success Time:%d",success_count]];
                if ([failData count]>0) {
                    [self sendLog:[NSString stringWithFormat:@"Fail:%@",[failData description]]];
                }
                NSDictionary *dis;
                if (isCancel) {
                    dis = @{@"case_name": [NSString stringWithFormat:@"Special%@",testCaseArray[sub_step][@"ID"]],
                            @"case_results":@[@{@"success_times": @(success_count),
                                                @"total_times":@(counter),
                                                @"failed_times":@(counter-success_count),
                                                @"results":@"Cancel"}]};
                }
                else {
                    dis = @{@"case_name": [NSString stringWithFormat:@"Special%@",testCaseArray[sub_step][@"ID"]],
                            @"case_results":@[@{@"success_times": @(success_count),
                                                @"total_times":@(total),
                                                @"failed_times":@(total-success_count),
                                                @"results":(total-success_count)>0?@"Failed":@"Pass"}]};
                }
                NSMutableArray *array = [output objectForKey:@"results"];
                [array addObject:dis];
                sub_step++;
                success_count = 0;
                counter = 0;
                if (sub_step >= [testCaseArray count]|| isCancel) {
                    [self sendLog:[NSString stringWithFormat:@"Special test case complete%@",@""]];
                    step = 5;
                    sub_step = 0;
                    counter = 0;
                    testCaseArray  = nil;
                    [self runTestCase];
                    return;
                }
            }
            [self sendLog:total now:counter+1 andSuccessTime:success_count];
            if ([[testCaseArray[sub_step] objectForKey:@"writeWithResponse"] boolValue]) {
                [def setBool:YES forKey:@"writeWithResponse"];
            }
            else {
                [def setBool:NO forKey:@"writeWithResponse"];
            }
            [def synchronize];
            [self specialTestCase];
        }
            break;
        case 5: {
            [self sendLog:[NSString stringWithFormat:@"Test complete:%@",uuid.UUIDString]];
            NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
            [formatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
            [output setObject:[formatter stringFromDate:[NSDate date]] forKey:@"finish_time"];
            NSData *output_data = [NSJSONSerialization  dataWithJSONObject:output options:NSJSONWritingPrettyPrinted error:nil];
            [formatter setDateFormat:@"'Result_'yyyyMMdd_HHmmss'.json'"];
            NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
            NSString *documentsDirectory = [paths objectAtIndex:0];
            NSString *file = [NSString stringWithFormat:@"%@/%@",documentsDirectory,[formatter stringFromDate:[NSDate date]]];
            [output_data writeToFile:file atomically:NO];
            /*if ([[NSUserDefaults standardUserDefaults] boolForKey:@"AutoUpload"]) {
                if (![[DBSession sharedSession] isLinked]) {
                    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"" message:@"You must link to dropbox to enable autoupload!" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [alert show];
                    });
                } else {
                    [[ISProcessController sharedInstance] upload];
                }
            }*/
            [self sendDone];
        }
            break;
        default:
            break;
    }
}

- (void)sendLog:(NSString *)string {
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:Log_Notification object:nil userInfo:@{@"Value":string}];
    });
}

- (void)sendLog:(int)total now:(int)now andSuccessTime:(int)success {
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:Log_Notification object:nil userInfo:@{@"Step":
                                @{@"total"  : @(total),
                                  @"now"    : @(now),
                                  @"success": @(success)}}];
    });
}

- (void)sendDone {
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:Log_Notification object:nil userInfo:@{@"Done":@""}];
    });
}


- (void)scanTimeout {
    if ([def boolForKey:@"StopWhenFail"]) {
        isCancel = YES;
    }
    [self sendLog:[NSString stringWithFormat:@"Can't find target device:%@",uuid.UUIDString]];
    [[ISControlManager sharedInstance] setDeviceList:nil];
    [[ISControlManager sharedInstance] stopScaning];
    [self performSelector:@selector(runTestCase) withObject:nil afterDelay:1];
    if (step == 4) {
        [failData addObject:@{@"Count": @(counter),@"Step":@"Scan",@"Reason":@"Timeout"}];
    }
}

- (void)receiveDataTimeout:(ISDataPath *)accessory {
    if (step != 3) {
        return;
    }
    if ([def boolForKey:@"StopWhenFail"]) {
        isCancel = YES;
    }
    [self sendLog:[NSString stringWithFormat:@"Receive data %lu bytes:%@",(unsigned long)[receiveData length],accessory.name]];
    BOOL data_matched;
    if ([receiveData isEqualToData:data]) {
        [self sendLog:@"Success"];
        data_matched = YES;
    }
    else {
        [self sendLog:@"Fail"];
        data_matched = NO;
    }
    NSDictionary *dis = @{@"case_name": [NSString stringWithFormat:@"Transfer%lu",(unsigned long)[data length]],
                          @"case_results":@[@{@"sent_data": @(counter),
                                              @"recv_data":@([receiveData length]),
                                              @"total_data":@([data length]),
                                              @"results":data_matched?@"Pass":@"Failed",
                                              @"data_matched":@(data_matched)}]};
    NSMutableArray *array = [output objectForKey:@"results"];
    [array addObject:dis];

    sub_step++;
    receiveData = [[NSMutableData alloc] init];
    [[ISControlManager sharedInstance] disconnectDevice:accessory];
}

#pragma mark - ISControlManagerDelegate
- (void)accessoryDidDisconnect:(ISDataPath *)accessory error:(NSError *)error {
    if (error) {
        if ([def boolForKey:@"StopWhenFail"]) {
            isCancel = YES;
        }
    }
    if (step == 1 || step == 2 || step == 3) {
        [self performSelector:@selector(runTestCase) withObject:nil afterDelay:1];
    }
    else if (step == 4) {
        if (error) {
            [self sendLog:[NSString stringWithFormat:@"Disconnect target device:%@ with error: %@",accessory.name,error]];
            [failData addObject:@{@"Count": @(counter),@"Step":@"Disconnect",@"Reason":error}];
        }
        else {
            success_count++;
            [self sendLog:[NSString stringWithFormat:@"Disconnect target device:%@",accessory.name]];
        }
        [self performSelector:@selector(runTestCase) withObject:nil afterDelay:1];
    }
}

- (void)accessoryDidConnect:(ISDataPath *)accessory {
    if (step == 1) {
        [self sendLog:[NSString stringWithFormat:@"Find target device:%@",accessory.name]];
        step = 2;
        sub_step = 0;
        counter = 0;
        success_count = 0;
        testCaseArray  = [def objectForKey:@"TestCase_Connect"];
        [[ISControlManager sharedInstance] disconnectDevice:accessory];

    }
    else if (step == 2) {
        [self sendLog:@"Success"];
        success_count++;
        [[ISControlManager sharedInstance] disconnectDevice:accessory];
    }
    else if (step == 3) {
        dispatch_async(backgroundQueue, ^{
            int size = [[testCaseArray[sub_step] objectForKey:@"Size"] intValue];
            data = [NSMutableData randomDataWithLength:size];
            [[ISControlManager sharedInstance] writeData:data withAccessory:accessory];
        });
    }
    else if (step == 4) {
        ISBLEDataPath *mAccessory = (ISBLEDataPath *)accessory;
        NSInteger size = [mAccessory.transmit transmitSize]*60;
        data = [NSMutableData randomDataWithLength:size];
        [[ISControlManager sharedInstance] writeData:data withAccessory:accessory];
        int disconnect_time = arc4random()%20 +11;
        [self sendLog:[NSString stringWithFormat:@"Disconnect time:%d s",disconnect_time]];
        [[ISControlManager sharedInstance] performSelector:@selector(disconnectDevice:) withObject:accessory afterDelay:disconnect_time];

    }
}

- (void)accessoryDidReadData:(ISDataPath *)accessory data:(NSData *)rx_data {
    if (step != 3) {
        return;
    }
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(receiveDataTimeout:) object:accessory];
    [self performSelector:@selector(receiveDataTimeout:) withObject:accessory afterDelay:10.0];
    [receiveData appendData:rx_data];
}

- (void)accessoryDidWriteData:(ISDataPath *)accessory bytes:(int)bytes complete:(BOOL)complete {
    if (step == 4) {
        if (complete) {
            [[ISControlManager sharedInstance] writeData:data withAccessory:accessory];
        }
    }
    else {
        [self sendLog:[NSString stringWithFormat:@"Write data %d/%lu :%@",bytes,(unsigned long)[data length],accessory.name]];
        counter = bytes;
        if (complete) {
            [self sendLog:@"Complete"];
        }
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(receiveDataTimeout:) object:accessory];
        [self performSelector:@selector(receiveDataTimeout:) withObject:accessory afterDelay:10.0];
    }
}

- (void)accessoryDidFailToConnect:(ISDataPath *)accessory error:(NSError *)error {
    if ([def boolForKey:@"StopWhenFail"]) {
        isCancel = YES;
    }
    if (step == 1) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"" message:@"Can't find target device!" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        dispatch_async(dispatch_get_main_queue(), ^{
            [alert show];
        });
        [self sendLog:[NSString stringWithFormat:@"Error Reason:%@",@"Can't find target device!"]];
        [self sendDone];
    }
    else if (step == 2 || step == 3 || step == 4) {
        [self sendLog:[NSString stringWithFormat:@"Error Reason:%@",error?[error localizedDescription]:@"Timeout"]];
        /*step = 0;
        sub_step = 0;
        counter = 0;
        testCaseArray = nil;
        */
        if (step == 4) {
            [failData addObject:@{@"Count": @(counter),@"Step":@"Connect",@"Reason":error?error:@"Timeout"}];
        }
        [self performSelector:@selector(runTestCase) withObject:nil afterDelay:1];
    }
}

- (void)accessoryDidFailToWriteData:(ISDataPath *)accessory error:(NSError *)error {
    if ([def boolForKey:@"StopWhenFail"]) {
        isCancel = YES;
    }
    if (step == 3) {
        [self sendLog:[NSString stringWithFormat:@"Error Reason:%@",error?[error localizedDescription]:@"Timeout"]];
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(receiveDataTimeout:) object:accessory];
        NSDictionary *dis = @{@"case_name": [NSString stringWithFormat:@"Transfer%lu",(unsigned long)[data length]],
                              @"case_results":@[@{@"sent_data": @(counter),
                                                  @"recv_data":@([receiveData length]),
                                                  @"total_data":@([data length]),
                                                  @"results":@"Failed",
                                                  @"data_matched":@(NO)}]};
        NSMutableArray *array = [output objectForKey:@"results"];
        [array addObject:dis];
        
        sub_step++;
        [[ISControlManager sharedInstance] disconnectDevice:accessory];
    }
    else if (step == 4) {
        [self sendLog:[NSString stringWithFormat:@"Error Reason:%@",error?[error localizedDescription]:@"Timeout"]];
        //sub_step++;
        [failData addObject:@{@"Count": @(counter),@"Step":@"Write",@"Reason":error?error:@"Timeout"}];
        success_count--;
        [NSObject cancelPreviousPerformRequestsWithTarget:[ISControlManager sharedInstance] selector:@selector(disconnectDevice:) object:accessory];
        [[ISControlManager sharedInstance] disconnectDevice:accessory];
    }
}

#pragma mark - ISControlManagerDeviceList
- (void)didGetDeviceList:(NSArray *)devices andConnected:(NSArray *)connectList {
    for (ISBLEDataPath *device in devices) {
        if ([device.UUID isEqual:uuid]) {
            NSLog(@"find %@",uuid.UUIDString);
            [[ISControlManager sharedInstance] stopScaning];
            [[ISControlManager sharedInstance] setDeviceList:nil];
            [self sendLog:[NSString stringWithFormat:@"Find target device:%@",device.name]];
            [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(scanTimeout) object:nil];
            [[ISControlManager sharedInstance] performSelector:@selector(connectDeviceWithUUID:) withObject:uuid afterDelay:1];
            return;
        }
    }
}

@end
