import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../config/app_theme.dart';
import '../../models/scrap_lot_model.dart';
import '../../providers/lot_provider.dart';

class QrDisplayScreen extends StatefulWidget {
  final dynamic lotId;
  final String? qrData;
  final ScrapLotModel? lot;

  const QrDisplayScreen({
    super.key,
    this.lotId,
    this.qrData,
    this.lot,
  });

  @override
  State<QrDisplayScreen> createState() => _QrDisplayScreenState();
}

class _QrDisplayScreenState extends State<QrDisplayScreen> {
  String? _qrToken;
  ScrapLotModel? _lot;
  bool _isLoading = false;
  String? _errorMessage;
  Timer? _countdownTimer;
  int _secondsRemaining = 15 * 60; // 15 minutes default
  bool _isExpired = false;

  @override
  void initState() {
    super.initState();
    _lot = widget.lot;
    _qrToken = widget.qrData ?? widget.lot?.qrToken;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadLotAndGenerateQr();
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _startTimer([int? totalSeconds]) {
    _countdownTimer?.cancel();
    setState(() {
      _secondsRemaining = totalSeconds ?? (15 * 60);
      _isExpired = _secondsRemaining <= 0;
    });

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() {
          _secondsRemaining--;
        });
      } else {
        timer.cancel();
        setState(() {
          _isExpired = true;
        });
      }
    });
  }

  Future<void> _loadLotAndGenerateQr() async {
    final effectiveLotId = widget.lotId ?? widget.lot?.id;
    if (effectiveLotId == null) {
      if (_qrToken != null) {
        _startTimer();
      }
      return;
    }

    final lotProvider = context.read<LotProvider>();

    // Load lot info if missing
    if (_lot == null) {
      final found = lotProvider.myLots.cast<ScrapLotModel?>().firstWhere(
            (l) => l?.id.toString() == effectiveLotId.toString(),
            orElse: () => null,
          );
      if (found != null) {
        _lot = found;
      }
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await lotProvider.generateQr(effectiveLotId);
      Map<String, dynamic> data = response is Map<String, dynamic> ? response : {};
      if (data.containsKey('data') && data['data'] is Map<String, dynamic>) {
        data = data['data'] as Map<String, dynamic>;
      }

      final token = data['qr_token'] ??
          data['qr_data'] ??
          data['token'] ??
          data['qrToken'] ??
          'SCRAPLINK:LOT:$effectiveLotId';

      DateTime? expiresAt;
      if (data['expires_at'] != null || data['expiresAt'] != null) {
        expiresAt = DateTime.tryParse((data['expires_at'] ?? data['expiresAt']).toString());
      }

      int remainingSeconds = 15 * 60;
      if (expiresAt != null) {
        final diff = expiresAt.difference(DateTime.now()).inSeconds;
        remainingSeconds = diff > 0 ? diff : 0;
      }

      setState(() {
        _qrToken = token.toString();
        _isLoading = false;
      });

      _startTimer(remainingSeconds);
    } catch (e) {
      // Fallback: use existing token or construct fallback token
      final fallbackToken = _qrToken ?? widget.lot?.qrToken ?? 'SCRAPLINK:LOT:$effectiveLotId';
      setState(() {
        _qrToken = fallbackToken;
        _isLoading = false;
      });
      _startTimer(15 * 60);
    }
  }

  String _formatDuration(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final lotId = widget.lotId ?? _lot?.id ?? 'N/A';
    final material = _lot?.material ?? 'Scrap Lot';
    final weight = _lot?.estimatedWeight != null ? '${_lot!.estimatedWeight} kg' : '';

    return Scaffold(
      appBar: AppBar(
        title: Text('QR Code - $lotId'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            tooltip: 'Share Token',
            onPressed: _qrToken == null
                ? null
                : () {
                    Clipboard.setData(ClipboardData(text: _qrToken!));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Copied token to clipboard: $_qrToken'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_isLoading)
                  const Padding(
                    padding: EdgeInsets.all(40.0),
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryGreen),
                    ),
                  )
                else if (_errorMessage != null)
                  Column(
                    children: [
                      const Icon(Icons.error_outline, size: 48, color: AppTheme.errorRed),
                      const SizedBox(height: 12),
                      Text(_errorMessage!, textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadLotAndGenerateQr,
                        child: const Text('Try Again'),
                      ),
                    ],
                  )
                else ...[
                  // QR Card with white background
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(20),
                          blurRadius: 18,
                          offset: const Offset(0, 4),
                        ),
                      ],
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      children: [
                        if (_isExpired)
                          Container(
                            height: 220,
                            width: 220,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.timer_off_outlined, size: 50, color: AppTheme.errorRed),
                                SizedBox(height: 10),
                                Text(
                                  'QR Code Expired',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.errorRed,
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          QrImageView(
                            data: _qrToken ?? 'SCRAPLINK',
                            version: QrVersions.auto,
                            size: 220.0,
                            backgroundColor: Colors.white,
                            eyeStyle: const QrEyeStyle(
                              eyeShape: QrEyeShape.square,
                              color: Colors.black,
                            ),
                            dataModuleStyle: const QrDataModuleStyle(
                              dataModuleShape: QrDataModuleShape.square,
                              color: Colors.black,
                            ),
                          ),
                        const SizedBox(height: 14),
                        Text(
                          _qrToken ?? '',
                          style: TextStyle(
                            fontSize: 12,
                            fontFamily: 'monospace',
                            color: Colors.grey.shade600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Below QR Details: Lot ID, material, weight
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Column(
                          children: [
                            const Text('Lot ID', style: TextStyle(fontSize: 12, color: Colors.grey)),
                            const SizedBox(height: 2),
                            Text(
                              lotId.toString(),
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                          ],
                        ),
                        Container(height: 28, width: 1, color: Colors.grey.shade300),
                        Column(
                          children: [
                            const Text('Material', style: TextStyle(fontSize: 12, color: Colors.grey)),
                            const SizedBox(height: 2),
                            Text(
                              material,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: AppTheme.primaryGreen,
                              ),
                            ),
                          ],
                        ),
                        if (weight.isNotEmpty) ...[
                          Container(height: 28, width: 1, color: Colors.grey.shade300),
                          Column(
                            children: [
                              const Text('Weight', style: TextStyle(fontSize: 12, color: Colors.grey)),
                              const SizedBox(height: 2),
                              Text(
                                weight,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Countdown Timer / Regenerate Button
                  if (_isExpired)
                    ElevatedButton.icon(
                      onPressed: _loadLotAndGenerateQr,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Regenerate QR Code'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryGreen,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: _secondsRemaining < 60
                            ? const Color(0xFFFFEBEE)
                            : const Color(0x1A2E7D32),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _secondsRemaining < 60
                              ? AppTheme.errorRed
                              : AppTheme.primaryGreen.withAlpha(60),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.timer_outlined,
                            size: 18,
                            color: _secondsRemaining < 60
                                ? AppTheme.errorRed
                                : AppTheme.primaryGreen,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Expires in: ${_formatDuration(_secondsRemaining)}',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: _secondsRemaining < 60
                                  ? AppTheme.errorRed
                                  : AppTheme.primaryGreen,
                            ),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 24),

                  // Recycler instruction
                  Text(
                    'Present this QR code to the verified recycler when handing over the scrap lot.',
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600, height: 1.4),
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
