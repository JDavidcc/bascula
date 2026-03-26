import '../models/ble_frame_data.dart';
import '../models/body_impedance.dart';

class BleFrameParser {
  const BleFrameParser();

  BleFrameData? parse(List<int> bytes) {
    if (bytes.isEmpty) {
      return null;
    }

    final header = bytes.first;
    switch (header) {
      case 0xC4:
        return _parseC4(bytes);
      case 0xC5:
        return _parseRemarkFrame(bytes);
      case 0xC8:
        return _parseRemarkFrame(bytes);
      case 0xCB:
        return _parseCB(bytes);
      default:
        return BleFrameData(header: header, rawBytes: List<int>.from(bytes));
    }
  }

  BleFrameData? _parseC4(List<int> b) {
    if (b.length < 10) {
      return null;
    }

    final rawWeight = (b[7] << 8) | b[6];
    final rawImpedance = (b[9] << 8) | b[8];

    return BleFrameData(
      header: b.first,
      rawBytes: List<int>.from(b),
      pesoKg: rawWeight / 100.0,
      impedancia: rawImpedance / 10.0,
    );
  }

  BleFrameData _parseRemarkFrame(List<int> b) {
    final header = b.first.toRadixString(16).toUpperCase();
    return BleFrameData(
      header: b.first,
      rawBytes: List<int>.from(b),
      remark: '$header|${_bytesToHex(b)}',
    );
  }

  BleFrameData? _parseCB(List<int> b) {
    if (b.length < 10) {
      return null;
    }

    final valores = parseImpedancias(b);
    final bodyImpedance =
        valores.length >= 10 ? mapearImpedancias(valores) : null;

    return BleFrameData(
      header: b.first,
      rawBytes: List<int>.from(b),
      impedanciasSegmentadas: valores,
      bodyImpedance: bodyImpedance,
      remark: 'CB|${valores.map((v) => v.toStringAsFixed(1)).join(",")}',
    );
  }

  List<double> parseImpedancias(List<int> b) {
    final valores = <double>[];

    for (int i = 9; i < b.length; i += 2) {
      final raw = (b[i] << 8) | b[i - 1];
      valores.add(raw * 0.1);
    }

    return valores;
  }

  BodyImpedance mapearImpedancias(List<double> r) {
    return BodyImpedance(
      rightHand1: r[0],
      leftHand1: r[1],
      trunk1: r[4],
      rightFoot1: r[2],
      leftFoot1: r[3],
      rightHand2: r[5],
      leftHand2: r[6],
      trunk2: r[9],
      rightFoot2: r[7],
      leftFoot2: r[8],
    );
  }

  String _bytesToHex(List<int> bytes) {
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ');
  }
}
