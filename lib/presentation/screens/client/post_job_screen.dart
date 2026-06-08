import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_routes.dart';
import '../../../data/models/job_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/job_provider.dart';
import '../../widgets/common/naql_button.dart';

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
    if (provider.selectedPhotos.length >= 5) return;
    final xfile =
        await _picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (xfile != null) provider.addPhoto(File(xfile.path));
  }

  Future<void> _setPickup() async {
    // In production: open Google Places search
    // For now: use a hardcoded demo location based on text input
    final provider = context.read<JobProvider>();
    provider.setPickup(LocationData(
      address: _pickupController.text.isNotEmpty
          ? _pickupController.text
          : 'Casablanca Centre',
      lat: 33.5731,
      lng: -7.5898,
    ));
  }

  Future<void> _setDropoff() async {
    final provider = context.read<JobProvider>();
    provider.setDropoff(LocationData(
      address: _dropoffController.text.isNotEmpty
          ? _dropoffController.text
          : 'Rabat Centre',
      lat: 34.0209,
      lng: -6.8416,
    ));
  }

  Future<void> _post() async {
    final provider = context.read<JobProvider>();
    final auth = context.read<AuthProvider>();
    if (provider.pickup == null || provider.dropoff == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Veuillez saisir le départ et l\'arrivée')),
      );
      return;
    }
    provider.setDescription(_descController.text.trim());
    final jobId = await provider.postJob(auth.uid!);
    if (!mounted) return;
    if (jobId != null) {
      context.pushReplacement(AppRoutes.jobPosted, extra: jobId);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(provider.error ?? 'Erreur')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<JobProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Publier une demande'),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // City selector
            Text('Ville', style: AppTextStyles.label),
            const SizedBox(height: 8),
            SizedBox(
              height: 44,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  ...AppConstants.supportedCities,
                  AppConstants.intercityCategory,
                ].map((c) {
                  final selected = provider.city == c;
                  return GestureDetector(
                    onTap: () => provider.setCity(c),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: selected
                            ? AppColors.primary
                            : AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: Text(
                        c,
                        style: AppTextStyles.body.copyWith(
                          color: selected
                              ? Colors.white
                              : AppColors.textSecondary,
                          fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 24),

            // Pickup
            Text('Adresse de départ', style: AppTextStyles.label),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _pickupController,
                    style: AppTextStyles.body,
                    decoration: const InputDecoration(
                      hintText: 'Ex: Maarif, Casablanca',
                      prefixIcon: Icon(Icons.circle_rounded,
                          color: AppColors.success, size: 14),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 8),
                _IconBtn(
                    icon: Icons.check_rounded, onTap: _setPickup),
              ],
            ),
            if (provider.pickup != null) ...[
              const SizedBox(height: 4),
              Text('✓ ${provider.pickup!.address}',
                  style:
                      AppTextStyles.caption.copyWith(color: AppColors.success)),
            ],

            const SizedBox(height: 16),

            // Dropoff
            Text('Adresse d\'arrivée', style: AppTextStyles.label),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _dropoffController,
                    style: AppTextStyles.body,
                    decoration: const InputDecoration(
                      hintText: 'Ex: Agdal, Rabat',
                      prefixIcon: Icon(Icons.location_on_rounded,
                          color: AppColors.primary, size: 18),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 8),
                _IconBtn(icon: Icons.check_rounded, onTap: _setDropoff),
              ],
            ),
            if (provider.dropoff != null) ...[
              const SizedBox(height: 4),
              Text('✓ ${provider.dropoff!.address}',
                  style:
                      AppTextStyles.caption.copyWith(color: AppColors.success)),
            ],

            // Distance badge
            if (provider.distanceKm > 0) ...[
              const SizedBox(height: 12),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.straighten_rounded,
                        color: AppColors.primary, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      'Distance estimée: ${provider.distanceKm.toStringAsFixed(1)} km',
                      style: AppTextStyles.body
                          .copyWith(color: AppColors.primary, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 24),

            // Description
            Text('Décrivez vos affaires', style: AppTextStyles.label),
            const SizedBox(height: 8),
            TextFormField(
              controller: _descController,
              maxLines: 4,
              style: AppTextStyles.body,
              decoration: const InputDecoration(
                hintText:
                    'Ex: Canapé 3 places, armoire, 10 cartons...',
              ),
            ),

            const SizedBox(height: 24),

            // Photos
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Photos des affaires', style: AppTextStyles.label),
                Text('${provider.selectedPhotos.length}/5',
                    style: AppTextStyles.caption),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 88,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  // Add button
                  GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      width: 88,
                      height: 88,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: AppColors.border,
                            style: BorderStyle.solid),
                      ),
                      child: const Icon(Icons.add_a_photo_rounded,
                          color: AppColors.textHint),
                    ),
                  ),
                  // Selected photos
                  ...provider.selectedPhotos.asMap().entries.map((entry) {
                    return Stack(
                      children: [
                        Container(
                          width: 88,
                          height: 88,
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            image: DecorationImage(
                              image: FileImage(entry.value),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        Positioned(
                          top: 4,
                          right: 12,
                          child: GestureDetector(
                            onTap: () => provider.removePhoto(entry.key),
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: const BoxDecoration(
                                color: AppColors.error,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.close_rounded,
                                  color: Colors.white, size: 14),
                            ),
                          ),
                        ),
                      ],
                    );
                  }),
                ],
              ),
            ),

            const SizedBox(height: 32),

            NaqlButton(
              label: 'Publier ma demande',
              onPressed: _post,
              isLoading: provider.isLoading,
              icon: Icons.send_rounded,
            )
                .animate(delay: 200.ms)
                .fadeIn(duration: 400.ms),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _IconBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 56,
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(icon, color: Colors.white),
      ),
    );
  }
}
