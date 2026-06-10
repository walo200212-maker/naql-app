import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/localization/app_strings.dart';
import '../../widgets/common/wasl_button.dart';

class SupportScreen extends StatefulWidget {
  const SupportScreen({super.key});

  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  WebViewController? _webController;
  bool _webLoaded = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_onTabChanged);

    if (!kIsWeb) {
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

  Future<void> _openChatUrl() async {
    final uri = Uri.parse(
        'https://tawk.to/chat/${AppConstants.tawkPropertyId}/${AppConstants.tawkWidgetId}');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text('المساعدة والدعم', style: AppTextStyles.h3),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          indicatorSize: TabBarIndicatorSize.label,
          tabs: const [
            Tab(text: 'دردشة'),
            Tab(text: 'واتساب'),
            Tab(text: 'أسئلة'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          kIsWeb || _webController == null
              ? _ChatWebFallback(onOpen: _openChatUrl)
              : _ChatTab(controller: _webController!, isLoaded: _webLoaded),
          _WhatsAppTab(onOpen: _openWhatsApp),
          const _FaqTab(),
        ],
      ),
    );
  }
}

// ── Chat Tab (native WebView) ─────────────────────────────────────────────────

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

// ── Chat Tab (web fallback) ───────────────────────────────────────────────────

class _ChatWebFallback extends StatelessWidget {
  final VoidCallback onOpen;
  const _ChatWebFallback({required this.onOpen});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.support_agent_rounded,
                  color: AppColors.primary, size: 44),
            )
                .animate()
                .scale(duration: 500.ms, curve: Curves.elasticOut),
            const SizedBox(height: 24),
            Text('دعم مباشر',
                style: AppTextStyles.h2, textAlign: TextAlign.center)
                .animate(delay: 100.ms)
                .fadeIn(duration: 400.ms),
            const SizedBox(height: 8),
            Text(
              'افتح نافذة الدردشة للتحدث مع فريق الدعم.',
              style: AppTextStyles.bodySecondary,
              textAlign: TextAlign.center,
            )
                .animate(delay: 150.ms)
                .fadeIn(duration: 400.ms),
            const SizedBox(height: 32),
            WaslButton(
              label: 'فتح الدردشة',
              onPressed: onOpen,
              icon: Icons.open_in_new_rounded,
            )
                .animate(delay: 200.ms)
                .fadeIn(duration: 400.ms),
          ],
        ),
      ),
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
                color: AppColors.success.withValues(alpha: 0.12),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.success.withValues(alpha: 0.15),
                    blurRadius: 24,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: const Icon(Icons.chat_rounded,
                  color: AppColors.success, size: 50),
            )
                .animate()
                .scale(duration: 500.ms, curve: Curves.elasticOut),

            const SizedBox(height: 24),

            Text('تواصل مع الإدارة',
                style: AppTextStyles.h2, textAlign: TextAlign.center)
                .animate(delay: 100.ms)
                .fadeIn(duration: 400.ms),

            const SizedBox(height: 8),

            Text(
              'نرد بسرعة عبر واتساب على أي سؤال أو مشكلة عاجلة.',
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
                label: const Text('فتح واتساب'),
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

            const SizedBox(height: 14),

            Text(AppConstants.adminWhatsApp, style: AppTextStyles.caption)
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
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        ...S.faqItems.asMap().entries.map((entry) {
          final i = entry.key;
          final faq = entry.value;
          return _FaqItem(question: faq['q']!, answer: faq['a']!, index: i);
        }),
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
            ? AppColors.primary.withValues(alpha: 0.07)
            : AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _expanded
              ? AppColors.primary.withValues(alpha: 0.3)
              : AppColors.surfaceBorder,
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
                    Divider(color: AppColors.surfaceBorder, height: 1),
                    const SizedBox(height: 10),
                    Text(widget.answer, style: AppTextStyles.bodySecondary),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    )
        .animate(delay: Duration(milliseconds: widget.index * 50))
        .fadeIn(duration: 300.ms)
        .slideY(begin: 0.04, end: 0);
  }
}
