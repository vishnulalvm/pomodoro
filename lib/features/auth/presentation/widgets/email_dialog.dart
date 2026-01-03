import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../../core/services/firebase_auth_service.dart';

class EmailDialog extends StatefulWidget {
  final FirebaseAuthService authService;

  const EmailDialog({super.key, required this.authService});

  @override
  State<EmailDialog> createState() => _EmailDialogState();
}

class _EmailDialogState extends State<EmailDialog> {
  final TextEditingController _emailController = TextEditingController();
  String? _errorText;
  bool _isValid = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _validateEmail(String email) {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );

    setState(() {
      if (email.isEmpty) {
        _errorText = null;
        _isValid = false;
      } else if (!emailRegex.hasMatch(email)) {
        _errorText = 'Please enter a valid email';
        _isValid = false;
      } else {
        _errorText = null;
        _isValid = true;
      }
    });
  }

  Future<void> _handleCreate() async {
    if (_isValid && !_isLoading) {
      setState(() {
        _isLoading = true;
        _errorText = null;
      });

      try {
        final email = _emailController.text.trim();

        // Create or get user account
        await widget.authService.getOrCreateUser(email);

        // Success - close dialog and return email
        if (mounted) {
          Navigator.of(context).pop(email);
        }
      } catch (e) {
        // Show error
        setState(() {
          _errorText = 'Failed to create account. Please try again.';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
      child: Dialog(
        backgroundColor: Colors.transparent,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              width: 450,
              padding: const EdgeInsets.all(40),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.black.withValues(alpha: 0.3),
                    Colors.black.withValues(alpha: 0.2),
                  ],
                ),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.3),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.4),
                    blurRadius: 40,
                    spreadRadius: 10,
                  ),
                ],
              ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Title
              const Text(
                'Welcome!',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 30),
              // Description
              Text(
                'This is your username and remember it next time',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white.withValues(alpha: 0.8),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 40),
              // Email Input
              TextField(
                controller: _emailController,
                onChanged: _validateEmail,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                ),
                decoration: InputDecoration(
                  hintText: 'Enter your email',
                  hintStyle: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                  ),
                  errorText: _errorText,
                  errorStyle: const TextStyle(
                    color: Color(0xFFFFCDD2),
                    fontSize: 14,
                  ),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.1),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide(
                      color: Colors.white.withValues(alpha: 0.3),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide(
                      color: Colors.white.withValues(alpha: 0.3),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide(
                      color: Colors.white.withValues(alpha: 0.6),
                      width: 2,
                    ),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: const BorderSide(
                      color: Color(0xFFFFCDD2),
                      width: 2,
                    ),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: const BorderSide(
                      color: Color(0xFFFFCDD2),
                      width: 2,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 18,
                  ),
                ),
              ),
              const SizedBox(height: 40),
              // Create Button
              AnimatedOpacity(
                opacity: _isValid && !_isLoading ? 1.0 : 0.5,
                duration: const Duration(milliseconds: 200),
                child: GestureDetector(
                  onTap: _isValid && !_isLoading ? _handleCreate : null,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    decoration: BoxDecoration(
                      color: _isValid && !_isLoading
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.5),
                        width: 1.5,
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 24,
                            child: Center(
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.black,
                                  ),
                                ),
                              ),
                            ),
                          )
                        : Text(
                            'CREATE',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: _isValid ? Colors.black : Colors.white,
                              letterSpacing: 2.0,
                            ),
                          ),
                  ),
                ),
              ),
            ],
          ),
            ),
          ),
        ),
      ),
    );
  }
}
