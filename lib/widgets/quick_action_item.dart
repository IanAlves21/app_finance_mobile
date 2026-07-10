import 'package:flutter/material.dart';
import 'interactive_card.dart';

class QuickActionItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color bg;
  final Color iconColor;
  final Color textColor;
  final VoidCallback onTap;

  const QuickActionItem({
    super.key,
    required this.icon,
    required this.label,
    required this.bg,
    required this.iconColor,
    required this.textColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InteractiveCard(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: textColor,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
