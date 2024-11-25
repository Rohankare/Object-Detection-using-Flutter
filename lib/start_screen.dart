import 'package:flutter/material.dart';

import 'model_selection_screen.dart';


class StartScreen extends StatelessWidget {
  const StartScreen({super.key});

  Size getSize(BuildContext context) {
    return MediaQuery.of(context).size;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            'assets/yashLogo.png',
            height: 200,
            width: 200,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
            child: SizedBox(
              height: 60,
              width: getSize(context).width,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => ModelSelectionScreen()));
                },
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                  ),
                child: const Text(
                  "Start Object Detection",
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
