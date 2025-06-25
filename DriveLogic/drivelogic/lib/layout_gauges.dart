import 'package:flutter/material.dart';
import 'app_data.dart';
import 'app_ui.dart';
import 'source_editor2.dart';
import 'settings_main.dart';
import 'dart:math';
import 'datapoint.dart';
import 'dart:io';

// Layout positions:
// Speed
// RPM
// Gauge1 - Gauge 9

Widget getChangeableWidgetByElement(BuildContext context, columnWidth,
    String element, int dlrgoOptions) {
  return GestureDetector(
    behavior: HitTestBehavior.translucent,
    onLongPress: () {
      Navigator.push(context, MaterialPageRoute(builder: (context) {
        return SourceEditor2('${DLAppData.appData.visualLayout}.$element');
      }));
    },
    child: dlGetRadialGaugeByElement(columnWidth, element, dlrgoOptions, imgGaugeNorm, imgGaugeRed),
  );
}

int longestBuild = 0;
Widget buildGaugesLayout(BuildContext context, VoidCallback settingsClosed) {
  Widget ret = GestureDetector(
      behavior: HitTestBehavior.translucent,
      onDoubleTap: () {
        //DLAppData.appData.drawerKey.currentState?.openDrawer();
        Navigator.push(context, MaterialPageRoute(builder: (context) {
          return SettingsMain(onClose: settingsClosed);
        }));
      },
      child: buildGaugesLayout2( context ));
  return ret;
}

Widget buildGaugeGrid(
    BuildContext context, double columnWidth, double gridHeight) {
  double cellWidth = gridHeight / 3;
  if (columnWidth / 3 < cellWidth) {
    cellWidth = columnWidth / 3;
  }
  double crossAxisSpacing =
      2; // Always.  This will reduce cell contents if needed.
  double mainAxisSpacing = 0;
  if (cellWidth * 3 < gridHeight) {
    mainAxisSpacing = (gridHeight - (cellWidth * 3)) / 3;
  }

  List<String> mutables = DLAppData.appData.getUnhiddenElements();
  if (mutables.length == 1) // full-sized gauge
  {
    return SizedBox(
      // Left most, large gauge
        width: columnWidth,
        height: gridHeight,
        child: getChangeableWidgetByElement(context, columnWidth, mutables[0], dlrgoRedCenter | dlrgoHideLabels )
    );

  } else if (mutables.length == 2) { // 2 x 1 grid


    double cellWidth = calc2CirclesInRect( columnWidth, gridHeight );
    Widget gaugeA = SizedBox( width: cellWidth, height: cellWidth, child: getChangeableWidgetByElement(
        context,  cellWidth, mutables[0], dlrgoRedCenter | dlrgoHideLabels));

    Widget gaugeB = Positioned(
      left: columnWidth-cellWidth,
      top: gridHeight-cellWidth,
      child:  SizedBox(  width: cellWidth, height: cellWidth, child: getChangeableWidgetByElement(
        context, cellWidth, mutables[1], dlrgoRedCenter | dlrgoHideLabels)
      ));

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        SizedBox(
            height: gridHeight,
            width: columnWidth,
            child: Stack( children: [ gaugeA, gaugeB ])
        ),
      ],
    );

  } else if (mutables.length == 3) { // 1x1 on top, 2x1 below

    double topRow = gridHeight / 3 * 2;
    double bottomRow = gridHeight / 3;

    double topDim = min( topRow, columnWidth );
    Widget gaugeA = SizedBox( width: topDim, height: topDim, child: getChangeableWidgetByElement(
        context,  topDim, mutables[0], dlrgoRedCenter ));

    double cellDim = min( bottomRow, columnWidth/2 );
    Widget row  = Row(
        children: [
         SizedBox(  width: columnWidth/2, height: bottomRow,
           child: getChangeableWidgetByElement( context, cellDim, mutables[1], dlrgoRedCenter | dlrgoHideLabels | dlrgoHalfPointer ), ),
          SizedBox(  width: columnWidth/2, height: bottomRow,
            child: getChangeableWidgetByElement( context, cellDim, mutables[2], dlrgoRedCenter | dlrgoHideLabels | dlrgoHalfPointer ), ),
        ]
    );

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        gaugeA, row
      ],
    );

  } else if (mutables.length == 4) { // 2 x 2 grid
    cellWidth = gridHeight / 2;
    if (columnWidth / 2 < cellWidth) {
      cellWidth = columnWidth / 2;
    }
    double crossAxisSpacing =
        2; // Always.  This will reduce cell contents if needed.
    double mainAxisSpacing = 0;
    if (cellWidth * 2 < gridHeight) {
      mainAxisSpacing = (gridHeight - (cellWidth * 2)) / 2;
    }

    return SizedBox(
      width: columnWidth,
      height: gridHeight,
      child: GridView.builder(
        padding: const EdgeInsets.fromLTRB(1, 1, 1, 1),
        //EdgeInsets.zero,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisExtent: cellWidth - 0.5,
          //childAspectRatio: 1.0,
          crossAxisSpacing: crossAxisSpacing,
          mainAxisSpacing: mainAxisSpacing,
          //20.0,
        ),
        itemBuilder: (context, index) {
          return Center(
            child: SizedBox(
              width: cellWidth,
              height: cellWidth,
              child: getChangeableWidgetByElement(
                  context,
                  columnWidth / 2,
                  mutables[index],
                  dlrgoRedCenter |
                      dlrgoHideLabels |  dlrgoHalfPointer ), // These keys must match into layoutElements
            ),
          );
        },
        itemCount: 4,
      ),
    );
  } else if (mutables.length == 5) { // 2 x 1 on top of 3 x 1

    double cellHeightTop = gridHeight / 3 * 2;
    double cellHeightBottom  = gridHeight / 3;

    cellWidth = gridHeight / 2;
    if (columnWidth / 2 < cellWidth) {
      cellWidth = columnWidth / 2;
    }
    if (cellWidth * 2 < gridHeight) {
      mainAxisSpacing = (gridHeight - (cellWidth * 2)) / 2;
    }
    // The 2x1 top row
    Widget row1 = SizedBox(height: cellHeightTop, width: columnWidth, child: Row(
        children: [
          SizedBox( width: columnWidth / 2, child: getChangeableWidgetByElement( context, columnWidth / 2,
          mutables[0],
          dlrgoRedCenter | dlrgoHideLabels | dlrgoHalfPointer)
        ),
          SizedBox( width: columnWidth / 2, child: getChangeableWidgetByElement( context, columnWidth / 2,
            mutables[1],
            dlrgoRedCenter | dlrgoHideLabels | dlrgoHalfPointer))
        ]
      ),
    );
    // The 3x1 bottom row
    Widget row2 = SizedBox( height: cellHeightBottom, width: columnWidth, child:
    Row( children: [
      SizedBox( width: columnWidth / 3, child: getChangeableWidgetByElement( context, columnWidth / 3,
          mutables[2],
          dlrgoRedCenter | dlrgoHideLabels | dlrgoQuarterPointer )),
      SizedBox( width: columnWidth / 3, child: getChangeableWidgetByElement( context, columnWidth / 3,
          mutables[3],
          dlrgoRedCenter | dlrgoHideLabels | dlrgoQuarterPointer)),
      SizedBox( width: columnWidth / 3, child: getChangeableWidgetByElement( context, columnWidth / 3,
          mutables[4],
          dlrgoRedCenter | dlrgoHideLabels | dlrgoQuarterPointer))
    ]
    ) );

    return SizedBox(
      width: columnWidth,
      height: gridHeight,
      child: Column( children: [row1,row2]),
    );
  } else { // Original 9x9 grid
      return SizedBox(
        width: columnWidth,
        height: gridHeight,
        child: GridView.builder(
          padding: const EdgeInsets.fromLTRB(1, 1, 1, 1),
          //EdgeInsets.zero,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisExtent: cellWidth - 0.5,
            //childAspectRatio: 1.0,
            crossAxisSpacing: crossAxisSpacing,
            mainAxisSpacing: mainAxisSpacing,
            //20.0,
          ),
          itemBuilder: (context, index) {
            return Center(
              child: SizedBox(
                width: cellWidth,
                height: cellWidth,
                child: getChangeableWidgetByElement(
                    context,
                    columnWidth / 3,
                    "Mutable.Gauge${index + 1}",
                    dlrgoRedCenter |
                    dlrgoHideLabels | dlrgoQuarterPointer ), // These keys must match into layoutElements
              ),
            );
          },
          itemCount: 9,
        ),
      );
    }
}
Widget buildGaugesLayout2( BuildContext context ) {
  final EdgeInsets padding = MediaQuery.of(context).padding;
  final double displayWidth = MediaQuery.of(context).size.width;
  double displayHeight = MediaQuery.of(context).size.height - padding.top - padding.bottom;

  String bg = DLAppData.appData.layoutBackgrounds[ 'Gauges' ]?? '';
  DecorationImage img = bg.isEmpty ?
    const DecorationImage(
      image: AssetImage("images/carbonfiber2.jpg"),
      fit: BoxFit.cover,
    )
        :
    DecorationImage(
      image: FileImage( File( bg ) ), // 2880 x 1080
      fit: BoxFit.cover,
    );

  return Column( children: [
    SizedBox( height: padding.top, width: displayWidth),


    Container( width: displayWidth, height: displayHeight,
      decoration: BoxDecoration(
        image: img,
      ),
        child: Opacity(
          opacity: 0.9, child: buildGaugesLayout3( ) /* add child content here */,
    )
  ),

  ]);
}

Widget buildGaugesLayout3() {
  return LayoutBuilder(
    builder: (context, constraints) {
      double deviceHeight = constraints.maxHeight;
      double deviceWidth = constraints.maxWidth;
      double displayHeight = deviceHeight;
      double columnWidth = (deviceWidth / 3) - 1;
      double lightHeight = deviceHeight / 16;
      double gridHeight = displayHeight - lightHeight;

      Datapoint ltDatapoint = DLAppData.appData.getDatapointByLabel("TURNL");
      Datapoint rtDatapoint = DLAppData.appData.getDatapointByLabel("TURNR");
      Datapoint hbDatapoint = DLAppData.appData.getDatapointByLabel("LIGHTSHI");
      //Datapoint tpDatapoint = DLAppData.appData.getDatapointByLabel( "TIRE" );
      Datapoint siDatapoint =
          DLAppData.appData.getDatapointByLabel("UserOnOff.RPM.ShiftIndicator");

      Widget speedWidget = GestureDetector(
          behavior: HitTestBehavior.translucent,
          onLongPress: () {
            dlDialogBuilder(context, DLDialogBuilderType.information,
                "Speed can not be altered");
          }, // Image tapped
          child: dlGetRadialGaugeByElement(columnWidth, 'Speed', 0, imgGaugeNorm, imgGaugeRed));
      Widget speedStack = Stack(
        children: [
          speedWidget,
          dlImageToggleOnOff(context, siDatapoint, lightHeight * 2,
              'images/YellowIndicatorOn.png', 'images/YellowIndicatorOff.png'),
        ],
      );

      Widget rpmWidget =
          dlGetRadialGaugeByElement(columnWidth, 'RPM', dlrgoRedCenter + dlrgoShrinkCenter, imgGaugeNorm, imgGaugeRed);
      Widget rpmStack = Stack(
        clipBehavior: Clip.none,
        children: <Widget>[
          rpmWidget,
          Positioned.fill(
              child: Align(
                alignment: Alignment.topRight,
          child: dlImageToggleOnOff(context, siDatapoint, lightHeight * 2,
              'images/YellowIndicatorOn.png', 'images/YellowIndicatorOff.png'),
              ),
          )
        ],
      );

      Widget idiotLights = SizedBox(
          // idiot lights
          width: columnWidth,
          height: lightHeight,
          child: Row(children: [
            dlImageToggle(ltDatapoint, lightHeight, 'images/IL_LeftTurnOn.png',
                'images/IL_LeftTurnOff.png'),
            const SizedBox(width: 5),
            dlImageToggle(rtDatapoint, lightHeight, 'images/IL_RightTurnOn.png',
                'images/IL_RightTurnOff.png'),
            const SizedBox(width: 5),
            dlImageToggle(hbDatapoint, lightHeight, 'images/IL_HighBeamOn.png',
                'images/IL_HighBeamOff.png'),
            const SizedBox(width: 5),
//                dlImageToggle( tpDatapoint, lightHeight, 'images/IL_TiresOn.png', 'images/IL_TiresOff.png' ),
//                const SizedBox( width: 5),
            dlLEDStrip(columnWidth - (lightHeight + 5) * 4, lightHeight),
          ]));

      Widget grid = buildGaugeGrid(context, columnWidth, gridHeight);

      Widget row = Row(
        children: [
          SizedBox(
              // Left most, large gauge
              width: columnWidth,
              height: displayHeight,
              child: speedStack),
          SizedBox(
              // Center column
              width: columnWidth,
              height: displayHeight,
              child: Center(
                child: Column(children: [
                  idiotLights,
                  grid,
                ] // children
                    ),
              )),
          SizedBox(
            width: columnWidth,
            height: displayHeight,
            child: rpmStack,
          )
        ],
      );

      return row;
    },
  );
}
