// MG: Issue 0000837: Implement Source Editor with new appearance

import 'package:flutter/material.dart';
import 'app_data.dart';
import 'app_ui.dart';
import 'dlsettingpanel.dart';
import 'dlsettings2tab.dart';
import 'dldropdown.dart';

class SourceEditor2 extends StatefulWidget {
  final String element;
  const SourceEditor2( this.element, {super.key});

  @override
  State<SourceEditor2> createState() => _SourceEditor2State( );
}

class _SourceEditor2State extends State<SourceEditor2> {
  String elementLabel = "";
  String sourcePrefix = "";
  String already = "";
  String element = "";
  final String _curTab = "";
  List<String> _curTabs = [];

  Map<String, String> elementToDatapoint = {};
  // Define a list of items for the dropdowns
  List<String> availableDatapoints = DLAppData.appData.selectableDatapoints;
  String? selectedValue;

  _SourceEditor2State( ) {
    elementToDatapoint.addAll(DLAppData.appData.elementSources);
  }

  void tabHandler(String label, List<String> labels) {
    // Just one tab
  }

  void buttonHandler(BuildContext context, String label) {
    if (label == "Cancel") {
      Navigator.pop(context);
    } else if (label == "Save") {
      //Save datapoint  selection
      DLAppData.appData
          .setElementsDatapoint(element, selectedValue ?? "");
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
    already = "";
    elementToDatapoint.forEach((String key, String value ) {
      if( key.indexOf(sourcePrefix) == 0 && key != element && value == val && already.isEmpty )
      {
        String label = getLastUpper( key ).replaceFirst("Gauge", "Gauge ");
        already = "Note: $label already uses $val";
      }
    });

    setState(() {
      selectedValue = val;
    });
  }

  String getLastUpper( String src ) {
    List<String> parts = src.split(".");
    return parts[2][0].toUpperCase() + parts[2].substring(1);
  }

  @override
  Widget build(BuildContext context) {

    if( element.isEmpty ) {
      element = widget.element.toLowerCase();
      List<String> parts = element.split(".");
      sourcePrefix = '${parts[0]}.${parts[1]}';
      elementLabel = parts[2][0].toUpperCase() + parts[2].substring(1);
      elementLabel = elementLabel.replaceFirst("Gauge", "Gauge ");
      _curTabs = [ elementLabel];
      selectedValue = elementToDatapoint[ element ];
    }

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

    List<Widget> sourceWidgets = [];

    // Add the tab control
    sourceWidgets.add(
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
    TextStyle labelStyle = TextStyle(
        fontFamily: 'ChakraPetch',
        fontSize: defaultFontSize,
        fontWeight: FontWeight.bold);
    TextStyle warnStyle = TextStyle(
        fontFamily: 'ChakraPetch',
        fontSize: defaultFontSize,
        fontWeight: FontWeight.bold,
        color: Colors.yellow,
        );
    double cTop = 80;

    sourceWidgets.add( Positioned(
        top: cTop,
        left: 40,
        child:

        Column( children: [
            Row( children: [
          // SizedBox( width: labelWidth, height: cellHeight, child:
          Center( child: Text( "Select the datapoint for $elementLabel " , style: labelStyle, ) ),
          // ),
          SizedBox( width: comboWidth, height: cellHeight, child:
          DLDropdownWidget(
            options: DLAppData.appData.getAllDatapointLabels(),
            initialValue: selectedValue?? 'ERR',
            onChanged: onChanged,
            fieldName: elementLabel,
            fillSafeAreaHeight: true,
          )
          ),
          ] ),
          Text( already, style: warnStyle, )
        ] ),
      ) );
    // }

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
                                children: sourceWidgets,
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
