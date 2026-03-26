class BodyImpedance {
  final double rightHand1;
  final double leftHand1;
  final double trunk1;
  final double rightFoot1;
  final double leftFoot1;
  final double rightHand2;
  final double leftHand2;
  final double trunk2;
  final double rightFoot2;
  final double leftFoot2;

  const BodyImpedance({
    required this.rightHand1,
    required this.leftHand1,
    required this.trunk1,
    required this.rightFoot1,
    required this.leftFoot1,
    required this.rightHand2,
    required this.leftHand2,
    required this.trunk2,
    required this.rightFoot2,
    required this.leftFoot2,
  });

  List<double> toList() {
    return [
      rightHand1,
      leftHand1,
      trunk1,
      rightFoot1,
      leftFoot1,
      rightHand2,
      leftHand2,
      trunk2,
      rightFoot2,
      leftFoot2,
    ];
  }
}
