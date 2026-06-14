import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../widgets/gradient_action_button.dart';
import '../widgets/medical_text_field.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  late final AnimationController _animationController;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  bool _loading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  bool get _hasPasswordText => _passwordController.text.isNotEmpty;

  bool get _hasMinLength => _passwordController.text.length >= 8;

  bool get _hasUppercase => RegExp(r'[A-Z]').hasMatch(_passwordController.text);

  bool get _hasNumber => RegExp(r'[0-9]').hasMatch(_passwordController.text);

  bool get _passwordsMatch =>
      _confirmPasswordController.text.isNotEmpty &&
      _confirmPasswordController.text == _passwordController.text;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutCubic,
          ),
        );

    _passwordController.addListener(_refreshPasswordState);
    _confirmPasswordController.addListener(_refreshPasswordState);
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController
      ..removeListener(_refreshPasswordState)
      ..dispose();
    _confirmPasswordController
      ..removeListener(_refreshPasswordState)
      ..dispose();
    super.dispose();
  }

  void _refreshPasswordState() {
    if (mounted) setState(() {});
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
    });

    try {
      await AuthService.instance.register(
        _fullNameController.text.trim(),
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );

      if (!mounted) return;
      _showSnackBar(
        message: 'Account created successfully. Please sign in.',
        isSuccess: true,
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    } catch (error) {
      if (!mounted) return;
      _showSnackBar(
        message: error.toString().replaceFirst('Exception: ', ''),
        isSuccess: false,
      );
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  void _showSnackBar({required String message, required bool isSuccess}) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                isSuccess ? Icons.check_circle_rounded : Icons.error_rounded,
                color: Colors.white,
              ),
              const SizedBox(width: 12),
              Expanded(child: Text(message)),
            ],
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: isSuccess
              ? const Color(0xFF047857)
              : const Color(0xFFB91C1C),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      );
  }

  void _goToLogin() {
    if (_loading) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6FAFA),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isTablet = constraints.maxWidth >= 700;
                final horizontalPadding = isTablet ? 40.0 : 20.0;

                return Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 560),
                    child: ListView(
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      padding: EdgeInsets.fromLTRB(
                        horizontalPadding,
                        18,
                        horizontalPadding,
                        28,
                      ),
                      children: [
                        _TopBar(onBack: () => Navigator.pop(context)),
                        const SizedBox(height: 18),
                        const _RegisterHeader(),
                        const SizedBox(height: 24),
                        _RegisterCard(
                          formKey: _formKey,
                          fullNameController: _fullNameController,
                          emailController: _emailController,
                          passwordController: _passwordController,
                          confirmPasswordController: _confirmPasswordController,
                          obscurePassword: _obscurePassword,
                          obscureConfirmPassword: _obscureConfirmPassword,
                          isLoading: _loading,
                          hasPasswordText: _hasPasswordText,
                          hasMinLength: _hasMinLength,
                          hasUppercase: _hasUppercase,
                          hasNumber: _hasNumber,
                          passwordsMatch: _passwordsMatch,
                          onTogglePassword: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                          onToggleConfirmPassword: () {
                            setState(() {
                              _obscureConfirmPassword =
                                  !_obscureConfirmPassword;
                            });
                          },
                          onSubmit: _submit,
                        ),
                        const SizedBox(height: 22),
                        _LoginRedirect(onPressed: _goToLogin),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton.filled(
          onPressed: onBack,
          icon: const Icon(Icons.arrow_back_rounded),
          style: IconButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: const Color(0xFF0F766E),
            minimumSize: const Size(48, 48),
            shadowColor: Colors.black.withValues(alpha: 0.12),
            elevation: 4,
          ),
          tooltip: 'Back',
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.verified_user_rounded,
                color: Color(0xFF0F766E),
                size: 18,
              ),
              SizedBox(width: 7),
              Text(
                'Secure Signup',
                style: TextStyle(
                  color: Color(0xFF0F172A),
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RegisterHeader extends StatelessWidget {
  const _RegisterHeader();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          height: 96,
          width: 96,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFE0F7F5), Color(0xFFFFFFFF), Color(0xFFFFF1F2)],
            ),
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF087F7A).withValues(alpha: 0.16),
                blurRadius: 24,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              const Icon(
                Icons.biotech_rounded,
                color: Color(0xFF087F7A),
                size: 48,
              ),
              Positioned(
                right: 18,
                top: 18,
                child: Container(
                  height: 18,
                  width: 18,
                  decoration: BoxDecoration(
                    color: const Color(0xFFDC2626),
                    borderRadius: BorderRadius.circular(99),
                    border: Border.all(color: Colors.white, width: 3),
                  ),
                ),
              ),
              Positioned(
                left: 18,
                bottom: 20,
                child: Container(
                  height: 14,
                  width: 14,
                  decoration: BoxDecoration(
                    color: const Color(0xFF14B8A6),
                    borderRadius: BorderRadius.circular(99),
                    border: Border.all(color: Colors.white, width: 3),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        const Text(
          'Create Account',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Color(0xFF0F172A),
            fontSize: 31,
            fontWeight: FontWeight.w900,
            height: 1.05,
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          'Join MalariaDetect AI and monitor your health with intelligent malaria analysis.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Color(0xFF475569),
            fontSize: 15.5,
            height: 1.45,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _RegisterCard extends StatelessWidget {
  const _RegisterCard({
    required this.formKey,
    required this.fullNameController,
    required this.emailController,
    required this.passwordController,
    required this.confirmPasswordController,
    required this.obscurePassword,
    required this.obscureConfirmPassword,
    required this.isLoading,
    required this.hasPasswordText,
    required this.hasMinLength,
    required this.hasUppercase,
    required this.hasNumber,
    required this.passwordsMatch,
    required this.onTogglePassword,
    required this.onToggleConfirmPassword,
    required this.onSubmit,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController fullNameController;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final TextEditingController confirmPasswordController;
  final bool obscurePassword;
  final bool obscureConfirmPassword;
  final bool isLoading;
  final bool hasPasswordText;
  final bool hasMinLength;
  final bool hasUppercase;
  final bool hasNumber;
  final bool passwordsMatch;
  final VoidCallback onTogglePassword;
  final VoidCallback onToggleConfirmPassword;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.08),
            blurRadius: 30,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: Form(
        key: formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: AutofillGroup(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              MedicalTextField(
                controller: fullNameController,
                label: 'Full Name',
                prefixIcon: Icons.person_rounded,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.name],
                validator: (value) {
                  final cleanValue = value?.trim() ?? '';
                  if (cleanValue.isEmpty) return 'Full name is required.';
                  if (cleanValue.length < 2) {
                    return 'Full name must be at least 2 characters.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              MedicalTextField(
                controller: emailController,
                label: 'Email Address',
                prefixIcon: Icons.alternate_email_rounded,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.email],
                validator: (value) {
                  final cleanValue = value?.trim() ?? '';
                  if (cleanValue.isEmpty) return 'Email is required.';
                  if (!RegExp(
                    r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                  ).hasMatch(cleanValue)) {
                    return 'Enter a valid email address.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              MedicalTextField(
                controller: passwordController,
                label: 'Password',
                prefixIcon: Icons.lock_rounded,
                obscureText: obscurePassword,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.newPassword],
                suffixIcon: IconButton(
                  onPressed: onTogglePassword,
                  tooltip: obscurePassword ? 'Show password' : 'Hide password',
                  icon: Icon(
                    obscurePassword
                        ? Icons.visibility_rounded
                        : Icons.visibility_off_rounded,
                  ),
                ),
                validator: (value) {
                  final password = value ?? '';
                  if (password.isEmpty) return 'Password is required.';
                  if (password.length < 8) {
                    return 'Use at least 8 characters.';
                  }
                  if (!RegExp(r'[A-Z]').hasMatch(password)) {
                    return 'Add at least one uppercase letter.';
                  }
                  if (!RegExp(r'[0-9]').hasMatch(password)) {
                    return 'Add at least one number.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),
              PasswordStrengthIndicator(
                password: passwordController.text,
                hasPasswordText: hasPasswordText,
                hasMinLength: hasMinLength,
                hasUppercase: hasUppercase,
                hasNumber: hasNumber,
              ),
              const SizedBox(height: 16),
              MedicalTextField(
                controller: confirmPasswordController,
                label: 'Confirm Password',
                prefixIcon: Icons.verified_rounded,
                obscureText: obscureConfirmPassword,
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.newPassword],
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (confirmPasswordController.text.isNotEmpty)
                      Icon(
                        passwordsMatch
                            ? Icons.check_circle_rounded
                            : Icons.error_rounded,
                        color: passwordsMatch
                            ? const Color(0xFF047857)
                            : const Color(0xFFB91C1C),
                      ),
                    IconButton(
                      onPressed: onToggleConfirmPassword,
                      tooltip: obscureConfirmPassword
                          ? 'Show password'
                          : 'Hide password',
                      icon: Icon(
                        obscureConfirmPassword
                            ? Icons.visibility_rounded
                            : Icons.visibility_off_rounded,
                      ),
                    ),
                  ],
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please confirm your password.';
                  }
                  if (value != passwordController.text) {
                    return 'Passwords do not match.';
                  }
                  return null;
                },
              ),
              if (confirmPasswordController.text.isNotEmpty) ...[
                const SizedBox(height: 8),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  child: Text(
                    passwordsMatch
                        ? 'Passwords match.'
                        : 'Passwords do not match yet.',
                    key: ValueKey(passwordsMatch),
                    style: TextStyle(
                      color: passwordsMatch
                          ? const Color(0xFF047857)
                          : const Color(0xFFB91C1C),
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 24),
              GradientActionButton(
                label: 'Create Account',
                icon: Icons.health_and_safety_rounded,
                isLoading: isLoading,
                enabled: !isLoading,
                onPressed: onSubmit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PasswordStrengthIndicator extends StatelessWidget {
  const PasswordStrengthIndicator({
    super.key,
    required this.password,
    required this.hasPasswordText,
    required this.hasMinLength,
    required this.hasUppercase,
    required this.hasNumber,
  });

  final String password;
  final bool hasPasswordText;
  final bool hasMinLength;
  final bool hasUppercase;
  final bool hasNumber;

  int get _score {
    var score = 0;
    if (hasMinLength) score++;
    if (hasUppercase) score++;
    if (hasNumber) score++;
    if (password.length >= 12 || RegExp(r'[^A-Za-z0-9]').hasMatch(password)) {
      score++;
    }
    return score;
  }

  String get _label {
    if (!hasPasswordText) return 'Weak';
    if (_score <= 1) return 'Weak';
    if (_score <= 3) return 'Medium';
    return 'Strong';
  }

  Color get _color {
    if (!hasPasswordText || _score <= 1) return const Color(0xFFDC2626);
    if (_score <= 3) return const Color(0xFFF59E0B);
    return const Color(0xFF047857);
  }

  double get _progress {
    if (!hasPasswordText) return 0.18;
    return (_score / 4).clamp(0.25, 1).toDouble();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Password strength',
              style: TextStyle(
                color: Color(0xFF475569),
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
              ),
            ),
            const Spacer(),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 180),
              style: TextStyle(
                color: _color,
                fontSize: 12.5,
                fontWeight: FontWeight.w900,
              ),
              child: Text(_label),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: LinearProgressIndicator(
            minHeight: 8,
            value: _progress,
            color: _color,
            backgroundColor: const Color(0xFFE2E8F0),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _PasswordRuleChip(label: '8+ characters', isMet: hasMinLength),
            _PasswordRuleChip(label: 'Uppercase', isMet: hasUppercase),
            _PasswordRuleChip(label: 'Number', isMet: hasNumber),
          ],
        ),
      ],
    );
  }
}

class _PasswordRuleChip extends StatelessWidget {
  const _PasswordRuleChip({required this.label, required this.isMet});

  final String label;
  final bool isMet;

  @override
  Widget build(BuildContext context) {
    final color = isMet ? const Color(0xFF047857) : const Color(0xFF64748B);
    final backgroundColor = isMet
        ? const Color(0xFFE7F8F0)
        : const Color(0xFFF1F5F9);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isMet ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
            color: color,
            size: 15,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _LoginRedirect extends StatelessWidget {
  const _LoginRedirect({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Flexible(
          child: Text(
            'Already have an account?',
            style: TextStyle(
              color: Color(0xFF475569),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        TextButton(
          onPressed: onPressed,
          style: TextButton.styleFrom(
            foregroundColor: const Color(0xFF087F7A),
            minimumSize: const Size(64, 44),
            textStyle: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
          child: const Text('Sign In'),
        ),
      ],
    );
  }
}
