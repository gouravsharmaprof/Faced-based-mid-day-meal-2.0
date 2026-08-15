import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:camera/camera.dart';
import 'package:file_picker/file_picker.dart';
import '../utils/app_theme.dart';
import '../utils/api_service.dart';
import '../widgets/common_widgets.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _classCtrl = TextEditingController();
  final _rollCtrl = TextEditingController();
  final _aadharCtrl = TextEditingController();
  final _consentRefCtrl = TextEditingController();
  bool _consentChecked = false;

  File? _faceImage;
  File? _prescriptionFile;
  bool _loading = false;

  // Allergy tracking
  final List<String> _allergies = [];
  final _allergyCtrl = TextEditingController();

  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _cameraOpen = false;
  bool _cameraReady = false;

  late AnimationController _dashAnim;

  @override
  void initState() {
    super.initState();
    _dashAnim = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _classCtrl.dispose();
    _rollCtrl.dispose();
    _aadharCtrl.dispose();
    _consentRefCtrl.dispose();
    _allergyCtrl.dispose();
    _cameraController?.dispose();
    _dashAnim.dispose();
    super.dispose();
  }

  Future<void> _openCamera() async {
    try {
      _cameras ??= await availableCameras();
      final frontCam = _cameras!.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => _cameras!.first,
      );
      _cameraController = CameraController(
        frontCam,
        ResolutionPreset.high,
        enableAudio: false,
      );
      await _cameraController!.initialize();
      if (mounted) {
        setState(() {
          _cameraOpen = true;
          _cameraReady = true;
        });
      }
    } catch (e) {
      _showError('Camera error: $e');
    }
  }

  Future<void> _captureFromCamera() async {
    if (_cameraController == null ||
        !_cameraController!.value.isInitialized) return;
    try {
      final xFile = await _cameraController!.takePicture();
      await _cameraController?.dispose();
      _cameraController = null;
      setState(() {
        _faceImage = File(xFile.path);
        _cameraOpen = false;
        _cameraReady = false;
      });
    } catch (e) {
      _showError('Capture failed: $e');
    }
  }

  Future<void> _pickFromGallery() async {
    final picker = ImagePicker();
    final xFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (xFile != null && mounted) {
      setState(() => _faceImage = File(xFile.path));
    }
  }

  Future<void> _pickPrescription() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
    );
    if (result != null && result.files.single.path != null) {
      setState(() => _prescriptionFile = File(result.files.single.path!));
    }
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    if (_faceImage == null) {
      _showError('Please capture or select a face photo first');
      return;
    }
    setState(() => _loading = true);
    try {
      final result = await ApiService.registerUser(
        name: _nameCtrl.text.trim(),
        className: _classCtrl.text.trim(),
        roll: _rollCtrl.text.trim(),
        aadhar: _aadharCtrl.text.trim().isEmpty ? null : _aadharCtrl.text.trim(),
        allergies: List.from(_allergies),
        consentRefId: 'NA',
        faceImage: _faceImage!,
      );
      if (mounted) {
        setState(() => _loading = false);
        _showSuccessSheet(result);
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
          Expanded(child: Text(msg)),
        ]),
      ),
    );
  }

  void _showSuccessSheet(Map<String, dynamic> result) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _SuccessSheet(
        result: result,
        name: _nameCtrl.text.trim(),
        className: _classCtrl.text.trim(),
        roll: _rollCtrl.text.trim(),
        onDone: () {
          Navigator.pop(context);
          _formKey.currentState?.reset();
          _nameCtrl.clear();
          _classCtrl.clear();
          _rollCtrl.clear();
          _aadharCtrl.clear();
          _consentRefCtrl.clear();
          setState(() {
            _faceImage = null;
            _consentChecked = false;
          });
        },
      ),
    );
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
                child: _cameraOpen
                    ? _buildCameraView()
                    : SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: Column(
                          children: [
                            _buildFaceSection(),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                              child: Column(
                                children: [
                                  _buildForm(),
                                  const SizedBox(height: 24),
                                  GradientButton(
                                    text: 'Register Student',
                                    icon: Icons.person_add_rounded,
                                    onPressed: _loading ? null : _register,
                                    loading: _loading,
                                  ),
                                  const SizedBox(height: 32),
                                ],
                              ),
                            ),
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
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: Colors.white, size: 18),
            ),
          ),
          const SizedBox(width: 12),
          Text('Register Student',
              style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  // ─── FACE SECTION: Circular dashed frame (matches Figma) ─────────────────

  Widget _buildFaceSection() {
    return Container(
      width: double.infinity,
      color: const Color(0xFF0D1117),
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        children: [
          // LIVE indicator
          if (_faceImage == null)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFF4444),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text('LIVE',
                    style: GoogleFonts.poppins(
                        color: const Color(0xFFFF4444),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.5)),
              ],
            )
          else
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.check_circle_rounded,
                    color: AppTheme.success, size: 14),
                const SizedBox(width: 6),
                Text('CAPTURED',
                    style: GoogleFonts.poppins(
                        color: AppTheme.success,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.5)),
              ],
            ),
          const SizedBox(height: 20),

          // Circular face frame
          SizedBox(
            width: 200,
            height: 200,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Captured image fills the circle
                if (_faceImage != null)
                  ClipOval(
                    child: Image.file(_faceImage!,
                        width: 180,
                        height: 180,
                        fit: BoxFit.cover),
                  )
                else
                  // Placeholder
                  Container(
                    width: 180,
                    height: 180,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTheme.surfaceLight.withOpacity(0.5),
                    ),
                    child: const Icon(Icons.person_rounded,
                        size: 80, color: AppTheme.textMuted),
                  ),

                // Animated dashed circle
                AnimatedBuilder(
                  animation: _dashAnim,
                  builder: (_, __) => CustomPaint(
                    size: const Size(200, 200),
                    painter: _DashedCirclePainter(
                      progress: _dashAnim.value,
                      captured: _faceImage != null,
                    ),
                  ),
                ),

                // Corner brackets (Figma style)
                if (_faceImage == null)
                  CustomPaint(
                    size: const Size(200, 200),
                    painter: _CornerBracketPainter(),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          Text(
            _faceImage == null
                ? 'Position face within the frame'
                : 'Face photo ready for registration',
            style: GoogleFonts.poppins(
                color: AppTheme.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 24),

          // Camera / Gallery buttons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Row(
              children: [
                Expanded(
                  child: GradientButton(
                    text: 'Open Camera',
                    icon: Icons.camera_alt_rounded,
                    height: 48,
                    onPressed: _openCamera,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: GradientButton(
                    text: 'Gallery',
                    icon: Icons.photo_library_rounded,
                    height: 48,
                    gradient: const LinearGradient(
                        colors: [Color(0xFF00D4AA), Color(0xFF00B4D8)]),
                    onPressed: _pickFromGallery,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── LIVE CAMERA VIEW ────────────────────────────────────────────────────

  Widget _buildCameraView() {
    return Stack(
      children: [
        if (_cameraReady && _cameraController != null)
          Positioned.fill(child: CameraPreview(_cameraController!)),

        // Darkened overlay with circular cutout
        if (_cameraReady)
          Positioned.fill(
            child: CustomPaint(painter: _CircularCutoutPainter()),
          ),

        // Animated dashed ring
        Positioned.fill(
          child: AnimatedBuilder(
            animation: _dashAnim,
            builder: (_, __) => CustomPaint(
              painter: _CameraCirclePainter(progress: _dashAnim.value),
            ),
          ),
        ),

        // Top LIVE badge
        Positioned(
          top: 16,
          left: 0,
          right: 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF4444).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: const Color(0xFFFF4444).withOpacity(0.4)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                            color: Color(0xFFFF4444),
                            shape: BoxShape.circle)),
                    const SizedBox(width: 6),
                    Text('LIVE',
                        style: GoogleFonts.poppins(
                            color: const Color(0xFFFF4444),
                            fontSize: 11,
                            fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Bottom controls
        Positioned(
          bottom: 40,
          left: 0,
          right: 0,
          child: Column(
            children: [
              Text('Position your face within the frame',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                      color: Colors.white, fontSize: 13)),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Cancel
                  GestureDetector(
                    onTap: () {
                      _cameraController?.dispose();
                      _cameraController = null;
                      setState(() {
                        _cameraOpen = false;
                        _cameraReady = false;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                          color: AppTheme.surfaceLight.withOpacity(0.8),
                          shape: BoxShape.circle),
                      child: const Icon(Icons.close,
                          color: Colors.white, size: 22),
                    ),
                  ),
                  const SizedBox(width: 36),
                  // Capture button
                  GestureDetector(
                    onTap: _captureFromCamera,
                    child: Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        gradient: AppTheme.primaryGradient,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                              color: AppTheme.primary.withOpacity(0.5),
                              blurRadius: 24,
                              spreadRadius: 4),
                        ],
                      ),
                      child: const Icon(Icons.camera_alt_rounded,
                          color: Colors.white, size: 30),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ─── FORM ────────────────────────────────────────────────────────────────

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Text('STUDENT DETAILS',
                style: GoogleFonts.poppins(
                    color: AppTheme.textMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5)),
          ),
          _buildField(
            controller: _nameCtrl,
            label: 'Full Name',
            hint: 'e.g. Arjun Sharma',
            icon: Icons.badge_rounded,
            validator: (v) =>
                v?.trim().isEmpty == true ? 'Name is required' : null,
          ),
          const SizedBox(height: 14),
          _buildField(
            controller: _classCtrl,
            label: 'Class / Grade',
            hint: 'e.g. Class 5B',
            icon: Icons.school_rounded,
            validator: (v) =>
                v?.trim().isEmpty == true ? 'Required' : null,
          ),
          const SizedBox(height: 14),
          _buildField(
            controller: _rollCtrl,
            label: 'Roll Number',
            hint: 'e.g. 42',
            icon: Icons.numbers_rounded,
            keyboardType: TextInputType.number,
            validator: (v) =>
                v?.trim().isEmpty == true ? 'Required' : null,
          ),
          const SizedBox(height: 14),
          _buildField(
            controller: _aadharCtrl,
            label: 'Aadhar Number',
            hint: 'XXXX XXXX XXXX',
            icon: Icons.credit_card_rounded,
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 22),
          _buildAllergySection(),
          const SizedBox(height: 22),
          _buildPrescriptionSection(),
        ],
      ),
    );
  }

  Widget _buildAllergySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('FOOD ALLERGIES',
            style: GoogleFonts.poppins(
                color: AppTheme.textMuted, fontSize: 11,
                fontWeight: FontWeight.w700, letterSpacing: 1.5)),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _allergyCtrl,
                style: GoogleFonts.poppins(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'e.g. Peanuts, Milk, Eggs',
                  prefixIcon: const Icon(Icons.warning_amber_rounded,
                      color: AppTheme.warning, size: 20),
                ),
                onFieldSubmitted: (_) => _addAllergy(),
              ),
            ),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: _addAllergy,
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.add, color: Colors.white, size: 20),
              ),
            ),
          ],
        ),
        if (_allergies.isNotEmpty) ...
          [
            const SizedBox(height: 10),
            Wrap(
              spacing: 8, runSpacing: 8,
              children: _allergies.map((a) => Chip(
                label: Text(a,
                    style: GoogleFonts.poppins(
                        color: AppTheme.warning, fontSize: 12)),
                backgroundColor: AppTheme.warning.withOpacity(0.12),
                side: BorderSide(color: AppTheme.warning.withOpacity(0.4)),
                deleteIcon: const Icon(Icons.close, size: 14,
                    color: AppTheme.warning),
                onDeleted: () => setState(() => _allergies.remove(a)),
              )).toList(),
            ),
          ],
      ],
    );
  }

  void _addAllergy() {
    final val = _allergyCtrl.text.trim();
    if (val.isNotEmpty && !_allergies.contains(val)) {
      setState(() { _allergies.add(val); _allergyCtrl.clear(); });
    }
  }

  Widget _buildPrescriptionSection() {
    final hasFile = _prescriptionFile != null;
    final name = hasFile
        ? _prescriptionFile!.path.split('/').last
        : 'No file selected';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('MEDICAL PRESCRIPTION (optional)',
            style: GoogleFonts.poppins(
                color: AppTheme.textMuted, fontSize: 11,
                fontWeight: FontWeight.w700, letterSpacing: 1.5)),
        const SizedBox(height: 10),
        GestureDetector(
          onTap: _pickPrescription,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.surfaceLight,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: hasFile
                    ? AppTheme.success.withOpacity(0.5)
                    : Colors.white.withOpacity(0.08),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: (hasFile ? AppTheme.success : AppTheme.primary)
                        .withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    hasFile
                        ? Icons.check_circle_rounded
                        : Icons.upload_file_rounded,
                    color: hasFile ? AppTheme.success : AppTheme.primary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        hasFile ? 'Prescription Selected' : 'Upload Prescription',
                        style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600),
                      ),
                      Text(
                        name,
                        style: GoogleFonts.poppins(
                            color: AppTheme.textMuted, fontSize: 11),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: AppTheme.textMuted,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: GoogleFonts.poppins(
                color: AppTheme.textSecondary, fontSize: 12)),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          validator: validator,
          style: GoogleFonts.poppins(color: Colors.white, fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: AppTheme.textSecondary, size: 20),
          ),
        ),
      ],
    );
  }
}

// ─── PAINTERS ────────────────────────────────────────────────────────────────

/// Animated spinning dashed circle (Figma style)
class _DashedCirclePainter extends CustomPainter {
  final double progress;
  final bool captured;

  _DashedCirclePainter({required this.progress, required this.captured});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 4;
    final color = captured ? AppTheme.success : AppTheme.primary;

    final paint = Paint()
      ..color = color.withOpacity(0.7)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    const dashCount = 20;
    const dashAngle = (2 * math.pi) / dashCount;
    const gapRatio = 0.4;
    final offset = 2 * math.pi * progress;

    for (int i = 0; i < dashCount; i++) {
      final startAngle = i * dashAngle + offset;
      final sweepAngle = dashAngle * (1 - gapRatio);
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        paint,
      );
    }

    // Glow ring
    final glowPaint = Paint()
      ..color = color.withOpacity(0.1)
      ..strokeWidth = 6
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(center, radius, glowPaint);
  }

  @override
  bool shouldRepaint(_DashedCirclePainter old) =>
      old.progress != progress || old.captured != captured;
}

/// Corner bracket corners inside the circle (Figma detail)
class _CornerBracketPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.primary.withOpacity(0.8)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width / 2 - 10;
    const len = 20.0;

    // Draw 4 corner markers at 45° positions
    for (final angle in [
      -3 * math.pi / 4,
      -math.pi / 4,
      math.pi / 4,
      3 * math.pi / 4
    ]) {
      final x = cx + r * math.cos(angle);
      final y = cy + r * math.sin(angle);
      final tangentX = -math.sin(angle);
      final tangentY = math.cos(angle);

      canvas.drawLine(
        Offset(x - tangentX * len / 2, y - tangentY * len / 2),
        Offset(x + tangentX * len / 2, y + tangentY * len / 2),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

/// Dark overlay with oval cutout for camera view
class _CircularCutoutPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height * 0.4;
    const r = 130.0;

    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addOval(Rect.fromCircle(center: Offset(cx, cy), radius: r))
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(path, Paint()..color = Colors.black.withOpacity(0.55));
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

/// Animated dashed circle overlay for the camera view
class _CameraCirclePainter extends CustomPainter {
  final double progress;
  _CameraCirclePainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height * 0.4;
    final center = Offset(cx, cy);
    const radius = 133.0;

    final paint = Paint()
      ..color = AppTheme.primary.withOpacity(0.8)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    const dashCount = 24;
    const dashAngle = (2 * math.pi) / dashCount;
    const gapRatio = 0.35;
    final offset = 2 * math.pi * progress;

    for (int i = 0; i < dashCount; i++) {
      final startAngle = i * dashAngle + offset;
      final sweepAngle = dashAngle * (1 - gapRatio);
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_CameraCirclePainter old) => old.progress != progress;
}

// ─── SUCCESS SHEET ───────────────────────────────────────────────────────────

class _SuccessSheet extends StatelessWidget {
  final Map<String, dynamic> result;
  final String name, className, roll;
  final VoidCallback onDone;

  const _SuccessSheet({
    required this.result,
    required this.name,
    required this.className,
    required this.roll,
    required this.onDone,
  });

  Uint8List _base64ToBytes(String base64Str) {
    final cleaned = base64Str.replaceFirst('data:image/png;base64,', '');
    return base64Decode(cleaned);
  }

  @override
  Widget build(BuildContext context) {
    final qrBase64 = result['qr_base64'] as String?;
    final userId = result['user_id'] as String?;

    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(28, 12, 28, 28),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 50, height: 5,
              decoration: BoxDecoration(
                  color: AppTheme.textMuted,
                  borderRadius: BorderRadius.circular(3)),
            ),
            const SizedBox(height: 24),
            Container(
              width: 72, height: 72,
              decoration: const BoxDecoration(
                  gradient: AppTheme.successGradient,
                  shape: BoxShape.circle),
              child: const Icon(Icons.check_rounded,
                  color: Colors.white, size: 36),
            ),
            const SizedBox(height: 16),
            Text('Student Registered!',
                style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text('$name • Class $className • Roll $roll',
                style: GoogleFonts.poppins(
                    color: AppTheme.textSecondary, fontSize: 13)),
            if (qrBase64 != null) ...[
              const SizedBox(height: 24),
              Text('Student QR Code',
                  style: GoogleFonts.poppins(
                      color: AppTheme.textSecondary, fontSize: 12)),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16)),
                child: Image.memory(_base64ToBytes(qrBase64),
                    width: 180, height: 180),
              ),
            ],
            if (userId != null) ...[
              const SizedBox(height: 16),
              GlassCard(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 10),
                child: Row(
                  children: [
                    const Icon(Icons.fingerprint,
                        color: AppTheme.primary, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text('ID: $userId',
                          style: GoogleFonts.poppins(
                              color: AppTheme.textSecondary, fontSize: 11),
                          overflow: TextOverflow.ellipsis),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),
            GradientButton(
              text: 'Done',
              icon: Icons.check_circle_outline_rounded,
              onPressed: onDone,
            ),
          ],
        ),
      ),
    );
  }
}
