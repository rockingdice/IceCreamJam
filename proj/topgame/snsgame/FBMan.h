//
//  FBMan.h
//  ZombieFarm
//
//  Created by Vicente McDonnell on 11/7/09.
//  Copyright 2009 The Playforge LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Facebook.h"
#import "FriendList.h"
#import "Reachability.h"
#import "PermissionTracker.h"

typedef enum {
	kDialogTagDefault = 0,
	kDialogTagLevel
}FBDialogTags;

CGImageRef UIGetScreenImage();

@interface FBMan : UIViewController <FriendListDelegate, FBDialogDelegate, FBSessionDelegate, FBRequestDelegate, PermissionTrackerDelegate>
{
	Facebook *facebookInterface;
	NSMutableArray* sessionDelegates;
	FriendList *friendListForUserAppUser;
	Reachability* hostReach;
	NSArray* friends;
	NSArray* appUserFriends;
	NSString *playerName;
	NSString *playerFullName;
	NSString *playerEmail;
	NSString *playerBio;
	UIImage *playerImage;
	NSString* playerID;
	BOOL permissionStatus;
	BOOL permissionPhoto;
	BOOL connectedToInternet;
	BOOL useFaceBook;
	NSMutableArray* permissionTrackers;
}

@property (nonatomic, retain) Facebook *facebookInterface;
@property (nonatomic,readonly) NSMutableArray* sessionDelegates;
@property (nonatomic, copy) NSString* playerName;
@property (nonatomic, copy) NSString* playerFullName;
@property (nonatomic, copy) NSString* playerEmail;
@property (nonatomic, copy) NSString* playerBio;
@property (nonatomic, retain) UIImage *playerImage;
@property (nonatomic, copy) NSString* playerID;
@property (nonatomic, assign) int playerGender;
@property (nonatomic, retain) NSArray* friends;
@property (nonatomic, retain) NSArray* appUserFriends;
@property (nonatomic, retain) Reachability* hostReach;
@property BOOL permissionStatus;
@property BOOL permissionPhoto;
@property BOOL connectedToInternet;
@property BOOL useFaceBook;
@property (nonatomic, retain) NSMutableArray* permissionTrackers;


- (void)publishFeed:(NSString*)name withCaption:(NSString*)caption withDescription:(NSString*)description withImageURl:(NSString*)imageUrl withDelegate:(id<FBDialogDelegate>)delegate;

- (void)startFBConnectPrompt;
- (BOOL)internetConnectivity;
- (void)publishPhoto:(UIImage *)image withCaption:(NSString *)caption withDelegate:(id <FBRequestDelegate>)delegate;
// feed照片成功之后的回调函数
- (void)feedPhotoSuccess;
- (void)askPermissionForPhotoUpload;
- (BOOL)checkUseFaceBook;
//- (void)show;

- (void)addSessionDelegate:(id<FBSessionDelegate>)delegate;
- (void)removeSessionDelegate:(id<FBSessionDelegate>)delegate;

- (void)requestPermission:(NSString*)permissionName;

// Some pass thru functions for the Facebook interface
- (BOOL)isSessionValid;
- (void)login:(NSArray*)permissions;
- (void)logout;
- (void)resume;
- (BOOL)useFaceBook;
- (BOOL)handleOpenURL:(NSURL *)url;
- (FBRequest*)requestWithMethodName:(NSString *)methodName
                          andParams:(NSMutableDictionary *)params
                        andDelegate:(id <FBRequestDelegate>)delegate;

+ (FBMan *)fbman;
@end
