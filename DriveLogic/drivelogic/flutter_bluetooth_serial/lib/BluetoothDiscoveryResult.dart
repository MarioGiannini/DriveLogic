// ignore_for_file: file_names, use_string_in_part_of_directives

part of flutter_bluetooth_serial;

class BluetoothDiscoveryResult {
  final BluetoothDevice device;
  final int rssi;

  BluetoothDiscoveryResult({
    required this.device,
    this.rssi = 0,
  });

  factory BluetoothDiscoveryResult.fromMap(Map map) {
    return BluetoothDiscoveryResult(
      device: BluetoothDevice.fromMap(map),
      rssi: map['rssi'] ?? 0,
    );
  }
}
