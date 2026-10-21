import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../services/firestore_service.dart';
import '../infant_registration/infant_registration_screen.dart';
import 'child_development_screen.dart';

/// Guards the growth-tracking feature: if the child's data has not been
/// entered yet (e.g. the user skipped it at sign-up) the mandatory child
/// registration form is shown first. Once saved, the growth screen is shown.
class ChildDevelopmentGate extends StatelessWidget {
  const ChildDevelopmentGate({super.key});

  bool _hasChildData(Map<String, dynamic>? data) {
    if (data == null) return false;

    final name = (data['childName'] as String?)?.trim() ?? '';

    return name.isNotEmpty &&
        data['childDateOfBirth'] is Timestamp &&
        data['childGender'] != null;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirestoreService.instance.watchAccount(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            backgroundColor: AppColors.backgroundCream,
            body: Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          );
        }

        if (_hasChildData(snapshot.data!.data())) {
          return const ChildDevelopmentScreen();
        }

        return const InfantRegistrationScreen(requiredForFeature: true);
      },
    );
  }
}
