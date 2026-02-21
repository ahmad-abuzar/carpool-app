import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user.dart';
import '../services/user_service.dart';

// User Service Provider
final userServiceProvider = Provider<UserService>((ref) {
  return UserService();
});

// Provider to fetch a user by ID (Stream)
final userProvider = StreamProvider.family<User?, String>((ref, userId) {
  final userService = ref.watch(userServiceProvider);
  return userService.listenToUser(userId);
});

// Provider to fetch a user by ID (Future) - useful for one-time fetches
final userFutureProvider = FutureProvider.family<User?, String>((ref, userId) {
  final userService = ref.watch(userServiceProvider);
  return userService.getUserById(userId);
});
