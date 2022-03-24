// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// ignore_for_file: public_member_api_docs

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tuple/tuple.dart';

void main() {
  runApp(MaterialApp(
    home: HWImageSelect(),
  ));
}

class HWImageSelect extends StatefulWidget {
  HWImageSelect({Key? key}) : super(key: key);

  final ValueNotifier<Tuple2<Uint8List, img.Image>?> imageVN = ValueNotifier(null);
  final VoidCallback? onNewImageSelected = null;

  @override
  State<StatefulWidget> createState() {
    return _HWImageSelectState();
  }
}

class _HWImageSelectState extends State<HWImageSelect> {
  String? _imagePath;

  @override
  Widget build(BuildContext context) {
    final cameraButton = _imageSelectorButton(
      iconData: Icons.camera_alt_rounded,
      source: ImageSource.camera,
    );
    final galleryButton = _imageSelectorButton(
      iconData: Icons.photo_album,
      source: ImageSource.gallery,
    );
    final cropButton = _cropButton();
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          children: [
            AspectRatio(
              aspectRatio: 1,
              child: ValueListenableBuilder<Tuple2<Uint8List, img.Image>?>(
                valueListenable: widget.imageVN,
                builder: (
                  BuildContext context,
                  Tuple2<Uint8List, img.Image>? byteAndImage,
                  Widget? child,
                ) {
                  return Container(
                    color: byteAndImage == null ? Colors.black26 : Colors.black,
                    child: child = byteAndImage == null
                        ? null
                        : Image.memory(byteAndImage.item1, fit: BoxFit.fill),
                  );
                },
              ),
            ),
            ValueListenableBuilder<Tuple2<Uint8List, img.Image>?>(
              valueListenable: widget.imageVN,
              builder: (
                BuildContext context,
                Tuple2<Uint8List, img.Image>? byteAndImage,
                Widget? child,
              ) {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (widget.imageVN.value != null) cropButton,
                    galleryButton,
                    cameraButton,
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _imageSelectorButton({
    required IconData iconData,
    required ImageSource source,
  }) {
    return IconButton(
      iconSize: 20,
      icon: Icon(iconData),
      onPressed: () async {
        final image = await ImagePicker().pickImage(source: source);
        if (image == null) {
          return;
        }
        await _cropOriginalImage(image.path);
      },
    );
  }

  Widget _cropButton() {
    return IconButton(
      iconSize: 20,
      icon: const Icon(Icons.crop),
      onPressed: () {
        if (_imagePath != null) {
          _cropOriginalImage(_imagePath!);
        }
      },
    );
  }

  Future<void> _cropOriginalImage(String path) async {
    final croppedImageFile = await ImageCropper().cropImage(
      sourcePath: path,
      aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
      aspectRatioPresets: const [
        CropAspectRatioPreset.square,
      ],
    );
    if (croppedImageFile == null) {
      return;
    }

    _imagePath = path;
    widget.imageVN.value = await compute(_decodeImage, croppedImageFile);
    if (widget.onNewImageSelected != null) {
      widget.onNewImageSelected!();
    }
  }
}

Future<Tuple2<Uint8List, img.Image>> _decodeImage(File file) async {
  final bytes = await file.readAsBytes();
  final imgImage = img.decodeImage(bytes)!;
  return Tuple2(bytes, imgImage);
}
