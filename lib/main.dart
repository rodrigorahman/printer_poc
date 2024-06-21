// ignore_for_file: depend_on_referenced_packages

import 'dart:async';
import 'dart:developer';
import 'dart:ui';


import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_thermal_printer/flutter_thermal_printer.dart';
import 'package:flutter_thermal_printer/utils/printer.dart';

// import 'package:another_brother/printer_info.dart' as brother;
import 'dart:ui' as ui;


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
    ''
    ^XA~TA000~JSN^LT0^MNW^MTT^PON^PMN^LH0,0^JMA^PR6,6~SD15^JUS^LRN^CI0^XZ
    ^XA
    ^MMT
    ^PW400
    ^LL0600
    ^LS0
    ^FT0,50^A0N,25,24^FB111,1,0,C^FH^FDEtiquetando^FS
    ^FT0,80^A@N,25,24,TT0003M_^FB394,1,0,C^FH^CI17^F8^FDEtiquetando^FS^CI0
    ^PQ1,0,1,Y^XZ
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
 Future<ui.Image> loadImage(String path) async {
    final ByteData data = await rootBundle.load(path);
    final Completer<ui.Image> completer = Completer();
    ui.decodeImageFromList(data.buffer.asUint8List(), (ui.Image img) {
      completer.complete(img);
    });
    return completer.future;
  }
Future<void> _printLabel() async {
    try {
        const platform = MethodChannel('com.example.brother_printer');

//       final result = await platform.invokeMethod('printLabel', {
//         'text': '''
// Line 1: Até que enfim
// Line 2:Conseguimos 
// imprimir 
// na Brother
// Etiquetando
// ''',
//       });

      // print(result);

      var imageBytes = await (await loadImage('assets/etiquetando.png')).toByteData(format: ImageByteFormat.png);
      
      var outByteArray = Uint8List(imageBytes!.lengthInBytes);
      for (int i = 0; i < imageBytes.lengthInBytes; i ++) {
        outByteArray[i] = imageBytes.getUint8(i);
      }

      final result = await platform.invokeMethod('printImage', {
        'image': outByteArray,
      });
      
    } on PlatformException catch (e) {
      print("Failed to print label: '${e.message}'.");
    }
  }
//   Future<void> printerBrother() async {
//     final printer = brother.Printer();
//     var printInfo = brother.PrinterInfo();
//     printInfo.printerModel = brother.Model.QL_810W;
//     // printInfo.printMode = brother.PrintMode.FIT_TO_PAGE;
//     // printInfo.isAutoCut = true;
//     printInfo.port = brother.Port.USB;
//     //printInfo.paperSize = brother.PaperSize.CUSTOM;
//     //printInfo.labelNameIndex = QL700.ordinalFromID(QL700.W62.getId());


    

//     // Set the printer info so we can use the SDK to get the printers.
//     await printer.setPrinterInfo(printInfo);
    
//     // final image = await loadImage('assets/x.png');
//     // printer.printImage(image);
// final paragraphStyle = ui.ParagraphStyle(
//     textAlign: TextAlign.left,
//     fontSize: 14.0,
//     fontWeight: FontWeight.normal,
//   );

//   final paragraphBuilder = ui.ParagraphBuilder(paragraphStyle)
//     ..addText('batata');

//   const constraints = ui.ParagraphConstraints(width: 200.0);

//   final paragraph = paragraphBuilder.build()
//     ..layout(constraints);
    
//     final status = await printer.printText(paragraph);
//     print('status::::: $status');
//   }

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
          //printerBrother();
          _printLabel();
          //printZebra();
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
