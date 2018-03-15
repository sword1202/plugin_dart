// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.plugins.imagepicker;

import android.Manifest;
import android.app.Activity;
import android.content.Intent;
import android.content.pm.PackageManager;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.media.ExifInterface;
import android.support.v4.app.ActivityCompat;
import android.support.v4.content.ContextCompat;
import android.util.Log;
import com.esafirm.imagepicker.features.ImagePicker;
import com.esafirm.imagepicker.features.camera.DefaultCameraModule;
import com.esafirm.imagepicker.features.camera.OnImageReadyListener;
import com.esafirm.imagepicker.model.Image;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.plugin.common.PluginRegistry;
import io.flutter.plugin.common.PluginRegistry.ActivityResultListener;
import io.flutter.plugin.common.PluginRegistry.RequestPermissionsResultListener;
import java.io.ByteArrayOutputStream;
import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;

/** ImagePicker Plugin */
public class ImagePickerPlugin
    implements MethodCallHandler, ActivityResultListener, RequestPermissionsResultListener {
  private static String TAG = "ImagePicker";
  private static final String CHANNEL = "image_picker";

  public static final int REQUEST_CODE_PICK = 2342;
  public static final int REQUEST_CODE_CAMERA = 2343;
  public static final int REQUEST_PERMISSIONS = 2345;

  private static final int SOURCE_ASK_USER = 0;
  private static final int SOURCE_CAMERA = 1;
  private static final int SOURCE_GALLERY = 2;

  private static final DefaultCameraModule cameraModule = new DefaultCameraModule();

  private final PluginRegistry.Registrar registrar;

  // Pending method call to obtain an image
  private Result pendingResult;
  private MethodCall methodCall;

  public static void registerWith(PluginRegistry.Registrar registrar) {
    final MethodChannel channel = new MethodChannel(registrar.messenger(), CHANNEL);
    final ImagePickerPlugin instance = new ImagePickerPlugin(registrar);
    registrar.addActivityResultListener(instance);
    registrar.addRequestPermissionsResultListener(instance);
    channel.setMethodCallHandler(instance);
  }

  private ImagePickerPlugin(PluginRegistry.Registrar registrar) {
    this.registrar = registrar;
  }

  @Override
  public void onMethodCall(MethodCall call, Result result) {
    if (pendingResult != null) {
      result.error("ALREADY_ACTIVE", "Image picker is already active", null);
      return;
    }

    Activity activity = registrar.activity();
    if (activity == null) {
      result.error("no_activity", "image_picker plugin requires a foreground activity.", null);
      return;
    }

    pendingResult = result;
    methodCall = call;

    if (call.method.equals("pickImage")) {
      int imageSource = call.argument("source");

      switch (imageSource) {
        case SOURCE_ASK_USER:
          ImagePicker.create(activity).single().start(REQUEST_CODE_PICK);
          break;
        case SOURCE_GALLERY:
          ImagePicker.create(activity).single().showCamera(false).start(REQUEST_CODE_PICK);
          break;
        case SOURCE_CAMERA:
          if (ContextCompat.checkSelfPermission(activity, Manifest.permission.CAMERA)
                  != PackageManager.PERMISSION_GRANTED
              || ContextCompat.checkSelfPermission(
                      activity, Manifest.permission.READ_EXTERNAL_STORAGE)
                  != PackageManager.PERMISSION_GRANTED) {
            ActivityCompat.requestPermissions(
                activity,
                new String[] {
                  Manifest.permission.CAMERA, Manifest.permission.READ_EXTERNAL_STORAGE
                },
                REQUEST_PERMISSIONS);
            break;
          }
          activity.startActivityForResult(
              cameraModule.getCameraIntent(activity), REQUEST_CODE_CAMERA);
          break;
        default:
          throw new IllegalArgumentException("Invalid image source: " + imageSource);
      }
    } else {
      throw new IllegalArgumentException("Unknown method " + call.method);
    }
  }

  @Override
  public boolean onActivityResult(int requestCode, int resultCode, Intent data) {
    if (requestCode == REQUEST_CODE_PICK) {
      if (resultCode == Activity.RESULT_OK && data != null) {
        ArrayList<Image> images = (ArrayList<Image>) ImagePicker.getImages(data);
        handleResult(images.get(0));
        return true;
      } else if (resultCode != Activity.RESULT_CANCELED) {
        pendingResult.error("PICK_ERROR", "Error picking image", null);
      }

      pendingResult = null;
      methodCall = null;
      return true;
    }
    if (requestCode == REQUEST_CODE_CAMERA) {
      if (resultCode == Activity.RESULT_OK) {
        cameraModule.getImage(
            registrar.context(),
            data,
            new OnImageReadyListener() {
              @Override
              public void onImageReady(List<Image> images) {
                handleResult(images.get(0));
              }
            });
        return true;
      } else if (resultCode != Activity.RESULT_CANCELED) {
        pendingResult.error("PICK_ERROR", "Error taking photo", null);
      }

      pendingResult = null;
      methodCall = null;
      return true;
    }
    return false;
  }

  @Override
  public boolean onRequestPermissionsResult(
      int requestCode, String[] permissions, int[] grantResults) {
    if (requestCode == REQUEST_PERMISSIONS) {
      if (grantResults.length == 2
          && grantResults[0] == PackageManager.PERMISSION_GRANTED
          && grantResults[1] == PackageManager.PERMISSION_GRANTED) {
        Activity activity = registrar.activity();
        if (activity == null) {
          pendingResult.error(
              "no_activity", "image_picker plugin requires a foreground activity.", null);
        }
        activity.startActivityForResult(
            cameraModule.getCameraIntent(activity), REQUEST_CODE_CAMERA);
      } else {
        pendingResult.error(
            "no_permissions", "image_picker plugin requires camera permissions", null);
        pendingResult = null;
        methodCall = null;
      }
      return true;
    }
    return false;
  }

  private void handleResult(Image image) {
    if (pendingResult != null) {
      Double maxWidth = methodCall.argument("maxWidth");
      Double maxHeight = methodCall.argument("maxHeight");
      boolean shouldScale = maxWidth != null || maxHeight != null;

      if (!shouldScale) {
        pendingResult.success(image.getPath());
      } else {
        try {
          File imageFile = scaleImage(image, maxWidth, maxHeight);
          pendingResult.success(imageFile.getPath());
        } catch (IOException e) {
          throw new RuntimeException(e);
        }
      }

      pendingResult = null;
      methodCall = null;
    } else {
      throw new IllegalStateException("Received images from picker that were not requested");
    }
  }

  private File scaleImage(Image image, Double maxWidth, Double maxHeight) throws IOException {
    Bitmap bmp = BitmapFactory.decodeFile(image.getPath());
    double originalWidth = bmp.getWidth() * 1.0;
    double originalHeight = bmp.getHeight() * 1.0;

    boolean hasMaxWidth = maxWidth != null;
    boolean hasMaxHeight = maxHeight != null;

    Double width = hasMaxWidth ? Math.min(originalWidth, maxWidth) : originalWidth;
    Double height = hasMaxHeight ? Math.min(originalHeight, maxHeight) : originalHeight;

    boolean shouldDownscaleWidth = hasMaxWidth && maxWidth < originalWidth;
    boolean shouldDownscaleHeight = hasMaxHeight && maxHeight < originalHeight;
    boolean shouldDownscale = shouldDownscaleWidth || shouldDownscaleHeight;

    if (shouldDownscale) {
      double downscaledWidth = (height / originalHeight) * originalWidth;
      double downscaledHeight = (width / originalWidth) * originalHeight;

      if (width < height) {
        if (!hasMaxWidth) {
          width = downscaledWidth;
        } else {
          height = downscaledHeight;
        }
      } else if (height < width) {
        if (!hasMaxHeight) {
          height = downscaledHeight;
        } else {
          width = downscaledWidth;
        }
      } else {
        if (originalWidth < originalHeight) {
          width = downscaledWidth;
        } else if (originalHeight < originalWidth) {
          height = downscaledHeight;
        }
      }
    }

    Bitmap scaledBmp = Bitmap.createScaledBitmap(bmp, width.intValue(), height.intValue(), false);
    ByteArrayOutputStream outputStream = new ByteArrayOutputStream();
    scaledBmp.compress(Bitmap.CompressFormat.JPEG, 100, outputStream);

    String scaledCopyPath = image.getPath().replace(image.getName(), "scaled_" + image.getName());
    File imageFile = new File(scaledCopyPath);

    FileOutputStream fileOutput = new FileOutputStream(imageFile);
    fileOutput.write(outputStream.toByteArray());
    fileOutput.close();

    if (shouldDownscale) {
      copyExif(image.getPath(), scaledCopyPath);
    }

    return imageFile;
  }

  private void copyExif(String filePathOri, String filePathDest) {
    try {
      ExifInterface oldExif = new ExifInterface(filePathOri);
      ExifInterface newExif = new ExifInterface(filePathDest);

      List<String> attributes =
          Arrays.asList(
              "FNumber",
              "ExposureTime",
              "ISOSpeedRatings",
              "GPSAltitude",
              "GPSAltitudeRef",
              "FocalLength",
              "GPSDateStamp",
              "WhiteBalance",
              "GPSProcessingMethod",
              "GPSTimeStamp",
              "DateTime",
              "Flash",
              "GPSLatitude",
              "GPSLatitudeRef",
              "GPSLongitude",
              "GPSLongitudeRef",
              "Make",
              "Model",
              "Orientation");
      for (String attribute : attributes) {
        setIfNotNull(oldExif, newExif, attribute);
      }

      newExif.saveAttributes();

    } catch (Exception ex) {
      Log.e(TAG, "Error preserving Exif data on selected image: " + ex);
    }
  }

  private void setIfNotNull(ExifInterface oldExif, ExifInterface newExif, String property) {
    if (oldExif.getAttribute(property) != null) {
      newExif.setAttribute(property, oldExif.getAttribute(property));
    }
  }
}
