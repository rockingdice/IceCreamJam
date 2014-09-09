//
//  SnsFriendsSelectViewController.m
//  Pet Home
//
//  Created by yangjie on 4/29/12.
//  Copyright (c) 2012 topgame.com. All rights reserved.
//

#import "SnsFriendsSelectViewController.h"
#import "SnsFriendsSelectCell.h"
#import "TinyiMailHelper.h"
#import "SystemUtils.h"

@implementation SnsFriendsSelectViewController
@synthesize finallyEmailList = m_finallyEmailList;
@synthesize items;
@synthesize friendTableView;
@synthesize emailType; // 1-invite email, 2-gift email
@synthesize cancelButton, sendButton;


- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (id)init
{
	if ((self = [super init])) {
		self.finallyEmailList = [NSMutableArray arrayWithCapacity:20];
	}
	return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
	[self.friendTableView setEditing:YES];
	// 设置两个按钮的文字
	[self.cancelButton setTitle:[SystemUtils getLocalizedString:@"Cancel"]];
	[self.sendButton setTitle:[SystemUtils getLocalizedString:@"Send"]];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
	self.friendTableView = nil;
	self.cancelButton = nil;
	self.sendButton = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    /*
    // return (interfaceOrientation == UIInterfaceOrientationPortrait);
    UIDeviceOrientation orie = [SystemUtils getGameOrientation];
    if(UIDeviceOrientationIsPortrait(orie)) 
        return UIInterfaceOrientationIsPortrait(interfaceOrientation);
    if(UIDeviceOrientationIsLandscape(orie))
        return UIInterfaceOrientationIsLandscape(interfaceOrientation);
    return NO;
     */
    return YES;
}

- (void)dealloc
{
	self.finallyEmailList = nil;
	self.items = nil;
	self.friendTableView = nil;
	self.cancelButton = nil;
	self.sendButton = nil;
	[super dealloc];
}

- (void) cleanUp
{
    [self release];
}

/*
- (void) willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    //if(self.view.superview)
    //    self.view.frame = self.view.superview.frame;
}
*/

#pragma mark - tableView delegate & datasource

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return UITableViewCellEditingStyleDelete | UITableViewCellEditingStyleInsert;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [items count];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 64;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSUInteger row = [indexPath row];
	NSUInteger allCount = [items count];
	static NSString *CellIdentifier = @"kSnsFriendsSelectCellIdentifier";
	SnsFriendsSelectCell *cell = (SnsFriendsSelectCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
	if (cell == nil) {
		NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"SnsFriendsSelectCell" owner:self options:nil];
		for (id oneObject in nib) {
			if ([oneObject isKindOfClass:[SnsFriendsSelectCell class]]) {
				cell = (SnsFriendsSelectCell *)oneObject;
			}
		}
	}
	if (allCount > 0 && row < allCount) {
		NSDictionary *friend = [items objectAtIndex:row];
		NSString *name = [friend objectForKey:@"name"];
		NSString *email = [friend objectForKey:@"email"];
        /*
		if ([friend isKindOfClass:[NSDictionary class]]) {
			name = [friend objectForKey:@"name"];
            if([name rangeOfString:@"\""].location != NSNotFound) {
                name = [name stringByReplacingOccurrencesOfString:@"\"" withString:@"'"];
            }
            email = [NSString stringWithFormat:@"\"%@\" <%@>", name, [friend objectForKey:@"email"]];
		}
         */
		cell.name.text = name;
		cell.email.text = email;
	}
	//cell.selectionStyle = UITableViewCellSelectionStyleNone;
	return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{ 
    NSUInteger row = [indexPath row];
	NSDictionary *friend = [items objectAtIndex:row];
	if ([friend isKindOfClass:[NSDictionary class]]) {
		// NSString *email = [friend objectForKey:@"email"];
		if (![m_finallyEmailList containsObject:friend]) {
			[m_finallyEmailList addObject:friend];
		}
	}
	smLog(@"email:%@", [m_finallyEmailList description]);
} 

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath
{ 
	NSUInteger row = [indexPath row];
	NSDictionary *friend = [items objectAtIndex:row];
	if ([friend isKindOfClass:[NSDictionary class]]) {
		// NSString *email = [friend objectForKey:@"email"];
		if ([m_finallyEmailList containsObject:friend]) {
			[m_finallyEmailList removeObject:friend];
		}
	}
	smLog(@"email:%@", [m_finallyEmailList description]);
}

#pragma mark - IBAction function

- (IBAction)closeAndSend:(id)sender
{
    [SystemUtils closePopupView:self];
    // generate email list
    NSMutableArray *emails = [NSMutableArray arrayWithCapacity:[m_finallyEmailList count]];
    for(int i=0;i<[m_finallyEmailList count];i++)
    {
        NSDictionary *f = [m_finallyEmailList objectAtIndex:i];
        NSString *name = [f objectForKey:@"name"];
        if([name rangeOfString:@"\""].location != NSNotFound) {
            name = [name stringByReplacingOccurrencesOfString:@"\"" withString:@"'"];
        }
        NSString *email = [NSString stringWithFormat:@"\"%@\" <%@>", name, [f objectForKey:@"email"]];
        [emails addObject:email];
        
    }
    if(emailType==2)
        [[TinyiMailHelper helper] sendGiftEmail:emails];
    else 
        [[TinyiMailHelper helper] sendInvitationEmail:emails];
	// [self closeDialog];
    [self cleanUp];
}

- (IBAction)closeDialog:(id)sender
{
    // [self.view removeFromSuperview];
    [SystemUtils closePopupView:self];
    [self cleanUp];
}

- (void) showHard
{
    [SystemUtils showPopupView:self];
    [self retain];
}

@end
