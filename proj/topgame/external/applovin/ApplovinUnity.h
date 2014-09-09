//
//  TMBUnity.h
//  TMBDemo
//
//  Created by Leon Qiu on 7/23/13.
//
//

#ifndef TMBDemo_APPLOVINUNITY_h
#define TMBDemo_APPLOVINUNITY_h

// extern "C" {
/*
 在info.plist中加入下面这个属性：
<key>AppLovinSdkKey</key>
<string>scUi6v0EzBMdQb1qlOrd60AVlXcmslMJr3Byu_fh5J9h15rnnCXZWP9mLkFANNMCg9kH1l9w3De8E8bPwr01Bn</string>
*/

// 在游戏启动时调用这个函数初始化applovin
void UnityStartApplovin();

// 每跑完5次后调用一下下面这个函数，显示applovin的广告
void UnityShowApplovinOffer();
// }

#endif
