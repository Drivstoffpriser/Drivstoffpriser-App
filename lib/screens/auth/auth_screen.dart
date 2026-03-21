import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/app_colors.dart';
import '../../config/app_text_styles.dart';
import '../../l10n/l10n_helper.dart';
import '../../providers/user_provider.dart';

class AuthScreen extends StatefulWidget {
  final bool popOnSuccess;

  const AuthScreen({super.key, this.popOnSuccess = false});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();

  bool _isRegister = true;
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _signInWithGoogle() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final userProvider = context.read<UserProvider>();
      await userProvider.signInWithGoogle();

      if (mounted) {
        if (widget.popOnSuccess) {
          Navigator.pop(context, true);
        } else {
          Navigator.pop(context);
        }
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'sign-in-cancelled') {
      } else {
        setState(() => _error = _friendlyError(context, e.code));
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final userProvider = context.read<UserProvider>();

      if (_isRegister) {
        await userProvider.registerWithEmail(
          _emailController.text.trim(),
          _passwordController.text,
          _nameController.text.trim(),
        );
      } else {
        await userProvider.signInWithEmail(
          _emailController.text.trim(),
          _passwordController.text,
        );
      }

      if (mounted) {
        if (widget.popOnSuccess) {
          Navigator.pop(context, true);
        } else {
          Navigator.pop(context);
        }
      }
    } on FirebaseAuthException catch (e) {
      setState(() => _error = _friendlyError(context, e.code));
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _friendlyError(BuildContext context, String code) {
    switch (code) {
      case 'email-already-in-use':
        return context.l10n.errorEmailInUse;
      case 'invalid-email':
        return context.l10n.errorInvalidEmail;
      case 'weak-password':
        return context.l10n.errorWeakPassword;
      case 'user-not-found':
        return context.l10n.errorUserNotFound;
      case 'wrong-password':
      case 'invalid-credential':
        return context.l10n.errorWrongPassword;
      case 'credential-already-in-use':
        return context.l10n.errorCredentialInUse;
      default:
        return context.l10n.errorAuthFailed(code);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background(context),
      appBar: AppBar(
        backgroundColor: AppColors.background(context),
        surfaceTintColor: Colors.transparent,
        title: Text(
          _isRegister ? context.l10n.createAccount : context.l10n.signIn,
          style: AppTextStyles.title(context),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (_error != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  _error!,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onErrorContainer,
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
            _PressableButton(
              onPressed: _isLoading ? () {} : _signInWithGoogle,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.surface(context),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppColors.border(context),
                    width: 0.5,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (_isLoading)
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    else ...[
                      const Text(
                        'G',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        context.l10n.continueWithGoogle,
                        style: AppTextStyles.bodyMedium(context),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(child: Divider(color: AppColors.border(context))),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(context.l10n.or, style: AppTextStyles.label(context)),
                ),
                Expanded(child: Divider(color: AppColors.border(context))),
              ],
            ),
            const SizedBox(height: 24),
            if (_isRegister) ...[
              _buildTextField(
                controller: _nameController,
                label: context.l10n.displayName,
                icon: Icons.person_outline,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return context.l10n.enterYourName;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
            ],
            _buildTextField(
              controller: _emailController,
              label: context.l10n.email,
              icon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
              autocorrect: false,
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return context.l10n.enterYourEmail;
                }
                if (!v.contains('@')) {
                  return context.l10n.enterValidEmail;
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _passwordController,
              label: context.l10n.password,
              icon: Icons.lock_outline,
              obscureText: true,
              validator: (v) {
                if (v == null || v.isEmpty) {
                  return context.l10n.enterYourPassword;
                }
                if (v.length < 6) {
                  return context.l10n.passwordMinLength;
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            _PressableButton(
              onPressed: _isLoading ? () {} : _submit,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer(context),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          _isRegister ? context.l10n.createAccount : context.l10n.signIn,
                          style: AppTextStyles.bodyMedium(
                            context,
                          ).copyWith(color: Colors.white),
                        ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: GestureDetector(
                onTap: () {
                  if (!_isLoading) {
                    setState(() {
                      _isRegister = !_isRegister;
                      _error = null;
                    });
                  }
                },
                child: Text(
                  _isRegister
                      ? context.l10n.alreadyHaveAccount
                      : context.l10n.needAccount,
                  style: AppTextStyles.label(
                    context,
                  ).copyWith(color: AppColors.primaryContainer(context)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    bool autocorrect = true,
    bool obscureText = false,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      autocorrect: autocorrect,
      obscureText: obscureText,
      style: AppTextStyles.body(context),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
      ),
      validator: validator,
    );
  }
}

class _PressableButton extends StatefulWidget {
  final VoidCallback onPressed;
  final Widget child;

  const _PressableButton({required this.onPressed, required this.child});

  @override
  State<_PressableButton> createState() => _PressableButtonState();
}

class _PressableButtonState extends State<_PressableButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onPressed();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 80),
        curve: Curves.easeOutCubic,
        child: AnimatedOpacity(
          opacity: _isPressed ? 0.85 : 1.0,
          duration: const Duration(milliseconds: 80),
          child: widget.child,
        ),
      ),
    );
  }
}
