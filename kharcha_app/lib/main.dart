import 'package:kharcha_app/app.dart';
import 'package:kharcha_app/bootstrap.dart';

Future<void> main() async {
  await bootstrap(() => const App());
}
