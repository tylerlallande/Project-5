import 'package:flutter/material.dart';

import '../app_shell.dart';
import '../theme/app_theme.dart';
import '../widgets/app_header.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  bool _hidePassword = true;

  void _enterApp() {
    FocusScope.of(context).unfocus();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => const AppShell()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const AppHeader(),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.purple, AppColors.deepPurple],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(28),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.sports_football_rounded,
                          size: 40,
                          color: AppColors.gold,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'GOOD FOOD. GREAT CREW.',
                          style: TextStyle(
                            color: AppColors.gold,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.2,
                          ),
                        ),
                        SizedBox(height: 12),
                        Text(
                          'Your game day\nstarts here.',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 30,
                            height: 1.1,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Bring your people together for a better LSU tailgate.',
                          style: TextStyle(
                            color: Color(0xFFD9CFE8),
                            fontSize: 15,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                  Text(
                    'Welcome to Bayou Blitz',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Plan the tailgate. Split the supplies. Find your crew.',
                    style: TextStyle(color: AppColors.muted, height: 1.5),
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    key: const Key('login-username'),
                    textInputAction: TextInputAction.next,
                    autocorrect: false,
                    enableSuggestions: false,
                    decoration: const InputDecoration(
                      labelText: 'Username',
                      hintText: 'Enter your username',
                      prefixIcon: Icon(Icons.person_outline_rounded),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(14)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    key: const Key('login-password'),
                    obscureText: _hidePassword,
                    autocorrect: false,
                    enableSuggestions: false,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _enterApp(),
                    decoration: InputDecoration(
                      labelText: 'Password',
                      hintText: 'Enter your password',
                      prefixIcon: const Icon(Icons.lock_outline_rounded),
                      border: const OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(14)),
                      ),
                      suffixIcon: IconButton(
                        tooltip: _hidePassword
                            ? 'Show password'
                            : 'Hide password',
                        onPressed: () =>
                            setState(() => _hidePassword = !_hidePassword),
                        icon: Icon(
                          _hidePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    key: const Key('sign-in-button'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.gold,
                      foregroundColor: AppColors.deepPurple,
                      minimumSize: const Size.fromHeight(54),
                    ),
                    onPressed: _enterApp,
                    icon: const Icon(Icons.login_rounded),
                    label: const Text('Sign in'),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    key: const Key('continue-as-guest'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(54),
                    ),
                    onPressed: _enterApp,
                    icon: const Icon(Icons.arrow_forward_rounded),
                    label: const Text('Continue as guest'),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Demo sign-in · no account or password required yet.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.muted, fontSize: 12),
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
