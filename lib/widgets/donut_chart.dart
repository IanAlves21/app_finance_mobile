import 'dart:math' as math;
import 'package:flutter/material.dart';

class DonutChartSection {
  final double percentage; // Valor entre 0.0 e 1.0
  final Color color;

  DonutChartSection({
    required this.percentage,
    required this.color,
  });
}

class DonutChart extends StatelessWidget {
  final List<DonutChartSection> sections;
  final double strokeWidth;

  const DonutChart({
    super.key,
    required this.sections,
    this.strokeWidth = 12.0,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(100, 100),
      painter: _DonutChartPainter(
        sections: sections,
        strokeWidth: strokeWidth,
      ),
    );
  }
}

class _DonutChartPainter extends CustomPainter {
  final List<DonutChartSection> sections;
  final double strokeWidth;

  _DonutChartPainter({
    required this.sections,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double radius = math.min(size.width, size.height) / 2;
    final Offset center = Offset(size.width / 2, size.height / 2);
    
    final Paint bgPaint = Paint()
      ..color = Colors.grey.withValues(alpha: 0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
      
    // Desenha o trilho circular de fundo
    canvas.drawCircle(center, radius - strokeWidth / 2, bgPaint);

    if (sections.isEmpty) return;

    double startAngle = -math.pi / 2; // Começa no topo (12 horas)

    for (final section in sections) {
      if (section.percentage <= 0) continue;
      
      final double sweepAngle = section.percentage * 2 * math.pi;
      
      final Paint sectionPaint = Paint()
        ..color = section.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      // Espaço/gap sutil entre as fatias se houver mais de uma
      final double finalSweep = sections.length > 1 ? sweepAngle - 0.05 : sweepAngle;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius - strokeWidth / 2),
        startAngle + 0.025,
        finalSweep.clamp(0.0, 2 * math.pi),
        false,
        sectionPaint,
      );

      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutChartPainter oldDelegate) {
    return oldDelegate.sections != sections || oldDelegate.strokeWidth != strokeWidth;
  }
}
