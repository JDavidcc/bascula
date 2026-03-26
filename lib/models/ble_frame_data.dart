import 'body_impedance.dart';

class BleFrameData {
  final int header;
  final List<int> rawBytes;
  final double? pesoKg;
  final double? impedancia;
  final List<double> impedanciasSegmentadas;
  final BodyImpedance? bodyImpedance;
  final String? remark;

  const BleFrameData({
    required this.header,
    required this.rawBytes,
    this.pesoKg,
    this.impedancia,
    this.impedanciasSegmentadas = const [],
    this.bodyImpedance,
    this.remark,
  });
}
