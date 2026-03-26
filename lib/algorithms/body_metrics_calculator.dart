import '../models/body_metrics.dart';
import '../models/user_profile.dart';

class BodyMetricsCalculator {
  static double calcularBMI(double peso, double altura) {
    return peso / ((altura / 100) * (altura / 100));
  }

  static double grasaCorporal(double bmi, int edad, bool hombre) {
    final sexo = hombre ? 1 : 0;
    return (1.2 * bmi) + (0.23 * edad) - (10.8 * sexo) - 5.4;
  }

  static double agua(double grasa) {
    return 100 - grasa;
  }

  static double masaMuscular(double peso, double grasa) {
    return peso * (1 - grasa / 100);
  }

  static double grasaVisceral(double bmi, int edad) {
    return (bmi * 0.5) + (edad * 0.1);
  }

  static double metabolismo(
    double peso,
    double altura,
    int edad,
    bool hombre,
  ) {
    if (hombre) {
      return 10 * peso + 6.25 * altura - 5 * edad + 5;
    }

    return 10 * peso + 6.25 * altura - 5 * edad - 161;
  }

  static double masaOsea(double peso) {
    return peso * 0.04;
  }

  static double proteina(double masaMuscular) {
    return masaMuscular * 0.2;
  }

  static double edadMetabolica(double bmr, int edad) {
    return edad + ((bmr - 1500) / 100);
  }

  static BodyMetrics calcularTodo({
    required double peso,
    required double impedancia,
    required UserProfile user,
  }) {
    if (peso <= 0 || impedancia <= 0) {
      return const BodyMetrics(
        peso: 0,
        bmi: 0,
        grasa: 0,
        masaMuscular: 0,
        agua: 0,
        grasaVisceral: 0,
        hueso: 0,
        metabolismo: 0,
        proteina: 0,
        edadMetabolica: 0,
      );
    }

    final bmi = calcularBMI(peso, user.altura);
    final grasa = grasaCorporal(bmi, user.edad, user.hombre).clamp(0.0, 75.0);
    final aguaVal = agua(grasa).clamp(0.0, 100.0);
    final musculo = masaMuscular(peso, grasa).clamp(0.0, peso);
    final visceral = grasaVisceral(bmi, user.edad).clamp(0.0, 60.0);
    final bmr = metabolismo(peso, user.altura, user.edad, user.hombre);
    final hueso = masaOsea(peso).clamp(0.0, peso);
    final prot = proteina(musculo).clamp(0.0, peso);
    final edadMeta = edadMetabolica(bmr, user.edad).clamp(0.0, 120.0);

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
}
