// lib/core/utils/enum_label.dart

extension EnumLabel on Enum {
  String get label {
    final raw = toString();
    final dotIndex = raw.indexOf('.');
    return dotIndex == -1 ? raw : raw.substring(dotIndex + 1);
  }
}
