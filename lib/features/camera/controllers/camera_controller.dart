import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:gallery_asset_picker/entities/gallery_asset.dart';
import 'package:gallery_asset_picker/features/camera/camera.dart';
import 'package:gallery_asset_picker/features/camera/exceptions/camera_exceptions.dart';
import 'package:gallery_asset_picker/utils/utils.dart';
import 'package:intl/intl.dart';
import 'package:photo_manager/photo_manager.dart';

const datePattern = 'yyyyMMdd_HHmmss_MS';

class XCameraController extends ValueNotifier<XCameraValue> {
  XCameraController() : super(const XCameraValue());

  CameraController? _cameraController;
  bool _isDisposed = false;

  CameraController? get cameraController => _cameraController;
  bool get isInitialized => _cameraController?.value.isInitialized ?? false;

  bool get _hasCamera {
    if (!isInitialized) {
      final exception = CameraExceptions.unvailable;
      value = value.copyWith(error: exception);
      return false;
    }
    return true;
  }

  Future<CameraController?> createCamera({CameraDescription? description}) async {
    if (value.error != null) {
      value = value.copyWith();
    }

    var cameraDescription = description ?? value.cameraDescription;
    var cameras = value.cameras;

    // Fetch camera descriptions if description is not available
    if (cameraDescription == null) {
      cameras = await availableCameras();
      if (cameras.isNotEmpty) {
        cameraDescription = cameras[0];
      } else {
        cameraDescription = const CameraDescription(
          name: 'Simulator',
          lensDirection: CameraLensDirection.front,
          sensorOrientation: 0,
        );
      }
    }

    // create camera controller
    _cameraController = CameraController(
      cameraDescription,
      GAPManager.cameraConfig.resolutionPreset,
      imageFormatGroup: GAPManager.cameraConfig.imageFormatGroup,
      enableAudio: false,
    );
    _cameraController!.addListener(() {
      if (_cameraController?.value.hasError == true) {
        value = value.copyWith(error: CameraExceptions.createCamera);
        return;
      }
    });

    return await _safeCall(
      checkHasCamera: false,
      callback: () async {
        await _cameraController!.initialize();
        value = value.copyWith(cameraDescription: cameraDescription, cameras: cameras);
        if (_cameraController!.description.lensDirection == CameraLensDirection.back) {
          unawaited(_cameraController!.setFlashMode(value.flashMode));
        }
      },
      customException: CameraExceptions.createCamera,
    );
  }

  void switchCameraDirection(CameraLensDirection direction) {
    if (!_hasCamera) return;
    final cameraDescription = value.cameras.firstWhereOrNull((element) => element.lensDirection == direction);
    createCamera(description: cameraDescription);
  }

  Future<GalleryAsset?> takePicture(BuildContext context) async {
 return null;
  }

  Future<void> toggleFlashMode() async {
    await _safeCall(
      callback: () async {
        final mode = _cameraController!.value.flashMode == FlashMode.off ? FlashMode.torch : FlashMode.off;
        value = value.copyWith(flashMode: mode);
        await _cameraController!.setFlashMode(mode);
      },
      customException: CameraExceptions.flaseMode,
    );
  }

  Future<dynamic> _safeCall({
    required Future<dynamic> Function() callback,
    CameraException? customException,
    Function()? onError,
    bool checkHasCamera = true,
  }) async {
    if (checkHasCamera && !_hasCamera) return;

    try {
      return await callback();
    } on CameraException catch (e) {
      onError?.call();
      debugPrint('FUCK BUG:  ${e.description}');
      value = value.copyWith(error: e);
      return;
    } catch (e) {
      onError?.call();
      debugPrint('FUCK BUG: ${customException?.description}');
      value = value.copyWith(error: customException);
      return;
    }
  }

  @override
  set value(XCameraValue newValue) {
    if (_isDisposed) return;
    super.value = newValue;
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _isDisposed = true;
    super.dispose();
  }
}
