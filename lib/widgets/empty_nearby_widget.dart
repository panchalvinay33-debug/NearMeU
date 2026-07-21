import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class EmptyNearbyWidget extends StatelessWidget {
  const EmptyNearbyWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(
              Icons.location_off_rounded,
              color: AppColors.textHint,
              size: 70,
            ),
            SizedBox(height: 20),
            Text(
              "No nearby users found",
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 10),
            Text(
              "Try refreshing or check your location permission.",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}