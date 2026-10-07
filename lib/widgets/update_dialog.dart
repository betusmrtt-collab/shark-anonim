import 'package:flutter/material.dart';
import '../services/update_service.dart';

class UpdateDialog extends StatefulWidget {
  final Map<String, dynamic> updateInfo;

  const UpdateDialog({super.key, required this.updateInfo});

  @override
  State<UpdateDialog> createState() => _UpdateDialogState();
}

class _UpdateDialogState extends State<UpdateDialog> {
  final _updateService = UpdateService();
  bool _downloading = false;
  double _progress = 0.0;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('🎉 Yeni Güncelleme Mevcut'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Versiyon ${widget.updateInfo['version']}',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Text(widget.updateInfo['releaseNotes'] ?? ''),
          if (_downloading) ...[
            const SizedBox(height: 16),
            LinearProgressIndicator(value: _progress),
            const SizedBox(height: 8),
            Text('${(_progress * 100).toStringAsFixed(0)}% indiriliyor...'),
          ],
        ],
      ),
      actions: [
        if (!_downloading)
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Şimdi Değil'),
          ),
        if (!_downloading)
          ElevatedButton(
            onPressed: _downloadAndInstall,
            child: const Text('Güncelle'),
          ),
      ],
    );
  }

  Future<void> _downloadAndInstall() async {
    setState(() {
      _downloading = true;
    });

    final filePath = await _updateService.downloadUpdate(
      widget.updateInfo['downloadUrl'],
      (progress) {
        setState(() {
          _progress = progress;
        });
      },
    );

    if (filePath != null && mounted) {
      Navigator.pop(context);
      await _updateService.installApk(filePath);
    } else if (mounted) {
      setState(() {
        _downloading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('İndirme başarısız oldu')),
      );
    }
  }
}
