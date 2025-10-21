import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/user_provider.dart';
import '../services/biometric_service.dart';
import 'register_page.dart';
import 'home_page.dart';

/// Tela de login onde o policial insere a matrícula e a senha para acessar.
class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _matriculaController = TextEditingController();
  final _passwordController = TextEditingController();
  final _biometricService = BiometricService();

  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;
  bool _useBiometric = false;
  bool _saveCredentials = false;
  bool _biometricAvailable = false;

  @override
  void initState() {
    super.initState();
    _checkBiometricAvailability();
    _loadSavedPreferences();
  }

  Future<void> _checkBiometricAvailability() async {
    final available = await _biometricService.isBiometricAvailable();
    setState(() {
      _biometricAvailable = available;
    });
  }

  Future<void> _loadSavedPreferences() async {
    final useBiometric = await _biometricService.getBiometricPreference();
    final saveCredentials =
        await _biometricService.getSaveCredentialsPreference();

    setState(() {
      _useBiometric = useBiometric;
      _saveCredentials = saveCredentials;
    });

    if (saveCredentials) {
      final credentials = await _biometricService.getSavedCredentials();
      if (credentials != null) {
        _matriculaController.text = credentials['matricula']!;
        _passwordController.text = credentials['password']!;

        if (useBiometric && _biometricAvailable) {
          _attemptBiometricLogin();
        }
      }
    }
  }

  /// Tenta autenticação biométrica e executa o login com credenciais salvas
  Future<void> _attemptBiometricLogin() async {
    try {
      final authenticated = await _biometricService.authenticate();
      if (!authenticated) return;

      // 🔹 Recupera credenciais salvas antes de tentar o login
      final savedCredentials = await _biometricService.getSavedCredentials();
      if (savedCredentials == null) {
        setState(() {
          _errorMessage =
              'Não foi possível recuperar suas credenciais salvas. Faça login manualmente.';
        });
        return;
      }

      _matriculaController.text = savedCredentials['matricula'] ?? '';
      _passwordController.text = savedCredentials['password'] ?? '';

      await _handleLogin(isBiometric: true);
    } catch (e) {
      setState(() {
        _errorMessage = 'Erro ao autenticar com biometria.';
      });
      print('Erro ao autenticar: $e');
    }
  }

  @override
  void dispose() {
    _matriculaController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;

    final bool biometricMode =
        _biometricAvailable && _saveCredentials && _useBiometric;

    return Scaffold(
      body: Container(
        width: size.width,
        height: size.height,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              theme.colorScheme.primary,
              theme.colorScheme.primary.withOpacity(0.8),
              theme.colorScheme.background,
            ],
            stops: const [0.0, 0.3, 0.6],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  children: [
                    const SizedBox(height: 40),

                    // Ícone e título principais
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.security,
                        size: 64,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'DERSO',
                      style: theme.textTheme.displaySmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Gestão de Serviços',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.white.withOpacity(0.9),
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                    const SizedBox(height: 48),

                    // Modo biometria ou login completo
                    if (biometricMode)
                      _buildBiometricQuickAccess(theme)
                    else
                      _buildFullLoginForm(theme),

                    const SizedBox(height: 24),

                    // Rodapé - Criar conta
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Não possui cadastro?',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color:
                                theme.colorScheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const RegisterPage(),
                              ),
                            );
                          },
                          style: TextButton.styleFrom(
                            foregroundColor: theme.colorScheme.primary,
                          ),
                          child: Text(
                            'Criar conta',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// ==============================
  /// FORMULÁRIO COMPLETO DE LOGIN
  /// ==============================
  Widget _buildFullLoginForm(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Acessar',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            if (_errorMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: theme.colorScheme.error.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: theme.colorScheme.error,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(
                          color: theme.colorScheme.error,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            TextFormField(
              controller: _matriculaController,
              keyboardType: TextInputType.text,
              style: theme.textTheme.bodyLarge,
              decoration: InputDecoration(
                labelText: 'Matrícula',
                hintText: 'Digite sua matrícula',
                prefixIcon: Icon(
                  Icons.badge_outlined,
                  color: theme.colorScheme.primary,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Informe a matrícula';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              style: theme.textTheme.bodyLarge,
              decoration: InputDecoration(
                labelText: 'Senha',
                hintText: 'Digite sua senha',
                prefixIcon: Icon(
                  Icons.lock_outline,
                  color: theme.colorScheme.primary,
                ),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Informe a senha';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            CheckboxListTile(
              value: _saveCredentials,
              onChanged: (value) {
                setState(() {
                  _saveCredentials = value ?? false;
                  if (!_saveCredentials) _useBiometric = false;
                });
              },
              title: const Text('Salvar informações de login'),
              controlAffinity: ListTileControlAffinity.leading,
            ),

            if (_biometricAvailable && _saveCredentials)
              CheckboxListTile(
                value: _useBiometric,
                onChanged: (value) {
                  setState(() {
                    _useBiometric = value ?? false;
                  });
                },
                title: Row(
                  children: [
                    Icon(Icons.fingerprint,
                        color: theme.colorScheme.primary, size: 20),
                    const SizedBox(width: 8),
                    const Text('Usar biometria'),
                  ],
                ),
                controlAffinity: ListTileControlAffinity.leading,
              ),

            const SizedBox(height: 24),

            SizedBox(
              height: 56,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _handleLogin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation(Colors.white),
                      )
                    : const Text(
                        'Entrar',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// ==============================
  /// ACESSO RÁPIDO COM BIOMETRIA
  /// ==============================
  Widget _buildBiometricQuickAccess(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 36,
            backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
            child: const Icon(
              Icons.person,
              size: 40,
              color: Colors.blueGrey,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Wender',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'PM RO',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 32),
          InkWell(
            onTap: _attemptBiometricLogin,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: theme.colorScheme.primary.withOpacity(0.1),
                border: Border.all(
                  color: theme.colorScheme.primary.withOpacity(0.3),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.fingerprint,
                      color: theme.colorScheme.primary, size: 32),
                  const SizedBox(width: 12),
                  Text(
                    'Acessar com biometria',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () {
              setState(() {
                _useBiometric = false;
              });
            },
            child: Text(
              'Usar senha',
              style: TextStyle(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Executa o login normal ou biométrico
  Future<void> _handleLogin({bool isBiometric = false}) async {
    if (_formKey.currentState == null && !isBiometric) return;
    if (!isBiometric && !_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final userProvider = context.read<UserProvider>();
      final matricula = _matriculaController.text.trim();
      final senha = _passwordController.text.trim();

      if (matricula.isEmpty || senha.isEmpty) {
        setState(() {
          _errorMessage =
              'Credenciais inválidas. Faça login manualmente novamente.';
        });
        return;
      }

      final success = await userProvider.login(matricula, senha);

      if (success) {
        // 🔹 Salva credenciais apenas se habilitado
        if (_saveCredentials) {
          await _biometricService.saveCredentials(matricula, senha);
          await _biometricService.setBiometricPreference(_useBiometric);
          await _biometricService
              .setSaveCredentialsPreference(_saveCredentials);
        } else {
          await _biometricService.clearCredentials();
        }

        if (!mounted) return;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomePage()),
        );
      } else {
        setState(() {
          _errorMessage = 'Matrícula ou senha inválidos.';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Erro inesperado ao tentar login.';
      });
      print('Erro no login: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}
