import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';

import 'algorithms/body_metrics_calculator.dart';
import 'models/ble_frame_data.dart';
import 'models/body_impedance.dart';
import 'models/body_metrics.dart';
import 'models/user_profile.dart';
import 'parsers/ble_frame_parser.dart';

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
  static const String targetMac = '24:16:51:9D:DE:4F';
  static const UserProfile defaultProfile = UserProfile(
    edad: 30,
    altura: 170,
    hombre: true,
  );

  final BleFrameParser parser = const BleFrameParser();

  double pesoKg = 0.0;
  double impedancia = 0.0;
  double biIndex = 0.0;
  double conductividad = 0.0;
  double indiceCorporal = 0.0;

  List<int> ultimoPaquete = [];
  List<double> impedanciasSegmentadas = [];
  BodyImpedance? bodyImpedance;
  BodyMetrics? bodyMetrics;
  String hexString = '';
  String estadoConexion = 'Buscando bascula...';
  String ultimoFrame = '-';
  String remark = '';

  StreamSubscription<List<ScanResult>>? scanSubscription;

  @override
  void initState() {
    super.initState();
    pedirPermisos();
  }

  @override
  void dispose() {
    scanSubscription?.cancel();
    FlutterBluePlus.stopScan();
    super.dispose();
  }

  String bytesToHex(List<int> bytes) {
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ');
  }

  Future<void> pedirPermisos() async {
    try {
      await [
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
        Permission.location,
      ].request();

      await iniciarScan();
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        estadoConexion = 'BLE no disponible en este entorno: $e';
      });
    }
  }

  Future<void> iniciarScan() async {
    scanSubscription?.cancel();

    if (!mounted) {
      return;
    }

    setState(() {
      estadoConexion = 'Escaneando anuncios BLE...';
    });

    await FlutterBluePlus.startScan(timeout: const Duration(minutes: 10));

    scanSubscription = FlutterBluePlus.scanResults.listen((results) {
      for (final result in results) {
        if (result.device.remoteId.str != targetMac) {
          continue;
        }

        final manufacturerData = result.advertisementData.manufacturerData;
        if (manufacturerData.isEmpty) {
          continue;
        }

        procesarAdvertisement(result);
      }
    });
  }

  void procesarAdvertisement(ScanResult result) {
    final manufacturerData = result.advertisementData.manufacturerData;

    for (final entry in manufacturerData.entries) {
      final bytes = entry.value;
      if (bytes.isEmpty) {
        continue;
      }

      procesarFrame(bytes);
    }

    if (!mounted) {
      return;
    }

    setState(() {
      estadoConexion =
          'Leyendo advertisementData de ${result.device.remoteId.str} (RSSI ${result.rssi})';
    });
  }

  void procesarFrame(List<int> bytes) {
    final frame = parser.parse(bytes);
    if (frame == null) {
      return;
    }

    setState(() {
      ultimoPaquete = List<int>.from(frame.rawBytes);
      hexString = bytesToHex(frame.rawBytes);
      ultimoFrame = '0x${frame.header.toRadixString(16).toUpperCase()}';
    });

    _aplicarFrame(frame);
  }

  void _aplicarFrame(BleFrameData frame) {
    setState(() {
      if (frame.pesoKg != null) {
        pesoKg = frame.pesoKg!;
      }

      if (frame.impedancia != null) {
        impedancia = frame.impedancia!;
      }

      if (frame.impedanciasSegmentadas.isNotEmpty) {
        impedanciasSegmentadas = frame.impedanciasSegmentadas;
      }

      if (frame.bodyImpedance != null) {
        bodyImpedance = frame.bodyImpedance;
      }

      if (frame.remark != null && frame.remark!.isNotEmpty) {
        remark = frame.remark!;
      }

      recalcularIndices();
      recalcularMetricas();
    });
  }

  void recalcularIndices() {
    if (impedancia == 0) {
      biIndex = 0;
      conductividad = 0;
      indiceCorporal = 0;
      return;
    }

    biIndex = pesoKg / impedancia;
    conductividad = 1 / impedancia;
    indiceCorporal = (pesoKg * 1000) / impedancia;
  }

  void recalcularMetricas() {
    if (pesoKg <= 0 || impedancia <= 0) {
      bodyMetrics = null;
      return;
    }

    bodyMetrics = BodyMetricsCalculator.calcularTodo(
      peso: pesoKg,
      impedancia: impedancia,
      user: defaultProfile,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bascula BLE')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(estadoConexion),
            Text('Ultimo frame: $ultimoFrame'),
            if (remark.isNotEmpty) Text('Remark: $remark'),
            const SizedBox(height: 12),
            Text(
              '${pesoKg.toStringAsFixed(2)} kg',
              style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold),
            ),
            Text('Impedancia: ${impedancia.toStringAsFixed(0)} ohm'),
            Text('Indice de Bioimpedancia: ${biIndex.toStringAsFixed(3)}'),
            Text('Conductividad: ${conductividad.toStringAsFixed(5)}'),
            Text('Indice corporal: ${indiceCorporal.toStringAsFixed(1)}'),
            if (bodyMetrics != null) ...[
              const SizedBox(height: 16),
              _MetricsGrid(metrics: bodyMetrics!),
            ],
            if (impedanciasSegmentadas.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Impedancias segmentadas: '
                  '${impedanciasSegmentadas.map((v) => v.toStringAsFixed(1)).join(', ')}',
                ),
              ),
            if (bodyImpedance != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Segmentos: RH1 ${bodyImpedance!.rightHand1.toStringAsFixed(1)}, '
                  'LH1 ${bodyImpedance!.leftHand1.toStringAsFixed(1)}, '
                  'TR1 ${bodyImpedance!.trunk1.toStringAsFixed(1)}, '
                  'RF1 ${bodyImpedance!.rightFoot1.toStringAsFixed(1)}, '
                  'LF1 ${bodyImpedance!.leftFoot1.toStringAsFixed(1)}',
                ),
              ),
            const SizedBox(height: 20),
            const Text(
              'Paquete BLE (HEX)',
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
                  fontFamily: 'monospace',
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Bytes individuales',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: ultimoPaquete.length,
                itemBuilder: (context, index) {
                  final byte = ultimoPaquete[index];

                  return ListTile(
                    title: Text('Byte [$index]'),
                    subtitle: Text('Decimal: $byte'),
                    trailing: Text(
                      '0x${byte.toRadixString(16).padLeft(2, '0')}',
                      style: const TextStyle(fontFamily: 'monospace'),
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

class _MetricsGrid extends StatelessWidget {
  final BodyMetrics metrics;

  const _MetricsGrid({required this.metrics});

  @override
  Widget build(BuildContext context) {
    final items = <_MetricItem>[
      _MetricItem('BMI', metrics.bmi.toStringAsFixed(1)),
      _MetricItem('Grasa', '${metrics.grasa.toStringAsFixed(1)} %'),
      _MetricItem('Musculo', '${metrics.masaMuscular.toStringAsFixed(1)} kg'),
      _MetricItem('Agua', '${metrics.agua.toStringAsFixed(1)} %'),
      _MetricItem('Visceral', metrics.grasaVisceral.toStringAsFixed(1)),
      _MetricItem('Hueso', '${metrics.hueso.toStringAsFixed(1)} kg'),
      _MetricItem('BMR', metrics.metabolismo.toStringAsFixed(0)),
      _MetricItem('Proteina', '${metrics.proteina.toStringAsFixed(1)} kg'),
      _MetricItem(
        'Edad metabolica',
        metrics.edadMetabolica.toStringAsFixed(1),
      ),
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: items
          .map(
            (item) => SizedBox(
              width: 150,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        item.label,
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.value,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _MetricItem {
  final String label;
  final String value;

  const _MetricItem(this.label, this.value);
}
