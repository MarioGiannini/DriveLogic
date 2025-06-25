// MG: Issue 0000838: Implement LED settings with new appearance
import 'package:flutter/material.dart';
import 'app_data.dart';
import 'app_ui.dart';
import 'dlsettingpanel.dart';
import 'dlsettings2tab.dart';
import 'dldropdown.dart';
import 'dleditdialog.dart';

class SettingsLED2 extends StatefulWidget {
  const SettingsLED2({super.key});

  @override
  State<SettingsLED2> createState() => _SettingsLED2State();
}

class _SettingsLED2State extends State<SettingsLED2> {
  List<String> availableLEDColors = ["Red","Green","Blue","Violet","Orange"];
  List<String> selectedDatapoints = [];
  List<String> selectedConditions = [];
  List<String> selectedValues = [];
  List<String> selectedColors = [];
  Map<String,String> ledsForLayout = {};

  Map<String, String> elementToDatapoint = {};
  // Define a list of items for the dropdowns
  List<String> availableDatapoints = DLAppData.appData.selectableDatapoints;

  // Map<String, double> elementTurnOn = {};
  // elementTurnOnTextControllers was intended to set minimum and maximum values
  Map<String, String> elementTurnOnValues = {};

  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    DLAppData.appData.ledStripSources.forEach((String key, String data ) {
      if( key.indexOf( '${DLAppData.appData.visualLayout}.' ) == 0 ) {
        ledsForLayout[ key ] = data;
      }
    });
    if( ledsForLayout.isEmpty )
    {
      for( int i=0; i < 5; i++ ) {
        ledsForLayout['${DLAppData.appData.visualLayout}.led$i'] = ",,,,";
      }
    }
    ledsForLayout
        .forEach((String label, String userSettings) {
      List<String> settings = userSettings.split(",");

      selectedDatapoints.add( settings[0].toUpperCase() );
      if( settings[1] != '' )
      {
        selectedConditions.add("<");
        selectedValues.add( settings[1] );
      } else {
        selectedConditions.add(">");
        selectedValues.add( settings[2] );
      }

      if( settings.length > 3 ) {
        selectedColors.add(settings[3]);
      }
      else {
        selectedColors.add('Red');
      }
    });

  }

  void saveState() {

    for( int i=0; i < 5; i++ ) {
      String data = '${selectedDatapoints[i]},${selectedConditions[i] == '<' ? selectedValues[i] : ''},${selectedConditions[i] == '>' ? selectedValues[i] : ''},${selectedColors[i]}';
      DLAppData.appData.ledStripSources['${DLAppData.appData.visualLayout}.led$i'] = data;
    }
    DLAppData.appData.store(load: false).whenComplete(() { // and store the changes
      if( !mounted )
      {
        return;
      }
      Navigator.pop(context);
    });
  }

  void tabHandler(String label, List<String> labels) {
    // Single tab, nothing to do
  }

  void buttonHandler(BuildContext context, String label) {
    if (label == "Cancel") {
      Navigator.pop(context);
    } else if (label == "Save") {
      saveState();
    } else {
      dlDialogBuilder(context, DLDialogBuilderType.confirmation, "$label Not implemented");
    }
  }

  void onChangedDatapoint( String key, String val )
  {
    key = key.replaceFirst('LED ','');
    setState(() {
      selectedDatapoints[ int.parse(key) - 1 ] = val;
    });
  }
  void onChangedCondition( String key, String val )
  {
    key = key.replaceFirst('LED ','');
    setState(() {
      selectedConditions[ int.parse(key) - 1 ] = val;
    });
  }
  void onChangedColor( String key, String val )
  {
    key = key.replaceFirst('LED ','');
    setState(() {
      selectedColors[ int.parse(key) - 1 ] = val;
    });
  }
  void onChangedValue( String val )
  {
    List<String> ar1 = val.split(":");
    List<String> ar2 = ar1[0].split('.');
    String key = ar2[1].replaceFirst("LED", "");
    setState(() {
      selectedValues[ int.parse(key) - 1 ] = ar1[1];
    });
  }

  Widget buildLedGrid(double displayWidth, double displayHeight, TextStyle labelStyle) {
    final rowHeight = displayHeight / 6;

    Widget buildHeaderRow() {
      return SizedBox(
        height: displayHeight / 9,
        child: Row(
          children: [
            Container(
              width: displayWidth * 0.17,
            ),
            SizedBox(
              width: displayWidth * 0.20,
              child: Center(child: Text('Property', style: labelStyle) ),
            ),
            SizedBox(
              width: displayWidth * 0.28,
              child: Center(child: Text('Condition', style: labelStyle) ),
            ),
            SizedBox(
              width: displayWidth * 0.24,
              child: Center(child: Text('Color', style: labelStyle) ),
            ),
          ],
        ),
      );
    }

    Widget buildGridRow( int index, TextStyle labelStyle) {
      String dialogLabel = "LED ${index+1} value";

      return SizedBox(
        height: rowHeight,
        child: Row(
          children: [
            // LED Label
            SizedBox(
              width: displayWidth * 0.17,
              child: Center(child: Text("LED ${index+1}", style: labelStyle)),
            ),

            // Datapoint Field
            SizedBox(
              width: displayWidth * 0.20,
              height: rowHeight,
              child: Padding(
                padding: const EdgeInsets.all(0),
                child:
                DLDropdownWidget(
                  options: availableDatapoints,
                  initialValue: selectedDatapoints[index],
                  onChanged: onChangedDatapoint,
                  fieldName: "LED ${index+1}",
                  fillSafeAreaHeight: true, ),
              ),
            ),

            // Condition Fields, criteria and value
            SizedBox(
              width: displayWidth * 0.28,
              height: rowHeight,
              child: Row(
                children: [
                  SizedBox(
                    width: (displayWidth * 0.28) * 0.39,
                    height: rowHeight,
                    child: Padding(
                      padding: const EdgeInsets.all(0.0),
                      child:
                      DLDropdownWidget(
                        options: const ['<','>'],
                        initialValue: selectedConditions[index],
                        onChanged: onChangedCondition,
                        fieldName: "LED ${index+1}",
                        fillSafeAreaHeight: true, ),
                    ),
                  ),
                  SizedBox(
                    width: (displayWidth * 0.28) * 0.60,
                    height: rowHeight,
                    child: Padding(
                      padding: const EdgeInsets.all(0.0),
                      child:
                      DLEditTextDialog(
                            width: (displayWidth * 0.24) * 0.65,
                            height: rowHeight,
                            keyboardType: TextInputType.number,
                            maxChars: 5,
                            initialText: selectedValues[index],
                            labelText: dialogLabel,
                            onSubmitted: onChangedValue,
                            valueKey: '${DLAppData.appData.visualLayout}.LED${index+1}',
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Color Field
            SizedBox(
              width: displayWidth * 0.24,
              height: rowHeight,
              child: Padding(
                padding: const EdgeInsets.all(0.0),
                child:
                DLDropdownWidget(
                  options: availableLEDColors,
                  initialValue: selectedColors[index],
                  onChanged: onChangedColor,
                  fieldName: "LED ${index+1}",
                  fillSafeAreaHeight: true, ),

              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        buildHeaderRow(),
        for (int index = 0; index < 5; index++) buildGridRow( index, labelStyle),
      ],
    );
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

    List<Widget> ledWidgets = [];

    // Add the tab control
    ledWidgets.add(
        SizedBox(
          width: double.infinity,
          height: height,
          child: DLSettings2TabWidget(
            tabHandler, "LEDs", const ["LEDs"],
            gap: 10,
            tabWidth: width / 7, tabHeight: height / 8,
          ),
        )
    );

    TextStyle labelStyle = TextStyle(
        fontFamily: 'ChakraPetch',
        fontSize: defaultFontSize,
        fontWeight: FontWeight.bold);

    // Add the comboboxes for the gauges
    ledWidgets.add( Positioned(
        top: 80,
        left: 10,
        child: buildLedGrid( width - (width / 7 ) , height - 80, labelStyle ),
    ) );


    Scaffold scaffold = Scaffold(
        body:
        Column(
            children: [

              SizedBox(height: padding, width: width),

              Container(
                height: height,
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
                          DLSettingPanelWidget( iconFile: 'images/NewSettingLEDsIcon.png',
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
                                children: ledWidgets,
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
    );

    return scaffold;
  }
}
