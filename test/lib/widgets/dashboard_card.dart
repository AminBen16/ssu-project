import 'package:flutter/material.dart';

/// A reusable card widget for dashboard items.
class DashboardCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;
  final String? highlightQuery;

  const DashboardCard({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
    this.highlightQuery,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cardColor = color ?? theme.colorScheme.primary;

    Widget buildLabel() {
      final style = (theme.textTheme.titleSmall ?? const TextStyle()).copyWith(
        color: Colors.white,
      );

      if (highlightQuery == null ||
          highlightQuery!.isEmpty ||
          !label.toLowerCase().contains(highlightQuery!.toLowerCase())) {
        return Text(
          label,
          textAlign: TextAlign.center,
          style: style,
        );
      }

      final highlightStyle = style.copyWith(
        backgroundColor: Colors.yellow.shade700,
        color: Colors.black,
        fontWeight: FontWeight.bold,
      );

      final spans = <TextSpan>[];
      int start = 0;
      final query = highlightQuery!.toLowerCase();
      final lowerCaseLabel = label.toLowerCase();

      while (start < label.length) {
        final matchIndex = lowerCaseLabel.indexOf(query, start);
        if (matchIndex == -1) {
          spans.add(TextSpan(text: label.substring(start), style: style));
          break;
        }

        if (matchIndex > start) {
          spans.add(
              TextSpan(text: label.substring(start, matchIndex), style: style));
        }

        final matchEnd = matchIndex + query.length;
        spans.add(TextSpan(
            text: label.substring(matchIndex, matchEnd),
            style: highlightStyle));
        start = matchEnd;
      }

      return RichText(
          textAlign: TextAlign.center, text: TextSpan(children: spans));
    }

    return Card(
      color: cardColor,
      elevation: 2,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: Colors.white),
            const SizedBox(height: 8),
            buildLabel(),
          ],
        ),
      ),
    );
  }
}
