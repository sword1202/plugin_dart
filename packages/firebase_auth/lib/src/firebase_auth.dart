// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of firebase_auth;

typedef void PhoneVerificationCompleted(AuthCredential phoneAuthCredential);
typedef void PhoneVerificationFailed(AuthException error);
typedef void PhoneCodeSent(String verificationId, [int forceResendingToken]);
typedef void PhoneCodeAutoRetrievalTimeout(String verificationId);

/// The entry point of the Firebase Authentication SDK.
class FirebaseAuth {
  FirebaseAuth._(this.app) {
    channel.setMethodCallHandler(_callHandler);
  }

  /// Provides an instance of this class corresponding to `app`.
  factory FirebaseAuth.fromApp(FirebaseApp app) {
    assert(app != null);
    return FirebaseAuth._(app);
  }

  /// Provides an instance of this class corresponding to the default app.
  static final FirebaseAuth instance = FirebaseAuth._(FirebaseApp.instance);

  @visibleForTesting
  static const MethodChannel channel = MethodChannel(
    'plugins.flutter.io/firebase_auth',
  );

  final Map<int, StreamController<FirebaseUser>> _authStateChangedControllers =
      <int, StreamController<FirebaseUser>>{};

  static int _nextHandle = 0;
  final Map<int, Map<String, dynamic>> _phoneAuthCallbacks =
      <int, Map<String, dynamic>>{};

  final FirebaseApp app;

  /// Receive [FirebaseUser] each time the user signIn or signOut
  Stream<FirebaseUser> get onAuthStateChanged {
    Future<int> _handle;

    StreamController<FirebaseUser> controller;
    controller = StreamController<FirebaseUser>.broadcast(onListen: () {
      _handle = channel.invokeMethod<int>('startListeningAuthState',
          <String, String>{"app": app.name}).then<int>((dynamic v) => v);
      _handle.then((int handle) {
        _authStateChangedControllers[handle] = controller;
      });
    }, onCancel: () {
      _handle.then((int handle) async {
        await channel.invokeMethod<void>("stopListeningAuthState",
            <String, dynamic>{"id": handle, "app": app.name});
        _authStateChangedControllers.remove(handle);
      });
    });

    return controller.stream;
  }

  /// Asynchronously creates and becomes an anonymous user.
  ///
  /// If there is already an anonymous user signed in, that user will be
  /// returned instead. If there is any other existing user signed in, that
  /// user will be signed out.
  ///
  /// **Important**: You must enable Anonymous accounts in the Auth section
  /// of the Firebase console before being able to use them.
  ///
  /// Errors:
  ///   • `ERROR_OPERATION_NOT_ALLOWED` - Indicates that Anonymous accounts are not enabled.
  Future<AuthResult> signInAnonymously() async {
    final Map<String, dynamic> data = await channel
        .invokeMapMethod<String, dynamic>(
            'signInAnonymously', <String, String>{"app": app.name});
    final AuthResult authResult = AuthResult._(data, app);
    return authResult;
  }

  /// Tries to create a new user account with the given email address and password.
  ///
  /// If successful, it also signs the user in into the app and updates
  /// the [onAuthStateChanged] stream.
  ///
  /// Errors:
  ///   • `ERROR_WEAK_PASSWORD` - If the password is not strong enough.
  ///   • `ERROR_INVALID_EMAIL` - If the email address is malformed.
  ///   • `ERROR_EMAIL_ALREADY_IN_USE` - If the email is already in use by a different account.
  Future<AuthResult> createUserWithEmailAndPassword({
    @required String email,
    @required String password,
  }) async {
    assert(email != null);
    assert(password != null);
    final Map<String, dynamic> data =
        await channel.invokeMapMethod<String, dynamic>(
      'createUserWithEmailAndPassword',
      <String, String>{'email': email, 'password': password, 'app': app.name},
    );
    final AuthResult authResult = AuthResult._(data, app);
    return authResult;
  }

  /// Returns a list of sign-in methods that can be used to sign in a given
  /// user (identified by its main email address).
  ///
  /// This method is useful when you support multiple authentication mechanisms
  /// if you want to implement an email-first authentication flow.
  ///
  /// Errors:
  ///   • `ERROR_INVALID_CREDENTIAL` - If the [email] address is malformed.
  ///   • `ERROR_USER_NOT_FOUND` - If there is no user corresponding to the given [email] address.
  Future<List<String>> fetchSignInMethodsForEmail({
    @required String email,
  }) async {
    assert(email != null);
    return await channel.invokeListMethod<String>(
      'fetchSignInMethodsForEmail',
      <String, String>{'email': email, 'app': app.name},
    );
  }

  /// Triggers the Firebase Authentication backend to send a password-reset
  /// email to the given email address, which must correspond to an existing
  /// user of your app.
  ///
  /// Errors:
  ///   • `ERROR_INVALID_EMAIL` - If the [email] address is malformed.
  ///   • `ERROR_USER_NOT_FOUND` - If there is no user corresponding to the given [email] address.
  Future<void> sendPasswordResetEmail({
    @required String email,
  }) async {
    assert(email != null);
    return await channel.invokeMethod<void>(
      'sendPasswordResetEmail',
      <String, String>{'email': email, 'app': app.name},
    );
  }

  /// Sends a sign in with email link to provided email address.
  Future<void> sendSignInWithEmailLink({
    @required String email,
    @required String url,
    @required bool handleCodeInApp,
    @required String iOSBundleID,
    @required String androidPackageName,
    @required bool androidInstallIfNotAvailable,
    @required String androidMinimumVersion,
  }) async {
    assert(email != null);
    assert(url != null);
    assert(handleCodeInApp != null);
    assert(iOSBundleID != null);
    assert(androidPackageName != null);
    assert(androidInstallIfNotAvailable != null);
    assert(androidMinimumVersion != null);
    await channel.invokeMethod<void>(
      'sendLinkToEmail',
      <String, dynamic>{
        'email': email,
        'url': url,
        'handleCodeInApp': handleCodeInApp,
        'iOSBundleID': iOSBundleID,
        'androidPackageName': androidPackageName,
        'androidInstallIfNotAvailable': androidInstallIfNotAvailable,
        'androidMinimumVersion': androidMinimumVersion,
        'app': app.name,
      },
    );
  }

  /// Checks if link is an email sign-in link.
  Future<bool> isSignInWithEmailLink(String link) async {
    return await channel.invokeMethod<bool>(
      'isSignInWithEmailLink',
      <String, String>{'link': link, 'app': app.name},
    );
  }

  /// Signs in using an email address and email sign-in link.
  ///
  /// Errors:
  ///   • `ERROR_NOT_ALLOWED` - Indicates that email and email sign-in link
  ///      accounts are not enabled. Enable them in the Auth section of the
  ///      Firebase console.
  ///   • `ERROR_DISABLED` - Indicates the user's account is disabled.
  ///   • `ERROR_INVALID` - Indicates the email address is invalid.
  Future<AuthResult> signInWithEmailAndLink({String email, String link}) async {
    final Map<String, dynamic> data =
        await channel.invokeMapMethod<String, dynamic>(
      'signInWithEmailAndLink',
      <String, dynamic>{
        'app': app.name,
        'email': email,
        'link': link,
      },
    );
    final AuthResult authResult = AuthResult._(data, app);
    return authResult;
  }

  /// Tries to sign in a user with the given email address and password.
  ///
  /// If successful, it also signs the user in into the app and updates
  /// the [onAuthStateChanged] stream.
  ///
  /// **Important**: You must enable Email & Password accounts in the Auth
  /// section of the Firebase console before being able to use them.
  ///
  /// Errors:
  ///   • `ERROR_INVALID_EMAIL` - If the [email] address is malformed.
  ///   • `ERROR_WRONG_PASSWORD` - If the [password] is wrong.
  ///   • `ERROR_USER_NOT_FOUND` - If there is no user corresponding to the given [email] address, or if the user has been deleted.
  ///   • `ERROR_USER_DISABLED` - If the user has been disabled (for example, in the Firebase console)
  ///   • `ERROR_TOO_MANY_REQUESTS` - If there was too many attempts to sign in as this user.
  ///   • `ERROR_OPERATION_NOT_ALLOWED` - Indicates that Email & Password accounts are not enabled.
  Future<AuthResult> signInWithEmailAndPassword({
    @required String email,
    @required String password,
  }) {
    assert(email != null);
    assert(password != null);
    final AuthCredential credential = EmailAuthProvider.getCredential(
      email: email,
      password: password,
    );
    return signInWithCredential(credential);
  }

  /// Asynchronously signs in to Firebase with the given 3rd-party credentials
  /// (e.g. a Facebook login Access Token, a Google ID Token/Access Token pair,
  /// etc.) and returns additional identity provider data.
  ///
  /// If successful, it also signs the user in into the app and updates
  /// the [onAuthStateChanged] stream.
  ///
  /// If the user doesn't have an account already, one will be created automatically.
  ///
  /// **Important**: You must enable the relevant accounts in the Auth section
  /// of the Firebase console before being able to use them.
  ///
  /// Errors:
  ///   • `ERROR_INVALID_CREDENTIAL` - If the credential data is malformed or has expired.
  ///   • `ERROR_USER_DISABLED` - If the user has been disabled (for example, in the Firebase console)
  ///   • `ERROR_ACCOUNT_EXISTS_WITH_DIFFERENT_CREDENTIAL` - If there already exists an account with the email address asserted by Google.
  ///       Resolve this case by calling [fetchSignInMethodsForEmail] and then asking the user to sign in using one of them.
  ///       This error will only be thrown if the "One account per email address" setting is enabled in the Firebase console (recommended).
  ///   • `ERROR_OPERATION_NOT_ALLOWED` - Indicates that Google accounts are not enabled.
  ///   • `ERROR_INVALID_ACTION_CODE` - If the action code in the link is malformed, expired, or has already been used.
  ///       This can only occur when using [EmailAuthProvider.getCredentialWithLink] to obtain the credential.
  Future<AuthResult> signInWithCredential(AuthCredential credential) async {
    assert(credential != null);
    final Map<String, dynamic> data =
        await channel.invokeMapMethod<String, dynamic>(
      'signInWithCredential',
      <String, dynamic>{
        'app': app.name,
        'provider': credential._provider,
        'data': credential._data,
      },
    );
    final AuthResult authResult = AuthResult._(data, app);
    return authResult;
  }

  /// Starts the phone number verification process for the given phone number.
  ///
  /// Either sends an SMS with a 6 digit code to the phone number specified,
  /// or sign's the user in and [verificationCompleted] is called.
  ///
  /// No duplicated SMS will be sent out upon re-entry (before timeout).
  ///
  /// Make sure to test all scenarios below:
  ///   • You directly get logged in if Google Play Services verified the phone
  ///     number instantly or helped you auto-retrieve the verification code.
  ///   • Auto-retrieve verification code timed out.
  ///   • Error cases when you receive [verificationFailed] callback.
  ///
  /// [phoneNumber] The phone number for the account the user is signing up
  ///   for or signing into. Make sure to pass in a phone number with country
  ///   code prefixed with plus sign ('+').
  ///
  /// [timeout] The maximum amount of time you are willing to wait for SMS
  ///   auto-retrieval to be completed by the library. Maximum allowed value
  ///   is 2 minutes. Use 0 to disable SMS-auto-retrieval. Setting this to 0
  ///   will also cause [codeAutoRetrievalTimeout] to be called immediately.
  ///   If you specified a positive value less than 30 seconds, library will
  ///   default to 30 seconds.
  ///
  /// [forceResendingToken] The [forceResendingToken] obtained from [codeSent]
  ///   callback to force re-sending another verification SMS before the
  ///   auto-retrieval timeout.
  ///
  /// [verificationCompleted] This callback must be implemented.
  ///   It will trigger when an SMS is auto-retrieved or the phone number has
  ///   been instantly verified. The callback will receive an [AuthCredential]
  ///   that can be passed to [signInWithCredential] or [linkWithCredential].
  ///
  /// [verificationFailed] This callback must be implemented.
  ///   Triggered when an error occurred during phone number verification.
  ///
  /// [codeSent] Optional callback.
  ///   It will trigger when an SMS has been sent to the users phone,
  ///   and will include a [verificationId] and [forceResendingToken].
  ///
  /// [codeAutoRetrievalTimeout] Optional callback.
  ///   It will trigger when SMS auto-retrieval times out and provide a
  ///   [verificationId].
  Future<void> verifyPhoneNumber({
    @required String phoneNumber,
    @required Duration timeout,
    int forceResendingToken,
    @required PhoneVerificationCompleted verificationCompleted,
    @required PhoneVerificationFailed verificationFailed,
    @required PhoneCodeSent codeSent,
    @required PhoneCodeAutoRetrievalTimeout codeAutoRetrievalTimeout,
  }) async {
    final Map<String, dynamic> callbacks = <String, dynamic>{
      'PhoneVerificationCompleted': verificationCompleted,
      'PhoneVerificationFailed': verificationFailed,
      'PhoneCodeSent': codeSent,
      'PhoneCodeAuthRetrievalTimeout': codeAutoRetrievalTimeout,
    };
    _nextHandle += 1;
    _phoneAuthCallbacks[_nextHandle] = callbacks;

    final Map<String, dynamic> params = <String, dynamic>{
      'handle': _nextHandle,
      'phoneNumber': phoneNumber,
      'timeout': timeout.inMilliseconds,
      'forceResendingToken': forceResendingToken,
      'app': app.name,
    };

    await channel.invokeMethod<void>('verifyPhoneNumber', params);
  }

  /// Tries to sign in a user with a given Custom Token [token].
  ///
  /// If successful, it also signs the user in into the app and updates
  /// the [onAuthStateChanged] stream.
  ///
  /// Use this method after you retrieve a Firebase Auth Custom Token from your server.
  ///
  /// If the user identified by the [uid] specified in the token doesn't
  /// have an account already, one will be created automatically.
  ///
  /// Read how to use Custom Token authentication and the cases where it is
  /// useful in [the guides](https://firebase.google.com/docs/auth/android/custom-auth).
  ///
  /// Errors:
  ///   • `ERROR_INVALID_CUSTOM_TOKEN` - The custom token format is incorrect.
  ///     Please check the documentation.
  ///   • `ERROR_CUSTOM_TOKEN_MISMATCH` - Invalid configuration.
  ///     Ensure your app's SHA1 is correct in the Firebase console.
  Future<AuthResult> signInWithCustomToken({@required String token}) async {
    assert(token != null);
    final Map<String, dynamic> data =
        await channel.invokeMapMethod<String, dynamic>(
      'signInWithCustomToken',
      <String, String>{'token': token, 'app': app.name},
    );
    final AuthResult authResult = AuthResult._(data, app);
    return authResult;
  }

  /// Signs out the current user and clears it from the disk cache.
  ///
  /// If successful, it signs the user out of the app and updates
  /// the [onAuthStateChanged] stream.
  Future<void> signOut() async {
    return await channel
        .invokeMethod<void>("signOut", <String, String>{'app': app.name});
  }

  /// Returns the currently signed-in [FirebaseUser] or [null] if there is none.
  Future<FirebaseUser> currentUser() async {
    final Map<String, dynamic> data = await channel
        .invokeMapMethod<String, dynamic>(
            "currentUser", <String, String>{'app': app.name});
    final FirebaseUser currentUser =
        data == null ? null : FirebaseUser._(data, app);
    return currentUser;
  }

  /// Sets the user-facing language code for auth operations that can be
  /// internationalized, such as [sendEmailVerification]. This language
  /// code should follow the conventions defined by the IETF in BCP47.
  Future<void> setLanguageCode(String language) async {
    assert(language != null);
    await FirebaseAuth.channel
        .invokeMethod<void>('setLanguageCode', <String, String>{
      'language': language,
      'app': app.name,
    });
  }

  Future<void> _callHandler(MethodCall call) async {
    switch (call.method) {
      case 'onAuthStateChanged':
        _onAuthStageChangedHandler(call);
        break;
      case 'phoneVerificationCompleted':
        final int handle = call.arguments['handle'];
        final PhoneVerificationCompleted verificationCompleted =
            _phoneAuthCallbacks[handle]['PhoneVerificationCompleted'];
        verificationCompleted(PhoneAuthProvider._getCredentialFromObject(
            jsonObject: call.arguments["phoneAuthCredential"].toString()));
        break;
      case 'phoneVerificationFailed':
        final int handle = call.arguments['handle'];
        final PhoneVerificationFailed verificationFailed =
            _phoneAuthCallbacks[handle]['PhoneVerificationFailed'];
        final Map<dynamic, dynamic> exception = call.arguments['exception'];
        verificationFailed(
            AuthException(exception['code'], exception['message']));
        break;
      case 'phoneCodeSent':
        final int handle = call.arguments['handle'];
        final String verificationId = call.arguments['verificationId'];
        final int forceResendingToken = call.arguments['forceResendingToken'];

        final PhoneCodeSent codeSent =
            _phoneAuthCallbacks[handle]['PhoneCodeSent'];
        if (forceResendingToken == null) {
          codeSent(verificationId);
        } else {
          codeSent(verificationId, forceResendingToken);
        }
        break;
      case 'phoneCodeAutoRetrievalTimeout':
        final int handle = call.arguments['handle'];
        final PhoneCodeAutoRetrievalTimeout codeAutoRetrievalTimeout =
            _phoneAuthCallbacks[handle]['PhoneCodeAuthRetrievalTimeout'];
        final String verificationId = call.arguments['verificationId'];
        codeAutoRetrievalTimeout(verificationId);
        break;
    }
  }

  void _onAuthStageChangedHandler(MethodCall call) {
    final Map<dynamic, dynamic> data = call.arguments["user"];
    final int id = call.arguments["id"];

    final FirebaseUser currentUser =
        data != null ? FirebaseUser._(data.cast<String, dynamic>(), app) : null;
    _authStateChangedControllers[id].add(currentUser);
  }
}
