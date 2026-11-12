import '../../domain/enums/post_run_action.dart';

/// Executes the action selected to run after a batch finishes.
abstract interface class IPostRunService {
  Future<void> perform(PostRunAction action);
}
