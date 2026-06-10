import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_routes.dart';
import '../../../data/models/job_model.dart';
import '../../../data/services/geocoding_service.dart';
import '../../providers/auth_provider.dart';
import '../../providers/job_provider.dart';
import '../../widgets/common/wasl_button.dart';
import '../../widgets/common/wasl_toast.dart';

// Arabic city display labels
const _cityDisplay = {
  'Casablanca': 'الدار البيضاء',
  'Rabat': 'الرباط',
  'Casablanca ↔ Rabat': 'الدار البيضاء ↔ الرباط',
};

class PostJobScreen extends StatefulWidget {
  const PostJobScreen({super.key});

  @override
  State<PostJobScreen> createState() => _PostJobScreenState();
}

class _PostJobScreenState extends State<PostJobScreen> {
  final _descController = TextEditingController();
  final _pickupController = TextEditingController();
  final _dropoffController = TextEditingController();
  final _picker = ImagePicker();

  @override
  void dispose() {
    _descController.dispose();
    _pickupController.dispose();
    _dropoffController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final provider = context.read<JobProvider>();
    if (provider.selectedPhotos.length >= 5) {
      WaslToast.show(context, 'يمكنك إضافة 5 صور كحد أقصى',
          type: ToastType.warning);
      return;
    }
    final xfile = await _picker.pickImage(
        source: ImageSource.gallery, imageQuality: 70);
    if (xfile != null) provider.addPhoto(xfile);
  }

  void _confirmPickup() {
    final provider = context.read<JobProvider>();
    final text = _pickupController.text.trim();
    if (text.isEmpty) {
      WaslToast.show(context, 'أدخل عنوان الانطلاق', type: ToastType.error);
      return;
    }
    provider.setPickup(LocationData(
      address: text,
      lat: 33.5731,
      lng: -7.5898,
    ));
    FocusScope.of(context).unfocus();
  }

  void _confirmDropoff() {
    final provider = context.read<JobProvider>();
    final text = _dropoffController.text.trim();
    if (text.isEmpty) {
      WaslToast.show(context, 'أدخل عنوان الوصول', type: ToastType.error);
      return;
    }
    provider.setDropoff(LocationData(
      address: text,
      lat: 34.0209,
      lng: -6.8416,
    ));
    FocusScope.of(context).unfocus();
  }

  Future<void> _post() async {
    final provider = context.read<JobProvider>();
    final auth = context.read<AuthProvider>();
    if (provider.pickup == null || provider.dropoff == null) {
      WaslToast.show(context, 'حدد عنوان الانطلاق والوصول',
          type: ToastType.error);
      return;
    }
    provider.setDescription(_descController.text.trim());
    final jobId = await provider.postJob(auth.uid!);
    if (!mounted) return;
    if (jobId != null) {
      context.pushReplacement(AppRoutes.jobPosted, extra: jobId);
    } else {
      WaslToast.show(context, provider.error ?? 'حدث خطأ، حاول مجدداً',
          type: ToastType.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<JobProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'نشر طلب نقل',
          style: GoogleFonts.cairo(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // City selector
            Text('اختر المدينة', style: AppTextStyles.label),
            const SizedBox(height: 10),
            SizedBox(
              height: 46,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  ...AppConstants.supportedCities,
                  AppConstants.intercityCategory,
                ].map((c) {
                  final selected = provider.city == c;
                  final label = _cityDisplay[c] ?? c;
                  return GestureDetector(
                    onTap: () => provider.setCity(c),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 11),
                      decoration: BoxDecoration(
                        color: selected
                            ? AppColors.primary
                            : AppColors.surface,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: selected
                              ? AppColors.primary
                              : AppColors.surfaceBorder,
                        ),
                        boxShadow: selected
                            ? [
                                BoxShadow(
                                  color: AppColors.primaryGlow,
                                  blurRadius: 12,
                                )
                              ]
                            : null,
                      ),
                      child: Text(
                        label,
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
                  );
                }).toList(),
              ),
            ).animate().fadeIn(duration: 350.ms),

            const SizedBox(height: 24),

            // Route card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.surfaceBorder),
              ),
              child: Column(
                children: [
                  // Pickup
                  _LocationField(
                    controller: _pickupController,
                    hint: 'عنوان الانطلاق',
                    iconColor: AppColors.success,
                    icon: Icons.circle,
                    confirmed: provider.pickup != null,
                    confirmedAddress: provider.pickup?.address,
                    onConfirm: _confirmPickup,
                    onLocationSelected: (loc) =>
                        context.read<JobProvider>().setPickup(loc),
                  ).animate(delay: 60.ms).fadeIn(duration: 350.ms),

                  // Dashed connector
                  Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: Row(
                      children: [
                        Column(
                          children: List.generate(
                            3,
                            (_) => Container(
                              width: 2,
                              height: 5,
                              margin: const EdgeInsets.symmetric(vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceBorder,
                                borderRadius: BorderRadius.circular(1),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Dropoff
                  _LocationField(
                    controller: _dropoffController,
                    hint: 'عنوان الوصول',
                    iconColor: AppColors.primary,
                    icon: Icons.location_on_rounded,
                    confirmed: provider.dropoff != null,
                    confirmedAddress: provider.dropoff?.address,
                    onConfirm: _confirmDropoff,
                    onLocationSelected: (loc) =>
                        context.read<JobProvider>().setDropoff(loc),
                  ).animate(delay: 100.ms).fadeIn(duration: 350.ms),
                ],
              ),
            ).animate().fadeIn(duration: 350.ms).slideY(begin: 0.06, end: 0),

            // Distance + price estimate
            if (provider.distanceKm > 0) ...[
              const SizedBox(height: 12),
              _EstimateBanner(distanceKm: provider.distanceKm)
                  .animate()
                  .fadeIn(duration: 300.ms)
                  .slideY(begin: 0.1, end: 0),
            ],

            const SizedBox(height: 24),

            // Description
            Text('وصف البضائع والأثاث', style: AppTextStyles.label),
            const SizedBox(height: 10),
            TextFormField(
              controller: _descController,
              maxLines: 4,
              style: AppTextStyles.body,
              decoration: const InputDecoration(
                hintText: 'مثال: كنبة 3 مقاعد، خزانة، 10 صناديق...',
                alignLabelWithHint: true,
              ),
            )
                .animate(delay: 100.ms)
                .fadeIn(duration: 350.ms),

            const SizedBox(height: 24),

            // Photos strip
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('صور البضائع (اختياري)', style: AppTextStyles.label),
                Text(
                  '${provider.selectedPhotos.length}/5',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: provider.selectedPhotos.length == 5
                        ? AppColors.primary
                        : AppColors.textHint,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 90,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  // Add button
                  GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      width: 90,
                      height: 90,
                      margin: const EdgeInsets.only(right: 10),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceHigh,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.surfaceBorder),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.add_a_photo_rounded,
                              color: AppColors.primary, size: 24),
                          const SizedBox(height: 4),
                          Text('إضافة',
                              style: AppTextStyles.caption
                                  .copyWith(color: AppColors.primary)),
                        ],
                      ),
                    ),
                  ),

                  // Photos
                  ...provider.selectedPhotos.asMap().entries.map((entry) {
                    return Container(
                      margin: const EdgeInsets.only(right: 10),
                      child: Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: FutureBuilder<dynamic>(
                              future: entry.value.readAsBytes(),
                              builder: (ctx, snap) => snap.hasData
                                  ? Image.memory(
                                      snap.data!,
                                      width: 90,
                                      height: 90,
                                      fit: BoxFit.cover,
                                    )
                                  : Container(
                                      width: 90,
                                      height: 90,
                                      color: AppColors.surfaceHigh,
                                    ),
                            ),
                          ),
                          Positioned(
                            top: 4,
                            right: 4,
                            child: GestureDetector(
                              onTap: () =>
                                  provider.removePhoto(entry.key),
                              child: Container(
                                width: 22,
                                height: 22,
                                decoration: const BoxDecoration(
                                  color: AppColors.error,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.close_rounded,
                                    color: Colors.white, size: 13),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ).animate(delay: 150.ms).fadeIn(duration: 350.ms),

            const SizedBox(height: 32),

            WaslButton(
              label: 'نشر الطلب الآن',
              onPressed: _post,
              isLoading: provider.isLoading,
              icon: Icons.send_rounded,
            )
                .animate(delay: 200.ms)
                .fadeIn(duration: 400.ms)
                .slideY(begin: 0.1, end: 0),
          ],
        ),
      ),
    );
  }
}

// ─── Location field row ───────────────────────────────────────────────────────

class _LocationField extends StatefulWidget {
  final TextEditingController controller;
  final String hint;
  final Color iconColor;
  final IconData icon;
  final bool confirmed;
  final String? confirmedAddress;
  final VoidCallback onConfirm;
  final void Function(LocationData)? onLocationSelected;

  const _LocationField({
    required this.controller,
    required this.hint,
    required this.iconColor,
    required this.icon,
    required this.confirmed,
    required this.confirmedAddress,
    required this.onConfirm,
    this.onLocationSelected,
  });

  @override
  State<_LocationField> createState() => _LocationFieldState();
}

class _LocationFieldState extends State<_LocationField> {
  final _geocoder = GeocodingService();
  List<PlaceSuggestion> _suggestions = [];
  bool _loading = false;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  void _onTextChanged() {
    final text = widget.controller.text.trim();
    _debounce?.cancel();
    if (text.length < 3) {
      if (_suggestions.isNotEmpty || _loading) {
        setState(() {
          _suggestions = [];
          _loading = false;
        });
      }
      return;
    }
    _debounce =
        Timer(const Duration(milliseconds: 600), () => _fetch(text));
  }

  Future<void> _fetch(String query) async {
    if (!mounted) return;
    setState(() => _loading = true);
    final results = await _geocoder.searchMorocco(query);
    if (!mounted) return;
    setState(() {
      _suggestions = results;
      _loading = false;
    });
  }

  void _select(PlaceSuggestion s) {
    widget.controller.removeListener(_onTextChanged);
    widget.controller.text = s.shortName;
    widget.controller.addListener(_onTextChanged);
    setState(() => _suggestions = []);
    FocusScope.of(context).unfocus();
    widget.onLocationSelected
        ?.call(LocationData(address: s.displayName, lat: s.lat, lng: s.lng));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Input row
        Row(
          children: [
            Icon(widget.icon, color: widget.iconColor, size: 14),
            const SizedBox(width: 10),
            Expanded(
              child: TextFormField(
                controller: widget.controller,
                style: AppTextStyles.body,
                decoration: InputDecoration(
                  hintText: widget.hint,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
                onFieldSubmitted: (_) => widget.onConfirm(),
              ),
            ),
            const SizedBox(width: 8),
            if (_loading)
              const SizedBox(
                width: 34,
                height: 34,
                child: Center(
                  child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: AppColors.primary),
                  ),
                ),
              )
            else
              GestureDetector(
                onTap: widget.onConfirm,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: widget.confirmed
                        ? AppColors.success.withValues(alpha: 0.15)
                        : AppColors.surfaceHigh,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: widget.confirmed
                          ? AppColors.success
                          : AppColors.surfaceBorder,
                    ),
                  ),
                  child: Icon(
                    widget.confirmed
                        ? Icons.check_rounded
                        : Icons.arrow_forward_rounded,
                    color: widget.confirmed
                        ? AppColors.success
                        : AppColors.textHint,
                    size: 16,
                  ),
                ),
              ),
          ],
        ),

        // Confirmed address label
        if (widget.confirmed && widget.confirmedAddress != null) ...[
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(right: 24),
            child: Text(
              '✓ ${widget.confirmedAddress}',
              style:
                  AppTextStyles.caption.copyWith(color: AppColors.success),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],

        // Autocomplete suggestions
        if (_suggestions.isNotEmpty) ...[
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: AppColors.surfaceHigh,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.surfaceBorder),
            ),
            child: Column(
              children:
                  _suggestions.take(4).toList().asMap().entries.map((e) {
                final idx = e.key;
                final s = e.value;
                final total =
                    _suggestions.length > 4 ? 4 : _suggestions.length;
                final isLast = idx == total - 1;
                final parts = s.displayName.split(',');
                final cityPart =
                    parts.length > 2 ? parts[2].trim() : '';
                return Column(
                  children: [
                    InkWell(
                      onTap: () => _select(s),
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        child: Row(
                          children: [
                            const Icon(Icons.location_on_outlined,
                                color: AppColors.primary, size: 18),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    s.shortName,
                                    style: AppTextStyles.body.copyWith(
                                        fontWeight: FontWeight.w600),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if (cityPart.isNotEmpty)
                                    Text(
                                      cityPart,
                                      style: AppTextStyles.caption,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (!isLast)
                      Divider(
                        height: 1,
                        color: AppColors.surfaceBorder,
                        indent: 14,
                        endIndent: 14,
                      ),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ],
    );
  }
}

// ─── Estimate banner ──────────────────────────────────────────────────────────

class _EstimateBanner extends StatelessWidget {
  final double distanceKm;

  const _EstimateBanner({required this.distanceKm});

  @override
  Widget build(BuildContext context) {
    final minEstimate = (distanceKm * 5).toStringAsFixed(0);
    final maxEstimate = (distanceKm * 15).toStringAsFixed(0);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.primaryGlow,
        borderRadius: BorderRadius.circular(14),
        border:
            Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.straighten_rounded,
              color: AppColors.primary, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'المسافة التقديرية: ${distanceKm.toStringAsFixed(1)} كم',
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'السعر المتوقع: $minEstimate – $maxEstimate درهم',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.primary.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
