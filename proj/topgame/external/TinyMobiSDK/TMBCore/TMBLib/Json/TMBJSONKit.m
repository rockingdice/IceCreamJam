//
//  TMBJSONKit.m
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


/*
  Acknowledgments:

  The bulk of the UTF8 / UTF32 conversion and verification comes
  from ConvertUTF.[hc].  It has been modified from the original sources.

  The original sources were obtained from http://www.unicode.org/.
  However, the web site no longer seems to host the files.  Instead,
  the Unicode FAQ http://www.unicode.org/faq//utf_bom.html#gen4
  points to International Components for Unicode (ICU)
  http://site.icu-project.org/ as an example of how to write a UTF
  converter.

  The decision to use the ConvertUTF.[ch] code was made to leverage
  "proven" code.  Hopefully the local modifications are bug free.

  The code in isValidCodePoint() is derived from the ICU code in
  utf.h for the macros U_IS_UNICODE_NONCHAR and U_IS_UNICODE_CHAR.

  From the original ConvertUTF.[ch]:

 * Copyright 2001-2004 Unicode, Inc.
 * 
 * Disclaimer
 * 
 * This source code is provided as is by Unicode, Inc. No claims are
 * made as to fitness for any particular purpose. No warranties of any
 * kind are expressed or implied. The recipient agrees to determine
 * applicability of information provided. If this file has been
 * purchased on magnetic or optical media from Unicode, Inc., the
 * sole remedy for any claim will be exchange of defective media
 * within 90 days of receipt.
 * 
 * Limitations on Rights to Redistribute This Code
 * 
 * Unicode, Inc. hereby grants the right to freely use the information
 * supplied in this file in the creation of products supporting the
 * Unicode Standard, and to make copies of this file in any form
 * for internal or external distribution as long as this notice
 * remains attached.

*/

#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <string.h>
#include <assert.h>
#include <sys/errno.h>
#include <math.h>
#include <limits.h>
#include <objc/runtime.h>

#import "TMBJSONKit.h"

//#include <CoreFoundation/CoreFoundation.h>
#include <CoreFoundation/CFString.h>
#include <CoreFoundation/CFArray.h>
#include <CoreFoundation/CFDictionary.h>
#include <CoreFoundation/CFNumber.h>

//#import <Foundation/Foundation.h>
#import <Foundation/NSArray.h>
#import <Foundation/NSAutoreleasePool.h>
#import <Foundation/NSData.h>
#import <Foundation/NSDictionary.h>
#import <Foundation/NSException.h>
#import <Foundation/NSNull.h>
#import <Foundation/NSObjCRuntime.h>

#ifndef __has_feature
#define __has_feature(x) 0
#endif

#ifdef TMBJK_ENABLE_CF_TRANSFER_OWNERSHIP_CALLBACKS
#warning As of TMBJSONKit v1.4, TMBJK_ENABLE_CF_TRANSFER_OWNERSHIP_CALLBACKS is no longer required.  It is no longer a valid option.
#endif

#ifdef __OBJC_GC__
#error TMBJSONKit does not support Objective-C Garbage Collection
#endif

#if __has_feature(objc_arc)
#error TMBJSONKit does not support Objective-C Automatic Reference Counting (ARC)
#endif

// The following checks are really nothing more than sanity checks.
// TMBJSONKit technically has a few problems from a "strictly C99 conforming" standpoint, though they are of the pedantic nitpicking variety.
// In practice, though, for the compilers and architectures we can reasonably expect this code to be compiled for, these pedantic nitpicks aren't really a problem.
// Since we're limited as to what we can do with pre-processor #if checks, these checks are not nearly as through as they should be.

#if (UINT_MAX != 0xffffffffU) || (INT_MIN != (-0x7fffffff-1)) || (ULLONG_MAX != 0xffffffffffffffffULL) || (LLONG_MIN != (-0x7fffffffffffffffLL-1LL))
#error TMBJSONKit requires the C 'int' and 'long long' types to be 32 and 64 bits respectively.
#endif

#if !defined(__LP64__) && ((UINT_MAX != ULONG_MAX) || (INT_MAX != LONG_MAX) || (INT_MIN != LONG_MIN) || (WORD_BIT != LONG_BIT))
#error TMBJSONKit requires the C 'int' and 'long' types to be the same on 32-bit architectures.
#endif

// Cocoa / Foundation uses NS*Integer as the type for a lot of arguments.  We make sure that NS*Integer is something we are expecting and is reasonably compatible with size_t / ssize_t

#if (NSUIntegerMax != ULONG_MAX) || (NSIntegerMax != LONG_MAX) || (NSIntegerMin != LONG_MIN)
#error TMBJSONKit requires NSInteger and NSUInteger to be the same size as the C 'long' type.
#endif

#if (NSUIntegerMax != SIZE_MAX) || (NSIntegerMax != SSIZE_MAX)
#error TMBJSONKit requires NSInteger and NSUInteger to be the same size as the C 'size_t' type.
#endif


// For DJB hash.
#define TMBJK_HASH_INIT           (1402737925UL)

// Use __builtin_clz() instead of trailingBytesForUTF8[] table lookup.
#define TMBJK_FAST_TRAILING_BYTES

// TMBJK_CACHE_SLOTS must be a power of 2.  Default size is 1024 slots.
#define TMBJK_CACHE_SLOTS_BITS    (10)
#define TMBJK_CACHE_SLOTS         (1UL << TMBJK_CACHE_SLOTS_BITS)
// TMBJK_CACHE_PROBES is the number of probe attempts.
#define TMBJK_CACHE_PROBES        (4UL)
// TMBJK_INIT_CACHE_AGE must be < (1 << AGE) - 1, where AGE is sizeof(typeof(AGE)) * 8.
#define TMBJK_INIT_CACHE_AGE      (0)

// TMBJK_TOKENBUFFER_SIZE is the default stack size for the temporary buffer used to hold "non-simple" strings (i.e., contains \ escapes)
#define TMBJK_TOKENBUFFER_SIZE    (1024UL * 2UL)

// TMBJK_STACK_OBJS is the default number of spaces reserved on the stack for temporarily storing pointers to Obj-C objects before they can be transferred to a NSArray / NSDictionary.
#define TMBJK_STACK_OBJS          (1024UL * 1UL)

#define TMBJK_JSONBUFFER_SIZE     (1024UL * 4UL)
#define TMBJK_UTF8BUFFER_SIZE     (1024UL * 16UL)

#define TMBJK_ENCODE_CACHE_SLOTS  (1024UL)


#if       defined (__GNUC__) && (__GNUC__ >= 4)
#define TMBJK_ATTRIBUTES(attr, ...)        __attribute__((attr, ##__VA_ARGS__))
#define TMBJK_EXPECTED(cond, expect)       __builtin_expect((long)(cond), (expect))
#define TMBJK_EXPECT_T(cond)               TMBJK_EXPECTED(cond, 1U)
#define TMBJK_EXPECT_F(cond)               TMBJK_EXPECTED(cond, 0U)
#define TMBJK_PREFETCH(ptr)                __builtin_prefetch(ptr)
#else  // defined (__GNUC__) && (__GNUC__ >= 4) 
#define TMBJK_ATTRIBUTES(attr, ...)
#define TMBJK_EXPECTED(cond, expect)       (cond)
#define TMBJK_EXPECT_T(cond)               (cond)
#define TMBJK_EXPECT_F(cond)               (cond)
#define TMBJK_PREFETCH(ptr)
#endif // defined (__GNUC__) && (__GNUC__ >= 4) 

#define TMBJK_STATIC_INLINE                         static __inline__ TMBJK_ATTRIBUTES(always_inline)
#define TMBJK_ALIGNED(arg)                                            TMBJK_ATTRIBUTES(aligned(arg))
#define TMBJK_UNUSED_ARG                                              TMBJK_ATTRIBUTES(unused)
#define TMBJK_WARN_UNUSED                                             TMBJK_ATTRIBUTES(warn_unused_result)
#define TMBJK_WARN_UNUSED_CONST                                       TMBJK_ATTRIBUTES(warn_unused_result, const)
#define TMBJK_WARN_UNUSED_PURE                                        TMBJK_ATTRIBUTES(warn_unused_result, pure)
#define TMBJK_WARN_UNUSED_SENTINEL                                    TMBJK_ATTRIBUTES(warn_unused_result, sentinel)
#define TMBJK_NONNULL_ARGS(arg, ...)                                  TMBJK_ATTRIBUTES(nonnull(arg, ##__VA_ARGS__))
#define TMBJK_WARN_UNUSED_NONNULL_ARGS(arg, ...)                      TMBJK_ATTRIBUTES(warn_unused_result, nonnull(arg, ##__VA_ARGS__))
#define TMBJK_WARN_UNUSED_CONST_NONNULL_ARGS(arg, ...)                TMBJK_ATTRIBUTES(warn_unused_result, const, nonnull(arg, ##__VA_ARGS__))
#define TMBJK_WARN_UNUSED_PURE_NONNULL_ARGS(arg, ...)                 TMBJK_ATTRIBUTES(warn_unused_result, pure, nonnull(arg, ##__VA_ARGS__))

#if       defined (__GNUC__) && (__GNUC__ >= 4) && (__GNUC_MINOR__ >= 3)
#define TMBJK_ALLOC_SIZE_NON_NULL_ARGS_WARN_UNUSED(as, nn, ...) TMBJK_ATTRIBUTES(warn_unused_result, nonnull(nn, ##__VA_ARGS__), alloc_size(as))
#else  // defined (__GNUC__) && (__GNUC__ >= 4) && (__GNUC_MINOR__ >= 3)
#define TMBJK_ALLOC_SIZE_NON_NULL_ARGS_WARN_UNUSED(as, nn, ...) TMBJK_ATTRIBUTES(warn_unused_result, nonnull(nn, ##__VA_ARGS__))
#endif // defined (__GNUC__) && (__GNUC__ >= 4) && (__GNUC_MINOR__ >= 3)


@class TMBJKArray, TMBJKDictionaryEnumerator, TMBJKDictionary;

enum {
  TMBJSONNumberStateStart                 = 0,
  TMBJSONNumberStateFinished              = 1,
  TMBJSONNumberStateError                 = 2,
  TMBJSONNumberStateWholeNumberStart      = 3,
  TMBJSONNumberStateWholeNumberMinus      = 4,
  TMBJSONNumberStateWholeNumberZero       = 5,
  TMBJSONNumberStateWholeNumber           = 6,
  TMBJSONNumberStatePeriod                = 7,
  TMBJSONNumberStateFractionalNumberStart = 8,
  TMBJSONNumberStateFractionalNumber      = 9,
  TMBJSONNumberStateExponentStart         = 10,
  TMBJSONNumberStateExponentPlusMinus     = 11,
  TMBJSONNumberStateExponent              = 12,
};

enum {
  TMBJSONStringStateStart                           = 0,
  TMBJSONStringStateParsing                         = 1,
  TMBJSONStringStateFinished                        = 2,
  TMBJSONStringStateError                           = 3,
  TMBJSONStringStateEscape                          = 4,
  TMBJSONStringStateEscapedUnicode1                 = 5,
  TMBJSONStringStateEscapedUnicode2                 = 6,
  TMBJSONStringStateEscapedUnicode3                 = 7,
  TMBJSONStringStateEscapedUnicode4                 = 8,
  TMBJSONStringStateEscapedUnicodeSurrogate1        = 9,
  TMBJSONStringStateEscapedUnicodeSurrogate2        = 10,
  TMBJSONStringStateEscapedUnicodeSurrogate3        = 11,
  TMBJSONStringStateEscapedUnicodeSurrogate4        = 12,
  TMBJSONStringStateEscapedNeedEscapeForSurrogate   = 13,
  TMBJSONStringStateEscapedNeedEscapedUForSurrogate = 14,
};

enum {
  TMBJKParseAcceptValue      = (1 << 0),
  TMBJKParseAcceptComma      = (1 << 1),
  TMBJKParseAcceptEnd        = (1 << 2),
  TMBJKParseAcceptValueOrEnd = (TMBJKParseAcceptValue | TMBJKParseAcceptEnd),
  TMBJKParseAcceptCommaOrEnd = (TMBJKParseAcceptComma | TMBJKParseAcceptEnd),
};

enum {
  TMBJKClassUnknown    = 0,
  TMBJKClassString     = 1,
  TMBJKClassNumber     = 2,
  TMBJKClassArray      = 3,
  TMBJKClassDictionary = 4,
  TMBJKClassNull       = 5,
};

enum {
  TMBJKManagedBufferOnStack        = 1,
  TMBJKManagedBufferOnHeap         = 2,
  TMBJKManagedBufferLocationMask   = (0x3),
  TMBJKManagedBufferLocationShift  = (0),
  
  TMBJKManagedBufferMustFree       = (1 << 2),
};
typedef TMBJKFlags TMBJKManagedBufferFlags;

enum {
  TMBJKObjectStackOnStack        = 1,
  TMBJKObjectStackOnHeap         = 2,
  TMBJKObjectStackLocationMask   = (0x3),
  TMBJKObjectStackLocationShift  = (0),
  
  TMBJKObjectStackMustFree       = (1 << 2),
};
typedef TMBJKFlags TMBJKObjectStackFlags;

enum {
  TMBJKTokenTypeInvalid     = 0,
  TMBJKTokenTypeNumber      = 1,
  TMBJKTokenTypeString      = 2,
  TMBJKTokenTypeObjectBegin = 3,
  TMBJKTokenTypeObjectEnd   = 4,
  TMBJKTokenTypeArrayBegin  = 5,
  TMBJKTokenTypeArrayEnd    = 6,
  TMBJKTokenTypeSeparator   = 7,
  TMBJKTokenTypeComma       = 8,
  TMBJKTokenTypeTrue        = 9,
  TMBJKTokenTypeFalse       = 10,
  TMBJKTokenTypeNull        = 11,
  TMBJKTokenTypeWhiteSpace  = 12,
};
typedef NSUInteger TMBJKTokenType;

// These are prime numbers to assist with hash slot probing.
enum {
  TMBJKValueTypeNone             = 0,
  TMBJKValueTypeString           = 5,
  TMBJKValueTypeLongLong         = 7,
  TMBJKValueTypeUnsignedLongLong = 11,
  TMBJKValueTypeDouble           = 13,
};
typedef NSUInteger TMBJKValueType;

enum {
  TMBJKEncodeOptionAsData              = 1,
  TMBJKEncodeOptionAsString            = 2,
  TMBJKEncodeOptionAsTypeMask          = 0x7,
  TMBJKEncodeOptionCollectionObj       = (1 << 3),
  TMBJKEncodeOptionStringObj           = (1 << 4),
  TMBJKEncodeOptionStringObjTrimQuotes = (1 << 5),
  
};
typedef NSUInteger TMBJKEncodeOptionType;

typedef NSUInteger TMBJKHash;

typedef struct TMBJKTokenCacheItem  TMBJKTokenCacheItem;
typedef struct TMBJKTokenCache      TMBJKTokenCache;
typedef struct TMBJKTokenValue      TMBJKTokenValue;
typedef struct TMBJKParseToken      TMBJKParseToken;
typedef struct TMBJKPtrRange        TMBJKPtrRange;
typedef struct TMBJKObjectStack     TMBJKObjectStack;
typedef struct TMBJKBuffer          TMBJKBuffer;
typedef struct TMBJKConstBuffer     TMBJKConstBuffer;
typedef struct TMBJKConstPtrRange   TMBJKConstPtrRange;
typedef struct TMBJKRange           TMBJKRange;
typedef struct TMBJKManagedBuffer   TMBJKManagedBuffer;
typedef struct TMBJKFastClassLookup TMBJKFastClassLookup;
typedef struct TMBJKEncodeCache     TMBJKEncodeCache;
typedef struct TMBJKEncodeState     TMBJKEncodeState;
typedef struct TMBJKObjCImpCache    TMBJKObjCImpCache;
typedef struct TMBJKHashTableEntry  TMBJKHashTableEntry;

typedef id (*NSNumberAllocImp)(id receiver, SEL selector);
typedef id (*NSNumberInitWithUnsignedLongLongImp)(id receiver, SEL selector, unsigned long long value);
typedef id (*TMBJKClassFormatterIMP)(id receiver, SEL selector, id object);
#ifdef __BLOCKS__
typedef id (^TMBJKClassFormatterBlock)(id formatObject);
#endif


struct TMBJKPtrRange {
  unsigned char *ptr;
  size_t         length;
};

struct TMBJKConstPtrRange {
  const unsigned char *ptr;
  size_t               length;
};

struct TMBJKRange {
  size_t location, length;
};

struct TMBJKManagedBuffer {
  TMBJKPtrRange           bytes;
  TMBJKManagedBufferFlags flags;
  size_t               roundSizeUpToMultipleOf;
};

struct TMBJKObjectStack {
  void               **objects, **keys;
  CFHashCode          *cfHashes;
  size_t               count, index, roundSizeUpToMultipleOf;
  TMBJKObjectStackFlags   flags;
};

struct TMBJKBuffer {
  TMBJKPtrRange bytes;
};

struct TMBJKConstBuffer {
  TMBJKConstPtrRange bytes;
};

struct TMBJKTokenValue {
  TMBJKConstPtrRange   ptrRange;
  TMBJKValueType       type;
  TMBJKHash            hash;
  union {
    long long          longLongValue;
    unsigned long long unsignedLongLongValue;
    double             doubleValue;
  } number;
  TMBJKTokenCacheItem *cacheItem;
};

struct TMBJKParseToken {
  TMBJKConstPtrRange tokenPtrRange;
  TMBJKTokenType     type;
  TMBJKTokenValue    value;
  TMBJKManagedBuffer tokenBuffer;
};

struct TMBJKTokenCacheItem {
  void          *object;
  TMBJKHash         hash;
  CFHashCode     cfHash;
  size_t         size;
  unsigned char *bytes;
  TMBJKValueType    type;
};

struct TMBJKTokenCache {
  TMBJKTokenCacheItem *items;
  size_t            count;
  unsigned int      prng_lfsr;
  unsigned char     age[TMBJK_CACHE_SLOTS];
};

struct TMBJKObjCImpCache {
  Class                               NSNumberClass;
  NSNumberAllocImp                    NSNumberAlloc;
  NSNumberInitWithUnsignedLongLongImp NSNumberInitWithUnsignedLongLong;
};

struct TMBJKParseState {
  TMBJKParseOptionFlags  parseOptionFlags;
  TMBJKConstBuffer       stringBuffer;
  size_t              atIndex, lineNumber, lineStartIndex;
  size_t              prev_atIndex, prev_lineNumber, prev_lineStartIndex;
  TMBJKParseToken        token;
  TMBJKObjectStack       objectStack;
  TMBJKTokenCache        cache;
  TMBJKObjCImpCache      objCImpCache;
  NSError            *error;
  int                 errorIsPrev;
  BOOL                mutableCollections;
};

struct TMBJKFastClassLookup {
  void *stringClass;
  void *numberClass;
  void *arrayClass;
  void *dictionaryClass;
  void *nullClass;
};

struct TMBJKEncodeCache {
  id object;
  size_t offset;
  size_t length;
};

struct TMBJKEncodeState {
  TMBJKManagedBuffer         utf8ConversionBuffer;
  TMBJKManagedBuffer         stringBuffer;
  size_t                  atIndex;
  TMBJKFastClassLookup       fastClassLookup;
  TMBJKEncodeCache           cache[TMBJK_ENCODE_CACHE_SLOTS];
  TMBJKSerializeOptionFlags  serializeOptionFlags;
  TMBJKEncodeOptionType      encodeOption;
  size_t                  depth;
  NSError                *error;
  id                      classFormatterDelegate;
  SEL                     classFormatterSelector;
  TMBJKClassFormatterIMP     classFormatterIMP;
#ifdef __BLOCKS__
  TMBJKClassFormatterBlock   classFormatterBlock;
#endif
};

// This is a TMBJSONKit private class.
@interface TMBJKSerializer : NSObject {
  TMBJKEncodeState *encodeState;
}

#ifdef __BLOCKS__
#define TMBJKSERIALIZER_BLOCKS_PROTO id(^)(id object)
#else
#define TMBJKSERIALIZER_BLOCKS_PROTO id
#endif

+ (id)serializeObject:(id)object options:(TMBJKSerializeOptionFlags)optionFlags encodeOption:(TMBJKEncodeOptionType)encodeOption block:(TMBJKSERIALIZER_BLOCKS_PROTO)block delegate:(id)delegate selector:(SEL)selector error:(NSError **)error;
- (id)serializeObject:(id)object options:(TMBJKSerializeOptionFlags)optionFlags encodeOption:(TMBJKEncodeOptionType)encodeOption block:(TMBJKSERIALIZER_BLOCKS_PROTO)block delegate:(id)delegate selector:(SEL)selector error:(NSError **)error;
- (void)releaseState;

@end

struct TMBJKHashTableEntry {
  NSUInteger keyHash;
  id key, object;
};


typedef uint32_t UTF32; /* at least 32 bits */
typedef uint16_t UTF16; /* at least 16 bits */
typedef uint8_t  UTF8;  /* typically 8 bits */

typedef enum {
  conversionOK,           /* conversion successful */
  sourceExhausted,        /* partial character in source, but hit end */
  targetExhausted,        /* insuff. room in target for conversion */
  sourceIllegal           /* source sequence is illegal/malformed */
} ConversionResult;

#define UNI_REPLACEMENT_CHAR (UTF32)0x0000FFFD
#define UNI_MAX_BMP          (UTF32)0x0000FFFF
#define UNI_MAX_UTF16        (UTF32)0x0010FFFF
#define UNI_MAX_UTF32        (UTF32)0x7FFFFFFF
#define UNI_MAX_LEGAL_UTF32  (UTF32)0x0010FFFF
#define UNI_SUR_HIGH_START   (UTF32)0xD800
#define UNI_SUR_HIGH_END     (UTF32)0xDBFF
#define UNI_SUR_LOW_START    (UTF32)0xDC00
#define UNI_SUR_LOW_END      (UTF32)0xDFFF


#if !defined(JK_FAST_TRAILING_BYTES)
static const char trailingBytesForUTF8[256] = {
    0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
    0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
    0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
    0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
    0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
    0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
    1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1, 1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,
    2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2, 3,3,3,3,3,3,3,3,4,4,4,4,5,5,5,5
};
#endif

static const UTF32 offsetsFromUTF8[6] = { 0x00000000UL, 0x00003080UL, 0x000E2080UL, 0x03C82080UL, 0xFA082080UL, 0x82082080UL };
static const UTF8  firstByteMark[7]   = { 0x00, 0x00, 0xC0, 0xE0, 0xF0, 0xF8, 0xFC };

#define TMBJK_AT_STRING_PTR(x)  (&((x)->stringBuffer.bytes.ptr[(x)->atIndex]))
#define TMBJK_END_STRING_PTR(x) (&((x)->stringBuffer.bytes.ptr[(x)->stringBuffer.bytes.length]))


static TMBJKArray          *_JKArrayCreate(id *objects, NSUInteger count, BOOL mutableCollection);
static void              _JKArrayInsertObjectAtIndex(TMBJKArray *array, id newObject, NSUInteger objectIndex);
static void              _JKArrayReplaceObjectAtIndexWithObject(TMBJKArray *array, NSUInteger objectIndex, id newObject);
static void              _JKArrayRemoveObjectAtIndex(TMBJKArray *array, NSUInteger objectIndex);


static NSUInteger        _JKDictionaryCapacityForCount(NSUInteger count);
static TMBJKDictionary     *_JKDictionaryCreate(id *keys, NSUInteger *keyHashes, id *objects, NSUInteger count, BOOL mutableCollection);
static TMBJKHashTableEntry *_JKDictionaryHashEntry(TMBJKDictionary *dictionary);
static NSUInteger        _JKDictionaryCapacity(TMBJKDictionary *dictionary);
static void              _JKDictionaryResizeIfNeccessary(TMBJKDictionary *dictionary);
static void              _JKDictionaryRemoveObjectWithEntry(TMBJKDictionary *dictionary, TMBJKHashTableEntry *entry);
static void              _JKDictionaryAddObject(TMBJKDictionary *dictionary, NSUInteger keyHash, id key, id object);
static TMBJKHashTableEntry *_JKDictionaryHashTableEntryForKey(TMBJKDictionary *dictionary, id aKey);


static void _JSONDecoderCleanup(TMBJSONDecoder *decoder);

static id _NSStringObjectFromJSONString(NSString *jsonString, TMBJKParseOptionFlags parseOptionFlags, NSError **error, BOOL mutableCollection);


static void jk_managedBuffer_release(TMBJKManagedBuffer *managedBuffer);
static void jk_managedBuffer_setToStackBuffer(TMBJKManagedBuffer *managedBuffer, unsigned char *ptr, size_t length);
static unsigned char *jk_managedBuffer_resize(TMBJKManagedBuffer *managedBuffer, size_t newSize);
static void jk_objectStack_release(TMBJKObjectStack *objectStack);
static void jk_objectStack_setToStackBuffer(TMBJKObjectStack *objectStack, void **objects, void **keys, CFHashCode *cfHashes, size_t count);
static int  jk_objectStack_resize(TMBJKObjectStack *objectStack, size_t newCount);

static void   jk_error(TMBJKParseState *parseState, NSString *format, ...);
static int    jk_parse_string(TMBJKParseState *parseState);
static int    jk_parse_number(TMBJKParseState *parseState);
static size_t jk_parse_is_newline(TMBJKParseState *parseState, const unsigned char *atCharacterPtr);
TMBJK_STATIC_INLINE int jk_parse_skip_newline(TMBJKParseState *parseState);
TMBJK_STATIC_INLINE void jk_parse_skip_whitespace(TMBJKParseState *parseState);
static int    jk_parse_next_token(TMBJKParseState *parseState);
static void   jk_error_parse_accept_or3(TMBJKParseState *parseState, int state, NSString *or1String, NSString *or2String, NSString *or3String);
static void  *jk_create_dictionary(TMBJKParseState *parseState, size_t startingObjectIndex);
static void  *jk_parse_dictionary(TMBJKParseState *parseState);
static void  *jk_parse_array(TMBJKParseState *parseState);
static void  *jk_object_for_token(TMBJKParseState *parseState);
static void  *jk_cachedObjects(TMBJKParseState *parseState);
TMBJK_STATIC_INLINE void jk_cache_age(TMBJKParseState *parseState);
TMBJK_STATIC_INLINE void jk_set_parsed_token(TMBJKParseState *parseState, const unsigned char *ptr, size_t length, TMBJKTokenType type, size_t advanceBy);


static void jk_encode_error(TMBJKEncodeState *encodeState, NSString *format, ...);
static int jk_encode_printf(TMBJKEncodeState *encodeState, TMBJKEncodeCache *cacheSlot, size_t startingAtIndex, id object, const char *format, ...);
static int jk_encode_write(TMBJKEncodeState *encodeState, TMBJKEncodeCache *cacheSlot, size_t startingAtIndex, id object, const char *format);
static int jk_encode_writePrettyPrintWhiteSpace(TMBJKEncodeState *encodeState);
static int jk_encode_write1slow(TMBJKEncodeState *encodeState, ssize_t depthChange, const char *format);
static int jk_encode_write1fast(TMBJKEncodeState *encodeState, ssize_t depthChange TMBJK_UNUSED_ARG, const char *format);
static int jk_encode_writen(TMBJKEncodeState *encodeState, TMBJKEncodeCache *cacheSlot, size_t startingAtIndex, id object, const char *format, size_t length);
TMBJK_STATIC_INLINE TMBJKHash jk_encode_object_hash(void *objectPtr);
TMBJK_STATIC_INLINE void jk_encode_updateCache(TMBJKEncodeState *encodeState, TMBJKEncodeCache *cacheSlot, size_t startingAtIndex, id object);
static int jk_encode_add_atom_to_buffer(TMBJKEncodeState *encodeState, void *objectPtr);

#define jk_encode_write1(es, dc, f)  (TMBJK_EXPECT_F(_TMBjk_encode_prettyPrint) ? jk_encode_write1slow(es, dc, f) : jk_encode_write1fast(es, dc, f))


TMBJK_STATIC_INLINE size_t jk_min(size_t a, size_t b);
TMBJK_STATIC_INLINE size_t jk_max(size_t a, size_t b);
TMBJK_STATIC_INLINE TMBJKHash jk_calculateHash(TMBJKHash currentHash, unsigned char c);

// TMBJSONKit v1.4 used both a TMBJKArray : NSArray and TMBJKMutableArray : NSMutableArray, and the same for the dictionary collection type.
// However, Louis Gerbarg (via cocoa-dev) pointed out that Cocoa / Core Foundation actually implements only a single class that inherits from the 
// mutable version, and keeps an ivar bit for whether or not that instance is mutable.  This means that the immutable versions of the collection
// classes receive the mutating methods, but this is handled by having those methods throw an exception when the ivar bit is set to immutable.
// We adopt the same strategy here.  It's both cleaner and gets rid of the method swizzling hackery used in TMBJSONKit v1.4.


// This is a workaround for issue #23 https://github.com/johnezang/JSONKit/pull/23
// Basically, there seem to be a problem with using +load in static libraries on iOS.  However, __attribute__ ((constructor)) does work correctly.
// Since we do not require anything "special" that +load provides, and we can accomplish the same thing using __attribute__ ((constructor)), the +load logic was moved here.

static Class                               _TMBJKArrayClass                           = NULL;
static size_t                              _TMBJKArrayInstanceSize                    = 0UL;
static Class                               _TMBJKDictionaryClass                      = NULL;
static size_t                              _TMBJKDictionaryInstanceSize               = 0UL;

// For TMBJSONDecoder...
static Class                               _TMBjk_NSNumberClass                       = NULL;
static NSNumberAllocImp                    _TMBjk_NSNumberAllocImp                    = NULL;
static NSNumberInitWithUnsignedLongLongImp _TMBjk_NSNumberInitWithUnsignedLongLongImp = NULL;

extern void TMBjk_collectionClassLoadTimeInitialization(void) __attribute__ ((constructor));

void TMBjk_collectionClassLoadTimeInitialization(void) {
  NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init]; // Though technically not required, the run time environment at load time initialization may be less than ideal.
  
  _TMBJKArrayClass             = objc_getClass("TMBJKArray");
  _TMBJKArrayInstanceSize      = jk_max(16UL, class_getInstanceSize(_TMBJKArrayClass));
  
  _TMBJKDictionaryClass        = objc_getClass("TMBJKDictionary");
  _TMBJKDictionaryInstanceSize = jk_max(16UL, class_getInstanceSize(_TMBJKDictionaryClass));
  
  // For TMBJSONDecoder...
  _TMBjk_NSNumberClass = [NSNumber class];
  _TMBjk_NSNumberAllocImp = (NSNumberAllocImp)[NSNumber methodForSelector:@selector(alloc)];
  
  // Hacktacular.  Need to do it this way due to the nature of class clusters.
  id temp_NSNumber = [NSNumber alloc];
  _TMBjk_NSNumberInitWithUnsignedLongLongImp = (NSNumberInitWithUnsignedLongLongImp)[temp_NSNumber methodForSelector:@selector(initWithUnsignedLongLong:)];
  [[temp_NSNumber init] release];
  temp_NSNumber = NULL;
  
  [pool release]; pool = NULL;
}


#pragma mark -
@interface TMBJKArray : NSMutableArray <NSCopying, NSMutableCopying, NSFastEnumeration> {
  id         *objects;
  NSUInteger  count, capacity, mutations;
}
@end

@implementation TMBJKArray

+ (id)allocWithZone:(NSZone *)zone
{
#pragma unused(zone)
  [NSException raise:NSInvalidArgumentException format:@"*** - [%@ %@]: The %@ class is private to TMBJSONKit and should not be used in this fashion.", NSStringFromClass([self class]), NSStringFromSelector(_cmd), NSStringFromClass([self class])];
  return(NULL);
}

static TMBJKArray *_JKArrayCreate(id *objects, NSUInteger count, BOOL mutableCollection) {
  NSCParameterAssert((objects != NULL) && (_TMBJKArrayClass != NULL) && (_TMBJKArrayInstanceSize > 0UL));
  TMBJKArray *array = NULL;
  if(TMBJK_EXPECT_T((array = (TMBJKArray *)calloc(1UL, _TMBJKArrayInstanceSize)) != NULL)) { // Directly allocate the TMBJKArray instance via calloc.
    array->isa      = _TMBJKArrayClass;
    if((array = [array init]) == NULL) { return(NULL); }
    array->capacity = count;
    array->count    = count;
    if(TMBJK_EXPECT_F((array->objects = (id *)malloc(sizeof(id) * array->capacity)) == NULL)) { [array autorelease]; return(NULL); }
    memcpy(array->objects, objects, array->capacity * sizeof(id));
    array->mutations = (mutableCollection == NO) ? 0UL : 1UL;
  }
  return(array);
}

// Note: The caller is responsible for -retaining the object that is to be added.
static void _JKArrayInsertObjectAtIndex(TMBJKArray *array, id newObject, NSUInteger objectIndex) {
  NSCParameterAssert((array != NULL) && (array->objects != NULL) && (array->count <= array->capacity) && (objectIndex <= array->count) && (newObject != NULL));
  if(!((array != NULL) && (array->objects != NULL) && (objectIndex <= array->count) && (newObject != NULL))) { [newObject autorelease]; return; }
  if((array->count + 1UL) >= array->capacity) {
    id *newObjects = NULL;
    if((newObjects = (id *)realloc(array->objects, sizeof(id) * (array->capacity + 16UL))) == NULL) { [NSException raise:NSMallocException format:@"Unable to resize objects array."]; }
    array->objects = newObjects;
    array->capacity += 16UL;
    memset(&array->objects[array->count], 0, sizeof(id) * (array->capacity - array->count));
  }
  array->count++;
  if((objectIndex + 1UL) < array->count) { memmove(&array->objects[objectIndex + 1UL], &array->objects[objectIndex], sizeof(id) * ((array->count - 1UL) - objectIndex)); array->objects[objectIndex] = NULL; }
  array->objects[objectIndex] = newObject;
}

// Note: The caller is responsible for -retaining the object that is to be added.
static void _JKArrayReplaceObjectAtIndexWithObject(TMBJKArray *array, NSUInteger objectIndex, id newObject) {
  NSCParameterAssert((array != NULL) && (array->objects != NULL) && (array->count <= array->capacity) && (objectIndex < array->count) && (array->objects[objectIndex] != NULL) && (newObject != NULL));
  if(!((array != NULL) && (array->objects != NULL) && (objectIndex < array->count) && (array->objects[objectIndex] != NULL) && (newObject != NULL))) { [newObject autorelease]; return; }
  CFRelease(array->objects[objectIndex]);
  array->objects[objectIndex] = NULL;
  array->objects[objectIndex] = newObject;
}

static void _JKArrayRemoveObjectAtIndex(TMBJKArray *array, NSUInteger objectIndex) {
  NSCParameterAssert((array != NULL) && (array->objects != NULL) && (array->count > 0UL) && (array->count <= array->capacity) && (objectIndex < array->count) && (array->objects[objectIndex] != NULL));
  if(!((array != NULL) && (array->objects != NULL) && (array->count > 0UL) && (array->count <= array->capacity) && (objectIndex < array->count) && (array->objects[objectIndex] != NULL))) { return; }
  CFRelease(array->objects[objectIndex]);
  array->objects[objectIndex] = NULL;
  if((objectIndex + 1UL) < array->count) { memmove(&array->objects[objectIndex], &array->objects[objectIndex + 1UL], sizeof(id) * ((array->count - 1UL) - objectIndex)); array->objects[array->count - 1UL] = NULL; }
  array->count--;
}

- (void)dealloc
{
  if(TMBJK_EXPECT_T(objects != NULL)) {
    NSUInteger atObject = 0UL;
    for(atObject = 0UL; atObject < count; atObject++) { if(TMBJK_EXPECT_T(objects[atObject] != NULL)) { CFRelease(objects[atObject]); objects[atObject] = NULL; } }
    free(objects); objects = NULL;
  }
  
  [super dealloc];
}

- (NSUInteger)count
{
  NSParameterAssert((objects != NULL) && (count <= capacity));
  return(count);
}

- (void)getObjects:(id *)objectsPtr range:(NSRange)range
{
  NSParameterAssert((objects != NULL) && (count <= capacity));
  if((objectsPtr     == NULL)  && (NSMaxRange(range) > 0UL))   { [NSException raise:NSRangeException format:@"*** -[%@ %@]: pointer to objects array is NULL but range length is %u", NSStringFromClass([self class]), NSStringFromSelector(_cmd), NSMaxRange(range)];        }
  if((range.location >  count) || (NSMaxRange(range) > count)) { [NSException raise:NSRangeException format:@"*** -[%@ %@]: index (%u) beyond bounds (%u)",                          NSStringFromClass([self class]), NSStringFromSelector(_cmd), NSMaxRange(range), count]; }
  memcpy(objectsPtr, objects + range.location, range.length * sizeof(id));
}

- (id)objectAtIndex:(NSUInteger)objectIndex
{
  if(objectIndex >= count) { [NSException raise:NSRangeException format:@"*** -[%@ %@]: index (%u) beyond bounds (%u)", NSStringFromClass([self class]), NSStringFromSelector(_cmd), objectIndex, count]; }
  NSParameterAssert((objects != NULL) && (count <= capacity) && (objects[objectIndex] != NULL));
  return(objects[objectIndex]);
}

- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state objects:(id *)stackbuf count:(NSUInteger)len
{
  NSParameterAssert((state != NULL) && (stackbuf != NULL) && (len > 0UL) && (objects != NULL) && (count <= capacity));
  if(TMBJK_EXPECT_F(state->state == 0UL))   { state->mutationsPtr = (unsigned long *)&mutations; state->itemsPtr = stackbuf; }
  if(TMBJK_EXPECT_F(state->state >= count)) { return(0UL); }
  
  NSUInteger enumeratedCount  = 0UL;
  while(TMBJK_EXPECT_T(enumeratedCount < len) && TMBJK_EXPECT_T(state->state < count)) { NSParameterAssert(objects[state->state] != NULL); stackbuf[enumeratedCount++] = objects[state->state++]; }
  
  return(enumeratedCount);
}

- (void)insertObject:(id)anObject atIndex:(NSUInteger)objectIndex
{
  if(mutations   == 0UL)   { [NSException raise:NSInternalInconsistencyException format:@"*** -[%@ %@]: mutating method sent to immutable object", NSStringFromClass([self class]), NSStringFromSelector(_cmd)]; }
  if(anObject    == NULL)  { [NSException raise:NSInvalidArgumentException       format:@"*** -[%@ %@]: attempt to insert nil",                    NSStringFromClass([self class]), NSStringFromSelector(_cmd)]; }
  if(objectIndex >  count) { [NSException raise:NSRangeException                 format:@"*** -[%@ %@]: index (%u) beyond bounds (%lu)",          NSStringFromClass([self class]), NSStringFromSelector(_cmd), objectIndex, count + 1UL]; }
#ifdef __clang_analyzer__
  [anObject retain]; // Stupid clang analyzer...  Issue #19.
#else
  anObject = [anObject retain];
#endif
  _JKArrayInsertObjectAtIndex(self, anObject, objectIndex);
  mutations = (mutations == NSUIntegerMax) ? 1UL : mutations + 1UL;
}

- (void)removeObjectAtIndex:(NSUInteger)objectIndex
{
  if(mutations   == 0UL)   { [NSException raise:NSInternalInconsistencyException format:@"*** -[%@ %@]: mutating method sent to immutable object", NSStringFromClass([self class]), NSStringFromSelector(_cmd)]; }
  if(objectIndex >= count) { [NSException raise:NSRangeException                 format:@"*** -[%@ %@]: index (%u) beyond bounds (%u)",          NSStringFromClass([self class]), NSStringFromSelector(_cmd), objectIndex, count]; }
  _JKArrayRemoveObjectAtIndex(self, objectIndex);
  mutations = (mutations == NSUIntegerMax) ? 1UL : mutations + 1UL;
}

- (void)replaceObjectAtIndex:(NSUInteger)objectIndex withObject:(id)anObject
{
  if(mutations   == 0UL)   { [NSException raise:NSInternalInconsistencyException format:@"*** -[%@ %@]: mutating method sent to immutable object", NSStringFromClass([self class]), NSStringFromSelector(_cmd)]; }
  if(anObject    == NULL)  { [NSException raise:NSInvalidArgumentException       format:@"*** -[%@ %@]: attempt to insert nil",                    NSStringFromClass([self class]), NSStringFromSelector(_cmd)]; }
  if(objectIndex >= count) { [NSException raise:NSRangeException                 format:@"*** -[%@ %@]: index (%u) beyond bounds (%u)",          NSStringFromClass([self class]), NSStringFromSelector(_cmd), objectIndex, count]; }
#ifdef __clang_analyzer__
  [anObject retain]; // Stupid clang analyzer...  Issue #19.
#else
  anObject = [anObject retain];
#endif
  _JKArrayReplaceObjectAtIndexWithObject(self, objectIndex, anObject);
  mutations = (mutations == NSUIntegerMax) ? 1UL : mutations + 1UL;
}

- (id)copyWithZone:(NSZone *)zone
{
  NSParameterAssert((objects != NULL) && (count <= capacity));
  return((mutations == 0UL) ? [self retain] : [(NSArray *)[NSArray allocWithZone:zone] initWithObjects:objects count:count]);
}

- (id)mutableCopyWithZone:(NSZone *)zone
{
  NSParameterAssert((objects != NULL) && (count <= capacity));
  return([(NSMutableArray *)[NSMutableArray allocWithZone:zone] initWithObjects:objects count:count]);
}

@end


#pragma mark -
@interface TMBJKDictionaryEnumerator : NSEnumerator {
  id         collection;
  NSUInteger nextObject;
}

- (id)initWithJKDictionary:(TMBJKDictionary *)initDictionary;
- (NSArray *)allObjects;
- (id)nextObject;

@end

@implementation TMBJKDictionaryEnumerator

- (id)initWithJKDictionary:(TMBJKDictionary *)initDictionary
{
  NSParameterAssert(initDictionary != NULL);
  if((self = [super init]) == NULL) { return(NULL); }
  if((collection = (id)CFRetain(initDictionary)) == NULL) { [self autorelease]; return(NULL); }
  return(self);
}

- (void)dealloc
{
  if(collection != NULL) { CFRelease(collection); collection = NULL; }
  [super dealloc];
}

- (NSArray *)allObjects
{
  NSParameterAssert(collection != NULL);
  NSUInteger count = [(NSDictionary *)collection count], atObject = 0UL;
  id         objects[count];

  while((objects[atObject] = [self nextObject]) != NULL) { NSParameterAssert(atObject < count); atObject++; }

  return([NSArray arrayWithObjects:objects count:atObject]);
}

- (id)nextObject
{
  NSParameterAssert((collection != NULL) && (_JKDictionaryHashEntry(collection) != NULL));
  TMBJKHashTableEntry *entry        = _JKDictionaryHashEntry(collection);
  NSUInteger        capacity     = _JKDictionaryCapacity(collection);
  id                returnObject = NULL;

  if(entry != NULL) { while((nextObject < capacity) && ((returnObject = entry[nextObject++].key) == NULL)) { /* ... */ } }
  
  return(returnObject);
}

@end

#pragma mark -
@interface TMBJKDictionary : NSMutableDictionary <NSCopying, NSMutableCopying, NSFastEnumeration> {
  NSUInteger count, capacity, mutations;
  TMBJKHashTableEntry *entry;
}
@end

@implementation TMBJKDictionary

+ (id)allocWithZone:(NSZone *)zone
{
#pragma unused(zone)
  [NSException raise:NSInvalidArgumentException format:@"*** - [%@ %@]: The %@ class is private to TMBJSONKit and should not be used in this fashion.", NSStringFromClass([self class]), NSStringFromSelector(_cmd), NSStringFromClass([self class])];
  return(NULL);
}

// These values are taken from Core Foundation CF-550 CFBasicHash.m.  As a bonus, they align very well with our TMBJKHashTableEntry struct too.
static const NSUInteger jk_dictionaryCapacities[] = {
  0UL, 3UL, 7UL, 13UL, 23UL, 41UL, 71UL, 127UL, 191UL, 251UL, 383UL, 631UL, 1087UL, 1723UL,
  2803UL, 4523UL, 7351UL, 11959UL, 19447UL, 31231UL, 50683UL, 81919UL, 132607UL,
  214519UL, 346607UL, 561109UL, 907759UL, 1468927UL, 2376191UL, 3845119UL,
  6221311UL, 10066421UL, 16287743UL, 26354171UL, 42641881UL, 68996069UL,
  111638519UL, 180634607UL, 292272623UL, 472907251UL
};

static NSUInteger _JKDictionaryCapacityForCount(NSUInteger count) {
  NSUInteger bottom = 0UL, top = sizeof(jk_dictionaryCapacities) / sizeof(NSUInteger), mid = 0UL, tableSize = lround(floor((count) * 1.33));
  while(top > bottom) { mid = (top + bottom) / 2UL; if(jk_dictionaryCapacities[mid] < tableSize) { bottom = mid + 1UL; } else { top = mid; } }
  return(jk_dictionaryCapacities[bottom]);
}

static void _JKDictionaryResizeIfNeccessary(TMBJKDictionary *dictionary) {
  NSCParameterAssert((dictionary != NULL) && (dictionary->entry != NULL) && (dictionary->count <= dictionary->capacity));

  NSUInteger capacityForCount = 0UL;
  if(dictionary->capacity < (capacityForCount = _JKDictionaryCapacityForCount(dictionary->count + 1UL))) { // resize
    NSUInteger        oldCapacity = dictionary->capacity;
#ifndef NS_BLOCK_ASSERTIONS
    NSUInteger oldCount = dictionary->count;
#endif
    TMBJKHashTableEntry *oldEntry    = dictionary->entry;
    if(TMBJK_EXPECT_F((dictionary->entry = (TMBJKHashTableEntry *)calloc(1UL, sizeof(TMBJKHashTableEntry) * capacityForCount)) == NULL)) { [NSException raise:NSMallocException format:@"Unable to allocate memory for hash table."]; }
    dictionary->capacity = capacityForCount;
    dictionary->count    = 0UL;
    
    NSUInteger idx = 0UL;
    for(idx = 0UL; idx < oldCapacity; idx++) { if(oldEntry[idx].key != NULL) { _JKDictionaryAddObject(dictionary, oldEntry[idx].keyHash, oldEntry[idx].key, oldEntry[idx].object); oldEntry[idx].keyHash = 0UL; oldEntry[idx].key = NULL; oldEntry[idx].object = NULL; } }
    NSCParameterAssert((oldCount == dictionary->count));
    free(oldEntry); oldEntry = NULL;
  }
}

static TMBJKDictionary *_JKDictionaryCreate(id *keys, NSUInteger *keyHashes, id *objects, NSUInteger count, BOOL mutableCollection) {
  NSCParameterAssert((keys != NULL) && (keyHashes != NULL) && (objects != NULL) && (_TMBJKDictionaryClass != NULL) && (_TMBJKDictionaryInstanceSize > 0UL));
  TMBJKDictionary *dictionary = NULL;
  if(TMBJK_EXPECT_T((dictionary = (TMBJKDictionary *)calloc(1UL, _TMBJKDictionaryInstanceSize)) != NULL)) { // Directly allocate the TMBJKDictionary instance via calloc.
    dictionary->isa      = _TMBJKDictionaryClass;
    if((dictionary = [dictionary init]) == NULL) { return(NULL); }
    dictionary->capacity = _JKDictionaryCapacityForCount(count);
    dictionary->count    = 0UL;
    
    if(TMBJK_EXPECT_F((dictionary->entry = (TMBJKHashTableEntry *)calloc(1UL, sizeof(TMBJKHashTableEntry) * dictionary->capacity)) == NULL)) { [dictionary autorelease]; return(NULL); }

    NSUInteger idx = 0UL;
    for(idx = 0UL; idx < count; idx++) { _JKDictionaryAddObject(dictionary, keyHashes[idx], keys[idx], objects[idx]); }

    dictionary->mutations = (mutableCollection == NO) ? 0UL : 1UL;
  }
  return(dictionary);
}

- (void)dealloc
{
  if(TMBJK_EXPECT_T(entry != NULL)) {
    NSUInteger atEntry = 0UL;
    for(atEntry = 0UL; atEntry < capacity; atEntry++) {
      if(TMBJK_EXPECT_T(entry[atEntry].key    != NULL)) { CFRelease(entry[atEntry].key);    entry[atEntry].key    = NULL; }
      if(TMBJK_EXPECT_T(entry[atEntry].object != NULL)) { CFRelease(entry[atEntry].object); entry[atEntry].object = NULL; }
    }
  
    free(entry); entry = NULL;
  }

  [super dealloc];
}

static TMBJKHashTableEntry *_JKDictionaryHashEntry(TMBJKDictionary *dictionary) {
  NSCParameterAssert(dictionary != NULL);
  return(dictionary->entry);
}

static NSUInteger _JKDictionaryCapacity(TMBJKDictionary *dictionary) {
  NSCParameterAssert(dictionary != NULL);
  return(dictionary->capacity);
}

static void _JKDictionaryRemoveObjectWithEntry(TMBJKDictionary *dictionary, TMBJKHashTableEntry *entry) {
  NSCParameterAssert((dictionary != NULL) && (entry != NULL) && (entry->key != NULL) && (entry->object != NULL) && (dictionary->count > 0UL) && (dictionary->count <= dictionary->capacity));
  CFRelease(entry->key);    entry->key    = NULL;
  CFRelease(entry->object); entry->object = NULL;
  entry->keyHash = 0UL;
  dictionary->count--;
  // In order for certain invariants that are used to speed up the search for a particular key, we need to "re-add" all the entries in the hash table following this entry until we hit a NULL entry.
  NSUInteger removeIdx = entry - dictionary->entry, idx = 0UL;
  NSCParameterAssert((removeIdx < dictionary->capacity));
  for(idx = 0UL; idx < dictionary->capacity; idx++) {
    NSUInteger entryIdx = (removeIdx + idx + 1UL) % dictionary->capacity;
    TMBJKHashTableEntry *atEntry = &dictionary->entry[entryIdx];
    if(atEntry->key == NULL) { break; }
    NSUInteger keyHash = atEntry->keyHash;
    id key = atEntry->key, object = atEntry->object;
    NSCParameterAssert(object != NULL);
    atEntry->keyHash = 0UL;
    atEntry->key     = NULL;
    atEntry->object  = NULL;
    NSUInteger addKeyEntry = keyHash % dictionary->capacity, addIdx = 0UL;
    for(addIdx = 0UL; addIdx < dictionary->capacity; addIdx++) {
      TMBJKHashTableEntry *atAddEntry = &dictionary->entry[((addKeyEntry + addIdx) % dictionary->capacity)];
      if(TMBJK_EXPECT_T(atAddEntry->key == NULL)) { NSCParameterAssert((atAddEntry->keyHash == 0UL) && (atAddEntry->object == NULL)); atAddEntry->key = key; atAddEntry->object = object; atAddEntry->keyHash = keyHash; break; }
    }
  }
}

static void _JKDictionaryAddObject(TMBJKDictionary *dictionary, NSUInteger keyHash, id key, id object) {
  NSCParameterAssert((dictionary != NULL) && (key != NULL) && (object != NULL) && (dictionary->count < dictionary->capacity) && (dictionary->entry != NULL));
  NSUInteger keyEntry = keyHash % dictionary->capacity, idx = 0UL;
  for(idx = 0UL; idx < dictionary->capacity; idx++) {
    NSUInteger entryIdx = (keyEntry + idx) % dictionary->capacity;
    TMBJKHashTableEntry *atEntry = &dictionary->entry[entryIdx];
    if(TMBJK_EXPECT_F(atEntry->keyHash == keyHash) && TMBJK_EXPECT_T(atEntry->key != NULL) && (TMBJK_EXPECT_F(key == atEntry->key) || TMBJK_EXPECT_F(CFEqual(atEntry->key, key)))) { _JKDictionaryRemoveObjectWithEntry(dictionary, atEntry); }
    if(TMBJK_EXPECT_T(atEntry->key == NULL)) { NSCParameterAssert((atEntry->keyHash == 0UL) && (atEntry->object == NULL)); atEntry->key = key; atEntry->object = object; atEntry->keyHash = keyHash; dictionary->count++; return; }
  }

  // We should never get here.  If we do, we -release the key / object because it's our responsibility.
  CFRelease(key);
  CFRelease(object);
}

- (NSUInteger)count
{
  return(count);
}

static TMBJKHashTableEntry *_JKDictionaryHashTableEntryForKey(TMBJKDictionary *dictionary, id aKey) {
  NSCParameterAssert((dictionary != NULL) && (dictionary->entry != NULL) && (dictionary->count <= dictionary->capacity));
  if((aKey == NULL) || (dictionary->capacity == 0UL)) { return(NULL); }
  NSUInteger        keyHash = CFHash(aKey), keyEntry = (keyHash % dictionary->capacity), idx = 0UL;
  TMBJKHashTableEntry *atEntry = NULL;
  for(idx = 0UL; idx < dictionary->capacity; idx++) {
    atEntry = &dictionary->entry[(keyEntry + idx) % dictionary->capacity];
    if(TMBJK_EXPECT_T(atEntry->keyHash == keyHash) && TMBJK_EXPECT_T(atEntry->key != NULL) && ((atEntry->key == aKey) || CFEqual(atEntry->key, aKey))) { NSCParameterAssert(atEntry->object != NULL); return(atEntry); break; }
    if(TMBJK_EXPECT_F(atEntry->key == NULL)) { NSCParameterAssert(atEntry->object == NULL); return(NULL); break; } // If the key was in the table, we would have found it by now.
  }
  return(NULL);
}

- (id)objectForKey:(id)aKey
{
  NSParameterAssert((entry != NULL) && (count <= capacity));
  TMBJKHashTableEntry *entryForKey = _JKDictionaryHashTableEntryForKey(self, aKey);
  return((entryForKey != NULL) ? entryForKey->object : NULL);
}

- (void)getObjects:(id *)objects andKeys:(id *)keys
{
  NSParameterAssert((entry != NULL) && (count <= capacity));
  NSUInteger atEntry = 0UL; NSUInteger arrayIdx = 0UL;
  for(atEntry = 0UL; atEntry < capacity; atEntry++) {
    if(TMBJK_EXPECT_T(entry[atEntry].key != NULL)) {
      NSCParameterAssert((entry[atEntry].object != NULL) && (arrayIdx < count));
      if(TMBJK_EXPECT_T(keys    != NULL)) { keys[arrayIdx]    = entry[atEntry].key;    }
      if(TMBJK_EXPECT_T(objects != NULL)) { objects[arrayIdx] = entry[atEntry].object; }
      arrayIdx++;
    }
  }
}

- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state objects:(id *)stackbuf count:(NSUInteger)len
{
  NSParameterAssert((state != NULL) && (stackbuf != NULL) && (len > 0UL) && (entry != NULL) && (count <= capacity));
  if(TMBJK_EXPECT_F(state->state == 0UL))      { state->mutationsPtr = (unsigned long *)&mutations; state->itemsPtr = stackbuf; }
  if(TMBJK_EXPECT_F(state->state >= capacity)) { return(0UL); }
  
  NSUInteger enumeratedCount  = 0UL;
  while(TMBJK_EXPECT_T(enumeratedCount < len) && TMBJK_EXPECT_T(state->state < capacity)) { if(TMBJK_EXPECT_T(entry[state->state].key != NULL)) { stackbuf[enumeratedCount++] = entry[state->state].key; } state->state++; }
    
  return(enumeratedCount);
}

- (NSEnumerator *)keyEnumerator
{
  return([[[TMBJKDictionaryEnumerator alloc] initWithJKDictionary:self] autorelease]);
}

- (void)setObject:(id)anObject forKey:(id)aKey
{
  if(mutations == 0UL)  { [NSException raise:NSInternalInconsistencyException format:@"*** -[%@ %@]: mutating method sent to immutable object", NSStringFromClass([self class]), NSStringFromSelector(_cmd)];       }
  if(aKey      == NULL) { [NSException raise:NSInvalidArgumentException       format:@"*** -[%@ %@]: attempt to insert nil key",                NSStringFromClass([self class]), NSStringFromSelector(_cmd)];       }
  if(anObject  == NULL) { [NSException raise:NSInvalidArgumentException       format:@"*** -[%@ %@]: attempt to insert nil value (key: %@)",    NSStringFromClass([self class]), NSStringFromSelector(_cmd), aKey]; }
  
  _JKDictionaryResizeIfNeccessary(self);
#ifndef __clang_analyzer__
  aKey     = [aKey     copy];   // Why on earth would clang complain that this -copy "might leak", 
  anObject = [anObject retain]; // but this -retain doesn't!?
#endif // __clang_analyzer__
  _JKDictionaryAddObject(self, CFHash(aKey), aKey, anObject);
  mutations = (mutations == NSUIntegerMax) ? 1UL : mutations + 1UL;
}

- (void)removeObjectForKey:(id)aKey
{
  if(mutations == 0UL)  { [NSException raise:NSInternalInconsistencyException format:@"*** -[%@ %@]: mutating method sent to immutable object", NSStringFromClass([self class]), NSStringFromSelector(_cmd)]; }
  if(aKey      == NULL) { [NSException raise:NSInvalidArgumentException       format:@"*** -[%@ %@]: attempt to remove nil key",                NSStringFromClass([self class]), NSStringFromSelector(_cmd)]; }
  TMBJKHashTableEntry *entryForKey = _JKDictionaryHashTableEntryForKey(self, aKey);
  if(entryForKey != NULL) {
    _JKDictionaryRemoveObjectWithEntry(self, entryForKey);
    mutations = (mutations == NSUIntegerMax) ? 1UL : mutations + 1UL;
  }
}

- (id)copyWithZone:(NSZone *)zone
{
  NSParameterAssert((entry != NULL) && (count <= capacity));
  return((mutations == 0UL) ? [self retain] : [[NSDictionary allocWithZone:zone] initWithDictionary:self]);
}

- (id)mutableCopyWithZone:(NSZone *)zone
{
  NSParameterAssert((entry != NULL) && (count <= capacity));
  return([[NSMutableDictionary allocWithZone:zone] initWithDictionary:self]);
}

@end



#pragma mark -

TMBJK_STATIC_INLINE size_t jk_min(size_t a, size_t b) { return((a < b) ? a : b); }
TMBJK_STATIC_INLINE size_t jk_max(size_t a, size_t b) { return((a > b) ? a : b); }

TMBJK_STATIC_INLINE TMBJKHash jk_calculateHash(TMBJKHash currentHash, unsigned char c) { return((((currentHash << 5) + currentHash) + (c - 29)) ^ (currentHash >> 19)); }


static void jk_error(TMBJKParseState *parseState, NSString *format, ...) {
  NSCParameterAssert((parseState != NULL) && (format != NULL));

  va_list varArgsList;
  va_start(varArgsList, format);
  NSString *formatString = [[[NSString alloc] initWithFormat:format arguments:varArgsList] autorelease];
  va_end(varArgsList);

#if 0
  const unsigned char *lineStart      = parseState->stringBuffer.bytes.ptr + parseState->lineStartIndex;
  const unsigned char *lineEnd        = lineStart;
  const unsigned char *atCharacterPtr = NULL;

  for(atCharacterPtr = lineStart; atCharacterPtr < TMBJK_END_STRING_PTR(parseState); atCharacterPtr++) { lineEnd = atCharacterPtr; if(jk_parse_is_newline(parseState, atCharacterPtr)) { break; } }

  NSString *lineString = @"", *carretString = @"";
  if(lineStart < TMBJK_END_STRING_PTR(parseState)) {
    lineString   = [[[NSString alloc] initWithBytes:lineStart length:(lineEnd - lineStart) encoding:NSUTF8StringEncoding] autorelease];
    carretString = [NSString stringWithFormat:@"%*.*s^", (int)(parseState->atIndex - parseState->lineStartIndex), (int)(parseState->atIndex - parseState->lineStartIndex), " "];
  }
#endif

  if(parseState->error == NULL) {
    parseState->error = [NSError errorWithDomain:@"JKErrorDomain" code:-1L userInfo:
                                   [NSDictionary dictionaryWithObjectsAndKeys:
                                                                              formatString,                                             NSLocalizedDescriptionKey,
                                                                              [NSNumber numberWithUnsignedLong:parseState->atIndex],    @"JKAtIndexKey",
                                                                              [NSNumber numberWithUnsignedLong:parseState->lineNumber], @"JKLineNumberKey",
                                                 //lineString,   @"JKErrorLine0Key",
                                                 //carretString, @"JKErrorLine1Key",
                                                                              NULL]];
  }
}

#pragma mark -
#pragma mark Buffer and Object Stack management functions

static void jk_managedBuffer_release(TMBJKManagedBuffer *managedBuffer) {
  if((managedBuffer->flags & TMBJKManagedBufferMustFree)) {
    if(managedBuffer->bytes.ptr != NULL) { free(managedBuffer->bytes.ptr); managedBuffer->bytes.ptr = NULL; }
    managedBuffer->flags &= ~TMBJKManagedBufferMustFree;
  }

  managedBuffer->bytes.ptr     = NULL;
  managedBuffer->bytes.length  = 0UL;
  managedBuffer->flags        &= ~TMBJKManagedBufferLocationMask;
}

static void jk_managedBuffer_setToStackBuffer(TMBJKManagedBuffer *managedBuffer, unsigned char *ptr, size_t length) {
  jk_managedBuffer_release(managedBuffer);
  managedBuffer->bytes.ptr     = ptr;
  managedBuffer->bytes.length  = length;
  managedBuffer->flags         = (managedBuffer->flags & ~TMBJKManagedBufferLocationMask) | TMBJKManagedBufferOnStack;
}

static unsigned char *jk_managedBuffer_resize(TMBJKManagedBuffer *managedBuffer, size_t newSize) {
  size_t roundedUpNewSize = newSize;

  if(managedBuffer->roundSizeUpToMultipleOf > 0UL) { roundedUpNewSize = newSize + ((managedBuffer->roundSizeUpToMultipleOf - (newSize % managedBuffer->roundSizeUpToMultipleOf)) % managedBuffer->roundSizeUpToMultipleOf); }

  if((roundedUpNewSize != managedBuffer->bytes.length) && (roundedUpNewSize > managedBuffer->bytes.length)) {
    if((managedBuffer->flags & TMBJKManagedBufferLocationMask) == TMBJKManagedBufferOnStack) {
      NSCParameterAssert((managedBuffer->flags & TMBJKManagedBufferMustFree) == 0);
      unsigned char *newBuffer = NULL, *oldBuffer = managedBuffer->bytes.ptr;
      
      if((newBuffer = (unsigned char *)malloc(roundedUpNewSize)) == NULL) { return(NULL); }
      memcpy(newBuffer, oldBuffer, jk_min(managedBuffer->bytes.length, roundedUpNewSize));
      managedBuffer->flags        = (managedBuffer->flags & ~TMBJKManagedBufferLocationMask) | (TMBJKManagedBufferOnHeap | TMBJKManagedBufferMustFree);
      managedBuffer->bytes.ptr    = newBuffer;
      managedBuffer->bytes.length = roundedUpNewSize;
    } else {
      NSCParameterAssert(((managedBuffer->flags & TMBJKManagedBufferMustFree) != 0) && ((managedBuffer->flags & TMBJKManagedBufferLocationMask) == TMBJKManagedBufferOnHeap));
      if((managedBuffer->bytes.ptr = (unsigned char *)reallocf(managedBuffer->bytes.ptr, roundedUpNewSize)) == NULL) { return(NULL); }
      managedBuffer->bytes.length = roundedUpNewSize;
    }
  }

  return(managedBuffer->bytes.ptr);
}



static void jk_objectStack_release(TMBJKObjectStack *objectStack) {
  NSCParameterAssert(objectStack != NULL);

  NSCParameterAssert(objectStack->index <= objectStack->count);
  size_t atIndex = 0UL;
  for(atIndex = 0UL; atIndex < objectStack->index; atIndex++) {
    if(objectStack->objects[atIndex] != NULL) { CFRelease(objectStack->objects[atIndex]); objectStack->objects[atIndex] = NULL; }
    if(objectStack->keys[atIndex]    != NULL) { CFRelease(objectStack->keys[atIndex]);    objectStack->keys[atIndex]    = NULL; }
  }
  objectStack->index = 0UL;

  if(objectStack->flags & TMBJKObjectStackMustFree) {
    NSCParameterAssert((objectStack->flags & TMBJKObjectStackLocationMask) == TMBJKObjectStackOnHeap);
    if(objectStack->objects  != NULL) { free(objectStack->objects);  objectStack->objects  = NULL; }
    if(objectStack->keys     != NULL) { free(objectStack->keys);     objectStack->keys     = NULL; }
    if(objectStack->cfHashes != NULL) { free(objectStack->cfHashes); objectStack->cfHashes = NULL; }
    objectStack->flags &= ~TMBJKObjectStackMustFree;
  }

  objectStack->objects  = NULL;
  objectStack->keys     = NULL;
  objectStack->cfHashes = NULL;

  objectStack->count    = 0UL;
  objectStack->flags   &= ~TMBJKObjectStackLocationMask;
}

static void jk_objectStack_setToStackBuffer(TMBJKObjectStack *objectStack, void **objects, void **keys, CFHashCode *cfHashes, size_t count) {
  NSCParameterAssert((objectStack != NULL) && (objects != NULL) && (keys != NULL) && (cfHashes != NULL) && (count > 0UL));
  jk_objectStack_release(objectStack);
  objectStack->objects  = objects;
  objectStack->keys     = keys;
  objectStack->cfHashes = cfHashes;
  objectStack->count    = count;
  objectStack->flags    = (objectStack->flags & ~TMBJKObjectStackLocationMask) | TMBJKObjectStackOnStack;
#ifndef NS_BLOCK_ASSERTIONS
  size_t idx;
  for(idx = 0UL; idx < objectStack->count; idx++) { objectStack->objects[idx] = NULL; objectStack->keys[idx] = NULL; objectStack->cfHashes[idx] = 0UL; }
#endif
}

static int jk_objectStack_resize(TMBJKObjectStack *objectStack, size_t newCount) {
  size_t roundedUpNewCount = newCount;
  int    returnCode = 0;

  void       **newObjects  = NULL, **newKeys = NULL;
  CFHashCode  *newCFHashes = NULL;

  if(objectStack->roundSizeUpToMultipleOf > 0UL) { roundedUpNewCount = newCount + ((objectStack->roundSizeUpToMultipleOf - (newCount % objectStack->roundSizeUpToMultipleOf)) % objectStack->roundSizeUpToMultipleOf); }

  if((roundedUpNewCount != objectStack->count) && (roundedUpNewCount > objectStack->count)) {
    if((objectStack->flags & TMBJKObjectStackLocationMask) == TMBJKObjectStackOnStack) {
      NSCParameterAssert((objectStack->flags & TMBJKObjectStackMustFree) == 0);

      if((newObjects  = (void **     )calloc(1UL, roundedUpNewCount * sizeof(void *    ))) == NULL) { returnCode = 1; goto errorExit; }
      memcpy(newObjects, objectStack->objects,   jk_min(objectStack->count, roundedUpNewCount) * sizeof(void *));
      if((newKeys     = (void **     )calloc(1UL, roundedUpNewCount * sizeof(void *    ))) == NULL) { returnCode = 1; goto errorExit; }
      memcpy(newKeys,     objectStack->keys,     jk_min(objectStack->count, roundedUpNewCount) * sizeof(void *));

      if((newCFHashes = (CFHashCode *)calloc(1UL, roundedUpNewCount * sizeof(CFHashCode))) == NULL) { returnCode = 1; goto errorExit; }
      memcpy(newCFHashes, objectStack->cfHashes, jk_min(objectStack->count, roundedUpNewCount) * sizeof(CFHashCode));

      objectStack->flags    = (objectStack->flags & ~TMBJKObjectStackLocationMask) | (TMBJKObjectStackOnHeap | TMBJKObjectStackMustFree);
      objectStack->objects  = newObjects;  newObjects  = NULL;
      objectStack->keys     = newKeys;     newKeys     = NULL;
      objectStack->cfHashes = newCFHashes; newCFHashes = NULL;
      objectStack->count    = roundedUpNewCount;
    } else {
      NSCParameterAssert(((objectStack->flags & TMBJKObjectStackMustFree) != 0) && ((objectStack->flags & TMBJKObjectStackLocationMask) == TMBJKObjectStackOnHeap));
      if((newObjects  = (void  **    )realloc(objectStack->objects,  roundedUpNewCount * sizeof(void *    ))) != NULL) { objectStack->objects  = newObjects;  newObjects  = NULL; } else { returnCode = 1; goto errorExit; }
      if((newKeys     = (void  **    )realloc(objectStack->keys,     roundedUpNewCount * sizeof(void *    ))) != NULL) { objectStack->keys     = newKeys;     newKeys     = NULL; } else { returnCode = 1; goto errorExit; }
      if((newCFHashes = (CFHashCode *)realloc(objectStack->cfHashes, roundedUpNewCount * sizeof(CFHashCode))) != NULL) { objectStack->cfHashes = newCFHashes; newCFHashes = NULL; } else { returnCode = 1; goto errorExit; }

#ifndef NS_BLOCK_ASSERTIONS
      size_t idx;
      for(idx = objectStack->count; idx < roundedUpNewCount; idx++) { objectStack->objects[idx] = NULL; objectStack->keys[idx] = NULL; objectStack->cfHashes[idx] = 0UL; }
#endif
      objectStack->count = roundedUpNewCount;
    }
  }

 errorExit:
  if(newObjects  != NULL) { free(newObjects);  newObjects  = NULL; }
  if(newKeys     != NULL) { free(newKeys);     newKeys     = NULL; }
  if(newCFHashes != NULL) { free(newCFHashes); newCFHashes = NULL; }

  return(returnCode);
}

////////////
#pragma mark -
#pragma mark Unicode related functions

TMBJK_STATIC_INLINE ConversionResult isValidCodePoint(UTF32 *u32CodePoint) {
  ConversionResult result = conversionOK;
  UTF32            ch     = *u32CodePoint;

  if(TMBJK_EXPECT_F(ch >= UNI_SUR_HIGH_START) && (TMBJK_EXPECT_T(ch <= UNI_SUR_LOW_END)))                                                        { result = sourceIllegal; ch = UNI_REPLACEMENT_CHAR; goto finished; }
  if(TMBJK_EXPECT_F(ch >= 0xFDD0U) && (TMBJK_EXPECT_F(ch <= 0xFDEFU) || TMBJK_EXPECT_F((ch & 0xFFFEU) == 0xFFFEU)) && TMBJK_EXPECT_T(ch <= 0x10FFFFU)) { result = sourceIllegal; ch = UNI_REPLACEMENT_CHAR; goto finished; }
  if(TMBJK_EXPECT_F(ch == 0U))                                                                                                                { result = sourceIllegal; ch = UNI_REPLACEMENT_CHAR; goto finished; }

 finished:
  *u32CodePoint = ch;
  return(result);
}


static int isLegalUTF8(const UTF8 *source, size_t length) {
  const UTF8 *srcptr = source + length;
  UTF8 a;

  switch(length) {
    default: return(0); // Everything else falls through when "true"...
    case 4: if(TMBJK_EXPECT_F(((a = (*--srcptr)) < 0x80) || (a > 0xBF))) { return(0); }
    case 3: if(TMBJK_EXPECT_F(((a = (*--srcptr)) < 0x80) || (a > 0xBF))) { return(0); }
    case 2: if(TMBJK_EXPECT_F( (a = (*--srcptr)) > 0xBF               )) { return(0); }
      
      switch(*source) { // no fall-through in this inner switch
        case 0xE0: if(TMBJK_EXPECT_F(a < 0xA0)) { return(0); } break;
        case 0xED: if(TMBJK_EXPECT_F(a > 0x9F)) { return(0); } break;
        case 0xF0: if(TMBJK_EXPECT_F(a < 0x90)) { return(0); } break;
        case 0xF4: if(TMBJK_EXPECT_F(a > 0x8F)) { return(0); } break;
        default:   if(TMBJK_EXPECT_F(a < 0x80)) { return(0); }
      }
      
    case 1: if(TMBJK_EXPECT_F((TMBJK_EXPECT_T(*source < 0xC2)) && TMBJK_EXPECT_F(*source >= 0x80))) { return(0); }
  }

  if(TMBJK_EXPECT_F(*source > 0xF4)) { return(0); }

  return(1);
}

static ConversionResult ConvertSingleCodePointInUTF8(const UTF8 *sourceStart, const UTF8 *sourceEnd, UTF8 const **nextUTF8, UTF32 *convertedUTF32) {
  ConversionResult result = conversionOK;
  const UTF8 *source = sourceStart;
  UTF32 ch = 0UL;

#if !defined(JK_FAST_TRAILING_BYTES)
  unsigned short extraBytesToRead = trailingBytesForUTF8[*source];
#else
  unsigned short extraBytesToRead = __builtin_clz(((*source)^0xff) << 25);
#endif

  if(TMBJK_EXPECT_F((source + extraBytesToRead + 1) > sourceEnd) || TMBJK_EXPECT_F(!isLegalUTF8(source, extraBytesToRead + 1))) {
    source++;
    while((source < sourceEnd) && (((*source) & 0xc0) == 0x80) && ((source - sourceStart) < (extraBytesToRead + 1))) { source++; } 
    NSCParameterAssert(source <= sourceEnd);
    result = ((source < sourceEnd) && (((*source) & 0xc0) != 0x80)) ? sourceIllegal : ((sourceStart + extraBytesToRead + 1) > sourceEnd) ? sourceExhausted : sourceIllegal;
    ch = UNI_REPLACEMENT_CHAR;
    goto finished;
  }

  switch(extraBytesToRead) { // The cases all fall through.
    case 5: ch += *source++; ch <<= 6;
    case 4: ch += *source++; ch <<= 6;
    case 3: ch += *source++; ch <<= 6;
    case 2: ch += *source++; ch <<= 6;
    case 1: ch += *source++; ch <<= 6;
    case 0: ch += *source++;
  }
  ch -= offsetsFromUTF8[extraBytesToRead];

  result = isValidCodePoint(&ch);
  
 finished:
  *nextUTF8       = source;
  *convertedUTF32 = ch;
  
  return(result);
}


static ConversionResult ConvertUTF32toUTF8 (UTF32 u32CodePoint, UTF8 **targetStart, UTF8 *targetEnd) {
  const UTF32       byteMask     = 0xBF, byteMark = 0x80;
  ConversionResult  result       = conversionOK;
  UTF8             *target       = *targetStart;
  UTF32             ch           = u32CodePoint;
  unsigned short    bytesToWrite = 0;

  result = isValidCodePoint(&ch);

  // Figure out how many bytes the result will require. Turn any illegally large UTF32 things (> Plane 17) into replacement chars.
       if(ch < (UTF32)0x80)          { bytesToWrite = 1; }
  else if(ch < (UTF32)0x800)         { bytesToWrite = 2; }
  else if(ch < (UTF32)0x10000)       { bytesToWrite = 3; }
  else if(ch <= UNI_MAX_LEGAL_UTF32) { bytesToWrite = 4; }
  else {                               bytesToWrite = 3; ch = UNI_REPLACEMENT_CHAR; result = sourceIllegal; }
        
  target += bytesToWrite;
  if (target > targetEnd) { target -= bytesToWrite; result = targetExhausted; goto finished; }

  switch (bytesToWrite) { // note: everything falls through.
    case 4: *--target = (UTF8)((ch | byteMark) & byteMask); ch >>= 6;
    case 3: *--target = (UTF8)((ch | byteMark) & byteMask); ch >>= 6;
    case 2: *--target = (UTF8)((ch | byteMark) & byteMask); ch >>= 6;
    case 1: *--target = (UTF8) (ch | firstByteMark[bytesToWrite]);
  }

  target += bytesToWrite;

 finished:
  *targetStart = target;
  return(result);
}

TMBJK_STATIC_INLINE int jk_string_add_unicodeCodePoint(TMBJKParseState *parseState, uint32_t unicodeCodePoint, size_t *tokenBufferIdx, TMBJKHash *stringHash) {
  UTF8             *u8s = &parseState->token.tokenBuffer.bytes.ptr[*tokenBufferIdx];
  ConversionResult  result;

  if((result = ConvertUTF32toUTF8(unicodeCodePoint, &u8s, (parseState->token.tokenBuffer.bytes.ptr + parseState->token.tokenBuffer.bytes.length))) != conversionOK) { if(result == targetExhausted) { return(1); } }
  size_t utf8len = u8s - &parseState->token.tokenBuffer.bytes.ptr[*tokenBufferIdx], nextIdx = (*tokenBufferIdx) + utf8len;
  
  while(*tokenBufferIdx < nextIdx) { *stringHash = jk_calculateHash(*stringHash, parseState->token.tokenBuffer.bytes.ptr[(*tokenBufferIdx)++]); }

  return(0);
}

////////////
#pragma mark -
#pragma mark Decoding / parsing / deserializing functions

static int jk_parse_string(TMBJKParseState *parseState) {
  NSCParameterAssert((parseState != NULL) && (TMBJK_AT_STRING_PTR(parseState) <= TMBJK_END_STRING_PTR(parseState)));
  const unsigned char *stringStart       = TMBJK_AT_STRING_PTR(parseState) + 1;
  const unsigned char *endOfBuffer       = TMBJK_END_STRING_PTR(parseState);
  const unsigned char *atStringCharacter = stringStart;
  unsigned char       *tokenBuffer       = parseState->token.tokenBuffer.bytes.ptr;
  size_t               tokenStartIndex   = parseState->atIndex;
  size_t               tokenBufferIdx    = 0UL;

  int      onlySimpleString        = 1,  stringState     = TMBJSONStringStateStart;
  uint16_t escapedUnicode1         = 0U, escapedUnicode2 = 0U;
  uint32_t escapedUnicodeCodePoint = 0U;
  TMBJKHash   stringHash              = TMBJK_HASH_INIT;
    
  while(1) {
    unsigned long currentChar;

    if(TMBJK_EXPECT_F(atStringCharacter == endOfBuffer)) { /* XXX Add error message */ stringState = TMBJSONStringStateError; goto finishedParsing; }
    
    if(TMBJK_EXPECT_F((currentChar = *atStringCharacter++) >= 0x80UL)) {
      const unsigned char *nextValidCharacter = NULL;
      UTF32                u32ch              = 0U;
      ConversionResult     result;

      if(TMBJK_EXPECT_F((result = ConvertSingleCodePointInUTF8(atStringCharacter - 1, endOfBuffer, (UTF8 const **)&nextValidCharacter, &u32ch)) != conversionOK)) { goto switchToSlowPath; }
      stringHash = jk_calculateHash(stringHash, currentChar);
      while(atStringCharacter < nextValidCharacter) { NSCParameterAssert(TMBJK_AT_STRING_PTR(parseState) <= TMBJK_END_STRING_PTR(parseState)); stringHash = jk_calculateHash(stringHash, *atStringCharacter++); }
      continue;
    } else {
      if(TMBJK_EXPECT_F(currentChar == (unsigned long)'"')) { stringState = TMBJSONStringStateFinished; goto finishedParsing; }

      if(TMBJK_EXPECT_F(currentChar == (unsigned long)'\\')) {
      switchToSlowPath:
        onlySimpleString = 0;
        stringState      = TMBJSONStringStateParsing;
        tokenBufferIdx   = (atStringCharacter - stringStart) - 1L;
        if(TMBJK_EXPECT_F((tokenBufferIdx + 16UL) > parseState->token.tokenBuffer.bytes.length)) { if((tokenBuffer = jk_managedBuffer_resize(&parseState->token.tokenBuffer, tokenBufferIdx + 1024UL)) == NULL) { jk_error(parseState, @"Internal error: Unable to resize temporary buffer. %@ line #%ld", [NSString stringWithUTF8String:__FILE__], (long)__LINE__); stringState = TMBJSONStringStateError; goto finishedParsing; } }
        memcpy(tokenBuffer, stringStart, tokenBufferIdx);
        goto slowMatch;
      }

      if(TMBJK_EXPECT_F(currentChar < 0x20UL)) { jk_error(parseState, @"Invalid character < 0x20 found in string: 0x%2.2x.", currentChar); stringState = TMBJSONStringStateError; goto finishedParsing; }

      stringHash = jk_calculateHash(stringHash, currentChar);
    }
  }

 slowMatch:

  for(atStringCharacter = (stringStart + ((atStringCharacter - stringStart) - 1L)); (atStringCharacter < endOfBuffer) && (tokenBufferIdx < parseState->token.tokenBuffer.bytes.length); atStringCharacter++) {
    if((tokenBufferIdx + 16UL) > parseState->token.tokenBuffer.bytes.length) { if((tokenBuffer = jk_managedBuffer_resize(&parseState->token.tokenBuffer, tokenBufferIdx + 1024UL)) == NULL) { jk_error(parseState, @"Internal error: Unable to resize temporary buffer. %@ line #%ld", [NSString stringWithUTF8String:__FILE__], (long)__LINE__); stringState = TMBJSONStringStateError; goto finishedParsing; } }

    NSCParameterAssert(tokenBufferIdx < parseState->token.tokenBuffer.bytes.length);

    unsigned long currentChar = (*atStringCharacter), escapedChar;

    if(TMBJK_EXPECT_T(stringState == TMBJSONStringStateParsing)) {
      if(TMBJK_EXPECT_T(currentChar >= 0x20UL)) {
        if(TMBJK_EXPECT_T(currentChar < (unsigned long)0x80)) { // Not a UTF8 sequence
          if(TMBJK_EXPECT_F(currentChar == (unsigned long)'"'))  { stringState = TMBJSONStringStateFinished; atStringCharacter++; goto finishedParsing; }
          if(TMBJK_EXPECT_F(currentChar == (unsigned long)'\\')) { stringState = TMBJSONStringStateEscape; continue; }
          stringHash = jk_calculateHash(stringHash, currentChar);
          tokenBuffer[tokenBufferIdx++] = currentChar;
          continue;
        } else { // UTF8 sequence
          const unsigned char *nextValidCharacter = NULL;
          UTF32                u32ch              = 0U;
          ConversionResult     result;
          
          if(TMBJK_EXPECT_F((result = ConvertSingleCodePointInUTF8(atStringCharacter, endOfBuffer, (UTF8 const **)&nextValidCharacter, &u32ch)) != conversionOK)) {
            if((result == sourceIllegal) && ((parseState->parseOptionFlags & TMBJKParseOptionLooseUnicode) == 0)) { jk_error(parseState, @"Illegal UTF8 sequence found in \"\" string.");              stringState = TMBJSONStringStateError; goto finishedParsing; }
            if(result == sourceExhausted)                                                                      { jk_error(parseState, @"End of buffer reached while parsing UTF8 in \"\" string."); stringState = TMBJSONStringStateError; goto finishedParsing; }
            if(jk_string_add_unicodeCodePoint(parseState, u32ch, &tokenBufferIdx, &stringHash))                { jk_error(parseState, @"Internal error: Unable to add UTF8 sequence to internal string buffer. %@ line #%ld", [NSString stringWithUTF8String:__FILE__], (long)__LINE__); stringState = TMBJSONStringStateError; goto finishedParsing; }
            atStringCharacter = nextValidCharacter - 1;
            continue;
          } else {
            while(atStringCharacter < nextValidCharacter) { tokenBuffer[tokenBufferIdx++] = *atStringCharacter; stringHash = jk_calculateHash(stringHash, *atStringCharacter++); }
            atStringCharacter--;
            continue;
          }
        }
      } else { // currentChar < 0x20
        jk_error(parseState, @"Invalid character < 0x20 found in string: 0x%2.2x.", currentChar); stringState = TMBJSONStringStateError; goto finishedParsing;
      }

    } else { // stringState != TMBJSONStringStateParsing
      int isSurrogate = 1;

      switch(stringState) {
        case TMBJSONStringStateEscape:
          switch(currentChar) {
            case 'u': escapedUnicode1 = 0U; escapedUnicode2 = 0U; escapedUnicodeCodePoint = 0U; stringState = TMBJSONStringStateEscapedUnicode1; break;

            case 'b':  escapedChar = '\b'; goto parsedEscapedChar;
            case 'f':  escapedChar = '\f'; goto parsedEscapedChar;
            case 'n':  escapedChar = '\n'; goto parsedEscapedChar;
            case 'r':  escapedChar = '\r'; goto parsedEscapedChar;
            case 't':  escapedChar = '\t'; goto parsedEscapedChar;
            case '\\': escapedChar = '\\'; goto parsedEscapedChar;
            case '/':  escapedChar = '/';  goto parsedEscapedChar;
            case '"':  escapedChar = '"';  goto parsedEscapedChar;
              
            parsedEscapedChar:
              stringState = TMBJSONStringStateParsing;
              stringHash  = jk_calculateHash(stringHash, escapedChar);
              tokenBuffer[tokenBufferIdx++] = escapedChar;
              break;
              
            default: jk_error(parseState, @"Invalid escape sequence found in \"\" string."); stringState = TMBJSONStringStateError; goto finishedParsing; break;
          }
          break;

        case TMBJSONStringStateEscapedUnicode1:
        case TMBJSONStringStateEscapedUnicode2:
        case TMBJSONStringStateEscapedUnicode3:
        case TMBJSONStringStateEscapedUnicode4:           isSurrogate = 0;
        case TMBJSONStringStateEscapedUnicodeSurrogate1:
        case TMBJSONStringStateEscapedUnicodeSurrogate2:
        case TMBJSONStringStateEscapedUnicodeSurrogate3:
        case TMBJSONStringStateEscapedUnicodeSurrogate4:
          {
            uint16_t hexValue = 0U;

            switch(currentChar) {
              case '0' ... '9': hexValue =  currentChar - '0';        goto parsedHex;
              case 'a' ... 'f': hexValue = (currentChar - 'a') + 10U; goto parsedHex;
              case 'A' ... 'F': hexValue = (currentChar - 'A') + 10U; goto parsedHex;
                
              parsedHex:
              if(!isSurrogate) { escapedUnicode1 = (escapedUnicode1 << 4) | hexValue; } else { escapedUnicode2 = (escapedUnicode2 << 4) | hexValue; }
                
              if(stringState == TMBJSONStringStateEscapedUnicode4) {
                if(((escapedUnicode1 >= 0xD800U) && (escapedUnicode1 < 0xE000U))) {
                  if((escapedUnicode1 >= 0xD800U) && (escapedUnicode1 < 0xDC00U)) { stringState = TMBJSONStringStateEscapedNeedEscapeForSurrogate; }
                  else if((escapedUnicode1 >= 0xDC00U) && (escapedUnicode1 < 0xE000U)) { 
                    if((parseState->parseOptionFlags & TMBJKParseOptionLooseUnicode)) { escapedUnicodeCodePoint = UNI_REPLACEMENT_CHAR; }
                    else { jk_error(parseState, @"Illegal \\u Unicode escape sequence."); stringState = TMBJSONStringStateError; goto finishedParsing; }
                  }
                }
                else { escapedUnicodeCodePoint = escapedUnicode1; }
              }

              if(stringState == TMBJSONStringStateEscapedUnicodeSurrogate4) {
                if((escapedUnicode2 < 0xdc00) || (escapedUnicode2 > 0xdfff)) {
                  if((parseState->parseOptionFlags & TMBJKParseOptionLooseUnicode)) { escapedUnicodeCodePoint = UNI_REPLACEMENT_CHAR; }
                  else { jk_error(parseState, @"Illegal \\u Unicode escape sequence."); stringState = TMBJSONStringStateError; goto finishedParsing; }
                }
                else { escapedUnicodeCodePoint = ((escapedUnicode1 - 0xd800) * 0x400) + (escapedUnicode2 - 0xdc00) + 0x10000; }
              }
                
              if((stringState == TMBJSONStringStateEscapedUnicode4) || (stringState == TMBJSONStringStateEscapedUnicodeSurrogate4)) { 
                if((isValidCodePoint(&escapedUnicodeCodePoint) == sourceIllegal) && ((parseState->parseOptionFlags & TMBJKParseOptionLooseUnicode) == 0)) { jk_error(parseState, @"Illegal \\u Unicode escape sequence."); stringState = TMBJSONStringStateError; goto finishedParsing; }
                stringState = TMBJSONStringStateParsing;
                if(jk_string_add_unicodeCodePoint(parseState, escapedUnicodeCodePoint, &tokenBufferIdx, &stringHash)) { jk_error(parseState, @"Internal error: Unable to add UTF8 sequence to internal string buffer. %@ line #%ld", [NSString stringWithUTF8String:__FILE__], (long)__LINE__); stringState = TMBJSONStringStateError; goto finishedParsing; }
              }
              else if((stringState >= TMBJSONStringStateEscapedUnicode1) && (stringState <= TMBJSONStringStateEscapedUnicodeSurrogate4)) { stringState++; }
              break;

              default: jk_error(parseState, @"Unexpected character found in \\u Unicode escape sequence.  Found '%c', expected [0-9a-fA-F].", currentChar); stringState = TMBJSONStringStateError; goto finishedParsing; break;
            }
          }
          break;

        case TMBJSONStringStateEscapedNeedEscapeForSurrogate:
          if(currentChar == '\\') { stringState = TMBJSONStringStateEscapedNeedEscapedUForSurrogate; }
          else { 
            if((parseState->parseOptionFlags & TMBJKParseOptionLooseUnicode) == 0) { jk_error(parseState, @"Required a second \\u Unicode escape sequence following a surrogate \\u Unicode escape sequence."); stringState = TMBJSONStringStateError; goto finishedParsing; }
            else { stringState = TMBJSONStringStateParsing; atStringCharacter--;    if(jk_string_add_unicodeCodePoint(parseState, UNI_REPLACEMENT_CHAR, &tokenBufferIdx, &stringHash)) { jk_error(parseState, @"Internal error: Unable to add UTF8 sequence to internal string buffer. %@ line #%ld", [NSString stringWithUTF8String:__FILE__], (long)__LINE__); stringState = TMBJSONStringStateError; goto finishedParsing; } }
          }
          break;

        case TMBJSONStringStateEscapedNeedEscapedUForSurrogate:
          if(currentChar == 'u') { stringState = TMBJSONStringStateEscapedUnicodeSurrogate1; }
          else { 
            if((parseState->parseOptionFlags & TMBJKParseOptionLooseUnicode) == 0) { jk_error(parseState, @"Required a second \\u Unicode escape sequence following a surrogate \\u Unicode escape sequence."); stringState = TMBJSONStringStateError; goto finishedParsing; }
            else { stringState = TMBJSONStringStateParsing; atStringCharacter -= 2; if(jk_string_add_unicodeCodePoint(parseState, UNI_REPLACEMENT_CHAR, &tokenBufferIdx, &stringHash)) { jk_error(parseState, @"Internal error: Unable to add UTF8 sequence to internal string buffer. %@ line #%ld", [NSString stringWithUTF8String:__FILE__], (long)__LINE__); stringState = TMBJSONStringStateError; goto finishedParsing; } }
          }
          break;

        default: jk_error(parseState, @"Internal error: Unknown stringState. %@ line #%ld", [NSString stringWithUTF8String:__FILE__], (long)__LINE__); stringState = TMBJSONStringStateError; goto finishedParsing; break;
      }
    }
  }

finishedParsing:

  if(TMBJK_EXPECT_T(stringState == TMBJSONStringStateFinished)) {
    NSCParameterAssert((parseState->stringBuffer.bytes.ptr + tokenStartIndex) < atStringCharacter);

    parseState->token.tokenPtrRange.ptr    = parseState->stringBuffer.bytes.ptr + tokenStartIndex;
    parseState->token.tokenPtrRange.length = (atStringCharacter - parseState->token.tokenPtrRange.ptr);

    if(TMBJK_EXPECT_T(onlySimpleString)) {
      NSCParameterAssert(((parseState->token.tokenPtrRange.ptr + 1) < endOfBuffer) && (parseState->token.tokenPtrRange.length >= 2UL) && (((parseState->token.tokenPtrRange.ptr + 1) + (parseState->token.tokenPtrRange.length - 2)) < endOfBuffer));
      parseState->token.value.ptrRange.ptr    = parseState->token.tokenPtrRange.ptr    + 1;
      parseState->token.value.ptrRange.length = parseState->token.tokenPtrRange.length - 2UL;
    } else {
      parseState->token.value.ptrRange.ptr    = parseState->token.tokenBuffer.bytes.ptr;
      parseState->token.value.ptrRange.length = tokenBufferIdx;
    }
    
    parseState->token.value.hash = stringHash;
    parseState->token.value.type = TMBJKValueTypeString;
    parseState->atIndex          = (atStringCharacter - parseState->stringBuffer.bytes.ptr);
  }

  if(TMBJK_EXPECT_F(stringState != TMBJSONStringStateFinished)) { jk_error(parseState, @"Invalid string."); }
  return(TMBJK_EXPECT_T(stringState == TMBJSONStringStateFinished) ? 0 : 1);
}

static int jk_parse_number(TMBJKParseState *parseState) {
  NSCParameterAssert((parseState != NULL) && (TMBJK_AT_STRING_PTR(parseState) <= TMBJK_END_STRING_PTR(parseState)));
  const unsigned char *numberStart       = TMBJK_AT_STRING_PTR(parseState);
  const unsigned char *endOfBuffer       = TMBJK_END_STRING_PTR(parseState);
  const unsigned char *atNumberCharacter = NULL;
  int                  numberState       = TMBJSONNumberStateWholeNumberStart, isFloatingPoint = 0, isNegative = 0, backup = 0;
  size_t               startingIndex     = parseState->atIndex;
  
  for(atNumberCharacter = numberStart; (TMBJK_EXPECT_T(atNumberCharacter < endOfBuffer)) && (TMBJK_EXPECT_T(!(TMBJK_EXPECT_F(numberState == TMBJSONNumberStateFinished) || TMBJK_EXPECT_F(numberState == TMBJSONNumberStateError)))); atNumberCharacter++) {
    unsigned long currentChar = (unsigned long)(*atNumberCharacter), lowerCaseCC = currentChar | 0x20UL;
    
    switch(numberState) {
      case TMBJSONNumberStateWholeNumberStart: if   (currentChar == '-')                                                                              { numberState = TMBJSONNumberStateWholeNumberMinus;      isNegative      = 1; break; }
      case TMBJSONNumberStateWholeNumberMinus: if   (currentChar == '0')                                                                              { numberState = TMBJSONNumberStateWholeNumberZero;                            break; }
                                       else if(  (currentChar >= '1') && (currentChar <= '9'))                                                     { numberState = TMBJSONNumberStateWholeNumber;                                break; }
                                       else                                                     { /* XXX Add error message */                        numberState = TMBJSONNumberStateError;                                      break; }
      case TMBJSONNumberStateExponentStart:    if(  (currentChar == '+') || (currentChar == '-'))                                                     { numberState = TMBJSONNumberStateExponentPlusMinus;                          break; }
      case TMBJSONNumberStateFractionalNumberStart:
      case TMBJSONNumberStateExponentPlusMinus:if(!((currentChar >= '0') && (currentChar <= '9'))) { /* XXX Add error message */                        numberState = TMBJSONNumberStateError;                                      break; }
                                       else {                                              if(numberState == TMBJSONNumberStateFractionalNumberStart) { numberState = TMBJSONNumberStateFractionalNumber; }
                                                                                           else                                                    { numberState = TMBJSONNumberStateExponent;         }                         break; }
      case TMBJSONNumberStateWholeNumberZero:
      case TMBJSONNumberStateWholeNumber:      if   (currentChar == '.')                                                                              { numberState = TMBJSONNumberStateFractionalNumberStart; isFloatingPoint = 1; break; }
      case TMBJSONNumberStateFractionalNumber: if   (lowerCaseCC == 'e')                                                                              { numberState = TMBJSONNumberStateExponentStart;         isFloatingPoint = 1; break; }
      case TMBJSONNumberStateExponent:         if(!((currentChar >= '0') && (currentChar <= '9')) || (numberState == TMBJSONNumberStateWholeNumberZero)) { numberState = TMBJSONNumberStateFinished;              backup          = 1; break; }
        break;
      default:                                                                                    /* XXX Add error message */                        numberState = TMBJSONNumberStateError;                                      break;
    }
  }
  
  parseState->token.tokenPtrRange.ptr    = parseState->stringBuffer.bytes.ptr + startingIndex;
  parseState->token.tokenPtrRange.length = (atNumberCharacter - parseState->token.tokenPtrRange.ptr) - backup;
  parseState->atIndex                    = (parseState->token.tokenPtrRange.ptr + parseState->token.tokenPtrRange.length) - parseState->stringBuffer.bytes.ptr;

  if(TMBJK_EXPECT_T(numberState == TMBJSONNumberStateFinished)) {
    unsigned char  numberTempBuf[parseState->token.tokenPtrRange.length + 4UL];
    unsigned char *endOfNumber = NULL;

    memcpy(numberTempBuf, parseState->token.tokenPtrRange.ptr, parseState->token.tokenPtrRange.length);
    numberTempBuf[parseState->token.tokenPtrRange.length] = 0;

    errno = 0;
    
    // Treat "-0" as a floating point number, which is capable of representing negative zeros.
    if(TMBJK_EXPECT_F(parseState->token.tokenPtrRange.length == 2UL) && TMBJK_EXPECT_F(numberTempBuf[1] == '0') && TMBJK_EXPECT_F(isNegative)) { isFloatingPoint = 1; }

    if(isFloatingPoint) {
      parseState->token.value.number.doubleValue = strtod((const char *)numberTempBuf, (char **)&endOfNumber); // strtod is documented to return U+2261 (identical to) 0.0 on an underflow error (along with setting errno to ERANGE).
      parseState->token.value.type               = TMBJKValueTypeDouble;
      parseState->token.value.ptrRange.ptr       = (const unsigned char *)&parseState->token.value.number.doubleValue;
      parseState->token.value.ptrRange.length    = sizeof(double);
      parseState->token.value.hash               = (TMBJK_HASH_INIT + parseState->token.value.type);
    } else {
      if(isNegative) {
        parseState->token.value.number.longLongValue = strtoll((const char *)numberTempBuf, (char **)&endOfNumber, 10);
        parseState->token.value.type                 = TMBJKValueTypeLongLong;
        parseState->token.value.ptrRange.ptr         = (const unsigned char *)&parseState->token.value.number.longLongValue;
        parseState->token.value.ptrRange.length      = sizeof(long long);
        parseState->token.value.hash                 = (TMBJK_HASH_INIT + parseState->token.value.type) + (TMBJKHash)parseState->token.value.number.longLongValue;
      } else {
        parseState->token.value.number.unsignedLongLongValue = strtoull((const char *)numberTempBuf, (char **)&endOfNumber, 10);
        parseState->token.value.type                         = TMBJKValueTypeUnsignedLongLong;
        parseState->token.value.ptrRange.ptr                 = (const unsigned char *)&parseState->token.value.number.unsignedLongLongValue;
        parseState->token.value.ptrRange.length              = sizeof(unsigned long long);
        parseState->token.value.hash                         = (TMBJK_HASH_INIT + parseState->token.value.type) + (TMBJKHash)parseState->token.value.number.unsignedLongLongValue;
      }
    }

    if(TMBJK_EXPECT_F(errno != 0)) {
      numberState = TMBJSONNumberStateError;
      if(errno == ERANGE) {
        switch(parseState->token.value.type) {
          case TMBJKValueTypeDouble:           jk_error(parseState, @"The value '%s' could not be represented as a 'double' due to %s.",           numberTempBuf, (parseState->token.value.number.doubleValue == 0.0) ? "underflow" : "overflow"); break; // see above for == 0.0.
          case TMBJKValueTypeLongLong:         jk_error(parseState, @"The value '%s' exceeded the minimum value that could be represented: %lld.", numberTempBuf, parseState->token.value.number.longLongValue);                                   break;
          case TMBJKValueTypeUnsignedLongLong: jk_error(parseState, @"The value '%s' exceeded the maximum value that could be represented: %llu.", numberTempBuf, parseState->token.value.number.unsignedLongLongValue);                           break;
          default:                          jk_error(parseState, @"Internal error: Unknown token value type. %@ line #%ld",                     [NSString stringWithUTF8String:__FILE__], (long)__LINE__);                                      break;
        }
      }
    }
    if(TMBJK_EXPECT_F(endOfNumber != &numberTempBuf[parseState->token.tokenPtrRange.length]) && TMBJK_EXPECT_F(numberState != TMBJSONNumberStateError)) { numberState = TMBJSONNumberStateError; jk_error(parseState, @"The conversion function did not consume all of the number tokens characters."); }

    size_t hashIndex = 0UL;
    for(hashIndex = 0UL; hashIndex < parseState->token.value.ptrRange.length; hashIndex++) { parseState->token.value.hash = jk_calculateHash(parseState->token.value.hash, parseState->token.value.ptrRange.ptr[hashIndex]); }
  }

  if(TMBJK_EXPECT_F(numberState != TMBJSONNumberStateFinished)) { jk_error(parseState, @"Invalid number."); }
  return(TMBJK_EXPECT_T((numberState == TMBJSONNumberStateFinished)) ? 0 : 1);
}

TMBJK_STATIC_INLINE void jk_set_parsed_token(TMBJKParseState *parseState, const unsigned char *ptr, size_t length, TMBJKTokenType type, size_t advanceBy) {
  parseState->token.tokenPtrRange.ptr     = ptr;
  parseState->token.tokenPtrRange.length  = length;
  parseState->token.type                  = type;
  parseState->atIndex                    += advanceBy;
}

static size_t jk_parse_is_newline(TMBJKParseState *parseState, const unsigned char *atCharacterPtr) {
  NSCParameterAssert((parseState != NULL) && (atCharacterPtr != NULL) && (atCharacterPtr >= parseState->stringBuffer.bytes.ptr) && (atCharacterPtr < TMBJK_END_STRING_PTR(parseState)));
  const unsigned char *endOfStringPtr = TMBJK_END_STRING_PTR(parseState);

  if(TMBJK_EXPECT_F(atCharacterPtr >= endOfStringPtr)) { return(0UL); }

  if(TMBJK_EXPECT_F((*(atCharacterPtr + 0)) == '\n')) { return(1UL); }
  if(TMBJK_EXPECT_F((*(atCharacterPtr + 0)) == '\r')) { if((TMBJK_EXPECT_T((atCharacterPtr + 1) < endOfStringPtr)) && ((*(atCharacterPtr + 1)) == '\n')) { return(2UL); } return(1UL); }
  if(parseState->parseOptionFlags & TMBJKParseOptionUnicodeNewlines) {
    if((TMBJK_EXPECT_F((*(atCharacterPtr + 0)) == 0xc2)) && (((atCharacterPtr + 1) < endOfStringPtr) && ((*(atCharacterPtr + 1)) == 0x85))) { return(2UL); }
    if((TMBJK_EXPECT_F((*(atCharacterPtr + 0)) == 0xe2)) && (((atCharacterPtr + 2) < endOfStringPtr) && ((*(atCharacterPtr + 1)) == 0x80) && (((*(atCharacterPtr + 2)) == 0xa8) || ((*(atCharacterPtr + 2)) == 0xa9)))) { return(3UL); }
  }

  return(0UL);
}

TMBJK_STATIC_INLINE int jk_parse_skip_newline(TMBJKParseState *parseState) {
  size_t newlineAdvanceAtIndex = 0UL;
  if(TMBJK_EXPECT_F((newlineAdvanceAtIndex = jk_parse_is_newline(parseState, TMBJK_AT_STRING_PTR(parseState))) > 0UL)) { parseState->lineNumber++; parseState->atIndex += (newlineAdvanceAtIndex - 1UL); parseState->lineStartIndex = parseState->atIndex + 1UL; return(1); }
  return(0);
}

TMBJK_STATIC_INLINE void jk_parse_skip_whitespace(TMBJKParseState *parseState) {
#ifndef __clang_analyzer__
  NSCParameterAssert((parseState != NULL) && (TMBJK_AT_STRING_PTR(parseState) <= TMBJK_END_STRING_PTR(parseState)));
  const unsigned char *atCharacterPtr   = NULL;
  const unsigned char *endOfStringPtr   = TMBJK_END_STRING_PTR(parseState);

  for(atCharacterPtr = TMBJK_AT_STRING_PTR(parseState); (TMBJK_EXPECT_T((atCharacterPtr = TMBJK_AT_STRING_PTR(parseState)) < endOfStringPtr)); parseState->atIndex++) {
    if(((*(atCharacterPtr + 0)) == ' ') || ((*(atCharacterPtr + 0)) == '\t')) { continue; }
    if(jk_parse_skip_newline(parseState)) { continue; }
    if(parseState->parseOptionFlags & TMBJKParseOptionComments) {
      if((TMBJK_EXPECT_F((*(atCharacterPtr + 0)) == '/')) && (TMBJK_EXPECT_T((atCharacterPtr + 1) < endOfStringPtr))) {
        if((*(atCharacterPtr + 1)) == '/') {
          parseState->atIndex++;
          for(atCharacterPtr = TMBJK_AT_STRING_PTR(parseState); (TMBJK_EXPECT_T((atCharacterPtr = TMBJK_AT_STRING_PTR(parseState)) < endOfStringPtr)); parseState->atIndex++) { if(jk_parse_skip_newline(parseState)) { break; } }
          continue;
        }
        if((*(atCharacterPtr + 1)) == '*') {
          parseState->atIndex++;
          for(atCharacterPtr = TMBJK_AT_STRING_PTR(parseState); (TMBJK_EXPECT_T((atCharacterPtr = TMBJK_AT_STRING_PTR(parseState)) < endOfStringPtr)); parseState->atIndex++) {
            if(jk_parse_skip_newline(parseState)) { continue; }
            if(((*(atCharacterPtr + 0)) == '*') && (((atCharacterPtr + 1) < endOfStringPtr) && ((*(atCharacterPtr + 1)) == '/'))) { parseState->atIndex++; break; }
          }
          continue;
        }
      }
    }
    break;
  }
#endif
}

static int jk_parse_next_token(TMBJKParseState *parseState) {
  NSCParameterAssert((parseState != NULL) && (TMBJK_AT_STRING_PTR(parseState) <= TMBJK_END_STRING_PTR(parseState)));
  const unsigned char *atCharacterPtr   = NULL;
  const unsigned char *endOfStringPtr   = TMBJK_END_STRING_PTR(parseState);
  unsigned char        currentCharacter = 0U;
  int                  stopParsing      = 0;

  parseState->prev_atIndex        = parseState->atIndex;
  parseState->prev_lineNumber     = parseState->lineNumber;
  parseState->prev_lineStartIndex = parseState->lineStartIndex;

  jk_parse_skip_whitespace(parseState);

  if((TMBJK_AT_STRING_PTR(parseState) == endOfStringPtr)) { stopParsing = 1; }

  if((TMBJK_EXPECT_T(stopParsing == 0)) && (TMBJK_EXPECT_T((atCharacterPtr = TMBJK_AT_STRING_PTR(parseState)) < endOfStringPtr))) {
    currentCharacter = *atCharacterPtr;

         if(TMBJK_EXPECT_T(currentCharacter == '"')) { if(TMBJK_EXPECT_T((stopParsing = jk_parse_string(parseState)) == 0)) { jk_set_parsed_token(parseState, parseState->token.tokenPtrRange.ptr, parseState->token.tokenPtrRange.length, TMBJKTokenTypeString, 0UL); } }
    else if(TMBJK_EXPECT_T(currentCharacter == ':')) { jk_set_parsed_token(parseState, atCharacterPtr, 1UL, TMBJKTokenTypeSeparator,   1UL); }
    else if(TMBJK_EXPECT_T(currentCharacter == ',')) { jk_set_parsed_token(parseState, atCharacterPtr, 1UL, TMBJKTokenTypeComma,       1UL); }
    else if((TMBJK_EXPECT_T(currentCharacter >= '0') && TMBJK_EXPECT_T(currentCharacter <= '9')) || TMBJK_EXPECT_T(currentCharacter == '-')) { if(TMBJK_EXPECT_T((stopParsing = jk_parse_number(parseState)) == 0)) { jk_set_parsed_token(parseState, parseState->token.tokenPtrRange.ptr, parseState->token.tokenPtrRange.length, TMBJKTokenTypeNumber, 0UL); } }
    else if(TMBJK_EXPECT_T(currentCharacter == '{')) { jk_set_parsed_token(parseState, atCharacterPtr, 1UL, TMBJKTokenTypeObjectBegin, 1UL); }
    else if(TMBJK_EXPECT_T(currentCharacter == '}')) { jk_set_parsed_token(parseState, atCharacterPtr, 1UL, TMBJKTokenTypeObjectEnd,   1UL); }
    else if(TMBJK_EXPECT_T(currentCharacter == '[')) { jk_set_parsed_token(parseState, atCharacterPtr, 1UL, TMBJKTokenTypeArrayBegin,  1UL); }
    else if(TMBJK_EXPECT_T(currentCharacter == ']')) { jk_set_parsed_token(parseState, atCharacterPtr, 1UL, TMBJKTokenTypeArrayEnd,    1UL); }
    
    else if(TMBJK_EXPECT_T(currentCharacter == 't')) { if(!((TMBJK_EXPECT_T((atCharacterPtr + 4UL) < endOfStringPtr)) && (TMBJK_EXPECT_T(atCharacterPtr[1] == 'r')) && (TMBJK_EXPECT_T(atCharacterPtr[2] == 'u')) && (TMBJK_EXPECT_T(atCharacterPtr[3] == 'e'))))                                            { stopParsing = 1; /* XXX Add error message */ } else { jk_set_parsed_token(parseState, atCharacterPtr, 4UL, TMBJKTokenTypeTrue,  4UL); } }
    else if(TMBJK_EXPECT_T(currentCharacter == 'f')) { if(!((TMBJK_EXPECT_T((atCharacterPtr + 5UL) < endOfStringPtr)) && (TMBJK_EXPECT_T(atCharacterPtr[1] == 'a')) && (TMBJK_EXPECT_T(atCharacterPtr[2] == 'l')) && (TMBJK_EXPECT_T(atCharacterPtr[3] == 's')) && (TMBJK_EXPECT_T(atCharacterPtr[4] == 'e')))) { stopParsing = 1; /* XXX Add error message */ } else { jk_set_parsed_token(parseState, atCharacterPtr, 5UL, TMBJKTokenTypeFalse, 5UL); } }
    else if(TMBJK_EXPECT_T(currentCharacter == 'n')) { if(!((TMBJK_EXPECT_T((atCharacterPtr + 4UL) < endOfStringPtr)) && (TMBJK_EXPECT_T(atCharacterPtr[1] == 'u')) && (TMBJK_EXPECT_T(atCharacterPtr[2] == 'l')) && (TMBJK_EXPECT_T(atCharacterPtr[3] == 'l'))))                                            { stopParsing = 1; /* XXX Add error message */ } else { jk_set_parsed_token(parseState, atCharacterPtr, 4UL, TMBJKTokenTypeNull,  4UL); } }
    else { stopParsing = 1; /* XXX Add error message */ }    
  }

  if(TMBJK_EXPECT_F(stopParsing)) { jk_error(parseState, @"Unexpected token, wanted '{', '}', '[', ']', ',', ':', 'true', 'false', 'null', '\"STRING\"', 'NUMBER'."); }
  return(stopParsing);
}

static void jk_error_parse_accept_or3(TMBJKParseState *parseState, int state, NSString *or1String, NSString *or2String, NSString *or3String) {
  NSString *acceptStrings[16];
  int acceptIdx = 0;
  if(state & TMBJKParseAcceptValue) { acceptStrings[acceptIdx++] = or1String; }
  if(state & TMBJKParseAcceptComma) { acceptStrings[acceptIdx++] = or2String; }
  if(state & TMBJKParseAcceptEnd)   { acceptStrings[acceptIdx++] = or3String; }
       if(acceptIdx == 1) { jk_error(parseState, @"Expected %@, not '%*.*s'",           acceptStrings[0],                                     (int)parseState->token.tokenPtrRange.length, (int)parseState->token.tokenPtrRange.length, parseState->token.tokenPtrRange.ptr); }
  else if(acceptIdx == 2) { jk_error(parseState, @"Expected %@ or %@, not '%*.*s'",     acceptStrings[0], acceptStrings[1],                   (int)parseState->token.tokenPtrRange.length, (int)parseState->token.tokenPtrRange.length, parseState->token.tokenPtrRange.ptr); }
  else if(acceptIdx == 3) { jk_error(parseState, @"Expected %@, %@, or %@, not '%*.*s", acceptStrings[0], acceptStrings[1], acceptStrings[2], (int)parseState->token.tokenPtrRange.length, (int)parseState->token.tokenPtrRange.length, parseState->token.tokenPtrRange.ptr); }
}

static void *jk_parse_array(TMBJKParseState *parseState) {
  size_t  startingObjectIndex = parseState->objectStack.index;
  int     arrayState          = TMBJKParseAcceptValueOrEnd, stopParsing = 0;
  void   *parsedArray         = NULL;

  while(TMBJK_EXPECT_T((TMBJK_EXPECT_T(stopParsing == 0)) && (TMBJK_EXPECT_T(parseState->atIndex < parseState->stringBuffer.bytes.length)))) {
    if(TMBJK_EXPECT_F(parseState->objectStack.index > (parseState->objectStack.count - 4UL))) { if(jk_objectStack_resize(&parseState->objectStack, parseState->objectStack.count + 128UL)) { jk_error(parseState, @"Internal error: [array] objectsIndex > %zu, resize failed? %@ line %#ld", (parseState->objectStack.count - 4UL), [NSString stringWithUTF8String:__FILE__], (long)__LINE__); break; } }

    if(TMBJK_EXPECT_T((stopParsing = jk_parse_next_token(parseState)) == 0)) {
      void *object = NULL;
#ifndef NS_BLOCK_ASSERTIONS
      parseState->objectStack.objects[parseState->objectStack.index] = NULL;
      parseState->objectStack.keys   [parseState->objectStack.index] = NULL;
#endif
      switch(parseState->token.type) {
        case TMBJKTokenTypeNumber:
        case TMBJKTokenTypeString:
        case TMBJKTokenTypeTrue:
        case TMBJKTokenTypeFalse:
        case TMBJKTokenTypeNull:
        case TMBJKTokenTypeArrayBegin:
        case TMBJKTokenTypeObjectBegin:
          if(TMBJK_EXPECT_F((arrayState & TMBJKParseAcceptValue)          == 0))    { parseState->errorIsPrev = 1; jk_error(parseState, @"Unexpected value.");              stopParsing = 1; break; }
          if(TMBJK_EXPECT_F((object = jk_object_for_token(parseState)) == NULL)) {                              jk_error(parseState, @"Internal error: Object == NULL"); stopParsing = 1; break; } else { parseState->objectStack.objects[parseState->objectStack.index++] = object; arrayState = TMBJKParseAcceptCommaOrEnd; }
          break;
        case TMBJKTokenTypeArrayEnd: if(TMBJK_EXPECT_T(arrayState & TMBJKParseAcceptEnd)) { NSCParameterAssert(parseState->objectStack.index >= startingObjectIndex); parsedArray = (void *)_JKArrayCreate((id *)&parseState->objectStack.objects[startingObjectIndex], (parseState->objectStack.index - startingObjectIndex), parseState->mutableCollections); } else { parseState->errorIsPrev = 1; jk_error(parseState, @"Unexpected ']'."); } stopParsing = 1; break;
        case TMBJKTokenTypeComma:    if(TMBJK_EXPECT_T(arrayState & TMBJKParseAcceptComma)) { arrayState = TMBJKParseAcceptValue; } else { parseState->errorIsPrev = 1; jk_error(parseState, @"Unexpected ','."); stopParsing = 1; } break;
        default: parseState->errorIsPrev = 1; jk_error_parse_accept_or3(parseState, arrayState, @"a value", @"a comma", @"a ']'"); stopParsing = 1; break;
      }
    }
  }

  if(TMBJK_EXPECT_F(parsedArray == NULL)) { size_t idx = 0UL; for(idx = startingObjectIndex; idx < parseState->objectStack.index; idx++) { if(parseState->objectStack.objects[idx] != NULL) { CFRelease(parseState->objectStack.objects[idx]); parseState->objectStack.objects[idx] = NULL; } } }
#if !defined(NS_BLOCK_ASSERTIONS)
  else { size_t idx = 0UL; for(idx = startingObjectIndex; idx < parseState->objectStack.index; idx++) { parseState->objectStack.objects[idx] = NULL; parseState->objectStack.keys[idx] = NULL; } }
#endif
  
  parseState->objectStack.index = startingObjectIndex;
  return(parsedArray);
}

static void *jk_create_dictionary(TMBJKParseState *parseState, size_t startingObjectIndex) {
  void *parsedDictionary = NULL;

  parseState->objectStack.index--;

  parsedDictionary = _JKDictionaryCreate((id *)&parseState->objectStack.keys[startingObjectIndex], (NSUInteger *)&parseState->objectStack.cfHashes[startingObjectIndex], (id *)&parseState->objectStack.objects[startingObjectIndex], (parseState->objectStack.index - startingObjectIndex), parseState->mutableCollections);

  return(parsedDictionary);
}

static void *jk_parse_dictionary(TMBJKParseState *parseState) {
  size_t  startingObjectIndex = parseState->objectStack.index;
  int     dictState           = TMBJKParseAcceptValueOrEnd, stopParsing = 0;
  void   *parsedDictionary    = NULL;

  while(TMBJK_EXPECT_T((TMBJK_EXPECT_T(stopParsing == 0)) && (TMBJK_EXPECT_T(parseState->atIndex < parseState->stringBuffer.bytes.length)))) {
    if(TMBJK_EXPECT_F(parseState->objectStack.index > (parseState->objectStack.count - 4UL))) { if(jk_objectStack_resize(&parseState->objectStack, parseState->objectStack.count + 128UL)) { jk_error(parseState, @"Internal error: [dictionary] objectsIndex > %zu, resize failed? %@ line #%ld", (parseState->objectStack.count - 4UL), [NSString stringWithUTF8String:__FILE__], (long)__LINE__); break; } }

    size_t objectStackIndex = parseState->objectStack.index++;
    parseState->objectStack.keys[objectStackIndex]    = NULL;
    parseState->objectStack.objects[objectStackIndex] = NULL;
    void *key = NULL, *object = NULL;

    if(TMBJK_EXPECT_T((TMBJK_EXPECT_T(stopParsing == 0)) && (TMBJK_EXPECT_T((stopParsing = jk_parse_next_token(parseState)) == 0)))) {
      switch(parseState->token.type) {
        case TMBJKTokenTypeString:
          if(TMBJK_EXPECT_F((dictState & TMBJKParseAcceptValue)        == 0))    { parseState->errorIsPrev = 1; jk_error(parseState, @"Unexpected string.");           stopParsing = 1; break; }
          if(TMBJK_EXPECT_F((key = jk_object_for_token(parseState)) == NULL)) {                              jk_error(parseState, @"Internal error: Key == NULL."); stopParsing = 1; break; }
          else {
            parseState->objectStack.keys[objectStackIndex] = key;
            if(TMBJK_EXPECT_T(parseState->token.value.cacheItem != NULL)) { if(TMBJK_EXPECT_F(parseState->token.value.cacheItem->cfHash == 0UL)) { parseState->token.value.cacheItem->cfHash = CFHash(key); } parseState->objectStack.cfHashes[objectStackIndex] = parseState->token.value.cacheItem->cfHash; }
            else { parseState->objectStack.cfHashes[objectStackIndex] = CFHash(key); }
          }
          break;

        case TMBJKTokenTypeObjectEnd: if((TMBJK_EXPECT_T(dictState & TMBJKParseAcceptEnd)))   { NSCParameterAssert(parseState->objectStack.index >= startingObjectIndex); parsedDictionary = jk_create_dictionary(parseState, startingObjectIndex); } else { parseState->errorIsPrev = 1; jk_error(parseState, @"Unexpected '}'."); } stopParsing = 1; break;
        case TMBJKTokenTypeComma:     if((TMBJK_EXPECT_T(dictState & TMBJKParseAcceptComma))) { dictState = TMBJKParseAcceptValue; parseState->objectStack.index--; continue; } else { parseState->errorIsPrev = 1; jk_error(parseState, @"Unexpected ','."); stopParsing = 1; } break;

        default: parseState->errorIsPrev = 1; jk_error_parse_accept_or3(parseState, dictState, @"a \"STRING\"", @"a comma", @"a '}'"); stopParsing = 1; break;
      }
    }

    if(TMBJK_EXPECT_T(stopParsing == 0)) {
      if(TMBJK_EXPECT_T((stopParsing = jk_parse_next_token(parseState)) == 0)) { if(TMBJK_EXPECT_F(parseState->token.type != TMBJKTokenTypeSeparator)) { parseState->errorIsPrev = 1; jk_error(parseState, @"Expected ':'."); stopParsing = 1; } }
    }

    if((TMBJK_EXPECT_T(stopParsing == 0)) && (TMBJK_EXPECT_T((stopParsing = jk_parse_next_token(parseState)) == 0))) {
      switch(parseState->token.type) {
        case TMBJKTokenTypeNumber:
        case TMBJKTokenTypeString:
        case TMBJKTokenTypeTrue:
        case TMBJKTokenTypeFalse:
        case TMBJKTokenTypeNull:
        case TMBJKTokenTypeArrayBegin:
        case TMBJKTokenTypeObjectBegin:
          if(TMBJK_EXPECT_F((dictState & TMBJKParseAcceptValue)           == 0))    { parseState->errorIsPrev = 1; jk_error(parseState, @"Unexpected value.");               stopParsing = 1; break; }
          if(TMBJK_EXPECT_F((object = jk_object_for_token(parseState)) == NULL)) {                              jk_error(parseState, @"Internal error: Object == NULL."); stopParsing = 1; break; } else { parseState->objectStack.objects[objectStackIndex] = object; dictState = TMBJKParseAcceptCommaOrEnd; }
          break;
        default: parseState->errorIsPrev = 1; jk_error_parse_accept_or3(parseState, dictState, @"a value", @"a comma", @"a '}'"); stopParsing = 1; break;
      }
    }
  }

  if(TMBJK_EXPECT_F(parsedDictionary == NULL)) { size_t idx = 0UL; for(idx = startingObjectIndex; idx < parseState->objectStack.index; idx++) { if(parseState->objectStack.keys[idx] != NULL) { CFRelease(parseState->objectStack.keys[idx]); parseState->objectStack.keys[idx] = NULL; } if(parseState->objectStack.objects[idx] != NULL) { CFRelease(parseState->objectStack.objects[idx]); parseState->objectStack.objects[idx] = NULL; } } }
#if !defined(NS_BLOCK_ASSERTIONS)
  else { size_t idx = 0UL; for(idx = startingObjectIndex; idx < parseState->objectStack.index; idx++) { parseState->objectStack.objects[idx] = NULL; parseState->objectStack.keys[idx] = NULL; } }
#endif

  parseState->objectStack.index = startingObjectIndex;
  return(parsedDictionary);
}

static id json_parse_it(TMBJKParseState *parseState) {
  id  parsedObject = NULL;
  int stopParsing  = 0;

  while((TMBJK_EXPECT_T(stopParsing == 0)) && (TMBJK_EXPECT_T(parseState->atIndex < parseState->stringBuffer.bytes.length))) {
    if((TMBJK_EXPECT_T(stopParsing == 0)) && (TMBJK_EXPECT_T((stopParsing = jk_parse_next_token(parseState)) == 0))) {
      switch(parseState->token.type) {
        case TMBJKTokenTypeArrayBegin:
        case TMBJKTokenTypeObjectBegin: parsedObject = [(id)jk_object_for_token(parseState) autorelease]; stopParsing = 1; break;
        default:                     jk_error(parseState, @"Expected either '[' or '{'.");             stopParsing = 1; break;
      }
    }
  }

  NSCParameterAssert((parseState->objectStack.index == 0) && (TMBJK_AT_STRING_PTR(parseState) <= TMBJK_END_STRING_PTR(parseState)));

  if((parsedObject == NULL) && (TMBJK_AT_STRING_PTR(parseState) == TMBJK_END_STRING_PTR(parseState))) { jk_error(parseState, @"Reached the end of the buffer."); }
  if(parsedObject == NULL) { jk_error(parseState, @"Unable to parse TMBJSON."); }

  if((parsedObject != NULL) && (TMBJK_AT_STRING_PTR(parseState) < TMBJK_END_STRING_PTR(parseState))) {
    jk_parse_skip_whitespace(parseState);
    if((parsedObject != NULL) && ((parseState->parseOptionFlags & TMBJKParseOptionPermitTextAfterValidJSON) == 0) && (TMBJK_AT_STRING_PTR(parseState) < TMBJK_END_STRING_PTR(parseState))) {
      jk_error(parseState, @"A valid TMBJSON object was parsed but there were additional non-white-space characters remaining.");
      parsedObject = NULL;
    }
  }

  return(parsedObject);
}

////////////
#pragma mark -
#pragma mark Object cache

// This uses a Galois Linear Feedback Shift Register (LFSR) PRNG to pick which item in the cache to age. It has a period of (2^32)-1.
// NOTE: A LFSR *MUST* be initialized to a non-zero value and must always have a non-zero value. The LFSR is initalized to 1 in -initWithParseOptions:
TMBJK_STATIC_INLINE void jk_cache_age(TMBJKParseState *parseState) {
  NSCParameterAssert((parseState != NULL) && (parseState->cache.prng_lfsr != 0U));
  parseState->cache.prng_lfsr = (parseState->cache.prng_lfsr >> 1) ^ ((0U - (parseState->cache.prng_lfsr & 1U)) & 0x80200003U);
  parseState->cache.age[parseState->cache.prng_lfsr & (parseState->cache.count - 1UL)] >>= 1;
}

// The object cache is nothing more than a hash table with open addressing collision resolution that is bounded by TMBJK_CACHE_PROBES attempts.
//
// The hash table is a linear C array of TMBJKTokenCacheItem.  The terms "item" and "bucket" are synonymous with the index in to the cache array, i.e. cache.items[bucket].
//
// Items in the cache have an age associated with them.  An items age is incremented using saturating unsigned arithmetic and decremeted using unsigned right shifts.
// Thus, an items age is managed using an AIMD policy- additive increase, multiplicative decrease.  All age calculations and manipulations are branchless.
// The primitive C type MUST be unsigned.  It is currently a "char", which allows (at a minimum and in practice) 8 bits.
//
// A "useable bucket" is a bucket that is not in use (never populated), or has an age == 0.
//
// When an item is found in the cache, it's age is incremented.
// If a useable bucket hasn't been found, the current item (bucket) is aged along with two random items.
//
// If a value is not found in the cache, and no useable bucket has been found, that value is not added to the cache.

static void *jk_cachedObjects(TMBJKParseState *parseState) {
  unsigned long  bucket     = parseState->token.value.hash & (parseState->cache.count - 1UL), setBucket = 0UL, useableBucket = 0UL, x = 0UL;
  void          *parsedAtom = NULL;
    
  if(TMBJK_EXPECT_F(parseState->token.value.ptrRange.length == 0UL) && TMBJK_EXPECT_T(parseState->token.value.type == TMBJKValueTypeString)) { return(@""); }

  for(x = 0UL; x < TMBJK_CACHE_PROBES; x++) {
    if(TMBJK_EXPECT_F(parseState->cache.items[bucket].object == NULL)) { setBucket = 1UL; useableBucket = bucket; break; }
    
    if((TMBJK_EXPECT_T(parseState->cache.items[bucket].hash == parseState->token.value.hash)) && (TMBJK_EXPECT_T(parseState->cache.items[bucket].size == parseState->token.value.ptrRange.length)) && (TMBJK_EXPECT_T(parseState->cache.items[bucket].type == parseState->token.value.type)) && (TMBJK_EXPECT_T(parseState->cache.items[bucket].bytes != NULL)) && (TMBJK_EXPECT_T(memcmp(parseState->cache.items[bucket].bytes, parseState->token.value.ptrRange.ptr, parseState->token.value.ptrRange.length) == 0U))) {
      parseState->cache.age[bucket]     = (((uint32_t)parseState->cache.age[bucket]) + 1U) - (((((uint32_t)parseState->cache.age[bucket]) + 1U) >> 31) ^ 1U);
      parseState->token.value.cacheItem = &parseState->cache.items[bucket];
      NSCParameterAssert(parseState->cache.items[bucket].object != NULL);
      return((void *)CFRetain(parseState->cache.items[bucket].object));
    } else {
      if(TMBJK_EXPECT_F(setBucket == 0UL) && TMBJK_EXPECT_F(parseState->cache.age[bucket] == 0U)) { setBucket = 1UL; useableBucket = bucket; }
      if(TMBJK_EXPECT_F(setBucket == 0UL))                                                     { parseState->cache.age[bucket] >>= 1; jk_cache_age(parseState); jk_cache_age(parseState); }
      // This is the open addressing function.  The values length and type are used as a form of "double hashing" to distribute values with the same effective value hash across different object cache buckets.
      // The values type is a prime number that is relatively coprime to the other primes in the set of value types and the number of hash table buckets.
      bucket = (parseState->token.value.hash + (parseState->token.value.ptrRange.length * (x + 1UL)) + (parseState->token.value.type * (x + 1UL)) + (3UL * (x + 1UL))) & (parseState->cache.count - 1UL);
    }
  }
  
  switch(parseState->token.value.type) {
    case TMBJKValueTypeString:           parsedAtom = (void *)CFStringCreateWithBytes(NULL, parseState->token.value.ptrRange.ptr, parseState->token.value.ptrRange.length, kCFStringEncodingUTF8, 0); break;
    case TMBJKValueTypeLongLong:         parsedAtom = (void *)CFNumberCreate(NULL, kCFNumberLongLongType, &parseState->token.value.number.longLongValue);                                             break;
    case TMBJKValueTypeUnsignedLongLong:
      if(parseState->token.value.number.unsignedLongLongValue <= LLONG_MAX) { parsedAtom = (void *)CFNumberCreate(NULL, kCFNumberLongLongType, &parseState->token.value.number.unsignedLongLongValue); }
      else { parsedAtom = (void *)parseState->objCImpCache.NSNumberInitWithUnsignedLongLong(parseState->objCImpCache.NSNumberAlloc(parseState->objCImpCache.NSNumberClass, @selector(alloc)), @selector(initWithUnsignedLongLong:), parseState->token.value.number.unsignedLongLongValue); }
      break;
    case TMBJKValueTypeDouble:           parsedAtom = (void *)CFNumberCreate(NULL, kCFNumberDoubleType,   &parseState->token.value.number.doubleValue);                                               break;
    default: jk_error(parseState, @"Internal error: Unknown token value type. %@ line #%ld", [NSString stringWithUTF8String:__FILE__], (long)__LINE__); break;
  }
  
  if(TMBJK_EXPECT_T(setBucket) && (TMBJK_EXPECT_T(parsedAtom != NULL))) {
    bucket = useableBucket;
    if(TMBJK_EXPECT_T((parseState->cache.items[bucket].object != NULL))) { CFRelease(parseState->cache.items[bucket].object); parseState->cache.items[bucket].object = NULL; }
    
    if(TMBJK_EXPECT_T((parseState->cache.items[bucket].bytes = (unsigned char *)reallocf(parseState->cache.items[bucket].bytes, parseState->token.value.ptrRange.length)) != NULL)) {
      memcpy(parseState->cache.items[bucket].bytes, parseState->token.value.ptrRange.ptr, parseState->token.value.ptrRange.length);
      parseState->cache.items[bucket].object = (void *)CFRetain(parsedAtom);
      parseState->cache.items[bucket].hash   = parseState->token.value.hash;
      parseState->cache.items[bucket].cfHash = 0UL;
      parseState->cache.items[bucket].size   = parseState->token.value.ptrRange.length;
      parseState->cache.items[bucket].type   = parseState->token.value.type;
      parseState->token.value.cacheItem      = &parseState->cache.items[bucket];
      parseState->cache.age[bucket]          = TMBJK_INIT_CACHE_AGE;
    } else { // The realloc failed, so clear the appropriate fields.
      parseState->cache.items[bucket].hash   = 0UL;
      parseState->cache.items[bucket].cfHash = 0UL;
      parseState->cache.items[bucket].size   = 0UL;
      parseState->cache.items[bucket].type   = 0UL;
    }
  }
  
  return(parsedAtom);
}


static void *jk_object_for_token(TMBJKParseState *parseState) {
  void *parsedAtom = NULL;
  
  parseState->token.value.cacheItem = NULL;
  switch(parseState->token.type) {
    case TMBJKTokenTypeString:      parsedAtom = jk_cachedObjects(parseState);    break;
    case TMBJKTokenTypeNumber:      parsedAtom = jk_cachedObjects(parseState);    break;
    case TMBJKTokenTypeObjectBegin: parsedAtom = jk_parse_dictionary(parseState); break;
    case TMBJKTokenTypeArrayBegin:  parsedAtom = jk_parse_array(parseState);      break;
    case TMBJKTokenTypeTrue:        parsedAtom = (void *)kCFBooleanTrue;          break;
    case TMBJKTokenTypeFalse:       parsedAtom = (void *)kCFBooleanFalse;         break;
    case TMBJKTokenTypeNull:        parsedAtom = (void *)kCFNull;                 break;
    default: jk_error(parseState, @"Internal error: Unknown token type. %@ line #%ld", [NSString stringWithUTF8String:__FILE__], (long)__LINE__); break;
  }
  
  return(parsedAtom);
}

#pragma mark -
@implementation TMBJSONDecoder

+ (id)decoder
{
  return([self decoderWithParseOptions:TMBJKParseOptionStrict]);
}

+ (id)decoderWithParseOptions:(TMBJKParseOptionFlags)parseOptionFlags
{
  return([[[self alloc] initWithParseOptions:parseOptionFlags] autorelease]);
}

- (id)init
{
  return([self initWithParseOptions:TMBJKParseOptionStrict]);
}

- (id)initWithParseOptions:(TMBJKParseOptionFlags)parseOptionFlags
{
  if((self = [super init]) == NULL) { return(NULL); }

  if(parseOptionFlags & ~TMBJKParseOptionValidFlags) { [self autorelease]; [NSException raise:NSInvalidArgumentException format:@"Invalid parse options."]; }

  if((parseState = (TMBJKParseState *)calloc(1UL, sizeof(TMBJKParseState))) == NULL) { goto errorExit; }

  parseState->parseOptionFlags = parseOptionFlags;
  
  parseState->token.tokenBuffer.roundSizeUpToMultipleOf = 4096UL;
  parseState->objectStack.roundSizeUpToMultipleOf       = 2048UL;

  parseState->objCImpCache.NSNumberClass                    = _TMBjk_NSNumberClass;
  parseState->objCImpCache.NSNumberAlloc                    = _TMBjk_NSNumberAllocImp;
  parseState->objCImpCache.NSNumberInitWithUnsignedLongLong = _TMBjk_NSNumberInitWithUnsignedLongLongImp;
  
  parseState->cache.prng_lfsr = 1U;
  parseState->cache.count     = TMBJK_CACHE_SLOTS;
  if((parseState->cache.items = (TMBJKTokenCacheItem *)calloc(1UL, sizeof(TMBJKTokenCacheItem) * parseState->cache.count)) == NULL) { goto errorExit; }

  return(self);

 errorExit:
  if(self) { [self autorelease]; self = NULL; }
  return(NULL);
}

// This is here primarily to support the NSString and NSData convenience functions so the autoreleased TMBJSONDecoder can release most of its resources before the pool pops.
static void _JSONDecoderCleanup(TMBJSONDecoder *decoder) {
  if((decoder != NULL) && (decoder->parseState != NULL)) {
    jk_managedBuffer_release(&decoder->parseState->token.tokenBuffer);
    jk_objectStack_release(&decoder->parseState->objectStack);
    
    [decoder clearCache];
    if(decoder->parseState->cache.items != NULL) { free(decoder->parseState->cache.items); decoder->parseState->cache.items = NULL; }
    
    free(decoder->parseState); decoder->parseState = NULL;
  }
}

- (void)dealloc
{
  _JSONDecoderCleanup(self);
  [super dealloc];
}

- (void)clearCache
{
  if(TMBJK_EXPECT_T(parseState != NULL)) {
    if(TMBJK_EXPECT_T(parseState->cache.items != NULL)) {
      size_t idx = 0UL;
      for(idx = 0UL; idx < parseState->cache.count; idx++) {
        if(TMBJK_EXPECT_T(parseState->cache.items[idx].object != NULL)) { CFRelease(parseState->cache.items[idx].object); parseState->cache.items[idx].object = NULL; }
        if(TMBJK_EXPECT_T(parseState->cache.items[idx].bytes  != NULL)) { free(parseState->cache.items[idx].bytes);       parseState->cache.items[idx].bytes  = NULL; }
        memset(&parseState->cache.items[idx], 0, sizeof(TMBJKTokenCacheItem));
        parseState->cache.age[idx] = 0U;
      }
    }
  }
}

// This needs to be completely rewritten.
static id _JKParseUTF8String(TMBJKParseState *parseState, BOOL mutableCollections, const unsigned char *string, size_t length, NSError **error) {
  NSCParameterAssert((parseState != NULL) && (string != NULL) && (parseState->cache.prng_lfsr != 0U));
  parseState->stringBuffer.bytes.ptr    = string;
  parseState->stringBuffer.bytes.length = length;
  parseState->atIndex                   = 0UL;
  parseState->lineNumber                = 1UL;
  parseState->lineStartIndex            = 0UL;
  parseState->prev_atIndex              = 0UL;
  parseState->prev_lineNumber           = 1UL;
  parseState->prev_lineStartIndex       = 0UL;
  parseState->error                     = NULL;
  parseState->errorIsPrev               = 0;
  parseState->mutableCollections        = (mutableCollections == NO) ? NO : YES;
  
  unsigned char stackTokenBuffer[TMBJK_TOKENBUFFER_SIZE] TMBJK_ALIGNED(64);
  jk_managedBuffer_setToStackBuffer(&parseState->token.tokenBuffer, stackTokenBuffer, sizeof(stackTokenBuffer));
  
  void       *stackObjects [TMBJK_STACK_OBJS] TMBJK_ALIGNED(64);
  void       *stackKeys    [TMBJK_STACK_OBJS] TMBJK_ALIGNED(64);
  CFHashCode  stackCFHashes[TMBJK_STACK_OBJS] TMBJK_ALIGNED(64);
  jk_objectStack_setToStackBuffer(&parseState->objectStack, stackObjects, stackKeys, stackCFHashes, TMBJK_STACK_OBJS);
  
  id parsedJSON = json_parse_it(parseState);
  
  if((error != NULL) && (parseState->error != NULL)) { *error = parseState->error; }
  
  jk_managedBuffer_release(&parseState->token.tokenBuffer);
  jk_objectStack_release(&parseState->objectStack);
  
  parseState->stringBuffer.bytes.ptr    = NULL;
  parseState->stringBuffer.bytes.length = 0UL;
  parseState->atIndex                   = 0UL;
  parseState->lineNumber                = 1UL;
  parseState->lineStartIndex            = 0UL;
  parseState->prev_atIndex              = 0UL;
  parseState->prev_lineNumber           = 1UL;
  parseState->prev_lineStartIndex       = 0UL;
  parseState->error                     = NULL;
  parseState->errorIsPrev               = 0;
  parseState->mutableCollections        = NO;
  
  return(parsedJSON);
}

////////////
#pragma mark Deprecated as of v1.4
////////////

// Deprecated in TMBJSONKit v1.4.  Use objectWithUTF8String:length: instead.
- (id)parseUTF8String:(const unsigned char *)string length:(size_t)length
{
  return([self objectWithUTF8String:string length:length error:NULL]);
}

// Deprecated in TMBJSONKit v1.4.  Use objectWithUTF8String:length:error: instead.
- (id)parseUTF8String:(const unsigned char *)string length:(size_t)length error:(NSError **)error
{
  return([self objectWithUTF8String:string length:length error:error]);
}

// Deprecated in TMBJSONKit v1.4.  Use objectWithData: instead.
- (id)parseJSONData:(NSData *)jsonData
{
  return([self objectWithData:jsonData error:NULL]);
}

// Deprecated in TMBJSONKit v1.4.  Use objectWithData:error: instead.
- (id)parseJSONData:(NSData *)jsonData error:(NSError **)error
{
  return([self objectWithData:jsonData error:error]);
}

////////////
#pragma mark Methods that return immutable collection objects
////////////

- (id)objectWithUTF8String:(const unsigned char *)string length:(NSUInteger)length
{
  return([self objectWithUTF8String:string length:length error:NULL]);
}

- (id)objectWithUTF8String:(const unsigned char *)string length:(NSUInteger)length error:(NSError **)error
{
  if(parseState == NULL) { [NSException raise:NSInternalInconsistencyException format:@"parseState is NULL."];          }
  if(string     == NULL) { [NSException raise:NSInvalidArgumentException       format:@"The string argument is NULL."]; }
  
  return(_JKParseUTF8String(parseState, NO, string, (size_t)length, error));
}

- (id)objectWithData:(NSData *)jsonData
{
  return([self objectWithData:jsonData error:NULL]);
}

- (id)objectWithData:(NSData *)jsonData error:(NSError **)error
{
  if(jsonData == NULL) { [NSException raise:NSInvalidArgumentException format:@"The TMBJSONData argument is NULL."]; }
  return([self objectWithUTF8String:(const unsigned char *)[jsonData bytes] length:[jsonData length] error:error]);
}

////////////
#pragma mark Methods that return mutable collection objects
////////////

- (id)mutableObjectWithUTF8String:(const unsigned char *)string length:(NSUInteger)length
{
  return([self mutableObjectWithUTF8String:string length:length error:NULL]);
}

- (id)mutableObjectWithUTF8String:(const unsigned char *)string length:(NSUInteger)length error:(NSError **)error
{
  if(parseState == NULL) { [NSException raise:NSInternalInconsistencyException format:@"parseState is NULL."];          }
  if(string     == NULL) { [NSException raise:NSInvalidArgumentException       format:@"The string argument is NULL."]; }
  
  return(_JKParseUTF8String(parseState, YES, string, (size_t)length, error));
}

- (id)mutableObjectWithData:(NSData *)jsonData
{
  return([self mutableObjectWithData:jsonData error:NULL]);
}

- (id)mutableObjectWithData:(NSData *)jsonData error:(NSError **)error
{
  if(jsonData == NULL) { [NSException raise:NSInvalidArgumentException format:@"The TMBJSONData argument is NULL."]; }
  return([self mutableObjectWithUTF8String:(const unsigned char *)[jsonData bytes] length:[jsonData length] error:error]);
}

@end

/*
 The NSString and NSData convenience methods need a little bit of explanation.
 
 Prior to TMBJSONKit v1.4, the NSString -objectFromJSONStringWithParseOptions:error: method looked like
 
 const unsigned char *utf8String = (const unsigned char *)[self UTF8String];
 if(utf8String == NULL) { return(NULL); }
 size_t               utf8Length = strlen((const char *)utf8String); 
 return([[JSONDecoder decoderWithParseOptions:parseOptionFlags] parseUTF8String:utf8String length:utf8Length error:error]);
 
 This changed with v1.4 to a more complicated method.  The reason for this is to keep the amount of memory that is
 allocated, but not yet freed because it is dependent on the autorelease pool to pop before it can be reclaimed.
 
 In the simpler v1.3 code, this included all the bytes used to store the -UTF8String along with the TMBJSONDecoder and all its overhead.
 
 Now we use an autoreleased CFMutableData that is sized to the UTF8 length of the NSString in question and is used to hold the UTF8
 conversion of said string.
 
 Once parsed, the CFMutableData has its length set to 0.  This should, hopefully, allow the CFMutableData to realloc and/or free
 the buffer.
 
 Another change made was a slight modification to TMBJSONDecoder so that most of the cleanup work that was done in -dealloc was moved
 to a private, internal function.  These convenience routines keep the pointer to the autoreleased TMBJSONDecoder and calls
 _JSONDecoderCleanup() to early release the decoders resources since we already know that particular decoder is not going to be used
 again.  
 
 If everything goes smoothly, this will most likely result in perhaps a few hundred bytes that are allocated but waiting for the
 autorelease pool to pop.  This is compared to the thousands and easily hundreds of thousands of bytes that would have been in
 autorelease limbo.  It's more complicated for us, but a win for the user.
 
 Autorelease objects are used in case things don't go smoothly.  By having them autoreleased, we effectively guarantee that our
 requirement to -release the object is always met, not matter what goes wrong.  The downside is having a an object or two in
 autorelease limbo, but we've done our best to minimize that impact, so it all balances out.
 */

@implementation NSString (JSONKitDeserializing)

static id _NSStringObjectFromJSONString(NSString *jsonString, TMBJKParseOptionFlags parseOptionFlags, NSError **error, BOOL mutableCollection) {
  id                returnObject = NULL;
  CFMutableDataRef  mutableData  = NULL;
  TMBJSONDecoder      *decoder      = NULL;
  
  CFIndex    stringLength     = CFStringGetLength((CFStringRef)jsonString);
  NSUInteger stringUTF8Length = [jsonString lengthOfBytesUsingEncoding:NSUTF8StringEncoding];
  
  if((mutableData = (CFMutableDataRef)[(id)CFDataCreateMutable(NULL, (NSUInteger)stringUTF8Length) autorelease]) != NULL) {
    UInt8   *utf8String = CFDataGetMutableBytePtr(mutableData);
    CFIndex  usedBytes  = 0L, convertedCount = 0L;
    
    convertedCount = CFStringGetBytes((CFStringRef)jsonString, CFRangeMake(0L, stringLength), kCFStringEncodingUTF8, '?', NO, utf8String, (NSUInteger)stringUTF8Length, &usedBytes);
    if(TMBJK_EXPECT_F(convertedCount != stringLength) || TMBJK_EXPECT_F(usedBytes < 0L)) { if(error != NULL) { *error = [NSError errorWithDomain:@"JKErrorDomain" code:-1L userInfo:[NSDictionary dictionaryWithObject:@"An error occurred converting the contents of a NSString to UTF8." forKey:NSLocalizedDescriptionKey]]; } goto exitNow; }
    
    if(mutableCollection == NO) { returnObject = [(decoder = [TMBJSONDecoder decoderWithParseOptions:parseOptionFlags])        objectWithUTF8String:(const unsigned char *)utf8String length:(size_t)usedBytes error:error]; }
    else                        { returnObject = [(decoder = [TMBJSONDecoder decoderWithParseOptions:parseOptionFlags]) mutableObjectWithUTF8String:(const unsigned char *)utf8String length:(size_t)usedBytes error:error]; }
  }
  
exitNow:
  if(mutableData != NULL) { CFDataSetLength(mutableData, 0L); }
  if(decoder     != NULL) { _JSONDecoderCleanup(decoder);     }
  return(returnObject);
}

- (id)objectFromJSONString
{
  return([self objectFromJSONStringWithParseOptions:TMBJKParseOptionStrict error:NULL]);
}

- (id)objectFromJSONStringWithParseOptions:(TMBJKParseOptionFlags)parseOptionFlags
{
  return([self objectFromJSONStringWithParseOptions:parseOptionFlags error:NULL]);
}

- (id)objectFromJSONStringWithParseOptions:(TMBJKParseOptionFlags)parseOptionFlags error:(NSError **)error
{
  return(_NSStringObjectFromJSONString(self, parseOptionFlags, error, NO));
}


- (id)mutableObjectFromJSONString
{
  return([self mutableObjectFromJSONStringWithParseOptions:TMBJKParseOptionStrict error:NULL]);
}

- (id)mutableObjectFromJSONStringWithParseOptions:(TMBJKParseOptionFlags)parseOptionFlags
{
  return([self mutableObjectFromJSONStringWithParseOptions:parseOptionFlags error:NULL]);
}

- (id)mutableObjectFromJSONStringWithParseOptions:(TMBJKParseOptionFlags)parseOptionFlags error:(NSError **)error
{
  return(_NSStringObjectFromJSONString(self, parseOptionFlags, error, YES));
}

@end

@implementation NSData (JSONKitDeserializing)

- (id)objectFromJSONData
{
  return([self objectFromJSONDataWithParseOptions:TMBJKParseOptionStrict error:NULL]);
}

- (id)objectFromJSONDataWithParseOptions:(TMBJKParseOptionFlags)parseOptionFlags
{
  return([self objectFromJSONDataWithParseOptions:parseOptionFlags error:NULL]);
}

- (id)objectFromJSONDataWithParseOptions:(TMBJKParseOptionFlags)parseOptionFlags error:(NSError **)error
{
  TMBJSONDecoder *decoder = NULL;
  id returnObject = [(decoder = [TMBJSONDecoder decoderWithParseOptions:parseOptionFlags]) objectWithData:self error:error];
  if(decoder != NULL) { _JSONDecoderCleanup(decoder); }
  return(returnObject);
}

- (id)mutableObjectFromJSONData
{
  return([self mutableObjectFromJSONDataWithParseOptions:TMBJKParseOptionStrict error:NULL]);
}

- (id)mutableObjectFromJSONDataWithParseOptions:(TMBJKParseOptionFlags)parseOptionFlags
{
  return([self mutableObjectFromJSONDataWithParseOptions:parseOptionFlags error:NULL]);
}

- (id)mutableObjectFromJSONDataWithParseOptions:(TMBJKParseOptionFlags)parseOptionFlags error:(NSError **)error
{
  TMBJSONDecoder *decoder = NULL;
  id returnObject = [(decoder = [TMBJSONDecoder decoderWithParseOptions:parseOptionFlags]) mutableObjectWithData:self error:error];
  if(decoder != NULL) { _JSONDecoderCleanup(decoder); }
  return(returnObject);
}


@end

////////////
#pragma mark -
#pragma mark Encoding / deserializing functions

static void jk_encode_error(TMBJKEncodeState *encodeState, NSString *format, ...) {
  NSCParameterAssert((encodeState != NULL) && (format != NULL));

  va_list varArgsList;
  va_start(varArgsList, format);
  NSString *formatString = [[[NSString alloc] initWithFormat:format arguments:varArgsList] autorelease];
  va_end(varArgsList);

  if(encodeState->error == NULL) {
    encodeState->error = [NSError errorWithDomain:@"JKErrorDomain" code:-1L userInfo:
                                   [NSDictionary dictionaryWithObjectsAndKeys:
                                                                              formatString, NSLocalizedDescriptionKey,
                                                                              NULL]];
  }
}

TMBJK_STATIC_INLINE void jk_encode_updateCache(TMBJKEncodeState *encodeState, TMBJKEncodeCache *cacheSlot, size_t startingAtIndex, id object) {
  NSCParameterAssert(encodeState != NULL);
  if(TMBJK_EXPECT_T(cacheSlot != NULL)) {
    NSCParameterAssert((object != NULL) && (startingAtIndex <= encodeState->atIndex));
    cacheSlot->object = object;
    cacheSlot->offset = startingAtIndex;
    cacheSlot->length = (size_t)(encodeState->atIndex - startingAtIndex);  
  }
}

static int jk_encode_printf(TMBJKEncodeState *encodeState, TMBJKEncodeCache *cacheSlot, size_t startingAtIndex, id object, const char *format, ...) {
  va_list varArgsList, varArgsListCopy;
  va_start(varArgsList, format);
  va_copy(varArgsListCopy, varArgsList);

  NSCParameterAssert((encodeState != NULL) && (encodeState->atIndex < encodeState->stringBuffer.bytes.length) && (startingAtIndex <= encodeState->atIndex) && (format != NULL));

  ssize_t  formattedStringLength = 0L;
  int      returnValue           = 0;

  if(TMBJK_EXPECT_T((formattedStringLength = vsnprintf((char *)&encodeState->stringBuffer.bytes.ptr[encodeState->atIndex], (encodeState->stringBuffer.bytes.length - encodeState->atIndex), format, varArgsList)) >= (ssize_t)(encodeState->stringBuffer.bytes.length - encodeState->atIndex))) {
    NSCParameterAssert(((encodeState->atIndex + (formattedStringLength * 2UL) + 256UL) > encodeState->stringBuffer.bytes.length));
    if(TMBJK_EXPECT_F(((encodeState->atIndex + (formattedStringLength * 2UL) + 256UL) > encodeState->stringBuffer.bytes.length)) && TMBJK_EXPECT_F((jk_managedBuffer_resize(&encodeState->stringBuffer, encodeState->atIndex + (formattedStringLength * 2UL)+ 4096UL) == NULL))) { jk_encode_error(encodeState, @"Unable to resize temporary buffer."); returnValue = 1; goto exitNow; }
    if(TMBJK_EXPECT_F((formattedStringLength = vsnprintf((char *)&encodeState->stringBuffer.bytes.ptr[encodeState->atIndex], (encodeState->stringBuffer.bytes.length - encodeState->atIndex), format, varArgsListCopy)) >= (ssize_t)(encodeState->stringBuffer.bytes.length - encodeState->atIndex))) { jk_encode_error(encodeState, @"vsnprintf failed unexpectedly."); returnValue = 1; goto exitNow; }
  }
  
exitNow:
  va_end(varArgsList);
  va_end(varArgsListCopy);
  if(TMBJK_EXPECT_T(returnValue == 0)) { encodeState->atIndex += formattedStringLength; jk_encode_updateCache(encodeState, cacheSlot, startingAtIndex, object); }
  return(returnValue);
}

static int jk_encode_write(TMBJKEncodeState *encodeState, TMBJKEncodeCache *cacheSlot, size_t startingAtIndex, id object, const char *format) {
  NSCParameterAssert((encodeState != NULL) && (encodeState->atIndex < encodeState->stringBuffer.bytes.length) && (startingAtIndex <= encodeState->atIndex) && (format != NULL));
  if(TMBJK_EXPECT_F(((encodeState->atIndex + strlen(format) + 256UL) > encodeState->stringBuffer.bytes.length)) && TMBJK_EXPECT_F((jk_managedBuffer_resize(&encodeState->stringBuffer, encodeState->atIndex + strlen(format) + 1024UL) == NULL))) { jk_encode_error(encodeState, @"Unable to resize temporary buffer."); return(1); }

  size_t formatIdx = 0UL;
  for(formatIdx = 0UL; format[formatIdx] != 0; formatIdx++) { NSCParameterAssert(encodeState->atIndex < encodeState->stringBuffer.bytes.length); encodeState->stringBuffer.bytes.ptr[encodeState->atIndex++] = format[formatIdx]; }
  jk_encode_updateCache(encodeState, cacheSlot, startingAtIndex, object);
  return(0);
}

static int jk_encode_writePrettyPrintWhiteSpace(TMBJKEncodeState *encodeState) {
  NSCParameterAssert((encodeState != NULL) && ((encodeState->serializeOptionFlags & TMBJKSerializeOptionPretty) != 0UL));
  if(TMBJK_EXPECT_F((encodeState->atIndex + ((encodeState->depth + 1UL) * 2UL) + 16UL) > encodeState->stringBuffer.bytes.length) && TMBJK_EXPECT_T(jk_managedBuffer_resize(&encodeState->stringBuffer, encodeState->atIndex + ((encodeState->depth + 1UL) * 2UL) + 4096UL) == NULL)) { jk_encode_error(encodeState, @"Unable to resize temporary buffer."); return(1); }
  encodeState->stringBuffer.bytes.ptr[encodeState->atIndex++] = '\n';
  size_t depthWhiteSpace = 0UL;
  for(depthWhiteSpace = 0UL; depthWhiteSpace < (encodeState->depth * 2UL); depthWhiteSpace++) { NSCParameterAssert(encodeState->atIndex < encodeState->stringBuffer.bytes.length); encodeState->stringBuffer.bytes.ptr[encodeState->atIndex++] = ' '; }
  return(0);
}  

static int jk_encode_write1slow(TMBJKEncodeState *encodeState, ssize_t depthChange, const char *format) {
  NSCParameterAssert((encodeState != NULL) && (encodeState->atIndex < encodeState->stringBuffer.bytes.length) && (format != NULL) && ((depthChange >= -1L) && (depthChange <= 1L)) && ((encodeState->depth == 0UL) ? (depthChange >= 0L) : 1) && ((encodeState->serializeOptionFlags & TMBJKSerializeOptionPretty) != 0UL));
  if(TMBJK_EXPECT_F((encodeState->atIndex + ((encodeState->depth + 1UL) * 2UL) + 16UL) > encodeState->stringBuffer.bytes.length) && TMBJK_EXPECT_F(jk_managedBuffer_resize(&encodeState->stringBuffer, encodeState->atIndex + ((encodeState->depth + 1UL) * 2UL) + 4096UL) == NULL)) { jk_encode_error(encodeState, @"Unable to resize temporary buffer."); return(1); }
  encodeState->depth += depthChange;
  if(TMBJK_EXPECT_T(format[0] == ':')) { encodeState->stringBuffer.bytes.ptr[encodeState->atIndex++] = format[0]; encodeState->stringBuffer.bytes.ptr[encodeState->atIndex++] = ' '; }
  else {
    if(TMBJK_EXPECT_F(depthChange == -1L)) { if(TMBJK_EXPECT_F(jk_encode_writePrettyPrintWhiteSpace(encodeState))) { return(1); } }
    encodeState->stringBuffer.bytes.ptr[encodeState->atIndex++] = format[0];
    if(TMBJK_EXPECT_T(depthChange != -1L)) { if(TMBJK_EXPECT_F(jk_encode_writePrettyPrintWhiteSpace(encodeState))) { return(1); } }
  }
  NSCParameterAssert(encodeState->atIndex < encodeState->stringBuffer.bytes.length);
  return(0);
}

static int jk_encode_write1fast(TMBJKEncodeState *encodeState, ssize_t depthChange TMBJK_UNUSED_ARG, const char *format) {
  NSCParameterAssert((encodeState != NULL) && (encodeState->atIndex < encodeState->stringBuffer.bytes.length) && ((encodeState->serializeOptionFlags & TMBJKSerializeOptionPretty) == 0UL));
  if(TMBJK_EXPECT_T((encodeState->atIndex + 4UL) < encodeState->stringBuffer.bytes.length)) { encodeState->stringBuffer.bytes.ptr[encodeState->atIndex++] = format[0]; }
  else { return(jk_encode_write(encodeState, NULL, 0UL, NULL, format)); }
  return(0);
}

static int jk_encode_writen(TMBJKEncodeState *encodeState, TMBJKEncodeCache *cacheSlot, size_t startingAtIndex, id object, const char *format, size_t length) {
  NSCParameterAssert((encodeState != NULL) && (encodeState->atIndex < encodeState->stringBuffer.bytes.length) && (startingAtIndex <= encodeState->atIndex));
  if(TMBJK_EXPECT_F((encodeState->stringBuffer.bytes.length - encodeState->atIndex) < (length + 4UL))) { if(jk_managedBuffer_resize(&encodeState->stringBuffer, encodeState->atIndex + 4096UL + length) == NULL) { jk_encode_error(encodeState, @"Unable to resize temporary buffer."); return(1); } }
  memcpy(encodeState->stringBuffer.bytes.ptr + encodeState->atIndex, format, length);
  encodeState->atIndex += length;
  jk_encode_updateCache(encodeState, cacheSlot, startingAtIndex, object);
  return(0);
}

TMBJK_STATIC_INLINE TMBJKHash jk_encode_object_hash(void *objectPtr) {
  return( ( (((TMBJKHash)objectPtr) >> 21) ^ (((TMBJKHash)objectPtr) >> 9)   ) + (((TMBJKHash)objectPtr) >> 4) );
}

static int jk_encode_add_atom_to_buffer(TMBJKEncodeState *encodeState, void *objectPtr) {
  NSCParameterAssert((encodeState != NULL) && (encodeState->atIndex < encodeState->stringBuffer.bytes.length) && (objectPtr != NULL));

  id     object          = (id)objectPtr, encodeCacheObject = object;
  int    isClass         = TMBJKClassUnknown;
  size_t startingAtIndex = encodeState->atIndex;

  TMBJKHash         objectHash = jk_encode_object_hash(objectPtr);
  TMBJKEncodeCache *cacheSlot  = &encodeState->cache[objectHash % TMBJK_ENCODE_CACHE_SLOTS];

  if(TMBJK_EXPECT_T(cacheSlot->object == object)) {
    NSCParameterAssert((cacheSlot->object != NULL) &&
                       (cacheSlot->offset < encodeState->atIndex)                   && ((cacheSlot->offset + cacheSlot->length) < encodeState->atIndex)                                    &&
                       (cacheSlot->offset < encodeState->stringBuffer.bytes.length) && ((cacheSlot->offset + cacheSlot->length) < encodeState->stringBuffer.bytes.length)                  &&
                       ((encodeState->stringBuffer.bytes.ptr + encodeState->atIndex)                     < (encodeState->stringBuffer.bytes.ptr + encodeState->stringBuffer.bytes.length)) &&
                       ((encodeState->stringBuffer.bytes.ptr + cacheSlot->offset)                        < (encodeState->stringBuffer.bytes.ptr + encodeState->stringBuffer.bytes.length)) &&
                       ((encodeState->stringBuffer.bytes.ptr + cacheSlot->offset + cacheSlot->length)    < (encodeState->stringBuffer.bytes.ptr + encodeState->stringBuffer.bytes.length)));
    if(TMBJK_EXPECT_F(((encodeState->atIndex + cacheSlot->length + 256UL) > encodeState->stringBuffer.bytes.length)) && TMBJK_EXPECT_F((jk_managedBuffer_resize(&encodeState->stringBuffer, encodeState->atIndex + cacheSlot->length + 1024UL) == NULL))) { jk_encode_error(encodeState, @"Unable to resize temporary buffer."); return(1); }
    NSCParameterAssert(((encodeState->atIndex + cacheSlot->length) < encodeState->stringBuffer.bytes.length) &&
                       ((encodeState->stringBuffer.bytes.ptr + encodeState->atIndex)                     < (encodeState->stringBuffer.bytes.ptr + encodeState->stringBuffer.bytes.length)) &&
                       ((encodeState->stringBuffer.bytes.ptr + encodeState->atIndex + cacheSlot->length) < (encodeState->stringBuffer.bytes.ptr + encodeState->stringBuffer.bytes.length)) &&
                       ((encodeState->stringBuffer.bytes.ptr + cacheSlot->offset)                        < (encodeState->stringBuffer.bytes.ptr + encodeState->stringBuffer.bytes.length)) &&
                       ((encodeState->stringBuffer.bytes.ptr + cacheSlot->offset + cacheSlot->length)    < (encodeState->stringBuffer.bytes.ptr + encodeState->stringBuffer.bytes.length)) &&
                       ((encodeState->stringBuffer.bytes.ptr + cacheSlot->offset + cacheSlot->length)    < (encodeState->stringBuffer.bytes.ptr + encodeState->atIndex)));
    memcpy(encodeState->stringBuffer.bytes.ptr + encodeState->atIndex, encodeState->stringBuffer.bytes.ptr + cacheSlot->offset, cacheSlot->length);
    encodeState->atIndex += cacheSlot->length;
    return(0);
  }

  // When we encounter a class that we do not handle, and we have either a delegate or block that the user supplied to format unsupported classes,
  // we "re-run" the object check.  However, we re-run the object check exactly ONCE.  If the user supplies an object that isn't one of the
  // supported classes, we fail the second time (i.e., double fault error).
  BOOL rerunningAfterClassFormatter = NO;
 rerunAfterClassFormatter:;

  // XXX XXX XXX XXX
  //     
  //     We need to work around a bug in 10.7, which breaks ABI compatibility with Objective-C going back not just to 10.0, but OpenStep and even NextStep.
  //     
  //     It has long been documented that "the very first thing that a pointer to an Objective-C object "points to" is a pointer to that objects class".
  //     
  //     This is euphemistically called "tagged pointers".  There are a number of highly technical problems with this, most involving long passages from
  //     the C standard(s).  In short, one can make a strong case, couched from the perspective of the C standard(s), that that 10.7 "tagged pointers" are
  //     fundamentally Wrong and Broken, and should have never been implemented.  Assuming those points are glossed over, because the change is very clearly
  //     breaking ABI compatibility, this should have resulted in a minimum of a "minimum version required" bump in various shared libraries to prevent
  //     causes code that used to work just fine to suddenly break without warning.
  //
  //     In fact, the C standard says that the hack below is "undefined behavior"- there is no requirement that the 10.7 tagged pointer hack of setting the
  //     "lower, unused bits" must be preserved when casting the result to an integer type, but this "works" because for most architectures
  //     `sizeof(long) == sizeof(void *)` and the compiler uses the same representation for both.  (note: this is informal, not meant to be
  //     normative or pedantically correct).
  //     
  //     In other words, while this "works" for now, technically the compiler is not obligated to do "what we want", and a later version of the compiler
  //     is not required in any way to produce the same results or behavior that earlier versions of the compiler did for the statement below.
  //
  //     Fan-fucking-tastic.
  //     
  //     Why not just use `object_getClass()`?  Because `object->isa` reduces to (typically) a *single* instruction.  Calling `object_getClass()` requires
  //     that the compiler potentially spill registers, establish a function call frame / environment, and finally execute a "jump subroutine" instruction.
  //     Then, the called subroutine must spend half a dozen instructions in its prolog, however many instructions doing whatever it does, then half a dozen
  //     instructions in its prolog.  One instruction compared to dozens, maybe a hundred instructions.
  //     
  //     Yes, that's one to two orders of magnitude difference.  Which is compelling in its own right.  When going for performance, you're often happy with
  //     gains in the two to three percent range.
  //     
  // XXX XXX XXX XXX

  BOOL workAroundMacOSXABIBreakingBug = NO;
  if(TMBJK_EXPECT_F(((NSUInteger)object) & 0x1)) { workAroundMacOSXABIBreakingBug = YES; goto slowClassLookup; }

       if(TMBJK_EXPECT_T(object->isa == encodeState->fastClassLookup.stringClass))     { isClass = TMBJKClassString;     }
  else if(TMBJK_EXPECT_T(object->isa == encodeState->fastClassLookup.numberClass))     { isClass = TMBJKClassNumber;     }
  else if(TMBJK_EXPECT_T(object->isa == encodeState->fastClassLookup.dictionaryClass)) { isClass = TMBJKClassDictionary; }
  else if(TMBJK_EXPECT_T(object->isa == encodeState->fastClassLookup.arrayClass))      { isClass = TMBJKClassArray;      }
  else if(TMBJK_EXPECT_T(object->isa == encodeState->fastClassLookup.nullClass))       { isClass = TMBJKClassNull;       }
  else {
  slowClassLookup:
         if(TMBJK_EXPECT_T([object isKindOfClass:[NSString     class]])) { if(workAroundMacOSXABIBreakingBug == NO) { encodeState->fastClassLookup.stringClass     = object->isa; } isClass = TMBJKClassString;     }
    else if(TMBJK_EXPECT_T([object isKindOfClass:[NSNumber     class]])) { if(workAroundMacOSXABIBreakingBug == NO) { encodeState->fastClassLookup.numberClass     = object->isa; } isClass = TMBJKClassNumber;     }
    else if(TMBJK_EXPECT_T([object isKindOfClass:[NSDictionary class]])) { if(workAroundMacOSXABIBreakingBug == NO) { encodeState->fastClassLookup.dictionaryClass = object->isa; } isClass = TMBJKClassDictionary; }
    else if(TMBJK_EXPECT_T([object isKindOfClass:[NSArray      class]])) { if(workAroundMacOSXABIBreakingBug == NO) { encodeState->fastClassLookup.arrayClass      = object->isa; } isClass = TMBJKClassArray;      }
    else if(TMBJK_EXPECT_T([object isKindOfClass:[NSNull       class]])) { if(workAroundMacOSXABIBreakingBug == NO) { encodeState->fastClassLookup.nullClass       = object->isa; } isClass = TMBJKClassNull;       }
    else {
      if((rerunningAfterClassFormatter == NO) && (
#ifdef __BLOCKS__
           ((encodeState->classFormatterBlock) && ((object = encodeState->classFormatterBlock(object))                                                                         != NULL)) ||
#endif
           ((encodeState->classFormatterIMP)   && ((object = encodeState->classFormatterIMP(encodeState->classFormatterDelegate, encodeState->classFormatterSelector, object)) != NULL))    )) { rerunningAfterClassFormatter = YES; goto rerunAfterClassFormatter; }
      
      if(rerunningAfterClassFormatter == NO) { jk_encode_error(encodeState, @"Unable to serialize object class %@.", NSStringFromClass([encodeCacheObject class])); return(1); }
      else { jk_encode_error(encodeState, @"Unable to serialize object class %@ that was returned by the unsupported class formatter.  Original object class was %@.", (object == NULL) ? @"NULL" : NSStringFromClass([object class]), NSStringFromClass([encodeCacheObject class])); return(1); }
    }
  }

  // This is here for the benefit of the optimizer.  It allows the optimizer to do loop invariant code motion for the TMBJKClassArray
  // and TMBJKClassDictionary cases when printing simple, single characters via jk_encode_write(), which is actually a macro:
  // #define TMBJK_encode_write1(es, dc, f) (_TMBjk_encode_prettyPrint ? jk_encode_write1slow(es, dc, f) : TMBJK_encode_write1fast(es, dc, f))
  int _TMBjk_encode_prettyPrint = TMBJK_EXPECT_T((encodeState->serializeOptionFlags & TMBJKSerializeOptionPretty) == 0) ? 0 : 1;
  
  switch(isClass) {
    case TMBJKClassString:
      {
        {
          const unsigned char *cStringPtr = (const unsigned char *)CFStringGetCStringPtr((CFStringRef)object, kCFStringEncodingMacRoman);
          if(cStringPtr != NULL) {
            const unsigned char *utf8String = cStringPtr;
            size_t               utf8Idx    = 0UL;

            CFIndex stringLength = CFStringGetLength((CFStringRef)object);
            if(TMBJK_EXPECT_F(((encodeState->atIndex + (stringLength * 2UL) + 256UL) > encodeState->stringBuffer.bytes.length)) && TMBJK_EXPECT_F((jk_managedBuffer_resize(&encodeState->stringBuffer, encodeState->atIndex + (stringLength * 2UL) + 1024UL) == NULL))) { jk_encode_error(encodeState, @"Unable to resize temporary buffer."); return(1); }

            if(TMBJK_EXPECT_T((encodeState->encodeOption & TMBJKEncodeOptionStringObjTrimQuotes) == 0UL)) { encodeState->stringBuffer.bytes.ptr[encodeState->atIndex++] = '\"'; }
            for(utf8Idx = 0UL; utf8String[utf8Idx] != 0U; utf8Idx++) {
              NSCParameterAssert(((&encodeState->stringBuffer.bytes.ptr[encodeState->atIndex]) - encodeState->stringBuffer.bytes.ptr) < (ssize_t)encodeState->stringBuffer.bytes.length);
              NSCParameterAssert(encodeState->atIndex < encodeState->stringBuffer.bytes.length);
              if(TMBJK_EXPECT_F(utf8String[utf8Idx] >= 0x80U)) { encodeState->atIndex = startingAtIndex; goto slowUTF8Path; }
              if(TMBJK_EXPECT_F(utf8String[utf8Idx] <  0x20U)) {
                switch(utf8String[utf8Idx]) {
                  case '\b': encodeState->stringBuffer.bytes.ptr[encodeState->atIndex++] = '\\'; encodeState->stringBuffer.bytes.ptr[encodeState->atIndex++] = 'b'; break;
                  case '\f': encodeState->stringBuffer.bytes.ptr[encodeState->atIndex++] = '\\'; encodeState->stringBuffer.bytes.ptr[encodeState->atIndex++] = 'f'; break;
                  case '\n': encodeState->stringBuffer.bytes.ptr[encodeState->atIndex++] = '\\'; encodeState->stringBuffer.bytes.ptr[encodeState->atIndex++] = 'n'; break;
                  case '\r': encodeState->stringBuffer.bytes.ptr[encodeState->atIndex++] = '\\'; encodeState->stringBuffer.bytes.ptr[encodeState->atIndex++] = 'r'; break;
                  case '\t': encodeState->stringBuffer.bytes.ptr[encodeState->atIndex++] = '\\'; encodeState->stringBuffer.bytes.ptr[encodeState->atIndex++] = 't'; break;
                  default: if(TMBJK_EXPECT_F(jk_encode_printf(encodeState, NULL, 0UL, NULL, "\\u%4.4x", utf8String[utf8Idx]))) { return(1); } break;
                }
              } else {
                if(TMBJK_EXPECT_F(utf8String[utf8Idx] == '\"') || TMBJK_EXPECT_F(utf8String[utf8Idx] == '\\') || (TMBJK_EXPECT_F(encodeState->serializeOptionFlags & TMBJKSerializeOptionEscapeForwardSlashes) && TMBJK_EXPECT_F(utf8String[utf8Idx] == '/'))) { encodeState->stringBuffer.bytes.ptr[encodeState->atIndex++] = '\\'; }
                encodeState->stringBuffer.bytes.ptr[encodeState->atIndex++] = utf8String[utf8Idx];
              }
            }
            NSCParameterAssert((encodeState->atIndex + 1UL) < encodeState->stringBuffer.bytes.length);
            if(TMBJK_EXPECT_T((encodeState->encodeOption & TMBJKEncodeOptionStringObjTrimQuotes) == 0UL)) { encodeState->stringBuffer.bytes.ptr[encodeState->atIndex++] = '\"'; }
            jk_encode_updateCache(encodeState, cacheSlot, startingAtIndex, encodeCacheObject);
            return(0);
          }
        }

      slowUTF8Path:
        {
          CFIndex stringLength        = CFStringGetLength((CFStringRef)object);
          CFIndex maxStringUTF8Length = CFStringGetMaximumSizeForEncoding(stringLength, kCFStringEncodingUTF8) + 32L;
        
          if(TMBJK_EXPECT_F((size_t)maxStringUTF8Length > encodeState->utf8ConversionBuffer.bytes.length) && TMBJK_EXPECT_F(jk_managedBuffer_resize(&encodeState->utf8ConversionBuffer, maxStringUTF8Length + 1024UL) == NULL)) { jk_encode_error(encodeState, @"Unable to resize temporary buffer."); return(1); }
        
          CFIndex usedBytes = 0L, convertedCount = 0L;
          convertedCount = CFStringGetBytes((CFStringRef)object, CFRangeMake(0L, stringLength), kCFStringEncodingUTF8, '?', NO, encodeState->utf8ConversionBuffer.bytes.ptr, encodeState->utf8ConversionBuffer.bytes.length - 16L, &usedBytes);
          if(TMBJK_EXPECT_F(convertedCount != stringLength) || TMBJK_EXPECT_F(usedBytes < 0L)) { jk_encode_error(encodeState, @"An error occurred converting the contents of a NSString to UTF8."); return(1); }
        
          if(TMBJK_EXPECT_F((encodeState->atIndex + (maxStringUTF8Length * 2UL) + 256UL) > encodeState->stringBuffer.bytes.length) && TMBJK_EXPECT_F(jk_managedBuffer_resize(&encodeState->stringBuffer, encodeState->atIndex + (maxStringUTF8Length * 2UL) + 1024UL) == NULL)) { jk_encode_error(encodeState, @"Unable to resize temporary buffer."); return(1); }
        
          const unsigned char *utf8String = encodeState->utf8ConversionBuffer.bytes.ptr;
        
          size_t utf8Idx = 0UL;
          if(TMBJK_EXPECT_T((encodeState->encodeOption & TMBJKEncodeOptionStringObjTrimQuotes) == 0UL)) { encodeState->stringBuffer.bytes.ptr[encodeState->atIndex++] = '\"'; }
          for(utf8Idx = 0UL; utf8Idx < (size_t)usedBytes; utf8Idx++) {
            NSCParameterAssert(((&encodeState->stringBuffer.bytes.ptr[encodeState->atIndex]) - encodeState->stringBuffer.bytes.ptr) < (ssize_t)encodeState->stringBuffer.bytes.length);
            NSCParameterAssert(encodeState->atIndex < encodeState->stringBuffer.bytes.length);
            NSCParameterAssert((CFIndex)utf8Idx < usedBytes);
            if(TMBJK_EXPECT_F(utf8String[utf8Idx] < 0x20U)) {
              switch(utf8String[utf8Idx]) {
                case '\b': encodeState->stringBuffer.bytes.ptr[encodeState->atIndex++] = '\\'; encodeState->stringBuffer.bytes.ptr[encodeState->atIndex++] = 'b'; break;
                case '\f': encodeState->stringBuffer.bytes.ptr[encodeState->atIndex++] = '\\'; encodeState->stringBuffer.bytes.ptr[encodeState->atIndex++] = 'f'; break;
                case '\n': encodeState->stringBuffer.bytes.ptr[encodeState->atIndex++] = '\\'; encodeState->stringBuffer.bytes.ptr[encodeState->atIndex++] = 'n'; break;
                case '\r': encodeState->stringBuffer.bytes.ptr[encodeState->atIndex++] = '\\'; encodeState->stringBuffer.bytes.ptr[encodeState->atIndex++] = 'r'; break;
                case '\t': encodeState->stringBuffer.bytes.ptr[encodeState->atIndex++] = '\\'; encodeState->stringBuffer.bytes.ptr[encodeState->atIndex++] = 't'; break;
                default: if(TMBJK_EXPECT_F(jk_encode_printf(encodeState, NULL, 0UL, NULL, "\\u%4.4x", utf8String[utf8Idx]))) { return(1); } break;
              }
            } else {
              if(TMBJK_EXPECT_F(utf8String[utf8Idx] >= 0x80U) && (encodeState->serializeOptionFlags & TMBJKSerializeOptionEscapeUnicode)) {
                const unsigned char *nextValidCharacter = NULL;
                UTF32                u32ch              = 0U;
                ConversionResult     result;

                if(TMBJK_EXPECT_F((result = ConvertSingleCodePointInUTF8(&utf8String[utf8Idx], &utf8String[usedBytes], (UTF8 const **)&nextValidCharacter, &u32ch)) != conversionOK)) { jk_encode_error(encodeState, @"Error converting UTF8."); return(1); }
                else {
                  utf8Idx = (nextValidCharacter - utf8String) - 1UL;
                  if(TMBJK_EXPECT_T(u32ch <= 0xffffU)) { if(TMBJK_EXPECT_F(jk_encode_printf(encodeState, NULL, 0UL, NULL, "\\u%4.4x", u32ch)))                                                           { return(1); } }
                  else                              { if(TMBJK_EXPECT_F(jk_encode_printf(encodeState, NULL, 0UL, NULL, "\\u%4.4x\\u%4.4x", (0xd7c0U + (u32ch >> 10)), (0xdc00U + (u32ch & 0x3ffU))))) { return(1); } }
                }
              } else {
                if(TMBJK_EXPECT_F(utf8String[utf8Idx] == '\"') || TMBJK_EXPECT_F(utf8String[utf8Idx] == '\\') || (TMBJK_EXPECT_F(encodeState->serializeOptionFlags & TMBJKSerializeOptionEscapeForwardSlashes) && TMBJK_EXPECT_F(utf8String[utf8Idx] == '/'))) { encodeState->stringBuffer.bytes.ptr[encodeState->atIndex++] = '\\'; }
                encodeState->stringBuffer.bytes.ptr[encodeState->atIndex++] = utf8String[utf8Idx];
              }
            }
          }
          NSCParameterAssert((encodeState->atIndex + 1UL) < encodeState->stringBuffer.bytes.length);
          if(TMBJK_EXPECT_T((encodeState->encodeOption & TMBJKEncodeOptionStringObjTrimQuotes) == 0UL)) { encodeState->stringBuffer.bytes.ptr[encodeState->atIndex++] = '\"'; }
          jk_encode_updateCache(encodeState, cacheSlot, startingAtIndex, encodeCacheObject);
          return(0);
        }
      }
      break;

    case TMBJKClassNumber:
      {
             if(object == (id)kCFBooleanTrue)  { return(jk_encode_writen(encodeState, cacheSlot, startingAtIndex, encodeCacheObject, "true",  4UL)); }
        else if(object == (id)kCFBooleanFalse) { return(jk_encode_writen(encodeState, cacheSlot, startingAtIndex, encodeCacheObject, "false", 5UL)); }
        
        const char         *objCType = [object objCType];
        char                anum[256], *aptr = &anum[255];
        int                 isNegative = 0;
        unsigned long long  ullv;
        long long           llv;
        
        if(TMBJK_EXPECT_F(objCType == NULL) || TMBJK_EXPECT_F(objCType[0] == 0) || TMBJK_EXPECT_F(objCType[1] != 0)) { jk_encode_error(encodeState, @"NSNumber conversion error, unknown type.  Type: '%s'", (objCType == NULL) ? "<NULL>" : objCType); return(1); }
        
        switch(objCType[0]) {
          case 'c': case 'i': case 's': case 'l': case 'q':
            if(TMBJK_EXPECT_T(CFNumberGetValue((CFNumberRef)object, kCFNumberLongLongType, &llv)))  {
              if(llv < 0LL)  { ullv = -llv; isNegative = 1; } else { ullv = llv; isNegative = 0; }
              goto convertNumber;
            } else { jk_encode_error(encodeState, @"Unable to get scalar value from number object."); return(1); }
            break;
          case 'C': case 'I': case 'S': case 'L': case 'Q': case 'B':
            if(TMBJK_EXPECT_T(CFNumberGetValue((CFNumberRef)object, kCFNumberLongLongType, &ullv))) {
            convertNumber:
              if(TMBJK_EXPECT_F(ullv < 10ULL)) { *--aptr = ullv + '0'; } else { while(TMBJK_EXPECT_T(ullv > 0ULL)) { *--aptr = (ullv % 10ULL) + '0'; ullv /= 10ULL; NSCParameterAssert(aptr > anum); } }
              if(isNegative) { *--aptr = '-'; }
              NSCParameterAssert(aptr > anum);
              return(jk_encode_writen(encodeState, cacheSlot, startingAtIndex, encodeCacheObject, aptr, &anum[255] - aptr));
            } else { jk_encode_error(encodeState, @"Unable to get scalar value from number object."); return(1); }
            break;
          case 'f': case 'd':
            {
              double dv;
              if(TMBJK_EXPECT_T(CFNumberGetValue((CFNumberRef)object, kCFNumberDoubleType, &dv))) {
                if(TMBJK_EXPECT_F(!isfinite(dv))) { jk_encode_error(encodeState, @"Floating point values must be finite.  TMBJSON does not support NaN or Infinity."); return(1); }
                return(jk_encode_printf(encodeState, cacheSlot, startingAtIndex, encodeCacheObject, "%.17g", dv));
              } else { jk_encode_error(encodeState, @"Unable to get floating point value from number object."); return(1); }
            }
            break;
          default: jk_encode_error(encodeState, @"NSNumber conversion error, unknown type.  Type: '%c' / 0x%2.2x", objCType[0], objCType[0]); return(1); break;
        }
      }
      break;
    
    case TMBJKClassArray:
      {
        int     printComma = 0;
        CFIndex arrayCount = CFArrayGetCount((CFArrayRef)object), idx = 0L;
        if(TMBJK_EXPECT_F(jk_encode_write1(encodeState, 1L, "["))) { return(1); }
        if(TMBJK_EXPECT_F(arrayCount > 1020L)) {
          for(id arrayObject in object)          { if(TMBJK_EXPECT_T(printComma)) { if(TMBJK_EXPECT_F(jk_encode_write1(encodeState, 0L, ","))) { return(1); } } printComma = 1; if(TMBJK_EXPECT_F(jk_encode_add_atom_to_buffer(encodeState, arrayObject)))  { return(1); } }
        } else {
          void *objects[1024];
          CFArrayGetValues((CFArrayRef)object, CFRangeMake(0L, arrayCount), (const void **)objects);
          for(idx = 0L; idx < arrayCount; idx++) { if(TMBJK_EXPECT_T(printComma)) { if(TMBJK_EXPECT_F(jk_encode_write1(encodeState, 0L, ","))) { return(1); } } printComma = 1; if(TMBJK_EXPECT_F(jk_encode_add_atom_to_buffer(encodeState, objects[idx]))) { return(1); } }
        }
        return(jk_encode_write1(encodeState, -1L, "]"));
      }
      break;

    case TMBJKClassDictionary:
      {
        int     printComma      = 0;
        CFIndex dictionaryCount = CFDictionaryGetCount((CFDictionaryRef)object), idx = 0L;
        id      enumerateObject = TMBJK_EXPECT_F(_TMBjk_encode_prettyPrint) ? [[object allKeys] sortedArrayUsingSelector:@selector(compare:)] : object;

        if(TMBJK_EXPECT_F(jk_encode_write1(encodeState, 1L, "{"))) { return(1); }
        if(TMBJK_EXPECT_F(_TMBjk_encode_prettyPrint) || TMBJK_EXPECT_F(dictionaryCount > 1020L)) {
          for(id keyObject in enumerateObject) {
            if(TMBJK_EXPECT_T(printComma)) { if(TMBJK_EXPECT_F(jk_encode_write1(encodeState, 0L, ","))) { return(1); } }
            printComma = 1;
            if(TMBJK_EXPECT_F((keyObject->isa      != encodeState->fastClassLookup.stringClass)) && TMBJK_EXPECT_F(([keyObject   isKindOfClass:[NSString class]] == NO))) { jk_encode_error(encodeState, @"Key must be a string object."); return(1); }
            if(TMBJK_EXPECT_F(jk_encode_add_atom_to_buffer(encodeState, keyObject)))                                                        { return(1); }
            if(TMBJK_EXPECT_F(jk_encode_write1(encodeState, 0L, ":")))                                                                      { return(1); }
            if(TMBJK_EXPECT_F(jk_encode_add_atom_to_buffer(encodeState, (void *)CFDictionaryGetValue((CFDictionaryRef)object, keyObject)))) { return(1); }
          }
        } else {
          void *keys[1024], *objects[1024];
          CFDictionaryGetKeysAndValues((CFDictionaryRef)object, (const void **)keys, (const void **)objects);
          for(idx = 0L; idx < dictionaryCount; idx++) {
            if(TMBJK_EXPECT_T(printComma)) { if(TMBJK_EXPECT_F(jk_encode_write1(encodeState, 0L, ","))) { return(1); } }
            printComma = 1;
            if(TMBJK_EXPECT_F(((id)keys[idx])->isa != encodeState->fastClassLookup.stringClass) && TMBJK_EXPECT_F([(id)keys[idx] isKindOfClass:[NSString class]] == NO)) { jk_encode_error(encodeState, @"Key must be a string object."); return(1); }
            if(TMBJK_EXPECT_F(jk_encode_add_atom_to_buffer(encodeState, keys[idx])))    { return(1); }
            if(TMBJK_EXPECT_F(jk_encode_write1(encodeState, 0L, ":")))                  { return(1); }
            if(TMBJK_EXPECT_F(jk_encode_add_atom_to_buffer(encodeState, objects[idx]))) { return(1); }
          }
        }
        return(jk_encode_write1(encodeState, -1L, "}"));
      }
      break;

    case TMBJKClassNull: return(jk_encode_writen(encodeState, cacheSlot, startingAtIndex, encodeCacheObject, "null", 4UL)); break;

    default: jk_encode_error(encodeState, @"Unable to serialize object class %@.", NSStringFromClass([object class])); return(1); break;
  }

  return(0);
}


@implementation TMBJKSerializer

+ (id)serializeObject:(id)object options:(TMBJKSerializeOptionFlags)optionFlags encodeOption:(TMBJKEncodeOptionType)encodeOption block:(TMBJKSERIALIZER_BLOCKS_PROTO)block delegate:(id)delegate selector:(SEL)selector error:(NSError **)error
{
  return([[[[self alloc] init] autorelease] serializeObject:object options:optionFlags encodeOption:encodeOption block:block delegate:delegate selector:selector error:error]);
}

- (id)serializeObject:(id)object options:(TMBJKSerializeOptionFlags)optionFlags encodeOption:(TMBJKEncodeOptionType)encodeOption block:(TMBJKSERIALIZER_BLOCKS_PROTO)block delegate:(id)delegate selector:(SEL)selector error:(NSError **)error
{
#ifndef __BLOCKS__
#pragma unused(block)
#endif
  NSParameterAssert((object != NULL) && (encodeState == NULL) && ((delegate != NULL) ? (block == NULL) : 1) && ((block != NULL) ? (delegate == NULL) : 1) &&
                    (((encodeOption & TMBJKEncodeOptionCollectionObj) != 0UL) ? (((encodeOption & TMBJKEncodeOptionStringObj)     == 0UL) && ((encodeOption & TMBJKEncodeOptionStringObjTrimQuotes) == 0UL)) : 1) &&
                    (((encodeOption & TMBJKEncodeOptionStringObj)     != 0UL) ?  ((encodeOption & TMBJKEncodeOptionCollectionObj) == 0UL)                                                                 : 1));

  id returnObject = NULL;

  if(encodeState != NULL) { [self releaseState]; }
  if((encodeState = (struct TMBJKEncodeState *)calloc(1UL, sizeof(TMBJKEncodeState))) == NULL) { [NSException raise:NSMallocException format:@"Unable to allocate state structure."]; return(NULL); }

  if((error != NULL) && (*error != NULL)) { *error = NULL; }

  if(delegate != NULL) {
    if(selector                               == NULL) { [NSException raise:NSInvalidArgumentException format:@"The delegate argument is not NULL, but the selector argument is NULL."]; }
    if([delegate respondsToSelector:selector] == NO)   { [NSException raise:NSInvalidArgumentException format:@"The serializeUnsupportedClassesUsingDelegate: delegate does not respond to the selector argument."]; }
    encodeState->classFormatterDelegate = delegate;
    encodeState->classFormatterSelector = selector;
    encodeState->classFormatterIMP      = (TMBJKClassFormatterIMP)[delegate methodForSelector:selector];
    NSCParameterAssert(encodeState->classFormatterIMP != NULL);
  }

#ifdef __BLOCKS__
  encodeState->classFormatterBlock                          = block;
#endif
  encodeState->serializeOptionFlags                         = optionFlags;
  encodeState->encodeOption                                 = encodeOption;
  encodeState->stringBuffer.roundSizeUpToMultipleOf         = (1024UL * 32UL);
  encodeState->utf8ConversionBuffer.roundSizeUpToMultipleOf = 4096UL;
    
  unsigned char stackJSONBuffer[TMBJK_JSONBUFFER_SIZE] TMBJK_ALIGNED(64);
  jk_managedBuffer_setToStackBuffer(&encodeState->stringBuffer,         stackJSONBuffer, sizeof(stackJSONBuffer));

  unsigned char stackUTF8Buffer[TMBJK_UTF8BUFFER_SIZE] TMBJK_ALIGNED(64);
  jk_managedBuffer_setToStackBuffer(&encodeState->utf8ConversionBuffer, stackUTF8Buffer, sizeof(stackUTF8Buffer));

  if(((encodeOption & TMBJKEncodeOptionCollectionObj) != 0UL) && (([object isKindOfClass:[NSArray  class]] == NO) && ([object isKindOfClass:[NSDictionary class]] == NO))) { jk_encode_error(encodeState, @"Unable to serialize object class %@, expected a NSArray or NSDictionary.", NSStringFromClass([object class])); goto errorExit; }
  if(((encodeOption & TMBJKEncodeOptionStringObj)     != 0UL) &&  ([object isKindOfClass:[NSString class]] == NO))                                                         { jk_encode_error(encodeState, @"Unable to serialize object class %@, expected a NSString.", NSStringFromClass([object class])); goto errorExit; }

  if(jk_encode_add_atom_to_buffer(encodeState, object) == 0) {
    BOOL stackBuffer = ((encodeState->stringBuffer.flags & TMBJKManagedBufferMustFree) == 0UL) ? YES : NO;
    
    if((encodeState->atIndex < 2UL))
    if((stackBuffer == NO) && ((encodeState->stringBuffer.bytes.ptr = (unsigned char *)reallocf(encodeState->stringBuffer.bytes.ptr, encodeState->atIndex + 16UL)) == NULL)) { jk_encode_error(encodeState, @"Unable to realloc buffer"); goto errorExit; }

    switch((encodeOption & TMBJKEncodeOptionAsTypeMask)) {
      case TMBJKEncodeOptionAsData:
        if(stackBuffer == YES) { if((returnObject = [(id)CFDataCreate(                 NULL,                encodeState->stringBuffer.bytes.ptr, (CFIndex)encodeState->atIndex)                                  autorelease]) == NULL) { jk_encode_error(encodeState, @"Unable to create NSData object"); } }
        else                   { if((returnObject = [(id)CFDataCreateWithBytesNoCopy(  NULL,                encodeState->stringBuffer.bytes.ptr, (CFIndex)encodeState->atIndex, NULL)                            autorelease]) == NULL) { jk_encode_error(encodeState, @"Unable to create NSData object"); } }
        break;

      case TMBJKEncodeOptionAsString:
        if(stackBuffer == YES) { if((returnObject = [(id)CFStringCreateWithBytes(      NULL, (const UInt8 *)encodeState->stringBuffer.bytes.ptr, (CFIndex)encodeState->atIndex, kCFStringEncodingUTF8, NO)       autorelease]) == NULL) { jk_encode_error(encodeState, @"Unable to create NSString object"); } }
        else                   { if((returnObject = [(id)CFStringCreateWithBytesNoCopy(NULL, (const UInt8 *)encodeState->stringBuffer.bytes.ptr, (CFIndex)encodeState->atIndex, kCFStringEncodingUTF8, NO, NULL) autorelease]) == NULL) { jk_encode_error(encodeState, @"Unable to create NSString object"); } }
        break;

      default: jk_encode_error(encodeState, @"Unknown encode as type."); break;
    }

    if((returnObject != NULL) && (stackBuffer == NO)) { encodeState->stringBuffer.flags &= ~TMBJKManagedBufferMustFree; encodeState->stringBuffer.bytes.ptr = NULL; encodeState->stringBuffer.bytes.length = 0UL; }
  }

errorExit:
  if((encodeState != NULL) && (error != NULL) && (encodeState->error != NULL)) { *error = encodeState->error; encodeState->error = NULL; }
  [self releaseState];

  return(returnObject);
}

- (void)releaseState
{
  if(encodeState != NULL) {
    jk_managedBuffer_release(&encodeState->stringBuffer);
    jk_managedBuffer_release(&encodeState->utf8ConversionBuffer);
    free(encodeState); encodeState = NULL;
  }  
}

- (void)dealloc
{
  [self releaseState];
  [super dealloc];
}

@end

@implementation NSString (JSONKitSerializing)

////////////
#pragma mark Methods for serializing a single NSString.
////////////

// Useful for those who need to serialize just a NSString.  Otherwise you would have to do something like [NSArray arrayWithObject:stringToBeJSONSerialized], serializing the array, and then chopping of the extra ^\[.*\]$ square brackets.

// NSData returning methods...

- (NSData *)JSONData
{
  return([self JSONDataWithOptions:TMBJKSerializeOptionNone includeQuotes:YES error:NULL]);
}

- (NSData *)JSONDataWithOptions:(TMBJKSerializeOptionFlags)serializeOptions includeQuotes:(BOOL)includeQuotes error:(NSError **)error
{
  return([TMBJKSerializer serializeObject:self options:serializeOptions encodeOption:(TMBJKEncodeOptionAsData | ((includeQuotes == NO) ? TMBJKEncodeOptionStringObjTrimQuotes : 0UL) | TMBJKEncodeOptionStringObj) block:NULL delegate:NULL selector:NULL error:error]);
}

// NSString returning methods...

- (NSString *)JSONString
{
  return([self JSONStringWithOptions:TMBJKSerializeOptionNone includeQuotes:YES error:NULL]);
}

- (NSString *)JSONStringWithOptions:(TMBJKSerializeOptionFlags)serializeOptions includeQuotes:(BOOL)includeQuotes error:(NSError **)error
{
  return([TMBJKSerializer serializeObject:self options:serializeOptions encodeOption:(TMBJKEncodeOptionAsString | ((includeQuotes == NO) ? TMBJKEncodeOptionStringObjTrimQuotes : 0UL) | TMBJKEncodeOptionStringObj) block:NULL delegate:NULL selector:NULL error:error]);
}

@end

@implementation NSArray (JSONKitSerializing)

// NSData returning methods...

- (NSData *)JSONData
{
  return([TMBJKSerializer serializeObject:self options:TMBJKSerializeOptionNone encodeOption:(TMBJKEncodeOptionAsData | TMBJKEncodeOptionCollectionObj) block:NULL delegate:NULL selector:NULL error:NULL]);
}

- (NSData *)JSONDataWithOptions:(TMBJKSerializeOptionFlags)serializeOptions error:(NSError **)error
{
  return([TMBJKSerializer serializeObject:self options:serializeOptions encodeOption:(TMBJKEncodeOptionAsData | TMBJKEncodeOptionCollectionObj) block:NULL delegate:NULL selector:NULL error:error]);
}

- (NSData *)JSONDataWithOptions:(TMBJKSerializeOptionFlags)serializeOptions serializeUnsupportedClassesUsingDelegate:(id)delegate selector:(SEL)selector error:(NSError **)error
{
  return([TMBJKSerializer serializeObject:self options:serializeOptions encodeOption:(TMBJKEncodeOptionAsData | TMBJKEncodeOptionCollectionObj) block:NULL delegate:delegate selector:selector error:error]);
}

// NSString returning methods...

- (NSString *)JSONString
{
  return([TMBJKSerializer serializeObject:self options:TMBJKSerializeOptionNone encodeOption:(TMBJKEncodeOptionAsString | TMBJKEncodeOptionCollectionObj) block:NULL delegate:NULL selector:NULL error:NULL]);
}

- (NSString *)JSONStringWithOptions:(TMBJKSerializeOptionFlags)serializeOptions error:(NSError **)error
{
  return([TMBJKSerializer serializeObject:self options:serializeOptions encodeOption:(TMBJKEncodeOptionAsString | TMBJKEncodeOptionCollectionObj) block:NULL delegate:NULL selector:NULL error:error]);
}

- (NSString *)JSONStringWithOptions:(TMBJKSerializeOptionFlags)serializeOptions serializeUnsupportedClassesUsingDelegate:(id)delegate selector:(SEL)selector error:(NSError **)error
{
  return([TMBJKSerializer serializeObject:self options:serializeOptions encodeOption:(TMBJKEncodeOptionAsString | TMBJKEncodeOptionCollectionObj) block:NULL delegate:delegate selector:selector error:error]);
}

@end

@implementation NSDictionary (JSONKitSerializing)

// NSData returning methods...

- (NSData *)JSONData
{
  return([TMBJKSerializer serializeObject:self options:TMBJKSerializeOptionNone encodeOption:(TMBJKEncodeOptionAsData | TMBJKEncodeOptionCollectionObj) block:NULL delegate:NULL selector:NULL error:NULL]);
}

- (NSData *)JSONDataWithOptions:(TMBJKSerializeOptionFlags)serializeOptions error:(NSError **)error
{
  return([TMBJKSerializer serializeObject:self options:serializeOptions encodeOption:(TMBJKEncodeOptionAsData | TMBJKEncodeOptionCollectionObj) block:NULL delegate:NULL selector:NULL error:error]);
}

- (NSData *)JSONDataWithOptions:(TMBJKSerializeOptionFlags)serializeOptions serializeUnsupportedClassesUsingDelegate:(id)delegate selector:(SEL)selector error:(NSError **)error
{
  return([TMBJKSerializer serializeObject:self options:serializeOptions encodeOption:(TMBJKEncodeOptionAsData | TMBJKEncodeOptionCollectionObj) block:NULL delegate:delegate selector:selector error:error]);
}

// NSString returning methods...

- (NSString *)JSONString
{
  return([TMBJKSerializer serializeObject:self options:TMBJKSerializeOptionNone encodeOption:(TMBJKEncodeOptionAsString | TMBJKEncodeOptionCollectionObj) block:NULL delegate:NULL selector:NULL error:NULL]);
}

- (NSString *)JSONStringWithOptions:(TMBJKSerializeOptionFlags)serializeOptions error:(NSError **)error
{
  return([TMBJKSerializer serializeObject:self options:serializeOptions encodeOption:(TMBJKEncodeOptionAsString | TMBJKEncodeOptionCollectionObj) block:NULL delegate:NULL selector:NULL error:error]);
}

- (NSString *)JSONStringWithOptions:(TMBJKSerializeOptionFlags)serializeOptions serializeUnsupportedClassesUsingDelegate:(id)delegate selector:(SEL)selector error:(NSError **)error
{
  return([TMBJKSerializer serializeObject:self options:serializeOptions encodeOption:(TMBJKEncodeOptionAsString | TMBJKEncodeOptionCollectionObj) block:NULL delegate:delegate selector:selector error:error]);
}

@end


#ifdef __BLOCKS__

@implementation NSArray (JSONKitSerializingBlockAdditions)

- (NSData *)JSONDataWithOptions:(TMBJKSerializeOptionFlags)serializeOptions serializeUnsupportedClassesUsingBlock:(id(^)(id object))block error:(NSError **)error
{
  return([TMBJKSerializer serializeObject:self options:serializeOptions encodeOption:(TMBJKEncodeOptionAsData | TMBJKEncodeOptionCollectionObj) block:block delegate:NULL selector:NULL error:error]);
}

- (NSString *)JSONStringWithOptions:(TMBJKSerializeOptionFlags)serializeOptions serializeUnsupportedClassesUsingBlock:(id(^)(id object))block error:(NSError **)error
{
  return([TMBJKSerializer serializeObject:self options:serializeOptions encodeOption:(TMBJKEncodeOptionAsString | TMBJKEncodeOptionCollectionObj) block:block delegate:NULL selector:NULL error:error]);
}

@end

@implementation NSDictionary (JSONKitSerializingBlockAdditions)

- (NSData *)JSONDataWithOptions:(TMBJKSerializeOptionFlags)serializeOptions serializeUnsupportedClassesUsingBlock:(id(^)(id object))block error:(NSError **)error
{
  return([TMBJKSerializer serializeObject:self options:serializeOptions encodeOption:(TMBJKEncodeOptionAsData | TMBJKEncodeOptionCollectionObj) block:block delegate:NULL selector:NULL error:error]);
}

- (NSString *)JSONStringWithOptions:(TMBJKSerializeOptionFlags)serializeOptions serializeUnsupportedClassesUsingBlock:(id(^)(id object))block error:(NSError **)error
{
  return([TMBJKSerializer serializeObject:self options:serializeOptions encodeOption:(TMBJKEncodeOptionAsString | TMBJKEncodeOptionCollectionObj) block:block delegate:NULL selector:NULL error:error]);
}

@end

#endif // __BLOCKS__

