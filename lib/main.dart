import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => BleProvider()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'BLE Scanner',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
        ),
        home: const MyHomePage(),
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.lightBlue,
        title: const Text("BLE SCANNER"),
      ),
      body: Consumer<BleProvider>(
        builder: (context, controller, child) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                // Toggle Button for Scanning
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      " Available Devices: ",
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                    Switch(
                      value: controller.isScanning,
                      onChanged: (value) async {
                        await controller.toggleScan();
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Show CircularProgressIndicator when scanning
                controller.isScanning
                    ? const CircularProgressIndicator()
                    : controller.scanResults.isEmpty
                        ? const Center(child: Text("No Device Found"))
                        : Expanded(
                            child: ListView.builder(
                              shrinkWrap: true,
                              itemCount: controller.scanResults.length,
                              itemBuilder: (context, index) {
                                final data = controller.scanResults[index];
                                // Calculate distance from RSSI

                                return Container(
                                  margin: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(15),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.2),
                                        blurRadius: 5,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: ListTile(
                                      title: Text(data.device.advName.isEmpty
                                          ? "Unknown Device"
                                          : data.device.advName),
                                      subtitle:
                                          Text(data.device.remoteId.toString()),
                                      //   trailing: Text(
                                      //    '${distance.toStringAsFixed(2)} m'), // Show distance in meters
                                      onTap: () {}),
                                );
                              },
                            ),
                          ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class BleProvider with ChangeNotifier {
  List<ScanResult> _scanResults = [];
  bool _isScanning = false;
  bool _isBluetoothOn = false; // Track Bluetooth state

  List<ScanResult> get scanResults => _scanResults;
  bool get isScanning => _isScanning;
  bool get isBluetoothOn => _isBluetoothOn; // Expose Bluetooth state

  // Request Bluetooth permissions
  Future<void> _requestBluetoothPermissions() async {
    await Permission.bluetoothScan.request();
    await Permission.bluetoothConnect.request();
    await Permission.location.request();
  }

  // Start BLE scan
  Future<void> startScan() async {
    await _requestBluetoothPermissions();

    // Check if Bluetooth is enabled
    final isOn = await FlutterBluePlus.isOn;
    if (!isOn) {
      print("Bluetooth is not enabled");
      return;
    }

    _isScanning = true;
    _scanResults.clear();
    notifyListeners();

    print("Starting BLE scan...");
    FlutterBluePlus.startScan(timeout: const Duration(seconds: 30));

    FlutterBluePlus.scanResults.listen((results) {
      if (results.isNotEmpty) {
        print('Found ${results.length} devices');
      } else {
        print('No devices found during scan.');
      }
      _scanResults.addAll(results); // Add new results to the existing list
      notifyListeners();
    });

    await Future.delayed(const Duration(seconds: 30));
    stopScan();
  }

  // Stop BLE scan
  void stopScan() {
    FlutterBluePlus.stopScan();
    _isScanning = false;
    notifyListeners();
  }

  // Toggle BLE scanning
  Future<void> toggleScan() async {
    if (_isScanning) {
      stopScan();
    } else {
      // Check if Bluetooth is off, and turn it on
      if (!_isBluetoothOn) {
        await toggleBluetooth(true); // Turn Bluetooth ON
      }
      await startScan();
    }
  }

  // Toggle Bluetooth state
  Future<void> toggleBluetooth(bool value) async {
    if (value) {
      await FlutterBluePlus.turnOn(); // Turn Bluetooth on
      _isBluetoothOn = true;
      print("Bluetooth turned ON");
    } else {
      await FlutterBluePlus.turnOff(); // Turn Bluetooth off
      _isBluetoothOn = false;
      print("Bluetooth turned OFF");
    }
    notifyListeners();
  }
}
