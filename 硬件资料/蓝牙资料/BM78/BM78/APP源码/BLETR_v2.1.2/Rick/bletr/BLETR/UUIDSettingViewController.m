//
//  UUIDSettingViewController.m
//  BLETR
//
//  Created by D500 user on 13/6/14.
//  Copyright (c) 2013年 ISSC. All rights reserved.
//

#import "UUIDSettingViewController.h"
#import "AppDelegate.h"

@interface UUIDSettingViewController ()
- (NSString *) getUuid: (NSString *)uuid;
- (void) animateTextField: (UITextField *)textField up:(BOOL)up;
@end

@implementation UUIDSettingViewController



- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        self.transServiceUUIDStr = nil;
        self.transTxUUIDStr = nil;
        self.transRxUUIDStr = nil;
        self.disUUID1Str = nil;
        self.disUUID2Str = nil;
        self.isUUIDAvailable = FALSE;
        self.isDISUUIDAvailable = FALSE;
        if (floor(NSFoundationVersionNumber) > NSFoundationVersionNumber_iOS_6_1) {
            self.edgesForExtendedLayout = UIRectEdgeNone;
        }
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.

}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    NSLog(@"[UUIDSettingViewController] textFieldShouldReturn");

    [textField resignFirstResponder];
    return TRUE;
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    
    NSCharacterSet *unacceptedInput = [[NSCharacterSet characterSetWithCharactersInString:@"1234567890aAbBcCdDeEfF"] invertedSet];
    if ([[string componentsSeparatedByCharactersInSet:unacceptedInput] count] > 1)
        return NO;
    else {
        NSUInteger newLength = [textField.text length] + [string length] - range.length;
        if ((textField == _disUUID1)||(textField == _disUUID2)) {
            return (newLength > 4) ? NO : YES;
        }
        else
            return (newLength > 32) ? NO : YES;
    }
}
- (void)dealloc {
    [_serviceUUID release];
    [_txUUID release];
    [_rxUUID release];
    if (self.transServiceUUIDStr)
        [self.transServiceUUIDStr release];
    if (self.transTxUUIDStr)
        [self.transTxUUIDStr release];
    if (self.transRxUUIDStr)
        [self.transRxUUIDStr release];
    [_disUUID1 release];
    [_disUUID2 release];
    if (self.disUUID1Str)
        [self.disUUID1Str release];
    if (self.disUUID2Str)
        [self.disUUID2Str release];
    [super dealloc];
}
- (void)viewDidUnload {
    [self setServiceUUID:nil];
    [self setTxUUID:nil];
    [self setRxUUID:nil];
    [self setDisUUID1:nil];
    [self setDisUUID2:nil];
    [super viewDidUnload];
}
- (IBAction)applySetting:(id)sender {

    //[textField resignFirstResponder];
    if (([[self.disUUID1 text] length] >0) || ([[self.disUUID2 text] length] >0)){
        if ([[self.disUUID1 text] length] != 4)
        {
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Invalid UUID Setting" message:@"DIS UUID1 must match 16-bit" delegate:self cancelButtonTitle:@"Close" otherButtonTitles:nil];
            [alertView show];
            [alertView release];
            return;
        }
        else{
            if (self.disUUID1Str)
                [self.disUUID1Str release];
            if (self.disUUID2Str)
                [self.disUUID1Str release];
            
            if ([[self.disUUID2 text] length] >0) {
                if ([[self.disUUID2 text] length] != 4) {
                    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Invalid UUID Setting" message:@"DIS UUID 2 must match 16-bit" delegate:self cancelButtonTitle:@"Close" otherButtonTitles:nil];
                    [alertView show];
                    [alertView release];
                    return;
                }
                else
                    self.disUUID2Str = [self getUuid:[self.disUUID2 text]];
            }
            else
                self.disUUID2Str = nil;
            self.disUUID1Str = [self getUuid:[self.disUUID1 text]];
            self.isDISUUIDAvailable = TRUE;
        }
    }
    
    if (([[self.serviceUUID text] length] >0) || ([[self.txUUID text] length] >0) || ([[self.rxUUID text] length] >0)){
        if ((([[self.serviceUUID text] length] != 4) && ([[self.serviceUUID text] length] != 32))
            || (([[self.txUUID text] length] != 4) && ([[self.txUUID text] length] != 32))
            || (([[self.rxUUID text] length] != 4) && ([[self.rxUUID text] length] != 32))
            ) {
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Invalid UUID Setting" message:@"UUID must match 16-bit or 128-bit format" delegate:self cancelButtonTitle:@"Close" otherButtonTitles:nil];
            [alertView show];
            [alertView release];
            return;
        }
        if (self.transServiceUUIDStr)
            [self.transServiceUUIDStr release];
        if (self.transTxUUIDStr)
            [self.transTxUUIDStr release];
        if (self.transRxUUIDStr)
            [self.transRxUUIDStr release];
        self.transServiceUUIDStr = [self getUuid:[self.serviceUUID text]];
        self.transTxUUIDStr = [self getUuid:[self.txUUID text]];
        self.transRxUUIDStr = [self getUuid:[self.rxUUID text]];
        self.isUUIDAvailable = TRUE;
    }
    
    
    //NSLog(@"%@",self.transServiceUUIDStr);
    //NSLog(@"%@",self.transTxUUIDStr);
    //NSLog(@"%@",self.transRxUUIDStr);
    
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    [[appDelegate navigationController] popToRootViewControllerAnimated:YES];
    
}

- (IBAction)resetSetting:(id)sender {
    self.isUUIDAvailable = FALSE;
    self.isDISUUIDAvailable = FALSE;
    [self.serviceUUID setText:@""];
    [self.txUUID setText:@""];
    [self.rxUUID setText:@""];
    [self.disUUID1 setText:@""];
    [self.disUUID2 setText:@""];
}

- (NSString *) getUuid: (NSString *)uuid{
    NSMutableString *data= [[NSMutableString alloc] init];

    [data setString:uuid];
    if ([data length] == 32) {
        [data insertString:@"-" atIndex:20];
        [data insertString:@"-" atIndex:16];
        [data insertString:@"-" atIndex:12];
        [data insertString:@"-" atIndex:8];
    }
    return data;//[data autorelease];
}

- (void) animateTextField: (UITextField *)textField up:(BOOL)up{
    const int movementDistance = 90; // tweak as needed
    const float movementDuration = 0.3f; // tweak as needed
    
    int movement = (up ? -movementDistance : movementDistance);
    
    [UIView beginAnimations: @"anim" context: nil];
    [UIView setAnimationBeginsFromCurrentState: YES];
    [UIView setAnimationDuration: movementDuration];
    self.view.frame = CGRectOffset(self.view.frame, 0, movement);
    [UIView commitAnimations];
}

-(void)textFieldDidBeginEditing:(UITextField *)textField{
    if((textField == _rxUUID)||(textField == _disUUID1)||(textField == _disUUID2))
        [self animateTextField:textField up:YES];
}

-(void)textFieldDidEndEditing:(UITextField *)textField{
    if((textField == _rxUUID)||(textField == _disUUID1)||(textField == _disUUID2))
       [self animateTextField:textField up:NO];
}
@end
