//
//  BLEDeviceViewController.m
//  BuleToothText
//
//  Created by try on 14-12-29.
//  Copyright (c) 2014年 TRY. All rights reserved.
//

#import "BLEDeviceViewController.h"
#import <AudioToolbox/AudioToolbox.h>
#import "QuartzCore/QuartzCore.h"
#import "ViewController.h"

@interface BLEDeviceViewController ()<BTSmartSensorDelegate,UITextFieldDelegate>

@end

@implementation BLEDeviceViewController
@synthesize MsgToArduino;
@synthesize theTrackingSwitch;
@synthesize textFromAdruino;
@synthesize tvRecv;
@synthesize lbDevice;

@synthesize rssi_container;


//@synthesize timer;

@synthesize peripheral;
@synthesize sensor;

static NSInteger fasong;
static NSInteger jieshou;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    self.title = self.sensor.activePeripheral.name;
    self.sensor.delegate = self;
    //[self.sensor notify:self.sensor.activePeripheral on:YES];
    CFStringRef s = CFUUIDCreateString(NULL, sensor.activePeripheral.UUID);
    textFromAdruino.text = (__bridge NSString*)s;
    
    //self.textFromAdruino.lineBreakMode = UILineBreakModeWordWrap;
    //self.textFromAdruino.numberOfLines = 0;
    tvRecv.layer.borderWidth = 1;
    tvRecv.layer.borderColor = [[UIColor grayColor] CGColor];
    tvRecv.layer.cornerRadius = 8;
    tvRecv.layer.masksToBounds = YES;
    
    textFromAdruino.layer.borderWidth = 1;
    textFromAdruino.layer.borderColor = [[UIColor grayColor] CGColor];
    textFromAdruino.layer.cornerRadius = 8;
    textFromAdruino.layer.masksToBounds = YES;
    
    lbDevice.layer.borderWidth = 1;
    lbDevice.layer.borderColor = [[UIColor grayColor] CGColor];
    lbDevice.layer.cornerRadius = 8;
    lbDevice.layer.masksToBounds = YES;
    
    MsgToArduino.delegate = self;
    MsgToArduino.layer.borderColor = [[UIColor blackColor] CGColor];
    MsgToArduino.returnKeyType = UIReturnKeyDone;
}

- (void)back {
    ViewController * V = [[ViewController alloc] init];
    [self presentViewController:V animated:YES completion:^{
        
    }];
}

- (void)viewDidUnload
{
    [self setTextFromAdruino:nil];
    [self setTheTrackingSwitch:nil];
    [self setMsgToArduino:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

-(void) serialGATTCharValueUpdated:(NSString *)UUID value:(NSData *)data
{
    
    jieshou += [data length];
    NSString * charariste = [NSString stringWithFormat:@"TX: %d , RX: %d",fasong,jieshou];
    _count.text = charariste;
    NSString *value = [[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding];
    //textFromAdruino.text = [textFromAdruino.text stringByAppendingString:value];
    tvRecv.text= [tvRecv.text stringByAppendingString:value];
    [tvRecv scrollRangeToVisible:NSMakeRange(tvRecv.text.length, 1)];
}

- (IBAction)sendMsgToArduino:(id)sender {
    NSData *data = [MsgToArduino.text dataUsingEncoding:[NSString defaultCStringEncoding]];
    [sensor write:sensor.activePeripheral data:data];
    
    fasong += [data length];
    NSString * charariste = [NSString stringWithFormat:@"TX: %d , RX: %d",fasong,jieshou];
    _count.text = charariste;
}

-(void)textFieldDidBeginEditing:(UITextField *)textField
{
    CGRect frame = textField.frame;
    int offset = frame.origin.y + 32 - (self.view.frame.size.height - 216.0);
    NSTimeInterval anm = 0.30f;
    [UIView beginAnimations:@"ResizeForKeyboard" context:nil];
    [UIView setAnimationDuration:anm];
    if(offset > 0)
    {
        self.view.frame = CGRectMake(0.0f, -offset, self.view.frame.size.width, self.view.frame.size.height);
    }
    [UIView commitAnimations];
}

-(BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    return YES;
}

-(void)textFieldDidEndEditing:(UITextField *)textField
{
    self.view.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height);
}

-(void)setConnect
{
    tvRecv.text = @"OK+CONN";
}

-(void)setDisconnect
{
    tvRecv.text= [tvRecv.text stringByAppendingString:@"OK+LOST"];
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)TrackingSwitch:(id)sender {
    
}

@end
