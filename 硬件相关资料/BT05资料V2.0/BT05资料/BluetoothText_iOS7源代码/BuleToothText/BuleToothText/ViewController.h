//
//  ViewController.h
//  BuleToothText
//
//  Created by try on 14-12-29.
//  Copyright (c) 2014年 TRY. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SerialGATT.h"

@interface ViewController : UIViewController

@property (strong, nonatomic) SerialGATT *sensor;
@property (nonatomic, retain) NSMutableArray *peripheralViewControllerArray;

-(void) scanTimer:(NSTimer *)timer;


@end
