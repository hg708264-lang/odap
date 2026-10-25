import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const _supabaseUrl = 'https://shxcutdsungjzaclmykm.supabase.co';
const _supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InNoeGN1dGRzdW5nanphY2xteWttIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTI5MTc0NzIsImV4cCI6MjEwODQ5MzQ3Mn0.XnRzOxJxn3KlENLFk-yRFzuL3VF0H4YWd1Rzn-v9BDI';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(url: _supabaseUrl, anonKey: _supabaseAnonKey);
  runApp(const WrongAnswerApp());
}

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
        home: const AuthGate(),
      );
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});
  @override
  Widget build(BuildContext context) => StreamBuilder<AuthState>(
        stream: Supabase.instance.client.auth.onAuthStateChange,
        builder: (_, snapshot) => Supabase.instance.client.auth.currentSession == null
            ? const LoginPage()
            : const HomePage(),
      );
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late Future<List<Map<String, dynamic>>> _notes;
  @override
  void initState() { super.initState(); _load(); }
  void _load() { _notes = Supabase.instance.client.from('notes').select().order('created_at', ascending: false); }
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('오답노트'), actions: [IconButton(onPressed: () => Supabase.instance.client.auth.signOut(), icon: const Icon(Icons.logout))]),
        body: FutureBuilder<List<Map<String, dynamic>>>(future: _notes, builder: (_, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          final notes = snapshot.data ?? [];
          if (notes.isEmpty) return const Center(child: Text('아직 저장한 오답이 없어요.\n아래 버튼으로 첫 오답을 추가해 보세요.', textAlign: TextAlign.center));
          return RefreshIndicator(onRefresh: () async => setState(_load), child: ListView.builder(padding: const EdgeInsets.all(16), itemCount: notes.length, itemBuilder: (_, i) {
            final reasons = ((notes[i]['reason'] as String?) ?? '이유 미설정').split(',').where((e) => e.isNotEmpty).toList();
            final hearts = (notes[i]['review_count'] as int?) ?? 0;
            return Card(child: ListTile(leading: const Icon(Icons.assignment_outlined), title: Text((notes[i]['content'] as String?)?.isNotEmpty == true ? notes[i]['content'] as String : '첨부 문제'), subtitle: Text('${reasons.join(' · ')} · ${notes[i]['source_type'] as String? ?? 'text'}', style: TextStyle(color: reasons.length >= 2 ? Colors.red : null)), trailing: Wrap(children: [IconButton(icon: Icon(Icons.favorite, color: hearts > 0 ? Colors.red : Colors.grey), onPressed: () async { await Supabase.instance.client.from('notes').update({'review_count': hearts + 1}).eq('id', notes[i]['id']); setState(_load); }), if (hearts > 0) Text('$hearts')])));
          }));
        }),
        floatingActionButton: FloatingActionButton.extended(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const UploadProblemPage())).then((_) => setState(_load)), icon: const Icon(Icons.add), label: const Text('오답 추가')),
      );
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final email = TextEditingController();
  final password = TextEditingController();
  bool signUp = false, busy = false;
  Future<void> submit() async {
    setState(() => busy = true);
    try {
      final auth = Supabase.instance.client.auth;
      if (signUp) {
        await auth.signUp(email: email.text.trim(), password: password.text, emailRedirectTo: 'https://hg708264-lang.github.io/odap/');
      } else {
        await auth.signInWithPassword(email: email.text.trim(), password: password.text);
      }
      if (mounted && signUp) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('가입 완료! 이메일 인증이 필요할 수 있어요.')));
    } on AuthException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Supabase 연결 오류: $e')));
    } finally { if (mounted) setState(() => busy = false); }
  }
  @override
  Widget build(BuildContext context) => Scaffold(body: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 420), child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [
    Text('오답노트', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)), const SizedBox(height: 8),
    Text(signUp ? '계정을 만들고 어디서나 이어서 공부하세요.' : '로그인하면 오답이 기기 간 동기화됩니다.'), const SizedBox(height: 24),
    TextField(controller: email, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: '이메일', border: OutlineInputBorder())), const SizedBox(height: 12),
    TextField(controller: password, obscureText: true, decoration: const InputDecoration(labelText: '비밀번호', border: OutlineInputBorder())), const SizedBox(height: 16),
    FilledButton(onPressed: busy ? null : submit, child: Text(busy ? '처리 중...' : (signUp ? '회원가입' : '로그인'))),
    TextButton(onPressed: () => setState(() => signUp = !signUp), child: Text(signUp ? '이미 계정이 있어요' : '처음 사용하시나요? 회원가입')),
  ])))));
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
  Uint8List? _imageBytes;
  PlatformFile? _pdf;
  final Set<String> _reasons = {'계산실수'};

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _takePhoto() async {
    final photo = await _picker.pickImage(source: ImageSource.camera, imageQuality: 85);
    if (photo != null && mounted) {
      final bytes = await photo.readAsBytes();
      if (mounted) setState(() { _image = photo; _imageBytes = bytes; });
    }
  }

  Future<void> _pickImage() async {
    final image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (image != null && mounted) {
      final bytes = await image.readAsBytes();
      if (mounted) setState(() { _image = image; _imageBytes = bytes; });
    }
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
    final content = _textController.text.trim();
    Supabase.instance.client.from('notes').insert({'user_id': Supabase.instance.client.auth.currentUser!.id, 'content': content, 'reason': _reasons.join(','), 'review_count': 0, 'source_type': _pdf != null ? 'pdf' : (_image != null ? 'image' : 'text')}).then((_) {
      if (mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomePage()));
    }).catchError((_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('저장에 실패했어요. Supabase notes 테이블을 확인해 주세요.')));
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('새 오답 추가'), actions: [IconButton(tooltip: '로그아웃', onPressed: () => Supabase.instance.client.auth.signOut(), icon: const Icon(Icons.logout))]),
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
              if (_imageBytes != null)
                ClipRRect(borderRadius: BorderRadius.circular(16), child: Image.memory(_imageBytes!, height: 190, width: double.infinity, fit: BoxFit.cover)),
              TextButton.icon(onPressed: () => setState(() { _image = null; _imageBytes = null; }), icon: const Icon(Icons.close), label: const Text('사진 제거')),
            ],
            if (_pdf != null) ...[
              const SizedBox(height: 20),
              ListTile(leading: const Icon(Icons.picture_as_pdf), title: Text(_pdf!.name), subtitle: const Text('선택된 PDF'), trailing: IconButton(icon: const Icon(Icons.close), onPressed: () => setState(() => _pdf = null))),
            ],
            const SizedBox(height: 24),
            Row(children: [Text('문제 텍스트', style: Theme.of(context).textTheme.titleMedium), const Spacer(), TextButton.icon(onPressed: _pasteText, icon: const Icon(Icons.content_paste), label: const Text('붙여넣기'))]),
            TextField(controller: _textController, minLines: 6, maxLines: 12, decoration: const InputDecoration(hintText: '문제를 복사해서 붙여넣거나 직접 입력하세요.', border: OutlineInputBorder())),
            const SizedBox(height: 24),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('틀린 이유(복수 선택 가능)'), Wrap(spacing: 8, children: ['계산실수', '유형 취약', '조건 해석', '개념 오류'].map<Widget>((reason) => FilterChip(label: Text(reason), selected: _reasons.contains(reason), selectedColor: Colors.indigo.shade100, onSelected: (selected) => setState(() { if (selected) { _reasons.add(reason); } else if (_reasons.length > 1) { _reasons.remove(reason); } })).toList())]),
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
