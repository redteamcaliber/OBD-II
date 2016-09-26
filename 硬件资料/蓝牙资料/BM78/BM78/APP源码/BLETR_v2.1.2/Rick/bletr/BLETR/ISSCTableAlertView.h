//
//  ISSCTableAlertView.h
//  MFiAudioAPP
//
//  Created by Rick on 13/10/4.
//  Copyright (c) 2013年 ISSC. All rights reserved.
//

#import <Foundation/Foundation.h>
@protocol TableAlertViewDelegate<NSObject>
-(void) didSelectRowAtIndex: (NSInteger)row withContext:(id)context;
@end

@interface ISSCTableAlertView : NSObject
-(id)initWithCaller:(id<TableAlertViewDelegate>)caller data:(NSArray*)data
              title:(NSString*)title buttonTitle:(NSString *)buttonTitle andContext:(id)context;
-(void)show;
- (void)dismissWithClickedButtonIndex:(NSInteger)buttonIndex animated:(BOOL)animated;

@property(nonatomic, retain) id<TableAlertViewDelegate> caller;
@property(nonatomic, retain) id context;
@property(nonatomic, retain) NSArray *data;
@property(nonatomic, retain) UITableView *myTableView;

@end
