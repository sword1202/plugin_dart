// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "FirebaseAuthPlugin.h"

#import "Firebase/Firebase.h"

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

NSDictionary *toDictionary(id<FIRUserInfo> userInfo) {
  return @{
    @"providerId" : userInfo.providerID,
    @"displayName" : userInfo.displayName ?: [NSNull null],
    @"uid" : userInfo.uid,
    @"photoUrl" : userInfo.photoURL.absoluteString ?: [NSNull null],
    @"email" : userInfo.email ?: [NSNull null],
  };
}

@interface FLTFirebaseAuthPlugin ()
@property(nonatomic, retain) NSMutableDictionary *authStateChangeListeners;
@property(nonatomic, retain) FlutterMethodChannel *channel;
@end

@implementation FLTFirebaseAuthPlugin

// Handles are ints used as indexes into the NSMutableDictionary of active observers
int nextHandle = 0;

+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar> *)registrar {
  FlutterMethodChannel *channel =
      [FlutterMethodChannel methodChannelWithName:@"plugins.flutter.io/firebase_auth"
                                  binaryMessenger:[registrar messenger]];
  FLTFirebaseAuthPlugin *instance = [[FLTFirebaseAuthPlugin alloc] init];
  instance.channel = channel;
  instance.authStateChangeListeners = [[NSMutableDictionary alloc] init];
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
  if ([@"currentUser" isEqualToString:call.method]) {
    id __block listener = [[FIRAuth auth]
        addAuthStateDidChangeListener:^(FIRAuth *_Nonnull auth, FIRUser *_Nullable user) {
          [self sendResult:result forUser:user error:nil];
          [auth removeAuthStateDidChangeListener:listener];
        }];
  } else if ([@"signInAnonymously" isEqualToString:call.method]) {
    [[FIRAuth auth] signInAnonymouslyWithCompletion:^(FIRUser *user, NSError *error) {
      [self sendResult:result forUser:user error:error];
    }];
  } else if ([@"signInWithGoogle" isEqualToString:call.method]) {
    NSString *idToken = call.arguments[@"idToken"];
    NSString *accessToken = call.arguments[@"accessToken"];
    FIRAuthCredential *credential =
        [FIRGoogleAuthProvider credentialWithIDToken:idToken accessToken:accessToken];
    [[FIRAuth auth] signInWithCredential:credential
                              completion:^(FIRUser *user, NSError *error) {
                                [self sendResult:result forUser:user error:error];
                              }];
  } else if ([@"signInWithFacebook" isEqualToString:call.method]) {
    NSString *accessToken = call.arguments[@"accessToken"];
    FIRAuthCredential *credential = [FIRFacebookAuthProvider credentialWithAccessToken:accessToken];
    [[FIRAuth auth] signInWithCredential:credential
                              completion:^(FIRUser *user, NSError *error) {
                                [self sendResult:result forUser:user error:error];
                              }];
  } else if ([@"createUserWithEmailAndPassword" isEqualToString:call.method]) {
    NSString *email = call.arguments[@"email"];
    NSString *password = call.arguments[@"password"];
    [[FIRAuth auth] createUserWithEmail:email
                               password:password
                             completion:^(FIRUser *user, NSError *error) {
                               [self sendResult:result forUser:user error:error];
                             }];
  } else if ([@"signInWithEmailAndPassword" isEqualToString:call.method]) {
    NSString *email = call.arguments[@"email"];
    NSString *password = call.arguments[@"password"];
    [[FIRAuth auth] signInWithEmail:email
                           password:password
                         completion:^(FIRUser *user, NSError *error) {
                           [self sendResult:result forUser:user error:error];
                         }];
  } else if ([@"signOut" isEqualToString:call.method]) {
    NSError *signOutError;
    BOOL status = [[FIRAuth auth] signOut:&signOutError];
    if (!status) {
      NSLog(@"Error signing out: %@", signOutError);
      [self sendResult:result forUser:nil error:signOutError];
    } else {
      [self sendResult:result forUser:nil error:nil];
    }
  } else if ([@"getIdToken" isEqualToString:call.method]) {
    [[FIRAuth auth].currentUser
        getIDTokenForcingRefresh:YES
                      completion:^(NSString *_Nullable token, NSError *_Nullable error) {
                        result(error != nil ? error.flutterError : token);
                      }];
  } else if ([@"linkWithEmailAndPassword" isEqualToString:call.method]) {
    NSString *email = call.arguments[@"email"];
    NSString *password = call.arguments[@"password"];
    FIRAuthCredential *credential =
        [FIREmailAuthProvider credentialWithEmail:email password:password];
    [[FIRAuth auth].currentUser linkWithCredential:credential
                                        completion:^(FIRUser *user, NSError *error) {
                                          [self sendResult:result forUser:user error:error];
                                        }];
  } else if ([@"linkWithGoogleCredential" isEqualToString:call.method]) {
    NSString *idToken = call.arguments[@"idToken"];
    NSString *accessToken = call.arguments[@"accessToken"];
    FIRAuthCredential *credential =
        [FIRGoogleAuthProvider credentialWithIDToken:idToken accessToken:accessToken];
    [[FIRAuth auth].currentUser linkWithCredential:credential
                                        completion:^(FIRUser *user, NSError *error) {
                                          [self sendResult:result forUser:user error:error];
                                        }];
  } else if ([@"signInWithCustomToken" isEqualToString:call.method]) {
    NSString *token = call.arguments[@"token"];
    [[FIRAuth auth] signInWithCustomToken:token
                               completion:^(FIRUser *user, NSError *error) {
                                 [self sendResult:result forUser:user error:error];
                               }];

  } else if ([@"startListeningAuthState" isEqualToString:call.method]) {
    NSNumber *identifier = [NSNumber numberWithInteger:nextHandle++];

    FIRAuthStateDidChangeListenerHandle listener = [[FIRAuth auth]
        addAuthStateDidChangeListener:^(FIRAuth *_Nonnull auth, FIRUser *_Nullable user) {
          NSMutableDictionary *response = [[NSMutableDictionary alloc] init];
          response[@"id"] = identifier;
          if (user) {
            response[@"user"] = [self dictionaryFromUser:user];
          }
          [self.channel invokeMethod:@"onAuthStateChanged" arguments:response];
        }];
    [self.authStateChangeListeners setObject:listener forKey:identifier];
    result(identifier);
  } else if ([@"stopListeningAuthState" isEqualToString:call.method]) {
    NSNumber *identifier =
        [NSNumber numberWithInteger:[call.arguments[@"id"] unsignedIntegerValue]];

    FIRAuthStateDidChangeListenerHandle listener = self.authStateChangeListeners[identifier];
    if (listener) {
      [[FIRAuth auth] removeAuthStateDidChangeListener:self.authStateChangeListeners];
      [self.authStateChangeListeners removeObjectForKey:identifier];
      result(nil);
    } else {
      result([FlutterError
          errorWithCode:@"not_found"
                message:[NSString stringWithFormat:@"Listener with identifier '%d' not found.",
                                                   identifier.intValue]
                details:nil]);
    }
  } else {
    result(FlutterMethodNotImplemented);
  }
}

- (NSMutableDictionary *)dictionaryFromUser:(FIRUser *)user {
  NSMutableArray<NSDictionary<NSString *, NSString *> *> *providerData =
      [NSMutableArray arrayWithCapacity:user.providerData.count];
  for (id<FIRUserInfo> userInfo in user.providerData) {
    [providerData addObject:toDictionary(userInfo)];
  }
  NSMutableDictionary *userData = [toDictionary(user) mutableCopy];
  userData[@"isAnonymous"] = [NSNumber numberWithBool:user.isAnonymous];
  userData[@"isEmailVerified"] = [NSNumber numberWithBool:user.isEmailVerified];
  userData[@"providerData"] = providerData;
  return userData;
}

- (void)sendResult:(FlutterResult)result forUser:(FIRUser *)user error:(NSError *)error {
  if (error != nil) {
    result(error.flutterError);
  } else if (user == nil) {
    result(nil);
  } else {
    result([self dictionaryFromUser:user]);
  }
}

@end
