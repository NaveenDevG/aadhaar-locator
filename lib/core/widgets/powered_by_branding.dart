import 'package:flutter/material.dart';

class PoweredByBranding extends StatelessWidget {
  final double? imageHeight;
  final double? textSize;
  final Color? textColor;
  final EdgeInsets? padding;

  const PoweredByBranding({
    super.key,
    this.imageHeight,
    this.textSize,
    this.textColor,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? const EdgeInsets.symmetric(vertical: 16.0, horizontal: 24.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Powered by image/icon
          Image.asset(
            'assets/images/powered_by_imblv.png',
            height: imageHeight ?? 20.0,
            width: (imageHeight ?? 20.0) * 1.2,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              // Fallback if image doesn't exist or fails to load
              return Container(
                height: imageHeight ?? 20.0,
                width: (imageHeight ?? 20.0) * 1.2,
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    colors: [
                      Colors.grey[200]!,
                      Colors.grey[100]!,
                    ],
                    center: Alignment.topLeft,
                    radius: 1.2,
                  ),
                  borderRadius: BorderRadius.circular((imageHeight ?? 20.0) / 2),
                  border: Border.all(color: Colors.grey[300]!, width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 2,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    'imlv',
                    style: TextStyle(
                      fontSize: (imageHeight ?? 20.0) * 0.4,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[700],
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(width: 8.0),
          // Powered by text
          Text(
            'Powered by IMBLV services pvt ltd',
            style: TextStyle(
              fontSize: textSize ?? 12.0,
              color: textColor ?? Colors.grey[600],
              fontStyle: FontStyle.italic,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}
