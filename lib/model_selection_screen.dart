import 'package:flutter/material.dart';

import 'home_page.dart';

class ModelSelectionScreen extends StatelessWidget {
  ModelSelectionScreen({super.key});

  Size getSize(BuildContext context) {
    return MediaQuery.of(context).size;
  }

  bool isPreTrained = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Object Detection'),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
            child: SizedBox(
              height: 60,
              width: getSize(context).width,
              child: ElevatedButton(
                onPressed: () {
                  isPreTrained = true;
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => HomePage(isPreTrained)));
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                ),
                child: const Text(
                  "Object Detection using pre trained model",
                  style: TextStyle(
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(
            height: 20,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
            child: SizedBox(
              height: 60,
              width: getSize(context).width,
              child: ElevatedButton(
                onPressed: () {
                  isPreTrained = false;
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => HomePage(isPreTrained)));
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                ),
                child: const Text(
                  "Object Detection using Custom model",
                  style: TextStyle(
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
