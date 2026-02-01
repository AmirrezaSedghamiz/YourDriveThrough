import 'dart:async';

import 'package:application/GlobalWidgets/AppTheme/Colors.dart';
import 'package:flutter/material.dart';
import 'package:tapsell_plus/NativeAdPayload.dart';
import 'package:tapsell_plus/tapsell_plus.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class NativeAdWidget extends StatefulWidget {
  final String zoneId;
  final String factoryId;

  const NativeAdWidget({
    super.key,
    required this.zoneId,
    required this.factoryId,
  });

  @override
  State<NativeAdWidget> createState() => _NativeAdWidgetState();
}

class _NativeAdWidgetState extends State<NativeAdWidget> {
  String? _responseId;
  bool _isLoading = false;
  String? _error;
  Widget? _adContent;

  @override
  void initState() {
    super.initState();
    _initializeAd();
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

    retryLoadAd(); // Retry ad loading
  }

  @override
  void dispose() {
    _adTimeoutTimer?.cancel();
    super.dispose();
  }

  Timer? _adTimeoutTimer;

  Future<void> _initializeAd() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _error = null;
      _adContent = null;
    });

    // Set a timeout for the ad request
    _adTimeoutTimer = Timer(const Duration(seconds: 10), () {
      if (mounted && _responseId == null && _error == null) {
        _handleError('Ad request timed out');
      }
    });

    try {
      final success = await TapsellPlus.instance.requestNativeAd(
        widget.zoneId,
        onResponse: (response) {
          _adTimeoutTimer?.cancel(); // Cancel timeout on response
          _responseId = response['response_id'];
          _handleAdResponse();
        },
        onError: (error) {
          _adTimeoutTimer?.cancel(); // Cancel timeout on error
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
  //

  void _handleAdResponse() {
    if (_responseId == null || !mounted) return;

    TapsellPlus.instance.showNativeAd(_responseId!,
        admobFactoryId: widget.factoryId, onOpened: (nativeAd) {
      if (!mounted) return;
      setState(() {
        _adContent = _buildAdContent(nativeAd);
        _isLoading = false;
      });
    }, onError: (error) {
      return _handleError(error['errorMessage'] ?? "ERROR UNKNOWN");
    });
  }

  Widget _buildAdContent(NativeAdPayload payload) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: AppColors.white,
          border: BoxBorder.all(
              width: 1, color: const Color(0xFFE3E3E3))),
      child: payload is GeneralNativeAdPayload
          ? _buildTapsellAd(payload)
          : (payload is AdMobNativeAdViewPayload
              ? _buildAdMobAd(payload)
              : Container()),
    );
  }

  Widget _buildTapsellAd(GeneralNativeAdPayload ad) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: AppColors.coal,
                  image: DecorationImage(
                    image: NetworkImage(ad.ad.iconUrl ?? ""),
                    fit: BoxFit.cover,
                  )),
            ),
            const SizedBox(width: 12),
            Text(ad.ad.title ?? 'Ad',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium!
                    .copyWith(fontWeight: FontWeight.w500)),
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (ad.ad.description != null)
                Column(
                  children: [
                    Text(ad.ad.description!,
                        style: Theme.of(context).textTheme.labelLarge!.copyWith(
                              fontWeight: FontWeight.w400,
                              color: Colors.grey[600],
                            )),
                  ],
                ),
              if (ad.ad.callToActionText != null)
                GestureDetector(
                  onTap: () {
                    TapsellPlus.instance.nativeBannerAdClicked(_responseId!);
                  },
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                    decoration: BoxDecoration(
                        border: Border.all(color: AppColors.primary, width: 2),
                        borderRadius: BorderRadius.circular(8)),
                    child: Center(
                      child: Text(ad.ad.callToActionText!,
                          style: Theme.of(context)
                              .textTheme
                              .labelLarge!
                              .copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary)),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  // Updated _buildAdMobAd to expect AdMobNativeAdViewPayload
  Widget _buildAdMobAd(AdMobNativeAdViewPayload adPayload) {
    return SizedBox(
      height: 300,
      child: AdWidget(
          ad: adPayload.nativeAdView), // nativeAdView is of type AdWithView
    );
  }

  Widget _buildLoading() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Center(
        child: CircularProgressIndicator(
          strokeWidth: 3,
          color: AppColors.primary,
        ),
      ),
    );
  }

  Widget _buildError() {
    return const SizedBox();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _isLoading
            ? _buildLoading()
            : _error != null
                ? _buildError()
                : _adContent ?? const SizedBox.shrink(),
      ),
    );
  }
}
