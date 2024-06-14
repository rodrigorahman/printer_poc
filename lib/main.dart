// ignore_for_file: depend_on_referenced_packages

import 'dart:async';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_thermal_printer/flutter_thermal_printer.dart';
import 'package:flutter_thermal_printer/utils/printer.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _flutterThermalPrinterPlugin = FlutterThermalPrinter.instance;

  List<Printer> bleDevices = [];

  StreamSubscription<List<Printer>>? _devicesStreamSubscription;

  Future<void> startScan() async {
    try {
      await _flutterThermalPrinterPlugin.startScan();
      _devicesStreamSubscription =
          _flutterThermalPrinterPlugin.devicesStream.listen((event) {
        setState(() {
          bleDevices = event.map((e) => Printer.fromJson(e.toJson())).toList();
          bleDevices.removeWhere(
            (element) => element.name == null || element.name!.isEmpty,
          );
        });
      });
    } catch (e) {
      log('Failed to start scanning for devices $e');
    }
  }

  // Stop scanning for BLE devices
  Future<void> stopScan() async {
    try {
      _devicesStreamSubscription?.cancel();
      await _flutterThermalPrinterPlugin.stopScan();
    } catch (e) {
      log('Failed to stop scanning for devices $e');
    }
  }

  Future<void> printZebra() async {
    String data;
    data = '''
    ^XA
^FX Top section with logo, name and address.
^CF0,60
^FO50,50^GB100,100,100^FS
^FO75,75^FR^GB100,100,100^FS
^FO93,93^GB40,40,40^FS
^FO220,50^FDIntershipping, Inc.^FS
^CF0,30
^FO220,115^FD1000 Shipping Lane^FS
^FO220,155^FDShelbyville TN 38102^FS
^FO220,195^FDUnited States (USA)^FS
^FO50,250^GB700,3,3^FS

^FX Second section with recipient address and permit information.
^CFA,30
^FO50,300^FDJohn Doe^FS
^FO50,340^FD100 Main Street^FS
^FO50,380^FDSpringfield TN 39021^FS
^FO50,420^FDUnited States (USA)^FS
^CFA,15
^FO600,300^GB150,150,3^FS
^FO638,340^FDPermit^FS
^FO638,390^FD123456^FS
^FO50,500^GB700,3,3^FS

^FX Third section with bar code.
^BY5,2,270
^FO100,550^BC^FD12345678^FS

^FX Fourth section (the two boxes on the bottom).
^FO50,900^GB700,250,3^FS
^FO400,900^GB3,250,3^FS
^CF0,40
^FO100,960^FDCtr. X34B-1^FS
^FO100,1010^FDREF1 F00B47^FS
^FO100,1060^FDREF2 BL4H8^FS
^CF0,190
^FO470,955^FDCA^FS

^XZ
        ''';
    await _flutterThermalPrinterPlugin.printData(
      bleDevices[0],
      Uint8List.fromList(data.codeUnits),
      longData: true,
    );
  }

  @override
  void initState() {
    super.initState();
    // _devicesStreamSubscription = _flutterThermalPrinterPlugin.devicesStream
    //     .listen((List<Printer> event) {
    //   log(event.map((e) => e.name).toList().toString());
    //   setState(() {
    //     printers = event;
    //     printers.removeWhere((element) =>
    //         element.name == null ||
    //         element.name == '' ||
    //         !element.name!.toLowerCase().contains('print'));
    //   });
    // });
  }

  void getUsbDevices() async {
    await _flutterThermalPrinterPlugin.getUsbDevices();
    _devicesStreamSubscription?.cancel();
    _devicesStreamSubscription =
        _flutterThermalPrinterPlugin.devicesStream.listen((event) {
      setState(() {
        // printers = event;
        setState(() {
          bleDevices = event.map((e) => Printer.fromJson(e.toJson())).toList();
          bleDevices.removeWhere(
            (element) => element.name == null || element.name!.isEmpty,
          );
        });
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
          systemOverlayStyle: const SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
          ),
        ),
        body: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                //startScan();
                getUsbDevices();
              },
              child: const Text('Get Printers'),
            ),
            ElevatedButton(
              onPressed: () {
                startScan();
              },
              child: const Text('Bluetooth'),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: bleDevices.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    onTap: () async {
                      if (bleDevices[index].isConnected ?? false) {
                        await _flutterThermalPrinterPlugin
                            .disconnect(bleDevices[index]);
                      } else {
                        final isConnected = await _flutterThermalPrinterPlugin
                            .connect(bleDevices[index]);
                        log("Devices: $isConnected");
                      }
                    },
                    title: Text(bleDevices[index].name ?? 'No Name'),
                    subtitle: Text(
                        "VendorId: ${bleDevices[index].address} - Connected: ${bleDevices[index].isConnected}"),
                    trailing: IconButton(
                      icon: const Icon(Icons.connect_without_contact),
                      onPressed: () async {
                        final profile = await CapabilityProfile.load();
                        final generator = Generator(PaperSize.mm58, profile);
                        String tsplCommand = '''
CLS
SIZE 60 mm, 40 mm
GAP 1.5 mm, 0 mm
DENSITY 5
SPEED 1
SET TEAR ON
DIRECTION 0
REFERENCE 0,0
TEXT 60,0,"ARIAL.TTF",0,1,1,"TEXTO COM ARIAL"
BARCODE 60,100,"128",100,1,0,2,4,"1234567890"
TEXT 60,250,"TSS24.BF2",0,1,1,"TEXTO NORMAL"
PRINT 1
  ''';
                        // BARCODE 180,200,"128",100,1,0,2,4,"1234567890"
                        await _flutterThermalPrinterPlugin.printData(
                          bleDevices[index],
                          generator.textEncoded(
                              Uint8List.fromList(tsplCommand.codeUnits)),
                          longData: true,
                        );
                        print('Imprimiu');
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(onPressed: () {
          printZebra();
        }),
      ),
    );
  }

  Widget receiptWidget() {
    return Container(
        padding: const EdgeInsets.all(8),
        color: Colors.white,
        width: 300,
        height: 300,
        child: const Center(
          child: Column(
            children: [
              Text(
                "FLUTTER THERMAL PRINTER",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              SizedBox(height: 10),
              Text(
                "Hello World",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              SizedBox(height: 10),
              Text(
                "This is a test receipt",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ],
          ),
        ));
  }
}
