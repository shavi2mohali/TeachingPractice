import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'login_page.dart';
import 'registration_page.dart';
import '../providers/auth_provider.dart';
import '../widgets/home_logout_actions.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  static const String pageHeading = 'ਡੀ.ਪੀ.ਐਡ. ਕੋਰਸ ਸੈਸ਼ਨ 2025-27 ਸਾਲ ਪਹਿਲਾ';

  static const String description = '''
ਡੀ.ਪੀ.ਅੇਡ. ਸੈਸ਼ਨ 2025-27 ਸਾਲ ਪਹਿਲਾ ਵਿੱਚ ਕੋਰਸ ਕਰ ਰਹੇ ਸਿੱਖਿਆਰਥੀਆਂ ਦੀ ਟੀਚਿੰਗ ਪ੍ਰੇਕਟਿਸ ਲਈ ਅਲਾਟ ਕੀਤੇ ਗਏ ਸਟੇਸ਼ਨਾਂ ਦੀ ਜਾਣਕਾਰੀ ਨੂੰ ਇਕੱਤਰ ਕਰਨ ਲਈ ਇਹ ਸਿਸਟਰ ਤਿਆਰ ਕੀਤਾ ਗਿਆ ਹੈ।
ਇਹ ਇੱਕ ਰੋਲ ਬੇਸਡ ਸਿਸਟਮ ਹੈ ਜਿਸ ਵਿੱਚ ਯੂਜ਼ਰ ਪੋਰਟਲ ਤੇ ਰਜਿਸਟਰ ਹੋਣ ਲਈ ਵਿਭਾਗ ਨੁੰ ਬੇਨਤੀ ਭੇਜੇਗਾ । ਯੂਜ਼ਰ ਦੀ ਪੁਸ਼ਟੀ ਕਰਨ ਉਪਰੰਤ ਉਹ ਇਸ ਸਿਸਟਮ ਵਿੱਚ ਆਪਣੇ ਯੂਜ਼ਰ ਆਈ.ਡੀ. ਅਤੇ ਪਾਸਵਰਡ ਨਾਲ ਲਾਗ ਇੰਨ ਕਰ ਸਕੇਗਾ। ਜਿਸ ਉਪਰੰਤ ਉਸਨੂੰ ਆਪਣੇ ਜਿਲ੍ਹੇ ਨਾਲ ਸਬੰਧਤ ਸੂਚਨਾ ਦਾ ਅਸੈਸ ਪ੍ਰਾਪਤ ਹੋ ਜਾਵੇਗਾ। ਇਸ ਵਿੱਚ ਹੇਠ ਲਿਖੇ ਅਨੁਸਾਰ ਯੂਜ਼ਰ ਆਪਣਾ ਖਾਤਾ ਰਜਿਸਟਰ ਕਰਵਾ ਸਕਦੇ ਹਨ:
1. ਜਿਲ੍ਹਾ ਸਿੱਖਿਆ ਅਫਸਰ
2. ਜਿਲ੍ਹਾ ਸਿੱਖਿਆ ਅਤੇ ਸਿਖਲਾਈ ਸੰਸਥਾ
3. ਡੀ.ਪੀ.ਐਡ. ਕੋਰਸ ਕਰਵਾ ਰਿਹਾ ਪ੍ਰਾਈਵੇਟ ਕਾਲਜ
4. ਸਕੂਲ ਜਿਸ ਵਿੱਚ ਸਿੱਖਿਆਰਥੀ ਆਪਣੀ ਟੀਚਿੰਗ ਪ੍ਰੇਕਟਿਸ ਮੁਕੰਮਲ ਕਰੇਗਾ

ਰਜਿਸਟਰ ਕਰਨ ਉਪਰੰਤ ਸਬੰਧਤ ਜਿਲ੍ਹਾ ਸਿਖਿਆ ਅਫਸਾਰ ਨੂੰ ਜਿਲ੍ਹੇ ਵਿੱਚ ਮੌਜੂਦ ਪ੍ਰਾਈਵੇਟ ਡੀ.ਪੀ.ਐਡ. ਕਾਲਜ ਵਿੰਚ ਕੋਰਸ ਕਰ ਰਹੇ ਸਿੱਖਿਆਰਥੀਆਾਂ ਦਾ ਕਾਲਜ ਵਾਈਜ਼ ਵੇਰਵਾ ਸ਼ੋਅ ਹੋਵੇਗਾ। ਡੀ.ਈ.ਓ ਵੱਲੋ਼ ਸਿੱਖਿਆਰਥੀ ਨੁੰ ਸਰਕਾਰੀ ਐਲੀਮੈਂਟਰੀ ਸਕੂਲ ਨੂੰ ਅਲਾਟ ਕਰਨ ਦੀ ਆਪਸ਼ਨ ਹੋਵੇਗੀ। ਅਲਾਟਮੈਂਟ ਉਪਰੰਤ ਇਹ ਅਰਜੀ ਜਿਲ੍ਹਾ ਸਿੱਖਿਆ ਅਤੇ ਸਿਖਲਾਈ ਸੰਸਥਾ ਵੱਲੋਂ ਪ੍ਰਵਾਨ ਕਰਦੇ ਹੋਏ ਸਬੰਧਤ ਸਕੂਲ ਲਾਗਇਨੰ ਵਿੱਚ ਭੇਜੀ ਜਾਵੇਗੀ।
ਇਸ ਸਿਸਟਮ ਵਿੱਚ ਰੋਜ਼ਾਨਾ ਸਿੱਖਿਆਰਥੀਆਂ ਦੀ ਹਾਜਰੀ ਸਕੂਲ ਮੁੱਖੀ ਵੱਲੋਂ ਅਪਡੇਟ ਕਰਨ ਦੀ ਵੀ ਪ੍ਰੋਵੀਜ਼ਨ ਰੱਖ ਗਈ ਹੈ। ਸਕੂਲ ਮੁੱਖੀ ਉਸਦੇ ਸਕੂਲ ਨੂੰ ਅਲਾਟ ਹੋਏ ਸਿੱਖਿਆਰਥੀਆਂ ਦੀ ਟੀਚਿੰਗ ਪ੍ਰੇਕਟਿਸ ਸਬੰਧੀ ਹਾਜਰੀ ਰੋਜਾਨਾ ਪੋਰਟਲ ਤੇ ਕਰਨੀ ਯਕੀਨੀ ਬਣਾਏਗਾ।''';

  @override
  Widget build(BuildContext context) {
    final currentUser = context.watch<AuthProvider>().currentUser;
    final userName = currentUser?.name.trim() ?? '';

    return Scaffold(
      appBar: AppBar(
        actions: const [HomeLogoutActions()],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 980),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                if (userName.isNotEmpty) ...[
                  Text(
                    userName,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),
                ],
                Text(
                  pageHeading,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 16),
                Text(
                  description,
                  textAlign: TextAlign.justify,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 32),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  alignment: WrapAlignment.center,
                  children: [
                    FilledButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const RegistrationPage(),
                          ),
                        );
                      },
                      child: const Text('Register'),
                    ),
                    if (currentUser == null)
                      OutlinedButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => const LoginPage(),
                            ),
                          );
                        },
                        child: const Text('Login'),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
