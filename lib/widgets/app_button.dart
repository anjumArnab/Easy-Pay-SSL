import 'package:flutter/material.dart';

class AppButton extends StatelessWidget {
  final String label;
  final String loadingLabel;
  final VoidCallback onPressed;
  final bool isLoading;
  final Color backgroundColor;
  final Color foregroundColor;
  final EdgeInsetsGeometry? padding;

  const AppButton({
    super.key,
    required this.label,
    required this.loadingLabel,
    required this.onPressed,
    this.isLoading = false,
    required this.backgroundColor,
    this.foregroundColor = Colors.white,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: foregroundColor,
          padding: padding ?? const EdgeInsets.symmetric(vertical: 12),
        ),
        child:
            isLoading
                ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: foregroundColor,
                        strokeWidth: 2,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(loadingLabel, style: TextStyle(fontSize: 20)),
                  ],
                )
                : Text(label),
      ),
    );
  }
}
