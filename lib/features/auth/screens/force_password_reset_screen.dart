import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../constant/app_colors.dart';
import '../../dashboard/services/log_service.dart';

class ForcePasswordResetScreen extends StatefulWidget {
  const ForcePasswordResetScreen({super.key});

  @override
  State<ForcePasswordResetScreen> createState() => _ForcePasswordResetScreenState();
}

class _ForcePasswordResetScreenState extends State<ForcePasswordResetScreen> {
  final _controller = TextEditingController();
  bool loading = false;

  Future<void> _updatePassword() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    if (_controller.text.trim().length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Password must be at least 6 characters")),
      );
      return;
    }

    setState(() => loading = true);

    try {
      await user.updatePassword(_controller.text.trim());

      await FirebaseFirestore.instance.collection("users").doc(user.uid).update({
        "mustResetPassword": false,
      });

      await LogService.logAdminAction(
        action: "password_reset_first_time",
        targetUid: user.uid,
      );

      Navigator.pushReplacementNamed(context, "/dashboard");
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }

    setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Container(
          width: 400,
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.lock_reset, size: 60, color: AppColors.accent),
              const SizedBox(height: 18),
              const Text("Security Password Reset", style: TextStyle(fontSize: 20)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _controller,
                obscureText: true,
                decoration: const InputDecoration(labelText: "New Password"),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: loading ? null : _updatePassword,
                child: loading
                    ? const CircularProgressIndicator()
                    : const Text("Update Password"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
