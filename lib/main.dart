import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

void main() => runApp(const WrongAnswerApp());

class WrongAnswerApp extends StatelessWidget {
  const WrongAnswerApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: '오답노트',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xff4b5fc0)),
          useMaterial3: true,
        ),
        home: const UploadProblemPage(),
      );
}

class UploadProblemPage extends StatefulWidget {
  const UploadProblemPage({super.key});

  @override
  State<UploadProblemPage> createState() => _UploadProblemPageState();
}

class _UploadProblemPageState extends State<UploadProblemPage> {
  final _picker = ImagePicker();
  final _textController = TextEditingController();
  XFile? _image;
  PlatformFile? _pdf;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _takePhoto() async {
    final photo = await _picker.pickImage(source: ImageSource.camera, imageQuality: 85);
    if (photo != null && mounted) setState(() => _image = photo);
  }

  Future<void> _pickImage() async {
    final image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (image != null && mounted) setState(() => _image = image);
  }

  Future<void> _pickPdf() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (result != null && result.isNotEmpty && mounted) {
      setState(() => _pdf = result.single);
    }
  }

  Future<void> _pasteText() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text?.trim().isNotEmpty == true) {
      setState(() => _textController.text = data!.text!.trim());
    }
  }

  void _save() {
    if (_image == null && _pdf == null && _textController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('문제 사진, PDF 또는 텍스트를 추가해 주세요.')));
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('문제를 오답노트에 추가했어요.')));
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('새 오답 추가')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text('문제를 가져와 보세요', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('사진, PDF, 또는 복사한 텍스트를 이용할 수 있어요.', style: TextStyle(color: colors.onSurfaceVariant)),
            const SizedBox(height: 24),
            Row(children: [
              Expanded(child: _ActionCard(icon: Icons.camera_alt_outlined, label: '사진 촬영', onTap: _takePhoto)),
              const SizedBox(width: 12),
              Expanded(child: _ActionCard(icon: Icons.photo_library_outlined, label: '앨범에서 선택', onTap: _pickImage)),
            ]),
            const SizedBox(height: 12),
            _ActionCard(icon: Icons.picture_as_pdf_outlined, label: 'PDF 파일 선택', wide: true, onTap: _pickPdf),
            if (_image != null) ...[
              const SizedBox(height: 20),
              ClipRRect(borderRadius: BorderRadius.circular(16), child: Image.file(File(_image!.path), height: 190, width: double.infinity, fit: BoxFit.cover)),
              TextButton.icon(onPressed: () => setState(() => _image = null), icon: const Icon(Icons.close), label: const Text('사진 제거')),
            ],
            if (_pdf != null) ...[
              const SizedBox(height: 20),
              ListTile(leading: const Icon(Icons.picture_as_pdf), title: Text(_pdf!.name), subtitle: const Text('선택된 PDF'), trailing: IconButton(icon: const Icon(Icons.close), onPressed: () => setState(() => _pdf = null))),
            ],
            const SizedBox(height: 24),
            Row(children: [Text('문제 텍스트', style: Theme.of(context).textTheme.titleMedium), const Spacer(), TextButton.icon(onPressed: _pasteText, icon: const Icon(Icons.content_paste), label: const Text('붙여넣기'))]),
            TextField(controller: _textController, minLines: 6, maxLines: 12, decoration: const InputDecoration(hintText: '문제를 복사해서 붙여넣거나 직접 입력하세요.', border: OutlineInputBorder())),
            const SizedBox(height: 24),
            FilledButton.icon(onPressed: _save, icon: const Icon(Icons.add_task), label: const Text('오답노트에 추가'), style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52))),
          ],
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({required this.icon, required this.label, required this.onTap, this.wide = false});
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool wide;

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          height: 104,
          decoration: BoxDecoration(color: Theme.of(context).colorScheme.secondaryContainer, borderRadius: BorderRadius.circular(16)),
          child: wide
              ? Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(icon), const SizedBox(width: 10), Text(label)])
              : Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(icon, size: 28), const SizedBox(height: 8), Text(label, textAlign: TextAlign.center)]),
        ),
      );
}
