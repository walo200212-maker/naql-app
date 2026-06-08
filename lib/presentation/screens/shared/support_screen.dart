import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/localization/app_strings.dart';

class SupportScreen extends StatefulWidget {
  const SupportScreen({super.key});

  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late final WebViewController _webController;
  bool _webLoaded = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_onTabChanged);

    _webController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(AppColors.background)
      ..setNavigationDelegate(NavigationDelegate(
        onPageFinished: (_) {
          if (mounted) setState(() => _webLoaded = true);
        },
      ))
      ..loadRequest(Uri.parse(
          'https://tawk.to/chat/${AppConstants.tawkPropertyId}/${AppConstants.tawkWidgetId}'));
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) setState(() {});
  }

  @override
  void dispose() {
    _tabController
      ..removeListener(_onTabChanged)
      ..dispose();
    super.dispose();
  }

  Future<void> _openWhatsApp() async {
    final uri = Uri.parse(
        'https://wa.me/${AppConstants.adminWhatsApp.replaceAll('+', '')}');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Aide & Support'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          indicatorSize: TabBarIndicatorSize.label,
          tabs: const [
            Tab(text: 'Chat'),
            Tab(text: 'WhatsApp'),
            Tab(text: 'FAQ'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _ChatTab(controller: _webController, isLoaded: _webLoaded),
          _WhatsAppTab(onOpen: _openWhatsApp),
          _FaqTab(),
        ],
      ),
    );
  }
}

// ── Chat Tab ─────────────────────────────────────────────────────────────────

class _ChatTab extends StatelessWidget {
  final WebViewController controller;
  final bool isLoaded;

  const _ChatTab({required this.controller, required this.isLoaded});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        WebViewWidget(controller: controller),
        if (!isLoaded)
          Container(
            color: AppColors.background,
            child: const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          ),
      ],
    );
  }
}

// ── WhatsApp Tab ──────────────────────────────────────────────────────────────

class _WhatsAppTab extends StatelessWidget {
  final VoidCallback onOpen;

  const _WhatsAppTab({required this.onOpen});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.chat_rounded,
                  color: AppColors.success, size: 48),
            )
                .animate()
                .scale(duration: 500.ms, curve: Curves.elasticOut),

            const SizedBox(height: 24),

            Text('Contacter l\'admin',
                style: AppTextStyles.h2, textAlign: TextAlign.center)
                .animate(delay: 100.ms)
                .fadeIn(duration: 400.ms),

            const SizedBox(height: 8),

            Text(
              'Réponse rapide via WhatsApp pour toute question ou problème urgent.',
              style: AppTextStyles.bodySecondary,
              textAlign: TextAlign.center,
            )
                .animate(delay: 150.ms)
                .fadeIn(duration: 400.ms),

            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onOpen,
                icon: const Icon(Icons.open_in_new_rounded),
                label: const Text('Ouvrir WhatsApp'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF25D366),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
              ),
            )
                .animate(delay: 200.ms)
                .fadeIn(duration: 400.ms),

            const SizedBox(height: 16),

            Text(AppConstants.adminWhatsApp,
                style: AppTextStyles.caption)
                .animate(delay: 250.ms)
                .fadeIn(duration: 400.ms),
          ],
        ),
      ),
    );
  }
}

// ── FAQ Tab ───────────────────────────────────────────────────────────────────

class _FaqTab extends StatelessWidget {
  const _FaqTab();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const SizedBox(height: 4),
        ...S.faqItems.asMap().entries.map((entry) {
          final i = entry.key;
          final faq = entry.value;
          return _FaqItem(question: faq['q']!, answer: faq['a']!, index: i);
        }),
        const SizedBox(height: 16),
      ],
    );
  }
}

class _FaqItem extends StatefulWidget {
  final String question;
  final String answer;
  final int index;

  const _FaqItem({
    required this.question,
    required this.answer,
    required this.index,
  });

  @override
  State<_FaqItem> createState() => _FaqItemState();
}

class _FaqItemState extends State<_FaqItem> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: _expanded
            ? AppColors.primary.withValues(alpha: 0.08)
            : AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _expanded
              ? AppColors.primary.withValues(alpha: 0.3)
              : AppColors.border,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          widget.question,
                          style: AppTextStyles.bodyLarge.copyWith(
                            color: _expanded
                                ? AppColors.primary
                                : AppColors.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      AnimatedRotation(
                        turns: _expanded ? 0.5 : 0,
                        duration: const Duration(milliseconds: 200),
                        child: Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: _expanded
                              ? AppColors.primary
                              : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  if (_expanded) ...[
                    const SizedBox(height: 10),
                    const Divider(),
                    const SizedBox(height: 8),
                    Text(widget.answer, style: AppTextStyles.bodySecondary),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    )
        .animate(delay: (widget.index * 50).ms)
        .fadeIn(duration: 300.ms)
        .slideY(begin: 0.04, end: 0);
  }
}
