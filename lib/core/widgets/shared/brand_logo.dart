import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../theme/app_colors.dart';

/// The EduSistem brand mark (`assets/branding/`).
///
/// [BrandLogo.new] is the full app icon (blue rounded square + symbol), with
/// a soft shadow; [BrandLogo.symbol] is the bare symbol, for brand surfaces
/// that already supply their own background.
class BrandLogo extends StatelessWidget {
  const BrandLogo({super.key, this.size = 40, this.shadow = true})
    : _asset = _icon;

  const BrandLogo.symbol({super.key, this.size = 40, bool onLight = false})
    : shadow = false,
      _asset = onLight ? _symbolOnLight : _symbol;

  static const _icon = 'assets/branding/logo.svg';
  static const _symbol = 'assets/branding/logo_symbol.svg';
  static const _symbolOnLight = 'assets/branding/logo_symbol_on_light.svg';

  final double size;
  final bool shadow;
  final String _asset;

  @override
  Widget build(BuildContext context) {
    final logo = SvgPicture.asset(
      _asset,
      width: size,
      height: size,
      excludeFromSemantics: true,
    );
    if (!shadow) return logo;

    return DecoratedBox(
      decoration: BoxDecoration(
        // Matches the icon's corner radius (116 / 512 of its side).
        borderRadius: BorderRadius.circular(size * 0.227),
        boxShadow: [
          BoxShadow(
            color: AppColors.accentBlue.withValues(alpha: 0.28),
            blurRadius: size * 0.28,
            offset: Offset(0, size * 0.11),
          ),
        ],
      ),
      child: logo,
    );
  }
}
