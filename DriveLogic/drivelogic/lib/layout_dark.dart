import 'package:drivelogic/app_ui_supp.dart';
import 'package:drivelogic/dlodometer.dart';
import 'package:flutter/material.dart';
import 'app_data.dart';
import 'app_ui.dart';
import 'settings_main.dart';
import 'settings_led2.dart';
import 'dlgauge.dart';
import 'dlarc.dart';
import 'dlmaskedimage.dart';
import 'source_editor2.dart';
import 'datapoint.dart';
import 'dart:io';
import 'dart:math';


Widget buildDarkLayout(BuildContext context, VoidCallback settingsClosed) {
  // debugPaintSizeEnabled = true;
  return GestureDetector(
      onDoubleTap: () {
        //DLAppData.appData.drawerKey.currentState?.openDrawer();
        Navigator.push(context, MaterialPageRoute(builder: (context) {
          return SettingsMain(onClose: settingsClosed);
        }));
      },
      child: buildDarkLayout2(context));
}

Widget buildDarkLayout2(BuildContext context) {

  return LayoutBuilder(
      builder: (context, constraints) {

        double topPadding = MediaQuery.of(context).viewPadding.top;
        double displayWidth = constraints.maxWidth;
        double displayHeight = constraints.maxHeight - topPadding;

        String bg = DLAppData.appData.layoutBackgrounds[ 'Dark' ]?? '';
        DecorationImage img = bg.isEmpty ?
          const DecorationImage(
            image: AssetImage("images/LayoutDarkBG.jpg"), // 2880 x 1080
            fit: BoxFit.cover,
          )
            :
          DecorationImage(
            image: FileImage( File( bg ) ), // 2880 x 1080
            fit: BoxFit.cover,
          );

        return Column( children: [
          SizedBox( height: topPadding, width: displayWidth),

          Container(
            width: displayWidth,
            height: displayHeight,
            decoration: BoxDecoration(
              image: img,
            ),
            child: buildDarkLayout3(context, constraints) /* add child content here */,
          )]

        );


      }
  );

}

Rect calcPosition (double deviceWidth, double deviceHeight, double percentWidth, double percentHeight, double percentLeft, double percentTop) {
  return Rect.fromLTWH(
      deviceWidth * percentLeft,
      deviceHeight * percentTop,
      percentWidth == 0 ?  deviceHeight * percentHeight : deviceWidth * percentWidth,
      percentHeight == 0 ? deviceWidth * percentWidth : deviceHeight * percentHeight );
}

Widget myPositioned (double topGap, double deviceWidth, double deviceHeight, double percentWidth, double percentHeight, double percentLeft, double percentTop, Widget child ) {
  // double top=0, left=0, width =0, height = 0;
  Rect rect = calcPosition(deviceWidth, deviceHeight, percentWidth, percentHeight, percentLeft, percentTop);

  return  Positioned( left: rect.left, top: rect.top+topGap,
      child: SizedBox( // Center, large gauge
          width: rect.width,
          height: rect.height,
          child: child )
  );
}

Widget myPosition( double width, double height, double left, double top, Widget child ) {
  return  Positioned( left: left, top: top,
  child: SizedBox( // Center, large gauge
  width: width,
  height: height,
  child: child )
  );
}

Widget buildDarkLayout3(BuildContext context, BoxConstraints constraints) {
  if( DLAppData.appData.datapointsWereSetup == false ) {
    return const Center(child: CircularProgressIndicator());
  }
  // We have a choice: Make the Speedometer and RPM full-height and possibly shrink the center,
  // Or shrink them to 1/3 width and make everything even.
  // Let's go for full-height and shrinking the center if needed.
  double deviceHeight = constraints.maxHeight;
  double deviceWidth = constraints.maxWidth;
  double padding = MediaQuery.of(context).viewPadding.top;
  double displayHeight = deviceHeight - padding;
  double bigDialHeight = displayHeight;
  double myTopGap = 0;
  double scale = 1;
  double centerColumn = 0;
  double colGap = 2;
  double mutableGap = 2;
  double mutableHeight = 0;

  if( displayHeight  > deviceWidth / 3 ) { // When the 3-button navigation is gone
    myTopGap = (displayHeight - (deviceWidth / 3) ) / 2;
    scale = (deviceWidth / 3) / displayHeight;
    bigDialHeight = deviceWidth / 3;
  }
  centerColumn = deviceWidth - ( bigDialHeight * 2 );
  mutableHeight = min( bigDialHeight / 3 - mutableGap*2, centerColumn/3 - mutableGap*2);
  // Honest;y, not sure why the *2 improves centering in the line below
  double centerColumnXOffset = (centerColumn - ((mutableHeight + mutableGap *2 /*see note above*/  )*3 ));
  double centerColumnYOffset = (bigDialHeight - mutableHeight*3 ) / 2;
  double stripHeight = bigDialHeight / 11;
  double stripWidth = (stripHeight + 2) * 5;
  double stripLeft = deviceWidth / 2 - stripWidth / 2;
  mutableHeight -= stripHeight / 3;

  Datapoint datapointSpeed = DLAppData.appData.getDatapointByElement('Speed');
  String bg = DLAppData.appData.dataFormats['Speed'] == "MPH" ? 'images/LayoutDarkMPHNoTicks.png' : 'images/LayoutDarkKPHNoTicks.png';

  Widget speedWidget = DLGaugeWidget( bg, 'images/LayoutDarkOrangeNeedle.png',
      datapointSpeed.value, datapointSpeed.min, datapointSpeed.max,
      startAngle: 230, endAngle: 130,

      backgroundOpacity: 0.75,
      labelStep: 20, labelGap: 50 * scale, labelColor: Colors.orange,
      labelFont: 'Exo', labelFontSize: 22 * scale, labelDecimals: 0,

      tickColor: const Color.fromARGB(255, 0xfa, 0x5e, 0x25),
      tickFractions: 4,

      arcColor: const Color.fromARGB(255, 0xfa, 0x5e, 0x25),
      arcGap: 10,
      textColor: Colors.white,

      //bevelWidth: 20, bevelColor: Colors.grey, bevelType: DLBevelType.both, bevelLightSource: 45, bevelOuterStrokeColor: Colors.black
  );

  Datapoint datapointFuel = DLAppData.appData.getDatapointByElement('FUEL');
  Widget fuelWidget = DLMaskedImageWidget( 'images/LayoutDarkFuelGrey.png', 'images/LayoutDarkFuelGreen.png', '', '',
      datapointFuel.value, datapointFuel.min, datapointFuel.max,40 );

  Datapoint datapointRPM = DLAppData.appData.getDatapointByElement('RPM');
  Widget rpmWidget = DLGaugeWidget('images/LayoutDarkRPMNoTicks.png', 'images/LayoutDarkOrangeNeedle.png',
      datapointRPM.value, datapointRPM.min, datapointRPM.max,
      startAngle: 230, endAngle: 130,

      backgroundOpacity: 0.75,
      labelStep: 1000, labelGap: 50* scale, labelColor: Colors.orange,
      labelFont: 'Exo', labelFontSize: 22* scale, labelDecimals: 0, labelDivisor: 1000,

      tickColor: const Color.fromARGB(255, 0xfa, 0x5e, 0x25),
      tickFractions: 2,

      arcColor: const Color.fromARGB(255, 0xfa, 0x5e, 0x25),
      arcGap: 10,
      textColor: Colors.white,

      //bevelWidth: 20, bevelColor: Colors.grey, bevelType: DLBevelType.both, bevelLightSource: 45, bevelOuterStrokeColor: Colors.black
  );

  List<String> mutables = DLAppData.appData.getUnhiddenElements();
  List<Widget> grid = [];

  Widget ledStrip = dlLEDStrip( stripWidth, stripHeight );
  Widget ledWidget = GestureDetector(
    behavior: HitTestBehavior.translucent,
    onLongPress: () {
      Navigator.push(context, MaterialPageRoute(builder: (context) {
        return const SettingsLED2();
      }));
    },
    child: ledStrip,
  );

  Widget idiotLights = dlIdiotLights( context, stripHeight * 3.3, stripHeight, false);

  grid.add( myPosition( bigDialHeight, bigDialHeight, 0, myTopGap, speedWidget));
  grid.add( myPosition( bigDialHeight, bigDialHeight, deviceWidth - bigDialHeight, myTopGap , rpmWidget));
  grid.add( myPosition( bigDialHeight*.55, bigDialHeight*.16, bigDialHeight*.22, myTopGap + bigDialHeight*.8, fuelWidget));
  grid.add( myPosition( centerColumn, stripHeight, deviceWidth/2-centerColumn/2, 0,
      Row( mainAxisAlignment: MainAxisAlignment.center, children:[
        idiotLights, ledWidget,
      ]) )
  );

  // MG: Issue 0000841: Implement an Odometer widget
  Datapoint datapointOdometer = DLAppData.appData.getDatapointByElement('ODO');
  DLOdometerWidget odoWidget = DLOdometerWidget(value: datapointOdometer.value,
    padding: const EdgeInsets.all(1),
    bevelType: DLBevelType.inner, fontName: 'RobotoMono', bevelWidth: 2, );
  grid.add( myPosition( stripHeight*2.5, stripHeight, bigDialHeight*.50-(stripHeight*2.5/2), myTopGap + bigDialHeight*.65, odoWidget));

  int i=0;
  double yOffset = 0.0, xOffset = 0.0;
  // double wWidth =  mutable0Width;
  // double wHeight = mutable0Height;
  int row=0;
  int col=0;
  for (var label in mutables) {
    int corners = 0;

    col = i % 3;
    row = (i / 3).floor();

    xOffset = col * (mutableHeight+mutableGap) - mutableGap;
    yOffset = row * (mutableHeight+mutableGap);

    if( i == 0 ) { // Only the first gets the top left
      corners +=  dlArcCornerTopLeft;
    }
    if( i+1 == mutables.length) {
      corners =  dlArcCornerBottomRight;
    }
    if( ( i == 2 && mutables.length > 2 ) || (i == 1 && mutables.length == 2) || (i == 0 && mutables.length == 1)){
      corners =  dlArcCornerTopRight;
    }

    if( (mutables.length > 6 && i == 6)
        || ( (mutables.length >=4 && mutables.length <= 6) && i == 3)
        || ( mutables.length < 4  && i == 0)){
      corners =  dlArcCornerBottomLeft;
    }

    Datapoint datapointMutable = DLAppData.appData.getDatapointByLabel( label );
    Widget mutable = SizedBox( width: mutableHeight, height: mutableHeight,
        child: DLArcWidget(
            datapointMutable,
            const Color.fromARGB(128, 64, 64, 64),
            //decimals: datapointMutable.decimals,
            colorBG: const Color.fromARGB(128, 64, 64, 64),
            startlabelText: datapointMutable.startCaption,
            endlabelText: datapointMutable.endCaption,
            nameText: datapointMutable.label,
            cornerRadius: corners )
    );
    Widget widget = GestureDetector(
        onLongPress: () {
          //dlDatapointSelector(context, index);
          Navigator.push(context, MaterialPageRoute(builder: (context) {
            return SourceEditor2('${DLAppData.appData.visualLayout}.$label');
          }));
        },
        child: mutable );
    grid.add(
      myPosition( mutableHeight, mutableHeight,
          bigDialHeight +  xOffset  + centerColumnXOffset,
          myTopGap + stripHeight + yOffset + centerColumnYOffset,
          widget),
    );
    i++;
  }

  return
    Stack(
      children: grid,
    );
}
