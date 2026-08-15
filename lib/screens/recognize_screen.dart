import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import '../utils/app_theme.dart';
import '../utils/api_service.dart';
import '../widgets/common_widgets.dart';

enum _Step { scanQr, captureFace, analyzeFood, result }

class RecognizeScreen extends StatefulWidget {
  const RecognizeScreen({super.key});

  @override
  State<RecognizeScreen> createState() => _RecognizeScreenState();
}

class _RecognizeScreenState extends State<RecognizeScreen>
    with TickerProviderStateMixin {
  _Step _step = _Step.scanQr;
  String? _scannedUserId;
  File? _faceImage;
  File? _foodImage;
  Map<String, dynamic>? _userData;
  Map<String, dynamic>? _nutritionData;
  String? _allergenAlert;
  bool _loading = false;

  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _cameraReady = false;

  late AnimationController _successAnim;

  @override
  void initState() {
    super.initState();
    _successAnim = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _successAnim.dispose();
    super.dispose();
  }

  Future<void> _onQrDetected(BarcodeCapture capture) async {
    if (_step != _Step.scanQr || _loading) return;
    final barcode = capture.barcodes.firstOrNull;
    if (barcode?.rawValue == null) return;
    final userId = barcode!.rawValue!;
    if (mounted) {
      setState(() {
        _scannedUserId = userId;
        _step = _Step.captureFace;
        _loading = true;
      });
    }
    try {
      final data = await ApiService.getUser(userId);
      if (mounted) {
        setState(() {
          _userData = data['user_data'];
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        _showError('User not found: ${e.toString().replaceAll("Exception: ", "")}');
        _reset();
      }
    }
  }

  Future<void> _openFaceCamera() async {
    try {
      _cameras ??= await availableCameras();
      final frontCam = _cameras!.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => _cameras!.first,
      );
      _cameraController?.dispose();
      _cameraController = CameraController(
          frontCam, ResolutionPreset.high, enableAudio: false);
      await _cameraController!.initialize();
      if (mounted) setState(() => _cameraReady = true);
    } catch (e) {
      _showError('Camera error: $e');
    }
  }

  Future<void> _captureFace() async {
    if (!_cameraReady || _cameraController == null) return;
    try {
      final xFile = await _cameraController!.takePicture();
      await _cameraController?.dispose();
      _cameraController = null;
      setState(() {
        _faceImage = File(xFile.path);
        _cameraReady = false;
        _loading = true;
      });
      await _verifyFace();
    } catch (e) {
      _showError('Capture failed: $e');
      setState(() => _loading = false);
    }
  }

  Future<void> _verifyFace() async {
    if (_faceImage == null || _scannedUserId == null) return;
    setState(() => _loading = true);
    try {
      final result = await ApiService.recognizeUser(
        userId: _scannedUserId!,
        faceImage: _faceImage!,
      );
      if (!mounted) return;
      if (result['match'] == true) {
        setState(() {
          _step = _Step.analyzeFood;
          _loading = false;
        });
        _successAnim.forward(from: 0);
      } else {
        _showError('Face does not match. Please try again.');
        setState(() {
          _faceImage = null;
          _loading = false;
        });
        await _openFaceCamera();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        _showError(e.toString().replaceAll('Exception: ', ''));
      }
    }
  }

  Future<void> _captureFood() async {
    final picker = ImagePicker();
    final xFile =
        await picker.pickImage(source: ImageSource.camera, imageQuality: 85);
    if (xFile == null) return;
    setState(() {
      _foodImage = File(xFile.path);
      _loading = true;
    });
    await _analyzeFood();
  }

  Future<void> _analyzeFood() async {
    if (_foodImage == null || _scannedUserId == null) return;
    setState(() => _loading = true);
    try {
      final result = await ApiService.analyzeFood(
        userId: _scannedUserId!,
        foodImage: _foodImage!,
      );
      if (mounted) {
        setState(() {
          _nutritionData = result['nutrition_data'];
          _allergenAlert = result['allergen_alert'] as String?;
          _step = _Step.result;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        _showError(e.toString().replaceAll('Exception: ', ''));
      }
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(children: [
          const Icon(Icons.error_outline, color: AppTheme.error),
          const SizedBox(width: 10),
          Expanded(child: Text(msg, style: GoogleFonts.poppins())),
        ]),
      ),
    );
  }

  void _reset() {
    _cameraController?.dispose();
    _cameraController = null;
    setState(() {
      _step = _Step.scanQr;
      _scannedUserId = null;
      _faceImage = null;
      _foodImage = null;
      _userData = null;
      _nutritionData = null;
      _allergenAlert = null;
      _loading = false;
      _cameraReady = false;
    });
    _successAnim.reset();
  }

  // ─── BUILD ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.bgGradient),
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(),
              _buildStepper(),
              Expanded(child: _buildStepContent()),
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
          Text('Verify & Serve Meal',
              style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600)),
          const Spacer(),
          if (_step != _Step.scanQr)
            TextButton.icon(
              onPressed: _reset,
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: Text('Reset', style: GoogleFonts.poppins(fontSize: 12)),
            ),
        ],
      ),
    );
  }

  Widget _buildStepper() {
    final steps = ['QR Scan', 'Face Verify', 'Food Scan', 'Result'];
    final currentIdx = _step.index;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
      child: Row(
        children: List.generate(steps.length * 2 - 1, (i) {
          if (i.isOdd) {
            final done = (i ~/ 2) < currentIdx;
            return Expanded(
              child: Container(
                height: 2,
                color: done
                    ? AppTheme.success
                    : AppTheme.textMuted.withOpacity(0.3),
              ),
            );
          }
          final idx = i ~/ 2;
          final done = idx < currentIdx;
          final active = idx == currentIdx;
          return Column(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: done || active ? AppTheme.primaryGradient : null,
                  color: done || active ? null : AppTheme.surfaceLight,
                  border: Border.all(
                    color: active ? AppTheme.primary : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: Center(
                  child: done
                      ? const Icon(Icons.check_rounded,
                          color: Colors.white, size: 16)
                      : Text(
                          '${idx + 1}',
                          style: GoogleFonts.poppins(
                            color: active ? Colors.white : AppTheme.textMuted,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                steps[idx],
                style: GoogleFonts.poppins(
                  color: active ? AppTheme.primary : AppTheme.textMuted,
                  fontSize: 9,
                  fontWeight: active ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildStepContent() {
    switch (_step) {
      case _Step.scanQr:
        return _buildQrStep();
      case _Step.captureFace:
        return _buildFaceStep();
      case _Step.analyzeFood:
        return _buildFoodStep();
      case _Step.result:
        return _buildResultStep();
    }
  }

  // ─── STEP 1: QR SCAN ─────────────────────────────────────────────────────────

  Widget _buildQrStep() {
    return Column(
      children: [
        Expanded(
          child: Stack(
            children: [
              MobileScanner(onDetect: _onQrDetected),
              Center(
                child: Container(
                  width: 220,
                  height: 220,
                  decoration: BoxDecoration(
                    border: Border.all(color: AppTheme.primary, width: 2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(24),
          child: GlassCard(
            padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: Row(
              children: [
                const Icon(Icons.qr_code_scanner_rounded,
                    color: AppTheme.primary, size: 28),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Scan Student QR Code',
                          style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600)),
                      Text("Point camera at the student's QR code",
                          style: GoogleFonts.poppins(
                              color: AppTheme.textSecondary, fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ─── STEP 2: FACE VERIFY ─────────────────────────────────────────────────────

  Widget _buildFaceStep() {
    if (_loading && _userData == null) {
      return const Center(
          child: CircularProgressIndicator(color: AppTheme.primary));
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          if (_userData != null)
            GlassCard(
              child: Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      gradient: AppTheme.primaryGradient,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Center(
                      child: Text(
                        (_userData!['name'] as String? ?? 'S')[0]
                            .toUpperCase(),
                        style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_userData!['name'] ?? '',
                            style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600)),
                        Text(
                          'Class ${_userData!['class'] ?? ''} • Roll ${_userData!['roll'] ?? ''}',
                          style: GoogleFonts.poppins(
                              color: AppTheme.textSecondary, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 20),
          GlassCard(
            child: Column(
              children: [
                const Icon(Icons.face_retouching_natural,
                    color: AppTheme.primary, size: 48),
                const SizedBox(height: 16),
                Text('Face Verification',
                    style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Text(
                  "Take a selfie to verify the student's identity",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                      color: AppTheme.textSecondary, fontSize: 13),
                ),
                const SizedBox(height: 20),
                if (_cameraReady && _cameraController != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: SizedBox(
                      height: 240,
                      child: CameraPreview(_cameraController!),
                    ),
                  ),
                const SizedBox(height: 16),
                if (!_cameraReady)
                  GradientButton(
                    text: 'Open Camera',
                    icon: Icons.camera_front_rounded,
                    onPressed: _openFaceCamera,
                    loading: _loading,
                  )
                else
                  GradientButton(
                    text: 'Capture & Verify',
                    icon: Icons.verified_user_rounded,
                    onPressed: _loading ? null : _captureFace,
                    loading: _loading,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── STEP 3: FOOD ANALYSIS ───────────────────────────────────────────────────

  Widget _buildFoodStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          ScaleTransition(
            scale: CurvedAnimation(
                parent: _successAnim, curve: Curves.elasticOut),
            child: GlassCard(
              borderColor: AppTheme.success.withOpacity(0.4),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.success.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.verified_rounded,
                        color: AppTheme.success, size: 28),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Identity Verified!',
                          style: GoogleFonts.poppins(
                              color: AppTheme.success,
                              fontSize: 16,
                              fontWeight: FontWeight.w700)),
                      Text(_userData?['name'] ?? '',
                          style: GoogleFonts.poppins(
                              color: AppTheme.textSecondary, fontSize: 13)),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          GlassCard(
            child: Column(
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
                const SizedBox(height: 16),
                Text('Food Analysis',
                    style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Text(
                  "Take a photo of the student's meal for automated nutrition and quality analysis",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                      color: AppTheme.textSecondary, fontSize: 12),
                ),
                const SizedBox(height: 20),
                if (_foodImage != null) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.file(_foodImage!,
                        height: 200,
                        width: double.infinity,
                        fit: BoxFit.cover),
                  ),
                  const SizedBox(height: 14),
                ],
                GradientButton(
                  text: _foodImage == null
                      ? 'Capture Food Photo'
                      : 'Re-capture',
                  icon: Icons.camera_alt_rounded,
                  gradient: const LinearGradient(
                      colors: [Color(0xFFFFB347), Color(0xFFFF6B6B)]),
                  onPressed: _loading ? null : _captureFood,
                  loading: _loading,
                ),
                if (_loading) ...[
                  const SizedBox(height: 14),
                  Text('Analyzing nutrition details...',
                      style: GoogleFonts.poppins(
                          color: AppTheme.textSecondary, fontSize: 12)),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: _loading
                ? null
                : () {
                    if (_scannedUserId != null) {
                      setState(() {
                        _nutritionData = {
                          'carbohydrates': 'Skipped',
                          'proteins': 'Skipped',
                          'vitamins': 'Skipped',
                          'fat': 'Skipped',
                          'calories': 'Skipped',
                          'other_nutrients': 'Skipped',
                        };
                        _step = _Step.result;
                      });
                    }
                  },
            child: Text('Skip Food Analysis',
                style:
                    GoogleFonts.poppins(color: AppTheme.textSecondary)),
          ),
        ],
      ),
    );
  }

  // ─── STEP 4: RESULT ──────────────────────────────────────────────────────────

  Widget _buildResultStep() {
    final nutrition = _nutritionData;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          // ── Success Banner ──
          GlassCard(
            borderColor: AppTheme.success.withOpacity(0.3),
            child: Column(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: const BoxDecoration(
                    gradient: AppTheme.successGradient,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check_rounded,
                      color: Colors.white, size: 32),
                ),
                const SizedBox(height: 12),
                Text('Meal Served Successfully!',
                    style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(_userData?['name'] ?? '',
                    style: GoogleFonts.poppins(
                        color: AppTheme.textSecondary, fontSize: 13)),
                Text(
                    'Class ${_userData?['class'] ?? ''} • Roll ${_userData?['roll'] ?? ''}',
                    style: GoogleFonts.poppins(
                        color: AppTheme.textSecondary, fontSize: 12)),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ── Allergen Alert ──
          if (_allergenAlert != null && _allergenAlert!.isNotEmpty) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.error.withOpacity(0.12),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.error.withOpacity(0.5)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: AppTheme.error, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _allergenAlert!,
                      style: GoogleFonts.poppins(color: AppTheme.error, fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // ── Per-Item Breakdown ──
          if (nutrition != null) ...[
            if ((nutrition['food_items'] as List?)?.isNotEmpty == true) ...[
              GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      const Icon(Icons.restaurant_menu_rounded, color: AppTheme.warning, size: 18),
                      const SizedBox(width: 8),
                      Text('Food Items Detected',
                          style: GoogleFonts.poppins(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                    ]),
                    const SizedBox(height: 14),
                    ...(nutrition['food_items'] as List).cast<Map<String, dynamic>>().map((item) =>
                      _buildFoodItemTile(item)
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // ── Total Nutrition ──
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.local_dining_rounded, color: AppTheme.warning, size: 20),
                      const SizedBox(width: 8),
                      Text('Total Nutrition',
                          style: GoogleFonts.poppins(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                      const Spacer(),
                      const StatusBadge(label: 'Verified', color: AppTheme.primary),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _nutRow(
                    _nutChip('Carbohydrates', nutrition['carbohydrates'] ?? 'N/A',
                        const Color(0xFFFFB347), Icons.grain_rounded),
                    _nutChip('Protein', nutrition['proteins'] ?? 'N/A',
                        const Color(0xFF6C63FF), Icons.fitness_center_rounded),
                  ),
                  const SizedBox(height: 10),
                  _nutRow(
                    _nutChip('Calories', nutrition['calories'] ?? 'N/A',
                        const Color(0xFFFF6B6B), Icons.local_fire_department_rounded),
                    _nutChip('Fat', nutrition['fat'] ?? 'N/A',
                        const Color(0xFF00D4AA), Icons.opacity_rounded),
                  ),
                  const SizedBox(height: 10),
                  _nutChipFull('Vitamins', nutrition['vitamins'] ?? 'N/A',
                      const Color(0xFF64FFDA), Icons.spa_rounded),
                  const SizedBox(height: 10),
                  _nutChipFull('Other Nutrients', nutrition['other_nutrients'] ?? 'N/A',
                      const Color(0xFFFF8E53), Icons.science_rounded),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Deficiencies ──
            if ((nutrition['deficiencies'] as List?)?.isNotEmpty == true) ...[
              GlassCard(
                borderColor: AppTheme.error.withOpacity(0.3),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      const Icon(Icons.warning_rounded, color: AppTheme.error, size: 18),
                      const SizedBox(width: 8),
                      Text('Nutrient Deficiencies',
                          style: GoogleFonts.poppins(color: AppTheme.error, fontSize: 14, fontWeight: FontWeight.w600)),
                    ]),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8, runSpacing: 8,
                      children: (nutrition['deficiencies'] as List).map<Widget>((d) =>
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                          decoration: BoxDecoration(
                            color: AppTheme.error.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppTheme.error.withOpacity(0.35)),
                          ),
                          child: Text('$d', style: GoogleFonts.poppins(color: AppTheme.error, fontSize: 12)),
                        )
                      ).toList(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // ── Suggestions ──
            if ((nutrition['suggestions'] as List?)?.isNotEmpty == true) ...[
              GlassCard(
                borderColor: AppTheme.success.withOpacity(0.3),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      const Icon(Icons.tips_and_updates_rounded, color: AppTheme.success, size: 18),
                      const SizedBox(width: 8),
                      Text('Dietary Suggestions',
                          style: GoogleFonts.poppins(color: AppTheme.success, fontSize: 14, fontWeight: FontWeight.w600)),
                    ]),
                    const SizedBox(height: 10),
                    ...(nutrition['suggestions'] as List).map<Widget>((s) =>
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.arrow_right_rounded, color: AppTheme.success, size: 18),
                            const SizedBox(width: 4),
                            Expanded(child: Text('$s',
                                style: GoogleFonts.poppins(color: AppTheme.textSecondary, fontSize: 12, height: 1.4))),
                          ],
                        ),
                      )
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
          ],

          // ── Serve Next Button ──
          GradientButton(
            text: 'Serve Next Student',
            icon: Icons.people_rounded,
            onPressed: _reset,
          ),
        ],
      ),
    );
  }

  Widget _buildFoodItemTile(Map<String, dynamic> item) {
    final allergen = item['allergen_warning'] as String? ?? 'None';
    final hasAllergen = allergen != 'None' && allergen.isNotEmpty;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: hasAllergen ? AppTheme.error.withOpacity(0.4) : Colors.white.withOpacity(0.06),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.fastfood_rounded, color: AppTheme.warning, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(item['name'] ?? 'Unknown',
                    style: GoogleFonts.poppins(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
              ),
              Text(item['quantity'] ?? '',
                  style: GoogleFonts.poppins(color: AppTheme.textMuted, fontSize: 11)),
            ],
          ),
          if (hasAllergen) ...[
            const SizedBox(height: 6),
            Text(allergen, style: GoogleFonts.poppins(color: AppTheme.error, fontSize: 11)),
          ],
          const SizedBox(height: 8),
          Wrap(
            spacing: 6, runSpacing: 6,
            children: [
              _miniChip('Carbs: ${item['carbohydrates'] ?? 'N/A'}', const Color(0xFFFFB347)),
              _miniChip('Protein: ${item['proteins'] ?? 'N/A'}', const Color(0xFF6C63FF)),
              _miniChip('Fat: ${item['fat'] ?? 'N/A'}', const Color(0xFF00D4AA)),
              _miniChip('Cal: ${item['calories'] ?? 'N/A'}', const Color(0xFFFF6B6B)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _miniChip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Text(text, style: GoogleFonts.poppins(color: color, fontSize: 10)),
    );
  }

  /// Two chips side by side, equal width, same height
  Widget _nutRow(Widget left, Widget right) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: left),
          const SizedBox(width: 10),
          Expanded(child: right),
        ],
      ),
    );
  }

  /// Compact chip for short values (numbers)
  Widget _nutChip(
      String label, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(value,
                    style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w700),
                    overflow: TextOverflow.ellipsis),
                Text(label,
                    style: GoogleFonts.poppins(
                        color: AppTheme.textSecondary, fontSize: 10)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Full-width chip for long values (vitamins, other nutrients)
  Widget _nutChipFull(
      String label, String value, Color color, IconData icon) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: GoogleFonts.poppins(
                        color: AppTheme.textSecondary, fontSize: 10)),
                const SizedBox(height: 2),
                Text(value,
                    style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        height: 1.4),
                    softWrap: true),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
