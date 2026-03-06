import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: BasculaPage(),
    );
  }
}

class BasculaPage extends StatefulWidget {
  const BasculaPage({super.key});

  @override
  State<BasculaPage> createState() => _BasculaPageState();
}

class _BasculaPageState extends State<BasculaPage> {
  double pesoKg = 0.0;

  @override
  void initState() {
    super.initState();
    pedirPermisos();
  }

  Future<void> pedirPermisos() async {
    await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.location,
    ].request();

    iniciarScan();
  }

  void iniciarScan() async {
    // iniciar escaneo BLE
    FlutterBluePlus.startScan(timeout: const Duration(minutes: 1));

    FlutterBluePlus.scanResults.listen((results) {
      for (ScanResult r in results) {
        // FILTRO POR MAC
        if (r.device.remoteId.str != "24:16:51:9D:DE:4F") {
          continue;
        }

        procesarManufacturerData(r.advertisementData.manufacturerData);
      }
    });
  }

  void procesarManufacturerData(Map<int, List<int>> data) {
    if (data.isEmpty) return;

    final bytes = data.values.first;

    print("=================================");
    print("BYTES RECIBIDOS (${bytes.length})");

    // imprimir cada byte con su posición
    for (int i = 0; i < bytes.length; i++) {
      print("byte[$i] = ${bytes[i]}");
    }

    // probar combinaciones posibles de 2 bytes
    for (int i = 0; i < bytes.length - 1; i++) {
      int bigEndian = (bytes[i] << 8) | bytes[i + 1];
      int littleEndian = (bytes[i + 1] << 8) | bytes[i];

      print("pos[$i-$i+1]  bigEndian=$bigEndian  littleEndian=$littleEndian");
    }

    // lectura actual de peso
    if (bytes.length >= 2) {
      int rawWeight = (bytes[0] << 8) | bytes[1];
      double nuevoPeso = rawWeight / 100.0;

      print("PESO DETECTADO: $nuevoPeso kg");

      setState(() {
        pesoKg = nuevoPeso;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Báscula BLE")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "${pesoKg.toStringAsFixed(2)} kg",
              style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
