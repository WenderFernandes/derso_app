import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BiometricService {
  static final BiometricService _instance = BiometricService._internal();
  factory BiometricService() => _instance;
  BiometricService._internal();

  final LocalAuthentication _localAuth = LocalAuthentication();

  Future<bool> isBiometricAvailable() async {
    try {
      final canCheckBiometrics = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();
      return canCheckBiometrics && isDeviceSupported;
    } catch (e) {
      print('Erro ao verificar biometria: $e');
      return false;
    }
  }

  Future<bool> authenticate() async {
    try {
      return await _localAuth.authenticate(
        localizedReason: 'Autentique-se para acessar o DERSO',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );
    } catch (e) {
      print('Erro ao autenticar: $e');
      return false;
    }
  }

  Future<void> saveCredentials(String matricula, String password) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('saved_matricula', matricula);
    await prefs.setString('saved_password', password);
    await prefs.setBool('use_biometric', true);
    await prefs.setBool('save_credentials', true);
  }

  Future<Map<String, String>?> getSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    final saveCredentials = prefs.getBool('save_credentials') ?? false;
    
    if (!saveCredentials) return null;

    final matricula = prefs.getString('saved_matricula');
    final password = prefs.getString('saved_password');

    if (matricula != null && password != null) {
      return {'matricula': matricula, 'password': password};
    }
    return null;
  }

  Future<bool> getBiometricPreference() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('use_biometric') ?? false;
  }

  Future<void> setBiometricPreference(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('use_biometric', value);
  }

  Future<bool> getSaveCredentialsPreference() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('save_credentials') ?? false;
  }

  Future<void> setSaveCredentialsPreference(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('save_credentials', value);
    if (!value) {
      await clearCredentials();
    }
  }

  Future<void> clearCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('saved_matricula');
    await prefs.remove('saved_password');
    await prefs.setBool('use_biometric', false);
  }
}
