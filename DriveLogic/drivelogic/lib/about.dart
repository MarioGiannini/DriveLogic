import 'package:flutter/material.dart';


class About extends StatelessWidget {
  const About({super.key});

  @override
  Widget build(BuildContext context) {
    var mediaQuery = MediaQuery.of(context);
    double width = mediaQuery.size.width;
    double height =mediaQuery.size.height;
    double devicePixelRatio =  mediaQuery.devicePixelRatio;
    EdgeInsets padding = mediaQuery.padding;
    double newheight = height - padding.top - padding.bottom;

    double physicalPixelWidth = width * devicePixelRatio;
    var physicalPixelHeight = newheight * devicePixelRatio;
    String dim = "W x H: ${physicalPixelWidth.round()}, ${physicalPixelHeight.round()}";
    return Scaffold(
        appBar: AppBar(
          title: const Text("About"),
          backgroundColor: Colors.green,
        ), // AppBar
        body: Center(
          child: Column(
            children: [
              Text( dim ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('Close'),
              ), // ElevatedButton
            ],
          ),
        )
    ); // Scaffold
  }

}