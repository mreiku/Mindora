import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../backend/auth_service.dart';

final userProvider = FutureProvider<Map<String, String>>((ref) async {
  final auth = AuthService();
  return await auth.getUserData();
});
