import 'package:drivelogic/app_data.dart';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';
import 'source_editor2.dart';
import 'dart:math';
import 'datapoint.dart';
import 'dart:ui';
import 'settings_led2.dart';

double logWidth = 0;
double logHeight = 0;
double phyWidth = 0;
double phyHeight = 0;
double devicePixelRatio = 0;
double logPaddingTop = 0;
double logPaddingBottom = 0;

const double referenceSize = 300.0;
const double bodyFontFactor = 1.25;
double largerBodyFontSize = 16;
double smallBodyFontSize = 12;
double sysFontSizeDigitalGauge = 16;
double defaultFontSize = 0;


// Predefine objects for centralizing, performance, memory saving
const AssetImage imgGaugeRed = AssetImage('images/tpgauge2.png');
const AssetImage imgGaugeNorm = AssetImage('images/tpgauge1.png');

const AssetImage imgOffroadNormKPH = AssetImage('images/OffroadDialKPH.png');
const AssetImage imgOffroadNormMPH = AssetImage('images/OffroadDialMPH.png');
const AssetImage imgOffroadNormRPM = AssetImage('images/OffroadDialRPM.png');
final Image imgOffroadTop = Image.asset('images/OffRoadDashMaskRectangularTop.png', fit: BoxFit.cover,);
final Image imgOffroadBottom = Image.asset('images/OffRoadDashMaskRectangularBottom.png', fit: BoxFit.cover,);

final Image imgILLeftTurnOn  = Image.asset( 'images/IL_LeftTurnOn.png', fit: BoxFit.cover, );
final Image imgILLeftTurnOff  = Image.asset( 'images/IL_LeftTurnOff.png', fit: BoxFit.cover );
final Image imgILRightTurnOn  = Image.asset( 'images/IL_RightTurnOn.png', fit: BoxFit.cover );
final Image imgILRightTurnOff  = Image.asset( 'images/IL_RightTurnOff.png', fit: BoxFit.cover );
final Image imgILHighBeamOn  = Image.asset( 'images/IL_HighBeamOn.png', fit: BoxFit.cover );
final Image imgILHighBeamOff  = Image.asset( 'images/IL_HighBeamOff.png', fit: BoxFit.cover );
final Image imgILTiresOn  = Image.asset( 'images/IL_TiresOn.png', fit: BoxFit.cover );
final Image imgILTiresOff  = Image.asset( 'images/IL_TiresOff.png', fit: BoxFit.cover );

final Image imgLEDOff = Image.asset( 'images/LEDOff.png', fit: BoxFit.cover );
final Image imgRedLED = Image.asset( 'images/LEDRed.png', fit: BoxFit.cover );
final Image imgGreenLED = Image.asset( 'images/LEDGreen.png', fit: BoxFit.cover );
final Image imgBlueLED = Image.asset( 'images/LEDBlue.png', fit: BoxFit.cover );
// Note: app_datadart has kludge: Kludge: Force outdated Yellow color to red:
final Image imgYellowLED = Image.asset( 'images/LEDYellow.png', fit: BoxFit.cover );
final Image imgOrangeLED = Image.asset( 'images/LEDOrange.png', fit: BoxFit.cover );
final Image imgVioletLED = Image.asset( 'images/LEDViolet.png', fit: BoxFit.cover );

const AssetImage imgDarkMPH = AssetImage( 'images/LayoutDarkMPH.png');
const AssetImage imgDarkRPM = AssetImage( 'images/LayoutDarkRPM.png');


enum DLImageArrayRounding { floor, round, ceiling, firstFloor } // firstFloor = round all but first, which is floor

List<bool> imgsCurvedLeftFuelLoaded = [false,false,false,false,false,false,false,false];

// Used by ThemeData and other location
const Color sysBackgroundColor = Colors.black;
const Color sysTextColor = Colors.white;
const Color sysTextErrorColor = Colors.red;
const Color sysDropdownColor = Colors.grey;
const Color sysScrollThumbColor = Colors.grey;
const Color sysColorGaugeAnnotation =Colors.white; // Color.fromARGB(0xFF, 0xFF, 0xFF, 0xFF);
const sysTextFieldBorderColor = Colors.white;

const Color sysDialogBackgroundColor = Colors.white;
const Color sysDialogTextColor = Colors.black;

const SweepGradient sgGaugeSweepGradientRed = SweepGradient( colors: <Color>[ Color(0xFFAA0000),  Color(0xFFFF0000)], stops: <double>[0.25, 0.75]);
const SweepGradient sgGaugeSweepGradientNorm = SweepGradient( colors: <Color>[ Color(0xFF00AA00),  Color(0xFF00FF00)], stops: <double>[0.25, 0.75]);

enum DLDialogBuilderType { error, warning, information, confirmation }


double dlCalculateMaxFontSize({
  required String text,
  required String fontFamily,
  required FontWeight fontWeight,
  required double width,
  required double height,
  double padding = 0.0,
})  {
  // Define the bounds accounting for padding
  final double maxWidth = width - (2 * padding);
  final double maxHeight = height - (2 * padding);

  // Define binary search range for font size
  double low = 1.0;
  double high = 200.0; // Start with a high limit
  double bestFit = low;

  // Text style generator
  TextStyle generateStyle(double fontSize) {
    return TextStyle(
      fontSize: fontSize,
      fontFamily: fontFamily,
      fontWeight: fontWeight,
    );
  }

  // Check if a font size fits within the constraints
  bool fits(double fontSize) {
    final TextPainter tp = TextPainter(
      text: TextSpan(
        text: text,
        style: generateStyle(fontSize),
      ),
      maxLines: 1,
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.left,
    )..layout(maxWidth: maxWidth);

    return tp.width < maxWidth && tp.height < maxHeight;
  }

  // Binary search to find the largest fitting font size
  while (low <= high) {
    final mid = (low + high) / 2;
    if (fits(mid)) {
      bestFit = mid;
      low = mid + 0.1; // try a bit larger
    } else {
      high = mid - 0.1; // try a bit smaller
    }
  }
  return bestFit;
}

void dlScreenInit(BuildContext context) {
  devicePixelRatio = MediaQuery.of(context).devicePixelRatio;
  Size logSize = MediaQuery.sizeOf(context);
  EdgeInsets logPadding = MediaQuery.of(context).viewPadding;
  logPaddingTop =   logPadding.top;
  logPaddingBottom = logPadding.bottom;
  logWidth = logSize.width;
  logHeight = logSize.height;
  phyHeight = logHeight * devicePixelRatio;
  phyWidth = logWidth * devicePixelRatio;

  defaultFontSize = 24;
}

Future<void> dlDialogBuilder(
    BuildContext context, DLDialogBuilderType type, String content) {
  List<Widget> actions = [];
  actions.add(TextButton(
    style: TextButton.styleFrom(
      textStyle: Theme.of(context).textTheme.labelLarge,
    ),
    child: const Text('OK'),
    onPressed: () {
      Navigator.of(context).pop();
    },
  ));

  List<Widget> titleRow = [];
  if (type == DLDialogBuilderType.error) {
    titleRow = [
      const Icon(
        Icons.error,
        size: 36.0,
      ),
      const Text('Error')
    ];
  } else if (type == DLDialogBuilderType.warning) {
    titleRow = [
      const Icon(
        Icons.warning,
        size: 36.0,
      ),
      const Text('Warning')
    ];
  } else if (type == DLDialogBuilderType.information) {
    titleRow = [
      const Icon(
        Icons.info,
        size: 36.0,
      ),
      const Text('Information')
    ];
  } else if (type == DLDialogBuilderType.confirmation) {
    titleRow = [
      const Icon(
        Icons.question_mark,
        size: 36.0,
      ),
      const Text('Confirmation')
    ];
  }

  return showDialog<void>(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        backgroundColor: sysDialogBackgroundColor,
        title: Row(
          children: titleRow,
        ),
        content: Text(content, style: const TextStyle( color: sysDialogTextColor  )),
        actions: actions,
      );
    },
  );
}

Widget dlSettingsButton(BuildContext context, String label, String image,
    double btnWidth, void Function(BuildContext, String) callback) {
  return Column(children: [
    Text(label),
    GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () {
        callback(context, label);
      }, // Image tapped
      child: Image.asset(
        image,
        fit: BoxFit.cover, // Fixes border issues
        width: btnWidth,
        height: btnWidth,
      ),
    )
  ]
  );
}

Widget dlImageToggle(
    Datapoint datapoint, double width, String onImage, String offImage) {
  return Image.asset(
    datapoint.isWarning() ? onImage : offImage,
    fit: BoxFit.cover, // Fixes border issues
    width: width,
    height: width,
  );
}

Widget dlImageToggleOnOff(BuildContext context, Datapoint datapoint,
    double width, String onImage, String offImage) {
  return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onLongPress: () {
        Navigator.push(context, MaterialPageRoute(builder: (context) {
          return SourceEditor2(datapoint.source);
        }));
      },
      child: Image.asset(
        datapoint.isWarning() ? onImage : offImage,
        fit: BoxFit.cover, // Fixes border issues
        width: width,
        height: width,
      ));
}

TableRow dlGetDebugTableRow(Datapoint datapoint, double tableWidth) {
  double columnWidth = tableWidth / 8;

  return TableRow(
    children: <Widget>[
      SizedBox(
          height: 32,
          width: columnWidth,
          child: Text(datapoint.label )),
      SizedBox(
          height: 32,
          width: columnWidth,
          child: Text(datapoint.valueStr)),
      SizedBox(
          height: 32,
          width: columnWidth,
          child: Text(datapoint.value.toString())),
      SizedBox(
          height: 32,
          width: columnWidth,
          child: Text(datapoint.min.toString())),
      SizedBox(
          height: 32,
          width: columnWidth,
          child: Text(datapoint.max.toString())),
      SizedBox(
          height: 32,
          width: columnWidth,
          child: Text(datapoint.warnLow.toString())),
      SizedBox(
          height: 32,
          width: columnWidth,
          child: Text(datapoint.warnHigh.toString() )),
    ],
  );
}

const int dlrgoRedRing = 0x0001;
const int dlrgoRedCenter = 0x0002;
const int dlrgoHideLabels = 0x0004;
const int dlrgoShrinkCenter = 0x0008;
const int dlrgoHalfPointer = 0x00010;
const int dlrgoQuarterPointer = 0x00020;
const int dlrgoNoText = 0x00040;
const int dlrgoUseNeedle = 0x00080;

enum DLDigitalGaugeCorner { none, all, tl, tr, bl, br }

Widget dlDigitalGauge(BuildContext context, Datapoint datapoint,
    double columnWidth, String element, int index, DLDigitalGaugeCorner corner) {

  BoxDecoration deco = BoxDecoration(
      border: Border.all(color: Colors.blueAccent),
      borderRadius:  BorderRadius.only(
          topLeft: corner == DLDigitalGaugeCorner.all || corner == DLDigitalGaugeCorner.tl ? const Radius.circular(20) : Radius.zero,
          topRight:  corner == DLDigitalGaugeCorner.all || corner == DLDigitalGaugeCorner.tr ? const Radius.circular(20) : Radius.zero,
          bottomLeft:  corner == DLDigitalGaugeCorner.all || corner == DLDigitalGaugeCorner.bl ? const Radius.circular(20) : Radius.zero,
          bottomRight: corner == DLDigitalGaugeCorner.all || corner == DLDigitalGaugeCorner.br ? const Radius.circular(20) : Radius.zero
      )
    );


  double fontSize = sysFontSizeDigitalGauge;

  List<Widget> chiln = [];

  if( datapoint.isSensor() && datapoint.min == datapoint.max )
  {
    String name = datapoint.labelNoOverride.replaceAll( 'SEN', 'Sensor ');
    chiln.add( Text(
        "$name is not setup properly.",
        textAlign: TextAlign.center, // Center the text inside the Text widget
        softWrap: true,              // Allow wrapping (default is true anyway)
        style: const TextStyle(fontSize: 12),
      )
    );
  }
  else
  {
    chiln.add( Text(datapoint.valueStr,
        textAlign: TextAlign.right,
        style: TextStyle(
          fontSize: fontSize,
          fontFamily: "DateStamp",
          color: datapoint.isWarning() ? Colors.red : Colors.green,
          //fontSize: fontSizeAnnotation,
          //fontWeight: FontWeight.bold)),
        )) );
    chiln.add( Text(
      datapoint.label,
      style: TextStyle(
      fontSize: sysFontSizeDigitalGauge,
      color:
      sysColorGaugeAnnotation,
      //fontSize: fontSizeAnnotation,
      //fontWeight: FontWeight.bold)),
      )) );

  }

  return GestureDetector(
      onLongPress: () {
        //dlDatapointSelector(context, index);
        Navigator.push(context, MaterialPageRoute(builder: (context) {
          return SourceEditor2('${DLAppData.appData.visualLayout}.$element');
        }));
      },


  child: Container(
          width: columnWidth,
          height: columnWidth,
          decoration: deco,
          child:   Column(
            mainAxisAlignment: MainAxisAlignment.center,

            children: chiln,
          )
      ),
  );
}

Widget dlGetRadialGaugeByElement(
    double columnWidth, String element, int dlrgoOptions,  AssetImage imgGaugeNormal, AssetImage imgGaugeRed) {

  Datapoint datapoint = DLAppData.appData.getDatapointByElement(element);
  Widget ret;
  if (datapoint.label.isEmpty) {
    ret = const Text("Loading" );
  } else if( datapoint.label == 'HIDE' ) {
    ret = SizedBox( width: columnWidth, height: columnWidth );
  }
  else {
    if (element == 'Speed') {
      // The speed gauge is unique, with an inner element
      Datapoint datapoint2 = DLAppData.appData.getDatapointByLabel('FUEL');
      ret = dlRadialGauge(
          datapoint, dlrgoOptions, datapoint2, dlrgoRedRing, columnWidth,imgGaugeNormal, imgGaugeRed);
    } else if (element == 'RPM') {
      ret = dlRadialGauge(datapoint, dlrgoOptions, null, 0, columnWidth,imgGaugeNormal, imgGaugeRed);
    } else {
      ret = dlRadialGauge(datapoint, dlrgoOptions, null, 0, columnWidth,imgGaugeNormal, imgGaugeRed);
    }
  }
  return ret;
}

Widget dlIdiotLights( BuildContext context, double width, double height, bool withLEDs )
{
  Datapoint ltDatapoint = DLAppData.appData.getDatapointByLabel("TURNL");
  Datapoint rtDatapoint = DLAppData.appData.getDatapointByLabel("TURNR");
  Datapoint hbDatapoint = DLAppData.appData.getDatapointByLabel("LIGHTSHI");

  Widget? ledStrip;
  Widget? ledWidget;

  if( withLEDs ) {
    ledStrip = dlLEDStrip(height * 5, height);
    ledWidget = GestureDetector(
      behavior: HitTestBehavior.translucent,
      onLongPress: () {
        Navigator.push(context, MaterialPageRoute(builder: (context) {
          return const SettingsLED2();
        }));
      },
      child: ledStrip,
    );
  }

  Widget idiotLights = SizedBox(
    // idiot lights
      width: width,
      height: height,
      child: Row(children: [
        dlImageToggle(ltDatapoint, height, 'images/IL_LeftTurnOn.png',
            'images/IL_LeftTurnOff.png'),
        const SizedBox(width: 5),
        dlImageToggle(rtDatapoint, height, 'images/IL_RightTurnOn.png',
            'images/IL_RightTurnOff.png'),
        const SizedBox(width: 5),
        dlImageToggle(hbDatapoint, height, 'images/IL_HighBeamOn.png',
            'images/IL_HighBeamOff.png'),
        if( withLEDs ) const SizedBox(width: 5),
        if( withLEDs && ledStrip != null )
          ledStrip,
      ]));
  return idiotLights;
}

Widget dlLEDStrip( double width, double height )
{
  List<Widget> leds=[];
  if( height * 5 > width ) {
    height = width / 5;
  }
  double gap = (width - (5 * height) ) / 4;
  if( gap < 0 ) { gap = 0;
  }

  int index = 0;
  DLAppData.appData.ledStripSources.forEach((String key, String data ) {
    if( key.indexOf( '${DLAppData.appData.visualLayout}.' ) == 0 ) {
      List<String> parts = data.split(','); // Label, warnLow, warnHigh
      if (DLAppData.appData.allDatapoints.containsKey(parts[0].toLowerCase())) {
        Datapoint dp = DLAppData.appData.allDatapoints[ parts[0].toLowerCase() ]!;
        double value = dp.value;
        double warnLo = parts[1].isEmpty ? dp.min : double.parse(parts[1]); // Treat blanks as no warning
        double warnHi = parts[2].isEmpty ? dp.max : double.parse(parts[2]);
        String color = parts.length > 3 ? parts[3] : 'red';
        bool isOn = (warnLo < warnHi && (value > warnHi || value < warnLo) );
        // Note: app_datadart has kludge: Kludge: Force outdated Yellow color to red:
        leds.add(  SizedBox( height: height-1, width: height-1, child:  isOn ?
            color == 'Violet'? imgVioletLED : ( color == 'Green' ? imgGreenLED : (color=='Blue'? imgBlueLED : (color=='Orange'? imgOrangeLED : imgRedLED)) )
            : imgLEDOff) );
      } else {
        leds.add( SizedBox( height: height-1, width: height-1, child: imgLEDOff) );
      }
      if( ++index < 5 ) {
        leds.add(SizedBox(width: gap));
      }
    }
  });
  while( index < 5 )
  {
    leds.add(  SizedBox( height: height-1, width: height-1, child: imgLEDOff) );
    index++;
  }

  return SizedBox( height: height, width: width, child: Row( children: leds ) );
}

Widget dlRadialGauge( Datapoint main, int dlrgoMainOptions, Datapoint? lower, int dlrgoLowerOptions, double columnWidth, AssetImage imgGaugeNorm, AssetImage imgGaugeRed) {
  if (main.label.isEmpty || (lower != null && lower.label.isEmpty)) {
    return const Text("Err: dlRadialDualGauge1",
        style: TextStyle( backgroundColor: sysBackgroundColor, color: sysTextErrorColor ));
  }

  if( main.isSensor() && main.min == main.max )
    {
      String name = main.labelNoOverride.replaceAll( 'SEN', 'Sensor ');
      return Container(
        alignment: Alignment.center, // Center the child
        padding: const EdgeInsets.all(16),  // Optional padding
        child: Text(
          "$name is not setup properly.",
          textAlign: TextAlign.center, // Center the text inside the Text widget
          softWrap: true,              // Allow wrapping (default is true anyway)
          style: const TextStyle(fontSize: 12),
        ),
      );

    }

  double scale = columnWidth / referenceSize;

  double fontSizeAxisLabel =
      (main.max > 999 ? (main.max > 9999 ? 12 : 14) : 14) *
          scale; // smaller font if 4 digits
  double fontSizeAnnotation = 30 * scale;
  bool mainIsOn = ( (dlrgoMainOptions & dlrgoRedRing != 0 ) && main.isWarning());
  bool shrinkCenter = ( (dlrgoMainOptions & dlrgoShrinkCenter ) != 0);
  List<Widget> annotations = <Widget>[];
  double pointerWidth = 10;
  if( (dlrgoMainOptions & dlrgoHalfPointer) != 0 ) {
    pointerWidth = 5;
  } else if ( (dlrgoMainOptions & dlrgoQuarterPointer) != 0 ) {
    pointerWidth = 2.5;
  }

  if( shrinkCenter )
  {
    if( (dlrgoMainOptions & dlrgoNoText)  == 0 ) {
      annotations = [
        const SizedBox(height: 6),
        Text(main.valueStr,
            textAlign: TextAlign.right,
            style: TextStyle(
                fontFamily: "DateStamp",
                color: (dlrgoMainOptions & dlrgoRedCenter != 0 &&
                    main.isWarning())
                    ? Colors.white
                    : Colors.green,
                fontSize: fontSizeAnnotation,
                fontWeight: FontWeight.bold)),
        Text(
            main.label,
            style: TextStyle(
                color: sysColorGaugeAnnotation,
                fontSize: fontSizeAnnotation,
                height: 0.7,
                fontWeight: FontWeight.bold)),
      ];
    }
  }
  else {
    if( (dlrgoMainOptions & dlrgoNoText)  == 0 ) {
      annotations = [
      Text(main.valueStr,
          textAlign: TextAlign.right,
          style: TextStyle(
              fontFamily: "DateStamp",
              color: (dlrgoMainOptions & dlrgoRedCenter != 0 &&
                  main.isWarning())
                  ? Colors.white
                  : Colors.green,
              fontSize: fontSizeAnnotation,
              fontWeight: FontWeight.bold)),
      Text(
          main.label,
          style: TextStyle(
              color: sysColorGaugeAnnotation,
              fontSize: fontSizeAnnotation,
              fontWeight: FontWeight.bold)),
    ];
    }
  }

  //double rangeWidth = 15 * scale;
  //List<Color> mainRangeColors = ( (dlrgoMainOptions & dlrgoRedRing != 0 ) && main.isOn())
  //    ? clrsGaugeSweepRed
  //    : clrsGaugeSweepNorm;

  //double textPositionFactor = 1.0 * scale;

  GaugePointer? theGaugePointer;
  if(  (dlrgoMainOptions & dlrgoUseNeedle ) != 0 ) {
    theGaugePointer = NeedlePointer(
        value:  main.value,
        needleLength: 0.9,
        needleColor:
        (main.warnHigh != main.warnLow ) && (main.value < main.warnLow || main.value > main.warnHigh) ? Colors.red : Colors.green);

  } else {
    theGaugePointer = RangePointer(
        value: main.value,
        color: Colors.green,
        width: pointerWidth,
        cornerStyle: CornerStyle.endCurve,
        gradient: mainIsOn ? sgGaugeSweepGradientRed : sgGaugeSweepGradientNorm,
        enableAnimation: true,
        animationDuration: 100);
  }

  List<RadialAxis> axis = [
    RadialAxis(
        minimum: main.min.toDouble(),
        maximum: main.max.toDouble(),
        axisLineStyle: const AxisLineStyle(
          thickness: 0.0, // This is the line along which the range sweeps
          thicknessUnit: GaugeSizeUnit.factor, color: sysBackgroundColor,
        ),
        startAngle: 135,
        endAngle: 45, //Starting and ending angle of arc sweep

        offsetUnit: GaugeSizeUnit.factor,
        //tickOffset: 1, // This is the offset of the tick marks from the edge of the gauge
        labelOffset: 0.15,
        showLastLabel: true,
        showLabels: (dlrgoMainOptions & dlrgoHideLabels == 0),
        axisLabelStyle: // These are the numbers along the gauge, indicating the range and various midpoints
        GaugeTextStyle(
            color: sysColorGaugeAnnotation,
            fontSize: fontSizeAxisLabel),
        minorTickStyle: const MinorTickStyle(
          // These are the smaller tick marks
            color: Color(0xFF616161),
            thickness: 1.6,
            length: 0.058,
            lengthUnit: GaugeSizeUnit.factor),
        majorTickStyle: const MajorTickStyle(
          // These are the larger tick marks
            color: Color(0xFF949494),
            thickness: 2.3,
            length: 0.087,
            lengthUnit: GaugeSizeUnit.factor),
        radiusFactor: 0.88, // Radius of gauge in rectangle

/*            ranges: <GaugeRange>[
              GaugeRange(
                  startValue: 0,
                  endValue: maxVal * 0.90,
                  color: Colors.green,
                  startWidth: 10,
                  endWidth: 10),
              GaugeRange(
                  startValue: maxVal * 0.90,
                  endValue: maxVal.toDouble(),
                  color: Colors.red,
                  startWidth: 10,
                  endWidth: 10)
            ],
*/

        pointers: <GaugePointer>[
          theGaugePointer
        ],
        backgroundImage:
        (dlrgoMainOptions & dlrgoRedCenter != 0) && main.isWarning()
            ? imgGaugeRed
            : imgGaugeNorm,
        annotations: <GaugeAnnotation>[
          // This is the value and label texts
          GaugeAnnotation(
//                  axisValue: 50, positionFactor: 0.5,
              verticalAlignment: GaugeAlignment.center,
              horizontalAlignment: GaugeAlignment.center,


              widget: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: annotations)
        /*
              widget: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(main.valueStr,
                    textAlign: TextAlign.right,
                    style: TextStyle(
                        fontFamily: "DateStamp",
                        color: (dlrgoMainOptions & dlrgoRedCenter != 0 &&
                            main.isWarning())
                            ? Colors.white
                            : Colors.green,
                        fontSize: fontSizeAnnotation-4,
                        fontWeight: FontWeight.bold)),
                Text(
                    main.labelOverride.isEmpty
                        ? main.label
                        : main.labelOverride,
                    style: TextStyle(
                        color: sysColorGaugeAnnotation,
                        fontSize: fontSizeAnnotation,
                        fontWeight: FontWeight.bold)),
              ])
         */

          )
        ]
    ),
  ];

  if( lower != null )
  {
    bool lowerIsOn = ( (dlrgoLowerOptions & dlrgoRedRing != 0 ) && lower.isWarning());
    //List<Color> lowerRangeColors = ( (dlrgoLowerOptions & dlrgoRedRing != 0 ) && lower.isOn())
    //    ? clrsGaugeSweepRed
    //    : clrsGaugeSweepNorm;

    axis.add( RadialAxis(
      // This is the embedded gauge
        minimum: lower.min.toDouble(),
        maximum: lower.max.toDouble(),
        isInversed: true,
        axisLineStyle: const AxisLineStyle(
          thickness: 0.0, // This is the line along which the range sweeps
          thicknessUnit: GaugeSizeUnit.factor, color: sysBackgroundColor,
        ),
        startAngle: 50,
        endAngle: 130, //Starting end anding angle of arc sweep
        tickOffset:
        .92, // This is the offset of the tick marks from the edge of the gauge
        showTicks: false,
        showLabels: false,
        axisLabelStyle: // These are the numbers along the gauge, indicating the range and various midpoints
        GaugeTextStyle(
            color: sysColorGaugeAnnotation, fontSize: fontSizeAxisLabel),
        radiusFactor: 0.88, // Radius of gauge in rectangle
        pointers: <GaugePointer>[
          // this is the sweeping indicator
          RangePointer(
              value: lower.value,
              color: Colors.green,
              width: pointerWidth,
              cornerStyle: CornerStyle.endCurve,
              gradient: lowerIsOn ? sgGaugeSweepGradientRed : sgGaugeSweepGradientNorm,
          )
        ],
        annotations: <GaugeAnnotation>[
          GaugeAnnotation(
              horizontalAlignment: GaugeAlignment.center,
              widget: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(height: columnWidth / 16 * 11),
                    Text(
                        lower.label,
                        style: TextStyle(
                            color: sysColorGaugeAnnotation,
                            fontSize: fontSizeAnnotation / 2,
                            fontWeight: FontWeight.bold)),
                  ]))
        ]
    )

    );
  }

  return SfRadialGauge(axes: axis, );
}

double getTextHeight( BuildContext context )
{
  MediaQueryData media = MediaQuery.of(context);
  final tp = TextPainter(
      text: const TextSpan(text: 'Visual'),
      textDirection: TextDirection.ltr,
      textScaler: media.textScaler);
  tp.layout();
  return tp.height;
}

// Determine best diameter for 2 same-sized circles within a rectangle
double lastCalc2CirclesInRectWidth=0, lastCalc2CirclesInRectHeight=0, lastCalc2CirclesInRectCalced=0;
double calc2CirclesInRect( double width, double height) {
  // Cache results for best speed
  if( width == lastCalc2CirclesInRectWidth && height == lastCalc2CirclesInRectHeight ) {
    return lastCalc2CirclesInRectCalced;
  }
  double endDiameter = min(width, height);
  double startDiameter = endDiameter / 2;

  double ret = startDiameter;

  double xDiff = (startDiameter / 2) - (width - (startDiameter / 2));
  double yDiff = (startDiameter / 2) - (height - (startDiameter / 2));
  double distance = sqrt(xDiff * xDiff + yDiff * yDiff).abs();

  while (distance >= startDiameter) {
    ret = startDiameter;
    startDiameter = startDiameter + 1;
    xDiff = (startDiameter / 2) - (width - (startDiameter / 2));
    yDiff = (startDiameter / 2) - (height - (startDiameter / 2));
    distance = sqrt(xDiff * xDiff + yDiff * yDiff).abs();
  }
  lastCalc2CirclesInRectWidth = width;
  lastCalc2CirclesInRectHeight = height;
  lastCalc2CirclesInRectCalced = ret;

  return lastCalc2CirclesInRectCalced;
}


void paintPathWithTicks({
  required Canvas canvas,
  required Path originalPath,
  required Rect targetRect,
  required Color lineColor,
  required double lineThickness,
  required int majorTicks,
  required double tickThickness,
  required double tickLength,
}) {

  Offset normalizeOffset(Offset offset) {
    final length = offset.distance;
    return length == 0 ? Offset.zero : offset / length;
  }

  final Paint pathPaint = Paint()
    ..color = lineColor
    ..style = PaintingStyle.stroke
    ..strokeWidth = lineThickness;

  // Get bounds and scale to fit in targetRect
  final Rect pathBounds = originalPath.getBounds();

  final double scaleX = targetRect.width / pathBounds.width;
  final double scaleY = targetRect.height / pathBounds.height;
  final double scale = min(scaleX, scaleY);

  final Matrix4 matrix = Matrix4.identity()
    ..translate(targetRect.left - pathBounds.left * scale, targetRect.top - pathBounds.top * scale)
    ..scale(scale, scale);

  final Path scaledPath = originalPath.transform(matrix.storage);

  // Draw the path
  canvas.drawPath(scaledPath, pathPaint);

  // Draw major tick marks
  final Paint tickPaint = Paint()
    ..color = lineColor
    ..style = PaintingStyle.stroke
    ..strokeWidth = tickThickness;

  final totalLength = scaledPath.computeMetrics().fold<double>(
      0, (sum, metric) => sum + metric.length);

  final tickSpacing = totalLength / (majorTicks + 1);
  double currentDistance = tickSpacing;

  for (final metric in scaledPath.computeMetrics()) {
    while (currentDistance < metric.length) {
      final Tangent? tangent = metric.getTangentForOffset(currentDistance);
      if (tangent == null) break;

      final Offset start = tangent.position;
      final Offset normal = normalizeOffset( Offset(-tangent.vector.dy, tangent.vector.dx));

      final Offset tickStart = start - normal * (tickLength / 2);
      final Offset tickEnd = start + normal * (tickLength / 2);

      canvas.drawLine(tickStart, tickEnd, tickPaint);
      currentDistance += tickSpacing;
    }
    currentDistance -= metric.length; // Adjust for next segment
    if (currentDistance < 0) currentDistance = tickSpacing;
  }
}
