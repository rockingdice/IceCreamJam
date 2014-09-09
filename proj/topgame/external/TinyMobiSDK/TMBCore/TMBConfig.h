//
//  TMBConfig.h
//  TinyMobi SDK
//
//  Created by gaofeng on 12-6-27.
//  Copyright (c) 2012 TinyMobi. All rights reserved.
//
//  This file is to define all the constants relative to TinyMobi’s business,
//  including primary network request paths, network timeout period, etc.
//

#import "TinyMobiAppConfig.h"


#ifndef TMBConfig_h
#define TMBConfig_h

//advertisement format define

//ad wall img
#define TMB_AD_BACK_BUTTON_IMG  @"tmb_head_back.png"
#define TMB_AD_NAV_BG_IMG       @"tmb_head_nav.png"
#define TMB_AD_NAV_ICON_IMG     @"tmb_head_icon.png"

//SDK version
#define TMB_SDK_VERSION         @"2.0.3"

//network timeout
#define TMB_NET_TIMEOUT         60

//TinyMobi server address
#ifdef TMB_SDK_TEST

#define TMB_SERVICE_URL         @"http://127.0.0.1"
//dev url
#define TMB_AD_WALL_URL @"%@/ad/wall.php?app_id=%@"
#define TMB_AD_WALL_READY_URL @"%@/ad/wall_ready.php?app_id=%@"
#define TMB_AD_POP_URL @"%@/ad/pop.php?app_id=%@"
#define TMB_AD_POP_READY_URL @"%@/ad/pop_ready.php?app_id=%@"
#define TMB_CONFIG_SERVER_URL @"%@/sdk/sdk_config.php?app_id=%@"
#define TMB_OFFER_INFO_URL @"%@/reward/reward_info.php?app_id=%@"
#define TMB_OFFER_FINISH_URL @"%@/reward/reward_finish.php?app_id=%@"
#define TMB_USER_ACTIVITY_OPEN_URL @"%@/activity/open.php?app_id=%@"
#define TMB_USER_ACTIVITY_CHECK_APP_LIST_URL @"%@/sdk/app_list.php?app_id=%@"
#define TMB_USER_ACTIVITY_CHECK_INSTALLED_URL @"%@/sdk/installed.php?app_id=%@"

#else
//online server url
//us
#define TMB_SERVICE_URL         @"http://mobile.tinymobi.com"
#define TMB_AD_WALL_URL @"%@/ad/wall/?app_id=%@"
#define TMB_AD_WALL_READY_URL @"%@/ad/wall_ready/?app_id=%@"
#define TMB_AD_POP_URL @"%@/ad/pop/?app_id=%@"
#define TMB_AD_POP_READY_URL @"%@/ad/pop_ready/?app_id=%@"
#define TMB_CONFIG_SERVER_URL @"%@/sdk/sdk_config/?app_id=%@"
#define TMB_OFFER_INFO_URL @"%@/reward/reward_info/?app_id=%@"
#define TMB_OFFER_FINISH_URL @"%@/reward/reward_finish/?app_id=%@"
#define TMB_USER_ACTIVITY_OPEN_URL @"%@/activity/open/?app_id=%@"
#define TMB_USER_ACTIVITY_CHECK_APP_LIST_URL @"%@/sdk/app_list/?app_id=%@"
#define TMB_USER_ACTIVITY_CHECK_INSTALLED_URL @"%@/sdk/installed/?app_id=%@"

#endif

#endif