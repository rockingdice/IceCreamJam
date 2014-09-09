//
//  TMBGTMNSDictionary+URLArguments.m
//
//  Copyright 2006-2008 Google Inc.
//
//  Licensed under the Apache License, Version 2.0 (the "License"); you may not
//  use this file except in compliance with the License.  You may obtain a copy
//  of the License at
// 
//  http://www.apache.org/licenses/LICENSE-2.0
// 
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
//  WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.  See the
//  License for the specific language governing permissions and limitations under
//  the License.
//

#import "TMBGTMNSDictionary+URLArguments.h"
#import "TMBGTMNSString+URLArguments.h"
//#import "TMBGTMMethodCheck.h"
#import "TMBGTMDefines.h"

@implementation NSDictionary (TMBGTMNSDictionaryURLArgumentsAdditions)

+ (NSDictionary *)TMBGTM_dictionaryWithHttpArgumentsString:(NSString *)argString {
  NSMutableDictionary* ret = [NSMutableDictionary dictionary];
  NSArray* components = [argString componentsSeparatedByString:@"&"];
  NSString* component;
  // Use reverse order so that the first occurrence of a key replaces
  // those subsequent.
  TMBGTM_FOREACH_ENUMEREE(component, [components reverseObjectEnumerator]) {
    if ([component length] == 0)
      continue;
    NSRange pos = [component rangeOfString:@"="];
    NSString *key;
    NSString *val;
    if (pos.location == NSNotFound) {
      key = [component TMBGTM_stringByUnescapingFromURLArgument];
      val = @"";
    } else {
      key = [[component substringToIndex:pos.location]
             TMBGTM_stringByUnescapingFromURLArgument];
      val = [[component substringFromIndex:pos.location + pos.length]
             TMBGTM_stringByUnescapingFromURLArgument];
    }
    // TMBGTM_stringByUnescapingFromURLArgument returns nil on invalid UTF8
    // and NSMutableDictionary raises an exception when passed nil values.
    if (!key) key = @"";
    if (!val) val = @"";
    [ret setObject:val forKey:key];
  }
  return ret;
}

- (NSString *)TMBGTM_httpArgumentsString {
  NSMutableArray* arguments = [NSMutableArray arrayWithCapacity:[self count]];
  NSString* key;
  TMBGTM_FOREACH_KEY(key, self) {
    [arguments addObject:[NSString stringWithFormat:@"%@=%@",
                          [key TMBGTM_stringByEscapingForURLArgument],
                          [[[self objectForKey:key] description] TMBGTM_stringByEscapingForURLArgument]]];
  }

  return [arguments componentsJoinedByString:@"&"];
}

@end
