//
//  DataTransparentViewController.m
//  BLEServerTest
//
//  Created by D500 user on 13/1/29.
//  Copyright (c) 2013年 D500 user. All rights reserved.
//

#import "DataTransparentViewController.h"
#import "AppDelegate.h"
#import "ISSCButton.h"

#define BM77SPP_HW @"353035305f535050"
#define BM77SPP_FW @"32303233303230"
#define BM77SPP_AD 0xd97e

#define BLETR_HW @"353035305f424c455452"
#define BLETR_FW @"32303032303130"
#define BLETR_AD 0x4833

@interface NSString (HexString)
+ (NSString *)stringFromHexString:(NSString *)hexString;
@end

@implementation NSString(HexString)

+ (NSString *)stringFromHexString:(NSString *)hexString {
    
    // The hex codes should all be two characters.
    if (([hexString length] % 2) != 0)
        return nil;
    
    NSMutableString *string = [NSMutableString string];
    
    for (NSInteger i = 0; i < [hexString length]; i += 2) {
        
        NSString *hex = [hexString substringWithRange:NSMakeRange(i, 2)];
        NSInteger decimalValue = 0;
        sscanf([hex UTF8String], "%x", &decimalValue);
        [string appendFormat:@"%c", decimalValue];
    }
    
    return string;
}

@end

@interface DataTransparentViewController () <ReliableBurstDataDelegate>{
    NSString *_hardwareRevision;
    NSString *_firmwareRevision;
    BOOL isPatch;
    NSMutableArray *_loopBackQueue;
    NSTimer *_loopBackTimer;
}

@end

@implementation DataTransparentViewController
@synthesize dirArray;
@synthesize connectedPeripheral;
@synthesize comparedPath;
@synthesize checkRxDataTimer;
@synthesize receivedDataPath;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    NSLog(@"[DataTransparentViewController] initWithNibName");
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        content = [[NSMutableString alloc] initWithCapacity:100008];
        if (floor(NSFoundationVersionNumber) > NSFoundationVersionNumber_iOS_6_1) {
            self.edgesForExtendedLayout = UIRectEdgeNone;
        }
        isPatch = NO;
        _loopBackQueue = nil;
    }
    return self;
}

- (void)viewDidLoad
{
    NSLog(@"[DataTransparentViewController] viewDidLoad");
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(200, 28, 57, 57)];
    [titleLabel setBackgroundColor:[UIColor colorWithPatternImage:[UIImage imageNamed:@"Icon_old"]]];
    [titleLabel setTextAlignment:NSTextAlignmentCenter];//aaa
    self.navigationItem.titleView = titleLabel;
    [titleLabel release];
    
    ISSCButton *button = [ISSCButton buttonWithType:UIButtonTypeCustom];
    button.frame = CGRectMake(0.0f, 0.0f, 60.0f, 30.0f);
    [button addTarget:self action:@selector(saveReceivedData) forControlEvents:UIControlEventTouchUpInside];
    [button setTitle:@"Save As" forState:UIControlStateNormal];
    button.titleLabel.adjustsFontSizeToFitWidth = YES;
    saveAsButton = [[UIBarButtonItem alloc] initWithCustomView:button];
    //saveAsButton = [[UIBarButtonItem alloc] initWithTitle:@"Save As" style:UIBarButtonItemStyleBordered target:self action:@selector(saveReceivedData)];
    button = [ISSCButton buttonWithType:UIButtonTypeCustom];
    button.frame = CGRectMake(0.0f, 0.0f, 60.0f, 30.0f);
    [button addTarget:self action:@selector(selectCompareFile) forControlEvents:UIControlEventTouchUpInside];
    [button setTitle:@"Compare" forState:UIControlStateNormal];
    button.titleLabel.adjustsFontSizeToFitWidth = YES;
    compareButton = [[UIBarButtonItem alloc] initWithCustomView:button];
    //compareButton = [[UIBarButtonItem alloc] initWithTitle:@"Compare" style:UIBarButtonItemStyleBordered target:self action:@selector(selectCompareFile)];
    button = [ISSCButton buttonWithType:UIButtonTypeCustom];
    button.frame = CGRectMake(0.0f, 0.0f, 60.0f, 30.0f);
    [button addTarget:self action:@selector(selectTxFile) forControlEvents:UIControlEventTouchUpInside];
    [button setTitle:@" TX File " forState:UIControlStateNormal];
    button.titleLabel.adjustsFontSizeToFitWidth = YES;
    txFileButton = [[UIBarButtonItem alloc] initWithCustomView:button];
    //txFileButton = [[UIBarButtonItem alloc] initWithTitle:@" TX File " style:UIBarButtonItemStyleBordered target:self action:@selector(selectTxFile)];
    button = [ISSCButton buttonWithType:UIButtonTypeCustom];
    button.frame = CGRectMake(0.0f, 0.0f, 60.0f, 30.0f);
    [button addTarget:self action:@selector(clearWebView) forControlEvents:UIControlEventTouchUpInside];
    [button setTitle:@"  Clear  " forState:UIControlStateNormal];
    button.titleLabel.adjustsFontSizeToFitWidth = YES;
    clearButton = [[UIBarButtonItem alloc] initWithCustomView:button];
    //clearButton = [[UIBarButtonItem alloc] initWithTitle:@"  Clear  " style:UIBarButtonItemStyleBordered target:self action:@selector(clearWebView)];
    /*button = [ISSCButton buttonWithType:UIButtonTypeCustom];
     button.frame = CGRectMake(0.0f, 0.0f, 60.0f, 30.0f);
     [button addTarget:self action:@selector(cancelEditing) forControlEvents:UIControlEventTouchUpInside];
     [button setTitle:@"Cancel" forState:UIControlStateNormal];
     button.titleLabel.adjustsFontSizeToFitWidth = YES;
     cancelButton = [[UIBarButtonItem alloc] initWithCustomView:button];*/
    cancelButton = [[UIBarButtonItem alloc] initWithTitle:@"Cancel" style:UIBarButtonItemStyleDone target:self action:@selector(cancelEditing)];
    button = [ISSCButton buttonWithType:UIButtonTypeCustom];
    button.frame = CGRectMake(0.0f, 0.0f, 60.0f, 30.0f);
    [button addTarget:self action:@selector(toggleWriteType) forControlEvents:UIControlEventTouchUpInside];
    [button setTitle:@"Write Type" forState:UIControlStateNormal];
    button.titleLabel.adjustsFontSizeToFitWidth = YES;
    writeTypeButton = [[UIBarButtonItem alloc] initWithCustomView:button];
    //writeTypeButton = [[UIBarButtonItem alloc] initWithTitle:@"Write Type" style:UIBarButtonItemStyleBordered target:self action:@selector(toggleWriteType)];
    writeType = CBCharacteristicWriteWithResponse;
    
    NSArray *toolbarItems = [[NSArray alloc] initWithObjects:compareButton, txFileButton, writeTypeButton, clearButton, nil];
    self.toolbarItems = toolbarItems;
    [toolbarItems release];

    
    [self.webView setDelegate:self];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
    [self groupComponentsDisplay];
    editingTextField = self.inputTextField;
    fileManager = [NSFileManager defaultManager];
    
    NSString *path = [[NSBundle mainBundle] resourcePath];
    /*NSString *path = [[NSString alloc] initWithFormat:@"%@/%@.app",NSHomeDirectory(), [[[NSBundle mainBundle] infoDictionary]   objectForKey:@"CFBundleName"]];*/
    NSDirectoryEnumerator *dirEnumerator = [fileManager enumeratorAtPath: path];
    NSLog(path);
    dirArray = [[NSMutableArray alloc] init];
    
    NSString *currentFile;
    while (currentFile = [dirEnumerator nextObject]) {
        NSRange range = [currentFile rangeOfString:@".txt"];
        if (range.location != NSNotFound) {
            [dirArray addObject:currentFile];
        }
    }
    if ([dirArray count] == 0) {
        [dirArray addObject:@"No File"];
    }
    NSLog(@"dirarray count = %d", [dirArray count]);
    //[path release];
    comparedPath = nil;
    checkRxDataTimer = nil;
    receivedDataPath = nil;
}

- (void)viewDidAppear:(BOOL)animated {
    NSLog(@"[DataTransparentViewController] viewDidAppear");
    connectedPeripheral.deviceInfoDelegate = self;
    connectedPeripheral.proprietaryDelegate = self;
    if (isPatch) {
        [connectedPeripheral setTransDataNotification:TRUE];
    }
    else {
        [connectedPeripheral readHardwareRevision];
    }
    connectedPeripheral.transmit.delegate = self;
    [self groupComponentsDisplay];
    webFinishLoad = TRUE;
    [self reloadOutputView];
    
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    [[appDelegate navigationController] setToolbarHidden:NO animated:YES];
    if (([connectedPeripheral transparentDataWriteChar] == nil) || ([connectedPeripheral transparentDataReadChar] == nil) ) {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Service Not Found" message:@"Can't find custom service UUID or TX/RX UUID" delegate:self cancelButtonTitle:@"Close" otherButtonTitles:nil];
        [alertView show];
        [alertView release];
    }
    
}

- (void)viewDidDisappear:(BOOL)animated {
    NSLog(@"[DataTransparentViewController] viewDidDisappear");
    [editingTextField resignFirstResponder];
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    [[appDelegate navigationController] setToolbarHidden:YES animated:YES];
}

- (void)didReceiveMemoryWarning
{
    NSLog(@"[DataTransparentViewController] didReceiveMemoryWarning");
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
    
}

- (void)dealloc {
    NSLog(@"[DataTransparentViewController] dealloc");
    if (checkRxDataTimer)
        [checkRxDataTimer invalidate];
    if (receivedDataPath) {
        [fileManager removeItemAtPath:receivedDataPath error:NULL];
    }
    [_inputTextField release];
    [_segmentedControl release];
    [_timerDeltaTimeTextField release];
    [_timerPatternSizeTextField release];
    [_timerRepeatTimesTextField release];
    [_timerStartButton release];
    [_webView release];
    [_timerDeltaTimeLabel release];
    [_timerPatternSizeLabel release];
    [_timerRepeatTimesLabel release];
    [_timerLabel release];
    [_statusLabel release];
    [saveAsButton release];
    [compareButton release];
    [txFileButton release];
    [clearButton release];
    [cancelButton release];
    [writeTypeButton release];
    [_writeTypeLabel release];
    [_hardwareRevision release];
    [_firmwareRevision release];
    if (_loopBackQueue) {
        [_loopBackQueue release];
        _loopBackQueue = nil;
    }
    if (_loopBackTimer) {
        [_loopBackTimer invalidate];
        _loopBackTimer = nil;
    }
    [super dealloc];
}

- (void)sendTransparentData:(NSData *)data {
    NSLog(@"[DataTransparentViewController] sendTransparentData:%@", data);
    CBCharacteristicWriteType type = [connectedPeripheral sendTransparentData:data type:writeType];
    if (type == CBCharacteristicWriteWithoutResponse) {
        //writeAllowFlag = TRUE;
        if (txPath) {
            //[NSTimer scheduledTimerWithTimeInterval:0.0001 target:self selector:@selector(writeFile) userInfo:nil repeats:NO];
        }
    }
    if (writeType != type) {
        [self toggleWriteType];
    }
}

- (void)MyPeripheral:(MyPeripheral *)peripheral didSendTransparentDataStatus:(NSError *)error {
    NSLog(@"[DataTransparentViewController] didSendTransparentDataStatus");
    if (error == nil) {
        writeAllowFlag = TRUE;
        if (txPath) {
            [NSTimer scheduledTimerWithTimeInterval:0.001 target:self selector:@selector(writeFile) userInfo:nil repeats:NO];
        }
    }
    else if (writeType == CBCharacteristicWriteWithResponse){
        
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Transparent data TX error" message:error.domain delegate:self cancelButtonTitle:@"OK" otherButtonTitles: nil];
        [alertView show];
        [alertView release];
        if (txPath) {
            [txPath release];
            txPath = nil;
        }
        if (sendDataTimer) {
            [sendDataTimer invalidate];
            sendDataTimer = nil;
            [self.timerStartButton setTitle: @"Start" forState:UIControlStateNormal];
        }
    }
}

#pragma mark -
#pragma mark Responding to keyboard events
- (void) moveTextViewForKeyboard:(NSNotification*)aNotification up: (BOOL) up{
    NSDictionary* userInfo = [aNotification userInfo];
    
    // Get animation info from userInfo
    NSTimeInterval animationDuration;
    UIViewAnimationCurve animationCurve;
    
    CGRect keyboardEndFrame;
    
    [[userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey] getValue:&animationCurve];
    [[userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] getValue:&animationDuration];
    [[userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] getValue:&keyboardEndFrame];
    
    // Animate up or down
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:animationDuration];
    [UIView setAnimationCurve:animationCurve];
    
    CGRect newFrame = self.view.frame;
    CGRect keyboardFrame = [self.view convertRect:keyboardEndFrame toView:nil];
    
    newFrame.origin.y -= (keyboardFrame.size.height-100) * (up? 1 : -1);
    self.view.frame = newFrame;
    
    [UIView commitAnimations];
}

- (void)keyboardWillShow:(NSNotification *)notification {
    int segmentIndex = [self.segmentedControl selectedSegmentIndex];
    if (segmentIndex != CBTimerMode) {
        [self moveTextViewForKeyboard:notification up:YES];
    }
	[self.webView stringByEvaluatingJavaScriptFromString:@"window.scrollTo(document.body.scrollWidth, document.body.scrollHeight);"];
}
- (void)keyboardWillHide:(NSNotification *)notification {
    int segmentIndex = [self.segmentedControl selectedSegmentIndex];
    if (segmentIndex != CBTimerMode) {
        [self moveTextViewForKeyboard:notification up:NO];
    }
	[self.webView stringByEvaluatingJavaScriptFromString:@"window.scrollTo(document.body.scrollWidth, document.body.scrollHeight);"];
}


- (void)webViewDidFinishLoad:(UIWebView *)aWebView {
    NSLog(@"[DataTransparentViewController] webViewDidFinishLoad");
    [self.webView stringByEvaluatingJavaScriptFromString:@"window.scrollTo(document.body.scrollWidth, document.body.scrollHeight);"];
    webFinishLoad = TRUE;
}

- (void)reloadOutputView {
    if (webFinishLoad) {
        NSLog(@"[DataTransparentViewController] reloadOutputView");
        webFinishLoad = FALSE;
        NSString *tmp = [[NSString alloc] initWithFormat:@"<html><body>%@</body></html>", content];
        // NSLog(@"html = %@", tmp);
        [self.webView loadHTMLString:tmp baseURL:nil];
        [tmp release];
    }
    
	// TODO implement scrollsToBottomAnimated
}

// <--- UITextFieldDelegate
- (BOOL)textViewShouldBeginEditing:(UITextView *)textView {
    [UIView beginAnimations:@"ResizeForKeyboard" context:nil];
    [UIView setAnimationDuration:0.3f];
    float width=self.view.frame.size.width;
    float height=self.view.frame.size.height;
    CGRect rect=CGRectMake(0.0f,-80*(textView.tag),width,height);//上移80个单位，一般也够用了
    self.view.frame=rect;
    [UIView commitAnimations];
    return YES;
}

- (BOOL) textFieldDidBeginEditing: (UITextField *)textField
{
    NSLog(@"[DataTransparentViewController] textFieldDidBeginEditing LE");
    editingTextField = textField;
    self.navigationItem.rightBarButtonItem = cancelButton;
    
    return YES;
}
- (BOOL) textFieldDidEndEditing: (UITextField *)textField
{
    NSLog(@"[DataTransparentViewController] textFieldDidEndEditing LE");

    return YES;
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    NSLog(@"[DataTransparentViewController] shouldChangeCharactersInRange LE");
    if (textField != self.inputTextField) {
        
        NSCharacterSet *unacceptedInput = [[NSCharacterSet characterSetWithCharactersInString:@"1234567890"] invertedSet];
		if ([[string componentsSeparatedByCharactersInSet:unacceptedInput] count] > 1)
			return NO;
		else
			return YES;
    }
    else {
        /*if ([self.inputTextField.text length] > 20) {
            return NO;
        }*/
    }
	return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    self.navigationItem.rightBarButtonItem = nil;
    NSLog(@"[DataTransparentViewController] textFieldShouldReturn LE");
    if (textField == self.inputTextField) {
        self.inputTextField.placeholder = @"";
        [self sendData];
        self.inputTextField.text = @"";
    }
	return YES;
}
// UITextFieldDelegate --->

- (void)sendData {
    NSLog(@"[DataTransparentViewController] sendData");
    if (![connectedPeripheral.transmit canSendReliableBurstTransmit]) {
        return;
    }
    if ([[self.inputTextField text] length]) {
        [self sendTransparentData:[[self.inputTextField text] dataUsingEncoding:NSUTF8StringEncoding]];
        [content appendFormat:@"<span>%@</span><br>", self.inputTextField.text];
        [self reloadOutputView];
    }
}

- (void) groupComponentsDisplay {
    BOOL bRawModeGroup = false, bTimerModeGroup = false;

    if ([self.segmentedControl selectedSegmentIndex] == CBTimerMode) {
        bTimerModeGroup = false;
        bRawModeGroup = true;
    }
    else {
        bTimerModeGroup = true;
        bRawModeGroup = false;
    }
    
    self.webView.hidden = bRawModeGroup;
    self.inputTextField.hidden = bRawModeGroup;
    
    self.timerPatternSizeLabel.hidden = bTimerModeGroup;
    self.timerPatternSizeTextField.hidden = bTimerModeGroup;
    self.timerRepeatTimesLabel.hidden = bTimerModeGroup;
    self.timerRepeatTimesTextField.hidden = bTimerModeGroup;
    self.timerDeltaTimeLabel.hidden = bTimerModeGroup;
    self.timerDeltaTimeTextField.hidden = bTimerModeGroup;
    self.timerStartButton.hidden = bTimerModeGroup;
    
}

- (void)clearLoopBackQueue {
    [_loopBackTimer invalidate];
    _loopBackTimer = nil;
    [_loopBackQueue removeAllObjects];
}

- (IBAction)segmentModeSwitch:(id)sender {
    if (txPath) {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Transmitting a file" message:nil delegate:self cancelButtonTitle:@"Close" otherButtonTitles: nil];
        [alertView show];
        [alertView release];
        [self.segmentedControl setSelectedSegmentIndex:CBRawMode];
        return;
    }
    [self groupComponentsDisplay];
    int segmentIndex = [self.segmentedControl selectedSegmentIndex];

    if (segmentIndex == CBRawMode) {
        self.timerLabel.text = @"";
        [self reloadOutputView];
        NSArray *toolbarItems = [[NSArray alloc] initWithObjects:compareButton, txFileButton, writeTypeButton, clearButton, nil];
        [self setToolbarItems:toolbarItems animated:TRUE];
        [toolbarItems release];
    }
    else if (segmentIndex == CBLoopBackMode) {
        NSArray *toolbarItems = [[NSArray alloc] initWithObjects: writeTypeButton,clearButton, nil];
        [self setToolbarItems:toolbarItems animated:TRUE];
        [toolbarItems release];
    }
    else if (segmentIndex == CBTimerMode) {
        NSArray *toolbarItems = [[NSArray alloc] initWithObjects:writeTypeButton, nil];
        [self setToolbarItems:toolbarItems animated:TRUE];
        [toolbarItems release];
        
    }
    if ([_loopBackQueue count]) {
        [self clearLoopBackQueue];
    }
    
    if (sendDataTimer)
    {
        [self.timerStartButton setTitle: @"Start" forState:UIControlStateNormal];
        [sendDataTimer invalidate];
        sendDataTimer = nil;
    }
}

- (void) SendTestPattern {
      NSLog(@"[DataTransparentViewController] Send test pattern");
    if (![connectedPeripheral.transmit canSendReliableBurstTransmit]) {
        return;
    }

//    timeUpFlag = TRUE;
    if (writeAllowFlag == FALSE) {
        return;
    }
    writeAllowFlag = FALSE;
    //NSLog(@"Send test pattern2");
    NSString *tmp;
    timerCount++;
    
    if (pattern_times == 0) {
        tmp = [[NSString alloc] initWithFormat:@"Timer = %.3fs, Len = %d, times = unlimited, Count = %d",timer_second,pattern_length, timerCount];
    }
    else {
        tmp = [[NSString alloc] initWithFormat:@"Timer = %.3fs, Len = %d, times = %d, Count = %d",timer_second,pattern_length, pattern_times,timerCount];
        if (timerCount >= pattern_times) {
            [sendDataTimer invalidate];
            sendDataTimer = nil;
            [self.timerStartButton setTitle: @"Start" forState:UIControlStateNormal];
            NSLog(@"timer stop");
        }
    }
    NSLog(@"times = %d, counter = %d", pattern_times, timerCount);
    self.timerLabel.text = tmp;
    [tmp release];
    NSMutableString *pattern_str = [[NSMutableString alloc] initWithCapacity:pattern_length+10];
    for (int i=0; i<pattern_length-1; i++) {
        [pattern_str appendFormat:@"%d",timerCount%10];
    }
    [pattern_str appendFormat:@"\n"];
    [self sendTransparentData:[pattern_str dataUsingEncoding:NSMacOSRomanStringEncoding]];
    [pattern_str release];
////////////////
 /*   NSString *path = [[NSString alloc] initWithFormat:@"%@/%@.app/10k.txt",NSHomeDirectory(), [[[NSBundle mainBundle] infoDictionary]   objectForKey:@"CFBundleName"]];
    NSFileHandle *fileHandleRead = [NSFileHandle fileHandleForReadingAtPath:path];
    [path release];
    if (fileHandleRead == nil) {
        NSLog(@"[SendTestPattern], open file fail");
    //    NSMutableString *pattern_str = [[NSMutableString alloc] initWithCapacity:pattern_length+10];
    //    for (int i=0; i<pattern_length-1; i++) {
    //        [pattern_str appendFormat:@"%d",timerCount%10];
    //    }
    //    [pattern_str appendFormat:@"\n"];
    //    [self sendTransparentData:[pattern_str dataUsingEncoding:NSMacOSRomanStringEncoding]];
    //    [pattern_str release];
    }
    else {
        NSMutableData *data = [NSMutableData alloc];
        [fileHandleRead seekToFileOffset:fileReadOffset];
        [data setData: [fileHandleRead readDataOfLength:pattern_length]];
        
        if ([data length] < pattern_length) {
            
            fileReadOffset = pattern_length - [data length];
            [fileHandleRead seekToFileOffset:0];
            [data appendData:[fileHandleRead readDataOfLength:fileReadOffset]];
        }
        else {
            fileReadOffset += pattern_length;
            
        }
        NSLog(@"offset = %ld",fileReadOffset);
        [self sendTransparentData:data];
    }
    */
///////////////
    
}

- (IBAction)timerButtonAction:(id)sender {
    if (sendDataTimer) {
        [sendDataTimer invalidate];
        sendDataTimer = nil;
        [self.timerStartButton setTitle: @"Start" forState:UIControlStateNormal];
        return;
    }
    [editingTextField resignFirstResponder];
    float miliSecond = [self.timerDeltaTimeTextField.text integerValue];
    if (miliSecond != 0) {
        timer_second = (miliSecond/1000);
    }
    else {
        [self.timerDeltaTimeTextField becomeFirstResponder];
        return;
    }
    pattern_length = [self.timerPatternSizeTextField.text integerValue];
    if (pattern_length == 0) {
        [self.timerPatternSizeTextField becomeFirstResponder];
        return;
    }
    pattern_times = [self.timerRepeatTimesTextField.text integerValue];
    
    NSString *tmp;
    if (pattern_times == 0) {
        tmp = [[NSString alloc] initWithFormat:@"Timer = %.3fs, Len = %d, times = unlimited",timer_second,pattern_length];
    }
    else {
        tmp = [[NSString alloc] initWithFormat:@"Timer = %.3fs, Len = %d, times = %d",timer_second,pattern_length,pattern_times];
    }
    self.timerLabel.text = tmp;
    [tmp release];
    [self.timerStartButton setTitle: @"Stop" forState:UIControlStateNormal];
    timerCount = 0;

    writeAllowFlag = TRUE;
    sendDataTimer = [NSTimer scheduledTimerWithTimeInterval:timer_second target:self selector:@selector(SendTestPattern) userInfo:nil repeats:YES];
    
}

- (void)sendLoopBackData {
    static BOOL entry = FALSE;
    if (![connectedPeripheral.transmit canSendReliableBurstTransmit]) {
        return;
    }
    else if (entry) {
        return;
    }
    else {
        entry = TRUE;
        if ([_loopBackQueue count]>0) {
            
            NSData *data = [_loopBackQueue objectAtIndex:0];
            [self sendTransparentData:data];
            [_loopBackQueue removeObjectAtIndex:0];
            if ([_loopBackQueue count] == 0) {
                [_loopBackTimer invalidate];
                _loopBackTimer = nil;
            }
        }
    }
    entry = FALSE;
}

- (void)MyPeripheral:(MyPeripheral *)peripheral didReceiveTransparentData:(NSData *)data {
    NSLog(@"[DataTransparentViewController] didReceiveTransparentData");
    if ([data length] > 0) {
        int segmentIndex = [self.segmentedControl selectedSegmentIndex];
        
        NSMutableString *str = [[NSMutableString alloc] initWithData:data encoding:NSASCIIStringEncoding];
        [str replaceOccurrencesOfString:@"\n" withString:@"<br>" options:NSLiteralSearch range:NSMakeRange(0, [str length])];
        [content appendFormat:@"<span style=\"color:red\">%@</span><br>", str];
        if (segmentIndex == CBLoopBackMode) {
            [content appendFormat:@"<span>%@</span><br>",str];
            if (!_loopBackQueue) {
                _loopBackQueue = [[NSMutableArray alloc] initWithCapacity:1000];
            }
            if (![connectedPeripheral.transmit canSendReliableBurstTransmit]) {
                if ([_loopBackQueue count]==1000) {
                    [_loopBackQueue removeObjectAtIndex:0];
                }
                [_loopBackQueue addObject:data];
                if (!_loopBackTimer) {
                    _loopBackTimer = [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(sendLoopBackData) userInfo:nil repeats:YES];
                }
            }
            else {
                if (_loopBackQueue && [_loopBackQueue count]>0) {
                    if ([_loopBackQueue count]==1000) {
                        [_loopBackQueue removeObjectAtIndex:0];
                    }
                    [_loopBackQueue addObject:data];
                }
                else {
                    [self sendTransparentData:data];
                }
            }
        }

        if (checkRxDataTimer == nil) {
            checkRxDataTimer = [NSTimer scheduledTimerWithTimeInterval:CHECK_RX_TIMER target:self selector:@selector(checkRxData) userInfo:nil repeats:YES];
            rxDataTime.trail_time = 0;
            rxDataTime.transmit_time = 0;
            rxDataTime.sinceDate = [[NSDate date] retain];
            lastReceivedByteCount = 0;
            
            receivedByteCount = 0;
        }
        
        if (receivedDataPath == nil) {
            receivedDataPath = [[NSString alloc] initWithFormat:@"%@/Documents/%f.txt",NSHomeDirectory(), [rxDataTime.sinceDate timeIntervalSince1970]];
            if (![fileManager createFileAtPath:receivedDataPath contents:nil attributes:nil]) {
                NSLog(@"Create file fail");
                UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Create file fail!"  message:@"Create file fail! Cant save recevied file." delegate:self cancelButtonTitle:@"OK" otherButtonTitles: nil];
                [alertView show];
                [alertView release];
            }
            else
                NSLog(@"create file %@", receivedDataPath);
        }

        NSFileHandle *fileHandleWrite = [NSFileHandle fileHandleForWritingAtPath:receivedDataPath];
        if (fileHandleWrite == nil) {
            NSLog(@"open file fail");
        }
        rxDataTime.transmit_time = [[NSDate date] timeIntervalSinceDate:rxDataTime.sinceDate];
        receivedByteCount += [data length];
        [fileHandleWrite seekToEndOfFile];
        [fileHandleWrite writeData:data];
        [fileHandleWrite closeFile];
        if ([content length] > 5000) {
            NSRange range = {2500,1000};
            range = [content rangeOfString:@"<span style=" options:NSLiteralSearch range:range];
            if (range.location != NSNotFound) {
                range.length = range.location;
                range.location = 0;
                [content deleteCharactersInRange:range];
            }
            
        }
    }
}

- (void)saveReceivedData {
    
}

- (void)selectCompareFile {
    ISSCTableAlertView  *alert = [[[ISSCTableAlertView alloc] initWithCaller:self data:dirArray title:@"Select a file to compare" buttonTitle:@"Don't compare" andContext:@"Compare"] autorelease];
    [alert show];
}

- (void)selectTxFile {
    ISSCTableAlertView  *alert = [[[ISSCTableAlertView alloc] initWithCaller:self data:dirArray title:@"Tx File" buttonTitle:@"Cancel" andContext:@"TxFile"] autorelease];
    [alert show];
}

- (void)toggleWriteType {
    if (writeType == CBCharacteristicWriteWithResponse) {
        writeType = CBCharacteristicWriteWithoutResponse;
        [self.writeTypeLabel setText:@"Write with ReliableBurstTransmit"];
    }
    else {
        writeType = CBCharacteristicWriteWithResponse;
        [self.writeTypeLabel setText:@"Write with Response"];
    }
    
}

- (void)clearWebView {
    NSString *htmlBody = @"<html><body></body></html>";
	NSRange range;
    range.location = 0;
    range.length = [content length];
    [content deleteCharactersInRange:range];
	[self.webView loadHTMLString:htmlBody baseURL:nil];
    //[fileManager removeItemAtPath:receivedDataPath error:NULL];
    if ([_loopBackQueue count]) {
        [self clearLoopBackQueue];
    }
}

-(void)didSelectRowAtIndex:(NSInteger)row withContext:(id)context{
    NSString *tmp = (NSString *)context;
    if ([tmp isEqualToString:@"Compare"]) {
        NSLog(@"DataTransparentViewController] didSelectRowAtIndex Compare");
        if(row >= 0){
            comparedPath = [[NSString stringWithFormat:@"%@/%@",[[NSBundle mainBundle] resourcePath],[dirArray objectAtIndex:row]] retain];
            //comparedPath = [[NSString alloc] initWithFormat:@"%@/%@.app/%@",NSHomeDirectory(), [[[NSBundle mainBundle] infoDictionary]   objectForKey:@"CFBundleName"], [dirArray objectAtIndex:row]];
            NSLog(@"Did select %@", comparedPath);
        }
        else{
            NSLog(@"Selection cancelled");
            if (comparedPath) {
                [comparedPath release];
                comparedPath = nil;
            }
        }
    }
    else {
        if (row >= 0) {
            txPath = [[NSString stringWithFormat:@"%@/%@",[[NSBundle mainBundle] resourcePath],[dirArray objectAtIndex:row]] retain];
            //txPath = [[NSString alloc] initWithFormat:@"%@/%@.app/%@",NSHomeDirectory(), [[[NSBundle mainBundle] infoDictionary]   objectForKey:@"CFBundleName"], [dirArray objectAtIndex:row]];
            fileReadOffset = 0;
            writeAllowFlag = TRUE;
            [self writeFile];
            self.navigationItem.rightBarButtonItem = cancelButton;
        }
        else{
            NSLog(@"Selection cancelled");
            if (txPath) {
                [txPath release];
                txPath = nil;
            }
        }
        
    }
}

- (void)cancelEditing {
    [editingTextField resignFirstResponder];
    if (txPath) {
        [txPath release];
        txPath = nil;
    }
    self.navigationItem.rightBarButtonItem = nil;
}

-(void) writeFile {
    //  NSLog(@"DataTransparentViewController] writeFile");
    if (!txPath)
        return;
    if (![connectedPeripheral.transmit canSendReliableBurstTransmit]) {
        return;
    }
    NSFileHandle *fileHandleRead = [NSFileHandle fileHandleForReadingAtPath:txPath];
    if (fileHandleRead == nil) {
        NSLog(@"open file fail");
    }
    NSMutableData *data = [NSMutableData alloc];
    [fileHandleRead seekToFileOffset:fileReadOffset];
    [data setData: [fileHandleRead readDataOfLength:[connectedPeripheral.transmit transmitSize]]];
    
    
    if ([data length]) {
        fileReadOffset += [data length];
        NSLog(@"offset = %ld",fileReadOffset);
        [self sendTransparentData:data];
        [self.statusLabel setText:[[NSString alloc] initWithFormat:@"Writing file, Tx bytes = %ld", fileReadOffset]];
    }
    else {
        fileReadOffset = 0;
        NSString *str = [[NSString alloc] initWithFormat:@"file = %@",txPath];
        [txPath release];
        txPath = nil;
        self.navigationItem.rightBarButtonItem = nil;
        NSLog(@"tx complete");
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Tx File Complete" message:str delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alertView show];
        [str release];
        [alertView release];
    }
    [data release];
    [fileHandleRead closeFile];
}

- (void)checkRxData
{
    rxDataTime.trail_time++;
    static short refreshOutputViewCount = 0;
    refreshOutputViewCount++;

    if (lastReceivedByteCount < receivedByteCount) {//check if new incoming data
        rxDataTime.trail_time = 0;
        lastReceivedByteCount = receivedByteCount;
        NSLog(@"current time = %f", (rxDataTime.transmit_time));
        
        NSString *tmp = [[NSString alloc] initWithFormat:@"Rx bytes = %d, time = %f",receivedByteCount, rxDataTime.transmit_time];
        self.statusLabel.text = tmp;
        [tmp release];
        if (refreshOutputViewCount > 10) {
            refreshOutputViewCount = 0;
            [self reloadOutputView];
        }
    }
    else if ((refreshOutputViewCount > rxDataTime.trail_time) && (refreshOutputViewCount > 10)){
        refreshOutputViewCount = 0;
        [self reloadOutputView];
    }
    else if (rxDataTime.trail_time >=50) {//no new incoming data over 5 seconds
        NSLog(@"rxDataTime.trail_time >=50..1");
        [checkRxDataTimer invalidate]; //remove timer
        checkRxDataTimer = nil;
        BOOL bResult = TRUE;
        refreshOutputViewCount = 0;
        if (comparedPath && [comparedPath length] != 0 && receivedDataPath) {
            NSLog(@"compare...");
            bResult = [fileManager contentsEqualAtPath:comparedPath andPath:receivedDataPath];
            
            NSString *tmp = [[NSString alloc] initWithFormat:@"Rx bytes = %d,  time = %.3fs,  compare %@",receivedByteCount, rxDataTime.transmit_time, bResult ?@"Pass":@"Fail"];
            self.statusLabel.text = tmp;
            [tmp release];
            if (bResult == false) {

                UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Compare Fail"  message:[NSString stringWithFormat:@"Please check /Documents/%@.txt", [rxDataTime.sinceDate description]]  delegate:self cancelButtonTitle:@"OK" otherButtonTitles: nil];
                [alertView show];
                [alertView release];
            }
            [rxDataTime.sinceDate release];
        }
        if (receivedDataPath) {
            if(bResult)
                [fileManager removeItemAtPath:receivedDataPath error:NULL];
            [receivedDataPath release];
            receivedDataPath = nil;
        }
        NSLog(@"rxDataTime.trail_time >=50..2");
    }
}
- (void)viewDidUnload {
    [self setWriteTypeLabel:nil];
    [super viewDidUnload];
}

- (void)MyPeripheral:(MyPeripheral *)peripheral didUpdateTransDataNotifyStatus:(BOOL)notify{
    NSLog(@"DataTransparentViewController] didUpdateTransDataNotifyStatus = %@",notify==true?@"true":@"false");
}

- (void)MyPeripheral:(MyPeripheral *)peripheral didUpdateHardwareRevision:(NSString *)hardwareRevision error:(NSError *)error {
    if (!error) {
        NSLog(@"Hardware = %@",hardwareRevision);
        _hardwareRevision = [hardwareRevision retain];
        if ([hardwareRevision hasPrefix:[NSString stringFromHexString:BM77SPP_HW]]) {
            //BM77SPP
            [connectedPeripheral readFirmwareRevision];
        }
        else if ([hardwareRevision hasPrefix:[NSString stringFromHexString:BLETR_HW]]) {
            //BLETR
            [connectedPeripheral readFirmwareRevision];
        }
        else {
            isPatch = YES;
            [connectedPeripheral setTransDataNotification:TRUE];
        }
    }

}

- (void)MyPeripheral:(MyPeripheral *)peripheral didUpdateFirmwareRevision:(NSString *)firmwareRevision error:(NSError *)error {
    if (!error) {
        NSLog(@"firmwareRevision = %@",firmwareRevision);
        _firmwareRevision = [firmwareRevision retain];
        if ([firmwareRevision hasPrefix:[NSString stringFromHexString:BM77SPP_FW]]) {
            //BM77SPP
            [connectedPeripheral readMemoryValue:BM77SPP_AD length:2];
        }
        else if ([firmwareRevision hasPrefix:[NSString stringFromHexString:BLETR_FW]]) {
            //BLETR
            [connectedPeripheral readMemoryValue:BLETR_AD length:2];
        }
        else {
            isPatch = YES;
            [connectedPeripheral setTransDataNotification:TRUE];
        }
    }

}

- (void)MyPeripheral:(MyPeripheral *)peripheral didReceiveMemoryAddress:(NSData *)address length:(short)length data:(NSData *)data {
    NSLog(@"%@ = %@",address,data);
    _writeTypeLabel.text = [NSString stringWithFormat:@"Address %@ = %@",address,data];
    unsigned short int add;
    [address getBytes:&add length:2];
    add = NSSwapBigShortToHost(add);
    unsigned short int d;
    [data getBytes:&d length:length];
    d = NSSwapBigShortToHost(d);
    if ([_hardwareRevision hasPrefix:[NSString stringFromHexString:BM77SPP_HW]] && [_firmwareRevision hasPrefix:[NSString stringFromHexString:BM77SPP_FW]] && add == BM77SPP_AD) {
        if (d != 0x0017) {
            char w[2];
            w[0] = 0x00;
            w[1] = 0x17;
            [connectedPeripheral writeMemoryValue:BM77SPP_AD length:2 data:w];
        }
        else {
            isPatch = YES;
            [connectedPeripheral setTransDataNotification:TRUE];
        }
    }
    else if ([_hardwareRevision hasPrefix:[NSString stringFromHexString:BLETR_HW]] && [_firmwareRevision hasPrefix:[NSString stringFromHexString:BLETR_FW]] && add == BLETR_AD) {
        if (d != 0x17) {
            char w[2];
            w[0] = 0x00;
            w[1] = 0x17;
            [connectedPeripheral writeMemoryValue:BLETR_AD length:2 data:w];
        }
        else {
            isPatch = YES;
            [connectedPeripheral setTransDataNotification:TRUE];
        }
    }
}

- (void)MyPeripheral:(MyPeripheral *)peripheral didWriteMemoryAddress:(NSError *)error {
    if (!error) {
        isPatch = YES;
        [connectedPeripheral setTransDataNotification:TRUE];
    }
}

- (void)reliableBurstData:(ReliableBurstData *)reliableBurstData didSendDataWithCharacteristic:(CBCharacteristic *)transparentDataWriteChar {
    NSLog(@"reliableBurstData:didSendDataWithCharacteristic:");
    writeAllowFlag = TRUE;
    int segmentIndex = [self.segmentedControl selectedSegmentIndex];
    if (segmentIndex == CBLoopBackMode) {
        [self sendLoopBackData];
    }
    else if (txPath) {
        [self writeFile];
    }
}

@end
