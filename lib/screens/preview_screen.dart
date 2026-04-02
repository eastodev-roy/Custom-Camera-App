import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

class PreviewView extends StatelessWidget {
  final String path;
  final bool isVideo;

  const PreviewView({super.key, required this.path, required this.isVideo});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Preview")),
      body: Column(
        children: [
          Expanded(
            child: isVideo
                ? Center(child: Text("Video Preview Here"))
                : Image.file(File(path)),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(
                onPressed: () => Get.back(),
                child: Text("Retake"),
              ),
              ElevatedButton(
                onPressed: () async {
                  // await image_gallery_saver.saveImage(path);
                  // await ImageGallerySaver.saveFile(path);
                },
                child: Text("Save"),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
