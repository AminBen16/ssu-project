import 'package:flutter/material.dart';

class DashboardItem {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  DashboardItem({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });
}
