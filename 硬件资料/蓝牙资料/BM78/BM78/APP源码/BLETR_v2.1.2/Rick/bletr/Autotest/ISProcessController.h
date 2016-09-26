//
//  ISProcessController.h
//  AutoTest
//
//  Created by Rick on 13/12/26.
//  Copyright (c) 2013年 Rick. All rights reserved.
//

#import <Foundation/Foundation.h>

#define Log_Notification @"Log_Notification"

@interface ISProcessController : NSObject
+ (ISProcessController *)sharedInstance;
- (void)start;
- (void)stop;
- (void)upload;
- (void)cancel;
@end
