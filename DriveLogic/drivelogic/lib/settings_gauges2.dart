import 'package:flutter/material.dart';
import 'app_data.dart';
import 'app_ui.dart';
import 'datapoint.dart';
import 'dlsettingpanel.dart';
import 'dlsettings2tab.dart';
import 'dldropdown.dart';
import 'dleditdialog.dart';

class SettingsGauges2 extends StatefulWidget {
  const SettingsGauges2({super.key});

  @override
  State<SettingsGauges2> createState() => _SettingsGauges2State();
}

class _SettingsGauges2State extends State<SettingsGauges2> {
  String _curTab = "";
  List<String> _curTabs = ["Gauges"];

  Map<String, String> elementToDatapoint = {};
  // Define a list of items for the dropdowns
  List<String> availableDatapoints = DLAppData.appData.selectableDatapoints;
  List<String?> selectedValues = [];

  // Map<String, double> elementTurnOn = {};
  // elementTurnOnTextControllers was intended to set minimum and maximum values
  Map<String, String> elementTurnOnValues = {};

  _SettingsGauges2State() {
    elementToDatapoint.addAll(DLAppData.appData.elementSources);
    elementToDatapoint.forEach((String key, String label) {
      if (key.indexOf(RegExp('${DLAppData.appData.visualLayout}.mutable.',caseSensitive: false)) == 0) {
        selectedValues.add(label.split(',')[0]);
      }
    });

    // Copy AppData.userOnOffElements values into
    //DLAppData.appData.elementTurnOn
    for (String visualElement in DLAppData.appData.userOnOffElements) {
      String src =  DLAppData.appData.getElementSource( visualElement );
      String val = '';
      List<String> attributes = src.split(",");
      if( attributes.length == 3 ) { // label, warnLow, warnHigh
        val = attributes[2];
      } else if( attributes.length == 2 ) { // label, warnLow, warnHigh
        val = attributes[1];
      }
      elementTurnOnValues[ "${DLAppData.appData.visualLayout}.$visualElement" ] = val;
    }
  }

  String buildUserDisplay( String str, bool simple )
  {
    String ret;
    List<String> ar = str.split('.');

    if( simple ) {
      ret = "${ar[1]} ${ar[2]}";
    }
    else {
      ret = ar[2];
      if( ar[0] == 'UserOnOff' ) {
        ret += " turns on when ";
      }
      ret += ar[1];
      if( ar[0] == 'UserOnOff' ) {
        ret += " >= ";
      }
    }
    return ret;
  }

  void tabHandler(String label, List<String> labels) {
    if( mounted ) {
      setState(() {
        _curTab = label;
        _curTabs = labels;
      });
    }
  }

  void buttonHandler(BuildContext context, String label) {
    if (label == "Cancel") {
      Navigator.pop(context);
    } else if (label == "Save") {
      int index = 0;

      //Save gauge selections
      elementToDatapoint.forEach((String key, String label) {
        if (key.indexOf(RegExp('${DLAppData.appData.visualLayout}.mutable.',
            caseSensitive: false)) ==
            0) {
          DLAppData.appData
              .setElementsDatapoint(key, selectedValues[index++] ?? "");
        }
      });

      // Save OnOff settings
      elementTurnOnValues.forEach((String key, String val) {
        if (key.indexOf(RegExp('${DLAppData.appData.visualLayout}.useronoff.',
            caseSensitive: false)) == 0) {
          List<String> portions = DLAppData.appData.elementSources[ key.toLowerCase() ]!.split(',');
          DLAppData.appData
              .setElementsSource(key, portions[0], portions[1], val );
        }
      });

      DLAppData.appData.store(load: false).whenComplete(() { // and store the changes
        if( context.mounted ) {
          Navigator.pop(context);
        }
      });
    } else {
      dlDialogBuilder(context, DLDialogBuilderType.confirmation, "$label Not implemented");
    }
  }

  void onChanged( String key, String val )
  {
    key = key.replaceFirst('Gauge','');
    setState(() {
      selectedValues[ int.parse(key) - 1 ] = val;
    });
  }

  void changeOnOff( String keyAndValue ) {
     List<String> pair = keyAndValue.split(':');
     setState(() {
       elementTurnOnValues[ pair[0] ] = pair[1];
     });
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
    final double cellHeight = (height ) / 6;

    List<Widget> gaugeWidgets = [];

    // Add the tab control
    gaugeWidgets.add(
        SizedBox(
          width: double.infinity,
          height: height,
          child: DLSettings2TabWidget(
            tabHandler, _curTab, _curTabs,
            gap: 10,
            tabWidth: width / 7, tabHeight: height / 8,
            ),
        )
    );

    double comboWidth = width / 8;
    double labelWidth = width / 8;
    double colGap = 2;
    double rowGap = 2;
    double columnWidth = comboWidth + labelWidth + colGap;
    int index=0;
    TextStyle labelStyle = TextStyle(
        fontFamily: 'ChakraPetch',
        fontSize: defaultFontSize,
        fontWeight: FontWeight.bold);

    // Add the comboboxes for the gauges
    double bottomOfCombos = 0;
    for (var element in DLAppData.appData.changeableElements) {
      double cTop = 80 + (index % 3 ) * (cellHeight+rowGap);
      bottomOfCombos = cTop +  (cellHeight+rowGap);

      gaugeWidgets.add( Positioned(
        top: cTop,
        left: 40 + ( (index-1) / 3).round() * columnWidth,
        child:

            Row( children: [
              SizedBox( width: labelWidth, height: cellHeight, child:
                Center( child: Text( element.replaceFirst( 'Gauge', 'Gauge '), style: labelStyle, ) ),
              ),
              SizedBox( width: comboWidth, height: cellHeight, child:
                DLDropdownWidget(
                  options: DLAppData.appData.getAllDatapointLabels(),
                  initialValue: selectedValues[index]?? 'ERR',
                  onChanged: onChanged,
                  fieldName: element,
                  fillSafeAreaHeight: true,
                  templateText: 'XXXX',
                )
            ),

        ] ),
      ) );
      index++;
    }

    // Add UserOnOff values, just warnHigh at the moment.
    for( int i=0; i < DLAppData.appData.userOnOffElements.length; i++ )
    {
      String key = '${DLAppData.appData.visualLayout}.${DLAppData.appData.userOnOffElements[i]}';
      if( elementTurnOnValues.containsKey( key ) == false ) {
        List<String> pieces = DLAppData.appData.userOnOffElements[i].split('.');
        Datapoint tmpDatapoint = DLAppData.appData.getDatapointByElement( pieces[1] );
        // Store current values
        elementTurnOnValues[ key ] = tmpDatapoint.getDecimaled( tmpDatapoint.warnHigh );
      }

      String initialText = elementTurnOnValues[ key ] ?? 'ERR';
      String editLabel = buildUserDisplay( DLAppData.appData.userOnOffElements[i], false );
      String dialogLabel = buildUserDisplay( DLAppData.appData.userOnOffElements[i], true );

      gaugeWidgets.add( Positioned(
        top: bottomOfCombos,
        left: 40,
        child:
        Row(
            children: [
              SizedBox(
                width: columnWidth * 1.5,
                child:
                Text( editLabel, style: TextStyle( color: sysTextColor, fontSize: largerBodyFontSize  )
                ),
              ),

              SizedBox(
                height: cellHeight,
                width: comboWidth,
                child:
                DLEditTextDialog(
                    width: columnWidth,
                    height: cellHeight,
                    keyboardType: TextInputType.number,
                    maxChars: 5,
                    initialText: initialText,
                    labelText: dialogLabel,
                    onSubmitted: changeOnOff,
                    valueKey: '${DLAppData.appData.visualLayout}.${DLAppData.appData.userOnOffElements[i]}'
                ),
              ),

            ]
        )

      ) );
    }

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
                      DLSettingPanelWidget( iconFile: 'images/NewSettingGaugesIcon.png',
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
                              children: gaugeWidgets,
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
