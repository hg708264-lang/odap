import 'package:flutter_test/flutter_test.dart';
import 'package:wrong_answer_note/main.dart';

void main() {
  testWidgets('shows problem upload options', (tester) async {
    await tester.pumpWidget(const WrongAnswerApp());

    expect(find.text('새 오답 추가'), findsOneWidget);
    expect(find.text('사진 촬영'), findsOneWidget);
    expect(find.text('PDF 파일 선택'), findsOneWidget);
    expect(find.text('붙여넣기'), findsOneWidget);
  });
}
