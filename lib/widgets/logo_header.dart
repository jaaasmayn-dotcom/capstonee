import 'package:flutter/material.dart';

class LogoHeader extends StatelessWidget {
  const LogoHeader({
    super.key,
    this.height = 140,
  });

  final double height;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/logos/logo.png',
      height: height,
      fit: BoxFit.contain,
    );
  }
}
