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

class UserProfile {
  int edad;
  double altura;
  bool hombre;

  UserProfile({
    required this.edad,
    required this.altura,
    required this.hombre,
  });
}

class BodyMetrics {
  double peso;
  double bmi;
  double grasa;
  double masaMuscular;
  double agua;
  double grasaVisceral;
  double hueso;
  double metabolismo;
  double proteina;
  double edadMetabolica;

  BodyMetrics({
    required this.peso,
    required this.bmi,
    required this.grasa,
    required this.masaMuscular,
    required this.agua,
    required this.grasaVisceral,
    required this.hueso,
    required this.metabolismo,
    required this.proteina,
    required this.edadMetabolica,
  });
}

class BasculaPage extends StatefulWidget {
  const BasculaPage({super.key});

  @override
  State<BasculaPage> createState() => _BasculaPageState();
}

class _BasculaPageState extends State<BasculaPage> {
  double pesoKg = 0;
  double impedancia = 0;

  BodyMetrics? metrics;

  String hexString = "";
  List<int> ultimoPaquete = [];

  final user = UserProfile(
    edad: 25,
    altura: 170,
    hombre: true,
  );

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

  void iniciarScan() {
    FlutterBluePlus.startScan(timeout: const Duration(minutes: 10));

    FlutterBluePlus.scanResults.listen((results) {
      for (ScanResult r in results) {
        if (r.device.remoteId.str != "24:16:51:9D:DE:4F") continue;

        procesarManufacturerData(r.advertisementData.manufacturerData);
      }
    });
  }

  void procesarManufacturerData(Map<int, List<int>> data) {
    if (data.isEmpty) return;

    final bytes = data.values.first;

    if (bytes.length < 8) return;

    final rawWeight = (bytes[0] << 8) | bytes[1];
    final peso = rawWeight / 100.0;

    final rawImp = (bytes[6] << 8) | bytes[7];
    final imp = rawImp / 10.0;

    setState(() {
      pesoKg = peso;
      impedancia = imp;
      ultimoPaquete = bytes;
      hexString = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join(" ");

      metrics = calcularTodo(
        peso: pesoKg,
        impedancia: impedancia,
        user: user,
      );
    });
  }

  // ================= ALGORITMOS =================

  double calcularBMI(double peso, double altura) {
    return peso / ((altura / 100) * (altura / 100));
  }

  double grasaCorporal(double bmi, int edad, bool hombre) {
    double sexo = hombre ? 1 : 0;
    return (1.2 * bmi) + (0.23 * edad) - (10.8 * sexo) - 5.4;
  }

  double agua(double grasa) => 100 - grasa;

  double masaMuscular(double peso, double grasa) {
    return peso * (1 - grasa / 100);
  }

  double grasaVisceral(double bmi, int edad) {
    return (bmi * 0.5) + (edad * 0.1);
  }

  double metabolismo(double peso, double altura, int edad, bool hombre) {
    if (hombre) {
      return 10 * peso + 6.25 * altura - 5 * edad + 5;
    } else {
      return 10 * peso + 6.25 * altura - 5 * edad - 161;
    }
  }

  double masaOsea(double peso) => peso * 0.04;

  double proteina(double masaMuscular) => masaMuscular * 0.2;

  double edadMetabolica(double bmr, int edad) {
    return edad + ((bmr - 1500) / 100);
  }

  BodyMetrics calcularTodo({
    required double peso,
    required double impedancia,
    required UserProfile user,
  }) {
    final bmi = calcularBMI(peso, user.altura);
    final grasa = grasaCorporal(bmi, user.edad, user.hombre);
    final aguaVal = agua(grasa);
    final musculo = masaMuscular(peso, grasa);
    final visceral = grasaVisceral(bmi, user.edad);
    final bmr = metabolismo(peso, user.altura, user.edad, user.hombre);
    final hueso = masaOsea(peso);
    final prot = proteina(musculo);
    final edadMeta = edadMetabolica(bmr, user.edad);

    return BodyMetrics(
      peso: peso,
      bmi: bmi,
      grasa: grasa,
      masaMuscular: musculo,
      agua: aguaVal,
      grasaVisceral: visceral,
      hueso: hueso,
      metabolismo: bmr,
      proteina: prot,
      edadMetabolica: edadMeta,
    );
  }

  // ================= UI =================

  Widget card(String titulo, String valor) {
    return Card(
      child: ListTile(
        title: Text(titulo),
        trailing: Text(valor, style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Báscula estilo OKOK")),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: ListView(
          children: [
            Text(
              "${pesoKg.toStringAsFixed(2)} kg",
              style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold),
            ),
            Text("Impedancia: ${impedancia.toStringAsFixed(0)} Ω"),

            const SizedBox(height: 10),

            if (metrics != null) ...[
              card("BMI", metrics!.bmi.toStringAsFixed(1)),
              card("Grasa corporal %", metrics!.grasa.toStringAsFixed(1)),
              card("Agua %", metrics!.agua.toStringAsFixed(1)),
              card("Músculo (kg)", metrics!.masaMuscular.toStringAsFixed(1)),
              card("Grasa visceral", metrics!.grasaVisceral.toStringAsFixed(1)),
              card("Hueso (kg)", metrics!.hueso.toStringAsFixed(1)),
              card("Metabolismo (kcal)", metrics!.metabolismo.toStringAsFixed(0)),
              card("Proteína", metrics!.proteina.toStringAsFixed(1)),
              card("Edad metabólica", metrics!.edadMetabolica.toStringAsFixed(1)),
            ],

            const SizedBox(height: 20),

            const Text("Paquete BLE"),
            Container(
              color: Colors.black,
              padding: const EdgeInsets.all(10),
              child: Text(
                hexString,
                style: const TextStyle(color: Colors.green),
              ),
            ),
          ],
        ),
      ),
    );
  }
}