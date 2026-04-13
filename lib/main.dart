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

  UserProfile({required this.edad, required this.altura, required this.hombre});
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
  double masaMuscularKg;
  double aguaKg;
  double pesoSinGrasa;
  double gradoObesidad;
  int edadReal;
  double alturaCm;

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
  // NUEVOS
  required this.masaMuscularKg,
  required this.aguaKg,
  required this.pesoSinGrasa,
  required this.gradoObesidad,
  required this.edadReal,
  required this.alturaCm,
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

  final user = UserProfile(edad: 26, altura: 170, hombre: true);

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
      hexString = bytes
          .map((b) => b.toRadixString(16).padLeft(2, '0'))
          .join(" ");

      metrics = calcularTodo(peso: pesoKg, impedancia: impedancia, user: user);
    });
  }

  // ================= ALGORITMOS =================

  // BMI
  double calcularBMI(double peso, double altura) {
    return peso / ((altura / 100) * (altura / 100));
  }

  double masaLibre({
    required double peso,
    required double altura,
    required double impedancia,
    required bool hombre,
  }) {
    double coef = hombre ? 0.407 : 0.252;
    double coefAltura = hombre ? 0.267 : 0.473;

    return (coef * peso) +
        (coefAltura * (altura * altura / impedancia)) +
        (hombre ? 0.095 : 0.0) -
        4.0;
  }

  // Grasa corporal usando BIA
  double grasaCorporalBIA({
    required double peso,
    required double altura,
    required double impedancia,
    required int edad,
    required bool hombre,
  }) {
    double sexo = hombre ? 1 : 0;
    double grasa =
        (0.3 * peso) +
        (0.15 * (altura * altura / impedancia)) +
        (0.1 * edad) -
        (8 * sexo) -
        10;
    return grasa;
  }

  double ajustarGrasa(double grasaRaw) {
    return (grasaRaw * 1.85).clamp(5, 60);
  }

  double agua(double masaLibre, double peso) {
    return (masaLibre * 0.73 / peso) * 100;
  }

  // Masa muscular (no es igual a masa libre de grasa)
  double masaMuscular(double masaLibre) {
    return masaLibre * 0.55;
  }

  double grasaCorporal(double peso, double masaLibre) {
    return ((peso - masaLibre) / peso) * 100;
  }

  // Grasa visceral
  double grasaVisceral(double grasa, int edad) {
    return ((grasa * 0.8) + (edad * 0.2)).clamp(1, 30);
  }

  // Metabolismo
  double metabolismo(double peso, double altura, int edad, bool hombre) {
    if (hombre) {
      return 10 * peso + 6.25 * altura - 5 * edad + 5;
    } else {
      return 10 * peso + 6.25 * altura - 5 * edad - 161;
    }
  }

  // Masa ósea
  double masaOsea(double masaLibre) {
    return masaLibre * 0.06;
  }

  // Proteína
  double proteina(double masaLibre, double peso) {
    return (masaLibre * 0.20 / peso) * 100;
  }

  // Edad metabólica
  double edadMetabolica(double bmr, int edad) {
    return (edad + ((bmr - 1400) / 80)).clamp(10, 80);
  }

  BodyMetrics calcularTodo({
    required double peso,
    required double impedancia,
    required UserProfile user,
  }) {
    final bmi = calcularBMI(peso, user.altura);

    // 🔥 BASE REAL
    final masaLibreVal = masaLibre(
      peso: peso,
      altura: user.altura,
      impedancia: impedancia,
      hombre: user.hombre,
    );

    final grasa = grasaCorporal(peso, masaLibreVal);

    // 🔥 DERIVADOS CORRECTOS
    final aguaVal = agua(masaLibreVal, peso);
    final musculoKg = masaMuscular(masaLibreVal);
    final musculoPorc = (musculoKg / peso) * 100;

    final visceral = grasaVisceral(grasa, user.edad);
    final bmr = metabolismo(peso, user.altura, user.edad, user.hombre);
    final hueso = masaOsea(masaLibreVal);
    final prot = proteina(masaLibreVal, peso);
    final edadMeta = edadMetabolica(bmr, user.edad);

    final aguaKg = (aguaVal / 100) * peso;
    final pesoSinGrasaVal = masaLibreVal;
    final gradoOb = ((peso - (22 * (user.altura / 100) * (user.altura / 100))) / (22 * (user.altura / 100) * (user.altura / 100))) * 100;

    return BodyMetrics(
      peso: peso,
      bmi: bmi,
      grasa: grasa,
      masaMuscular: musculoPorc,
      agua: aguaVal,
      grasaVisceral: visceral,
      hueso: hueso,
      metabolismo: bmr,
      proteina: prot,
      edadMetabolica: edadMeta,

      masaMuscularKg: musculoKg,
      aguaKg: aguaKg,
      pesoSinGrasa: pesoSinGrasaVal,
      gradoObesidad: gradoOb,
      edadReal: user.edad,
      alturaCm: user.altura,
    );
  }

  // ================= UI =================

  Widget card(String titulo, String valor) {
    return Card(
      child: ListTile(
        title: Text(titulo),
        trailing: Text(
          valor,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Báscula BLE")),
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
              card("Músculo (%)", metrics!.masaMuscular.toStringAsFixed(1)),
              card("Grasa visceral", metrics!.grasaVisceral.toStringAsFixed(1)),
              card("Hueso (kg)", metrics!.hueso.toStringAsFixed(1)),
              card("Metabolismo (kcal)", metrics!.metabolismo.toStringAsFixed(0)),
              card("Proteína (%)", metrics!.proteina.toStringAsFixed(1)),
              card("Edad metabólica", metrics!.edadMetabolica.toStringAsFixed(1)),

              card("Músculo (kg)", metrics!.masaMuscularKg.toStringAsFixed(1)),
              card("Agua (kg)", metrics!.aguaKg.toStringAsFixed(1)),
              card("Peso sin grasa", metrics!.pesoSinGrasa.toStringAsFixed(1)),
              card("Grado de obesidad %", metrics!.gradoObesidad.toStringAsFixed(1)),
              card("Edad real", metrics!.edadReal.toString()),
              card("Altura (cm)", metrics!.alturaCm.toStringAsFixed(0)),
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
