import 'package:flutter/material.dart';
import 'app_data.dart';
import 'app_ui.dart';
import 'source_editor2.dart';
import 'settings_main.dart';
import 'google_map_embed.dart';
import 'datapoint.dart';

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
Widget map = const GoogleMapEmbed();
int longestBuild = 0;
Widget buildEmbeddedLayout(BuildContext context, VoidCallback settingsClosed) {
  Widget ret = GestureDetector(
      behavior: HitTestBehavior.translucent,
      onDoubleTap: () {
        //DLAppData.appData.drawerKey.currentState?.openDrawer();
        Navigator.push(context, MaterialPageRoute(builder: (context) {
          return SettingsMain(onClose: settingsClosed);
        }));
      },
      child: buildEmbeddedLayout2());
  return ret;
}

Widget buildEmbeddedLayout2() {
  return LayoutBuilder(
    builder: (context, constraints) {
      double deviceHeight = constraints.maxHeight;
      double deviceWidth = constraints.maxWidth;
      double padding = MediaQuery.of(context).viewPadding.top;
      double displayHeight = deviceHeight - padding;
      double columnWidth = (deviceWidth / 3) - 1;
      double lightHeight = deviceHeight / 16;

      Datapoint ltDatapoint = DLAppData.appData.getDatapointByLabel("TURNL");
      Datapoint rtDatapoint = DLAppData.appData.getDatapointByLabel("TURNR");
      Datapoint hbDatapoint = DLAppData.appData.getDatapointByLabel("LIGHTSHI");

      Datapoint siDatapoint =
      DLAppData.appData.getDatapointByLabel("UserOnOff.RPM.ShiftIndicator");


      Widget speedWidget = GestureDetector(
          behavior: HitTestBehavior.translucent,
          onLongPress: () {
            dlDialogBuilder(context, DLDialogBuilderType.information,
                "Speed can not be altered");
          }, // Image tapped
          child: dlGetRadialGaugeByElement(columnWidth, 'Speed', 0, imgGaugeNorm, imgGaugeRed));

      Widget rpmWidget = dlGetRadialGaugeByElement(columnWidth, 'RPM', dlrgoRedCenter + dlrgoShrinkCenter, imgGaugeNorm, imgGaugeRed);

      Widget rpmStack = Stack(
        clipBehavior: Clip.none,
        children: <Widget>[
          rpmWidget,
          dlImageToggleOnOff(context, siDatapoint, lightHeight * 2,
              'images/YellowIndicatorOn.png', 'images/YellowIndicatorOff.png'),
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

          Widget row = Row(
        children: [
          SizedBox(
            // Left most, large gauge
              width: columnWidth,
              height: displayHeight,
              child: speedWidget),
          SizedBox(
            // Center column
              width: columnWidth,
              height: displayHeight,
              child: Center(
                child: Column(children: [
                  idiotLights,
                  map,
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

      return Column(children: [
        SizedBox(
          width: deviceWidth,
          height: padding,
        ),
        row
      ]);
    },
  );
}

/*
Widget buildViewGauge( BuildContext context) {
  return buildPanel();

  List<Widget> containers = <Widget>[];
  MediaQueryData queryData = MediaQuery.of(context);
  int across = (queryData.size.width / queryData.size.height).round();
  double maxDim = 0;
  if( across < 1 ) {
    across = 1;
  }
  maxDim = (( queryData.size.width > queryData.size.height ) ? queryData.size.height : queryData.size.width)-4;

  for (DLAttributeListener attListener in DLAppData.appData.attributeListeners.values) {
    attListener.attributeNotifier = ValueNotifier<DLAttribute>( DLAttribute( attListener.attribute.name, attListener.attribute.curValue, attListener.attribute.minValue, attListener.attribute.maxValue) );
    Widget cell = Container(
      width: maxDim,
      height: maxDim,
      alignment: Alignment.centerLeft,
      child: Column(
        children: <Widget>[
          AspectRatio(
              aspectRatio: 1,
              child:
              ValueListenableBuilder(
                  valueListenable: attListener.attributeNotifier!,
                  builder: (_, DLAttribute value, __) =>
                      DLRadialGauge(
                          value.name, value.curValue, value.minValue, value.maxValue)
              )
          ),
        ],
      ),
    );

    containers.add( cell );
  }
  Container(
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage("images/carbonfiber.jpg"),
          fit: BoxFit.cover,
        ),
      ),
      child:
      GridView.count(
          crossAxisCount: across,
          // Generate 100 widgets that display their index in the List.
          children: <Widget>[
            ...containers,
          ]
      )
  );

  return GridView.count(
      crossAxisCount: across,
      // Generate 100 widgets that display their index in the List.
      children: <Widget>[
        ...containers,
      ]
  );
}
*/
