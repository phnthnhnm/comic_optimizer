import 'package:riverpod/riverpod.dart';

import '../interfaces/i_archive_service.dart';
import '../interfaces/i_encoder_service.dart';
import '../interfaces/i_optimizer_service.dart';
import '../interfaces/i_settings_service.dart';
import '../../infrastructure/services/archive_service_impl.dart';
import '../../infrastructure/services/encoder_service_impl.dart';
import '../../infrastructure/services/optimizer_service_impl.dart';
import '../../infrastructure/services/settings_service_impl.dart';

final settingsServiceProvider = Provider<ISettingsService>(
  (ref) => SettingsServiceImpl(),
);

final archiveServiceProvider = Provider<IArchiveService>(
  (ref) => ArchiveServiceImpl(),
);

final encoderServiceProvider = Provider<IEncoderService>(
  (ref) => EncoderServiceImpl(),
);

final optimizerServiceProvider = Provider<IOptimizerService>(
  (ref) => OptimizerServiceImpl(),
);
