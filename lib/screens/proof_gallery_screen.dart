import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProofGalleryScreen extends StatelessWidget {
  const ProofGalleryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('📷 Kanıt Galerisi'),
        backgroundColor: Colors.orange,
        centerTitle: true,
      ),
      body: FutureBuilder<Map<String, List<Map<String, dynamic>>>>(
        future: _loadProofsGroupedByTask(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final grouped = snapshot.data ?? {};
          if (grouped.isEmpty) {
            return const Center(
              child: Text('Henüz eklenmiş kanıt yok.'),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: grouped.length,
            itemBuilder: (context, i) {
              final entry = grouped.entries.elementAt(i);
              final taskTitle = entry.key;
              final proofs = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      taskTitle,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 120,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemBuilder: (context, index) {
                          final p = proofs[index];
                          final imagePath = p['imagePath'] as String?;
                          final docPath = p['docPath'] as String?;
                          if (imagePath != null && imagePath.isNotEmpty) {
                            final file = File(imagePath);
                            return GestureDetector(
                              onTap: () => _openFullscreen(context, file),
                              onLongPress: () => _confirmDelete(context, file),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Image.file(
                                  file,
                                  width: 160,
                                  height: 120,
                                  fit: BoxFit.cover,
                                  filterQuality: FilterQuality.high,
                                ),
                              ),
                            );
                          } else if (docPath != null && docPath.isNotEmpty) {
                            return Container(
                              width: 200,
                              height: 120,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.orange.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: Colors.orange.withOpacity(0.2),
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.description,
                                      color: Colors.orange),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      docPath.split('/').last,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontSize: 13),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemCount: proofs.length,
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

Future<Map<String, List<Map<String, dynamic>>>>
    _loadProofsGroupedByTask() async {
  final prefs = await SharedPreferences.getInstance();
  final log = prefs.getStringList('proof_log') ?? [];
  final map = <String, List<Map<String, dynamic>>>{};
  for (final item in log) {
    try {
      final p = jsonDecode(item) as Map<String, dynamic>;
      final title = (p['taskTitle'] as String?)?.trim();
      if (title == null || title.isEmpty) continue;
      map.putIfAbsent(title, () => []).add(p);
    } catch (_) {}
  }
  return map;
}

Future<void> _openFullscreen(BuildContext context, File file) async {
  return showDialog(
    context: context,
    builder: (context) => Dialog(
      insetPadding: const EdgeInsets.all(16),
      child: Stack(
        children: [
          InteractiveViewer(
            child: Image.file(file, fit: BoxFit.contain),
          ),
          Positioned(
            right: 8,
            top: 8,
            child: IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ],
      ),
    ),
  );
}

Future<void> _confirmDelete(BuildContext context, File file) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Fotoğrafı sil?'),
      content: const Text('Bu fotoğrafı galeriden kaldırmak istiyor musun?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('İptal'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Sil'),
        ),
      ],
    ),
  );
  if (ok == true) {
    await _deleteProof(file);
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Fotoğraf silindi.')));
    }
  }
}

Future<void> _deleteProof(File file) async {
  final prefs = await SharedPreferences.getInstance();
  final keys = prefs.getKeys().where((k) => k.startsWith('proof_'));
  for (final key in keys) {
    final jsonStr = prefs.getString(key);
    if (jsonStr == null) continue;
    try {
      final data = jsonDecode(jsonStr) as Map<String, dynamic>;
      if (data['imagePath'] == file.path) {
        data['imagePath'] = '';
        await prefs.setString(key, jsonEncode(data));
        break;
      }
    } catch (_) {}
  }
  if (await file.exists()) {
    try {
      await file.delete();
    } catch (_) {}
  }
}

