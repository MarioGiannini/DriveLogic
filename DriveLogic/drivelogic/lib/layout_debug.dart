import 'package:flutter/material.dart';
import 'app_data.dart';
import 'app_ui.dart';
import 'settings_main.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'datapoint.dart';
// This is a special debug layout, to just show lots of data.

Widget buildDebugLayout(BuildContext context, VoidCallback settingsClosed ) {
  return GestureDetector(
      onDoubleTap: (){
        //DLAppData.appData.drawerKey.currentState?.openDrawer();
        Navigator.push(
            context,
            MaterialPageRoute(builder: (context) {
              return SettingsMain( onClose: settingsClosed  );
            }
            )
        );
      },
      child: buildDebugLayout2( )
  );
}

List<Widget> getDebugRightData( BuildContext context, BoxConstraints constraints )
{
  List<Widget> ret=[];
  if( DLAppData.appData.bt != null ) {
    if( DLAppData.appData.packageInfo != null ) {
      PackageInfo packageInfo = DLAppData.appData.packageInfo!;
      ret.add(Text(packageInfo.appName));
      ret.add(Text(packageInfo.packageName));
      ret.add(Text('Version: ${packageInfo.version}.${packageInfo.buildNumber}'));
    }
    ret.add(Text('OS Version: ${DLAppData.appData.osData}'));

    ret.add(const Text( ''));
    ret.add(Text( 'longestDelay: ${DLAppData.appData.bt!.longestDelay}' ));
    if( DLAppData.appData.bt!.shortestDelay == 999999999999999 ){
      ret.add(const Text( 'shortestDelay: N/A' ));
    } else {
      ret.add(Text('shortestDelay: ${DLAppData.appData.bt!.shortestDelay}' ));
    }
    ret.add(Text( 'averageDelay: ${DLAppData.appData.bt!.averageDelay}' ));
    ret.add(Text( 'Reset countdown: ${DLAppData.appData.bt!.resetSeconds()}'));

    ret.add(Text( 'devicePixelRatio: ${devicePixelRatio.toStringAsFixed(2)}'));
    ret.add(Text( 'Top/Bottom Padding: ${logPaddingTop.toStringAsFixed(2)}, ${logPaddingBottom.toStringAsFixed(2)}'));
    ret.add(Text( 'Device height: ${logHeight.toStringAsFixed(2)}  (${phyHeight.toStringAsFixed(0)})'));

    double safeLogHeight = logHeight - logPaddingTop - logPaddingBottom;
    double safePhyHeight = safeLogHeight * devicePixelRatio;
    ret.add(Text( 'Device safe height: ${safeLogHeight.toStringAsFixed(2)}  (${safePhyHeight.toStringAsFixed(0)})'));
    ret.add(Text( 'Device Width: ${logWidth.toStringAsFixed(2)}  (${phyWidth.toStringAsFixed(0)})'));
  }
  return ret;
}

Widget buildDebugLayout2() {
  return LayoutBuilder(

    builder: (context, constraints) {
      double deviceHeight = constraints.maxHeight;
      double deviceWidth = constraints.maxWidth;
      double columnWidth = deviceWidth * 0.75;
      double padding = logPaddingTop;
      if( padding == 0.0 ) {
        padding = MediaQuery.sizeOf(context).height / 11;
      }
      double mas = ( ( deviceHeight / 3 ) - (deviceWidth / 9.0 ) ); // main axis spacing
      if( mas < 0 ) {
        mas = 0;
      }
      List<TableRow> rows = [];
      DLAppData.appData.allDatapoints.forEach( (String key, Datapoint datapoint ) {
        rows.add( dlGetDebugTableRow( datapoint, columnWidth ));
      });
      FixedColumnWidth tableColumnWidth = FixedColumnWidth( columnWidth / 8);

      Widget leftCol = SizedBox(
        width:  deviceWidth * 0.75,
        height: deviceHeight - padding*2,
        child:
        SingleChildScrollView(
          child:
          Table(
              border: TableBorder.all(),
              columnWidths: <int, TableColumnWidth>{
                0: tableColumnWidth,
                1: tableColumnWidth,
                2: tableColumnWidth,
                3: tableColumnWidth,
                4: tableColumnWidth,
                5: tableColumnWidth,
                6: tableColumnWidth,
                7: tableColumnWidth,
              },
              defaultVerticalAlignment: TableCellVerticalAlignment.middle,
              children: rows
          ),
        ),
      );
      Widget rightCol = SizedBox( // Right column
          width:  deviceWidth * 0.25,
          height: deviceHeight-padding*2,

          child: Center(
            child: Container( color: Colors.grey, width:  deviceWidth * 0.25, child:
            SingleChildScrollView(
              child: Column(
                    children: getDebugRightData( context, constraints ) // children
                ),
            )
            ),
          )
      );

      Column ch = Column(
          children: [
            Column(
                children: [
                  //SizedBox( height: padding ),
                  Row(
                    children: [
                      leftCol,
                      rightCol,
                    ],
                  ),
                ]
            )
          ]
      );

      return ch;
    },
  );
}
