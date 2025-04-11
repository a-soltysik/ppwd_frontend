import 'dart:async';

import 'package:flutter/material.dart';
import 'package:ppwd_frontend/repository/platform_repository.dart';
import 'package:ppwd_frontend/services/sensor_service.dart';
import 'package:ppwd_frontend/utils.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _repository = PlatformRepository();
  String sensorData = "N/A";
  TextEditingController _controller = TextEditingController();

  connect(String mac) async {
    await _repository.connectToDevice(context, mac);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      //  backgroundColor: Colors.blue,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextFormField(
              controller: _controller,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Enter a mac address of divice',
              ),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  // @TODO, mac address need to be configurable
                  //connect(getMacAddress(1));
                  // connect("C1:74:71:F3:94:E0");
                  connect(_controller.text);
                  Timer.periodic(Duration(seconds: 2), (timer) async {
                    List<String>? data = await _repository.getSensorData();
                    if (data != null && data.isNotEmpty) {
                      setState(() {
                        sensorData = data.first;
                      });
                      await SensorService().sendSensorData(data);
                    }
                  });
                });
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Connect to device",
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            Text(sensorData, style: TextStyle(fontSize: 20)),
          ],
        ),
      ),
    );
  }
}
