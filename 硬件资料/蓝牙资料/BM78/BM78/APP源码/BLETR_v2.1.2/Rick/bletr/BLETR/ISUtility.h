//
//  ISUtility.h
//  Lighting
//
//  Created by D500 user on 14/6/27.
//  Copyright (c) 2014年 ISSC. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ISUtility : NSObject
+ (NSString *)convertDataToHexString:(NSData *)data;
+ (NSData *)convertHexToData:(NSString *)hexString;
@end
