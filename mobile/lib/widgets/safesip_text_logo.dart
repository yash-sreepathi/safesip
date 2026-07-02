import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// SafeSip wordmark: optional logo image + "Safe" in cyan, "Sip" in dark blue, plus optional tagline.
class SafeSipTextLogo extends StatelessWidget {
  const SafeSipTextLogo({
    super.key,
    this.fontSize = 48,
    this.showTagline = true,
    this.logoPath,
    this.logoSize = 64,
  });

  final double fontSize;
  final bool showTagline;
  /// Path to logo image (e.g. 'assets/images/SafeSip_Logo.png'). Shown to the right of the text when set.
  final String? logoPath;
  final double logoSize;

  @override
  Widget build(BuildContext context) {
    final wordmark = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Safe',
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.w500,
            color: AppColors.primaryLight,
            letterSpacing: 0.5,
          ),
        ),
        Text(
          'Sip',
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.w500,
            color: AppColors.primaryDark,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            wordmark,
            if (logoPath != null) ...[
              SizedBox(width: 4),
              Image.asset(
                logoPath!,
                width: logoSize,
                height: logoSize,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
              ),
            ],
          ],
        ),
        if (showTagline) ...[
          const SizedBox(height: 8),
          Text(
            'Ensuring every sip of water is a safe one.',
            style: TextStyle(
              fontSize: fontSize * 0.32,
              fontStyle: FontStyle.italic,
              color: AppColors.primaryDark,
              fontWeight: FontWeight.w400,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }
}
