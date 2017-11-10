// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

const String kMockProviderId = 'firebase';
const String kMockUid = '12345';
const String kMockDisplayName = 'Flutter Test User';
const String kMockPhotoUrl = 'http://www.example.com/';
const String kMockEmail = 'test@example.com';
const String kMockPassword = 'passw0rd';
const String kMockIdToken = '12345';
const String kMockAccessToken = '67890';
const String kMockCustomToken = '12345';

void main() {
  group('$FirebaseAuth', () {
    final FirebaseAuth auth = FirebaseAuth.instance;
    final List<MethodCall> log = <MethodCall>[];

    int mockHandleId = 0;

    setUp(() {
      log.clear();
      FirebaseAuth.channel.setMockMethodCallHandler((MethodCall call) async {
        log.add(call);
        switch (call.method) {
          case "getIdToken":
            return kMockIdToken;
            break;
          case "startListeningAuthState":
            return mockHandleId++;
            break;
          default:
            return mockFirebaseUser();
            break;
        }
      });
    });
    void verifyUser(FirebaseUser user) {
      expect(user, isNotNull);
      expect(user.isAnonymous, isTrue);
      expect(user.isEmailVerified, isFalse);
      expect(user.providerData.length, 1);
      final UserInfo userInfo = user.providerData[0];
      expect(userInfo.providerId, kMockProviderId);
      expect(userInfo.uid, kMockUid);
      expect(userInfo.displayName, kMockDisplayName);
      expect(userInfo.photoUrl, kMockPhotoUrl);
      expect(userInfo.email, kMockEmail);
    }

    test('currentUser', () async {
      final FirebaseUser user = await auth.currentUser();
      verifyUser(user);
      expect(
        log,
        <Matcher>[
          isMethodCall('currentUser', arguments: null),
        ],
      );
    });

    test('signInAnonymously', () async {
      final FirebaseUser user = await auth.signInAnonymously();
      verifyUser(user);
      expect(await user.getIdToken(), equals(kMockIdToken));
      expect(await user.getIdToken(refresh: true), equals(kMockIdToken));
      expect(
        log,
        <Matcher>[
          isMethodCall('signInAnonymously', arguments: null),
          isMethodCall(
            'getIdToken',
            arguments: <String, bool>{'refresh': false},
          ),
          isMethodCall(
            'getIdToken',
            arguments: <String, bool>{'refresh': true},
          ),
        ],
      );
    });

    test('createUserWithEmailAndPassword', () async {
      final FirebaseUser user = await auth.createUserWithEmailAndPassword(
        email: kMockEmail,
        password: kMockPassword,
      );
      verifyUser(user);
      expect(
        log,
        <Matcher>[
          isMethodCall(
            'createUserWithEmailAndPassword',
            arguments: <String, String>{
              'email': kMockEmail,
              'password': kMockPassword,
            },
          ),
        ],
      );
    });

    test('linkWithEmailAndPassword', () async {
      final FirebaseUser user = await auth.linkWithEmailAndPassword(
        email: kMockEmail,
        password: kMockPassword,
      );
      verifyUser(user);
      expect(
        log,
        <Matcher>[
          isMethodCall(
            'linkWithEmailAndPassword',
            arguments: <String, String>{
              'email': kMockEmail,
              'password': kMockPassword,
            },
          ),
        ],
      );
    });

    test('signInWithGoogle', () async {
      final FirebaseUser user = await auth.signInWithGoogle(
        idToken: kMockIdToken,
        accessToken: kMockAccessToken,
      );
      verifyUser(user);
      expect(
        log,
        <Matcher>[
          isMethodCall(
            'signInWithGoogle',
            arguments: <String, String>{
              'idToken': kMockIdToken,
              'accessToken': kMockAccessToken,
            },
          ),
        ],
      );
    });

    test('linkWithGoogleCredential', () async {
      final FirebaseUser user = await auth.linkWithGoogleCredential(
        idToken: kMockIdToken,
        accessToken: kMockAccessToken,
      );
      verifyUser(user);
      expect(
        log,
        <Matcher>[
          isMethodCall(
            'linkWithGoogleCredential',
            arguments: <String, String>{
              'idToken': kMockIdToken,
              'accessToken': kMockAccessToken,
            },
          ),
        ],
      );
    });

    test('signInWithFacebook', () async {
      final FirebaseUser user = await auth.signInWithFacebook(
        accessToken: kMockAccessToken,
      );
      verifyUser(user);
      expect(
        log,
        <Matcher>[
          isMethodCall(
            'signInWithFacebook',
            arguments: <String, String>{
              'accessToken': kMockAccessToken,
            },
          ),
        ],
      );
    });

    test('linkWithEmailAndPassword', () async {
      final FirebaseUser user = await auth.linkWithEmailAndPassword(
        email: kMockEmail,
        password: kMockPassword,
      );
      verifyUser(user);
      expect(
        log,
        <Matcher>[
          isMethodCall(
            'linkWithEmailAndPassword',
            arguments: <String, String>{
              'email': kMockEmail,
              'password': kMockPassword,
            },
          ),
        ],
      );
    });

    test('signInWithCustomToken', () async {
      final FirebaseUser user =
          await auth.signInWithCustomToken(token: kMockCustomToken);
      verifyUser(user);
      expect(
        log,
        <Matcher>[
          isMethodCall('signInWithCustomToken', arguments: <String, String>{
            'token': kMockCustomToken,
          })
        ],
      );
    });

    test('onAuthStateChanged', () async {
      mockHandleId = 42;

      Future<Null> simulateEvent(Map<String, dynamic> user) async {
        await BinaryMessages.handlePlatformMessage(
          FirebaseAuth.channel.name,
          FirebaseAuth.channel.codec.encodeMethodCall(
            new MethodCall(
              'onAuthStateChanged',
              <String, dynamic>{'id': 42, 'user': user},
            ),
          ),
          (_) {},
        );
      }

      final AsyncQueue<FirebaseUser> events = new AsyncQueue<FirebaseUser>();

      // Subscribe and allow subscription to complete.
      final StreamSubscription<FirebaseUser> subscription =
          auth.onAuthStateChanged.listen(events.add);
      await new Future<Null>.delayed(const Duration(seconds: 0));

      await simulateEvent(null);
      await simulateEvent(mockFirebaseUser());

      final FirebaseUser user1 = await events.remove();
      expect(user1, isNull);

      final FirebaseUser user2 = await events.remove();
      verifyUser(user2);

      // Cancel subscription and allow cancellation to complete.
      subscription.cancel();
      await new Future<Null>.delayed(const Duration(seconds: 0));

      expect(
        log,
        <Matcher>[
          isMethodCall('startListeningAuthState', arguments: null),
          isMethodCall(
            'stopListeningAuthState',
            arguments: <String, dynamic>{
              'id': 42,
            },
          ),
        ],
      );
    });
  });
}

Map<String, dynamic> mockFirebaseUser(
        {String providerId: kMockProviderId,
        String uid: kMockUid,
        String displayName: kMockDisplayName,
        String photoUrl: kMockPhotoUrl,
        String email: kMockEmail}) =>
    <String, dynamic>{
      'isAnonymous': true,
      'isEmailVerified': false,
      'providerData': <Map<String, String>>[
        <String, String>{
          'providerId': providerId,
          'uid': uid,
          'displayName': displayName,
          'photoUrl': photoUrl,
          'email': email,
        },
      ],
    };

/// Queue whose remove operation is asynchronous, awaiting a corresponding add.
class AsyncQueue<T> {
  Map<int, Completer<T>> _completers = <int, Completer<T>>{};
  int _nextToRemove = 0;
  int _nextToAdd = 0;

  void add(T element) {
    _completer(_nextToAdd++).complete(element);
  }

  Future<T> remove() {
    final Future<T> result = _completer(_nextToRemove++).future;
    return result;
  }

  Completer<T> _completer(int index) {
    if (_completers.containsKey(index)) {
      return _completers.remove(index);
    } else {
      return _completers[index] = new Completer<T>();
    }
  }
}
