import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;
import 'package:drivelogic/app_data.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';

/*
Copyright 2021 Mario Giannini

Permission is hereby granted, free of charge, to any person obtaining a copy of this
 software and associated documentation files (the “Software”), to deal in the Software
 without restriction, including without limitation the rights to use, copy, modify, merge,
 publish, distribute, sublicense, and/or sell copies of the Software, and to permit
 persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or
substantial portions of the Software.

THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING
BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

See MG64Bluetooth._emulating for debugging and emulation
*/

enum MG64BluetoothDeviceType { unknown, classic, le, dual }
enum MG64BluetoothBondingState {unknown, none, bonding, bonded }

class MG64BluetoothDevice
{
  String name='';
  String address='';
  MG64BluetoothDeviceType type = MG64BluetoothDeviceType.unknown;
  bool isConnected = false;
  MG64BluetoothBondingState bondState = MG64BluetoothBondingState.none;
  int signalStrength=0;

  MG64BluetoothDevice({
    required this.name,
    required this.address,
    required this.type,
    required this.isConnected,
    required this.bondState,
    required this.signalStrength
  });

  Future<void> store( String prefix, SharedPreferences prefs, load ) async {
    if( load ){
      String gen;
      name = prefs.getString( '${prefix}_MG64BluetoothDevice.name')??'';
      address = prefs.getString( '${prefix}_MG64BluetoothDevice.address')??'';
      gen = prefs.getString( '${prefix}_MG64BluetoothDevice.type') ?? 'unknown';
      type = gen == 'dual' ?  MG64BluetoothDeviceType.dual : (gen == 'classic' ?  MG64BluetoothDeviceType.classic : (gen == 'le' ?  MG64BluetoothDeviceType.le : (MG64BluetoothDeviceType.unknown)));
      isConnected = false;
      gen = prefs.getString( '${prefix}_MG64BluetoothDevice.bondState') ?? 'unknown';
      bondState = gen == 'bonded' ?  MG64BluetoothBondingState.bonded : (gen == 'bonding' ?  MG64BluetoothBondingState.bonding : (gen == 'none' ?  MG64BluetoothBondingState.none : (MG64BluetoothBondingState.unknown)));
      signalStrength = prefs.getInt( '${prefix}_MG64BluetoothDevice.signalStrength') ?? 0;
    }   else
    {
      await prefs.setString( '${prefix}_MG64BluetoothDevice.name', name);
      await prefs.setString( '${prefix}_MG64BluetoothDevice.address',address);
      if( type == MG64BluetoothDeviceType.dual) {
        await prefs.setString( '${prefix}_MG64BluetoothDevice.type', 'dual');
      } else if( type == MG64BluetoothDeviceType.classic) {
        await prefs.setString( '${prefix}_MG64BluetoothDevice.type', 'classic');
      } else if( type == MG64BluetoothDeviceType.le) {
        await prefs.setString( '${prefix}_MG64BluetoothDevice.type', 'le');
      } else{
      await prefs.setString( '${prefix}_MG64BluetoothDevice.type', 'unknown');
      }
      if( bondState == MG64BluetoothBondingState.bonded) {
      await prefs.setString( '${prefix}_MG64BluetoothDevice.bondState', 'bonded');
      } else if( bondState == MG64BluetoothBondingState.bonding) {
      await prefs.setString( '${prefix}_MG64BluetoothDevice.bondState', 'bonding');
      } else if( bondState == MG64BluetoothBondingState.none) {
      await prefs.setString( '${prefix}_MG64BluetoothDevice.bondState', 'none');
      } else{
      await prefs.setString( '${prefix}_MG64BluetoothDevice.bondState', 'unknown');
      }
      signalStrength = prefs.getInt( '${prefix}_MG64BluetoothDevice.signalStrength') ?? 0;
    }
  }
}

MG64BluetoothDevice emptyMG64BluetoothDevice()
{
  return MG64BluetoothDevice(
    address: '',
    name: '',
    type: MG64BluetoothDeviceType.unknown,
    isConnected: false,
    bondState: MG64BluetoothBondingState.unknown,
    signalStrength: 0
  );
}

typedef OnMG64BluetoothNotify = void Function(MG64Bluetooth bt, MG64BluetoothNotify notfication);
enum MG64BluetoothNotify { discoveryDone, dataReceived, connected, disconnected, error }

class MG64Bluetooth {
  bool _emulating = false; // Enable emulation (set to true in emulators in init()
  String _error="";
  String get error => _error;

  // Delay debugging
  int longestDelay = 0;
  int shortestDelay = 999999999999999;
  int averageDelay = 0;
  int totalCalls = 0;
  int totalTicks = 0;
  int lastTick = 0;
  int resetTick = 0;


  bool _initialized = false, _initializing = false;
  bool get initialized => _initialized;

  PermissionStatus _permissionLocationStatus = PermissionStatus.denied;
  PermissionStatus get permissionLocationStatus => _permissionLocationStatus;
  PermissionStatus _permissionBluetoothConnectStatus = PermissionStatus.denied;
  PermissionStatus get permissionBluetoothStatus => _permissionBluetoothConnectStatus;
  PermissionStatus _permissionBluetoothConnect = PermissionStatus.denied;
  PermissionStatus get permissionBluetoothConnect => _permissionBluetoothConnect;
  PermissionStatus _permissionBluetoothScan = PermissionStatus.denied;
  PermissionStatus get permissionBluetoothScan => _permissionBluetoothScan;
  bool get permitted => (_permissionLocationStatus == PermissionStatus.granted || _permissionLocationStatus == PermissionStatus.limited || _permissionLocationStatus == PermissionStatus.restricted );

  final String _address = "";
  String get address => _address;
  final String _name = "";
  String get name => _name;

  String _desiredDevice="";

  BluetoothState _bluetoothState = BluetoothState.UNKNOWN;
  BluetoothState get bluetoothState => _bluetoothState;

  bool _isDiscovering = true;
  bool get isDiscovering => _isDiscovering;

  bool _isConnecting = false;
  bool get isConnecting => _isConnecting;
  bool _isDisconnecting = false;
  bool get isDisconnecting => _isDisconnecting;
  bool get isConnected {
    if( _bogusConnected ) {
      return true;
    }
    if( _connectionSerial == null ) {
      return false;
    } else {
      //_connectionSerial!.output.allSent;
      return _connectionSerial!.isConnected;
    }
  }

  bool _bogusConnected = false;
  Uint8List Function( String )? _bogusData;
  Timer? _emulatingTimer;

  final StreamController<List<int>> _dataStreamController = StreamController<List<int>>();
  Stream<List<int>> get dataStream => _dataStreamController.stream;

  //final BytesBuilder _readBuffer = BytesBuilder();
  String blockBuffer = "";

  BluetoothConnection? _connectionSerial;

  List<MG64BluetoothDevice> devicesList =
  List<MG64BluetoothDevice>.empty(growable: true);

  Timer? _discoverableTimeoutTimer;
  Timer? get discoverableTimeoutTimer => _discoverableTimeoutTimer;
  int _discoverableTimeoutSecondsLeft = 0;
  int get discoverableTimeoutSecondsLeft => _discoverableTimeoutSecondsLeft;

  //BackgroundCollectingTask? _collectingTask;
  //bool _autoAcceptPairingRequests = false;
  StreamSubscription<BluetoothDiscoveryResult>? _streamSubscription;

  Function(MG64Bluetooth,MG64BluetoothNotify)? _onBluetoothNotify;

  void dispose() {
    _emulatingTimer?.cancel();
    _dataStreamController.close();
  }

  Future<void> init( [bool dialogIfNeeded = true , String deviceName="", OnMG64BluetoothNotify? onBluetoothNotify, MG64BluetoothDevice? lastConnectedDevice ] ) async
  {
    if( ! kReleaseMode  ) {
      DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
      if (Platform.isAndroid) {
        AndroidDeviceInfo info = await deviceInfo.androidInfo;
        _emulating = !info.isPhysicalDevice;
      }
      if (Platform.isIOS) {
        IosDeviceInfo osInfo = await deviceInfo.iosInfo;
        _emulating = !osInfo.isPhysicalDevice;
      }
    }
    // _emulating = true; // Maybe you want to force emulation even in release mode?
    _onBluetoothNotify = onBluetoothNotify;
    _desiredDevice = deviceName;
    _initialized = false;
    if( _initializing == false ) {
      _initializing = true;
      _permissionLocationStatus = await Permission.location.status;
      _permissionBluetoothConnectStatus = await Permission.bluetooth.status;
      _permissionBluetoothConnectStatus = await Permission.bluetoothConnect.status;
      _permissionBluetoothScan = await Permission.bluetoothScan.status;

      if (_permissionBluetoothConnectStatus.isDenied ) {
        _permissionBluetoothConnectStatus = await Permission.bluetooth.request();
      }
      if ( _permissionLocationStatus.isDenied ) {
        _permissionLocationStatus = await Permission.location.request();
      }
      if ( _permissionBluetoothConnect.isDenied ) {
        _permissionBluetoothConnect = await Permission.bluetoothConnect.request();
      }
      if (_permissionBluetoothScan.isDenied ) {
        _permissionBluetoothScan = await Permission.bluetoothScan.request();
      }

      if((_permissionLocationStatus.isGranted || _permissionLocationStatus.isLimited )
          && (_permissionBluetoothConnectStatus.isGranted || _permissionBluetoothConnectStatus.isLimited )
          && (_permissionBluetoothScan.isGranted || _permissionBluetoothScan.isLimited )
          && (_permissionBluetoothConnect.isGranted || _permissionBluetoothConnect.isLimited ) ) {
        try {
          await _initBluetooth(lastConnectedDevice);
        } catch( e ) {
          rethrow;
        }
      }

      if (await Permission.location.status.isPermanentlyDenied
          || await Permission.bluetoothConnect.isPermanentlyDenied
          || await Permission.bluetooth.isPermanentlyDenied) {
        if( dialogIfNeeded ) {
          openAppSettings();
        }
      }
      _initialized = true;
      _initializing = false;
    }
  }

  _initBluetooth( MG64BluetoothDevice? lastConnectedDevice  ) async{
    _error = '';
    // Get current state
    if( !_emulating ) {
      FlutterBluetoothSerial.instance.state.then((state) {
        _bluetoothState = state;
      });

      // Listen for further state changes
      FlutterBluetoothSerial.instance
          .onStateChanged()
          .listen((BluetoothState state) {
        _bluetoothState = state;
        // Discoverable mode is disabled when Bluetooth gets disabled
        _discoverableTimeoutTimer = null;
        _discoverableTimeoutSecondsLeft = 0;
      });
    }

    if( lastConnectedDevice != null && lastConnectedDevice.address.isNotEmpty ) {
      connect( lastConnectedDevice, DLAppData.appData.getBogusData );
    } else {
      _startDiscovery( );
    }
  }

  void _startDiscovery( ) {
    if( _emulating ) // Debugging, should not be in production
    {
      _isDiscovering = true;
      String desired = ( _desiredDevice.isEmpty) ? 'Emulating' : _desiredDevice;

      final MG64BluetoothDevice myres = MG64BluetoothDevice(
          name: desired,
          address: "00:01:02:03",
          type: MG64BluetoothDeviceType.unknown,
          isConnected: false,
          bondState: MG64BluetoothBondingState.unknown,
          signalStrength: 1
      );
      devicesList.add(myres);
      _isDiscovering = false;
      if( _onBluetoothNotify != null ) {
        _onBluetoothNotify!(this, MG64BluetoothNotify.discoveryDone );
      }
      return;
    }

    _isDiscovering = true;
    _streamSubscription =
      FlutterBluetoothSerial.instance.startDiscovery().listen((r) {
          MG64BluetoothDevice myres = MG64BluetoothDevice(
              name: r.device.name ?? "",
              address: r.device.address,
              type:
              (r.device.type == BluetoothDeviceType.unknown ? MG64BluetoothDeviceType.unknown :
                (r.device.type == BluetoothDeviceType.classic ? MG64BluetoothDeviceType.classic :
                  (r.device.type == BluetoothDeviceType.le ? MG64BluetoothDeviceType.le :
                    (r.device.type == BluetoothDeviceType.dual ? MG64BluetoothDeviceType.dual : MG64BluetoothDeviceType.unknown )
                  )
                )
              ),
              isConnected: r.device.isConnected,
              bondState:
              (r.device.bondState == BluetoothBondState.bonded ? MG64BluetoothBondingState.bonded :
                (r.device.bondState == BluetoothBondState.bonding ? MG64BluetoothBondingState.bonding :
                  (r.device.bondState == BluetoothBondState.none ? MG64BluetoothBondingState.none : MG64BluetoothBondingState.unknown )
                )
              ),
              signalStrength: r.rssi
          );

          if( _desiredDevice.isEmpty || myres.name == _desiredDevice ) {

            final existingIndex = devicesList.indexWhere(
                    (element) =>
                element.address == myres.address);

            if (existingIndex >= 0) {
              devicesList[existingIndex] = myres;
            } else {
              devicesList.add(myres);
            }
          }
        }
      );
      _streamSubscription!.onDone(() {
      _isDiscovering = false;
      if( _onBluetoothNotify != null ) {
        _onBluetoothNotify!(this, MG64BluetoothNotify.discoveryDone );
      }
    });
  }

  Future<void> writeString( String str ) async
  {
    if( isConnected  && !_emulating && _connectionSerial != null ) {
      int started = DateTime.now().millisecondsSinceEpoch;
      _connectionSerial!.output.add(Uint8List.fromList(utf8.encode("$str\r\n")));
      await _connectionSerial!.output.allSent;
      int stopped = DateTime.now().millisecondsSinceEpoch;
      int duration = stopped - started;
      if( duration < 0  ) {
        _emulating = true;
      }
    } else if( _emulating && _bogusData != null ) {
      _bogusData!(str);
    }
  }

  int resetSeconds() {
    if( resetTick == 0 ) {
      return 10;
    }
    int i = resetTick - DateTime.now().millisecondsSinceEpoch;
    if( i < 0 ) {
      i = 0;
    }
    return ( i / 1000.0).ceil();
  }

  void _onDataReceived(Uint8List data) {
    //_dataStreamController.add(data.toList());
    //_readBuffer.add( data );

    int thisTick = DateTime.now().millisecondsSinceEpoch;
    if( lastTick > 0 )
    {
      int dif = thisTick - lastTick;
      if( dif > 0 ) {
        if( dif > longestDelay ) {
          longestDelay = dif;
        }
        if( dif < shortestDelay ) {
          shortestDelay = dif;
        }
      }
      totalCalls++;
      totalTicks += dif;
      averageDelay = (totalTicks / totalCalls ).round();
    }
    else {
      resetTick = thisTick + 10000;
    }
    lastTick = thisTick;
    if(thisTick > resetTick )
    {
      resetTick = thisTick + 5000;
      longestDelay = 0;
      shortestDelay = 999999999999999;
      averageDelay = 0;
      totalCalls = 0;
      totalTicks = 0;
      lastTick = 0;
    }


    blockBuffer += String.fromCharCodes(data);
    if( _onBluetoothNotify != null ) {
      _onBluetoothNotify!(this, MG64BluetoothNotify.dataReceived );
    }
  }

  String readBlockString({String startBlock = "<<", String endBlock = ">>" }) {
//    blockBuffer += readBufferString();
    blockBuffer =  blockBuffer.replaceAll("<<>>", "");
    int startPos = blockBuffer.indexOf(startBlock);
    if (startPos >= 0) {
      int endPos = blockBuffer.indexOf(endBlock, startPos);
      if ( endPos > startPos + startBlock.length) {
        String ret = blockBuffer.substring(
            startPos + startBlock.length, endPos );
        blockBuffer = blockBuffer.substring(endPos + endBlock.length);
        return ret;
      }
    }
    return "";
  }

  // String readBufferString()
  // {
  //   String ret = "";
  //   while( _readBuffer.isNotEmpty )
  //   {
  //     ret += String.fromCharCodes( _readBuffer.takeBytes() );
  //   }
  //   return ret;
  // }

  Future<void> disconnect( ) async {
    if( isConnected ) {
      _isDisconnecting = true;
      _bogusConnected = false;
      if( !_emulating && _connectionSerial != null ) {
        _connectionSerial!.close();
      }
    }
  }

  Future<void> connect( MG64BluetoothDevice device,  Uint8List Function( String )? bogusData ) async {
    if( _emulating ) {
      _isConnecting = false;
      _isDisconnecting = false;
      _isDiscovering = false;
      _bogusConnected = true;
      _bogusData = bogusData;
      _onBluetoothNotify!(this, MG64BluetoothNotify.connected );
      _emulatingTimer = Timer.periodic( const Duration( milliseconds: 10 ), (Timer t) {
        if( _bogusData != null ) {
          _onDataReceived( _bogusData!( "" ));
        }
      });
    }
    else {
      BluetoothConnection.toAddress(device.address).then((connection) {
        // print('Connected to the device');
        _connectionSerial = connection;
        _isConnecting = false;
        _isDisconnecting = false;
        _isDiscovering = false;
        _onBluetoothNotify!(this, MG64BluetoothNotify.connected );

        _connectionSerial!.input!.listen(_onDataReceived,
            onDone: () {
              if (isDisconnecting) {
                // print('Disconnecting locally!');
                _connectionSerial = null;
                _isDisconnecting = false;
              } else {
                _connectionSerial = null;
                _isDisconnecting = false;
                // print('Disconnected remotely!');
              }
              _onBluetoothNotify!(this, MG64BluetoothNotify.disconnected );
            } );

      }).catchError((error) {
        _error = error.code;
        if( _error.toLowerCase().compareTo('connect_error') == 0 ) {
          _error = 'Connect error';
        }
        _onBluetoothNotify!(this, MG64BluetoothNotify.error );
        // print('Cannot connect, exception occurred');
        //print(error);
      });
    }
  }

/*
  void _restartDiscovery() {
    devicesList.clear();
    isDiscovering = true;
    _startDiscovery();
  }

 */
}