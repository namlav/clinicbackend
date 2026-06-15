import 'package:flutter/material.dart';
import 'package:clinicbackend/services/supabase_service.dart';
import 'package:clinicbackend/widgets/admin_layout.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  late final AnimationController _animController;
  late final Animation<double> _fadeIn;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fadeIn = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _animController.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _animController.dispose();
    super.dispose();
  }

  // ─── Auth Logic ───────────────────────────────────────────────

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final service = SupabaseService.instance;

      // Step 1: Sign in with Supabase Auth
      final response = await service.signInWithEmail(
        _emailController.text.trim(),
        _passwordController.text,
      );

      final user = response.user;
      if (user == null) {
        _showError('Đăng nhập thất bại. Vui lòng thử lại.');
        return;
      }

      // Step 2: Check role in 'users' table
      final role = await service.getUserRole(user.id);

      if (role == null) {
        await service.signOut();
        _showError('Không tìm thấy tài khoản trong hệ thống.');
        return;
      }

      if (role != 'admin') {
        await service.signOut();
        _showError('Bạn không có quyền quản trị.');
        return;
      }

      // Step 3: Navigate to AdminLayout
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const AdminLayout()),
        );
      }
    } catch (e) {
      String message = 'Đã xảy ra lỗi. Vui lòng thử lại.';
      if (e.toString().contains('Invalid login credentials')) {
        message = 'Email hoặc mật khẩu không đúng.';
      } else if (e.toString().contains('Email not confirmed')) {
        message = 'Email chưa được xác nhận.';
      }
      _showError(message);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  // ─── UI ───────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        children: [
          // ─── Background Gradient ─────────────────────────────
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  colorScheme.primary,
                  colorScheme.primary.withValues(alpha: 0.8),
                  const Color(0xFF065F56),
                  const Color(0xFF042F2E),
                ],
                stops: const [0.0, 0.3, 0.7, 1.0],
              ),
            ),
          ),

          // ─── Decorative circles ──────────────────────────────
          Positioned(
            top: -120,
            right: -80,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.05),
              ),
            ),
          ),
          Positioned(
            bottom: -160,
            left: -100,
            child: Container(
              width: 500,
              height: 500,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.03),
              ),
            ),
          ),

          // ─── Main Content ────────────────────────────────────
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: FadeTransition(
                opacity: _fadeIn,
                child: Container(
                  width: size.width > 500 ? 440 : double.infinity,
                  padding: const EdgeInsets.all(40),
                  decoration: BoxDecoration(
                    color: colorScheme.surface.withValues(alpha: 0.95),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 40,
                        offset: const Offset(0, 16),
                      ),
                    ],
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // ─── Logo ──────────────────────────────
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                colorScheme.primary,
                                colorScheme.primary.withValues(alpha: 0.7),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: colorScheme.primary.withValues(alpha: 0.3),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.local_hospital_rounded,
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                        const SizedBox(height: 24),

                        // ─── Title ─────────────────────────────
                        Text(
                          'Serene Health',
                          style:
                              Theme.of(context).textTheme.headlineSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: colorScheme.onSurface,
                                  ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Đăng nhập vào trang quản trị',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                        ),
                        const SizedBox(height: 36),

                        // ─── Email Field ───────────────────────
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          decoration: InputDecoration(
                            labelText: 'Email',
                            hintText: 'admin@serenehealth.vn',
                            prefixIcon: Icon(
                              Icons.email_outlined,
                              color: colorScheme.onSurfaceVariant,
                            ),
                            fillColor:
                                colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Vui lòng nhập email';
                            }
                            if (!value.contains('@')) {
                              return 'Email không hợp lệ';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),

                        // ─── Password Field ────────────────────
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) => _handleLogin(),
                          decoration: InputDecoration(
                            labelText: 'Mật khẩu',
                            hintText: '••••••••',
                            prefixIcon: Icon(
                              Icons.lock_outline_rounded,
                              color: colorScheme.onSurfaceVariant,
                            ),
                            fillColor:
                                colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                color: colorScheme.onSurfaceVariant,
                              ),
                              onPressed: () {
                                setState(
                                    () => _obscurePassword = !_obscurePassword);
                              },
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Vui lòng nhập mật khẩu';
                            }
                            if (value.length < 6) {
                              return 'Mật khẩu phải có ít nhất 6 ký tự';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 32),

                        // ─── Login Button ──────────────────────
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: FilledButton(
                            onPressed: _isLoading ? null : _handleLogin,
                            style: FilledButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text(
                                    'Đăng nhập',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // ─── Footer ────────────────────────────
                        Text(
                          '© 2026 Serene Health. Bảo mật & Riêng tư.',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant
                                    .withValues(alpha: 0.6),
                              ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
