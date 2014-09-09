//
//  SnsFriendsSelectViewController.h
//  Pet Home
//
//  Created by yangjie on 4/29/12.
//  Copyright (c) 2012 topgame.com. All rights reserved.
//

#import <UIKit/UIKit.h>
// #import "SmDialogBaseController.h"

@interface SnsFriendsSelectViewController : UIViewController// SmDialogBaseController
{
@private
	NSMutableArray *			m_finallyEmailList;
}

@property (nonatomic, retain) NSMutableArray *finallyEmailList;
@property (nonatomic, retain) NSMutableArray *items;
@property (nonatomic, retain) IBOutlet UITableView *friendTableView;
@property (nonatomic, retain) IBOutlet UIBarButtonItem *cancelButton;
@property (nonatomic, retain) IBOutlet UIBarButtonItem *sendButton;

@property (nonatomic, assign) int emailType;

- (IBAction)closeAndSend:(id)sender;
- (IBAction)closeDialog:(id)sender;
- (void) showHard;
- (void) cleanUp;
@end
