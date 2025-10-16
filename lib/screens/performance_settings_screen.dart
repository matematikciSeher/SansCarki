import 'package:flutter/material.dart';
import '../services/performance_service.dart';
import '../services/pixel_service.dart';
import '../services/border_painter_fix.dart';
import '../widgets/responsive_widget.dart';
import 'welcome_info_screen.dart';

class PerformanceSettingsScreen extends StatefulWidget {
  const PerformanceSettingsScreen({super.key});

  @override
  State<PerformanceSettingsScreen> createState() =>
      _PerformanceSettingsScreenState();
}

class _PerformanceSettingsScreenState extends State<PerformanceSettingsScreen> {
  PerformanceLevel _currentLevel = PerformanceService.instance.performanceLevel;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Performans Ayarları'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ResponsiveCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ResponsiveText(
                      'Çarkıfelek Animasyon Hızı',
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    const SizedBox(height: 8),
                    ResponsiveText(
                      'Cihazınızın performansına göre animasyon hızı otomatik olarak ayarlanır.',
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                    const SizedBox(height: 12),
                    _buildPerformanceOption(
                      PerformanceLevel.low,
                      'Düşük Performans',
                      'Daha yavaş animasyonlar, düşük performanslı cihazlar için',
                      Icons.phone_android,
                      Colors.orange,
                    ),
                    const SizedBox(height: 8),
                    _buildPerformanceOption(
                      PerformanceLevel.medium,
                      'Orta Performans',
                      'Standart animasyon hızı, çoğu cihaz için uygun',
                      Icons.phone_iphone,
                      Colors.blue,
                    ),
                    const SizedBox(height: 8),
                    _buildPerformanceOption(
                      PerformanceLevel.high,
                      'Yüksek Performans',
                      'Daha hızlı ve smooth animasyonlar, güçlü cihazlar için',
                      Icons.phone_android,
                      Colors.green,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              ResponsiveCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ResponsiveText(
                      'Animasyon Detayları',
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    const SizedBox(height: 12),
                    _buildDetailRow(
                        'Çarkıfelek Dönüş Süresi', _getSpinDurationText()),
                    _buildDetailRow(
                        'Animasyon Kalitesi', _getAnimationQualityText()),
                    _buildDetailRow('Frame Rate', _getFrameRateText()),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              ResponsiveCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ResponsiveText(
                      'Uygulama Bilgileri',
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    const SizedBox(height: 12),
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      leading: ResponsiveIcon(Icons.info_outline,
                          size: 20, color: Colors.blue),
                      title: ResponsiveText('Uygulama Tanıtımı', fontSize: 15),
                      subtitle: ResponsiveText(
                          'ÇARKIGO özelliklerini tekrar gör',
                          fontSize: 13,
                          color: Colors.grey),
                      trailing:
                          ResponsiveIcon(Icons.arrow_forward_ios, size: 14),
                      onTap: _showWelcomeInfo,
                    ),
                    const Divider(height: 1),
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      leading: ResponsiveIcon(Icons.refresh,
                          size: 20, color: Colors.green),
                      title: ResponsiveText('Performansı Yeniden Tespit Et',
                          fontSize: 15),
                      subtitle: ResponsiveText(
                          'Cihaz performansını otomatik tespit et',
                          fontSize: 13,
                          color: Colors.grey),
                      trailing:
                          ResponsiveIcon(Icons.arrow_forward_ios, size: 14),
                      onTap: _detectPerformance,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPerformanceOption(
    PerformanceLevel level,
    String title,
    String description,
    IconData icon,
    Color color,
  ) {
    final isSelected = _currentLevel == level;

    return InkWell(
      onTap: () {
        setState(() {
          _currentLevel = level;
        });
        PerformanceService.instance.setPerformanceLevel(level);
        _showSnackBar('Performans seviyesi $title olarak ayarlandı');
      },
      child: ResponsiveContainer(
        padding: const EdgeInsets.all(8),
        decoration: BorderPainterFix.createPixelPerfectDecoration(
          border: BorderPainterFix.createPixelPerfectBorder(
            color: isSelected ? color : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
            devicePixelRatio:
                PixelService.instance.getDevicePixelRatio(context),
          ),
          borderRadius: BorderPainterFix.createPixelPerfectBorderRadius(
            radius: 8,
            devicePixelRatio:
                PixelService.instance.getDevicePixelRatio(context),
          ),
          color: isSelected ? color.withOpacity(0.1) : null,
          devicePixelRatio: PixelService.instance.getDevicePixelRatio(context),
        ),
        child: Row(
          children: [
            ResponsiveIcon(
              icon,
              size: 24,
              color: isSelected ? color : Colors.grey,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ResponsiveText(
                    title,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? color : Colors.black,
                  ),
                  ResponsiveText(
                    description,
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ],
              ),
            ),
            if (isSelected)
              ResponsiveIcon(
                Icons.check_circle,
                size: 20,
                color: color,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          ResponsiveText(label, fontSize: 14),
          ResponsiveText(
            value,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ],
      ),
    );
  }

  String _getSpinDurationText() {
    final duration = PerformanceService.instance.getWheelSpinDuration();
    return '${duration.inSeconds} saniye';
  }

  String _getAnimationQualityText() {
    switch (_currentLevel) {
      case PerformanceLevel.low:
        return 'Basit';
      case PerformanceLevel.medium:
        return 'Standart';
      case PerformanceLevel.high:
        return 'Yüksek';
    }
  }

  String _getFrameRateText() {
    final fps = PerformanceService.instance.getTargetFrameRate();
    return '$fps FPS';
  }

  void _detectPerformance() async {
    _showSnackBar('Performans tespit ediliyor...');

    await PerformanceService.instance.detectPerformanceLevel();

    setState(() {
      _currentLevel = PerformanceService.instance.performanceLevel;
    });

    _showSnackBar('Performans seviyesi otomatik olarak tespit edildi');
  }

  void _showWelcomeInfo() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const WelcomeInfoScreen(isFromSettings: true),
      ),
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
