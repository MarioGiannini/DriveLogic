// MG: Issue 0000839: Implement Warning Lights config screen with new UI
import 'package:flutter/material.dart';
import 'app_data.dart';
import 'app_ui.dart';
import 'dlsettingpanel.dart';
import 'dlsettings2tab.dart';
import 'dleditdialog.dart';

class SettingsWarning2 extends StatefulWidget {


  const SettingsWarning2({super.key});

  @override
  State<SettingsWarning2> createState() => _SettingsWarning2State();
}

class _SettingsWarning2State extends State<SettingsWarning2> {
  Map<String,String> userValues = {};
  static TextStyle labelStyle = TextStyle(
      fontFamily: 'ChakraPetch',
      fontSize: defaultFontSize,
      fontWeight: FontWeight.bold);

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    userValues.addAll(DLAppData.appData.warningLights);
  }

  void saveState() {
    DLAppData.appData.warningLights = userValues;
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

  void onChangedValue( String val )
  {
    List<String> ar1 = val.split(":");
    List<String> ar2 = ar1[0].split('.');
    String key = ar2[1].replaceAll('_','.');
    setState(() {
      userValues[ key ] = ar1[1];
    });
  }


    Widget buildRowCellLabel( String label, double displayWidth ) {
      return SizedBox(
        width: displayWidth * 0.17,
        child: Center(child: Text(label, style: labelStyle)),
      );
    }

    Widget buildRowCellEdit( String key, double displayWidth, double rowHeight ) {
      // Input
      return  SizedBox(
      width: (displayWidth * 0.24) * 0.65,
      height: rowHeight,
      child: Padding(
      padding: const EdgeInsets.all(4.0),
      child:
      DLEditTextDialog(
      width: (displayWidth * 0.24) * 0.65,
      height: rowHeight,
      keyboardType: TextInputType.number,
      maxChars: 5,
      initialText: userValues[ key ] ?? "ERR",
      labelText: key.replaceAll('.', '' ),
      onSubmitted: onChangedValue,
      valueKey: '${DLAppData.appData.visualLayout}.${key.replaceAll('.', '_')}'),
      ),
      );
    }

    Widget buildGridRow( int index, TextStyle labelStyle, double displayWidth, double rowHeight) {
        return Row( children:
        [
          buildRowCellLabel( userValues.keys.elementAt( index * 2 ), displayWidth ),
          buildRowCellEdit( userValues.keys.elementAt( index * 2), displayWidth, rowHeight ),
          buildRowCellLabel( userValues.keys.elementAt(index * 2 +1 ), displayWidth ),
          buildRowCellEdit( userValues.keys.elementAt(index * 2 + 1), displayWidth, rowHeight ),
        ] );
    }

    Widget buildWarningGrid(double displayWidth, double displayHeight, TextStyle labelStyle) {
    final rowHeight = displayHeight / 6;
    return Column(
      children: [
        for (int index = 0; index < 4; index++) buildGridRow( index, labelStyle, displayWidth, rowHeight),
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
            tabHandler, "Warning Lights", const ["Warning Lights"],
            gap: 10,
            tabWidth: width / 7, tabHeight: height / 8,
          ),
        )
    );


    // Add the comboboxes for the gauges
    ledWidgets.add( Positioned(
      top: 80,
      left: 10,
      child: buildWarningGrid( width - (width / 7 ) , height - 80, labelStyle ),
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
                          DLSettingPanelWidget( iconFile: 'images/NewSettingWarningLightsIcon.png',
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
