import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/utils/validators.dart';
import '../../../data/models/driver_model.dart';
import '../../../data/services/storage_service.dart';
import '../../providers/auth_provider.dart' as app_auth;
import '../../widgets/common/naql_button.dart';

class DriverRegistrationScreen extends StatefulWidget {
  const DriverRegistrationScreen({super.key});

  @override
  State<DriverRegistrationScreen> createState() =>
      _DriverRegistrationScreenState();
}

class _DriverRegistrationScreenState extends State<DriverRegistrationScreen> {
  final _pageController = PageController();
  int _currentStep = 0;
  static const int _totalSteps = 5;
  bool _isLoading = false;

  // Step 1 — Basic info
  final _step1Key = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  String _selectedTruckType = AppConstants.truckTypes[0];
  String _selectedCity = AppConstants.supportedCities[0];

  // Step 2 — CIN
  final _step2Key = GlobalKey<FormState>();
  final _cinController = TextEditingController();
  File? _cinFront;
  File? _cinBack;

  // Step 3 — Selfie
  File? _selfie;

  // Step 4 — Driving license
  File? _driverLicense;

  // Step 5 — Vehicle & registration docs
  File? _truckPhoto;
  File? _truckRegFront;
  File? _truckRegBack;

  final _storageService = StorageService();
  final _picker = ImagePicker();

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _priceController.dispose();
    _cinController.dispose();
    super.dispose();
  }

  Future<File?> _pickImage({bool camera = false}) async {
    final xfile = await _picker.pickImage(
      source: camera ? ImageSource.camera : ImageSource.gallery,
      imageQuality: 80,
    );
    if (xfile == null) return null;
    return File(xfile.path);
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  bool _validateCurrentStep() {
    switch (_currentStep) {
      case 0:
        return _step1Key.currentState?.validate() ?? false;
      case 1:
        if (!(_step2Key.currentState?.validate() ?? false)) return false;
        if (_cinFront == null || _cinBack == null) {
          _showError('Ajoutez les deux photos de la CIN');
          return false;
        }
        return true;
      case 2:
        if (_selfie == null) {
          _showError('Prenez votre selfie avec la CIN');
          return false;
        }
        return true;
      case 3:
        if (_driverLicense == null) {
          _showError('Ajoutez votre permis de conduire');
          return false;
        }
        return true;
      case 4:
        if (_truckPhoto == null || _truckRegFront == null || _truckRegBack == null) {
          _showError('Ajoutez toutes les photos du camion');
          return false;
        }
        return true;
      default:
        return true;
    }
  }

  Future<void> _nextOrSubmit() async {
    if (!_validateCurrentStep()) return;
    if (_currentStep < _totalSteps - 1) {
      setState(() => _currentStep++);
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    } else {
      await _submit();
    }
  }

  void _back() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      _pageController.previousPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _submit() async {
    setState(() => _isLoading = true);
    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      final phone = FirebaseAuth.instance.currentUser!.phoneNumber ?? '';

      // Upload all documents in parallel
      final results = await Future.wait([
        _storageService.uploadTruckPhoto(uid, _truckPhoto!),
        _storageService.uploadDriverDoc(uid, 'cin_front', _cinFront!),
        _storageService.uploadDriverDoc(uid, 'cin_back', _cinBack!),
        _storageService.uploadDriverDoc(uid, 'selfie', _selfie!),
        _storageService.uploadDriverDoc(uid, 'driver_license', _driverLicense!),
        _storageService.uploadDriverDoc(uid, 'truck_reg_front', _truckRegFront!),
        _storageService.uploadDriverDoc(uid, 'truck_reg_back', _truckRegBack!),
      ]);

      final driver = DriverModel(
        id: uid,
        name: _nameController.text.trim(),
        phone: phone,
        truckType: _selectedTruckType,
        truckPhotoUrl: results[0],
        pricePerKm: double.parse(_priceController.text.trim()),
        city: _selectedCity,
        createdAt: DateTime.now(),
        walletBalance: 0,
        cinNumber: _cinController.text.trim(),
        cinFrontUrl: results[1],
        cinBackUrl: results[2],
        selfieUrl: results[3],
        driverLicenseUrl: results[4],
        truckRegistrationFrontUrl: results[5],
        truckRegistrationBackUrl: results[6],
        isApproved: false,
      );

      if (!mounted) return;
      await context
          .read<app_auth.AuthProvider>()
          .createDriverProfile(driver);
      if (!mounted) return;
      context.go(AppRoutes.driverHome);
    } catch (e) {
      if (!mounted) return;
      _showError(e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  static const _stepTitles = [
    'Informations de base',
    'Carte Nationale (CIN)',
    'Selfie avec CIN',
    'Permis de conduire',
    'Camion & Documents',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(_stepTitles[_currentStep]),
        leading: _currentStep > 0
            ? IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: _back,
              )
            : null,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: _StepProgress(
            current: _currentStep,
            total: _totalSteps,
          ),
        ),
      ),
      body: Column(
        children: [
          // Step label row
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Étape ${_currentStep + 1} sur $_totalSteps',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(_stepTitles[_currentStep],
                    style: AppTextStyles.bodySecondary),
              ],
            ),
          ),

          // Page content
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _Step1BasicInfo(
                  formKey: _step1Key,
                  nameController: _nameController,
                  priceController: _priceController,
                  selectedTruckType: _selectedTruckType,
                  onTruckTypeChanged: (v) =>
                      setState(() => _selectedTruckType = v),
                  selectedCity: _selectedCity,
                  onCityChanged: (v) => setState(() => _selectedCity = v),
                ),
                _Step2Cin(
                  formKey: _step2Key,
                  cinController: _cinController,
                  cinFront: _cinFront,
                  cinBack: _cinBack,
                  onPickFront: () async {
                    final f = await _pickImage();
                    if (f != null) setState(() => _cinFront = f);
                  },
                  onPickBack: () async {
                    final f = await _pickImage();
                    if (f != null) setState(() => _cinBack = f);
                  },
                ),
                _Step3Selfie(
                  selfie: _selfie,
                  onPickSelfie: () async {
                    final f = await _pickImage(camera: true);
                    if (f != null) setState(() => _selfie = f);
                  },
                ),
                _Step4License(
                  license: _driverLicense,
                  onPickLicense: () async {
                    final f = await _pickImage();
                    if (f != null) setState(() => _driverLicense = f);
                  },
                ),
                _Step5Vehicle(
                  truckPhoto: _truckPhoto,
                  truckRegFront: _truckRegFront,
                  truckRegBack: _truckRegBack,
                  onPickTruck: () async {
                    final f = await _pickImage();
                    if (f != null) setState(() => _truckPhoto = f);
                  },
                  onPickRegFront: () async {
                    final f = await _pickImage();
                    if (f != null) setState(() => _truckRegFront = f);
                  },
                  onPickRegBack: () async {
                    final f = await _pickImage();
                    if (f != null) setState(() => _truckRegBack = f);
                  },
                ),
              ],
            ),
          ),

          // Bottom action
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            child: NaqlButton(
              label: _currentStep < _totalSteps - 1
                  ? 'Suivant'
                  : 'Créer mon compte chauffeur',
              onPressed: _nextOrSubmit,
              isLoading: _isLoading,
              icon: _currentStep < _totalSteps - 1
                  ? Icons.arrow_forward_rounded
                  : Icons.check_rounded,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Progress bar ─────────────────────────────────────────────────────────────

class _StepProgress extends StatelessWidget {
  final int current;
  final int total;

  const _StepProgress({required this.current, required this.total});

  @override
  Widget build(BuildContext context) {
    return LinearProgressIndicator(
      value: (current + 1) / total,
      backgroundColor: AppColors.surfaceVariant,
      valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
      minHeight: 3,
    );
  }
}

// ─── Reusable photo picker tile ───────────────────────────────────────────────

class _PhotoPickerTile extends StatelessWidget {
  final String label;
  final File? image;
  final VoidCallback onTap;
  final IconData icon;
  final double height;

  const _PhotoPickerTile({
    required this.label,
    required this.image,
    required this.onTap,
    this.icon = Icons.add_a_photo_rounded,
    this.height = 130,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: height,
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: image != null ? AppColors.primary : AppColors.border,
            width: image != null ? 2 : 1,
          ),
          image: image != null
              ? DecorationImage(image: FileImage(image!), fit: BoxFit.cover)
              : null,
        ),
        child: image == null
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, color: AppColors.textHint, size: 32),
                  const SizedBox(height: 8),
                  Text(label, style: AppTextStyles.bodySecondary),
                ],
              )
            : Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check_rounded,
                        color: Colors.white, size: 14),
                  ),
                ),
              ),
      ),
    );
  }
}

// ─── Step 1: Basic info ───────────────────────────────────────────────────────

class _Step1BasicInfo extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController nameController;
  final TextEditingController priceController;
  final String selectedTruckType;
  final ValueChanged<String> onTruckTypeChanged;
  final String selectedCity;
  final ValueChanged<String> onCityChanged;

  const _Step1BasicInfo({
    required this.formKey,
    required this.nameController,
    required this.priceController,
    required this.selectedTruckType,
    required this.onTruckTypeChanged,
    required this.selectedCity,
    required this.onCityChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.local_shipping_rounded,
                      color: AppColors.primary, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Rejoignez NaqlApp !',
                            style: AppTextStyles.bodyLarge),
                        Text(
                          'Gagnez de l\'argent avec votre camion',
                          style: AppTextStyles.bodySecondary,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.1, end: 0),

            const SizedBox(height: 24),

            Text('Nom complet', style: AppTextStyles.label),
            const SizedBox(height: 8),
            TextFormField(
              controller: nameController,
              style: AppTextStyles.body,
              decoration: const InputDecoration(
                hintText: 'Mohamed Alami',
                prefixIcon: Icon(Icons.person_rounded, color: AppColors.primary),
              ),
              validator: (v) => Validators.required(v, 'Nom'),
            ).animate(delay: 80.ms).fadeIn(duration: 400.ms),

            const SizedBox(height: 20),

            Text('Type de camion', style: AppTextStyles.label),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children:
                    AppConstants.truckTypes.asMap().entries.map((entry) {
                  final type = entry.value;
                  final selected = selectedTruckType == type;
                  return GestureDetector(
                    onTap: () => onTruckTypeChanged(type),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: selected
                            ? AppColors.primary.withValues(alpha: 0.15)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.local_shipping_rounded,
                            color: selected
                                ? AppColors.primary
                                : AppColors.textSecondary,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            type,
                            style: AppTextStyles.body.copyWith(
                              color: selected
                                  ? AppColors.primary
                                  : AppColors.textPrimary,
                              fontWeight: selected
                                  ? FontWeight.w700
                                  : FontWeight.w400,
                            ),
                          ),
                          const Spacer(),
                          if (selected)
                            const Icon(Icons.check_rounded,
                                color: AppColors.primary, size: 20),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ).animate(delay: 120.ms).fadeIn(duration: 400.ms),

            const SizedBox(height: 20),

            Text('Ville de travail', style: AppTextStyles.label),
            const SizedBox(height: 8),
            Row(
              children: AppConstants.supportedCities.map((city) {
                final selected = selectedCity == city;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => onCityChanged(city),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: selected
                            ? AppColors.primary
                            : AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color:
                              selected ? AppColors.primary : AppColors.border,
                        ),
                      ),
                      child: Text(
                        city,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.body.copyWith(
                          color: selected
                              ? Colors.white
                              : AppColors.textSecondary,
                          fontWeight: selected
                              ? FontWeight.w700
                              : FontWeight.w400,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ).animate(delay: 160.ms).fadeIn(duration: 400.ms),

            const SizedBox(height: 20),

            Text('Votre prix par km (MAD)', style: AppTextStyles.label),
            const SizedBox(height: 8),
            TextFormField(
              controller: priceController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              style: AppTextStyles.body,
              decoration: const InputDecoration(
                hintText: 'Ex: 8',
                prefixIcon:
                    Icon(Icons.speed_rounded, color: AppColors.primary),
                suffixText: 'MAD/km',
              ),
              validator: Validators.pricePerKm,
            ).animate(delay: 200.ms).fadeIn(duration: 400.ms),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

// ─── Step 2: CIN ─────────────────────────────────────────────────────────────

class _Step2Cin extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController cinController;
  final File? cinFront;
  final File? cinBack;
  final VoidCallback onPickFront;
  final VoidCallback onPickBack;

  const _Step2Cin({
    required this.formKey,
    required this.cinController,
    required this.cinFront,
    required this.cinBack,
    required this.onPickFront,
    required this.onPickBack,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _InfoBanner(
              icon: Icons.credit_card_rounded,
              text:
                  'Photographiez votre CIN (recto et verso) clairement, sans reflets.',
            ),
            const SizedBox(height: 24),
            Text('Numéro CIN', style: AppTextStyles.label),
            const SizedBox(height: 8),
            TextFormField(
              controller: cinController,
              style: AppTextStyles.body,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(
                hintText: 'Ex: AB123456',
                prefixIcon:
                    Icon(Icons.badge_rounded, color: AppColors.primary),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Numéro CIN requis';
                if (v.trim().length < 5) return 'Numéro CIN invalide';
                return null;
              },
            ).animate(delay: 80.ms).fadeIn(),
            const SizedBox(height: 20),
            Text('Recto (face)', style: AppTextStyles.label),
            const SizedBox(height: 8),
            _PhotoPickerTile(
              label: 'Photo recto de la CIN',
              image: cinFront,
              onTap: onPickFront,
              icon: Icons.credit_card_rounded,
            ).animate(delay: 120.ms).fadeIn(),
            const SizedBox(height: 16),
            Text('Verso (dos)', style: AppTextStyles.label),
            const SizedBox(height: 8),
            _PhotoPickerTile(
              label: 'Photo verso de la CIN',
              image: cinBack,
              onTap: onPickBack,
              icon: Icons.credit_card_rounded,
            ).animate(delay: 160.ms).fadeIn(),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

// ─── Step 3: Selfie ───────────────────────────────────────────────────────────

class _Step3Selfie extends StatelessWidget {
  final File? selfie;
  final VoidCallback onPickSelfie;

  const _Step3Selfie({required this.selfie, required this.onPickSelfie});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _InfoBanner(
            icon: Icons.face_rounded,
            text:
                'Prenez un selfie en tenant votre CIN bien visible à côté de votre visage.',
          ),
          const SizedBox(height: 24),
          Text('Selfie avec CIN', style: AppTextStyles.label),
          const SizedBox(height: 8),
          _PhotoPickerTile(
            label: 'Appuyez pour ouvrir la caméra',
            image: selfie,
            onTap: onPickSelfie,
            icon: Icons.camera_alt_rounded,
            height: 220,
          ).animate(delay: 80.ms).fadeIn(),
          const SizedBox(height: 12),
          Text(
            '• Visage entier visible\n• CIN lisible\n• Bonne luminosité',
            style: AppTextStyles.caption,
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

// ─── Step 4: Driving license ─────────────────────────────────────────────────

class _Step4License extends StatelessWidget {
  final File? license;
  final VoidCallback onPickLicense;

  const _Step4License({required this.license, required this.onPickLicense});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _InfoBanner(
            icon: Icons.drive_eta_rounded,
            text:
                'Photographiez votre permis de conduire (recto). Il doit être valide et lisible.',
          ),
          const SizedBox(height: 24),
          Text('Permis de conduire', style: AppTextStyles.label),
          const SizedBox(height: 8),
          _PhotoPickerTile(
            label: 'Photo du permis de conduire',
            image: license,
            onTap: onPickLicense,
            icon: Icons.drive_eta_rounded,
            height: 180,
          ).animate(delay: 80.ms).fadeIn(),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

// ─── Step 5: Vehicle ──────────────────────────────────────────────────────────

class _Step5Vehicle extends StatelessWidget {
  final File? truckPhoto;
  final File? truckRegFront;
  final File? truckRegBack;
  final VoidCallback onPickTruck;
  final VoidCallback onPickRegFront;
  final VoidCallback onPickRegBack;

  const _Step5Vehicle({
    required this.truckPhoto,
    required this.truckRegFront,
    required this.truckRegBack,
    required this.onPickTruck,
    required this.onPickRegFront,
    required this.onPickRegBack,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _InfoBanner(
            icon: Icons.local_shipping_rounded,
            text:
                'Ajoutez une photo de votre camion et la carte grise (recto et verso).',
          ),
          const SizedBox(height: 24),
          Text('Photo du camion', style: AppTextStyles.label),
          const SizedBox(height: 8),
          _PhotoPickerTile(
            label: 'Photo extérieure du camion',
            image: truckPhoto,
            onTap: onPickTruck,
            icon: Icons.local_shipping_rounded,
            height: 160,
          ).animate(delay: 80.ms).fadeIn(),
          const SizedBox(height: 20),
          Text('Carte grise — Recto', style: AppTextStyles.label),
          const SizedBox(height: 8),
          _PhotoPickerTile(
            label: 'Recto de la carte grise',
            image: truckRegFront,
            onTap: onPickRegFront,
            icon: Icons.article_rounded,
          ).animate(delay: 120.ms).fadeIn(),
          const SizedBox(height: 16),
          Text('Carte grise — Verso', style: AppTextStyles.label),
          const SizedBox(height: 8),
          _PhotoPickerTile(
            label: 'Verso de la carte grise',
            image: truckRegBack,
            onTap: onPickRegBack,
            icon: Icons.article_rounded,
          ).animate(delay: 160.ms).fadeIn(),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border:
                  Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline_rounded,
                    color: AppColors.warning, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Votre compte sera validé par l\'admin sous 24h après soumission.',
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.warning),
                  ),
                ),
              ],
            ),
          ).animate(delay: 200.ms).fadeIn(),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

// ─── Info banner (shared) ─────────────────────────────────────────────────────

class _InfoBanner extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoBanner({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.info.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.info.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.info, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text,
                style: AppTextStyles.bodySecondary
                    .copyWith(color: AppColors.info)),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.1, end: 0);
  }
}
