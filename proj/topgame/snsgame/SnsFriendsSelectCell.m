//
//  SnsFriendsSelectCell.m
//  Pet Home
//
//  Created by yangjie on 4/29/12.
//  Copyright (c) 2012 topgame.com. All rights reserved.
//

#import "SnsFriendsSelectCell.h"

@interface SnsFriendsSelectCell ()

@end

@implementation SnsFriendsSelectCell
@synthesize name;
@synthesize email;

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}


- (void)dealloc
{
	self.name = nil;
	self.email = nil;
	[super dealloc];
}

@end
