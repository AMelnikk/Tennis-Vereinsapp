import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

void appError(ScaffoldMessengerState messenger, String errorText) {
  messenger.showSnackBar(
    SnackBar(content: Text(errorText)),
  );
  if (kDebugMode) {
    print(errorText);
  }
}
