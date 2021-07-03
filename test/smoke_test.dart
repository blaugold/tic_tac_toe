import 'package:flutter_test/flutter_test.dart';
import 'package:tic_tac_toe/src/app.dart';

void main() {
  testWidgets('app is able to launch', (tester) async {
    await tester.pumpWidget(const TicTacToeApp());
  });
}
