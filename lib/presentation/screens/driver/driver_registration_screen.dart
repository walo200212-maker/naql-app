import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
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
import '../../widgets/common/wasl_button.dart';
import '../../widgets/common/wasl_toast.dart';

// ─── Local data ───────────────────────────────────────────────────────────────

class _TruckData {
  final String emoji;
  final String label;
  final String desc;
  final String value;
  const _TruckData(this.emoji, this.label, this.desc, this.value);
}

const _trucks = [
  _TruckData('🚐', 'شاحنة صغيرة', 'للأغراض الخفيفة والصناديق', 'Petit camion'),
  _TruckData('🚚', 'شاحنة متوسطة', 'غرفة أو غرفتين — مثالية للعائلات', 'Camion moyen'),
  _TruckData('🚛', 'شاحنة كبيرة', 'نقل البيوت الكاملة والأثاث الثقيل', 'Grand camion'),
];

const _cityEmojis = {'Casablanca': '🏙️', 'Rabat': '🏛️'};
const _cityNames  = {'Casablanca': 'الدار البيضاء', 'Rabat': 'الرباط'};

const _stepTitles = [
  'معلوماتك الشخصية',
  'نوع الشاحنة والسعر',
  'البطاقة الوطنية',
  'الوثائق',
  'المراجعة والإرسال',
];

// ─── Main screen ──────────────────────────────────────────────────────────────

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

  // Step 1 — Personal info
  final _step1Key = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  String _selectedCity = AppConstants.supportedCities[0];

  // Step 2 — Truck type + price
  String _selectedTruckType = AppConstants.truckTypes[0];
  double _pricePerKm = 8.0;

  // Step 3 — CIN
  final _step3Key = GlobalKey<FormState>();
  final _cinController = TextEditingController();
  XFile? _cinFront;
  XFile? _cinBack;

  // Step 4 — Documents
  XFile? _selfie;
  XFile? _driverLicense;

  // Step 5 — Vehicle
  XFile? _truckPhoto;
  XFile? _truckRegFront;
  XFile? _truckRegBack;

  final _storageService = StorageService();
  final _picker = ImagePicker();

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _cinController.dispose();
    super.dispose();
  }

  Future<XFile?> _pickImage({bool camera = false}) async {
    final xfile = await _picker.pickImage(
      source: camera ? ImageSource.camera : ImageSource.gallery,
      imageQuality: 80,
    );
    return xfile;
  }

  void _showError(String msg) =>
      WaslToast.show(context, msg, type: ToastType.error);

  bool _validateStep() {
    switch (_currentStep) {
      case 0:
        return _step1Key.currentState?.validate() ?? false;
      case 1:
        return true; // slider always valid
      case 2:
        if (!(_step3Key.currentState?.validate() ?? false)) return false;
        if (_cinFront == null || _cinBack == null) {
          _showError('أضف صورتَي البطاقة الوطنية (الوجه والظهر)');
          return false;
        }
        return true;
      case 3:
        if (_selfie == null) {
          _showError('التقط صورة سيلفي مع البطاقة الوطنية');
          return false;
        }
        if (_driverLicense == null) {
          _showError('أضف صورة رخصة القيادة');
          return false;
        }
        return true;
      case 4:
        if (_truckPhoto == null || _truckRegFront == null || _truckRegBack == null) {
          _showError('أضف صور الشاحنة وبطاقة التسجيل');
          return false;
        }
        return true;
      default:
        return true;
    }
  }

  Future<void> _nextOrSubmit() async {
    if (!_validateStep()) return;
    if (_currentStep < _totalSteps - 1) {
      setState(() => _currentStep++);
      _pageController.nextPage(
        duration: const Duration(milliseconds: 380),
        curve: Curves.easeOutCubic,
      );
    } else {
      await _submit();
    }
  }

  void _back() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      _pageController.previousPage(
        duration: const Duration(milliseconds: 380),
        curve: Curves.easeOutCubic,
      );
    } else {
      context.pop();
    }
  }

  Future<void> _submit() async {
    setState(() => _isLoading = true);
    try {
      final authUser = FirebaseAuth.instance.currentUser;
      if (authUser == null) {
        _showError('يجب تسجيل الدخول أولاً');
        setState(() => _isLoading = false);
        return;
      }
      final uid = authUser.uid;
      final phone = authUser.phoneNumber ?? authUser.email ?? '';

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
        pricePerKm: _pricePerKm,
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
      await context.read<app_auth.AuthProvider>().createDriverProfile(driver);
      if (!mounted) return;
      context.go(AppRoutes.driverHome);
    } catch (e) {
      if (!mounted) return;
      _showError(e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _TopBar(
              currentStep: _currentStep,
              totalSteps: _totalSteps,
              onBack: _back,
            ),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _Step1PersonalInfo(
                    formKey: _step1Key,
                    nameController: _nameController,
                    selectedCity: _selectedCity,
                    onCityChanged: (v) => setState(() => _selectedCity = v),
                  ),
                  _Step2TruckPrice(
                    selectedTruckType: _selectedTruckType,
                    onTruckTypeChanged: (v) =>
                        setState(() => _selectedTruckType = v),
                    pricePerKm: _pricePerKm,
                    onPriceChanged: (v) => setState(() => _pricePerKm = v),
                  ),
                  _Step3Cin(
                    formKey: _step3Key,
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
                  _Step4Documents(
                    selfie: _selfie,
                    license: _driverLicense,
                    onPickSelfie: () async {
                      final f = await _pickImage(camera: true);
                      if (f != null) setState(() => _selfie = f);
                    },
                    onPickLicense: () async {
                      final f = await _pickImage();
                      if (f != null) setState(() => _driverLicense = f);
                    },
                  ),
                  _Step5Review(
                    driverName: _nameController.text,
                    city: _selectedCity,
                    truckType: _selectedTruckType,
                    pricePerKm: _pricePerKm,
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
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              child: WaslButton(
                label: _currentStep < _totalSteps - 1
                    ? 'التالي'
                    : 'إنشاء حسابي كسائق',
                onPressed: _nextOrSubmit,
                isLoading: _isLoading,
                icon: _currentStep < _totalSteps - 1
                    ? Icons.arrow_forward_rounded
                    : Icons.check_circle_rounded,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Top bar with progress ────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  final int currentStep;
  final int totalSteps;
  final VoidCallback onBack;

  const _TopBar({
    required this.currentStep,
    required this.totalSteps,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 12, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios_rounded,
                    size: 20, color: AppColors.textPrimary),
                onPressed: onBack,
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.primaryGlow,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.3)),
                ),
                child: Text(
                  'الخطوة ${currentStep + 1} / $totalSteps',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: List.generate(totalSteps, (i) {
                final active = i <= currentStep;
                return Expanded(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 350),
                    height: 4,
                    margin: EdgeInsets.only(right: i < totalSteps - 1 ? 5 : 0),
                    decoration: BoxDecoration(
                      color: active ? AppColors.primary : AppColors.surfaceBorder,
                      borderRadius: BorderRadius.circular(2),
                      boxShadow: active
                          ? [
                              BoxShadow(
                                color: AppColors.primaryGlow,
                                blurRadius: 6,
                                spreadRadius: 0,
                              )
                            ]
                          : null,
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              _stepTitles[currentStep],
              style: AppTextStyles.bodySecondary,
            ),
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}

// ─── Step 1: Personal info ────────────────────────────────────────────────────

class _Step1PersonalInfo extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController nameController;
  final String selectedCity;
  final ValueChanged<String> onCityChanged;

  const _Step1PersonalInfo({
    required this.formKey,
    required this.nameController,
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
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary.withValues(alpha: 0.12),
                    AppColors.primaryDark.withValues(alpha: 0.06),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.25)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.local_shipping_rounded,
                        color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'انضم إلى وصل! 🚛',
                          style: AppTextStyles.bodyLarge.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'اكسب المال مع شاحنتك',
                          style: AppTextStyles.bodySecondary,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )
                .animate()
                .fadeIn(duration: 400.ms)
                .slideY(begin: -0.1, end: 0),

            const SizedBox(height: 28),

            Text('الاسم الكامل', style: AppTextStyles.label),
            const SizedBox(height: 8),
            TextFormField(
              controller: nameController,
              style: AppTextStyles.body,
              decoration: const InputDecoration(
                hintText: 'محمد العلمي',
                prefixIcon:
                    Icon(Icons.person_rounded, color: AppColors.primary),
              ),
              validator: (v) => Validators.required(v, 'الاسم'),
            ).animate(delay: 80.ms).fadeIn(duration: 400.ms),

            const SizedBox(height: 24),

            Text('مدينة العمل', style: AppTextStyles.label),
            const SizedBox(height: 12),

            Row(
              children: AppConstants.supportedCities.map((city) {
                final selected = selectedCity == city;
                final emoji = _cityEmojis[city] ?? '';
                final name  = _cityNames[city] ?? city;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => onCityChanged(city),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeOutCubic,
                      margin: EdgeInsets.only(
                          right: city == AppConstants.supportedCities.first
                              ? 8
                              : 0),
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      decoration: BoxDecoration(
                        color: selected
                            ? AppColors.primary.withValues(alpha: 0.12)
                            : AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: selected
                              ? AppColors.primary
                              : AppColors.surfaceBorder,
                          width: selected ? 2 : 1,
                        ),
                        boxShadow: selected
                            ? [
                                BoxShadow(
                                  color: AppColors.primaryGlow,
                                  blurRadius: 16,
                                )
                              ]
                            : null,
                      ),
                      child: Column(
                        children: [
                          Text(emoji,
                              style: const TextStyle(fontSize: 22)),
                          const SizedBox(height: 4),
                          Text(
                            name,
                            style: AppTextStyles.body.copyWith(
                              color: selected
                                  ? AppColors.primary
                                  : AppColors.textPrimary,
                              fontWeight: selected
                                  ? FontWeight.w700
                                  : FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ).animate(delay: 160.ms).fadeIn(duration: 400.ms),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

// ─── Step 2: Truck type + price ───────────────────────────────────────────────

class _Step2TruckPrice extends StatelessWidget {
  final String selectedTruckType;
  final ValueChanged<String> onTruckTypeChanged;
  final double pricePerKm;
  final ValueChanged<double> onPriceChanged;

  const _Step2TruckPrice({
    required this.selectedTruckType,
    required this.onTruckTypeChanged,
    required this.pricePerKm,
    required this.onPriceChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('اختر نوع شاحنتك', style: AppTextStyles.label),
          const SizedBox(height: 12),

          // Truck type animated cards
          ..._trucks.asMap().entries.map((entry) {
            final i = entry.key;
            final truck = entry.value;
            final selected = selectedTruckType == truck.value;
            return GestureDetector(
              onTap: () => onTruckTypeChanged(truck.value),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutCubic,
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: selected
                      ? AppColors.primary.withValues(alpha: 0.1)
                      : AppColors.surface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: selected ? AppColors.primary : AppColors.surfaceBorder,
                    width: selected ? 2 : 1,
                  ),
                  boxShadow: selected
                      ? [
                          BoxShadow(
                            color: AppColors.primaryGlow,
                            blurRadius: 20,
                          )
                        ]
                      : null,
                ),
                child: Row(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: selected
                            ? AppColors.primary.withValues(alpha: 0.18)
                            : AppColors.surfaceHigh,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Center(
                        child: Text(truck.emoji,
                            style: const TextStyle(fontSize: 30)),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            truck.label,
                            style: AppTextStyles.bodyLarge.copyWith(
                              color: selected
                                  ? AppColors.primary
                                  : AppColors.textPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(truck.desc, style: AppTextStyles.bodySecondary),
                        ],
                      ),
                    ),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: selected ? AppColors.primary : Colors.transparent,
                        border: Border.all(
                          color: selected
                              ? AppColors.primary
                              : AppColors.surfaceBorder,
                          width: 2,
                        ),
                      ),
                      child: selected
                          ? const Icon(Icons.check_rounded,
                              color: Colors.white, size: 14)
                          : null,
                    ),
                  ],
                ),
              )
                  .animate(delay: Duration(milliseconds: 80 + i * 60))
                  .fadeIn(duration: 400.ms)
                  .slideY(begin: 0.08, end: 0),
            );
          }),

          const SizedBox(height: 28),

          // Price slider
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('سعرك لكل كيلومتر', style: AppTextStyles.label),
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: pricePerKm.toStringAsFixed(0),
                      style: GoogleFonts.poppins(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                    ),
                    TextSpan(
                      text: ' درهم/كم',
                      style: AppTextStyles.bodySecondary.copyWith(fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          )
              .animate(delay: 300.ms)
              .fadeIn(duration: 400.ms),

          const SizedBox(height: 8),

          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 6,
              activeTrackColor: AppColors.primary,
              inactiveTrackColor: AppColors.surfaceBorder,
              thumbColor: AppColors.primary,
              thumbShape:
                  const RoundSliderThumbShape(enabledThumbRadius: 12),
              overlayColor: AppColors.primaryGlow,
              overlayShape:
                  const RoundSliderOverlayShape(overlayRadius: 24),
            ),
            child: Slider(
              value: pricePerKm,
              min: 5,
              max: 30,
              divisions: 25,
              onChanged: onPriceChanged,
            ),
          )
              .animate(delay: 350.ms)
              .fadeIn(duration: 400.ms),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('5 درهم',
                  style: AppTextStyles.caption
                      .copyWith(color: AppColors.textHint)),
              Text('30 درهم',
                  style: AppTextStyles.caption
                      .copyWith(color: AppColors.textHint)),
            ],
          ),

          const SizedBox(height: 16),

          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: AppColors.success.withValues(alpha: 0.25)),
            ),
            child: Row(
              children: [
                const Icon(Icons.tips_and_updates_rounded,
                    color: AppColors.success, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'متوسط السعر في المغرب 7–12 درهم/كم',
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.success),
                  ),
                ),
              ],
            ),
          ).animate(delay: 400.ms).fadeIn(duration: 400.ms),
        ],
      ),
    );
  }
}

// ─── Step 3: CIN ──────────────────────────────────────────────────────────────

class _Step3Cin extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController cinController;
  final XFile? cinFront;
  final XFile? cinBack;
  final VoidCallback onPickFront;
  final VoidCallback onPickBack;

  const _Step3Cin({
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
              color: AppColors.info,
              text: 'صوّر بطاقتك الوطنية (الوجه والظهر) بوضوح وبدون انعكاسات.',
            ),
            const SizedBox(height: 24),

            Text('رقم البطاقة الوطنية', style: AppTextStyles.label),
            const SizedBox(height: 8),
            TextFormField(
              controller: cinController,
              style: AppTextStyles.body,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(
                hintText: 'مثال: AB123456',
                prefixIcon:
                    Icon(Icons.badge_rounded, color: AppColors.primary),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'رقم البطاقة مطلوب';
                if (v.trim().length < 5) return 'رقم البطاقة غير صالح';
                return null;
              },
            ).animate(delay: 80.ms).fadeIn(),

            const SizedBox(height: 20),

            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('الوجه', style: AppTextStyles.label),
                      const SizedBox(height: 8),
                      _PhotoPickerTile(
                        label: 'وجه البطاقة',
                        image: cinFront,
                        onTap: onPickFront,
                        icon: Icons.credit_card_rounded,
                      ).animate(delay: 120.ms).fadeIn(),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('الظهر', style: AppTextStyles.label),
                      const SizedBox(height: 8),
                      _PhotoPickerTile(
                        label: 'ظهر البطاقة',
                        image: cinBack,
                        onTap: onPickBack,
                        icon: Icons.credit_card_rounded,
                      ).animate(delay: 160.ms).fadeIn(),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

// ─── Step 4: Documents ────────────────────────────────────────────────────────

class _Step4Documents extends StatelessWidget {
  final XFile? selfie;
  final XFile? license;
  final VoidCallback onPickSelfie;
  final VoidCallback onPickLicense;

  const _Step4Documents({
    required this.selfie,
    required this.license,
    required this.onPickSelfie,
    required this.onPickLicense,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _InfoBanner(
            icon: Icons.shield_rounded,
            color: AppColors.primary,
            text: 'نحتاج هذه الوثائق للتحقق من هويتك وضمان أمان منصتنا.',
          ),
          const SizedBox(height: 24),

          Text('سيلفي مع البطاقة الوطنية', style: AppTextStyles.label),
          const SizedBox(height: 4),
          Text(
            'وجهك كاملاً مرئي • البطاقة مقروءة • إضاءة جيدة',
            style: AppTextStyles.caption.copyWith(color: AppColors.textHint),
          ),
          const SizedBox(height: 10),
          _PhotoPickerTile(
            label: 'اضغط لفتح الكاميرا',
            image: selfie,
            onTap: onPickSelfie,
            icon: Icons.camera_alt_rounded,
            height: 200,
          ).animate(delay: 80.ms).fadeIn(),

          const SizedBox(height: 24),

          Text('رخصة القيادة', style: AppTextStyles.label),
          const SizedBox(height: 4),
          Text(
            'يجب أن تكون صالحة ومقروءة',
            style: AppTextStyles.caption.copyWith(color: AppColors.textHint),
          ),
          const SizedBox(height: 10),
          _PhotoPickerTile(
            label: 'صورة رخصة القيادة',
            image: license,
            onTap: onPickLicense,
            icon: Icons.drive_eta_rounded,
            height: 150,
          ).animate(delay: 160.ms).fadeIn(),

          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

// ─── Step 5: Review & submit ──────────────────────────────────────────────────

class _Step5Review extends StatelessWidget {
  final String driverName;
  final String city;
  final String truckType;
  final double pricePerKm;
  final XFile? truckPhoto;
  final XFile? truckRegFront;
  final XFile? truckRegBack;
  final VoidCallback onPickTruck;
  final VoidCallback onPickRegFront;
  final VoidCallback onPickRegBack;

  const _Step5Review({
    required this.driverName,
    required this.city,
    required this.truckType,
    required this.pricePerKm,
    required this.truckPhoto,
    required this.truckRegFront,
    required this.truckRegBack,
    required this.onPickTruck,
    required this.onPickRegFront,
    required this.onPickRegBack,
  });

  String get _truckLabel {
    final match = _trucks.where((t) => t.value == truckType);
    return match.isNotEmpty ? '${match.first.emoji} ${match.first.label}' : truckType;
  }

  String get _cityLabel => '${_cityEmojis[city] ?? ''} ${_cityNames[city] ?? city}'.trim();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Review summary card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.surfaceBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.fact_check_rounded,
                        color: AppColors.primary, size: 20),
                    const SizedBox(width: 8),
                    Text('ملخص معلوماتك',
                        style: AppTextStyles.bodyLarge
                            .copyWith(fontWeight: FontWeight.w700)),
                  ],
                ),
                const SizedBox(height: 16),
                Divider(color: AppColors.surfaceBorder, height: 1),
                const SizedBox(height: 16),
                _ReviewRow(icon: Icons.person_rounded, label: 'الاسم', value: driverName.isNotEmpty ? driverName : '—'),
                _ReviewRow(icon: Icons.location_city_rounded, label: 'المدينة', value: _cityLabel),
                _ReviewRow(icon: Icons.local_shipping_rounded, label: 'نوع الشاحنة', value: _truckLabel),
                _ReviewRow(
                  icon: Icons.speed_rounded,
                  label: 'السعر',
                  value: '${pricePerKm.toStringAsFixed(0)} درهم/كم',
                  valueColor: AppColors.primary,
                ),
              ],
            ),
          )
              .animate()
              .fadeIn(duration: 400.ms)
              .slideY(begin: 0.08, end: 0),

          const SizedBox(height: 24),

          Text('صورة الشاحنة', style: AppTextStyles.label),
          const SizedBox(height: 10),
          _PhotoPickerTile(
            label: 'صورة خارجية للشاحنة',
            image: truckPhoto,
            onTap: onPickTruck,
            icon: Icons.local_shipping_rounded,
            height: 160,
          ).animate(delay: 80.ms).fadeIn(),

          const SizedBox(height: 20),

          Text('بطاقة تسجيل الشاحنة', style: AppTextStyles.label),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('الوجه', style: AppTextStyles.caption.copyWith(color: AppColors.textHint)),
                    const SizedBox(height: 6),
                    _PhotoPickerTile(
                      label: 'وجه البطاقة',
                      image: truckRegFront,
                      onTap: onPickRegFront,
                      icon: Icons.article_rounded,
                    ).animate(delay: 120.ms).fadeIn(),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('الظهر', style: AppTextStyles.caption.copyWith(color: AppColors.textHint)),
                    const SizedBox(height: 6),
                    _PhotoPickerTile(
                      label: 'ظهر البطاقة',
                      image: truckRegBack,
                      onTap: onPickRegBack,
                      icon: Icons.article_rounded,
                    ).animate(delay: 160.ms).fadeIn(),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: AppColors.warning.withValues(alpha: 0.25)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline_rounded,
                    color: AppColors.warning, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'سيتم مراجعة حسابك من طرف الإدارة خلال 24 ساعة.',
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

class _ReviewRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _ReviewRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.textHint),
          const SizedBox(width: 8),
          Text(label, style: AppTextStyles.bodySecondary),
          const Spacer(),
          Text(
            value,
            style: AppTextStyles.body.copyWith(
              fontWeight: FontWeight.w600,
              color: valueColor ?? AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Reusable photo picker tile (dashed → solid) ──────────────────────────────

class _PhotoPickerTile extends StatefulWidget {
  final String label;
  final XFile? image;
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
  State<_PhotoPickerTile> createState() => _PhotoPickerTileState();
}

class _PhotoPickerTileState extends State<_PhotoPickerTile> {
  Future<dynamic>? _bytesFuture;

  @override
  void initState() {
    super.initState();
    if (widget.image != null) {
      _bytesFuture = widget.image!.readAsBytes();
    }
  }

  @override
  void didUpdateWidget(_PhotoPickerTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.image != oldWidget.image) {
      _bytesFuture = widget.image?.readAsBytes();
    }
  }

  @override
  Widget build(BuildContext context) {
    final filled = widget.image != null;
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        height: widget.height,
        decoration: BoxDecoration(
          color: filled
              ? AppColors.primary.withValues(alpha: 0.06)
              : AppColors.surfaceHigh,
          borderRadius: BorderRadius.circular(16),
        ),
        child: filled
            ? ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    FutureBuilder<dynamic>(
                      future: _bytesFuture,
                      builder: (_, snap) => snap.hasData
                          ? Image.memory(snap.data!, fit: BoxFit.cover)
                          : const SizedBox(),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.3),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: const BoxDecoration(
                          color: AppColors.success,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.check_rounded,
                            color: Colors.white, size: 16),
                      ),
                    ),
                    Positioned(
                      bottom: 8,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'اضغط للتغيير',
                            style: AppTextStyles.caption
                                .copyWith(color: Colors.white),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              )
            : CustomPaint(
                painter: _DashedBorderPainter(
                  color: AppColors.surfaceBorder,
                  radius: 16,
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(widget.icon,
                            color: AppColors.textHint, size: 24),
                      ),
                      const SizedBox(height: 8),
                      Text(widget.label, style: AppTextStyles.bodySecondary),
                      const SizedBox(height: 2),
                      Text(
                        'اضغط للإضافة',
                        style: AppTextStyles.caption
                            .copyWith(color: AppColors.textHint),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  final Color color;
  final double radius;

  const _DashedBorderPainter({required this.color, required this.radius});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(0.75, 0.75, size.width - 1.5, size.height - 1.5),
        Radius.circular(radius),
      ));

    const dashWidth = 7.0;
    const dashSpace = 5.0;
    final metric = path.computeMetrics().first;
    var d = 0.0;
    while (d < metric.length) {
      canvas.drawPath(metric.extractPath(d, d + dashWidth), paint);
      d += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(_DashedBorderPainter old) => old.color != color;
}

// ─── Info banner (shared) ─────────────────────────────────────────────────────

class _InfoBanner extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String text;

  const _InfoBanner({
    required this.icon,
    required this.color,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: AppTextStyles.bodySecondary.copyWith(color: color),
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 400.ms)
        .slideY(begin: -0.1, end: 0);
  }
}
