/// Prevents the operating system from sleeping while a run is active.
abstract interface class ISleepInhibitor {
  void inhibit();
  void release();
}
