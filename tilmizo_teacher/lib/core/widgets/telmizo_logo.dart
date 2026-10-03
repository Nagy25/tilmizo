import 'package:core_package/core_package.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../generated/locale_keys.g.dart';

/// The Telmizo Teacher brand mark, painted from the Stitch logo SVG.
class TelmizoLogo extends StatelessWidget {
  const TelmizoLogo({super.key, this.size = 40});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      image: true,
      label: LocaleKeys.logo_semantics.tr(),
      child: SizedBox.square(
        dimension: size,
        child: const CustomPaint(painter: _LogoPainter()),
      ),
    );
  }
}

class _LogoPainter extends CustomPainter {
  const _LogoPainter();

  @override
  void paint(Canvas canvas, Size size) {
    // Coordinates follow the 120×120 source viewBox.
    canvas.scale(size.width / 120, size.height / 120);

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(0, 0, 120, 120),
        const Radius.circular(28),
      ),
      Paint()..color = TelmizoColors.brandNavy,
    );

    final teal = Paint()..color = TelmizoColors.brandTeal;
    canvas.drawPath(
      Path()
        ..moveTo(60, 28)
        ..lineTo(88, 42)
        ..lineTo(60, 56)
        ..lineTo(32, 42)
        ..close(),
      teal,
    );

    final white = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(
      Path()
        ..moveTo(88, 42)
        ..lineTo(88, 62)
        ..cubicTo(88, 62, 82, 72, 60, 76)
        ..cubicTo(38, 72, 32, 62, 32, 62)
        ..lineTo(32, 42),
      white,
    );
    canvas.drawLine(const Offset(60, 56), const Offset(60, 76), white);

    final amber = Paint()
      ..color = TelmizoColors.brandAmber
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(
      Path()
        ..moveTo(88, 45)
        ..lineTo(96, 52)
        ..lineTo(96, 68),
      amber,
    );
    canvas.drawCircle(
      const Offset(96, 70),
      3,
      Paint()..color = TelmizoColors.brandAmber,
    );
    canvas.drawCircle(const Offset(60, 92), 4, teal);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
