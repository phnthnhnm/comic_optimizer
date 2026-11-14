import 'package:riverpod/riverpod.dart';

import '../interfaces/i_archive_service.dart';
import '../interfaces/i_encoder_service.dart';
import '../interfaces/i_optimizer_service.dart';
import '../interfaces/i_post_run_service.dart';
import '../interfaces/i_process_runner.dart';
import '../interfaces/i_run_history_service.dart';
import '../interfaces/i_settings_service.dart';
import '../interfaces/i_sleep_inhibitor.dart';
import '../../infrastructure/services/archive_service_impl.dart';
import '../../infrastructure/services/encoder_service_impl.dart';
import '../../infrastructure/services/optimizer_service_impl.dart';
import '../../infrastructure/services/post_run_service_impl.dart';
import '../../infrastructure/services/run_history_service_impl.dart';
import '../../infrastructure/services/run_journal_store.dart';
import '../../infrastructure/services/settings_service_impl.dart';
import '../../infrastructure/services/sleep_inhibitor.dart';
import '../../infrastructure/services/system_process_runner.dart';
import 'shared_preferences_provider.dart';

final settingsServiceProvider = Provider<ISettingsService>(
  (ref) => SettingsServiceImpl(ref.watch(sharedPreferencesProvider)),
);

final processRunnerProvider = Provider<IProcessRunner>(
  (ref) => const SystemProcessRunner(),
);

final archiveServiceProvider = Provider<IArchiveService>(
  (ref) => ArchiveServiceImpl(),
);

final encoderServiceProvider = Provider<IEncoderService>(
  (ref) => EncoderServiceImpl(runner: ref.watch(processRunnerProvider)),
);

final optimizerServiceProvider = Provider<IOptimizerService>(
  (ref) => OptimizerServiceImpl(
    ref.watch(archiveServiceProvider),
    ref.watch(encoderServiceProvider),
  ),
);

final postRunServiceProvider = Provider<IPostRunService>(
  (ref) => PostRunServiceImpl(runner: ref.watch(processRunnerProvider)),
);

final runHistoryServiceProvider = Provider<IRunHistoryService>(
  (ref) => RunHistoryServiceImpl(ref.watch(sharedPreferencesProvider)),
);

final runJournalStoreProvider = Provider<RunJournalStore>(
  (ref) => RunJournalStore(ref.watch(sharedPreferencesProvider)),
);

final sleepInhibitorProvider = Provider<ISleepInhibitor>(
  (ref) => WindowsSleepInhibitor(),
);
