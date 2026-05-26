import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/local_dispatch_service.dart';

final dispatchResultProvider = StateProvider<AsyncValue<DispatchResult>?>((ref) => null);
