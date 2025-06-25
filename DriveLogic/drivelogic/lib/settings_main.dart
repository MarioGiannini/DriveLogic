import 'package:drivelogic/settings_led2.dart';
import 'package:flutter/material.dart';
//import 'settings_efi.dart';
// import 'settings_visual.dart';
import 'settings_visual2.dart';
import 'settings_gauges2.dart';
// import 'settings_gauges.dart';
import 'settings_sensors2.dart';
import 'settings_warning2.dart';
import 'settings_general2.dart';
import 'app_ui.dart';
import 'app_data.dart';
import 'dlsettingbutton.dart';

class SettingsMain extends StatelessWidget {
  final VoidCallback onClose;
  SettingsMain( {required this.onClose, super.key}) {
    DLAppData.appData.inSettings = true;
  }

  void buttonHandler( BuildContext context, String label )
  {
    if( label =="Exit" || label == 'WTF' ) {
      DLAppData.appData.store( load: false ).whenComplete( () {
          if( context.mounted ) {
            // Navigator.pop(context);
          }
          DLAppData.appData.inSettings = false;
          onClose();
        }
      );
    }

    else if( label =="Visual" ) {
      Navigator.push(
          context,
          MaterialPageRoute(builder: (context) {
            return const SettingsVisual2();
          })
      );
    }
    else if( label =="Gauges" ) {
      if( DLAppData.appData.visualLayout == 'DEBUG')
        {
          dlDialogBuilder( context, DLDialogBuilderType.information, "Cannot change gauges for DEBUG layout.");
          return;
        }
      Navigator.push(
          context,
          MaterialPageRoute(builder: (context) {
            return const SettingsGauges2();
          })
      );
    }
    else if( label =="Warn Lights" ) {
      if( DLAppData.appData.visualLayout == 'DEBUG')
      {
        dlDialogBuilder( context, DLDialogBuilderType.information, "Cannot change Warnings for DEBUG layout.");
        return;
      }
      Navigator.push(
          context,
          MaterialPageRoute(builder: (context) {
            return const SettingsWarning2();
          })
      );
    } else if( label =="Sensors" ) {
      Navigator.push(
          context,
          MaterialPageRoute(builder: (context) {
            return const SettingsSensors2();
          })
      );
    } else if( label == "General" ) {
        Navigator.push(
        context,
        MaterialPageRoute(builder: (context) {
          return SettingsGeneral2( DLAppData.appData.logText );
        })
      );
    } else if( label == "LEDs" ) {
      Navigator.push(
      context,
      MaterialPageRoute(builder: (context) {
        return const SettingsLED2();
        })
      );
    }

    else {
      dlDialogBuilder( context, DLDialogBuilderType.information, "$label Not implemented" );
    }
  }

  @override
  Widget build(BuildContext context) {
    double padding = MediaQuery.of(context).viewPadding.top;
    if( padding == 0 ) {
      padding = 24;
    }

    double width = MediaQuery.sizeOf(context).width;
    double height = MediaQuery.sizeOf(context).height - padding;
    double logoHeight = height * 0.47;
    double btnHeight = height * 0.39;
    double btnWidth = height * 0.258;
    double btnGap = height *.0216;
    double rowGap = ( height - (logoHeight+btnHeight) ) / 4;

    Scaffold scaffold = Scaffold(
      body:
      Column(
          children: [

            SizedBox( height: padding, width: width),

            Container(
            height: height,
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage("images/CheckeredFlagBackground.jpg"),
                fit: BoxFit.cover,
                ),
              ),

              child: Column(
                children: [
                  SizedBox( width: width, height: rowGap),

                  SizedBox( width: width, height: logoHeight,
                    child: Image.asset(
                      'images/NexGenEFI_Logo_Orange.png',
                      //height: logoHeight*.45,
                      fit: BoxFit.contain,
                      filterQuality: FilterQuality.high,
                    ),
                  ),

                  SizedBox( width: width, height: rowGap*2),

                  Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // "Exit"
                      DLSettingButtonWidget( "images/NewSettingGaugesButton.png", "Gauges", btnWidth, btnHeight, buttonHandler),
                      SizedBox( width: btnGap, height: btnHeight,),
                      DLSettingButtonWidget( "images/NewSettingVisualsButton.png", "Visual", btnWidth, btnHeight, buttonHandler ),
                      SizedBox( width: btnGap, height: btnHeight,),
                      DLSettingButtonWidget( "images/NewSettingWarningLightsButton.png","Warn Lights", btnWidth, btnHeight, buttonHandler ),
                      SizedBox( width: btnGap, height: btnHeight,),
                      DLSettingButtonWidget( "images/NewSettingGeneralButton.png", "General", btnWidth, btnHeight, buttonHandler ),
                      SizedBox( width: btnGap, height: btnHeight,),
                      DLSettingButtonWidget( "images/NewSettingSensorslButton.png", "Sensors", btnWidth, btnHeight, buttonHandler ),
                      SizedBox( width: btnGap, height: btnHeight,),
                      DLSettingButtonWidget( "images/NewSettingLEDslButton.png", "LEDs", btnWidth, btnHeight, buttonHandler ),
                      SizedBox( width: btnGap, height: btnHeight,),
                    ]
                  ),



                ]

              ),

            ),
          ]
      )

    );

    // Implement latest Flutter method to handle back button.
    Widget win = PopScope(
        onPopInvokedWithResult: (bool didPop, Object? result) async {
          if (didPop) {
            //return;
          }
          buttonHandler( context, "Exit");
          //    SystemNavigator.pop();
        },
        child: scaffold
    );
    return win;
  }

}