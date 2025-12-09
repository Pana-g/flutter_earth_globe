import 'package:flutter/material.dart';

/// App color scheme and theme
class AppTheme {
  // Primary colors
  static const Color primaryDark = Color(0xFF0D1B2A);
  static const Color primaryMedium = Color(0xFF1B263B);
  static const Color primaryLight = Color(0xFF415A77);

  // Accent colors
  static const Color accentBlue = Color(0xFF778DA9);
  static const Color accentCyan = Color(0xFF00D9FF);
  static const Color accentPurple = Color(0xFF9D4EDD);
  static const Color accentPink = Color(0xFFFF006E);

  // Gradients
  static const LinearGradient panelGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xCC1B263B),
      Color(0xCC0D1B2A),
    ],
  );

  static const LinearGradient headerGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF667eea),
      Color(0xFF764ba2),
    ],
  );

  static const LinearGradient accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      accentCyan,
      accentPurple,
    ],
  );

  static ThemeData get darkTheme => ThemeData(
        brightness: Brightness.dark,
        primaryColor: primaryDark,
        scaffoldBackgroundColor: primaryDark,
        cardTheme: CardThemeData(
          color: primaryMedium.withAlpha(200),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: accentBlue.withAlpha(50)),
          ),
        ),
        sliderTheme: SliderThemeData(
          activeTrackColor: accentCyan,
          inactiveTrackColor: primaryLight.withAlpha(100),
          thumbColor: accentCyan,
          overlayColor: accentCyan.withAlpha(30),
          trackHeight: 4,
        ),
        switchTheme: SwitchThemeData(
          thumbColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return accentCyan;
            }
            return primaryLight;
          }),
          trackColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return accentCyan.withAlpha(100);
            }
            return primaryLight.withAlpha(50);
          }),
        ),
        iconButtonTheme: IconButtonThemeData(
          style: ButtonStyle(
            foregroundColor: WidgetStateProperty.all(accentBlue),
          ),
        ),
        textTheme: const TextTheme(
          titleLarge: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
          titleMedium: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          bodyMedium: TextStyle(
            color: Colors.white70,
            fontSize: 13,
          ),
          bodySmall: TextStyle(
            color: Colors.white54,
            fontSize: 11,
          ),
        ),
        colorScheme: const ColorScheme.dark(
          primary: accentCyan,
          secondary: accentPurple,
          surface: primaryMedium,
        ),
      );
}

/// Glassmorphism container
class GlassPanel extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;

  const GlassPanel({
    super.key,
    required this.child,
    this.padding,
    this.width,
    this.height,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        gradient: AppTheme.panelGradient,
        borderRadius: borderRadius ?? BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.accentBlue.withAlpha(40),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(80),
            blurRadius: 20,
            spreadRadius: 0,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: borderRadius ?? BorderRadius.circular(16),
        child: SingleChildScrollView(
          child: Padding(
            padding: padding ?? const EdgeInsets.all(12),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// Section header widget
class SectionHeader extends StatelessWidget {
  final String title;
  final IconData? icon;
  final bool isExpanded;
  final VoidCallback? onTap;

  const SectionHeader({
    super.key,
    required this.title,
    this.icon,
    this.isExpanded = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, size: 16, color: AppTheme.accentCyan),
              const SizedBox(width: 8),
            ],
            Expanded(
              child: Text(
                title.toUpperCase(),
                style: TextStyle(
                  color: AppTheme.accentCyan,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
            ),
            if (onTap != null)
              Icon(
                isExpanded ? Icons.expand_less : Icons.expand_more,
                size: 18,
                color: AppTheme.accentBlue,
              ),
          ],
        ),
      ),
    );
  }
}

/// Compact control row for toggles
class ControlRow extends StatelessWidget {
  final String label;
  final Widget control;
  final String? subtitle;

  const ControlRow({
    super.key,
    required this.label,
    required this.control,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: TextStyle(
                      color: Colors.white.withAlpha(120),
                      fontSize: 10,
                    ),
                  ),
              ],
            ),
          ),
          control,
        ],
      ),
    );
  }
}

/// Compact slider control
class SliderControl extends StatelessWidget {
  final String label;
  final double value;
  final double min;
  final double max;
  final ValueChanged<double>? onChanged;
  final String? valueLabel;

  const SliderControl({
    super.key,
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    this.onChanged,
    this.valueLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
              ),
            ),
            const Spacer(),
            if (valueLabel != null)
              Text(
                valueLabel!,
                style: TextStyle(
                  color: AppTheme.accentCyan,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 3,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
          ),
          child: Slider(
            value: value.clamp(min, max),
            min: min,
            max: max,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}
