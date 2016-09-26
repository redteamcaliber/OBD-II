//
//  ISUtility.m
//  Lighting
//
//  Created by D500 user on 14/6/27.
//  Copyright (c) 2014年 ISSC. All rights reserved.
//

#import "ISUtility.h"

@implementation ISUtility

+ (NSString *)convertDataToHexString:(NSData *)data {
    uint8_t *buf = (uint8_t *)[data bytes];
    NSMutableString *str = [[NSMutableString alloc] init];
    for (int i = 0; i < [data length]; i++) {
        [str appendFormat:@"%02X", buf[i]];
    }
    return str;
}
/*
+ (NSMutableData *) hexStrToData: (NSString *)hexStr
{
    NSMutableData *data= [[NSMutableData alloc] init];
    NSUInteger len = [hexStr length];
    
    unsigned char whole_byte;
    char byte_chars[3] = {'\0','\0','\0'};
    int i;
    for (i=0; i < len/2; i++) {
        byte_chars[0] = [hexStr characterAtIndex:i*2];
        byte_chars[1] = [hexStr characterAtIndex:i*2+1];
        whole_byte = strtol(byte_chars, NULL, 16);
        [data appendBytes:&whole_byte length:1];
    }
    return data;
}*/

+ (NSData *)convertHexToData:(NSString *)hexString
{
	NSMutableData *data = [[NSMutableData alloc] init];
    @try {
		NSUInteger location = 0;
		NSString *substring;
		unsigned intValue;
		while (1) {
			substring = [hexString substringWithRange:NSMakeRange(location, 2)];
			location+=2;
			NSScanner *scanner = [NSScanner scannerWithString:[NSString stringWithFormat:@"0x%@", substring]];
			if ([scanner scanHexInt:&intValue]) {
				[data appendBytes:&intValue length:1];
			}
			if (location >= [hexString length]) {
				break;
			}
		}
	}
	@catch (NSException * e) {
		
	}
	return data;
}

@end
