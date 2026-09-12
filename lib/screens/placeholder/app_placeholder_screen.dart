import 'package:flutter/material.dart';
import '../../core/config/app_config.dart';
import '../../core/network/api_client.dart';

/// Clean placeholder screen for Phase 1 verifying project initialization
/// and active backend configuration without implementing Login or Dashboard yet.
class AppPlaceholderScreen extends StatefulWidget {
  const AppPlaceholderScreen({super.key});

  @override
  State<AppPlaceholderScreen> createState() => _AppPlaceholderScreenState();
}

class _AppPlaceholderScreenState extends State<AppPlaceholderScreen> {
  String _healthStatus = 'Not checked';
  bool _isChecking = false;

  Future<void> _checkHealth() async {
    setState(() {
      _isChecking = true;
      _healthStatus = 'Checking backend connection...';
    });

    try {
      final client = ApiClient();
      final response = await client.get('/health');
      if (mounted) {
        setState(() {
          _isChecking = false;
          if (response is Map<String, dynamic>) {
            final dbStatus = response['database'] ?? 'unknown';
            final msg = response['message'] ?? 'Online';
            _healthStatus = '✅ Backend Online ($msg, DB: $dbStatus)';
          } else {
            _healthStatus = '✅ Backend Connected';
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isChecking = false;
          _healthStatus = '⚠️ Note: Backend unreachable or offline ($e)';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final config = AppConfig.current;

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: const Text(
          'ScrapLink Collector',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
        centerTitle: true,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF334155)),
                  ),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.hub_outlined,
                        size: 64,
                        color: Color(0xFF10B981),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Phase 1: Architecture Foundation',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Existing Database + Existing Backend API + Flutter Collector Client',
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF94A3B8),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const Divider(color: Color(0xFF334155), height: 32),
                      _buildInfoRow('Backend API Base', config.baseUrl),
                      _buildInfoRow('Direct MySQL', 'Strictly Prohibited (REST only)'),
                      _buildInfoRow('Shared Database', 'scraplink (Admin + Recycler + Collector)'),
                      _buildInfoRow('Scrap ID Format', 'Preserved (e.g. SCRAP-0005)'),
                      _buildInfoRow('Auth State', 'Pending Phase 2 (No UI yet)'),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF334155)),
                  ),
                  child: Column(
                    children: [
                      Text(
                        _healthStatus,
                        style: TextStyle(
                          color: _healthStatus.startsWith('✅')
                              ? const Color(0xFF34D399)
                              : (_healthStatus.startsWith('⚠️')
                                  ? const Color(0xFFFBBF24)
                                  : const Color(0xFF94A3B8)),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: _isChecking ? null : _checkHealth,
                        icon: _isChecking
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.refresh, size: 18),
                        label: const Text('Test Backend Connection'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF94A3B8),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: const TextStyle(
                color: Color(0xFFF1F5F9),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}
