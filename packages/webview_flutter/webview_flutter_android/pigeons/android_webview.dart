// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:pigeon/pigeon.dart';

@ConfigurePigeon(
  PigeonOptions(
    dartOut: 'lib/src/android_webview.g.dart',
    dartTestOut: 'test/test_android_webview.g.dart',
    dartOptions: DartOptions(copyrightHeader: <String>[
      'Copyright 2013 The Flutter Authors. All rights reserved.',
      'Use of this source code is governed by a BSD-style license that can be',
      'found in the LICENSE file.',
    ]),
    javaOut:
        'android/src/main/java/io/flutter/plugins/webviewflutter/GeneratedAndroidWebView.java',
    javaOptions: JavaOptions(
      package: 'io.flutter.plugins.webviewflutter',
      className: 'GeneratedAndroidWebView',
      copyrightHeader: <String>[
        'Copyright 2013 The Flutter Authors. All rights reserved.',
        'Use of this source code is governed by a BSD-style license that can be',
        'found in the LICENSE file.',
      ],
    ),
  ),
)

/// Mode of how to select files for a file chooser.
///
/// See https://developer.android.com/reference/android/webkit/WebChromeClient.FileChooserParams.
enum FileChooserMode {
  /// Open single file and requires that the file exists before allowing the
  /// user to pick it.
  ///
  /// See https://developer.android.com/reference/android/webkit/WebChromeClient.FileChooserParams#MODE_OPEN.
  open,

  /// Similar to [open] but allows multiple files to be selected.
  ///
  /// See https://developer.android.com/reference/android/webkit/WebChromeClient.FileChooserParams#MODE_OPEN_MULTIPLE.
  openMultiple,

  /// Allows picking a nonexistent file and saving it.
  ///
  /// See https://developer.android.com/reference/android/webkit/WebChromeClient.FileChooserParams#MODE_SAVE.
  save,
}

// TODO(bparrishMines): Enums need be wrapped in a data class because thay can't
// be used as primitive arguments. See https://github.com/flutter/flutter/issues/87307
class FileChooserModeEnumData {
  late FileChooserMode value;
}

class WebResourceRequestData {
  WebResourceRequestData(
    this.url,
    this.isForMainFrame,
    this.isRedirect,
    this.hasGesture,
    this.method,
    this.requestHeaders,
  );

  String url;
  bool isForMainFrame;
  bool? isRedirect;
  bool hasGesture;
  String method;
  Map<String?, String?> requestHeaders;
}

class WebResourceErrorData {
  WebResourceErrorData(this.errorCode, this.description);

  int errorCode;
  String description;
}

class WebViewPoint {
  WebViewPoint(this.x, this.y);

  int x;
  int y;
}

/// Handles methods calls to the native Java Object class.
///
/// Also handles calls to remove the reference to an instance with `dispose`.
///
/// See https://docs.oracle.com/javase/7/docs/api/java/lang/Object.html.
@HostApi(dartHostTestHandler: 'TestJavaObjectHostApi')
abstract class JavaObjectHostApi {
  void dispose(int identifier);
}

/// Handles callbacks methods for the native Java Object class.
///
/// See https://docs.oracle.com/javase/7/docs/api/java/lang/Object.html.
@FlutterApi()
abstract class JavaObjectFlutterApi {
  void dispose(int identifier);
}

@HostApi()
abstract class CookieManagerHostApi {
  @async
  bool clearCookies();

  void setCookie(String url, String value);
}

@HostApi(dartHostTestHandler: 'TestWebViewHostApi')
abstract class WebViewHostApi {
  void create(int instanceId, bool useHybridComposition);

  void loadData(
    int instanceId,
    String data,
    String? mimeType,
    String? encoding,
  );

  void loadDataWithBaseUrl(
    int instanceId,
    String? baseUrl,
    String data,
    String? mimeType,
    String? encoding,
    String? historyUrl,
  );

  void loadUrl(
    int instanceId,
    String url,
    Map<String, String> headers,
  );

  void postUrl(
    int instanceId,
    String url,
    Uint8List data,
  );

  String? getUrl(int instanceId);

  bool canGoBack(int instanceId);

  bool canGoForward(int instanceId);

  void goBack(int instanceId);

  void goForward(int instanceId);

  void reload(int instanceId);

  void clearCache(int instanceId, bool includeDiskFiles);

  @async
  String? evaluateJavascript(
    int instanceId,
    String javascriptString,
  );

  String? getTitle(int instanceId);

  void scrollTo(int instanceId, int x, int y);

  void scrollBy(int instanceId, int x, int y);

  int getScrollX(int instanceId);

  int getScrollY(int instanceId);

  WebViewPoint getScrollPosition(int instanceId);

  void setWebContentsDebuggingEnabled(bool enabled);

  void setWebViewClient(int instanceId, int webViewClientInstanceId);

  void addJavaScriptChannel(int instanceId, int javaScriptChannelInstanceId);

  void removeJavaScriptChannel(int instanceId, int javaScriptChannelInstanceId);

  void setDownloadListener(int instanceId, int? listenerInstanceId);

  void setWebChromeClient(int instanceId, int? clientInstanceId);

  void setBackgroundColor(int instanceId, int color);
}

@HostApi(dartHostTestHandler: 'TestWebSettingsHostApi')
abstract class WebSettingsHostApi {
  void create(int instanceId, int webViewInstanceId);

  void setDomStorageEnabled(int instanceId, bool flag);

  void setJavaScriptCanOpenWindowsAutomatically(int instanceId, bool flag);

  void setSupportMultipleWindows(int instanceId, bool support);

  void setJavaScriptEnabled(int instanceId, bool flag);

  void setUserAgentString(int instanceId, String? userAgentString);

  void setMediaPlaybackRequiresUserGesture(int instanceId, bool require);

  void setSupportZoom(int instanceId, bool support);

  void setLoadWithOverviewMode(int instanceId, bool overview);

  void setUseWideViewPort(int instanceId, bool use);

  void setDisplayZoomControls(int instanceId, bool enabled);

  void setBuiltInZoomControls(int instanceId, bool enabled);

  void setAllowFileAccess(int instanceId, bool enabled);
}

@HostApi(dartHostTestHandler: 'TestJavaScriptChannelHostApi')
abstract class JavaScriptChannelHostApi {
  void create(int instanceId, String channelName);
}

@FlutterApi()
abstract class JavaScriptChannelFlutterApi {
  void postMessage(int instanceId, String message);
}

@HostApi(dartHostTestHandler: 'TestWebViewClientHostApi')
abstract class WebViewClientHostApi {
  void create(int instanceId);

  void setSynchronousReturnValueForShouldOverrideUrlLoading(
    int instanceId,
    bool value,
  );
}

@FlutterApi()
abstract class WebViewClientFlutterApi {
  void onPageStarted(int instanceId, int webViewInstanceId, String url);

  void onPageFinished(int instanceId, int webViewInstanceId, String url);

  void onReceivedRequestError(
    int instanceId,
    int webViewInstanceId,
    WebResourceRequestData request,
    WebResourceErrorData error,
  );

  void onReceivedError(
    int instanceId,
    int webViewInstanceId,
    int errorCode,
    String description,
    String failingUrl,
  );

  void requestLoading(
    int instanceId,
    int webViewInstanceId,
    WebResourceRequestData request,
  );

  void urlLoading(int instanceId, int webViewInstanceId, String url);
}

@HostApi(dartHostTestHandler: 'TestDownloadListenerHostApi')
abstract class DownloadListenerHostApi {
  void create(int instanceId);
}

@FlutterApi()
abstract class DownloadListenerFlutterApi {
  void onDownloadStart(
    int instanceId,
    String url,
    String userAgent,
    String contentDisposition,
    String mimetype,
    int contentLength,
  );
}

@HostApi(dartHostTestHandler: 'TestWebChromeClientHostApi')
abstract class WebChromeClientHostApi {
  void create(int instanceId);

  void setSynchronousReturnValueForOnShowFileChooser(
    int instanceId,
    bool value,
  );
}

@HostApi(dartHostTestHandler: 'TestAssetManagerHostApi')
abstract class FlutterAssetManagerHostApi {
  List<String> list(String path);

  String getAssetFilePathByName(String name);
}

@FlutterApi()
abstract class WebChromeClientFlutterApi {
  void onProgressChanged(int instanceId, int webViewInstanceId, int progress);

  @async
  List<String> onShowFileChooser(
    int instanceId,
    int webViewInstanceId,
    int paramsInstanceId,
  );
}

@HostApi(dartHostTestHandler: 'TestWebStorageHostApi')
abstract class WebStorageHostApi {
  void create(int instanceId);

  void deleteAllData(int instanceId);
}

/// Handles callbacks methods for the native Java FileChooserParams class.
///
/// See https://developer.android.com/reference/android/webkit/WebChromeClient.FileChooserParams.
@FlutterApi()
abstract class FileChooserParamsFlutterApi {
  void create(
    int instanceId,
    bool isCaptureEnabled,
    List<String> acceptTypes,
    FileChooserModeEnumData mode,
    String? filenameHint,
  );
}
