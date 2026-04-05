/*
* A crowdsourced platform for real-time fuel price monitoring in Norway
* Copyright (C) 2026  Tsotne Karchava & Contributors
*
* This program is free software: you can redistribute it and/or modify
* it under the terms of the GNU General Public License as published by
* the Free Software Foundation, either version 3 of the License, or
* (at your option) any later version.
*
* This program is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
* GNU General Public License for more details.
*
* You should have received a copy of the GNU General Public License
* along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/

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
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();

  bool _isRegister = true;
  bool _isLoading = false;

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
        if (mounted) {
          _showSnackBar(_friendlyError(context, e));
        }
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar(e.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _sendPasswordReset() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      _showSnackBar(context.l10n.enterValidEmail);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await context.read<UserProvider>().sendPasswordResetEmail(email);
      if (mounted) {
        _showSnackBar(context.l10n.passwordResetSent);
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        _showSnackBar(_friendlyError(context, e));
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar(e.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showSnackBar(String message) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (_isRegister && name.isEmpty) {
      _showSnackBar(context.l10n.enterYourName);
      return;
    }
    if (email.isEmpty) {
      _showSnackBar(context.l10n.enterYourEmail);
      return;
    }
    if (!email.contains('@')) {
      _showSnackBar(context.l10n.enterValidEmail);
      return;
    }
    if (password.isEmpty) {
      _showSnackBar(context.l10n.enterYourPassword);
      return;
    }
    if (password.length < 6) {
      _showSnackBar(context.l10n.passwordMinLength);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final userProvider = context.read<UserProvider>();

      if (_isRegister) {
        await userProvider.registerWithEmail(
          email,
          password,
          name,
        );
      } else {
        await userProvider.signInWithEmail(
          email,
          password,
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
      if (mounted) {
        _showSnackBar(_friendlyError(context, e));
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar(e.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _friendlyError(BuildContext context, FirebaseAuthException exception) {
    switch (exception.code) {
      case 'email-already-in-use':
        return context.l10n.errorEmailInUse;
      case 'invalid-email':
        return context.l10n.errorInvalidEmail;
      case 'weak-password':
        return context.l10n.errorWeakPassword;
      case 'user-not-found':
        return context.l10n.errorUserNotFound;
      case 'user-disabled':
        return context.l10n.errorUserDisabled;
      case 'wrong-password':
      case 'invalid-credential':
        return context.l10n.errorWrongPassword;
      case 'credential-already-in-use':
        return context.l10n.errorCredentialInUse;
      case 'too-many-requests':
        return context.l10n.errorTooManyRequests;
      case 'network-request-failed':
        return context.l10n.errorNetworkRequestFailed;
      default:
        final message = exception.message?.trim();
        if (message != null && message.isNotEmpty) {
          return message;
        }
        return context.l10n.errorAuthFailed(exception.code);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background(context),
      appBar: AppBar(
        backgroundColor: AppColors.background(context),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Text(
          _isRegister ? context.l10n.createAccount : context.l10n.signIn,
          style: AppTextStyles.title(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        children: [
          const SizedBox(height: 8),

          // ── Subtitle ──
          Text(
            _isRegister
                ? context.l10n.createAccountSubtitle
                : context.l10n.signInSubtitle,
            style: AppTextStyles.label(context).copyWith(fontSize: 15),
          ),

          const SizedBox(height: 28),

          // ── Google sign-in ──
          _PressableButton(
            onPressed: _isLoading ? () {} : _signInWithGoogle,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: AppColors.surface(context),
                borderRadius: BorderRadius.circular(14),
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
                    Text(
                      'G',
                      style: AppTextStyles.heading(context).copyWith(
                        fontSize: 18,
                        color: AppColors.primaryContainer(context),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      context.l10n.continueWithGoogle,
                      style: AppTextStyles.bodyMedium(context),
                    ),
                  ],
                ],
              ),
            ),
          ),

          const SizedBox(height: 28),

          // ── Divider ──
          Row(
            children: [
              Expanded(child: Divider(color: AppColors.border(context))),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  context.l10n.or.toLowerCase(),
                  style: AppTextStyles.meta(context),
                ),
              ),
              Expanded(child: Divider(color: AppColors.border(context))),
            ],
          ),

          const SizedBox(height: 28),

          // ── Form fields ──
          if (_isRegister) ...[
            _buildTextField(
              controller: _nameController,
              hint: context.l10n.displayName,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 12),
          ],
          _buildTextField(
            controller: _emailController,
            hint: context.l10n.email,
            keyboardType: TextInputType.emailAddress,
            autocorrect: false,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 12),
          _buildTextField(
            controller: _passwordController,
            hint: context.l10n.password,
            obscureText: true,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _submit(),
          ),

          // ── Forgot password (sign-in only) ──
          if (!_isRegister) ...[
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: GestureDetector(
                onTap: _isLoading ? null : _sendPasswordReset,
                child: Text(
                  context.l10n.forgotPassword,
                  style: AppTextStyles.label(context).copyWith(
                    color: AppColors.primaryContainer(context),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],

          const SizedBox(height: 28),

          // ── Primary CTA ──
          _PressableButton(
            onPressed: _isLoading ? () {} : _submit,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: AppColors.primaryContainer(context),
                borderRadius: BorderRadius.circular(14),
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
                        _isRegister
                            ? context.l10n.createAccount
                            : context.l10n.signIn,
                        style: AppTextStyles.bodyMedium(context).copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // ── Mode toggle ──
          Center(
            child: GestureDetector(
              onTap: () {
                if (!_isLoading) {
                  setState(() {
                    _isRegister = !_isRegister;
                  });
                }
              },
              child: Text.rich(
                TextSpan(
                  style: AppTextStyles.label(context).copyWith(fontSize: 14),
                  children: [
                    TextSpan(
                      text: _isRegister
                          ? context.l10n.alreadyHaveAccountPrefix
                          : context.l10n.needAccountPrefix,
                    ),
                    TextSpan(
                      text: _isRegister
                          ? context.l10n.signIn
                          : context.l10n.createAccount,
                      style: TextStyle(
                        color: AppColors.primaryContainer(context),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    TextInputType? keyboardType,
    bool autocorrect = true,
    bool obscureText = false,
    TextInputAction? textInputAction,
    ValueChanged<String>? onFieldSubmitted,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      autocorrect: autocorrect,
      obscureText: obscureText,
      textInputAction: textInputAction,
      onFieldSubmitted: onFieldSubmitted,
      style: AppTextStyles.body(context),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: AppTextStyles.body(context).copyWith(
          color: AppColors.textMuted(context),
        ),
        filled: true,
        fillColor: AppColors.surface(context),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.border(context), width: 0.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.border(context), width: 0.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: AppColors.primaryContainer(context),
            width: 1.5,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.error,
            width: 1,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.error,
            width: 1.5,
          ),
        ),
      ),
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
