//
//  smWinQueueLogin.m
//  iPetHotel
//
//  Created by yang jie on 21/07/2011.
//  Copyright 2011 topgame. All rights reserved.
//

#import "SNSLogType.h"
#import "smPopupWindowFlurryOffer.h"
#import "smPopupWindowFlurryOfferCell.h"
#import "SystemUtils.h"
#ifndef SNS_DISABLE_FLURRY_V1
#import "FlurryHelper.h"
#endif

@implementation smPopupWindowFlurryOffer
@synthesize bodyView, titleContent, tableView, closeButton;
@synthesize setting;
@synthesize prizeType;
@synthesize tableTitle;

static BOOL isShowing = NO;

// 设置显示状态
+ (BOOL) isShowing
{
	return isShowing;
}

+ (void) setShowing:(BOOL)show
{
	isShowing = show;
}


- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)dealloc {
	self.bodyView = nil;
	self.tableTitle = nil;
	self.titleContent = nil;
	self.tableView = nil;
	self.setting = nil;
	self.closeButton = nil;
    [super dealloc];
}

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

- (void)viewDidDisappear:(BOOL)animated
{
	NSLog(@"%s", __func__);
}

#pragma mark - User method

- (IBAction) closeWindow {
	//[self dismissModalViewControllerAnimated:YES];
	isShowing = NO;
	// [FlurryHelper helper].isShowingOffer = NO;
    [super closeDialog];
}

- (void)didDialogClose {
	isShowing = NO;
	// [FlurryHelper helper].isShowingOffer = NO;
	[super didDialogClose];
}

#pragma mark - View lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
	//[self sizeToFitOrientation:NO];
    // Do any additional setup after loading the view from its nib.
	closeButton.title = [SystemUtils getLocalizedString:@"Close"];
	self.tableView.delegate = self;
	self.tableView.dataSource = self;
	NSString *prizeName = [SystemUtils getLocalizedString:@"CoinName1"];
	if(prizeType == 1)
		prizeName  = [SystemUtils getLocalizedString:@"CoinName2"];
    NSString *lang = [SystemUtils getCurrentLanguage];
    if(![lang isEqualToString:@"zh-Hans"] && ![lang isEqualToString:@"zh-Hant"])
        prizeName = [prizeName capitalizedString];
	// prizeName = [SystemUtils getLocalizedString:prizeName];
	NSString *cellText = [NSString stringWithFormat:[SystemUtils getLocalizedString:@"%@ Offers"], prizeName];
	((UINavigationItem *)titleContent).title = cellText;
	tableTitle.text = [NSString stringWithFormat:[SystemUtils getLocalizedString:@"Download and run the following applications to get bonus %@."], prizeName];
//	UIFont *cellFont = [UIFont fontWithName:@"Arial Bold" size:14.0f];
//	CGSize constraintSize = CGSizeMake(249.0f, MAXFLOAT);
//	CGSize labelSize = [cellText sizeWithFont:cellFont constrainedToSize:constraintSize lineBreakMode:UILineBreakModeWordWrap];
//	titleContent.frame = CGRectMake(36, 163, 249, labelSize.height);
}

- (void)viewDidUnload {
	NSLog(@"%s", __func__);
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
	self.bodyView = nil;
	self.tableTitle = nil;
	self.titleContent = nil;
	self.tableView = nil;
	self.setting = nil;
}

#pragma mark -

#pragma mark tableView delegate & dataSource Method

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	if(!setting) return 0;
	NSArray *arr = [setting objectForKey:@"arr"];
	if(!arr) return 0;
    return [arr count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSUInteger row=[indexPath row];
    static NSString *CellIdentifier = @"smWinQueueLoginCellIdentifier";
    smPopupWindowFlurryOfferCell *cell = (smPopupWindowFlurryOfferCell *)[self.tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell==nil) {
        NSArray *nib=[[NSBundle mainBundle] loadNibNamed:@"smPopupWindowFlurryOfferCell" owner:self options:nil];
        for (id oneObject in nib) {
            if ([oneObject isKindOfClass:[smPopupWindowFlurryOfferCell class]]) {
                cell=(smPopupWindowFlurryOfferCell *)oneObject;
            }
        }
    }
	
	NSDictionary *dic = [[setting objectForKey:@"arr"] objectAtIndex:row];
	cell.appName.text = [dic objectForKey:@"appName"];
	cell.icon.image = [dic objectForKey:@"appIcon"];
	cell.downBtn.text = [SystemUtils getLocalizedString:@"Download Now!"];
	float price = [[dic objectForKey:@"appPrice"] floatValue];
	NSString *priceValue = nil;
	if ([[setting objectForKey:@"prizeGold"] intValue] > 0) {
		priceValue = [setting objectForKey:@"prizeGold"];
	} else {
		priceValue = [setting objectForKey:@"prizeLeaf"];
	}

	if (price > 0) {
		price = price * 0.01;
	}
	if (self.prizeType == 0) {
		cell.coinIcon.image = [UIImage imageNamed:kFlurryPrizeCoinIcon40x40];
	} else if (self.prizeType == 1) {
		cell.coinIcon.image = [UIImage imageNamed:kFlurryPrizeLeafIcon40x40];
	}
	cell.appPrice.text = (price == 0)?[NSString stringWithFormat:@"[%@]", [SystemUtils getLocalizedString:@"Free"]]:[NSString stringWithFormat:@"[$%g]", price];
	cell.prizeGold.text = priceValue;
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 64;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    NSDictionary *dic = [[setting objectForKey:@"arr"] objectAtIndex:[indexPath row]];
	[[UIApplication sharedApplication] openURL:[NSURL URLWithString:[dic objectForKey:@"clickURL"]]];
}

#pragma mark -
#pragma mark parent method

- (void)sizeToFitOrientation:(BOOL)transform {
	//NSLog(@"%s - run orientation", __FUNCTION__);
	SNSCrashLog("start");
    if (transform) {
        self.view.transform = CGAffineTransformIdentity;
    }
    
    CGRect frame = [UIScreen mainScreen].applicationFrame;
    CGPoint center = CGPointMake(frame.origin.x + ceil(frame.size.width * 0.5f), frame.origin.y + ceil(frame.size.height * 0.5f));
    //self.view.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height);
	//未作Ipad适应，等二期吧⋯⋯
	//    CGFloat scale_factor = 1.0f;
	//    if ([self IsDeviceIPad]) {
	//        // On the iPad the dialog's dimensions should only be 60% of the screen's
	//        scale_factor = 0.6f;
	//    }
    
    //CGFloat width = floor(scale_factor * frame.size.width) - kPadding * 2;
    //CGFloat height = floor(scale_factor * frame.size.height) - kPadding * 2;
	
	CGFloat width, height;
	if ([SystemUtils isiPad]) {
		width = 768;
		height = 1024;
	} else {
		width = 320;
		height = 480;
	}
    
    self.privateOrientation = [UIApplication sharedApplication].statusBarOrientation;
	
    if (UIInterfaceOrientationIsLandscape(self.privateOrientation)) {
        //横着的时候
		smLog(@"横屏！！！！！！！！！");
		self.view.frame = CGRectMake(frame.size.width * 0.5f - height * 0.5f, frame.size.height * 0.5f - width * 0.5f, height, width);
    } else {
        //竖着的时候
		smLog(@"纵屏！！！！！！！！！");
		self.view.frame = CGRectMake(frame.size.width * 0.5f - width * 0.5f, frame.size.height * 0.5f - height * 0.5f, width, height);
    }
    self.view.center = center;
    
    if (transform) {
        self.view.transform = [self transformForOrientation];
    }
	SNSCrashLog("end");
}

@end
