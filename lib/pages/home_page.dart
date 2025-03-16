import 'dart:async';
import 'dart:developer';

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
  final _repository = PlatformRepository(getMacAddress(1));
  String battery = "N/A";
  TextEditingController _controller = TextEditingController();

  _connect(String mac) async {
    await _repository.connectToDevice(context, mac);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                setState(() {
                  // @TODO, mac address need to be configurable
                  _connect(_controller.text);
                  Timer.periodic(Duration(seconds: 60), (timer) async {
                    var data = await _repository.getModuleData(context);
                    data.filter((list) => list.isNotEmpty).ifPresent((
                      value,
                    ) async {
                      //@TODO update GUI
                      await SensorService().sendSensorData(
                        Board(getMacAddress(1), value),
                      );
                      (await _repository.getBatteryLevel(context)).ifPresent((
                        batteryLevel,
                      ) {
                        setState(() {
                          battery = batteryLevel.toString();
                        });
                      });
                    }, orElse: () => log("No data received from board"));
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
            Text(battery, style: TextStyle(fontSize: 20)),
          ],
        ),
      ),
    );
  }
}
