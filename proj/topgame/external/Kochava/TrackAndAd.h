//
//  TrackAndAd.h
//  TrackAndAd
//
//  Copyright (c) 2013 Kochava. All rights reserved.
//
//
//  JSONKit is used in this library
//  http://github.com/johnezang/JSONKit
//  Dual licensed under either the terms of the BSD License, or alternatively
//  under the terms of the Apache License, Version 2.0, as specified below.
//

/*
 Copyright (c) 2011, John Engelhart
 
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions are met:
 
 * Redistributions of source code must retain the above copyright
 notice, this list of conditions and the following disclaimer.
 
 * Redistributions in binary form must reproduce the above copyright
 notice, this list of conditions and the following disclaimer in the
 documentation and/or other materials provided with the distribution.
 
 * Neither the name of the Zang Industries nor the names of its
 contributors may be used to endorse or promote products derived from
 this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
 TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
 LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
 NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

/*
 Copyright 2011 John Engelhart
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 */


//
// Copyright 2011 ODIN Working Group. All rights reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

//
//  OpenUDID.h
//  openudid
//
//  initiated by Yann Lechelle (cofounder @Appsfire) on 8/28/11.
//  Copyright 2011 OpenUDID.org
//
//  Main branches
//      iOS code: https://github.com/ylechelle/OpenUDID
//

/*
 http://en.wikipedia.org/wiki/Zlib_License
 
 This software is provided 'as-is', without any express or implied
 warranty. In no event will the authors be held liable for any damages
 arising from the use of this software.
 
 Permission is granted to anyone to use this software for any purpose,
 including commercial applications, and to alter it and redistribute it
 freely, subject to the following restrictions:
 
 1. The origin of this software must not be misrepresented; you must not
 claim that you wrote the original software. If you use this software
 in a product, an acknowledgment in the product documentation would be
 appreciated but is not required.
 
 2. Altered source versions must be plainly marked as such, and must not be
 misrepresented as being the original software.
 
 3. This notice may not be removed or altered from any source
 distribution.
 */




#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface TrackAndAd : NSObject
@end

@protocol PxpNetworkAccessDelegate;
@protocol PxpNetworkAccessDelegate <NSObject>

@optional
- (void) PxpConnectionDidFinishLoading:(NSDictionary *)responseDict;
- (void) PxpInitResult:(NSDictionary*)initResult;
- (void) PxpIdentityLinkResult:(bool)identityLinkSuccess;
- (void) PxpConnectionDidFailWithError:(NSError *)error;

@end


#pragma mark - -------------------------------------
#pragma mark - Kochava Client

@protocol KochavaTrackerClientDelegate;

@interface KochavaTracker : NSObject <PxpNetworkAccessDelegate>

- (id) initWithKochavaAppId:(NSString*)appId;
- (id) initWithKochavaAppId:(NSString*)appId :(NSString*)currency;
- (id) initWithKochavaAppId:(NSString*)appId :(NSString*)currency :(bool)enableLogging;
- (id) initWithKochavaAppId:(NSString*)appId :(NSString*)currency :(bool)enableLogging :(bool)limitAdTracking;
- (id) initWithKochavaAppId:(NSString*)appId :(NSString*)currency :(bool)enableLogging :(bool)limitAdTracking :(bool)isNewUser;
- (id) initKochavaWithParams:(NSDictionary*)initDict;

- (void) enableConsoleLogging:(bool)enableLogging;

- (void) trackEvent:(NSString*)eventTitle :(NSString*)eventValue;
- (void) identityLinkEvent:(NSDictionary*)identityLinkData;
- (void) spatialEvent:(NSString*)eventTitle :(float)x :(float)y :(float)z;
- (void) setLimitAdTracking:(bool)limitAdTracking;
- (NSDictionary*) retrieveAttribution;

@property (nonatomic, assign) id <KochavaTrackerClientDelegate> trackerDelegate;

@end


@protocol KochavaTrackerClientDelegate <NSObject>
@optional
- (void) Kochava_identityLinkResult:(bool)identityLinkResult;
- (void) Kochava_attributionResult:(NSDictionary*)attributionResult;

@end



#pragma mark - -------------------------------------
#pragma mark - Ad Client

@protocol KochavaAdClientDelegate;

@interface KochavaAdClient : UIView <UIWebViewDelegate, UIGestureRecognizerDelegate, PxpNetworkAccessDelegate>

- (void) displayAdWebView:(UIViewController*)callingController :(UIView*)callingView :(bool)isInterstitial;
- (void) presentClickAd;

@property (nonatomic, assign) id <KochavaAdClientDelegate> adDelegate;
@end

@protocol KochavaAdClientDelegate <NSObject>
@optional
- (void) Kochava_adLoaded:(KochavaAdClient*)adView :(bool)isInterstitial;
- (void) Kochava_fullScreenAdWillLoad:(KochavaAdClient*)adView;
- (void) Kochava_fullScreenAdDidUnload:(KochavaAdClient*)adView;

@end

