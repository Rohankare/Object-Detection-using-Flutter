import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_yolo_poc/yolo.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';


import 'bbox.dart';
import 'custom_labels.dart';
import 'labels.dart';

class HomePage extends StatefulWidget {
  const HomePage(this.isPreTrained, {super.key});

  final bool isPreTrained;
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const inModelWidth = 640;
  static const inModelHeight = 640;
  static const numPreClasses = 80;
  static const numClasses = 4;

  static const double maxImageWidgetHeight = 400;

  YoloModel? model;

  File? imageFile;
  bool isLoading = false;

  double confidenceThreshold = 0.4;
  double iouThreshold = 0.1;
  bool agnosticNMS = false;

  List<List<double>>? inferenceOutput;
  List<int> classes = [];
  List<List<double>> bboxes = [];
  List<double> scores = [];

  int? imageWidth;
  int? imageHeight;

  Size getSize(BuildContext context) {
    return MediaQuery.of(context).size;
  }

  @override
  void initState() {
    super.initState();

    model = YoloModel(
        widget.isPreTrained
            ? 'assets/yolov8n_float16.tflite'
            : 'assets/yolo5n_4cls_flutter_float16.tflite',
        inModelWidth,
        inModelHeight,
        widget.isPreTrained ? numPreClasses : numClasses,
        widget.isPreTrained ? 84 : 8);

    model!.init();
  }

  @override
  Widget build(BuildContext context) {
    final bboxesColors = List<Color>.generate(
      widget.isPreTrained ? numPreClasses : numClasses,
      (_) => Color((Random().nextDouble() * 0xFFFFFF).toInt()).withOpacity(1.0),
    );
    final ImagePicker picker = ImagePicker();
    final double displayWidth = MediaQuery.of(context).size.width;
    double resizeFactor = 1;

    if (imageWidth != null && imageHeight != null) {
      double k1 = displayWidth / imageWidth!;
      double k2 = maxImageWidgetHeight / imageHeight!;
      resizeFactor = min(k1, k2);
    }

    int boxClass = 0;

    List<Bbox> bboxesWidgets = [];
    for (int i = 0; i < bboxes.length; i++) {
      final box = bboxes[i];
      boxClass = classes[i];
      bboxesWidgets.add(
        Bbox(
            box[0] * resizeFactor,
            box[1] * resizeFactor,
            box[2] * resizeFactor,
            box[3] * resizeFactor,
            widget.isPreTrained ? labels[boxClass] : customLabels[boxClass],
            scores[i],
            bboxesColors[boxClass]),
      );
    }

    // Count detected objects
    Map<String, int> objectCounts = {};
    for (int classIndex in classes) {
      String objectLabel =
          widget.isPreTrained ? labels[classIndex] : customLabels[classIndex];
      if (objectCounts.containsKey(objectLabel)) {
        objectCounts[objectLabel] = objectCounts[objectLabel]! + 1;
      } else {
        objectCounts[objectLabel] = 1;
      }
    }

    return Scaffold(
      appBar: AppBar(
          title: Text(widget.isPreTrained
              ? 'Object Detection using pre-trained model'
              : 'Object Detection using Custom model')),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          InkWell(
            onTap: () => _showImageSourceDialog(picker),
            child: SizedBox(
              height: maxImageWidgetHeight,
              child: Center(
                child: Stack(
                  children: [
                    if (isLoading)
                      const Center(
                        child: CircularProgressIndicator(),
                      )
                    else if (imageFile == null)
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.file_open_outlined,
                            size: 80,
                          ),
                          Text(
                            'Pick an image',
                            style: Theme.of(context).textTheme.headlineMedium,
                          ),
                        ],
                      )
                    else
                      Image.file(imageFile!),
                    if (!isLoading) ...bboxesWidgets,
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(
            height: 10,
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Visibility(
              visible: imageFile != null,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.isPreTrained
                      ? 'Objects Detected using Pre trained model'
                      : 'Objects Detected using Custom model',

                  style: const TextStyle(
                    fontSize: 20
                  ),),
                  const Text(
                      'Detected objects name and count',
                    style: TextStyle(
                        fontSize: 17
                    ),
                  ),
                  const SizedBox(height: 10),

                  Container(
                    width: getSize(context).width,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Objects Detected: ${bboxes.length}'),
                          const SizedBox(height: 10),
                          ...objectCounts.entries.map((entry) => Text(
                            '${entry.key}: ${entry.value}',
                          )),
                        ],
                      ),
                    ),
                  ),

                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  void _showImageSourceDialog(ImagePicker picker) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Image Source'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Camera'),
              onTap: () => _pickImage(ImageSource.camera, picker),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Gallery'),
              onTap: () => _pickImage(ImageSource.gallery, picker),
            ),
          ],
        ),
      ),
    );
  }

  void _pickImage(ImageSource source, ImagePicker picker) async {
    Navigator.of(context).pop();
    setState(() {
      isLoading = true;
    });
    final XFile? newImageFile = await picker.pickImage(source: source);
    if (newImageFile != null) {
      final imageBytes = await newImageFile.readAsBytes();
      final image = img.decodeImage(imageBytes)!;

      setState(() {
        imageFile = File(newImageFile.path);
        imageWidth = image.width;
        imageHeight = image.height;
        inferenceOutput = model!.infer(image);
        updatePostProcess();
        isLoading = false;
      });
    } else {
      setState(() {
        isLoading = false;
      });
    }
  }

  void updatePostProcess() {
    if (inferenceOutput == null) {
      return;
    }
    final (newClasses, newBboxes, newScores) = model!.postprocess(
      inferenceOutput!,
      imageWidth!,
      imageHeight!,
      confidenceThreshold: confidenceThreshold,
      iouThreshold: iouThreshold,
      agnostic: agnosticNMS,
    );
    debugPrint('Detected ${newBboxes.length} bboxes');
    setState(() {
      classes = newClasses;
      bboxes = newBboxes;
      scores = newScores;
    });
  }
}
