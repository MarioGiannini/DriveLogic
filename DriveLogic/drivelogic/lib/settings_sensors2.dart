import 'package:flutter/material.dart';
import 'app_data.dart';
import 'app_ui.dart';
import 'dlsettingpanel.dart';
import 'dlsettings2tab.dart';
import 'dlsensorpage.dart';
import 'dart:math';

class SettingsSensors2 extends StatefulWidget {
  const SettingsSensors2({super.key});

  @override
  State<SettingsSensors2> createState() => _SettingsSensors2State();
}

class _SettingsSensors2State extends State<SettingsSensors2> {
  String _curTab = "";
  List<String> _curTabs = [];
  int startSensor = 1;
  int endSensor = 5;
  Map<String,String> tmpSensorSettings = Map.from(DLAppData.appData.sensorSettings);

  int totalPages = ( DLAppData.appData.sensorSettings.length / 5).ceil();

  Map<String, String> elementToDatapoint = {};
  // Define a list of items for the dropdowns
  List<String> availableDatapoints = DLAppData.appData.selectableDatapoints;
  List<String?> selectedValues = [];

  Map<String, double> elementTurnOn = {};
  Map<String, TextEditingController> elementTurnOnTextControllers = {};

  _SettingsSensors2State() {

    for (int i = 0; i < totalPages; i++) {
      int fromSensor  = i * 5 + 1;
      int toSensor    = min ( DLAppData.appData.sensorSettings.length,  (i + 1) * 5 );
      _curTabs.add("$fromSensor - $toSensor");
      if( _curTab.isEmpty )
      {
        _curTab = "$fromSensor - $toSensor";
        startSensor = fromSensor;
        endSensor = toSensor;
      }
    }

    elementToDatapoint.addAll(DLAppData.appData.elementSources);
    elementToDatapoint.forEach((String key, String label) {
      if (key.indexOf(RegExp('${DLAppData.appData.visualLayout}.mutable.',caseSensitive: false)) == 0) {
        selectedValues.add(label.split(',')[0]);
      }
    });

    // Copy AppData.userOnOffElements values into
    //DLAppData.appData.elementTurnOn
    for (String visualElement in DLAppData.appData.userOnOffElements) {
      TextEditingController tec = TextEditingController();
      String src =  DLAppData.appData.getElementSource( visualElement );
      List<String> attributes = src.split(",");
      if( attributes.length == 3 ) { // label, warnLow, warnHigh
        tec.text = attributes[2];
      } else if( attributes.length == 2 ) { // label, warnLow, warnHigh
        tec.text = attributes[1];
      }
      elementTurnOnTextControllers[ "${DLAppData.appData.visualLayout}.$visualElement" ] = tec;
    }
  }

  void tabHandler(String label, List<String> labels) {
    if( mounted ) {
      setState(() {
        _curTab = label;
        _curTabs = labels;
        List<String> range = label.replaceAll(" - ", ",").split(",");
        startSensor = int.parse( range[0] );
        endSensor = int.parse( range[1] );
      });
    }
  }

  void buttonHandler(BuildContext context, String label) {
    if (label == "Cancel") {
      Navigator.pop(context);
    } else if (label == "Save") {
      DLAppData.appData.sensorSettings.clear();
      //DLAppData.appData.sensorSettings = tmpSensorSettings;
      tmpSensorSettings.forEach((key, value) {
        List<String> settings = value.split("\t");
        DLAppData.appData.setSensorSettings(
            key,
            settings[0],
            settings[1],
            settings[2],
            settings[3],
            settings[4],
            settings[5],
            settings[6],
        );

      });
      DLAppData.appData.updateDatapointFromSensors();

      DLAppData.appData.store(load: false).whenComplete(() {
        if( context.mounted ) {
          Navigator.pop(context);
        }
      });
    } else {
      dlDialogBuilder(context, DLDialogBuilderType.confirmation, "$label Not implemented");
    }
  }

  @override
  Widget build(BuildContext context) {
    double padding = MediaQuery
        .of(context)
        .viewPadding
        .top;
    if (padding == 0) {
      padding = 24;
    }

    double width = MediaQuery
        .sizeOf(context)
        .width;
    double height = MediaQuery
        .sizeOf(context)
        .height - padding;

    Scaffold scaffold = Scaffold(
        resizeToAvoidBottomInset: true,
        body:

        SingleChildScrollView( child:

        Column(
            children: [

              SizedBox(height: padding, width: width),


              Container(
                height: height,
                width: width,
                decoration: const BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage("images/CheckeredFlagBackground.jpg"),
                    fit: BoxFit.cover,
                  ),
                ),

                child: Row(
                    children: [
                      SizedBox(width: width/7 , height: height,
                          child:
                          DLSettingPanelWidget(
                            iconFile: 'images/NewSettingSensorslIcon.png',
                            onSave: () => buttonHandler(context, "Save"),
                            onCancel: () => buttonHandler(context, "Cancel"),
                          )
                      ),


                      Expanded(
                        child: Column(
                          children: [
                            Expanded(
                              child: Stack(
                                alignment: Alignment.center,
                                children: [

                                  SizedBox(
                                    width: double.infinity,
                                    height: height,
                                    child: DLSettings2TabWidget(
                                      tabHandler, _curTab, _curTabs,
                                      gap: 10,
                                      tabWidth: width / ( _curTabs.length + 5), tabHeight: height / 8,
                                    ),
                                  ),


                                  Positioned(
                                      top: 60,
                                      left: 30,
                                      width: width / 7 * 5.6,
                                      height: height - height / 8,
                                      child:
                                      DLSensorPageWidget( width / 7 * 5.6, height-height / 8 - padding,
                                        startSensor: startSensor, endSensor: endSensor,
                                        sensorSettings: tmpSensorSettings,
                                      ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                    ]
                ),
              ),



            ]
        )
        ),
    );

    return scaffold;
  }
}
