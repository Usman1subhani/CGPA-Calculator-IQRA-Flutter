/// Single source of truth for the app's display name, referenced anywhere
/// it's shown in-app (About dialog, share text, etc). The
/// OS-level launcher name is set separately per platform (AndroidManifest,
/// Info.plist, Runner.rc, etc) since those can't reference Dart code.
class AppInfo {
  AppInfo._();

  static const String appName = 'Student GPA Calculator';
  static const String appNameShort = 'Student GPA Calculator';
  static const String universityName = 'Iqra University';
  static const String universityShortName = 'IUIC';
  static const String developerName = 'Usman Subhani';
}
