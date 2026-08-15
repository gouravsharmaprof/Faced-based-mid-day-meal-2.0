import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import '../utils/app_theme.dart';
import '../utils/app_config.dart';
import '../widgets/common_widgets.dart';

class FoodQualityScreen extends StatefulWidget {
  const FoodQualityScreen({super.key});

  @override
  State<FoodQualityScreen> createState() => _FoodQualityScreenState();
}

class _FoodQualityScreenState extends State<FoodQualityScreen>
    with SingleTickerProviderStateMixin {
  File? _image;
  bool _loading = false;
  Map<String, dynamic>? _result;
  String? _errorMsg;

  late AnimationController _shimmerCtrl;

  @override
  void initState() {
    super.initState();
    _shimmerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _shimmerCtrl.dispose();
    super.dispose();
  }

  // ── Image picking ────────────────────────────────────────────────────────

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final xFile = await picker.pickImage(
      source: source,
      imageQuality: 85,
      maxWidth: 1280,
    );
    if (xFile == null) return;
    setState(() {
      _image = File(xFile.path);
      _result = null;
      _errorMsg = null;
    });
  }

  // ── Gemini REST API v1 call ───────────────────────────────────────────────

  Future<void> _analyzeWithGemini() async {
    if (_image == null) return;
    setState(() {
      _loading = true;
      _errorMsg = null;
      _result = null;
    });

    try {
      final apiKey = await AppConfig.getGeminiKey();

      // Read and base64-encode the image
      final Uint8List imageBytes = await _image!.readAsBytes();
      final String base64Image = base64Encode(imageBytes);

      const String prompt = '''
Analyze this mid-day meal image and respond ONLY with a valid JSON object 
(no markdown, no extra text, no code fences) with this exact structure:
{
  "overall_quality": "Excellent | Good | Fair | Poor",
  "quality_score": <integer 0-100>,
  "food_items": [
    {
      "name": "...",
      "portion": "...",
      "freshness": "Fresh | Slightly Stale | Stale",
      "hygiene": "Clean | Acceptable | Concerning"
    }
  ],
  "nutrition_summary": {
    "estimated_calories": "...",
    "proteins": "...",
    "carbohydrates": "...",
    "fats": "...",
    "vitamins": "..."
  },
  "hygiene_observations": ["..."],
  "quality_issues": ["..."],
  "positive_aspects": ["..."],
  "recommendations": ["..."],
  "safe_to_serve": true,
  "safety_note": "..."
}''';

      // Use Gemini REST API v1 (NOT v1beta) — supports gemini-1.5-flash
      final uri = Uri.parse(
        'https://generativelanguage.googleapis.com/v1/models/gemini-1.5-flash:generateContent?key=$apiKey',
      );

      final body = json.encode({
        'contents': [
          {
            'parts': [
              {'text': prompt},
              {
                'inline_data': {
                  'mime_type': 'image/jpeg',
                  'data': base64Image,
                }
              },
            ]
          }
        ],
        'generationConfig': {
          'temperature': 0.2,
          'maxOutputTokens': 2048,
        },
      });

      final response = await http
          .post(uri,
              headers: {'Content-Type': 'application/json'}, body: body)
          .timeout(const Duration(seconds: 60));

      if (response.statusCode != 200) {
        final errBody = json.decode(response.body);
        final errMsg = errBody['error']?['message'] ?? 'HTTP ${response.statusCode}';
        throw Exception(errMsg);
      }

      final decoded = json.decode(response.body) as Map<String, dynamic>;
      final text = (decoded['candidates'] as List?)?.firstOrNull
          ?['content']?['parts']?.firstOrNull?['text'] as String? ?? '';

      // Strip any accidental markdown fences
      final clean = text
          .replaceAll('```json', '')
          .replaceAll('```', '')
          .trim();

      final parsed = json.decode(clean) as Map<String, dynamic>;
      if (mounted) {
        setState(() {
          _result = parsed;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMsg = e.toString().replaceAll('Exception: ', '');
          _loading = false;
        });
      }
    }
  }

  // ─── BUILD ───────────────────────────────────────────────────────────────

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
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    children: [
                      _buildImageCard(),
                      const SizedBox(height: 16),
                      _buildActionButtons(),
                      if (_loading) ...[
                        const SizedBox(height: 24),
                        _buildLoadingCard(),
                      ],
                      if (_errorMsg != null) ...[
                        const SizedBox(height: 16),
                        _buildErrorCard(),
                      ],
                      if (_result != null) ...[
                        const SizedBox(height: 20),
                        _buildResultCards(),
                      ],
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

  // ── AppBar ───────────────────────────────────────────────────────────────

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
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: Colors.white, size: 18),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Food Quality Analysis',
                    style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w600)),
                Text('Powered by Smart Analysis Engine',
                    style: GoogleFonts.poppins(
                        color: AppTheme.warning,
                        fontSize: 10,
                        fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [Color(0xFFFFB347), Color(0xFFFF6B6B)]),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.auto_awesome_rounded,
                color: Colors.white, size: 18),
          ),
        ],
      ),
    );
  }

  // ── Image Card ───────────────────────────────────────────────────────────

  Widget _buildImageCard() {
    return GlassCard(
      padding: EdgeInsets.zero,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: _image == null
            ? Container(
                height: 220,
                width: double.infinity,
                color: AppTheme.surfaceLight,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppTheme.warning.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.restaurant_rounded,
                          color: AppTheme.warning, size: 48),
                    ),
                    const SizedBox(height: 14),
                    Text('No image selected',
                        style: GoogleFonts.poppins(
                            color: AppTheme.textSecondary,
                            fontSize: 14,
                            fontWeight: FontWeight.w500)),
                    const SizedBox(height: 4),
                    Text('Take or upload a photo of the meal',
                        style: GoogleFonts.poppins(
                            color: AppTheme.textMuted, fontSize: 12)),
                  ],
                ),
              )
            : Stack(
                children: [
                  Image.file(_image!,
                      height: 260,
                      width: double.infinity,
                      fit: BoxFit.cover),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: GestureDetector(
                      onTap: () => setState(() {
                        _image = null;
                        _result = null;
                        _errorMsg = null;
                      }),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.close_rounded,
                            color: Colors.white, size: 16),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  // ── Action Buttons ───────────────────────────────────────────────────────

  Widget _buildActionButtons() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _ActionBtn(
                icon: Icons.camera_alt_rounded,
                label: 'Camera',
                color: const Color(0xFF6C63FF),
                onTap: _loading ? null : () => _pickImage(ImageSource.camera),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ActionBtn(
                icon: Icons.photo_library_rounded,
                label: 'Gallery',
                color: const Color(0xFF00D4AA),
                onTap: _loading ? null : () => _pickImage(ImageSource.gallery),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_image != null)
          GradientButton(
            text: 'Analyze Food Quality',
            icon: Icons.auto_awesome_rounded,
            gradient: const LinearGradient(
                colors: [Color(0xFFFFB347), Color(0xFFFF6B6B)]),
            onPressed: _loading ? null : _analyzeWithGemini,
            loading: _loading,
          ),
      ],
    );
  }

  // ── Loading Card ─────────────────────────────────────────────────────────

  Widget _buildLoadingCard() {
    return GlassCard(
      borderColor: AppTheme.warning.withOpacity(0.3),
      child: Column(
        children: [
          AnimatedBuilder(
            animation: _shimmerCtrl,
            builder: (_, __) {
              return ShaderMask(
                shaderCallback: (bounds) => LinearGradient(
                  colors: const [
                    Color(0xFFFFB347),
                    Color(0xFFFF6B6B),
                    Color(0xFFFFB347)
                  ],
                  stops: [
                    (_shimmerCtrl.value - 0.3).clamp(0.0, 1.0),
                    _shimmerCtrl.value.clamp(0.0, 1.0),
                    (_shimmerCtrl.value + 0.3).clamp(0.0, 1.0),
                  ],
                ).createShader(bounds),
                child: const Icon(Icons.auto_awesome_rounded,
                    color: Colors.white, size: 40),
              );
            },
          ),
          const SizedBox(height: 14),
          Text('Analyzing food quality...',
              style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Text(
            'Checking food quality, hygiene, nutrition\nand safety with advanced systems',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
                color: AppTheme.textSecondary, fontSize: 12, height: 1.5),
          ),
          const SizedBox(height: 16),
          const LinearProgressIndicator(
            backgroundColor: Colors.white10,
            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.warning),
          ),
        ],
      ),
    );
  }

  // ── Error Card ───────────────────────────────────────────────────────────

  Widget _buildErrorCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.error.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.error.withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.error_outline_rounded,
                  color: AppTheme.error, size: 20),
              const SizedBox(width: 8),
              Text('Analysis Failed',
                  style: GoogleFonts.poppins(
                      color: AppTheme.error,
                      fontSize: 14,
                      fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 8),
          Text(_errorMsg ?? '',
              style: GoogleFonts.poppins(
                  color: AppTheme.textSecondary, fontSize: 12, height: 1.4)),
          const SizedBox(height: 12),
          Text('💡 Check your API key in Settings.',
              style: GoogleFonts.poppins(
                  color: AppTheme.warning, fontSize: 11)),
        ],
      ),
    );
  }

  // ── Result Cards ─────────────────────────────────────────────────────────

  Widget _buildResultCards() {
    final r = _result!;
    final score = (r['quality_score'] as num?)?.toInt() ?? 0;
    final overall = r['overall_quality'] as String? ?? 'Unknown';
    final safe = r['safe_to_serve'] as bool? ?? true;

    final scoreColor = score >= 75
        ? AppTheme.success
        : score >= 50
            ? AppTheme.warning
            : AppTheme.error;

    return Column(
      children: [
        // ── Score Banner ──
        GlassCard(
          borderColor: scoreColor.withOpacity(0.4),
          child: Row(
            children: [
              // Circular score
              SizedBox(
                width: 72,
                height: 72,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: score / 100,
                      strokeWidth: 6,
                      backgroundColor: scoreColor.withOpacity(0.15),
                      valueColor: AlwaysStoppedAnimation<Color>(scoreColor),
                    ),
                    Text('$score',
                        style: GoogleFonts.poppins(
                            color: scoreColor,
                            fontSize: 20,
                            fontWeight: FontWeight.w800)),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(overall,
                        style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          safe
                              ? Icons.check_circle_rounded
                              : Icons.cancel_rounded,
                          color: safe ? AppTheme.success : AppTheme.error,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            r['safety_note'] as String? ??
                                (safe ? 'Safe to serve' : 'Not safe to serve'),
                            style: GoogleFonts.poppins(
                                color: safe
                                    ? AppTheme.success
                                    : AppTheme.error,
                                fontSize: 11,
                                fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // ── Food Items ──
        if ((r['food_items'] as List?)?.isNotEmpty == true) ...[
          _sectionHeader(Icons.fastfood_rounded, 'Food Items Detected',
              AppTheme.warning),
          const SizedBox(height: 10),
          ...(r['food_items'] as List)
              .cast<Map<String, dynamic>>()
              .map(_buildFoodItemCard),
          const SizedBox(height: 14),
        ],

        // ── Nutrition Summary ──
        if (r['nutrition_summary'] != null) ...[
          _sectionHeader(Icons.local_dining_rounded, 'Nutrition Summary',
              const Color(0xFF6C63FF)),
          const SizedBox(height: 10),
          _buildNutritionCard(
              r['nutrition_summary'] as Map<String, dynamic>),
          const SizedBox(height: 14),
        ],

        // ── Positive Aspects ──
        if ((r['positive_aspects'] as List?)?.isNotEmpty == true) ...[
          _buildBulletCard(
            icon: Icons.thumb_up_rounded,
            title: 'Positive Aspects',
            color: AppTheme.success,
            items: (r['positive_aspects'] as List).cast<String>(),
          ),
          const SizedBox(height: 14),
        ],

        // ── Quality Issues ──
        if ((r['quality_issues'] as List?)?.isNotEmpty == true) ...[
          _buildBulletCard(
            icon: Icons.warning_amber_rounded,
            title: 'Quality Issues',
            color: AppTheme.error,
            items: (r['quality_issues'] as List).cast<String>(),
          ),
          const SizedBox(height: 14),
        ],

        // ── Hygiene ──
        if ((r['hygiene_observations'] as List?)?.isNotEmpty == true) ...[
          _buildBulletCard(
            icon: Icons.sanitizer_rounded,
            title: 'Hygiene Observations',
            color: const Color(0xFF00D4AA),
            items: (r['hygiene_observations'] as List).cast<String>(),
          ),
          const SizedBox(height: 14),
        ],

        // ── Recommendations ──
        if ((r['recommendations'] as List?)?.isNotEmpty == true) ...[
          _buildBulletCard(
            icon: Icons.tips_and_updates_rounded,
            title: 'Recommendations',
            color: AppTheme.primary,
            items: (r['recommendations'] as List).cast<String>(),
          ),
          const SizedBox(height: 20),
        ],

        // ── Re-analyze button ──
        GradientButton(
          text: 'Analyze Another Meal',
          icon: Icons.refresh_rounded,
          onPressed: () => setState(() {
            _image = null;
            _result = null;
            _errorMsg = null;
          }),
        ),
      ],
    );
  }

  Widget _sectionHeader(IconData icon, String title, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 8),
        Text(title,
            style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildFoodItemCard(Map<String, dynamic> item) {
    final freshness = item['freshness'] as String? ?? '';
    final hygieneVal = item['hygiene'] as String? ?? '';
    final freshnessColor = freshness == 'Fresh'
        ? AppTheme.success
        : freshness == 'Slightly Stale'
            ? AppTheme.warning
            : AppTheme.error;
    final hygieneColor = hygieneVal == 'Clean'
        ? AppTheme.success
        : hygieneVal == 'Acceptable'
            ? AppTheme.warning
            : AppTheme.error;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.restaurant_menu_rounded,
                  color: AppTheme.warning, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(item['name'] as String? ?? 'Unknown',
                    style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600)),
              ),
              if (item['portion'] != null)
                Text(item['portion'] as String,
                    style: GoogleFonts.poppins(
                        color: AppTheme.textMuted, fontSize: 11)),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _miniTag('🌿 $freshness', freshnessColor),
              _miniTag('🧼 $hygieneVal', hygieneColor),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNutritionCard(Map<String, dynamic> nut) {
    final entries = [
      ('🔥 Calories', nut['estimated_calories'] ?? 'N/A',
          const Color(0xFFFF6B6B)),
      ('💪 Proteins', nut['proteins'] ?? 'N/A', const Color(0xFF6C63FF)),
      ('🍞 Carbs', nut['carbohydrates'] ?? 'N/A', const Color(0xFFFFB347)),
      ('🫙 Fats', nut['fats'] ?? 'N/A', const Color(0xFF00D4AA)),
      ('🍋 Vitamins', nut['vitamins'] ?? 'N/A', const Color(0xFF64FFDA)),
    ];

    return GlassCard(
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: entries.map((e) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: e.$3.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: e.$3.withOpacity(0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(e.$1,
                    style: GoogleFonts.poppins(
                        color: AppTheme.textMuted, fontSize: 10)),
                Text(e.$2.toString(),
                    style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600)),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildBulletCard({
    required IconData icon,
    required String title,
    required Color color,
    required List<String> items,
  }) {
    return GlassCard(
      borderColor: color.withOpacity(0.25),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 8),
              Text(title,
                  style: GoogleFonts.poppins(
                      color: color,
                      fontSize: 13,
                      fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 10),
          ...items.map(
            (s) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.arrow_right_rounded, color: color, size: 18),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(s,
                        style: GoogleFonts.poppins(
                            color: AppTheme.textSecondary,
                            fontSize: 12,
                            height: 1.4)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniTag(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(label,
          style:
              GoogleFonts.poppins(color: color, fontSize: 11)),
    );
  }
}

// ── Compact icon action button ────────────────────────────────────────────────

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  const _ActionBtn({
    required this.icon,
    required this.label,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 26),
            const SizedBox(height: 6),
            Text(label,
                style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}
