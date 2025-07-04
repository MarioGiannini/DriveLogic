import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'mg64_bluetooth.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'datapoint.dart';

String bogusDevice =
    'HOLLEYTERMX2'; // HALTECH2 or MMEGASQUIRT, to utilizes bogusDatapoints

typedef MyVoidCallback = void Function();
typedef MyStringCallback = void Function(String);
typedef MyKeyStringCallback = void Function(String, String);

////////////////////////////////////////////////////////////////
////////////////  Data
////////////////////////////////////////////////////////////////

// class SensorAttributes {
//   String customLabel="";
//   double min=0, max=0, warnLow=0,warnHigh=0;
// }

// Below are data arrays for demonstration and default values, created via Excel.  Update Excel,then copy ad paste the new arrays
List<Datapoint> datapointsHolleyDemo = [
  Datapoint("HIDE", "0", 0, 300, 0, 0, 0, 300, "G", true, 0, '', '', DatapointUnitType.UT_ASIS, 1),
  Datapoint("TMG", "0", 0, 300, 0, 0, 0, 300, "G", true, 0, '', '', DatapointUnitType.UT_ASIS, 2),
  Datapoint("BST", "0", 0, 30, 0, 0, 0, 30, "G", true, 0, '', '', DatapointUnitType.UT_PSI, 1),
  Datapoint("AFRL", "0", 0, 300, 0, 0, 0, 300, "G", true, 0, '', '', DatapointUnitType.UT_ASIS, 4),
  Datapoint("AFRR", "0", 0, 300, 0, 0, 0, 300, "G", true, 0, '', '', DatapointUnitType.UT_ASIS, 5),
  Datapoint("AFRA", "0", 0, 300, 0, 0, 0, 300, "G", true, 0, '', '', DatapointUnitType.UT_ASIS, 6),
  Datapoint("ECO", "0", 0, 300, 0, 0, 0, 300, "G", true, 0, '', '', DatapointUnitType.UT_ASIS, 7),
  Datapoint("BAT", "0", 0, 15, 0, 0, 10, 14, "G", true, 1, 'L', 'H', DatapointUnitType.UT_ASIS, 0.5),
  Datapoint("OIL", "0", 0, 100, 0, 0, 25, 75, "G", true, 0, '', '', DatapointUnitType.UT_PSI, 1),
  Datapoint("IAT", "0", 0, 300, 0, 0, 0, 300, "G", true, 0, '', '', DatapointUnitType.UT_ASIS, 1),
  Datapoint("FPR", "0", 0, 300, 0, 0, 0, 300, "G", true, 0, '', '', DatapointUnitType.UT_ASIS, 2),
  Datapoint("CLT", "0", 0, 300, 0, 0, 0, 300, "G", true, 0, '', '', DatapointUnitType.UT_ASIS, 3),
  Datapoint("TPS", "0", 0, 300, 0, 0, 0, 300, "G", true, 0, '', '', DatapointUnitType.UT_ASIS, 4),
  Datapoint("TRN", "0", 0, 300, 0, 0, 0, 300, "G", true, 0, '', '', DatapointUnitType.UT_ASIS, 5),
  Datapoint("TRSP", "0", 0, 300, 0, 0, 0, 300, "G", true, 0, '', '', DatapointUnitType.UT_ASIS, 6),
  Datapoint("TAFR", "0", 0, 300, 0, 0, 0, 300, "G", true, 0, '', '', DatapointUnitType.UT_ASIS, 7),
  Datapoint("RANG", "0", 0, 300, 0, 0, 0, 300, "G", true, 0, '', '', DatapointUnitType.UT_ASIS, 8),
  Datapoint("IACP", "0", 0, 300, 0, 0, 0, 300, "G", true, 0, '', '', DatapointUnitType.UT_ASIS, 9),
  Datapoint("GEAR", "0", 0, 7, 0, 0, 0, 7, "G", true, 0, '', '', DatapointUnitType.UT_ASIS, 0.01),
  Datapoint("SEN1", "0", 0, 0, 0, 0, 0, 0, "S", true, 0, '', '', DatapointUnitType.UT_ASIS, 0.1),
  Datapoint("SEN2", "0", 0, 0, 0, 0, 0, 0, "S", true, 0, '', '', DatapointUnitType.UT_ASIS, 0.1),
  Datapoint("SEN3", "0", 0, 0, 0, 0, 0, 0, "S", true, 0, '', '', DatapointUnitType.UT_ASIS, 0.1),
  Datapoint("SEN4", "0", 0, 0, 0, 0, 0, 0, "S", true, 0, '', '', DatapointUnitType.UT_ASIS, 0.1),
  Datapoint("SEN5", "0", 0, 0, 0, 0, 0, 0, "S", true, 0, '', '', DatapointUnitType.UT_ASIS, 0.1),
  Datapoint("SEN6", "0", 0, 0, 0, 0, 0, 0, "S", true, 0, '', '', DatapointUnitType.UT_ASIS, 0.1),
  Datapoint("SEN7", "0", 0, 0, 0, 0, 0, 0, "S", true, 0, '', '', DatapointUnitType.UT_ASIS, 0.1),
  Datapoint("SEN8", "0", 0, 0, 0, 0, 0, 0, "S", true, 0, '', '', DatapointUnitType.UT_ASIS, 0.1),
  Datapoint("SEN9", "0", 0, 0, 0, 0, 0, 0, "S", true, 0, '', '', DatapointUnitType.UT_ASIS, 0.1),
  Datapoint("SEN10", "0", 0, 0, 0, 0, 0, 0, "S", true, 0, '', '', DatapointUnitType.UT_ASIS, 0.1),
  Datapoint("SEN11", "0", 0, 0, 0, 0, 0, 0, "S", true, 0, '', '', DatapointUnitType.UT_ASIS, 0.1),
  Datapoint("SEN12", "0", 0, 0, 0, 0, 0, 0, "S", true, 0, '', '', DatapointUnitType.UT_ASIS, 0.1),
  Datapoint("SEN13", "0", 0, 0, 0, 0, 0, 0, "S", true, 0, '', '', DatapointUnitType.UT_ASIS, 0.1),
  Datapoint("SEN14", "0", 0, 0, 0, 0, 0, 0, "S", true, 0, '', '', DatapointUnitType.UT_ASIS, 0.1),
  Datapoint("SEN15", "0", 0, 0, 0, 0, 0, 0, "S", true, 0, '', '', DatapointUnitType.UT_ASIS, 0.1),
  Datapoint("SEN16", "0", 0, 0, 0, 0, 0, 0, "S", true, 0, '', '', DatapointUnitType.UT_ASIS, 0.1),
  Datapoint("SEN17", "0", 0, 0, 0, 0, 0, 0, "S", true, 0, '', '', DatapointUnitType.UT_ASIS, 0.1),
  Datapoint("SEN18", "0", 0, 0, 0, 0, 0, 0, "S", true, 0, '', '', DatapointUnitType.UT_ASIS, 0.1),
  Datapoint("SEN19", "0", 0, 0, 0, 0, 0, 0, "S", true, 0, '', '', DatapointUnitType.UT_ASIS, 0.1),
  Datapoint("SEN20", "0", 0, 0, 0, 0, 0, 0, "S", true, 0, '', '', DatapointUnitType.UT_ASIS, 0.1),
  Datapoint("SEN21", "0", 0, 0, 0, 0, 0, 0, "S", true, 0, '', '', DatapointUnitType.UT_ASIS, 0.1),
  Datapoint("SEN22", "0", 0, 0, 0, 0, 0, 0, "S", true, 0, '', '', DatapointUnitType.UT_ASIS, 0.1),
  Datapoint("SEN23", "0", 0, 0, 0, 0, 0, 0, "S", true, 0, '', '', DatapointUnitType.UT_ASIS, 0.1),
  Datapoint("SEN24", "0", 0, 0, 0, 0, 0, 0, "S", true, 0, '', '', DatapointUnitType.UT_ASIS, 0.1),
  Datapoint("SEN25", "0", 0, 0, 0, 0, 0, 0, "S", true, 0, '', '', DatapointUnitType.UT_ASIS, 0.1),
];
List<Datapoint> datapointsHalTech2Demo = [
  Datapoint("HIDE", "0", 0, 300, 0, 0, 0, 300, "G", true, 0, '', '', DatapointUnitType.UT_ASIS, 1),
  Datapoint("BST", "0", 0, 30, 0, 0, 0, 30, "G", true, 0, '', '', DatapointUnitType.UT_PSI, 1),
  Datapoint("BAT", "0", 0, 15, 0, 0, 10, 14, "G", true, 1, 'L', 'H', DatapointUnitType.UT_ASIS, 3),
  Datapoint("OIL", "0", 0, 100, 0, 0, 25, 75, "G", true, 0, '', '', DatapointUnitType.UT_PSI, 4),
  Datapoint("OILT", "0", 0, 300, 0, 0, 0, 300, "G", true, 0, '', '', DatapointUnitType.UT_FAHRENHEIT, 5),
  Datapoint("IAT", "0", 0, 300, 0, 0, 0, 300, "G", true, 0, '', '', DatapointUnitType.UT_ASIS, 6),
  Datapoint("FPR", "0", 0, 300, 0, 0, 0, 300, "G", true, 0, '', '', DatapointUnitType.UT_ASIS, 7),
  Datapoint("CLT", "0", 0, 300, 0, 0, 0, 300, "G", true, 0, '', '', DatapointUnitType.UT_ASIS, 8),
  Datapoint("TPS", "0", 0, 300, 0, 0, 0, 300, "G", true, 0, '', '', DatapointUnitType.UT_ASIS, 9),
  Datapoint("EGT1", "0", 0, 300, 0, 0, 0, 300, "G", true, 0, '', '', DatapointUnitType.UT_ASIS, 10),
  Datapoint("EGT2", "0", 0, 300, 0, 0, 0, 300, "G", true, 0, '', '', DatapointUnitType.UT_ASIS, 11),
  Datapoint("E85", "0", 0, 300, 0, 0, 0, 300, "G", true, 0, '', '', DatapointUnitType.UT_ASIS, 12),
  Datapoint("GEAR", "0", 0, 7, 0, 0, 0, 7, "G", true, 0, '', '', DatapointUnitType.UT_ASIS, 0.01),
  Datapoint("SEN1", "0", 0, 0, 0, 0, 0, 0, "S", true, 0, '', '', DatapointUnitType.UT_ASIS, 0.1),
  Datapoint("SEN2", "0", 0, 0, 0, 0, 0, 0, "S", true, 0, '', '', DatapointUnitType.UT_ASIS, 0.1),
  Datapoint("SEN3", "0", 0, 0, 0, 0, 0, 0, "S", true, 0, '', '', DatapointUnitType.UT_ASIS, 0.1),
  Datapoint("SEN4", "0", 0, 0, 0, 0, 0, 0, "S", true, 0, '', '', DatapointUnitType.UT_ASIS, 0.1),
  Datapoint("SEN5", "0", 0, 0, 0, 0, 0, 0, "S", true, 0, '', '', DatapointUnitType.UT_ASIS, 0.1),
  Datapoint("SEN6", "0", 0, 0, 0, 0, 0, 0, "S", true, 0, '', '', DatapointUnitType.UT_ASIS, 0.1),
  Datapoint("SEN7", "0", 0, 0, 0, 0, 0, 0, "S", true, 0, '', '', DatapointUnitType.UT_ASIS, 0.1),
  Datapoint("SEN8", "0", 0, 0, 0, 0, 0, 0, "S", true, 0, '', '', DatapointUnitType.UT_ASIS, 0.1),
  Datapoint("SEN9", "0", 0, 0, 0, 0, 0, 0, "S", true, 0, '', '', DatapointUnitType.UT_ASIS, 0.1),
  Datapoint("SEN10", "0", 0, 0, 0, 0, 0, 0, "S", true, 0, '', '', DatapointUnitType.UT_ASIS, 0.1),
  Datapoint("LAM1", "0", 0, 300, 0, 0, 0, 300, "G", true, 0, '', '', DatapointUnitType.UT_ASIS, 1),
  Datapoint("LAM2", "0", 0, 300, 0, 0, 0, 300, "G", true, 0, '', '', DatapointUnitType.UT_ASIS, 2),
  Datapoint("LAM3", "0", 0, 300, 0, 0, 0, 300, "G", true, 0, '', '', DatapointUnitType.UT_ASIS, 3),
  Datapoint("LAM4", "0", 0, 300, 0, 0, 0, 300, "G", true, 0, '', '', DatapointUnitType.UT_ASIS, 0.01),
  Datapoint("LAMO", "0", 0, 300, 0, 0, 0, 300, "G", true, 0, '', '', DatapointUnitType.UT_ASIS, 1),
  Datapoint("LB1", "0", 0, 300, 0, 0, 0, 300, "G", true, 0, '', '', DatapointUnitType.UT_ASIS, 1),
  Datapoint("LB2", "0", 0, 300, 0, 0, 0, 300, "G", true, 0, '', '', DatapointUnitType.UT_ASIS, 2),
  Datapoint("FLVL", "0", 0, 300, 0, 0, 0, 300, "G", true, 0, '', '', DatapointUnitType.UT_ASIS, 3),
  Datapoint("BARO", "0", 0, 300, 0, 0, 0, 300, "G", true, 0, '', '', DatapointUnitType.UT_ASIS, 4),
  Datapoint("EGT3", "0", 0, 300, 0, 0, 0, 300, "G", true, 0, '', '', DatapointUnitType.UT_ASIS, 5),
  Datapoint("EGT4", "0", 0, 300, 0, 0, 0, 300, "G", true, 0, '', '', DatapointUnitType.UT_ASIS, 6),
  Datapoint("EGT5", "0", 0, 300, 0, 0, 0, 300, "G", true, 0, '', '', DatapointUnitType.UT_ASIS, 7),
  Datapoint("EGT6", "0", 0, 300, 0, 0, 0, 300, "G", true, 0, '', '', DatapointUnitType.UT_ASIS, 8),
  Datapoint("EGT7", "0", 0, 300, 0, 0, 0, 300, "G", true, 0, '', '', DatapointUnitType.UT_ASIS, 0.01),
  Datapoint("EGT8", "0", 0, 300, 0, 0, 0, 300, "G", true, 0, '', '', DatapointUnitType.UT_ASIS, 1),
  Datapoint("BRKP", "0", 0, 300, 0, 0, 0, 300, "G", true, 0, '', '', DatapointUnitType.UT_ASIS, 2),
  Datapoint("NOS1", "0", 0, 300, 0, 0, 0, 300, "G", true, 0, '', '', DatapointUnitType.UT_ASIS, 3),
  Datapoint("TRBS", "0", 0, 300, 0, 0, 0, 300, "G", true, 0, '', '', DatapointUnitType.UT_ASIS, 4),
  Datapoint("CLTP", "0", 0, 300, 0, 0, 0, 300, "G", true, 0, '', '', DatapointUnitType.UT_ASIS, 5),
  Datapoint("WGP", "0", 0, 300, 0, 0, 0, 300, "G", true, 0, '', '', DatapointUnitType.UT_ASIS, 6),
  Datapoint("IJS2", "0", 0, 300, 0, 0, 0, 300, "G", true, 0, '', '', DatapointUnitType.UT_ASIS, 7),
  Datapoint("IGNA", "0", 0, 300, 0, 0, 0, 300, "G", true, 0, '', '', DatapointUnitType.UT_ASIS, 8),
  Datapoint("WHSL", "0", 0, 300, 0, 0, 0, 300, "G", true, 0, '', '', DatapointUnitType.UT_ASIS, 9),
  Datapoint("WHDF", "0", 0, 300, 0, 0, 0, 300, "G", true, 0, '', '', DatapointUnitType.UT_ASIS, 10),
];
List<Datapoint> datapointsMegasquirtDemo = [
  Datapoint("HIDE", "0", 0, 300, 0, 0, 0, 300, "G", true, 0, '', '', DatapointUnitType.UT_ASIS, 1),
  Datapoint("ADV", "0", 0, 300, 0, 0, 0, 300, "G", true, 0, '', '', DatapointUnitType.UT_ASIS, 2),
  Datapoint("AFR", "0", 0, 300, 0, 0, 0, 300, "G", true, 0, '', '', DatapointUnitType.UT_ASIS, 3),
  Datapoint("BST", "0", 0, 30, 0, 0, 0, 30, "G", true, 0, '', '', DatapointUnitType.UT_PSI, 1),
  Datapoint("IAT", "0", 0, 300, 0, 0, 0, 300, "G", true, 0, '', '', DatapointUnitType.UT_ASIS, 5),
  Datapoint("CLT", "0", 0, 300, 0, 0, 0, 300, "G", true, 0, '', '', DatapointUnitType.UT_ASIS, 6),
  Datapoint("TPS", "0", 0, 300, 0, 0, 0, 300, "G", true, 0, '', '', DatapointUnitType.UT_ASIS, 7),
  Datapoint("BAT", "0", 0, 15, 0, 0, 10, 14, "G", true, 1, 'L', 'H', DatapointUnitType.UT_ASIS, 0.5),
  Datapoint("IAC", "0", 0, 300, 0, 0, 0, 300, "G", true, 0, '', '', DatapointUnitType.UT_ASIS, 9),
  Datapoint("GEAR", "0", 0, 7, 0, 0, 0, 7, "G", true, 0, '', '', DatapointUnitType.UT_ASIS, 0.01),
  Datapoint("FCOR", "0", 0, 300, 0, 0, 0, 300, "G", true, 0, '', '', DatapointUnitType.UT_ASIS, 1),
  Datapoint("FPR", "0", 0, 300, 0, 0, 0, 300, "G", true, 0, '', '', DatapointUnitType.UT_ASIS, 2),
  Datapoint("CLTP", "0", 0, 300, 0, 0, 0, 300, "G", true, 0, '', '', DatapointUnitType.UT_ASIS, 3),
  Datapoint("OIL", "0", 0, 100, 0, 0, 25, 75, "G", true, 0, '', '', DatapointUnitType.UT_PSI, 4),
  Datapoint("OILT", "0", 0, 300, 0, 0, 0, 300, "G", true, 0, '', '', DatapointUnitType.UT_FAHRENHEIT, 5),
  Datapoint("EGT", "0", 0, 300, 0, 0, 0, 300, "G", true, 0, '', '', DatapointUnitType.UT_ASIS, 6),
  Datapoint("VSS", "0", 0, 300, 0, 0, 0, 300, "G", true, 0, '', '', DatapointUnitType.UT_ASIS, 7),
  Datapoint("WCOR", "0", 0, 300, 0, 0, 0, 300, "G", true, 0, '', '', DatapointUnitType.UT_ASIS, 8),
  Datapoint("E85", "0", 0, 300, 0, 0, 0, 300, "G", true, 0, '', '', DatapointUnitType.UT_ASIS, 9),
  Datapoint("SEN1", "0", 0, 0, 0, 0, 0, 0, "S", true, 0, '', '', DatapointUnitType.UT_ASIS, 0.1),
  Datapoint("SEN2", "0", 0, 0, 0, 0, 0, 0, "S", true, 0, '', '', DatapointUnitType.UT_ASIS, 0.1),
  Datapoint("SEN3", "0", 0, 0, 0, 0, 0, 0, "S", true, 0, '', '', DatapointUnitType.UT_ASIS, 0.1),
  Datapoint("SEN4", "0", 0, 0, 0, 0, 0, 0, "S", true, 0, '', '', DatapointUnitType.UT_ASIS, 0.1),
  Datapoint("SEN5", "0", 0, 0, 0, 0, 0, 0, "S", true, 0, '', '', DatapointUnitType.UT_ASIS, 0.1),
  Datapoint("SEN6", "0", 0, 0, 0, 0, 0, 0, "S", true, 0, '', '', DatapointUnitType.UT_ASIS, 0.1),
  Datapoint("SEN7", "0", 0, 0, 0, 0, 0, 0, "S", true, 0, '', '', DatapointUnitType.UT_ASIS, 0.1),
  Datapoint("SEN8", "0", 0, 0, 0, 0, 0, 0, "S", true, 0, '', '', DatapointUnitType.UT_ASIS, 0.1),
  Datapoint("SEN9", "0", 0, 0, 0, 0, 0, 0, "S", true, 0, '', '', DatapointUnitType.UT_ASIS, 0.1),
  Datapoint("SEN10", "0", 0, 0, 0, 0, 0, 0, "S", true, 0, '', '', DatapointUnitType.UT_ASIS, 0.1),
  Datapoint("SEN11", "0", 0, 0, 0, 0, 0, 0, "S", true, 0, '', '', DatapointUnitType.UT_ASIS, 0.1),
  Datapoint("SEN12", "0", 0, 0, 0, 0, 0, 0, "S", true, 0, '', '', DatapointUnitType.UT_ASIS, 0.1),
  Datapoint("SEN13", "0", 0, 0, 0, 0, 0, 0, "S", true, 0, '', '', DatapointUnitType.UT_ASIS, 0.1),
  Datapoint("SEN14", "0", 0, 0, 0, 0, 0, 0, "S", true, 0, '', '', DatapointUnitType.UT_ASIS, 0.1),
  Datapoint("SEN15", "0", 0, 0, 0, 0, 0, 0, "S", true, 0, '', '', DatapointUnitType.UT_ASIS, 0.1),
  Datapoint("SEN16", "0", 0, 0, 0, 0, 0, 0, "S", true, 0, '', '', DatapointUnitType.UT_ASIS, 0.1),
];
List<Datapoint> datapointsCommonDemo = [
  Datapoint("SPEED", "0", 0, 200, 0, 0, 0, 200, "Speed", true, 0, '', '', DatapointUnitType.UT_MPH, 10),
  Datapoint("FUEL", "0", 0, 300, 0, 0, 75, 300, "Fuel", true, 0, '', '', DatapointUnitType.UT_ASIS, 1),
  Datapoint("RPM", "0", 0, 14000, 0, 0, 0, 13000, "RPM", true, 0, '', '', DatapointUnitType.UT_ASIS, 1000),
  Datapoint("TIREFD", "0", 0, 45, 0, 0, 30, 38, "TIREFD", true, 0, '', '', DatapointUnitType.UT_ASIS, 1),
  Datapoint("TIREFP", "0", 0, 45, 0, 0, 30, 38, "TIREFP", true, 0, '', '', DatapointUnitType.UT_ASIS, 1),
  Datapoint("TIRERD", "0", 0, 45, 0, 0, 30, 38, "TIRERD", true, 0, '', '', DatapointUnitType.UT_ASIS, 1),
  Datapoint("TIRERP", "0", 0, 45, 30, 0, 0, 38, "TIRERP", true, 0, '', '', DatapointUnitType.UT_ASIS, 1),
  Datapoint("TIRE", "0", 0, 45, 0, 0, 30, 38, "TIRE", true, 0, '', '', DatapointUnitType.UT_ASIS, 1),
  Datapoint("TURNL", "0", 0, 10, 0, 0, 0, 5, "LeftTurn", true, 0, '', '', DatapointUnitType.UT_ASIS, 1),
  Datapoint("TURNR", "0", 0, 20, 0, 0, 0, 10, "RightTurn", true, 0, '', '', DatapointUnitType.UT_ASIS, 1),
  Datapoint("LIGHTS", "0", 0, 1, 0, 0, 0, 1, "Lights", true, 0, '', '', DatapointUnitType.UT_ASIS, 1),
  Datapoint("LIGHTSHI", "0", 0, 40, 0, 0, 0, 20, "HighBeam", true, 0, '', '', DatapointUnitType.UT_ASIS, 1),
  // This is to standard on certain datapoints from different EFI units, like coolant temp
  Datapoint("CLNTT", "0", 0, 100, 0, 0, 0, 100, "CLNTT", true, 0, 'C', 'H', DatapointUnitType.UT_ASIS, 1),

  // MG: Issue 0000841: Implement an Odometer widget
  Datapoint("ODO", "0", 0, 9999999, 0, 0, 0, 9999999, "ODO", true, 0, '', '', DatapointUnitType.UT_MPH, 10),

  // Datapoint( "PITCH","0",0,360,0,360,"PITCH",true,0,'','',DatapointUnitType.UT_ASIS, 1),
  // Datapoint( "ROLL","0",0,360,0,360,"ROLL",true,0,'','',DatapointUnitType.UT_ASIS, 1),
];

class DLAppData {
  // Here are some definitions:
  // Datapoint - Defines data received from ESP32, such as Gear, Bat, Speed, RPM, etc..  Datapoints contain value, min, max, warnLow and warmHigh.
  // Source - A string that defines a datapoint and possibly user-managed warnLow and warnHi value.
  // element - An on screen widget.  Can be a gauge, text, image toggle, and so on.  It is linked to a Source.
  String osData = "";
  String _appVersion = "";
  get appVersion => _appVersion;
  String deviceVersion = "N/A";
  bool wasCleared = false;
  bool inSettings = false;

  Map<String, Datapoint> allDatapoints =
      {}; // All datapoints, as provided by the ESP32
  List<String> selectableDatapoints =
      []; // Name of datapoints that can be selected for an element.  i.e., GEAR, but not RPM.
  List<String> changeableElements =
      []; // Names of UI elements that can be changed to a different datapoint.  i.e., Mutable.Gauge0, but not Speed
  List<String> userOnOffElements =
      []; // Names of UI elements that are fixed to a datapoint, but can be configured, like, UserOnOff.RPM.ShiftIndicator.

  // MG: Issue 0000839: Implement Warning Lights config screen with new UI
  Map<String,String> warningLights = {}; // Map warning light labels to user values
  Map<String,String> warningLightLabelToDatapoint = { // Map labels to data points. Adked for clarification in email on how to identify
    "Oil Temp." : "OILT",
    "Shift" : "RPM",
    "Oil Press." : "OIL",
    "Fuel PSI" : "FPR",
    "Volts" : "BAT",
    "Boost" : "BST",
    "Coolant" : "CLT",
    "AFR" : "AFR",
  };

  MG64Bluetooth? bt;

  String visualLayout = "Gauges";
  String newvisualLayout = "Gauges";
  Map<String, String> layoutBackgrounds = {};
  Map<String, List<String>> layoutElements = {
    // Define elements for each layout
    // If preceded by 'Mutable', then it can be changed by user in the UI.
    // If not preceded by 'Mutable', or 'UserOnOff', it's a datapoint label
    // If preceded by 'UserOnOff, then a datapoint label follows, and a display name.  These are values the user can set an on/off valur for.
    // If preceded by *, then datapoint is wanted, but may not have direct onscreen gauge (such as Fuel under Speed)
    'Gauges': [
      "Speed",
      "RPM",
      "TURNL",
      "TURNR",
      "LIGHTSHI",
      "Mutable.Gauge1",
      "Mutable.Gauge2",
      "Mutable.Gauge3",
      "Mutable.Gauge4",
      "Mutable.Gauge5",
      "Mutable.Gauge6",
      "Mutable.Gauge7",
      "Mutable.Gauge8",
      "Mutable.Gauge9",
      "UserOnOff.RPM.ShiftIndicator",
      "*FUEL",
      "LEDStrip."
    ],
    // MG: Issue 0000842: Remove Digital and Offroad layouts
    /*'Digitals': [
      "Speed",
      "RPM",
      "TURNL",
      "TURNR",
      "LIGHTSHI",
      "Mutable.Gauge1",
      "Mutable.Gauge2",
      "Mutable.Gauge3",
      "Mutable.Gauge4",
      "Mutable.Gauge5",
      "Mutable.Gauge6",
      "Mutable.Gauge7",
      "Mutable.Gauge8",
      "Mutable.Gauge9",
      "UserOnOff.RPM.ShiftIndicator",
      "*FUEL",
      "LEDStrip."
    ],
    'OffRoad': [
      "FUEL",
      "Speed",
      "PITCH",
      "ROLL",
      "RPM",
      "CLNTT",
      "UserOnOff.RPM.ShiftIndicator",
      "Mutable.Gauge1",
      "Mutable.Gauge2",
      "Mutable.Gauge3",
      "Mutable.Gauge4",
      "Mutable.Gauge5",
      "Mutable.Gauge6",
      "Mutable.Gauge7",
      "Mutable.Gauge8",
      "Mutable.Gauge9"
    ],
     */
    'Dark': [
      "FUEL",
      "Speed",
      "RPM",
      "CLNTT",
      "ODO",
      "UserOnOff.RPM.ShiftIndicator",
      "Mutable.Gauge1",
      "Mutable.Gauge2",
      "Mutable.Gauge3",
      "Mutable.Gauge4",
      "Mutable.Gauge5",
      "Mutable.Gauge6",
      "Mutable.Gauge7",
      "Mutable.Gauge8",
      "Mutable.Gauge9",
      "LEDStrip."

    ],
    // Disable Map, it was implemented as a beta and part of research.
    //'Map': ["Speed", "+Map", "RPM" ],
  };

  Map<String, String> elementSources =
      {}; // Map layout position string to datapoint label and configuration (i.e., Mutable.Gauge0 -> GEAR ).  The string is Label[.warnLow,warnHigh].  Alllows user over-rides of received data
  Map<String, String> ledStripSources =
      {}; // Map LED strip indicators to different data points, layout dependant.  i.e., Gauges1.LED1-> OIL.  LED indicators are on when nominal settings are reached.
  Map<String, String> sensorSettings =
      {}; // Map Sensor label to user definitions, loaded from ESP32 to start, layout independent.  For example, SEN1 -> "lblOverride,newMin,newMax,newWarnLow,newWarnHigh"
  // Note: updateDatapointFromSensors updates allDatapoints from sensorSettings.

  // MG: Issue 000836: Implement Data Format feature
  // These data formats and keys must match ESP32 expectations.
  Map<String, String> dataFormats = {
    'Pressure': 'PSI',
    'Temperature': 'Fahrenheit',
    'Speed': 'MPH',
    'Fuel': 'AFR',
    'BaroCalc': 'Y'
  };

  /* Maybe if we want the ESP32 to send Device info, but not needed for now
  Map<String,String> EFIDevices = {
    'HOLLEYTERMX2': 'Holley Terminator X2',
    'HALTECH2': 'Haltech Series 2',
    'MEGASQUIRT': 'Megasquirt'
  };

  Map<String,List<Datapoint>> EFIDeviceBlocks = {
    'HOLLEYTERMX2': datapointsHolley,
    'HALTECH2': datapointsHalTech2,
    'MEGASQUIRT': datapointsMegasquirt
  };
  */

  // This data is for _emulating and bogus data
  String bogusDevice = "HOLLEYTERMX2";
  String bogusState = "";
  Map<String, Datapoint> allBogusDatapoints = {};

  MG64BluetoothDevice lastConnectedDevice = emptyMG64BluetoothDevice();
  List<String> logText = [];
  bool datapointsWereSetup = false;

  bool renewAccepted = false;

  PackageInfo? packageInfo;

  void setVisualLayout(String newLayout) {
    visualLayout = newLayout;
  }

  void logIt(String add) {
    if( logText.length > 1000) {
      logText.removeRange(0, 100);
    }
    logText.add("${DateFormat("jm").format(DateTime.now())} - $add");
  }

  String errorString = "";
  bool storeBusy = false;
  GlobalKey<ScaffoldState> drawerKey = GlobalKey();

  static DLAppData appData = DLAppData();

  DLAppData() {
    appData = this;
  }

  String getElementDisplayName(
      String
          element) // Because there is so much lower-case formatting in keys and lookups
  {
    String ret = "UNK";
    element = element.toLowerCase();
    List<String> parts = element.split('.');
    element = element.replaceFirst('${parts[0]}.', '');

    layoutElements.forEach((String key, List<String> list) {
      if (key.toLowerCase() == parts[0]) {
        for (int i = 0; i < list.length; i++) {
          if (list[i].toLowerCase() == element) {
            ret = list[i];
            break;
          }
        }
      }
    });
    return ret;
  }

  List<String> getUnhiddenElements() // Retrieves Datapoints not set to HIDE
  {
    List<String> ret = [];
    for (String element in layoutElements[visualLayout]!) {
      if (element.indexOf('Mutable.') == 0) // Only Mutable elements
      {
        String wanted =
            '${visualLayout.toLowerCase()}.${element.toLowerCase()}';
        if (elementSources.containsKey(wanted)) {
          List<String> sourcePortions = elementSources[wanted]!.split(',');
          if (sourcePortions[0] != 'HIDE') {
            ret.add(element);
          }
        }
      }
    }
    return ret;
  }

  Datapoint getDatapointByElement(String element) {
    String key = '$visualLayout.$element'.toLowerCase();

    if (elementSources.containsKey(key)) {
      String label = elementSources[key]!.toLowerCase();
      label = label.split(',')[0];
      if (allDatapoints.containsKey(label)) {
        return allDatapoints[label]!;
      }
    }
    return Datapoint.empty();
  }

  Datapoint getDatapointByLabel(String label,
      {bool labelContainsLayout = false}) {
    Datapoint? ret;
    label = label.toLowerCase();
    if (allDatapoints.isNotEmpty) {
      ret = allDatapoints.containsKey(label) ? allDatapoints[label] : null;
      allDatapoints.forEach((String key, Datapoint datapoint) {
        if (datapoint.label.toLowerCase() == label) {
          ret = datapoint;
        }
      });
      if (ret == null) {
        if (!labelContainsLayout) {
          label = '${visualLayout.toLowerCase()}.$label';
        } else {
          label = label.toLowerCase();
        }
        if (elementSources.containsKey(label)) {
          List<String> data = elementSources[label]!.split(',');
          String tmp = data[0].toLowerCase();
          if (allDatapoints.containsKey(tmp)) {
            ret = allDatapoints[tmp]!.clone();
            ret!.source = label;
            if (data.length == 3) {
              ret!.warnLow = double.parse(data[1]);
              ret!.warnHigh = double.parse(data[2]);
            } else if (data.length == 2) {
              ret!.warnHigh = double.parse(data[1]);
            }
          }
        }
      }
    }
    return ret ?? Datapoint.empty();
  }

  String getElementSource(String label) {
    String key = '${visualLayout.toLowerCase()}.${label.toLowerCase()}';
    return elementSources[key] ?? "";
  }

  void setElementsDatapoint(String key, String label) {
    elementSources[key] = label;
  }

  void setSensorSettings(
      String sensorKey,
      String labelOverride,
      String min,
      String max,
      String mapMin,
      String mapMax,
      String warnLow,
      String warnHigh) {
    if (labelOverride.isEmpty) {
      labelOverride = sensorKey;
    }
    Datapoint datapoint = getDatapointByLabel(sensorKey);
    if (min.isEmpty) {
      min = datapoint.getDecimaled(datapoint.min);
    }
    if (max.isEmpty) {
      max = datapoint.getDecimaled(datapoint.max);
    }
    if (mapMin.isEmpty) {
      mapMin = datapoint.getDecimaled(datapoint.mapMin);
    }
    if (mapMax.isEmpty) {
      mapMax = datapoint.getDecimaled(datapoint.mapMax);
    }
    if (warnLow.isEmpty) {
      warnLow = datapoint.getDecimaled(datapoint.min);
    }
    if (warnHigh.isEmpty) {
      warnHigh = datapoint.getDecimaled(datapoint.warnHigh);
    }

    String tmp =
        "$labelOverride\t$min\t$max\t$mapMin\t$mapMax\t$warnLow\t$warnHigh";
    DLAppData.appData.sensorSettings[sensorKey.toLowerCase()] = tmp;
    datapoint.applySensorSettings(tmp);
  }

  void setElementsSource(
      String key, String? srcDatapoint, String? warnLow, String? warnHigh) {
    key = key.toLowerCase();
    String source = elementSources[key] ?? ""; // RPM or RPM,0,13000
    if (source.isEmpty) {
      return;
    }
    List<String> attributes = source.split(",");
    Datapoint datapoint = getDatapointByLabel(
        (srcDatapoint != null) ? srcDatapoint : attributes[0]);
    String newSource = "";

    newSource = datapoint
        .labelNoOverride; // We want the lookup key, not a sensor override.
    if (warnLow != null) {
      newSource += ",$warnLow";
      //datapoint.warnLow = double.parse( warnLow );
    } else {
      newSource += ',${datapoint.getDecimaled(datapoint.warnLow)}';
    }
    if (warnHigh != null) {
      newSource += ",$warnHigh";
      //datapoint.warnHigh = double.parse( warnHigh );
    } else {
      newSource += ',${datapoint.getDecimaled(datapoint.warnHigh)}';
    }
    if (elementSources[key] != newSource) {
      elementSources[key] = newSource;
      renewAccepted = true;
    }
  }

  // Gets the display name for a data point, like HIDE, BAT, or SEN1 (XYZ)
  String getDatapointDisplay(String key) {
    String ret = key;
    key = key.toLowerCase();
    if (DLAppData.appData.sensorSettings.containsKey(key)) {
      List<String> portions =
          DLAppData.appData.sensorSettings[key]!.split('\t');
      if (portions.isNotEmpty && portions[0].toLowerCase() != key) {
        // element 0 is the label
        ret = "$ret (${portions[0]})";
      }
    }
    return ret;
  }

  void updateDatapointReading(
      {required String aName, required String aStrValue}) {
    aName = aName.toLowerCase();
    if (allDatapoints.containsKey(aName)) {
      Datapoint datapoint = allDatapoints[aName]!;
      datapoint.updateReading(aStrValue);
    }
  }

  void parseValue(String value) // Parse string from ESP32 for updating value
  {
    if (datapointsWereSetup) {
      try {
        List<String> rows = value.split("\n");
        for (String r in rows) {
          if (r
              .trim()
              .isNotEmpty) {
            List<String> el = r.split(",");
            if (el.length > 3) {
              double mv = double.parse(el[3]);
              if (mv == 0) {
                el[0] = 'wtf';
              }
              updateDatapointReading(aName: el[0], aStrValue: el[1]);
            }
          }
        }
      } catch (e) {
        // For some reason, the ESP32 can send bad data.  Log then ignore it
        // In testing, it happened once after hours of continuous operation
        logIt("parseValue exception: $e");
      }
    }
  }

  Future<void> init() async {
    logIt( 'App init' );
    logIt( kDebugMode ? 'Debug mode' : 'Release mode' );
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    _appVersion = packageInfo.version;

    await store(load: true);
    packageInfo = await PackageInfo.fromPlatform();

    final deviceInfoPlugin = DeviceInfoPlugin();
    final androidInfo = await deviceInfoPlugin.androidInfo;
    osData = '${androidInfo.version.release} ${androidInfo.version.sdkInt}';
    // For development, we will leave DEBUG display
    //if( !kReleaseMode ) {
    //layoutElements['DEBUG'] = [];
    //}
  }

  Uint8List getUint8ListFromString(String str) {
    List<int> list = <int>[];
    for (var rune in str.runes) {
      list.add(rune);
    }
    return Uint8List.fromList(list);
  }

  // MG: Issue 000836: Implement Data Format feature
  void setDataFormats( Map<String, String> formats ) {
    dataFormats = formats;
    allDatapoints.forEach((String key, Datapoint datapoint) {
      datapoint.resetMinMax();
    } );
  }

  void updateDatapointFromSensors() {
    allDatapoints.forEach((String key, Datapoint datapoint) {
      key = key.toLowerCase();
      if (datapoint.isSensor()) {
        if (DLAppData.appData.sensorSettings.containsKey(key)) {
          datapoint.applySensorSettings(DLAppData.appData.sensorSettings[key]!);
          if (allBogusDatapoints.containsKey(key.toUpperCase())) {
            Datapoint? bogus = allBogusDatapoints[key.toUpperCase()];
            if (bogus != null) {
              bogus.applySensorSettings(DLAppData.appData.sensorSettings[key]!);
            }
          }
        }
      }
    });
  }

  void setupDatapoints(
      String provided) // Sets up all data points with data from ESP32
  {
    allDatapoints.clear();
    selectableDatapoints.clear();
    changeableElements.clear();
    userOnOffElements.clear();

    datapointsWereSetup = false;
    List<String> definitions = provided.split("\n");
    for (var definition in definitions) {
      if (definition.trim().isNotEmpty) {
        Datapoint newDatapoint = Datapoint.fromString(definition);
        allDatapoints[newDatapoint.label.toLowerCase()] = newDatapoint;
      }
    }
    List<String> els = layoutElements[visualLayout] ?? [];
    for (var element in els) {
      if (element.indexOf(RegExp('Mutable.', caseSensitive: false)) == 0) {
        changeableElements.add(
            element.replaceFirst(RegExp('Mutable.', caseSensitive: false), ''));
      } else if (element.indexOf(RegExp('UserOnOff.', caseSensitive: false)) ==
          0) {
        userOnOffElements.add(element);
      }
    }

    //Create list of General, then Sensor type labels, for default placement
    allDatapoints.forEach((key, candidate) {
      if (candidate.type == 'G' || candidate.type.indexOf('G.') == 0) {
        selectableDatapoints.add(candidate.label);
      }
    });
    allDatapoints.forEach((key, candidate) {
      if (candidate.isSensor()) {
        selectableDatapoints.add(candidate.label);

        if (!sensorSettings.containsKey(candidate.label.toLowerCase())) {
          sensorSettings[candidate.label.toLowerCase()] = "${candidate.label}\t"
              "${candidate.getDecimaled(candidate.min)}\t"
              "${candidate.getDecimaled(candidate.max)}\t"
              "${candidate.getDecimaled(candidate.mapMin)}\t"
              "${candidate.getDecimaled(candidate.mapMax)}\t"
              "${candidate.getDecimaled(candidate.warnLow)}\t"
              "${candidate.getDecimaled(candidate.warnHigh)}";
        }
      }
    });

    // setup default layout positions
    List<String> availableDatapoints = [];

    // Iterate all elements, for all layouts
    layoutElements.forEach((layout, elements) {
      //Create list of General, then Sensor type labels, for default placement
      availableDatapoints.clear();
      availableDatapoints.addAll(selectableDatapoints);
      availableDatapoints.remove("HIDE");

      for (String element in elements) {
        String key = '$layout.$element'.toLowerCase();

        // Find the best datpoint for the element.
        allDatapoints.forEach((datapointKey, candidate) {
          if (candidate.label.toLowerCase() ==
              element
                  .toLowerCase()) // The label matches the datapoint.  For example, 'Speed'
          {
            if (elementSources.containsKey(key) == false) {
              elementSources[key] = element;
            }
          }
        });

        if (!key.contains(".*") && elementSources.containsKey(key) == false) {
          if (key.indexOf('.useronoff.') > 0) {
            List<String> pieces = element.split('.');
            String val = pieces[1];
            String lval = val.toLowerCase();
            if (allDatapoints.containsKey(lval)) {
              Datapoint dp = allDatapoints[lval]!;
              val =
                  '$val,${dp.getDecimaled(dp.warnLow)},${dp.getDecimaled(dp.warnHigh)}';
            }
            elementSources[key] = val;
          } else if (key.indexOf('.ledstrip.') > 0) {
            // ledStripSources
            for (int i = 0; i < 5; i++) {
              String ledKey = '$layout.led$i';
              if (ledStripSources.containsKey(ledKey) == false) {
                if (availableDatapoints.isNotEmpty) {
                  String s = availableDatapoints[0].toLowerCase();
                  double gap = allDatapoints[s]!.max * 0.10;

                  availableDatapoints.removeAt(0);
                  s = '$s,${allDatapoints[s]!.warnLow + gap},${allDatapoints[s]!.warnHigh - gap}';
                  ledStripSources[ledKey] = s;
                }
              }
            }
          } else if (availableDatapoints.isNotEmpty) {
            elementSources[key] = availableDatapoints[0];
            availableDatapoints.removeAt(0);
          }
        }
      }
    });
    updateDatapointFromSensors();
    store(load: false);
    datapointsWereSetup = true;
  }

  // MG: Issue 000836: Implement Data Format feature
  // For implementing bogus conversions of units to simulate what ESP32 would do
  DatapointUnitType requestedBogusUnitType( DatapointUnitType actualType ) {
    DatapointUnitType ret = DatapointUnitType.UT_ASIS;
    if( actualType == DatapointUnitType.UT_MPH || actualType == DatapointUnitType.UT_KPH ) {
      ret =dataFormats["Speed"] == "MPH"
          ? DatapointUnitType.UT_MPH
          : DatapointUnitType.UT_KPH;
    }
    if( actualType == DatapointUnitType.UT_FAHRENHEIT || actualType == DatapointUnitType.UT_CELSIUS ) {
      ret =dataFormats["Temperature"] == "Fahrenheit"
          ? DatapointUnitType.UT_FAHRENHEIT
          : DatapointUnitType.UT_CELSIUS;
    }
    if( actualType == DatapointUnitType.UT_PSI || actualType == DatapointUnitType.UT_KPA ) {
      ret =dataFormats["Pressure"] == "PSI"
          ? DatapointUnitType.UT_PSI
          : DatapointUnitType.UT_KPA;
    }
    if( actualType == DatapointUnitType.UT_AFR || actualType == DatapointUnitType.UT_LAMBDA ) {
      ret =dataFormats["Fuel"] == "AFR"
          ? DatapointUnitType.UT_AFR
          : DatapointUnitType.UT_LAMBDA;
    }
    if( actualType == DatapointUnitType.UT_BAROCALC ) {
      ret =dataFormats["BaroCalc"] == "Y"
          ? DatapointUnitType.UT_BAROCALC
          : DatapointUnitType.UT_ASIS;
    }
    return ret;
  }

  /// getBogusData allows for Bluetooth protocol testing without physical devices
  Uint8List getBogusData(String command) {
    StringBuffer sb = StringBuffer("<<");
    if (command == "<<IDENTIFY>>") {
      bogusState = command;
      return getUint8ListFromString("<<>>");
    } else if (command.indexOf("<<SETTINGS:") == 0) {
      // MG: Issue	0000836: Implement Data Format feature
      // We don't have to do anything here, because we have access to DLAppData.appData.dataFormats where the data is stored
      // and convertUnitTypeBogus is called later
      return getUint8ListFromString("<<>>");
    } else if (command.indexOf("<<ACCEPTED:") == 0) {
      command = command.replaceAll("<<ACCEPTED:", "");
      command = command.replaceAll(">>", "").toLowerCase();
      List<String> accepted = command.split(",");
      allBogusDatapoints.forEach((String key, Datapoint datapoint) {
        datapoint.included = accepted.contains(datapoint.label.toLowerCase());
      });
      return getUint8ListFromString("<<>>");
    } else if (bogusState == "<<IDENTIFY>>") {
      sb.write("PROVIDED:\n");
      sb.write("Version:1.1.0\n");  // Bogus, but should match ESP32 code
      bogusState = '';

      // Build allBogusDatapoints from bogus arrays
      List<Datapoint> bogusSource = bogusDevice == 'HOLLEYTERMX2'
          ? datapointsHolleyDemo
          : (bogusDevice == 'HALTECH2'
              ? datapointsHalTech2Demo
              : datapointsMegasquirtDemo);
      allBogusDatapoints.clear();

      for (var i = 0; i < bogusSource.length; i++) {
        allBogusDatapoints[bogusSource[i].label] = bogusSource[i].clone();
      }
      for (var i = 0; i < datapointsCommonDemo.length; i++) {
        allBogusDatapoints[datapointsCommonDemo[i].label] =
            datapointsCommonDemo[i].clone();
      }
    } else {
      // update bogus data
      allBogusDatapoints.forEach((key, datapoint) {
        datapoint.updateBogus();
      });
    }
    // format bogus data into buffer
    DatapointUnitType requestedUnitType = DatapointUnitType.UT_ASIS;
    allBogusDatapoints.forEach((key, datapoint) {
      // Convert bogus data into desired format
      requestedUnitType = requestedBogusUnitType( datapoint.unitType );
      if( datapoint.unitType == DatapointUnitType.UT_ASIS
          || requestedUnitType == datapoint.unitType ) { // MG: Issue 000836: Implement Data Format feature
        sb.write(
            "${datapoint.labelNoOverride},${datapoint.valueStr},${datapoint.min},${datapoint.max},${datapoint.warnLow},${datapoint.warnHigh},${datapoint.type},${datapoint.startCaption},${datapoint.endCaption},${datapoint.includedStr()},${datapoint.decimals},${datapoint.unitTypeStr},${datapoint.dir}\n");
      } else { // We need to convert to requested type
        bool withBaroCalc = requestedBogusUnitType( DatapointUnitType.UT_BAROCALC ) == DatapointUnitType.UT_BAROCALC; // If user wants BaroCalc, now doBaroCalc is true
        Datapoint converted = datapoint.convertUnitTypeBogus( requestedUnitType, withBaroCalc );
        sb.write(
            "${converted.labelNoOverride},${converted.valueStr},${converted.min},${converted.max},${converted.warnLow},${converted.warnHigh},${converted.type},${converted.startCaption},${converted.endCaption},${converted.includedStr()},${converted.decimals},${converted.unitTypeStr},${converted.dir}\n");
      }
    });

    sb.write(">>");
    String bs = sb.toString();
    List<int> list = <int>[];
    for (var rune in bs.runes) {
      list.add(rune);
    }
    return Uint8List.fromList(list);
  }

  Future<void> clearConfig() async {
    newvisualLayout = "Gauges";
    visualLayout = 'Gauges';
    elementSources.clear();
    ledStripSources.clear();
    sensorSettings.clear();
    layoutBackgrounds.clear();

    allDatapoints.clear();
    selectableDatapoints.clear();
    changeableElements.clear();
    userOnOffElements.clear();
    warningLights.clear();
    allBogusDatapoints.clear();

    await store(load: false);

    await init();
    wasCleared = true;
  }

  Future<void> clearBackgrounds() async {
    List<String> keepFiles = [];
    layoutBackgrounds.forEach((String layout, String file) {
      if (file.isNotEmpty) {
        keepFiles.add(file);
      }
    });

    final Directory appDocDir = await getApplicationDocumentsDirectory();
    final String backgroundPath = p.join(appDocDir.path, 'backgrounds');

    final dir = Directory(backgroundPath);

    if (!await dir.exists()) {
      return;
    }
    final files = dir.listSync().whereType<File>();

    for (final file in files) {
      final filename = file.path;
      if (!keepFiles.contains(filename)) {
        try {
          await file.delete();
        } catch (e) {
          // Ignore for now
        }
      }
    }
  }

  Future<void> store({bool load = false}) async {
    String dataVersion = '1.1';
    errorString = "";
    storeBusy = true;

    try {
      final prefs = await SharedPreferences.getInstance();
      if (load) {
        // Implement version # for stored data
        String dataVersionStored = prefs.getString('dataVersion') ?? '1.0';

        await lastConnectedDevice.store('last', prefs, load);
        visualLayout = prefs.getString('visualLayout') ??
            layoutElements.keys.toList().first;
        if( layoutElements.containsKey(visualLayout) == false )
        { // If using a removed layout
          visualLayout = layoutElements .keys.toList().first;
        }
        newvisualLayout = visualLayout;
        if (visualLayout == 'DEBUG' && !layoutElements.containsKey("DEBUG")) {
          DLAppData.appData.layoutElements['DEBUG'] =
              []; // If we closed in debug, make sure it's added
        }
        String jsonelementSources = prefs.getString('elementSources') ?? '';
        elementSources.clear();
        if (jsonelementSources.isNotEmpty) {
          elementSources.addAll(Map.castFrom(jsonDecode(jsonelementSources)));
        }
        String jsonledStripSources = prefs.getString('ledStripSources') ?? '';
        ledStripSources.clear();
        if (jsonledStripSources.isNotEmpty) {
          // Kludge: Force outdated Yellow color to red:
          jsonledStripSources =
              jsonledStripSources.replaceFirst(",Yellow", ",Red");
          ledStripSources.addAll(Map.castFrom(jsonDecode(jsonledStripSources)));
        }

        String jsonSensorSettings = prefs.getString('sensorSettings') ?? '';
        sensorSettings.clear();
        if (jsonSensorSettings.isNotEmpty) {
          sensorSettings.addAll(Map.castFrom(jsonDecode(jsonSensorSettings)));

          if (dataVersionStored == '1.0') {
            // from 1.0 to 1.1, sensorSettings needs mapMin and mapMax
            sensorSettings.forEach((String key, String value) {
              List<String> portions = value.split("\t");
              portions.insert(3, '0');
              portions.insert(4, '0');
              sensorSettings[key] = portions.join('\t');
            });
          }
        }

        String jsonlayoutBackgrounds =
            prefs.getString('layoutBackgrounds') ?? '';
        sensorSettings.clear();
        if (jsonlayoutBackgrounds.isNotEmpty) {
          layoutBackgrounds
              .addAll(Map.castFrom(jsonDecode(jsonlayoutBackgrounds)));
        }

        String jsonDataFormats = prefs.getString('dataFormats') ?? '';

        if (jsonDataFormats.isNotEmpty && jsonDataFormats != '{}') {
          setDataFormats( Map.castFrom(jsonDecode(jsonDataFormats)) );
        }

        String jsonWarningLights = prefs.getString('warningLights') ?? ''; // MG: Issue 0000839: Implement Warning Lights config screen with new UI
        if (jsonWarningLights.isNotEmpty && jsonWarningLights != '{}') {
          warningLights = Map.castFrom(jsonDecode(jsonWarningLights));
        }
        if( warningLights.isEmpty )
        {
          warningLights.addAll( {
            "Oil Temp." : "",
            "Shift" : "",
            "Oil Press." : "",
            "Fuel PSI" : "",
            "Volts" : "",
            "Boost" : "",
            "Coolant" : "",
            "AFR" : "",
          }
          );
        }

        updateDatapointFromSensors();
      } else {
        // It's a save
        await prefs.setString('dataVersion', dataVersion);
        await lastConnectedDevice.store('last', prefs, load);
        await prefs.setString('visualLayout', visualLayout);
        await prefs.setString('elementSources', jsonEncode(elementSources));
        await prefs.setString('ledStripSources', jsonEncode(ledStripSources));
        await prefs.setString('sensorSettings', jsonEncode(sensorSettings));
        await prefs.setString(
            'layoutBackgrounds', jsonEncode(layoutBackgrounds));
        await prefs.setString('dataFormats', jsonEncode(dataFormats));
        await prefs.setString('warningLights', jsonEncode(warningLights));
      }
    } catch (error) {
      errorString = error.toString();
    }
    storeBusy = false;
  }

  List<String> getAllDatapointLabels() {
    List<String> ret = [];
    allDatapoints.forEach((String key, Datapoint datapoint) {
      ret.add(datapoint.labelNoOverride);
    });
    return ret;
  }

  List<String> getLayoutsOrdered() {
    List<String> ret = [];
    layoutElements.forEach((key, val) {
      if (key != visualLayout) {
        ret.add(key);
      }
    });
    ret.sort();
    layoutElements.forEach((key, val) {
      if (key == visualLayout) {
        ret.insert(0, key);
      }
    });
    return ret;
  }

  String joinDataFormats() {
    String ret="";
    // Settings must be in the format "key1:value1\nkey2:value2\n...keyn:valuen\n"
    dataFormats.forEach((String key, String value) {
      ret += "$key:$value\n";
    });
    return ret;
  }

  double getWarningLights( String label, double defaultWarnHigh ) // MG: Issue 0000839: Implement Warning Lights config screen with new UI
  {
    double ret = defaultWarnHigh;
    // Does label match to one of the warningLights?  If so, return users value
    warningLightLabelToDatapoint.forEach((String key, String value ) {
      if( value == label )
      {
        String s = warningLights[key] ?? "";
        if( s.isNotEmpty )
        {
          ret = double.parse( s );
        }
      }
    });
    return ret;
  }

  // MG: Issue 0000840: Copy setting between Visual Layouts
  void copySettings( String oldVisualLayout, String newVisualLayout )
  {
    // elementSources
    // "gauges.speed" : "Speed"
    String search = '${newVisualLayout.toLowerCase()}.';
    String replace = '${oldVisualLayout.toLowerCase()}.';
    for (var key in elementSources.keys) {
      if( key.indexOf( search ) == 0 )
      {
        String sourceKey = key.replaceFirst( search, replace);
        if( (elementSources[ sourceKey ]?? '' ) != '' ) {
          elementSources[ key ] = elementSources[ sourceKey ]!;
        }
      }
    }

    // ledStripSources
    // "Gauges.led0" : "tmg,30.0,270.0",
    search = '$newVisualLayout.';
    replace = '$oldVisualLayout.';
    for (var key in ledStripSources.keys) {
      if( key.indexOf( search ) == 0 )
      {
        String sourceKey = key.replaceFirst( search, replace);
        if( (ledStripSources[ sourceKey ]?? '' ) != '' ) {
          ledStripSources[ key ] = ledStripSources[ sourceKey ]!;
        }
      }
    }

    if( layoutBackgrounds.containsKey( oldVisualLayout ) ) {
      layoutBackgrounds[ newVisualLayout ] = layoutBackgrounds[oldVisualLayout]!;
    } else {
      layoutBackgrounds[ newVisualLayout ] = '';
    }
  }
}
