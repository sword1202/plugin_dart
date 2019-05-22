// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import <Foundation/Foundation.h>
#import <Photos/Photos.h>

NS_ASSUME_NONNULL_BEGIN

@interface FLTImagePickerPhotoAssetUtil : NSObject

+ (PHAsset *)getAssetFromImagePickerInfo:(NSDictionary *)info;

// Save image with correct meta data and extention copied from the original asset.
+ (NSString *)saveImageWithOriginalImageData:(NSData *)originalImageData image:(UIImage *)image;

// Save image with correct meta data and extention copied from image picker result info.
+ (NSString *)saveImageWithPickerInfo:(nullable NSDictionary *)info image:(UIImage *)image;

@end

NS_ASSUME_NONNULL_END
