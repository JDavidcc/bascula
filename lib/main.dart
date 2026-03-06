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
  double impedancia = 0;

  double biIndex = 0;
  double conductividad = 0;
  double indiceCorporal = 0;

  List<int> ultimoPaquete = [];
  String hexString = "";

  String bytesToHex(List<int> bytes) {
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join(" ");
  }

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

    setState(() {
      ultimoPaquete = bytes;
      hexString = bytesToHex(bytes);
    });

    // lectura del peso
    if (bytes.length >= 2) {
      int rawWeight = (bytes[0] << 8) | bytes[1];
      double peso = rawWeight / 100.0;
      // IMPEDANCIA
      int rawImpedancia = (bytes[6] << 8) | bytes[7];
      double imp = rawImpedancia / 10.0;

      if (imp == 0) return;

      setState(() {
        pesoKg = peso;
        impedancia = imp;

        biIndex = peso / imp;
        conductividad = 1 / imp;
        indiceCorporal = (peso * 1000) / imp;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Báscula BLE")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "${pesoKg.toStringAsFixed(2)} kg",
              style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold),
            ),
            Text("Impedancia: ${impedancia.toStringAsFixed(0)} Ω"),

            Text("Índice de Bioimpedancia (BI) Index: ${biIndex.toStringAsFixed(3)}"),
            
            //  La conductividad eléctrica es el inverso de la resistencia
            Text("Conductividad: ${conductividad.toStringAsFixed(5)}"),
            
            //  Otra forma de visualizar cambios (Es muy sensible a los cambios de impedancia)
            Text("Índice corporal: ${indiceCorporal.toStringAsFixed(1)}"),

            const SizedBox(height: 20),

            const Text(
              "Paquete BLE (HEX)",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),

            Container(
              padding: const EdgeInsets.all(10),
              color: Colors.black,
              width: double.infinity,
              child: Text(
                hexString,
                style: const TextStyle(
                  color: Colors.green,
                  fontFamily: "monospace",
                ),
              ),
            ),

            const SizedBox(height: 20),

            const Text(
              "Bytes individuales",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),

            Expanded(
              child: ListView.builder(
                itemCount: ultimoPaquete.length,
                itemBuilder: (context, index) {
                  int byte = ultimoPaquete[index];

                  return ListTile(
                    title: Text("Byte [$index]"),
                    subtitle: Text("Decimal: $byte"),
                    trailing: Text(
                      "0x${byte.toRadixString(16).padLeft(2, '0')}",
                      style: const TextStyle(fontFamily: "monospace"),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
