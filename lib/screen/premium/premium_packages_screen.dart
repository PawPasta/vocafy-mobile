import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:gal/gal.dart';
import 'package:intl/intl.dart';

import '../../config/routes/route_names.dart';
import '../../core/data/models/payment_check_result.dart';
import '../../core/data/models/payment_subscribe_result.dart';
import '../../core/data/models/premium_package.dart';
import '../../core/data/services/premium_service.dart';

class PremiumPackagesScreen extends StatefulWidget {
  const PremiumPackagesScreen({super.key});

  @override
  State<PremiumPackagesScreen> createState() => _PremiumPackagesScreenState();
}

class _PremiumPackagesScreenState extends State<PremiumPackagesScreen> {
  static const Color _softErrorOrange = Color(0xFFF4A261);
  late final Future<List<PremiumPackage>> _packagesFuture;
  final Map<int, PremiumPackage> _detailCache = <int, PremiumPackage>{};
  final NumberFormat _vndFormat = NumberFormat.currency(
    locale: 'vi_VN',
    symbol: '₫',
    decimalDigits: 0,
  );

  int? _selectedPackageId;
  PremiumPackage? _selectedPackageDetail;
  bool _loadingDetail = false;
  bool _processingPayment = false;

  @override
  void initState() {
    super.initState();
    _packagesFuture = _loadPackages();
  }

  Future<List<PremiumPackage>> _loadPackages() async {
    final packages = await premiumService.listPremiumPackages(
      page: 0,
      size: 10,
    );
    final activePackages = packages.where((p) => p.active).toList();

    if (activePackages.isNotEmpty) {
      _selectedPackageId = activePackages.first.id;
      _selectedPackageDetail = activePackages.first;
      await _loadPackageDetail(activePackages.first.id);
    }

    return activePackages;
  }

  Future<void> _loadPackageDetail(int packageId) async {
    final cached = _detailCache[packageId];
    if (cached != null) {
      if (!mounted || _selectedPackageId != packageId) return;
      setState(() {
        _selectedPackageDetail = cached;
        _loadingDetail = false;
      });
      return;
    }

    setState(() => _loadingDetail = true);
    final detail = await premiumService.getPremiumPackageById(packageId);
    if (!mounted || _selectedPackageId != packageId) return;

    if (detail != null) {
      _detailCache[packageId] = detail;
    }

    setState(() {
      if (detail != null) {
        _selectedPackageDetail = detail;
      }
      _loadingDetail = false;
    });
  }

  Future<void> _onPayNow(PremiumPackage package) async {
    if (_processingPayment) return;

    setState(() => _processingPayment = true);
    final subscribe = await premiumService.subscribePremiumPackage(package.id);
    if (!mounted) return;
    setState(() => _processingPayment = false);

    if (subscribe == null || subscribe.url.trim().isEmpty) {
      final message =
          premiumService.lastErrorMessage ??
          'Khong tao duoc QR thanh toan. Vui long thu lai.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: _softErrorOrange,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final vipVerified = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Colors.white,
      builder: (_) => _PaymentQrSheet(
        package: package,
        subscribeResult: subscribe,
        vndFormat: _vndFormat,
      ),
    );

    if (!mounted || vipVerified != true) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Thanh toan VIP thanh cong. Dang quay ve Home...'),
        behavior: SnackBarBehavior.floating,
      ),
    );

    Navigator.of(
      context,
    ).pushNamedAndRemoveUntil(RouteNames.home, (r) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FF),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFFF6F8FF),
        title: const Text(
          'Get PLUS',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: FutureBuilder<List<PremiumPackage>>(
        future: _packagesFuture,
        builder: (context, snapshot) {
          final packages = snapshot.data ?? const <PremiumPackage>[];

          if (snapshot.connectionState == ConnectionState.waiting &&
              packages.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (packages.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Text(
                  'Chua co goi Premium nao dang mo.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final fallback = packages.firstWhere(
            (p) => p.id == _selectedPackageId,
            orElse: () => packages.first,
          );
          final selected = _selectedPackageDetail ?? fallback;

          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeroCard(),
                      const SizedBox(height: 14),
                      const Text(
                        'Chon goi Premium',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: Color(0xFF1B2A57),
                        ),
                      ),
                      const SizedBox(height: 10),
                      ...packages.map(
                        (pkg) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _PremiumPackageCard(
                            package: pkg,
                            selected: pkg.id == _selectedPackageId,
                            priceLabel: _vndFormat.format(pkg.price),
                            onTap: () {
                              setState(() {
                                _selectedPackageId = pkg.id;
                                _selectedPackageDetail = pkg;
                              });
                              _loadPackageDetail(pkg.id);
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      _buildSelectedPackageInfo(selected),
                    ],
                  ),
                ),
              ),
              _buildPayBar(selected),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeroCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF5B7FFF), Color(0xFF3F5BFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.workspace_premium, color: Colors.amber, size: 24),
              SizedBox(width: 8),
              Text(
                'Vocafy PLUS',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            'Mo toan bo noi dung Premium, hoc khong gioi han va uu tien tinh nang moi.',
            style: TextStyle(
              color: Color(0xFFE9EEFF),
              fontSize: 13,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedPackageInfo(PremiumPackage package) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E9FF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.info_outline,
                color: Color(0xFF4F6CFF),
                size: 18,
              ),
              const SizedBox(width: 6),
              const Text(
                'Chi tiet goi da chon',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1B2A57),
                ),
              ),
              const Spacer(),
              if (_loadingDetail)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            package.description,
            style: const TextStyle(
              color: Color(0xFF334155),
              fontSize: 13,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _chip('Gia: ${_vndFormat.format(package.price)}'),
              _chip('Thoi han: ${package.durationDays} ngay'),
              _chip(
                package.active ? 'Trang thai: Active' : 'Trang thai: Inactive',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _chip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFEEF2FF),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Color(0xFF3F5BFF),
        ),
      ),
    );
  }

  Widget _buildPayBar(PremiumPackage package) {
    return SafeArea(
      top: false,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Color(0xFFE8ECFF))),
        ),
        child: SizedBox(
          height: 52,
          child: ElevatedButton(
            onPressed: _processingPayment ? null : () => _onPayNow(package),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4F6CFF),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: _processingPayment
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    'Thanh toan ${_vndFormat.format(package.price)}',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

class _PremiumPackageCard extends StatelessWidget {
  final PremiumPackage package;
  final bool selected;
  final String priceLabel;
  final VoidCallback onTap;

  const _PremiumPackageCard({
    required this.package,
    required this.selected,
    required this.priceLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = selected
        ? const Color(0xFF4F6CFF)
        : const Color(0xFFE5E9FF);
    final backgroundColor = selected ? const Color(0xFFF0F4FF) : Colors.white;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Ink(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor, width: selected ? 1.8 : 1),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              selected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_off_outlined,
              color: selected
                  ? const Color(0xFF4F6CFF)
                  : const Color(0xFF94A3B8),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    package.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: Color(0xFF1B2A57),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    package.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      height: 1.35,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: const Color(0xFFDDE5FF)),
                        ),
                        child: Text(
                          '${package.durationDays} ngay',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 11,
                            color: Color(0xFF4F6CFF),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Text(
              priceLabel,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                color: Color(0xFF203685),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PaymentQrSheet extends StatefulWidget {
  final PremiumPackage package;
  final PaymentSubscribeResult subscribeResult;
  final NumberFormat vndFormat;

  const _PaymentQrSheet({
    required this.package,
    required this.subscribeResult,
    required this.vndFormat,
  });

  @override
  State<_PaymentQrSheet> createState() => _PaymentQrSheetState();
}

class _PaymentQrSheetState extends State<_PaymentQrSheet> {
  static const Color _softErrorOrange = Color(0xFFF4A261);
  final Dio _dio = Dio();
  bool _downloading = false;
  bool _checking = false;
  PaymentCheckResult? _lastCheckResult;

  List<MapEntry<String, String>> get _qrUrlMeta {
    final uri = Uri.tryParse(widget.subscribeResult.url);
    if (uri == null) return const <MapEntry<String, String>>[];

    final entries = <MapEntry<String, String>>[
      MapEntry<String, String>('host', uri.host),
      MapEntry<String, String>('path', uri.path),
    ];

    uri.queryParameters.forEach((key, value) {
      entries.add(MapEntry<String, String>(key, value));
    });

    return entries;
  }

  Future<void> _downloadQrImage() async {
    if (_downloading) return;
    setState(() => _downloading = true);

    try {
      final hasAccess = await Gal.hasAccess();
      if (!hasAccess) {
        final granted = await Gal.requestAccess();
        if (!granted) {
          _showSnack('Ban chua cap quyen luu anh vao thu vien.');
          return;
        }
      }

      final response = await _dio.get<List<int>>(
        widget.subscribeResult.url,
        options: Options(
          responseType: ResponseType.bytes,
          followRedirects: true,
          validateStatus: (status) {
            if (status == null) return false;
            return status >= 200 && status < 400;
          },
        ),
      );

      final bytes = response.data;
      if (bytes == null || bytes.isEmpty) {
        _showSnack('Khong tai duoc anh QR.');
        return;
      }

      final safeRef = widget.subscribeResult.ref1.replaceAll(
        RegExp(r'[^A-Za-z0-9_-]'),
        '_',
      );
      final fileName =
          'vocafy_qr_${safeRef}_${DateTime.now().millisecondsSinceEpoch}';

      await Gal.putImageBytes(Uint8List.fromList(bytes), name: fileName);
      _showSnack('Da luu anh QR vao thu vien.');
    } catch (_) {
      _showSnack('Tai anh that bai. Vui long thu lai.');
    } finally {
      if (mounted) {
        setState(() => _downloading = false);
      }
    }
  }

  Future<void> _checkTransaction() async {
    if (_checking) return;
    setState(() => _checking = true);
    final result = await premiumService.checkPaymentTransaction();
    if (!mounted) return;
    setState(() {
      _checking = false;
      _lastCheckResult = result;
    });

    if (result == null) {
      final message =
          premiumService.lastErrorMessage ??
          'Khong kiem tra duoc giao dich. Vui long thu lai.';
      _showSnack(message, backgroundColor: _softErrorOrange);
      return;
    }

    if (result.isVipPlan) {
      Navigator.of(context).pop(true);
      return;
    }

    _showSnack(
      'Chua xac nhan VIP. subscription_plan=${result.subscriptionPlan}',
    );
  }

  void _showSnack(String message, {Color? backgroundColor}) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: backgroundColor,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final amountText = widget.vndFormat.format(widget.subscribeResult.amount);
    final qrUrlMeta = _qrUrlMeta;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 8, 16, 16 + bottomInset),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'QR thanh toan Premium',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFF),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE3E8FF)),
                ),
                child: AspectRatio(
                  aspectRatio: 1,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(
                      widget.subscribeResult.url,
                      fit: BoxFit.contain,
                      loadingBuilder: (context, child, progress) {
                        if (progress == null) return child;
                        return const Center(child: CircularProgressIndicator());
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return const Center(
                          child: Text('Khong hien thi duoc anh QR'),
                        );
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'URL QR',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF203685),
                ),
              ),
              const SizedBox(height: 4),
              SelectableText(
                widget.subscribeResult.url,
                style: const TextStyle(fontSize: 12, color: Color(0xFF475569)),
              ),
              const SizedBox(height: 12),
              _InfoCard(
                title: 'Thong tin can trung khop de he thong xac nhan',
                items: [
                  'Goi: ${widget.package.name}',
                  'So tien: $amountText',
                  'Ma doi soat (ref1): ${widget.subscribeResult.ref1}',
                  'Noi dung chuyen khoan phai co dung ref1',
                  'Neu sai so tien hoac sai ref1 thi khong xac nhan duoc',
                ],
              ),
              const SizedBox(height: 10),
              _InfoCard(
                title: 'Thong tin trich tu URL QR',
                items: qrUrlMeta.isEmpty
                    ? const <String>['Khong doc duoc query params tu URL']
                    : qrUrlMeta
                          .map((e) => '${e.key}: ${e.value}')
                          .toList(growable: false),
              ),
              if (_lastCheckResult != null) ...[
                const SizedBox(height: 10),
                _InfoCard(
                  title: 'Ket qua kiem tra giao dich',
                  items: [
                    'is_registration_successful: ${_lastCheckResult!.isRegistrationSuccessful}',
                    'payment_status: ${_lastCheckResult!.paymentStatus}',
                    'subscription_plan: ${_lastCheckResult!.subscriptionPlan}',
                    'subscription_end_at: ${_lastCheckResult!.subscriptionEndAt}',
                    'latest_transaction_status: ${_lastCheckResult!.latestTransactionStatus}',
                    'latest_transaction_amount: ${_lastCheckResult!.latestTransactionAmount}',
                  ],
                ),
              ],
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _downloading ? null : _downloadQrImage,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4F6CFF),
                    foregroundColor: Colors.white,
                  ),
                  icon: _downloading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.download),
                  label: Text(
                    _downloading ? 'Dang tai anh...' : 'Download image',
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton.icon(
                  onPressed: _checking ? null : _checkTransaction,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF334155),
                    side: const BorderSide(color: Color(0xFFCBD5E1)),
                  ),
                  icon: _checking
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.verified_outlined),
                  label: Text(
                    _checking
                        ? 'Dang kiem tra...'
                        : 'Kiem tra thong tin thanh toan',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final List<String> items;

  const _InfoCard({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 8),
          ...items.map(
            (line) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 6),
                    child: Icon(
                      Icons.circle,
                      size: 6,
                      color: Color(0xFF475569),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      line,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF475569),
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
