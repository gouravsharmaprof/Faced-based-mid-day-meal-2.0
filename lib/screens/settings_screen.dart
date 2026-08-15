import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/app_theme.dart';
import '../utils/app_config.dart';
import '../widgets/common_widgets.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _urlCtrl    = TextEditingController();
  final _geminiCtrl = TextEditingController();
  bool _saving  = false;
  bool _loaded  = false;
  bool _keyVisible = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _urlCtrl.dispose();
    _geminiCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final url = await AppConfig.getBackendUrl();
    final key = await AppConfig.getGeminiKey();
    if (mounted) {
      setState(() {
        _urlCtrl.text = url;
        _geminiCtrl.text = key;
        _loaded = true;
      });
    }
  }

  Future<void> _saveSettings() async {
    setState(() => _saving = true);
    await AppConfig.setBackendUrl(_urlCtrl.text.trim());
    await AppConfig.setGeminiKey(_geminiCtrl.text.trim());
    if (mounted) {
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(children: [
            const Icon(Icons.check_circle_outline_rounded,
                color: AppTheme.success),
            const SizedBox(width: 10),
            Text('Settings saved!', style: GoogleFonts.poppins()),
          ]),
          backgroundColor: AppTheme.surfaceLight,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.bgGradient),
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      _buildBackendSection(),
                      const SizedBox(height: 20),
                      _buildGeminiSection(),
                      const SizedBox(height: 20),
                      _buildTipsSection(),
                      const SizedBox(height: 20),
                      _buildAboutSection(),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                  color: AppTheme.surfaceLight,
                  borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: Colors.white, size: 18),
            ),
          ),
          const SizedBox(width: 12),
          Text('Settings',
              style: GoogleFonts.poppins(
                  color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildBackendSection() {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.cloud_rounded,
                    color: AppTheme.primary, size: 20),
              ),
              const SizedBox(width: 10),
              Text('Backend Configuration',
                  style: GoogleFonts.poppins(
                      color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            'Backend Server URL',
            style: GoogleFonts.poppins(
                color: AppTheme.textSecondary, fontSize: 12),
          ),
          const SizedBox(height: 8),
          if (_loaded)
            TextFormField(
              controller: _urlCtrl,
              style: GoogleFonts.poppins(color: Colors.white, fontSize: 13),
              keyboardType: TextInputType.url,
              decoration: const InputDecoration(
                hintText: 'http://192.168.x.x:8000',
                prefixIcon: Icon(Icons.link_rounded,
                    color: AppTheme.textSecondary, size: 20),
              ),
            ),
          const SizedBox(height: 14),
          GlassCard(
            padding: const EdgeInsets.all(14),
            borderColor: AppTheme.warning.withOpacity(0.2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.info_outline_rounded,
                        color: AppTheme.warning, size: 16),
                    const SizedBox(width: 6),
                    Text('URL Examples',
                        style: GoogleFonts.poppins(
                            color: AppTheme.warning, fontSize: 12,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: 8),
                ...[
                  'Android Emulator: http://10.0.2.2:8000',
                  'Local Network: http://192.168.x.x:8000',
                  'Tunnel (ngrok): https://xxxx.ngrok.io',
                  'Production: https://your-domain.com',
                ].map((tip) => Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: GestureDetector(
                        onTap: () {
                          final url = tip.split(': ').last;
                          _urlCtrl.text = url;
                        },
                        child: Text(
                          tip,
                          style: GoogleFonts.poppins(
                              color: AppTheme.textSecondary, fontSize: 11),
                        ),
                      ),
                    )),
              ],
            ),
          ),
          const SizedBox(height: 16),
          GradientButton(
            text: 'Save Settings',
            icon: Icons.save_rounded,
            onPressed: _saving ? null : _saveSettings,
            loading: _saving,
          ),
        ],
      ),
    );
  }

  Widget _buildGeminiSection() {
    return GlassCard(
      borderColor: AppTheme.warning.withOpacity(0.25),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.warning.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.auto_awesome_rounded,
                    color: AppTheme.warning, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Food Analysis Configuration',
                        style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600)),
                    Text('Used for Food Quality Analysis',
                        style: GoogleFonts.poppins(
                            color: AppTheme.textMuted, fontSize: 10)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            'Analysis Service API Key',
            style: GoogleFonts.poppins(
                color: AppTheme.textSecondary, fontSize: 12),
          ),
          const SizedBox(height: 8),
          if (_loaded)
            TextFormField(
              controller: _geminiCtrl,
              style: GoogleFonts.poppins(color: Colors.white, fontSize: 13),
              obscureText: !_keyVisible,
              decoration: InputDecoration(
                hintText: 'Enter your service API key',
                prefixIcon: const Icon(Icons.vpn_key_rounded,
                    color: AppTheme.warning, size: 20),
                suffixIcon: IconButton(
                  icon: Icon(
                    _keyVisible
                        ? Icons.visibility_off_rounded
                        : Icons.visibility_rounded,
                    color: AppTheme.textSecondary,
                    size: 18,
                  ),
                  onPressed: () =>
                      setState(() => _keyVisible = !_keyVisible),
                ),
              ),
            ),
          const SizedBox(height: 10),
          GlassCard(
            padding: const EdgeInsets.all(12),
            borderColor: AppTheme.warning.withOpacity(0.15),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline_rounded,
                    color: AppTheme.warning, size: 15),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Get a free key at aistudio.google.com/app/apikey\n'
                    'The default key is pre-filled and ready to use.',
                    style: GoogleFonts.poppins(
                        color: AppTheme.textSecondary,
                        fontSize: 11,
                        height: 1.5),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTipsSection() {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.secondary.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.lightbulb_outline_rounded,
                    color: AppTheme.secondary, size: 20),
              ),
              const SizedBox(width: 10),
              Text('Setup Guide',
                  style: GoogleFonts.poppins(
                      color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 16),
          ...[
            (Icons.computer_rounded,
                'Run Docker backend',
                'Start with: docker-compose up in the project folder'),
            (Icons.wifi_rounded,
                'Same WiFi network',
                'Both phone and computer must be on the same network'),
            (Icons.security_rounded,
                'Allow firewall',
                'Allow port 8000 through your firewall settings'),
            (Icons.cable_rounded,
                'Use ngrok for HTTPS',
                'Run: ngrok http 8000 for remote access'),
          ].map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppTheme.secondary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(item.$1, color: AppTheme.secondary, size: 16),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.$2,
                            style: GoogleFonts.poppins(
                                color: Colors.white, fontSize: 13,
                                fontWeight: FontWeight.w500)),
                        Text(item.$3,
                            style: GoogleFonts.poppins(
                                color: AppTheme.textSecondary, fontSize: 11)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAboutSection() {
    return GlassCard(
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.restaurant_menu_rounded,
                color: Colors.white, size: 30),
          ),
          const SizedBox(height: 14),
          Text('Mid Day Meal System',
              style: GoogleFonts.poppins(
                  color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text('Version 1.0.0',
              style: GoogleFonts.poppins(
                  color: AppTheme.textSecondary, fontSize: 12)),
          const SizedBox(height: 4),
          Text('Powered by FastAPI & Smart Services',
              style: GoogleFonts.poppins(
                  color: AppTheme.textMuted, fontSize: 11)),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              _techChip('Flutter', AppTheme.primary),
              _techChip('FastAPI', AppTheme.secondary),
              _techChip('Meal Analysis', AppTheme.warning),
              _techChip('face_recognition', AppTheme.accent),
              _techChip('Docker', const Color(0xFF0DB7ED)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _techChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(label,
          style: GoogleFonts.poppins(color: color, fontSize: 11,
              fontWeight: FontWeight.w500)),
    );
  }
}
