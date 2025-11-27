import 'package:flutter/material.dart';
import 'firebase_status.dart';

/// A widget that displays a demo mode banner when Firebase is not configured
class DemoModeBanner extends StatelessWidget {
  final bool isSmall;
  
  const DemoModeBanner({
    super.key, 
    this.isSmall = false,
  });

  @override
  Widget build(BuildContext context) {
    // Firebase is now configured, so always return an empty widget
    return const SizedBox.shrink();
    
    if (isSmall) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.amber.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.amber),
        ),
        child: const Text(
          'DEMO',
          style: TextStyle(
            fontSize: 10,
            color: Colors.amber,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      color: Colors.amber.shade100,
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.info_outline, size: 16, color: Colors.amber),
          SizedBox(width: 8),
          Flexible(
            child: Text(
              'Demo Mode: Firebase features are not available',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: Colors.amber,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}