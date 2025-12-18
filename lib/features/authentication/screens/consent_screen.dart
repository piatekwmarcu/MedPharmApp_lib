import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

/// ConsentScreen - Display and accept informed consent
class ConsentScreen extends StatefulWidget {
  const ConsentScreen({Key? key}) : super(key: key);

  @override
  State<ConsentScreen> createState() => _ConsentScreenState();
}

class _ConsentScreenState extends State<ConsentScreen> {
  bool _consentChecked = false;

  // ===========================================================================
  // HANDLE CONSENT ACCEPTANCE
  // ===========================================================================
  Future<void> _handleAcceptConsent() async {
    final authProvider = context.read<AuthProvider>();

    await authProvider.acceptConsent();

    if (!mounted) return;

    if (authProvider.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.errorMessage!),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Consent accepted successfully'),
        backgroundColor: Colors.green,
      ),
    );

    // Navigate to tutorial screen
    Navigator.pushReplacementNamed(context, '/tutorial');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Informed Consent'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // =================================================================
              // CONSENT TEXT
              // =================================================================
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Clinical Trial Informed Consent',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Welcome to the MedPharm Pain Assessment Study.\n\n'
                            'This application collects daily pain assessments '
                            'to evaluate the effectiveness of treatment.\n\n'
                            'Your participation is voluntary. You may withdraw '
                            'from the study at any time without consequences.\n\n'
                            'Collected data includes:\n'
                            '• Pain scores (NRS and VAS)\n'
                            '• Assessment timestamps\n'
                            '• Application usage data\n\n'
                            'Your data will be:\n'
                            '• Stored securely\n'
                            '• Used only for research purposes\n'
                            '• Anonymized in all reports\n\n'
                            'By accepting this consent, you confirm that:\n'
                            '• You have read and understood this information\n'
                            '• You voluntarily agree to participate\n\n'
                            'For questions, contact: study@medpharm.com',
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // =================================================================
              // CONSENT CHECKBOX
              // =================================================================
              Row(
                children: [
                  Checkbox(
                    value: _consentChecked,
                    onChanged: (value) {
                      setState(() {
                        _consentChecked = value ?? false;
                      });
                    },
                  ),
                  const Expanded(
                    child: Text(
                      'I have read and accept the consent form',
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // =================================================================
              // ACCEPT BUTTON
              // =================================================================
              Consumer<AuthProvider>(
                builder: (context, provider, _) {
                  return ElevatedButton(
                    onPressed: (_consentChecked && !provider.isLoading)
                        ? _handleAcceptConsent
                        : null,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                    ),
                    child: provider.isLoading
                        ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                        : const Text('I Accept'),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
