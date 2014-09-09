//
//  FBMan.m
//  ZombieFarm
//
//  Created by Vicente McDonnell on 11/7/09.
//  Copyright 2009 The Playforge LLC. All rights reserved.
//

#import "FBMan.h"
#import "Reachability.h"
#import "SystemUtils.h"
#import "SnsServerHelper.h"
#import "socialConfig.h"

extern CGImageRef UIGetScreenImage(void);
static FBMan *_fbman = nil;

@implementation FBMan

@synthesize facebookInterface;
@synthesize sessionDelegates;

@synthesize playerName;
@synthesize playerEmail;
@synthesize playerFullName;
@synthesize playerBio;
@synthesize playerImage;
@synthesize playerID;
@synthesize playerGender;
@synthesize friends;
@synthesize appUserFriends;
@synthesize permissionStatus;
@synthesize permissionPhoto;
@synthesize hostReach;
@synthesize connectedToInternet;
@synthesize useFaceBook;
@synthesize permissionTrackers;

+ (FBMan *)fbman 
{ 
	@synchronized(self) {
        if (_fbman == NULL)
		{
			_fbman = [[self alloc] init];
		}
    }
	
    return(_fbman);
} 

+ (id)alloc
{	
	@synchronized([FBMan class]) { 
		NSAssert(_fbman == nil, @"Attempted to allocate a second instance of a singleton.");
		_fbman = [super alloc];
		return _fbman;
	}
	
	return nil;
}

- (id) init
{
	if((self = [super init])) {
		NSString *kAppId = [SystemUtils getSystemInfo:@"kFacebookAppID"];
		facebookInterface = [[Facebook alloc] initWithAppId:kAppId andDelegate:self];
		
		sessionDelegates = [[NSMutableArray alloc] init];
		
		//zffbLoginButton = [[ZFFBLoginButton alloc] init];
		
		//[self addSessionDelegate:zffbLoginButton];
		
		playerID = @"";
		
		permissionTrackers = [[NSMutableArray alloc] init];
	}
	return self;
}

- (void)dealloc
{
	[facebookInterface release];
    facebookInterface = nil;
	[sessionDelegates release];
    sessionDelegates = nil;
	self.playerName = nil;
	self.playerEmail = nil;
	self.playerFullName = nil;
	self.playerBio = nil;
	self.playerImage = nil;
	self.playerID = nil;
	self.appUserFriends = nil;
	
	[super dealloc];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation 
{
	return (interfaceOrientation == UIInterfaceOrientationLandscapeRight);
}

- (BOOL)checkUseFaceBook
{
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSNumber *useFBNum = (NSNumber*)[defaults objectForKey:kUserDefaultID_useFacebook];
	
	if (useFBNum) {
		useFaceBook = [useFBNum boolValue];
	} else {
        [defaults setObject:[NSNumber numberWithBool:YES] forKey:kUserDefaultID_useFacebook];
		[defaults synchronize];
		useFaceBook = YES;
	}
	
	return useFaceBook;
}

#pragma mark - FBRequestDelegate
- (void)requestLoading:(FBRequest *)request
{
	smLog(@"fb Loading!!!");
}

- (void)request:(FBRequest*)request didLoad:(id)result
{
	smLog(@"request result:%@", [result description]);
	if([result isKindOfClass:[NSArray class]])// login event
	{
		//		NSArray* users = result;
		//		NSDictionary* user = [users objectAtIndex:0];
		//		playerName = (NSString*)[user objectForKey:@"first_name"];
	} else {
		//如果是上传照片的话，直接返回
		if ([result count] == 1 && [result objectForKey:@"id"]) {
			[[NSNotificationCenter defaultCenter] postNotificationName:@"kFBFeedSuccess" object:self];
			// 隐藏loadingview
			[self feedPhotoSuccess];
			return;
		}
		// Get the user information
		self.playerName = (NSString*)[result objectForKey:@"username"];
		self.playerFullName = (NSString*)[result objectForKey:@"name"];
		self.playerEmail = (NSString *)[result objectForKey:@"email"];
		self.playerID = (NSString*)[result objectForKey:@"id"];
		self.playerBio = (NSString *)[result objectForKey:@"bio"];
		self.playerGender = [[result objectForKey:@"gender"] isEqualToString:@"male"]?1:2;
		
		// Fetch the image
		if (![playerID isKindOfClass:[NSNull class]])
		{
			NSString *photoURL = [NSString stringWithFormat:@"https://graph.facebook.com/%@/picture?type=square", playerID];
			
			NSURL *url = [NSURL URLWithString:photoURL];
			NSData *data = [NSData dataWithContentsOfURL:url];
			self.playerImage = [[UIImage alloc] initWithData:data];
		} else {
			playerImage = nil;
		}
		
		NSDictionary *fbUserDictionary = [NSDictionary dictionaryWithObjectsAndKeys:playerFullName, @"username", playerID, @"userid", playerEmail, @"userEmail", nil];
		[[NSUserDefaults standardUserDefaults] setValue:fbUserDictionary forKey:@"kFacebookUserInfo"];
		
		UIImageView *imgView = [[UIImageView alloc] initWithImage:playerImage];
		[self.view addSubview:imgView];
		[imgView release];
		
		// Add a tracker for permission to post status and upload pictures
		PermissionTracker *publish_stream = [[PermissionTracker alloc] initPermission:@"publish_stream" withDelegate:self];
		
		// Only check for now...don't request
		[publish_stream checkPermission:playerID];
		
		[permissionTrackers addObject:publish_stream];
		
		[publish_stream release];
		
		// Query for the friends list
		friendListForUserAppUser = (FriendList*)[[FriendList alloc] initWithUserId:playerID withDelegate:self];
		
		[[NSNotificationCenter defaultCenter] postNotificationName:@"FBUserLoggedIn" object:self];
	}
}

- (void)request:(FBRequest*)request didFailWithError:(NSError*)error
{
	// Make sure to return to a playable state
	//[self removeTouchBlocker];
}

- (void)requestWasCancelled:(FBRequest*)request
{
	// Make sure to return to a playable state
	//[self removeTouchBlocker];
}

- (void)publishFeed:(NSString*)name withCaption:(NSString*)caption withDescription:(NSString*)description withImageURl:(NSString*)imageUrl withDelegate:(id<FBDialogDelegate>)delegate
{
	NSString *PublishURI = [SystemUtils getSystemInfo:@"kFacebookFeedLink"];
    
    BOOL isURL = NO;
    if([imageUrl length]>7 && ([imageUrl hasPrefix:@"http://"] || [imageUrl hasPrefix:@"https://"])) {
        isURL = YES;
    }
    if(!isURL) {
        imageUrl = [SystemUtils getFeedImageLink:imageUrl];
    }
    
	NSMutableDictionary* params = [NSMutableDictionary dictionaryWithObjectsAndKeys:
								   name,  @"name",
								   caption, @"caption",
								   description, @"description",
								   imageUrl, @"picture",
								   PublishURI, @"link",
								   nil];
	
	if (delegate == nil)
	{
		[facebookInterface dialog:@"feed"
						andParams:params
					  andDelegate:self];
	}
	else
	{
		[facebookInterface dialog:@"feed"
						andParams:params
					  andDelegate:delegate];
	}
	
}

- (void)dialogDidComplete:(FBDialog *)dialog {
	smLog(@"dialog success!!!");
	[[NSNotificationCenter defaultCenter] postNotificationName:@"kFBFeedSuccess" object:self];
}

- (void)startFBConnectPrompt
{
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	BOOL useFaceBookLocal = YES;
	NSNumber *useFBNum = (NSNumber*)[defaults objectForKey:kUserDefaultID_useFacebook];
	
	if (useFBNum)
	{
		useFaceBookLocal = [useFBNum boolValue];
	}
	
	if (!useFaceBookLocal)
	{
		UIAlertView *av = [[UIAlertView	alloc] initWithTitle:SNSLocalizeString(@"Facebook is Disabled", @"FB Disabled Message") 
													 message:SNSLocalizeString(@"To use this feature, you must enable Facebook in the options.", @"FB Disabled Message Body")
													delegate:self 
										   cancelButtonTitle:SNSLocalizeString(@"Ok", @"OK Button") 
										   otherButtonTitles:nil];
		
		[av show];
		[av release];
		return;
	}
	else if(![self connectedToInternet])
	{
		UIAlertView *av = [[UIAlertView	alloc] initWithTitle:SNSLocalizeString(@"Unable to Connect", @"FB Unable To Connect Message") 
													 message:nil
													delegate:self 
										   cancelButtonTitle:SNSLocalizeString(@"Ok", @"OK Button") 
										   otherButtonTitles:nil];
		[av show];
		[av release];
		return;
	}
	
	if(![self isSessionValid])//send touchupinside event
	{
		//[zffbLoginButton sendActionsForControlEvents:UIControlEventTouchUpInside];
        smLog(@"session验证通过");
	}	
}

- (void)addSessionDelegate:(id<FBSessionDelegate>)delegate
{
	[sessionDelegates addObject:delegate];
}

- (void)removeSessionDelegate:(id<FBSessionDelegate>)delegate
{
	[sessionDelegates removeObject:delegate];
}

- (void)requestPermission:(NSString*)permissionName
{
	PermissionTracker* tracker = nil;
	
	for (PermissionTracker* testTracker in permissionTrackers)
	{
        if ([[testTracker permissionName] isEqualToString:permissionName])
		{
			tracker = testTracker;
			break;
		}
	}
	
	// If we didn't find a tracker then add a new one
	if (tracker == nil)
	{
		// Create a permission tracker for this new
		PermissionTracker* tracker = [[PermissionTracker alloc] initPermission:permissionName withDelegate:self];
		
		[permissionTrackers addObject:tracker];
		[tracker release];
	}
	
	// If we don't have the permission then send an authorization request
	if (![tracker hasPermission])
	{
		NSArray* permissions =  [NSArray arrayWithObjects:permissionName, nil];
		
		[facebookInterface authorize:permissions];
		[facebookInterface setSessionDelegate:tracker];
	}
}

- (BOOL)isSessionValid
{
    //NSLog(@"session:%d",[facebookInterface isSessionValid]);
	return [facebookInterface isSessionValid];
}

- (void)login:(NSArray*)permissions
{
	// On login, use the stored access token and see if it still works
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if ([defaults objectForKey:ACCESS_TOKEN_KEY] 
        && [defaults objectForKey:EXPIRATION_DATE_KEY]) {
        facebookInterface.accessToken = [defaults objectForKey:ACCESS_TOKEN_KEY];
        facebookInterface.expirationDate = [defaults objectForKey:EXPIRATION_DATE_KEY];
    }
    
    //NSLog(@"face book token:%@",facebookInterface.accessToken);
	
	// TODO: check to see if we already have all of the permissions requested
	// TODO: Test to make sure token is *really* valid
	if (![facebookInterface isSessionValid]) {
        //NSLog(@"%s - permission:%@", __FUNCTION__, permissions);
		if (permissions == nil) {
            [facebookInterface authorize:[NSArray arrayWithObjects:[NSString stringWithString:@"offline_access"], nil]];
        } else {
			[facebookInterface authorize:permissions];
            //[facebookInterface authorize:permissions delegate:self];
        }
        
		//        [facebookInterface dialog:@"oauth"
		//						andParams:[NSMutableDictionary dictionaryWithObjectsAndKeys:
		//                                   kAppId, @"client_id",
		//                                   @"user_agent", @"type",
		//                                   @"fbconnect://success", @"redirect_uri",
		//                                   @"touch", @"display",
		//                                   @"2", @"sdk",
		//                                   nil]
		//					  andDelegate:self];
    } else {
		[self fbDidLogin];
    }
}

- (void)logout
{
	[facebookInterface logout];
	
	// Remove the access token and expiration date from the user defaults
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults removeObjectForKey:ACCESS_TOKEN_KEY];
    [defaults removeObjectForKey:EXPIRATION_DATE_KEY];
    [defaults synchronize];
}

- (void)resume
{
	// Test to see if we have any credentials
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString* accessToken = [defaults objectForKey:ACCESS_TOKEN_KEY];
	
	// If we have credentials log bakc in otherwise wait for a user login action
	if (accessToken != nil)
		[self login:nil];//[NSArray arrayWithObjects:[NSString stringWithString:@"offline_access"], nil]];
	else
		[self logout];
}

- (BOOL)handleOpenURL:(NSURL *)url
{
	return [facebookInterface handleOpenURL:url];
}

- (FBRequest*)requestWithMethodName:(NSString *)methodName
						  andParams:(NSMutableDictionary *)params
						andDelegate:(id <FBRequestDelegate>)delegate
{
	return [facebookInterface requestWithMethodName:methodName
										  andParams:params
									  andHttpMethod:@"POST"
										andDelegate:delegate];
}

#pragma mark - FBSessionDelegate
- (void)fbDidLogin
{
	// Store the access token and expiration date to the user defaults
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:[facebookInterface accessToken] forKey:ACCESS_TOKEN_KEY];
    [defaults setObject:[facebookInterface expirationDate] forKey:EXPIRATION_DATE_KEY];
    [defaults synchronize];
    smLog(@"facebook 认证成功");
	
	// TODO: Send request for user info
	[facebookInterface requestWithGraphPath:@"me" andDelegate:self];
	
	// Notify any of the objects wanting to know a login occurred
	for (id<FBSessionDelegate> delegate in sessionDelegates)
	{
		if ([delegate respondsToSelector:@selector(fbDidLogin)])
			[delegate fbDidLogin];
	}
	
	[[NSNotificationCenter defaultCenter] postNotificationName:kUserDataFetchingNotification object: nil];
}

- (BOOL)application:(UIApplication *)application handleOpenURL:(NSURL *)url {
    return [facebookInterface handleOpenURL:url];
}

- (void)fbDidNotLogin:(BOOL)cancelled
{
	// Remove the access token and expiration date from the user defaults
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults removeObjectForKey:ACCESS_TOKEN_KEY];
    [defaults removeObjectForKey:EXPIRATION_DATE_KEY];
    [defaults synchronize];
	
	// Notify any of the objects wanting to know a login did not occurred
	for (id<FBSessionDelegate> delegate in sessionDelegates)
	{
		if ([delegate respondsToSelector:@selector(fbDidNotLogin:)])
			[delegate fbDidNotLogin:cancelled];
	}
	
	[[NSNotificationCenter defaultCenter] postNotificationName:@"FBUserLoggedOut" object:self];
}

- (void)fbDidLogout
{
	// Remove the access token and expiration date from the user defaults
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults removeObjectForKey:ACCESS_TOKEN_KEY];
    [defaults removeObjectForKey:EXPIRATION_DATE_KEY];
    [defaults synchronize];
	
	// Notify any of the objects wanting to know a logout occurred
	for (id<FBSessionDelegate> delegate in sessionDelegates)
        [delegate fbDidLogout];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:@"FBUserLoggedOut" object:self];
}

#pragma mark - FriendListDelegate

- (void)friendListWasFetched:(NSArray*)array
{
	self.appUserFriends = array;
	[friendListForUserAppUser release];
}


#pragma mark - post screenshot

- (void)askPermissionForPhotoUpload
{
	[self requestPermission:@"publish_stream"];
}

static BOOL inFeeding = NO;

- (void)publishPhoto:(UIImage *)image withCaption:(NSString *)caption withDelegate:(id <FBRequestDelegate>)delegate
{
	smLog(@"feed photo to facebook!");
	inFeeding = YES;
	//显示上传loading
	[[SnsServerHelper helper] onShowInGameLoadingView:nil];
	//设置超时
	[self performSelector:@selector(feedPhotoSuccess) withObject:nil afterDelay:60.0f];
	if ([image isKindOfClass:[UIImage class]]) {
		NSMutableDictionary *params = [NSMutableDictionary dictionaryWithObjectsAndKeys:image, @"source", caption, @"message", nil];
		
		if (delegate == nil) {
			[facebookInterface requestWithGraphPath:@"me/photos"
										   andParams:params
									   andHttpMethod:@"POST"
										 andDelegate:self];
		} else {
			[facebookInterface requestWithGraphPath:@"me/photos"
										   andParams:params
									   andHttpMethod:@"POST"
										 andDelegate:delegate];
		}
	}
}

- (void) feedPhotoSuccess
{
	[[SnsServerHelper helper] onHideInGameLoadingView:nil];
	if (inFeeding) {
		SNSAlertView *alert = [[SNSAlertView alloc] initWithTitle:@"" message:[SystemUtils getLocalizedString:@"feedImageSuccess!"] delegate:nil cancelButtonTitle:[SystemUtils getLocalizedString:@"OK"] otherButtonTitle:nil];
		[alert show];
		[alert release];
		inFeeding = NO;
	}
}

#pragma mark - internet connectivity

- (void) reachabilityChanged: (NSNotification* )note
{
	Reachability* curReach = [note object];
	NSParameterAssert([curReach isKindOfClass: [Reachability class]]);
	NetworkStatus netStatus = [curReach currentReachabilityStatus];
	BOOL old = connectedToInternet;
	connectedToInternet = (netStatus != NotReachable);
	
	if (connectedToInternet != old)
	{
		[[NSNotificationCenter defaultCenter] postNotificationName:kNetConnectivityUpdatedNotification object: nil];	
	}
	
	[[NSNotificationCenter defaultCenter] postNotificationName:kNetConnectivityResultDetermined object: nil];
}

- (BOOL) internetConnectivity
{	
	[[NSNotificationCenter defaultCenter] addObserver:self 
											 selector: @selector(reachabilityChanged:) 
												 name: kReachabilityChangedNotification 
											   object: nil];
	
    //Change the host name here to change the server your monitoring
	hostReach = [[Reachability reachabilityWithHostName: @"www.baidu.com"] retain];
	[hostReach startNotifer];
	
	return YES;
}

#pragma mark -
#pragma mark PermissionTrackerDelegate
- (void)permissionChanged:(NSString*)permissionName withValue:(BOOL)hasPermission
{
	if ([permissionName isEqualToString:@"publish_stream"])
	{
		permissionStatus = hasPermission;
		permissionPhoto = hasPermission;
		
		if (hasPermission)
		{
			[[NSNotificationCenter defaultCenter] postNotificationName:kPhotoPermissionApproved object:nil];
		}
	}
}

@end
