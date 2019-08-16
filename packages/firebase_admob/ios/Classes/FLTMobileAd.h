// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import <Flutter/Flutter.h>
#import "GoogleMobileAds/GoogleMobileAds.h"

typedef enum : NSUInteger {
  CREATED,
  LOADING,
  FAILED,
  PENDING,  // Will be shown when status is changed to LOADED.
  LOADED,
} FLTMobileAdStatus;

@interface FLTMobileAd : NSObject
+ (void)configureWithAppId:(NSString *)appId;
+ (FLTMobileAd *)getAdForId:(NSNumber *)mobileAdId;
- (FLTMobileAdStatus)status;
- (void)loadWithAdUnitId:(NSString *)adUnitId targetingInfo:(NSDictionary *)targetingInfo;
- (void)show;
- (void)showAtOffset:(double)anchorOffset
       hCenterOffset:(double)horizontalCenterOffset
          fromAnchor:(int)anchorType;
- (void)dispose;
@end

@interface FLTBannerAd : FLTMobileAd <GADBannerViewDelegate>
+ (instancetype)withId:(NSNumber *)mobileAdId
                adSize:(GADAdSize)adSize
               channel:(FlutterMethodChannel *)channel;
@end

@interface FLTInterstitialAd : FLTMobileAd <GADInterstitialDelegate>
+ (instancetype)withId:(NSNumber *)mobileAdId channel:(FlutterMethodChannel *)channel;
@end
