import 'package:hive/hive.dart';

abstract class AuthLocalDataSource {
  Future<void> storeToken(String token);
  Future<void> storeUserId(String userId);
  Future<String?> getToken();
  Future<String?> getUserId();
  Future<void> clearAll();
}

class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  static const String _tokenKey = 'auth_token';
  static const String _userIdKey = 'user_id';
  static const String _boxName = 'app';

  Future<Box> get _box async {
    if (!Hive.isBoxOpen(_boxName)) {
      return await Hive.openBox(_boxName);
    }
    return Hive.box(_boxName);
  }

  @override
  Future<void> storeToken(String token) async {
    final box = await _box;
    await box.put(_tokenKey, token);
  }

  @override
  Future<void> storeUserId(String userId) async {
    final box = await _box;
    await box.put(_userIdKey, userId);
  }

  @override
  Future<String?> getToken() async {
    final box = await _box;
    return box.get(_tokenKey)?.toString();
  }

  @override
  Future<String?> getUserId() async {
    final box = await _box;
    return box.get(_userIdKey)?.toString();
  }

  @override
  Future<void> clearAll() async {
    final box = await _box;
    await box.delete(_tokenKey);
    await box.delete(_userIdKey);
  }
}

