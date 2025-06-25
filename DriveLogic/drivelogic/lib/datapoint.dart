// A generic data point for maintaining information on a value and it's ranges and mappings.

// ignore_for_file: constant_identifier_names
import 'package:drivelogic/app_data.dart';

enum DatapointUnitType {
  UT_ASIS,
  UT_MPH,
  UT_KPH,
  UT_FAHRENHEIT,
  UT_CELSIUS,
  UT_PSI,
  UT_KPA,
  UT_AFR,
  UT_LAMBDA,
  UT_BAROCALC,
  UT_LASTENTRY
}

class Datapoint {
  final String _label;
  String get label {
    return ( _labelOverride.isNotEmpty ? _labelOverride : _label );
  }
  String get labelNoOverride => _label;

  // These are read values, which could be the same as displayed values, or mapped to displayed values
  double _lastReading = 0.0;
  double _readingMin = 0.0;
  double _readingMax = 0.0;

  // These are the displayed values
  double _value=0.0;
  double get value => _value;
  String _valueStr="";
  String get valueStr => _valueStr;
  double warnLow = 0.0, warnHigh = 0.0;
  double mapMin = 0.0, mapMax = 0.0; // Map reading to value
  double _min = 0.0, _max = 0.0; // This is the displayed value, like 14000 RPM
  double _minOriginal = 0.0, _maxOriginal = 0.0; // MG: Issue 000836: Implement Data Format feature (This is the original value, for bogus resets)
  double get min {
    return mapMin == 0 && mapMax == 0 ? _min : mapMin;
  }
  double get max {
    return mapMin == 0 && mapMax == 0 ? _max : mapMax;
  }
  // set min(double value) { _min = value; }
  // set max(double value) { _max = value; }


  String type;
  bool included;
  int decimals;
  double dir = 0; // For debugging only
  String source = ""; // If this Datapoint is linked to a source (ESP32 Datapoint.label), then it's the source, otherwise it's an empty string.
  String startCaption="", endCaption="";
  DatapointUnitType unitType = DatapointUnitType.UT_ASIS;
  get unitTypeStr => Datapoint.stringFromUnitType(unitType);
  String _labelOverride=""; // This is for Sensors, so that UI can override the displayed label


  Datapoint( this._label, this._valueStr, this._min, this._max, this.mapMin, this.mapMax, this.warnLow, this.warnHigh, this.type, this.included, this.decimals, this.startCaption, this.endCaption, this.unitType, this.dir )
  {
    _minOriginal = _min;
    _maxOriginal = _max;
    _value = double.parse( _valueStr);
  }

  Datapoint clone()
  {
    Datapoint ret = Datapoint(label, valueStr, min, max, mapMin, mapMax, warnLow, warnHigh, type, included, decimals, startCaption, endCaption, unitType, dir );
    ret._labelOverride = _labelOverride;
    return ret;
  }

  void resetMinMax() {
    // In case _min and _max were modified in updateReading
    _min = _minOriginal;
    _max = _maxOriginal;
  }


  // Any 'bogus' functions are only called in debug mode, when there is no ESP32.
  // The ESP32 would really be doing the 'bogus' work here.
  Datapoint convertUnitTypeBogus( DatapointUnitType newUnitType, bool withBaroCalc )
  {
    Datapoint ret = clone();
    if( unitType == DatapointUnitType.UT_MPH && newUnitType == DatapointUnitType.UT_KPH )
    { // KPH = MPH * 1.60934
      ret._value = _value * 1.60934;
      ret._min = _min * 1.60934;
      ret._max = _max * 1.60934;
      ret.warnHigh = warnHigh * 1.60934;
      ret.warnLow = warnLow * 1.60934;
  } else if( unitType == DatapointUnitType.UT_KPH && newUnitType == DatapointUnitType.UT_MPH )
  { // MPH = KPH / 1.60934
    ret._value = _value / 1.60934;
    ret._min = _min / 1.60934;
    ret._max = _max / 1.60934;
    ret.warnHigh = warnHigh / 1.60934;
    ret.warnLow = warnLow / 1.60934;
  } else if( unitType == DatapointUnitType.UT_FAHRENHEIT && newUnitType == DatapointUnitType.UT_CELSIUS )
    { //C = (F - 32) × 5 / 9
      ret._value = (_value-32) * 5 / 9;
      ret._min = (_min-32) * 5 / 9;
      ret._max = (_max-32) * 5 / 9;
      ret.warnHigh = (warnHigh-32) * 5 / 9;
      ret.warnLow = (warnLow-32) * 5 / 9;
    } else if( unitType == DatapointUnitType.UT_CELSIUS && newUnitType == DatapointUnitType.UT_FAHRENHEIT ) {
    //F = (C × 9 / 5) + 32
      ret._value = (_value * 9 / 5) + 32;
      ret._min = (_min * 9 / 5) + 32;
      ret._max = (_max * 9 / 5) + 32;
      ret.warnHigh = (warnHigh * 9 / 5) + 32;
      ret.warnLow = (warnLow * 9 / 5) + 32;

    } else if( unitType == DatapointUnitType.UT_PSI && newUnitType == DatapointUnitType.UT_KPA )
    { // kPa = PSI × 6.89476
      ret._value = _value * 6.89476;
      ret._min = _min * 6.89476;
      ret._max = _max * 6.89476;
      ret.warnHigh = warnHigh * 6.89476;
      ret.warnLow = warnLow * 6.89476;
    } else if( unitType == DatapointUnitType.UT_KPA && newUnitType == DatapointUnitType.UT_PSI ) {
    // PSI = kPa / 6.89476
      ret._value = _value / 6.89476;
      ret._min = _min / 6.89476;
      ret._max = _max / 6.89476;
      ret.warnHigh = warnHigh / 6.89476;
      ret.warnLow = warnLow / 6.89476;
    } else if( unitType == DatapointUnitType.UT_AFR && newUnitType == DatapointUnitType.UT_LAMBDA )
    { // TODO: Implement conversion formula
      // Note that withBaroCalc determines users choice of barometric correction
      // For now, just return what we received
    } else if( unitType == DatapointUnitType.UT_LAMBDA && newUnitType == DatapointUnitType.UT_AFR )
    { // TODO: Implement conversion formula
      // Note that withBaroCalc determines users choice of barometric correction
      // For now, just return what we received
    }
    ret._valueStr = ret.getDecimaled();
    return ret;
  }

  static Datapoint empty() {
    return Datapoint( "", "0", 0, 0, 0, 0, 0, 0, "", false, 0, '','', DatapointUnitType.UT_ASIS, 0 );
  }

  String getDecimaled( [ double? value ] )
  {
    value ??= this.value;
    String tmp = decimals == 0 ? value.round().toString() : value.toStringAsFixed(decimals);
    return tmp;
  }

  String includedStr()
  {
    return included ? "1" : "0";
  }

  static unitTypeFromString( String unitTypeStr ) {
    DatapointUnitType ret = DatapointUnitType.UT_ASIS;
    if( unitTypeStr == "UT_MPH" ) { ret = DatapointUnitType.UT_MPH;}
    else if( unitTypeStr == "UT_KPH" ) { ret = DatapointUnitType.UT_KPH;}
    else if( unitTypeStr == "UT_FAHRENHEIT" ) {ret = DatapointUnitType.UT_FAHRENHEIT;}
    else if( unitTypeStr == "UT_CELSIUS" ) {ret = DatapointUnitType.UT_CELSIUS;}
    else if( unitTypeStr == "UT_PSI" ) {ret = DatapointUnitType.UT_PSI;}
    else if( unitTypeStr == "UT_KPA" ) {ret = DatapointUnitType.UT_KPA;}
    else if( unitTypeStr == "UT_AFR" ) {ret = DatapointUnitType.UT_AFR;}
    else if( unitTypeStr == "UT_LAMBDA" ) {ret = DatapointUnitType.UT_LAMBDA;}
    else if( unitTypeStr == "UT_BAROCALC" ) {ret = DatapointUnitType.UT_BAROCALC;}

    return ret;
  }
  static String stringFromUnitType( DatapointUnitType unitType ) {
      String ret = "UT_ASIS";
      if( unitType == DatapointUnitType.UT_MPH ) {ret = "UT_MPH";}
      else if( unitType == DatapointUnitType.UT_KPH ) {ret = "UT_KPH";}
      else if( unitType == DatapointUnitType.UT_FAHRENHEIT ) {ret = "UT_FAHRENHEIT";}
      else if( unitType == DatapointUnitType.UT_CELSIUS ) {ret = "UT_CELSIUS";}
      else if( unitType == DatapointUnitType.UT_PSI ) {ret = "UT_PSI";}
      else if( unitType == DatapointUnitType.UT_KPA ) {ret = "UT_KPA";}
      else if( unitType == DatapointUnitType.UT_AFR ) {ret = "UT_AFR";}
      else if( unitType == DatapointUnitType.UT_LAMBDA ) {ret = "UT_LAMBDA";}
      else if( unitType == DatapointUnitType.UT_BAROCALC ) {ret = "UT_BAROCALC";}
      return ret;
  }

  static Datapoint fromString( String src )
  {
    List<String> list = src.split(",");
    Datapoint ret = Datapoint( list[0], // label
        list[1], // valueStr
        double.parse(list[2]), // min
        double.parse(list[3]), // max
        0, 0, // minMap and maxMap are not provided by ESP32, but specified in Sensor settings screen
        double.parse(list[4]), // warnLow
        double.parse(list[5]), // warnHigh
        list[6], //  type
        list[9]=="1", // included,
        int.parse(list[10]), // decimals,
        list[7], // startCaption,
        list[8], //endCaption
        unitTypeFromString( list[11] ), //unitType
        list.length > 12 ? double.parse( list[12] ) : 1.0 //  dir (really only used for emulating)
    );
    return ret;
  }

  bool hasWarning() // returns true if warnLow or warnHigh are not equal to min or max
  {
    return ( warnLow == min && warnHigh == max ? false : true );
  }
  bool isWarning() // returns true if value is not between warnLow and warnHigh
  {
    double myWarnHigh = DLAppData.appData.getWarningLights( _label, warnHigh );
   return ( _value <= warnLow && warnLow != min ) || (_value >= myWarnHigh && myWarnHigh != max );
  }

  bool isNominal() // returns true if value is between warnLow and warnHigh
  {
    return  ( !isWarning() );
  }

  bool isSensor() {
    return (  type == 'S' || type.indexOf( 'S.') == 0 );
  }

  void setLabelOverride( String labelOverride ) {
    _labelOverride = labelOverride;
  }

  void updateBogus() // Update bogus datapoint with bogus value, for demonstration and debugging
  {
    // This is not intended for the real data points.
    // It is meant to update the bogus data points like datapointsHolleyDemo

    double tmpMax = _max == 0.0 ? 5.0 : _max;
    _value += dir;
    if (_value < min) {
      _value = min;
      dir = -dir;
    }
    else if (_value > tmpMax) {
      _value = tmpMax;
      dir = -dir;
    }
    _valueStr = getDecimaled();
  }

  double map(double value, double inRangeMin, double inRangeMax, double outRangeMin, double outRangeMax ) {
    if( outRangeMin == outRangeMax ) {
      return value; // Nothing to map to?  Return original
    }
    return outRangeMin + ((value - inRangeMin) / (inRangeMax - inRangeMin)) * (outRangeMax - outRangeMin);
  }

  void updateReading( String aStrReading ) // update the value in the data point
  {
    _lastReading = double.parse( aStrReading );
    if( mapMin == 0 && mapMax == 0 ) // If no mapping, set directly into value
    {
        _value = _lastReading;
    }
    else
    {
      _value = map(_lastReading, _readingMin, _readingMax, mapMin, mapMax);
    }
    _valueStr = getDecimaled();

    if( mapMin == 0 && mapMax == 0) {
      if( _value > _max ) {
        _max = _value;
      }
      else if( _value < _min ) {
        _min = _value;
      }
    }
    else
    {
      if( _value > mapMax ) {
        mapMax = _value;
      }
      else if( _value < mapMin ) {
        mapMin = _value;
      }

    }


  }

  double distance () {
    return( ( max - min) + 1 );
  }

  void applySensorSettings( String settings ) {
    // label, readingMin, readingMax, displayMin, displayMax, warnLow, warnHigh
    List<String> attributes = settings.split("\t");

    setLabelOverride(attributes[0]);
    _readingMin = double.parse(attributes[1]);
    _readingMax = double.parse(attributes[2]);

    mapMin = double.parse(attributes[3]);
    mapMax = double.parse(attributes[4]);

    warnLow = double.parse(attributes[5]);
    warnHigh = double.parse(attributes[6]);
  }
}
