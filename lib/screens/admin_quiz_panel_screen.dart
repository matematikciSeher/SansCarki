import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/quiz.dart';
import '../data/quiz_repository.dart';

class AdminQuizPanelScreen extends StatefulWidget {
  const AdminQuizPanelScreen({super.key});

  @override
  State<AdminQuizPanelScreen> createState() => _AdminQuizPanelScreenState();
}

class _AdminQuizPanelScreenState extends State<AdminQuizPanelScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _questionCtrl = TextEditingController();
  final List<TextEditingController> _optionCtrls = List.generate(4, (_) => TextEditingController());
  final TextEditingController _correctIndexCtrl = TextEditingController(text: '0');
  final TextEditingController _basePointsCtrl = TextEditingController(text: '10');
  final TextEditingController _explanationCtrl = TextEditingController();
  final TextEditingController _searchCtrl = TextEditingController();
  QuizCategory _category = QuizCategory.genelKultur;
  QuizCategory? _filterCategory;
  bool _saving = false;

  @override
  void dispose() {
    _searchCtrl.dispose();
    _questionCtrl.dispose();
    for (final c in _optionCtrls) c.dispose();
    _correctIndexCtrl.dispose();
    _basePointsCtrl.dispose();
    _explanationCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final int correctIdx = int.parse(_correctIndexCtrl.text);
      final int basePoints = int.parse(_basePointsCtrl.text);
      final options = _optionCtrls.map((c) => c.text.trim()).where((t) => t.isNotEmpty).toList();

      final generatedId = FirebaseFirestore.instance.collection(QuizRepository.collectionName).doc().id;

      final q = QuizQuestion(
        id: generatedId,
        question: _questionCtrl.text.trim(),
        options: options,
        correctAnswerIndex: correctIdx,
        category: _category,
        explanation: _explanationCtrl.text.trim().isEmpty ? null : _explanationCtrl.text.trim(),
        basePoints: basePoints,
      );

      await QuizRepository.addQuestion(q);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Soru kaydedildi')),
      );
      _formKey.currentState!.reset();
      _questionCtrl.clear();
      for (final c in _optionCtrls) c.clear();
      _correctIndexCtrl.text = '0';
      _basePointsCtrl.text = '10';
      _explanationCtrl.clear();
      setState(() {});
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Hata: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Admin Paneli'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Soru Ekle', icon: Icon(Icons.add)),
              Tab(text: 'Soruları Yönet', icon: Icon(Icons.list)),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _AddQuestionTab(),
            _ManageQuestionsTab(),
          ],
        ),
      ),
    );
  }
}

class _AddQuestionTab extends StatefulWidget {
  const _AddQuestionTab();
  @override
  State<_AddQuestionTab> createState() => _AddQuestionTabState();
}

class _AddQuestionTabState extends State<_AddQuestionTab> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _questionCtrl = TextEditingController();
  final List<TextEditingController> _optionCtrls = List.generate(4, (_) => TextEditingController());
  final TextEditingController _correctIndexCtrl = TextEditingController(text: '0');
  final TextEditingController _basePointsCtrl = TextEditingController(text: '10');
  final TextEditingController _explanationCtrl = TextEditingController();
  QuizCategory _category = QuizCategory.genelKultur;
  bool _saving = false;

  @override
  void dispose() {
    _questionCtrl.dispose();
    for (final c in _optionCtrls) c.dispose();
    _correctIndexCtrl.dispose();
    _basePointsCtrl.dispose();
    _explanationCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final int correctIdx = int.parse(_correctIndexCtrl.text);
      final int basePoints = int.parse(_basePointsCtrl.text);
      final options = _optionCtrls.map((c) => c.text.trim()).where((t) => t.isNotEmpty).toList();

      final generatedId = FirebaseFirestore.instance.collection(QuizRepository.collectionName).doc().id;

      final q = QuizQuestion(
        id: generatedId,
        question: _questionCtrl.text.trim(),
        options: options,
        correctAnswerIndex: correctIdx,
        category: _category,
        explanation: _explanationCtrl.text.trim().isEmpty ? null : _explanationCtrl.text.trim(),
        basePoints: basePoints,
      );

      await QuizRepository.addQuestion(q);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Soru kaydedildi')),
      );
      _formKey.currentState!.reset();
      _questionCtrl.clear();
      for (final c in _optionCtrls) c.clear();
      _correctIndexCtrl.text = '0';
      _basePointsCtrl.text = '10';
      _explanationCtrl.clear();
      setState(() {});
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Hata: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _questionCtrl,
                decoration: const InputDecoration(labelText: 'Soru metni'),
                maxLines: 3,
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Gerekli' : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<QuizCategory>(
                value: _category,
                decoration: const InputDecoration(labelText: 'Kategori'),
                items: QuizCategory.values
                    .map((c) => DropdownMenuItem(
                          value: c,
                          child: Text(c.toString().split('.').last),
                        ))
                    .toList(),
                onChanged: (v) => setState(() => _category = v ?? QuizCategory.genelKultur),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _correctIndexCtrl,
                      decoration: const InputDecoration(labelText: 'Doğru cevap indexi (0-3)'),
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Gerekli';
                        final n = int.tryParse(v);
                        if (n == null || n < 0 || n > 3) {
                          return '0-3 arası olmalı';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _basePointsCtrl,
                      decoration: const InputDecoration(labelText: 'Puan'),
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      validator: (v) => (v == null || v.isEmpty) ? 'Gerekli' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text('Seçenekler (A-D)'),
              const SizedBox(height: 8),
              for (int i = 0; i < _optionCtrls.length; i++) ...[
                TextFormField(
                  controller: _optionCtrls[i],
                  decoration: InputDecoration(labelText: 'Seçenek ${String.fromCharCode(65 + i)}'),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Gerekli' : null,
                ),
                const SizedBox(height: 8),
              ],
              const SizedBox(height: 12),
              TextFormField(
                controller: _explanationCtrl,
                decoration: const InputDecoration(labelText: 'Açıklama (opsiyonel)'),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _saving ? null : _submit,
                  icon: _saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.save),
                  label: const Text('Kaydet'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ManageQuestionsTab extends StatefulWidget {
  const _ManageQuestionsTab();
  @override
  State<_ManageQuestionsTab> createState() => _ManageQuestionsTabState();
}

class _ManageQuestionsTabState extends State<_ManageQuestionsTab> {
  String _query = '';
  QuizCategory? _filterCategory;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(
                      labelText: 'Ara (soru metni veya ID)',
                      prefixIcon: Icon(Icons.search),
                    ),
                    onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
                  ),
                ),
                const SizedBox(width: 12),
                DropdownButton<QuizCategory?>(
                  value: _filterCategory,
                  hint: const Text('Kategori'),
                  items: <DropdownMenuItem<QuizCategory?>>[
                    const DropdownMenuItem(value: null, child: Text('Tümü')),
                    ...QuizCategory.values.map((c) => DropdownMenuItem(
                          value: c,
                          child: Text(c.toString().split('.').last),
                        )),
                  ],
                  onChanged: (v) => setState(() => _filterCategory = v),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: StreamBuilder<List<QuizQuestion>>(
                stream: QuizRepository.streamAll(),
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final list = (snap.data ?? <QuizQuestion>[])
                      .where((q) => _filterCategory == null || q.category == _filterCategory)
                      .where((q) {
                    if (_query.isEmpty) return true;
                    final t = _query;
                    return q.id.toLowerCase().contains(t) || q.question.toLowerCase().contains(t);
                  }).toList();
                  if (list.isEmpty) {
                    return const Center(child: Text('Kayıt bulunamadı'));
                  }
                  return ListView.separated(
                    itemCount: list.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, i) {
                      final q = list[i];
                      return ListTile(
                        title: Text(q.question, maxLines: 2, overflow: TextOverflow.ellipsis),
                        subtitle: Text(
                            'ID: ${q.id} • Kategori: ${q.category.toString().split('.').last} • Puan: ${q.basePoints}'),
                        onTap: () => _showEditDialog(context, q),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () => _showEditDialog(context, q),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _confirmDelete(context, q),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, QuizQuestion q) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Silme Onayı'),
        content: Text('“${q.question}” sorusunu silmek istiyor musun?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('İptal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await QuizRepository.deleteQuestion(q.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Soru silindi')));
      }
    }
  }

  Future<void> _showEditDialog(BuildContext context, QuizQuestion q) async {
    final formKey = GlobalKey<FormState>();
    final TextEditingController questionCtrl = TextEditingController(text: q.question);
    final List<TextEditingController> optionCtrls =
        List.generate(4, (i) => TextEditingController(text: i < q.options.length ? q.options[i] : ''));
    final TextEditingController correctIdxCtrl = TextEditingController(text: q.correctAnswerIndex.toString());
    final TextEditingController basePointsCtrl = TextEditingController(text: q.basePoints.toString());
    final TextEditingController explanationCtrl = TextEditingController(text: q.explanation ?? '');
    QuizCategory category = q.category;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Text('Soruyu Düzenle'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: questionCtrl,
                    decoration: const InputDecoration(labelText: 'Soru metni'),
                    maxLines: 3,
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Gerekli' : null,
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<QuizCategory>(
                    value: category,
                    decoration: const InputDecoration(labelText: 'Kategori'),
                    items: QuizCategory.values
                        .map((c) => DropdownMenuItem(value: c, child: Text(c.toString().split('.').last)))
                        .toList(),
                    onChanged: (v) => category = v ?? category,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: correctIdxCtrl,
                          decoration: const InputDecoration(labelText: 'Doğru index (0-3)'),
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'Gerekli';
                            final n = int.tryParse(v);
                            if (n == null || n < 0 || n > 3) return '0-3 arası';
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          controller: basePointsCtrl,
                          decoration: const InputDecoration(labelText: 'Puan'),
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          validator: (v) => (v == null || v.isEmpty) ? 'Gerekli' : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Align(alignment: Alignment.centerLeft, child: Text('Seçenekler (A-D)')),
                  const SizedBox(height: 6),
                  for (int i = 0; i < optionCtrls.length; i++) ...[
                    TextFormField(
                      controller: optionCtrls[i],
                      decoration: InputDecoration(labelText: 'Seçenek ${String.fromCharCode(65 + i)}'),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Gerekli' : null,
                    ),
                    const SizedBox(height: 6),
                  ],
                  TextFormField(
                    controller: explanationCtrl,
                    decoration: const InputDecoration(labelText: 'Açıklama (opsiyonel)'),
                    maxLines: 2,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('İptal')),
            ElevatedButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                final updated = QuizQuestion(
                  id: q.id,
                  question: questionCtrl.text.trim(),
                  options: optionCtrls.map((c) => c.text.trim()).toList(),
                  correctAnswerIndex: int.parse(correctIdxCtrl.text),
                  category: category,
                  explanation: explanationCtrl.text.trim().isEmpty ? null : explanationCtrl.text.trim(),
                  basePoints: int.parse(basePointsCtrl.text),
                );
                await QuizRepository.updateQuestion(updated);
                if (context.mounted) Navigator.pop(context);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Soru güncellendi')));
                }
              },
              child: const Text('Kaydet'),
            ),
          ],
        );
      },
    );
  }
}
