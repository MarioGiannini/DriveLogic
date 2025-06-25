import 'package:flutter/material.dart';
import 'dlsettingbutton.dart';

// DLSettingPanelWidget
//
// DLSettingPanelWidget('images/OffRoadRearSideProfile.png', ),
// Displays the left side panel for settings dialog: Icon with Save, and Cancel buttons.
//

class DLSettingPanelWidget extends StatelessWidget {
  final VoidCallback onSave;
  final VoidCallback onCancel;
  final String iconFile;

  const DLSettingPanelWidget(
      {
    super.key,
        required this.iconFile,
    required this.onSave,
    required this.onCancel,
  });

  void buttonHandler( BuildContext context, String label ) {
    if (label == "Save") {
      onSave();
    }
    else if (label == "Cancel") {
      onCancel();
    }
  }

    @override
  Widget build(BuildContext context) {
    double padding = MediaQuery.of(context).viewPadding.top;
    if( padding == 0 ) {
      padding = 24;
    }

    double height = MediaQuery.sizeOf(context).height - padding;

    double gap = height / 4;

    return SizedBox(
      width: double.infinity,
      height: height,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Opacity(
            opacity: 0.70,
            child: Image.asset(
              'images/Settings2LeftPanelBG.png',
              fit: BoxFit.fill,
            ),
          ),

          Column(
            mainAxisSize: MainAxisSize.min,
            children: [

              SizedBox(height: gap / 4),

              Image.asset( iconFile, width: height / 4 ,
                fit: BoxFit.cover,),

              SizedBox(height: gap / 2),

              DLSettingButtonWidget( "images/NewSettingsSave.png", "Save", height / 4, height / 4, buttonHandler,
              pathBG: "images/NewSettingsSaveCancelBG.png", backgroundOpacity: 0.5 ),
              SizedBox(height: gap / 8),

              DLSettingButtonWidget( "images/NewSettingsCancel.png", "Cancel", height / 4, height / 4, buttonHandler,
                  pathBG: "images/NewSettingsSaveCancelBG.png", backgroundOpacity: 0.5 ),


            ],

          ),
        ],
      ),
    );

  }
}
