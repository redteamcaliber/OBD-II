//
//  TableAlertView.h
//  BLEDKAPP
//
//  Created by d500_MacMini on 12/9/28.
//  Copyright (c) 2012 ISSC Technologies Corporation. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol TableAlertViewDelegate
-(void) didSelectRowAtIndex: (NSInteger)row withContext:(id)context;
@end

@interface TableAlertView : UIAlertView < UITableViewDelegate, UITableViewDataSource>{
    UITableView                *myTableView;
    id<TableAlertViewDelegate> caller;
    id                         context;
    NSArray                    *data;
    NSUInteger                 tableHeight;
}

-(id)initWithCaller:(id<TableAlertViewDelegate>)_caller data:(NSArray*)_data
              title:(NSString*)_title buttonTitle:(NSString *) _buttonTitle andContext:(id)_context;
@property(nonatomic, retain) id<TableAlertViewDelegate> caller;
@property(nonatomic, retain) id context;
@property(nonatomic, retain) NSArray *data;
@end

@interface TableAlertView(HIDDEN)
-(void)prepare;
@end
