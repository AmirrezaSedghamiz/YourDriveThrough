import 'dart:async';

import 'package:application/GlobalWidgets/AppTheme/Colors.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:tapsell_plus/NativeAdPayload.dart';
import 'package:tapsell_plus/tapsell_plus.dart';

class NativeAdWidget extends StatefulWidget {
  final String zoneId;
  final String factoryId;

  /// If true, show a small "Ad unavailable" + Retry button UI instead of hiding.
  final bool showErrorUI;

  /// Optional outer margin (defaults to vertical: 12).
  final EdgeInsets margin;

  const NativeAdWidget({
    super.key,
    required this.zoneId,
    required this.factoryId,
    this.showErrorUI = false,
    this.margin = const EdgeInsets.symmetric(vertical: 12),
  });

  @override
  State<NativeAdWidget> createState() => _NativeAdWidgetState();
}

class _NativeAdWidgetState extends State<NativeAdWidget> {
  String? _responseId;
  bool _isLoading = false;
  String? _error;
  Widget? _adContent;

  Timer? _adTimeoutTimer;

  @override
  void initState() {
    super.initState();
    _initializeAd();
  }

  @override
  void dispose() {
    _adTimeoutTimer?.cancel();
    super.dispose();
  }

  Future<void> retryLoadAd() async {
    await Future.delayed(const Duration(seconds: 1));
    _initializeAd();
  }

  void _handleError(String message) {
    if (!mounted) return;
    setState(() {
      _error = message;
      _isLoading = false;
    });

    // Auto retry (ads are best-effort)
    retryLoadAd();
  }

  Future<void> _initializeAd() async {
    if (!mounted) return;

    setState(() {
      _responseId = null; // important reset
      _isLoading = true;
      _error = null;
      _adContent = null;
    });

    _adTimeoutTimer?.cancel();
    _adTimeoutTimer = Timer(const Duration(seconds: 10), () {
      if (mounted && _responseId == null && _error == null) {
        _handleError('Ad request timed out');
      }
    });

    try {
      final success = await TapsellPlus.instance.requestNativeAd(
        widget.zoneId,
        onResponse: (response) {
          _adTimeoutTimer?.cancel();
          _responseId = response['response_id'];
          _handleAdResponse();
        },
        onError: (error) {
          _adTimeoutTimer?.cancel();
          _handleError(error['errorMessage'] ?? "ERROR UNKNOWN");
        },
      );

      if (!success && mounted) {
        _handleError('Failed to start ad request');
      }
    } catch (e) {
      _adTimeoutTimer?.cancel();
      _handleError(e.toString());
    }
  }

  void _handleAdResponse() {
    if (_responseId == null || !mounted) return;

    TapsellPlus.instance.showNativeAd(
      _responseId!,
      admobFactoryId: widget.factoryId,
      onOpened: (nativeAd) {
        if (!mounted) return;
        setState(() {
          _adContent = _buildAdContent(nativeAd);
          _isLoading = false;
        });
      },
      onError: (error) {
        _handleError(error['errorMessage'] ?? "ERROR UNKNOWN");
      },
    );
  }

  Widget _buildAdContent(NativeAdPayload payload) {
    final t = Theme.of(context).textTheme;

    return _AdCard(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: payload is GeneralNativeAdPayload
            ? _buildTapsellAd(payload)
            : (payload is AdMobNativeAdViewPayload
                ? _buildAdMobAd(payload)
                : Text("Unsupported ad type", style: t.bodyMedium)),
      ),
    );
  }

  Widget _buildTapsellAd(GeneralNativeAdPayload ad) {
    final t = Theme.of(context).textTheme;

    final title = (ad.ad.title ?? "Sponsored").trim();
    final desc = (ad.ad.description ?? "").trim();
    final cta = (ad.ad.callToActionText ?? "Learn more").trim();
    final iconUrl = (ad.ad.iconUrl ?? "").trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // header row
        Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: AppColors.coal.withOpacity(0.08),
                border: Border.all(color: const Color(0xFFEAEAEA)),
              ),
              clipBehavior: Clip.antiAlias,
              child: iconUrl.isEmpty
                  ? Icon(Icons.campaign, color: AppColors.coal.withOpacity(0.6))
                  : Image.network(
                      iconUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Icon(
                        Icons.campaign,
                        color: AppColors.coal.withOpacity(0.6),
                      ),
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: t.bodyLarge?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    "Sponsored",
                    style: t.bodySmall?.copyWith(
                      color: Colors.black.withOpacity(0.55),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        if (desc.isNotEmpty) ...[
          const SizedBox(height: 10),
          Text(
            desc,
            style: t.bodyMedium?.copyWith(
              color: Colors.black.withOpacity(0.75),
              height: 1.25,
            ),
          ),
        ],

        const SizedBox(height: 12),

        Row(
          children: [
            const Spacer(),
            _TapPill(
              text: cta,
              onTap: () {
                final id = _responseId;
                if (id != null) {
                  TapsellPlus.instance.nativeBannerAdClicked(id);
                }
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAdMobAd(AdMobNativeAdViewPayload adPayload) {
    // AdMob native view is already styled by factory; we just clip/radius it.
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        height: 300,
        child: AdWidget(ad: adPayload.nativeAdView),
      ),
    );
  }

  Widget _buildLoading() {
    return _AdCard(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Row(
              children: [
                _ShimmerBlock(w: 44, h: 44, r: 12),
                SizedBox(width: 12),
                Expanded(child: _ShimmerBlock(w: double.infinity, h: 14, r: 8)),
              ],
            ),
            SizedBox(height: 12),
            _ShimmerBlock(w: double.infinity, h: 12, r: 8),
            SizedBox(height: 8),
            _ShimmerBlock(w: 220, h: 12, r: 8),
            SizedBox(height: 14),
            Align(
              alignment: Alignment.centerRight,
              child: _ShimmerBlock(w: 120, h: 36, r: 10),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError() {
    if (!widget.showErrorUI) return const SizedBox.shrink();

    final t = Theme.of(context).textTheme;
    return _AdCard(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Icon(Icons.info_outline, color: Colors.black.withOpacity(0.55)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                "Ad unavailable right now",
                style: t.bodyMedium?.copyWith(
                  color: Colors.black.withOpacity(0.7),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            _TapPill(
              text: "Retry",
              onTap: _initializeAd,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: widget.margin,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 260),
        child: _isLoading
            ? _buildLoading()
            : _error != null
                ? _buildError()
                : (_adContent ?? const SizedBox.shrink()),
      ),
    );
  }
}

/// ---------------- Design helpers ----------------

class _AdCard extends StatelessWidget {
  const _AdCard({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEAEAEA)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _TapPill extends StatelessWidget {
  const _TapPill({required this.text, required this.onTap});

  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.primary, width: 1.5),
          ),
          child: Text(
            text,
            style: t.labelLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
        ),
      ),
    );
  }
}

class _ShimmerBlock extends StatefulWidget {
  const _ShimmerBlock({
    required this.w,
    required this.h,
    this.r = 10,
  });

  final double w;
  final double h;
  final double r;

  @override
  State<_ShimmerBlock> createState() => _ShimmerBlockState();
}

class _ShimmerBlockState extends State<_ShimmerBlock>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const base = Color(0xFFE9E9E9);

    return ClipRRect(
      borderRadius: BorderRadius.circular(widget.r),
      child: SizedBox(
        width: widget.w == double.infinity ? double.infinity : widget.w,
        height: widget.h,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Container(color: base),
            AnimatedBuilder(
              animation: _c,
              builder: (_, __) {
                final v = (_c.value * 2) - 1; // -1..+1
                return Transform.translate(
                  offset: Offset(v * 160, 0),
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          Color(0x00FFFFFF),
                          Color(0x55FFFFFF),
                          Color(0x00FFFFFF),
                        ],
                        stops: [0.25, 0.5, 0.75],
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}