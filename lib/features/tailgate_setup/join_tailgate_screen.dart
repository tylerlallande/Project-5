import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/app_theme.dart';

class JoinTailgateScreen extends StatefulWidget {
  const JoinTailgateScreen({super.key});

  @override
  State<JoinTailgateScreen> createState() => _JoinTailgateScreenState();
}

class _JoinTailgateScreenState extends State<JoinTailgateScreen> {
  final _codeController = TextEditingController();
  bool _showPreview = false;
  String? _error;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Join a tailgate')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 22, 24, 32),
        children: [
          const CircleAvatar(
            radius: 34,
            backgroundColor: Color(0xFFEDE4FA),
            child: Icon(
              Icons.group_add_rounded,
              size: 34,
              color: AppColors.purple,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'Enter your invite code',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineLarge,
          ),
          const SizedBox(height: 7),
          const Text(
            'Ask the host for the six-character code shared with your crew.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.muted, height: 1.4),
          ),
          const SizedBox(height: 26),
          TextField(
            key: const Key('join-code-field'),
            controller: _codeController,
            maxLength: 6,
            textCapitalization: TextCapitalization.characters,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 25,
              fontWeight: FontWeight.w900,
              letterSpacing: 7,
              color: AppColors.deepPurple,
            ),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp('[a-zA-Z0-9]')),
              UpperCaseTextFormatter(),
            ],
            decoration: InputDecoration(
              counterText: '',
              hintText: 'GEAUX7',
              errorText: _error,
            ),
            onChanged: (_) => setState(() {
              _error = null;
              _showPreview = false;
            }),
            onSubmitted: (_) => _findTailgate(),
          ),
          const SizedBox(height: 14),
          FilledButton(
            key: const Key('find-tailgate-button'),
            onPressed: _findTailgate,
            child: const Text('Find tailgate'),
          ),
          if (_showPreview) ...[
            const SizedBox(height: 28),
            const _TailgatePreview(),
            const SizedBox(height: 14),
            FilledButton.icon(
              key: const Key('join-crew-button'),
              onPressed: () => Navigator.pop(context, true),
              icon: const Icon(Icons.groups_rounded),
              label: const Text('Join the crew'),
            ),
          ],
        ],
      ),
    );
  }

  void _findTailgate() {
    final code = _codeController.text.trim().toUpperCase();
    setState(() {
      if (code.length != 6) {
        _error = 'Enter all six characters';
        _showPreview = false;
      } else if (code != 'GEAUX7') {
        _error = 'No tailgate found for that code';
        _showPreview = false;
      } else {
        _error = null;
        _showPreview = true;
      }
    });
  }
}

class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return newValue.copyWith(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}

class _TailgatePreview extends StatelessWidget {
  const _TailgatePreview();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.purple,
                  foregroundColor: Colors.white,
                  child: Icon(Icons.sports_football_rounded),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Gumbo & Geaux',
                        style: TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        'Hosted by Jordan',
                        style: TextStyle(color: AppColors.muted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Padding(
              padding: EdgeInsets.symmetric(vertical: 15),
              child: Divider(height: 1),
            ),
            _PreviewDetail(
              icon: Icons.sports_football_outlined,
              text: 'LSU vs. Alabama',
            ),
            SizedBox(height: 9),
            _PreviewDetail(
              icon: Icons.calendar_month_outlined,
              text: 'Saturday, Oct 24 · 6:30 PM kickoff',
            ),
            SizedBox(height: 9),
            _PreviewDetail(
              icon: Icons.location_on_outlined,
              text: 'Oak Grove · Meet at 11:00 AM',
            ),
            SizedBox(height: 9),
            _PreviewDetail(icon: Icons.groups_outlined, text: '8 Tigers going'),
          ],
        ),
      ),
    );
  }
}

class _PreviewDetail extends StatelessWidget {
  const _PreviewDetail({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.purple),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}
