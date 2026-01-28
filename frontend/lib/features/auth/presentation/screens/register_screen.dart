/// Register Screen with Term and Group Selection
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/network/api_client.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  
  int _selectedTerm = 1;
  String? _selectedGroup;
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;
  
  // Dönem bazlı staj grupları
  List<String> get _groups {
    switch (_selectedTerm) {
      case 5:
        return [
          'Adli Tıp',
          'Anestezi ve Reanimasyon',
          'Dermatoloji',
          'Fizik Tedavi ve Rehabilitasyon',
          'Göz',
          'Göğüs Cerrahisi',
          'Göğüs Hastalıkları',
          'Halk Sağlığı',
          'Kalp ve Damar Cerrahisi',
          'Nöroşiruji',
          'Plastik',
          'Psikiyatri',
          'Kardiyoloji',
          'Kulak Burun Boğaz',
          'Nöroloji',
          'Ortopedi ve Travmatoloji',
        ];
      case 4:
      case 6:
      default:
        return [
          'Dahiliye A', 'Dahiliye B', 'Cerrahi A', 'Cerrahi B', 'Pediatri', 'Kadın Doğum',
        ];
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final api = ref.read(apiServiceProvider);
      await api.register(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        fullName: _nameController.text.trim(),
        term: _selectedTerm,
        studyGroup: _selectedGroup,
      );
      
      // Auto login after registration
      final loginResponse = await api.login(
        _emailController.text.trim(),
        _passwordController.text,
      );
      
      ref.read(authTokenProvider.notifier).state = loginResponse['access_token'];
      
      if (mounted) {
        context.go(AppRoutes.dashboard);
      }
    } catch (e) {
      String message = 'Kayıt başarısız.';
      if (e.toString().contains('Email already registered')) {
        message = 'Bu e-posta adresi zaten kayıtlı.';
      } else if (e.toString().contains('Connection refused') || 
                 e.toString().contains('SocketException') ||
                 e.toString().contains('Connection timed out')) {
        message = 'Sunucuya bağlanılamadı. Backend çalışıyor mu?';
      } else if (e.toString().contains('400')) {
        message = 'Geçersiz bilgiler. Lütfen kontrol edin.';
      } else if (e.toString().contains('500')) {
        message = 'Sunucu hatası. Veritabanı bağlantısını kontrol edin.';
      } else {
        message = 'Hata: ${e.toString()}';
      }
      setState(() {
        _errorMessage = message;
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(AppRoutes.onboarding),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              ShaderMask(
                shaderCallback: (bounds) => AppTheme.primaryGradient.createShader(bounds),
                child: const Text(
                  'Hesap Oluştur',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Kişiselleştirilmiş çalışma deneyimi için bilgilerinizi girin',
                style: Theme.of(context).textTheme.bodyLarge,
              ),

              const SizedBox(height: 32),

              // Form
              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Ad Soyad',
                        prefixIcon: Icon(Icons.person_outlined),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Ad soyad gerekli';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    // Email
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'E-posta',
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'E-posta gerekli';
                        }
                        if (!value.contains('@')) {
                          return 'Geçerli bir e-posta girin';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    // Password
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        labelText: 'Şifre',
                        prefixIcon: const Icon(Icons.lock_outlined),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                          onPressed: () {
                            setState(() => _obscurePassword = !_obscurePassword);
                          },
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.length < 6) {
                          return 'Şifre en az 6 karakter olmalı';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 24),

                    // Term Selection
                    Text(
                      'Dönem',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      children: [1, 2, 3, 4, 5, 6].map((term) {
                        final isSelected = _selectedTerm == term;
                        return ChoiceChip(
                          label: Text('Dönem $term'),
                          selected: isSelected,
                          onSelected: (_) => setState(() {
                            _selectedTerm = term;
                            _selectedGroup = null; // Dönem değişince grubu sıfırla
                          }),
                          selectedColor: AppTheme.primaryColor,
                          backgroundColor: AppTheme.darkCard,
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : AppTheme.textSecondary,
                          ),
                        );
                      }).toList(),
                    ),

                    // Group Selection (for clinical years)
                    if (_selectedTerm >= 4) ...[
                      const SizedBox(height: 24),
                      Text(
                        'Staj Grubu',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: AppTheme.darkCard,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.darkBorder),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedGroup,
                            hint: const Text('Grup seçin'),
                            isExpanded: true,
                            dropdownColor: AppTheme.darkCard,
                            items: _groups.map((group) {
                              return DropdownMenuItem(value: group, child: Text(group));
                            }).toList(),
                            onChanged: (value) => setState(() => _selectedGroup = value),
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 24),

                    // Error Message
                    if (_errorMessage != null)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.errorColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline, color: AppTheme.errorColor, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: const TextStyle(color: AppTheme.errorColor, fontSize: 14),
                              ),
                            ),
                          ],
                        ),
                      ),

                    const SizedBox(height: 32),

                    // Register Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleRegister,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 18),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('Kayıt Ol'),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Login Link
              Center(
                child: TextButton(
                  onPressed: () => context.go(AppRoutes.login),
                  child: const Text('Zaten hesabınız var mı? Giriş yapın'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
