import 'package:flutter/material.dart';
import 'app_data.dart';
import 'app_ui.dart';
import 'dlsettingpanel.dart';
import 'dlsettings2tab.dart';
import 'dldialog2.dart';
import 'dlbutton.dart';
import 'dldropdown.dart';

class SettingsGeneral2 extends StatefulWidget {
  final List<String> logText;

  const SettingsGeneral2(this.logText, {super.key});

  @override
  State<SettingsGeneral2> createState() => _SettingsGeneral2State();
}

class _SettingsGeneral2State extends State<SettingsGeneral2> {
  String _curTab = "";
  List<String> _curTabs = ["General Settings", "Data Format"];
  Map<String, String> selectedFormats = {};
  bool baroCalc = false;

  @override
  initState() {
    super.initState();
    _curTab = _curTabs[0];
    selectedFormats = Map<String, String>.from(DLAppData.appData.dataFormats);
    baroCalc = (selectedFormats['BaroCalc']??"") == "Y";
  }

  void tabHandler(String label, List<String> labels) {
    if (mounted) {
      setState(() {
        _curTab = label;
        _curTabs = labels;
      });
    }
  }

  Future<void> deleteConfiguration() async {
    await DLAppData.appData.clearConfig();
  }

  void buttonHandler(BuildContext context, String label) async {
    if (label == 'Delete Configuration') {
      dlDialog2(
          context: context,
          dlType: 'Confirmation',
          message: 'Are you sure you want to delete the configuration?',
          buttons: ['Yes', 'No'],
          onResult: (String result) async {
            if (result == 'Yes') {
              await deleteConfiguration();
            }
          });
    } else if (label == "Cancel") {
      Navigator.pop(context);
    } else if (label == "Save") {
      DLAppData.appData.setDataFormats( Map<String, String>.from(selectedFormats) ); // MG: Issue 000836: Implement Data Format feature
      DLAppData.appData.store(load: false).whenComplete(() {
        // and store the changes
        if (context.mounted) {
          Navigator.pop(context);
        }
      });
    } else {
      dlDialogBuilder(
          context, DLDialogBuilderType.confirmation, "$label Not implemented");
    }
  }

  @override
  Widget build(BuildContext context) {
    double padding = MediaQuery.of(context).viewPadding.top;
    if (padding == 0) {
      padding = 24;
    }

    double width = MediaQuery.sizeOf(context).width;
    double height = MediaQuery.sizeOf(context).height - padding;
    double comboWidth = width / 7;
    final double cellHeight = (height) / 6;

    List<Widget> generalWidgets = [];

    // Add the tab control
    generalWidgets.add(SizedBox(
      width: double.infinity,
      height: height,
      child: DLSettings2TabWidget(
        tabHandler,
        _curTab,
        _curTabs,
        gap: 10,
        tabWidth: width / 5,
        tabHeight: height / 8,
      ),
    ));

    TextStyle labelStyle = TextStyle(
      fontFamily: 'ChakraPetch',
      fontSize: defaultFontSize,
      color: Colors.white,
    );

    if (_curTab == "General Settings") {
      buildGeneralSettingsPage(generalWidgets, labelStyle, height);
    } else if (_curTab == "Data Format") {
      buildDataFormatPage(
          generalWidgets, labelStyle, height, comboWidth, cellHeight);
    } else if (_curTab == "Log") {
      generalWidgets.add(Column(children: [
        SizedBox(height: height / 5),
        Row(children: [
          const SizedBox(width: 20),
          Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: Colors.white60,
                width: 2,
              ),
            ),
            padding: EdgeInsets.zero,
            height: height - (height / 4), // required for horizontal lists
            width: width - (width / 5.4),
            child: ListView(
              scrollDirection: Axis.vertical,
              children: widget.logText.reversed
                  .map((item) => Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: Text(item, style: const TextStyle(fontSize: 18)),
                      ))
                  .toList(),
            ),
          )
        ])
      ]));
    }

    Scaffold scaffold = Scaffold(
        body: Column(children: [
      SizedBox(height: padding, width: width),
      Container(
        height: height,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage("images/CheckeredFlagBackground.jpg"),
            fit: BoxFit.cover,
          ),
        ),
        child: Row(children: [
          SizedBox(
              width: width / 7,
              height: height,
              child: DLSettingPanelWidget(
                iconFile: 'images/NewSettingGeneralIcon.png',
                onSave: () => buttonHandler(context, "Save"),
                onCancel: () => buttonHandler(context, "Cancel"),
              )),
          SizedBox(
            width: width - (width / 7),
            height: height,
            child: Column(
              children: [
                Expanded(
                  child: Stack(
                    children: generalWidgets,
                  ),
                ),
              ],
            ),
          ),
        ]),
      ),
    ]));

    return scaffold;
  }

  void onFormatChanged(String key, String val) {
    key = key.replaceFirst('Gauge', '');
    setState(() {
      selectedFormats[key] = val;
    });
  }

  // MG: Issue 000836: Implement Data Format feature
  void buildDataFormatPage(List<Widget> generalWidgets, TextStyle labelStyle,
      double height, double comboWidth, double cellHeight) {
    double dropWidth = comboWidth * 1.25;
    Widget col =
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        SizedBox(
            width: comboWidth,
            height: cellHeight,
            child: Align(
                alignment: Alignment.centerLeft,
                child: Text('Pressure', style: labelStyle))),
        SizedBox(
            width: dropWidth,
            height: cellHeight,
            child: DLDropdownWidget(
              options: const ['PSI', 'kPa'],
              initialValue: selectedFormats['Pressure'] ?? 'ERR',
              onChanged: onFormatChanged,
              fieldName: 'Pressure',
              fillSafeAreaHeight: true,
            )),
        SizedBox(
            width: comboWidth * 2,
            height: cellHeight,
            child: Align(
                alignment: Alignment.centerLeft,
                child: CheckboxListTile(
                  title: Text('Enable Baro in calc', style: labelStyle),
                  value: baroCalc,
                  onChanged: (bool? value) {
                    selectedFormats['BaroCalc'] = value! ? "Y" : "N";
                    setState(() {
                      baroCalc = value;
                    });
                  },
                  controlAffinity: ListTileControlAffinity.leading,
                  fillColor: WidgetStateProperty.resolveWith<Color>(
                      (Set<WidgetState> states) {
                    if (states.contains(WidgetState.selected)) {
                      return Colors.green; // Fill when checked
                    }
                    return Colors.grey; // Fill when unchecked
                  }),
                )))
      ]),
      Row(children: [
        SizedBox(
            width: comboWidth,
            height: cellHeight,
            child: Align(
                alignment: Alignment.centerLeft,
                child: Text('Temperature', style: labelStyle))),
        SizedBox(
            width: dropWidth,
            height: cellHeight,
            child: DLDropdownWidget(
              options: const ['Fahrenheit', 'Celsius'],
              initialValue: selectedFormats['Temperature'] ?? 'ERR',
              onChanged: onFormatChanged,
              fieldName: 'Temperature',
              fillSafeAreaHeight: true,
            ))
      ]),
      Row(children: [
        SizedBox(
            width: comboWidth,
            height: cellHeight,
            child: Align(
                alignment: Alignment.centerLeft,
                child: Text('Speed', style: labelStyle))),
        SizedBox(
            width: dropWidth,
            height: cellHeight,
            child: DLDropdownWidget(
              options: const ['MPH', 'KPH'],
              initialValue: selectedFormats['Speed'] ?? 'ERR',
              onChanged: onFormatChanged,
              fieldName: 'Speed',
              fillSafeAreaHeight: true,
            ))
      ]),
      Row(children: [
        SizedBox(
            width: comboWidth,
            height: cellHeight,
            child: Align(
                alignment: Alignment.centerLeft,
                child: Text('Fuel', style: labelStyle))),
        SizedBox(
            width: dropWidth,
            height: cellHeight,
            child: DLDropdownWidget(
              options: const ['AFR', 'Lambda'],
              initialValue: selectedFormats['Fuel'] ?? 'ERR',
              onChanged: onFormatChanged,
              fieldName: 'Fuel',
              fillSafeAreaHeight: true,
            ))
      ]),
    ]);

    generalWidgets
        .add(Positioned(top: height / 5, left: height / 16, child: col));
  }

  void buildGeneralSettingsPage(
      List<Widget> generalWidgets, TextStyle labelStyle, double height) {
    Widget col =
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Software Version:', style: labelStyle),
      Text("Device: ${DLAppData.appData.deviceVersion}", style: labelStyle),
      Text("DriveLogic: ${DLAppData.appData.appVersion}", style: labelStyle),
      SizedBox(height: height / 16),
    ]);

    Widget col2 = Column(children: [
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        col,
        SizedBox(width: height / 16),
        GestureDetector(
            behavior: HitTestBehavior.translucent,
            onLongPress: () {
              if (_curTabs.length == 2) {
                _curTabs = ["General Settings", "Data Format", "Log"];
                setState(() {});
              }
            },
            child: const SizedBox(
                width: 100,
                height: 100,
                child: Image(
                  image: AssetImage('images/qrcode.jpg'),
                )))
      ]),
      Row(children: [
        Text("Delete configuration:", style: labelStyle),
        SizedBox(width: height / 16),
        SizedBox(
            width: 260,
            height: 60,
            child: DLButtonWidget(
              defaultLineColor: const Color.fromARGB(255, 128, 0, 0),
              lightLineColor: const Color.fromARGB(255, 255, 0, 0),
              backgroundColor: const Color.fromARGB(255, 128, 0, 0),
              label: 'Delete Configuration',
              onPressed: () => buttonHandler(context, "Delete Configuration"),
            ))
      ])
    ]);

    generalWidgets
        .add(Positioned(top: height / 5, left: height / 16, child: col2));
  }
}
