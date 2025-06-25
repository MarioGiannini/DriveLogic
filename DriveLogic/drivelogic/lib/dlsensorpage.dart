import 'package:flutter/material.dart';

import 'dleditdialog.dart';
import 'app_ui.dart';

class DLSensorPageWidget extends StatelessWidget {
  final double columnPadding;
  final double rowPadding;
  final int startSensor;
  final int endSensor;
  final double width;
  final double height;
  final double verticalGap;
  final Map<String,String> sensorSettings;

  const DLSensorPageWidget(  this.width,  this.height, {
    super.key,
    this.columnPadding = 15.0,
    this.rowPadding = 10.0,
    this.startSensor = 1,
    this.endSensor = 5,
    this.verticalGap = double.infinity,
    required this.sensorSettings
  });

  void changeHandler( String update ) // format is senx.n:value where x is sensor # and n is the index of the value
  {
    List<String> parts = update.split(':');
    String key = parts[0];
    String value = parts[1];
    List<String> keyParts = key.split('.');
    String sensor = keyParts[0];
    int index = int.parse(keyParts[1]);
    String sensorData = sensorSettings[sensor] ?? '';
    List<String> sensorDataList = sensorData.split('\t');
    sensorDataList[index] = value;
    sensorSettings[sensor] = sensorDataList.join('\t');
  }

  @override
  Widget build(BuildContext context) {
    double tmpVerticalGap = ( verticalGap == double.infinity ) ? (height / 5) / 3  : verticalGap;

    final double cellWidth = (width ) / 8;
    final double cellHeight = (height - tmpVerticalGap * 2) / 6;

    List<String> rowLabels = [];
    for( int i = startSensor; i <= endSensor; i++ ) {
      rowLabels.add("Sensor $i");
    }
    List<String> columnLabels = [ '', 'Label', 'In Volt 1', 'In Volt 2', 'Start', 'End', 'Warn Low', 'Warn Hi'];

    TextStyle labelStyle = TextStyle(
        fontFamily: 'ChakraPetch',
        fontSize: defaultFontSize,
        fontWeight: FontWeight.bold);

    List<Widget> rows = [];
    List<Widget> rowChildren = [];
    if( tmpVerticalGap != 0 ) {
      rows.add( SizedBox( width: cellWidth, height: tmpVerticalGap ) );
    }

    // Add labels on row 1
    for( int i=0; i < columnLabels.length; i++ ) {
      rowChildren.add(
        Container(
          width: cellWidth,
          height: cellHeight,
          color: Colors.transparent,
          child: Center(
            child: Text( columnLabels[i], style: labelStyle )
        )
      )
      );
    }
    rows.add( Row( children: rowChildren ) );

    // Add the 5 value rows
    for( int i=0; i < 5; i++ ) {
      rowChildren = [];
      rowChildren.add(
          Container(
              width: cellWidth,
              height: cellHeight,
              color: Colors.transparent,
              child: Center(
                  child: Text( rowLabels[i], style: labelStyle )
              )
          )
      );

      // Now add values
      int whichSensor = startSensor + i;
      String sensorData = sensorSettings['sen$whichSensor'] ?? '';
      List<String> sensorDataList = sensorData.split('\t');

      // valueKey is senx.index where x is the sensor # and index is the indexed value (see how setupDatapoints uses tab delimiters)
      for( int c=0; c < 7; c++ ) {
        rowChildren.add(
            SizedBox(
                width: cellWidth,
                height: cellHeight,
                child:
                DLEditTextDialog(
                    width: cellWidth,
                    height: cellHeight,
                    keyboardType: c == 0 ? TextInputType.text : TextInputType.number,
                    maxChars: 5,
                    initialText: sensorDataList[c],
                    labelText: '${rowLabels[i]} ${columnLabels[c+1]}',
                    onSubmitted: changeHandler,
                    valueKey: 'sen${startSensor+i}.$c'  )
            ));
      }

      rows.add( Row( children: rowChildren ) );
    }



    // for( int i=0; i < 6; i++ ) {
    //   rows.add( Row() );
    //
    // }



    return Container(
      color: Colors.transparent,
      child: Column(
        children: rows
      )

    );

  }
}
