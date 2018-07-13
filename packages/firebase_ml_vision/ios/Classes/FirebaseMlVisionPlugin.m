#import "FirebaseMlVisionPlugin.h"

@interface NSError (FlutterError)
@property(readonly, nonatomic) FlutterError *flutterError;
@end

@implementation NSError (FlutterError)
- (FlutterError *)flutterError {
  return [FlutterError errorWithCode:[NSString stringWithFormat:@"Error %d", (int)self.code]
                             message:self.domain
                             details:self.localizedDescription];
}
@end

@implementation FLTFirebaseMlVisionPlugin
+ (void)handleError:(NSError *)error result:(FlutterResult)result {
  result([error flutterError]);
}

+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar> *)registrar {
  FlutterMethodChannel *channel =
      [FlutterMethodChannel methodChannelWithName:@"plugins.flutter.io/firebase_ml_vision"
                                  binaryMessenger:[registrar messenger]];
  FLTFirebaseMlVisionPlugin *instance = [[FLTFirebaseMlVisionPlugin alloc] init];
  [registrar addMethodCallDelegate:instance channel:channel];
}

- (instancetype)init {
  self = [super init];
  if (self) {
    if (![FIRApp defaultApp]) {
      [FIRApp configure];
    }
  }
  return self;
}

- (void)handleMethodCall:(FlutterMethodCall *)call result:(FlutterResult)result {
  if ([@"BarcodeDetector#detectInImage" isEqualToString:call.method]) {
    FIRVisionImage *image = [self filePathToVisionImage:call.arguments];
    [BarcodeDetector handleDetection:image result:result];
  } else if ([@"BarcodeDetector#close" isEqualToString:call.method]) {
    [BarcodeDetector close];
  } else if ([@"FaceDetector#detectInImage" isEqualToString:call.method]) {
  } else if ([@"FaceDetector#close" isEqualToString:call.method]) {
  } else if ([@"LabelDetector#detectInImage" isEqualToString:call.method]) {
  } else if ([@"LabelDetector#close" isEqualToString:call.method]) {
  } else if ([@"TextDetector#detectInImage" isEqualToString:call.method]) {
    FIRVisionImage *image = [self filePathToVisionImage:call.arguments];
    [TextDetector handleDetection:image result:result];
  } else if ([@"TextDetector#close" isEqualToString:call.method]) {
    [TextDetector close];
  } else {
    result(FlutterMethodNotImplemented);
  }
}

- (FIRVisionImage *)filePathToVisionImage:(NSString *)path {
  UIImage *image = [UIImage imageWithContentsOfFile:path];
  return [[FIRVisionImage alloc] initWithImage:image];
}
@end
