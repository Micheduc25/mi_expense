import 'package:flutter/material.dart';

/// Helper class to handle deferred loading of components
/// This helps reduce initial app load time and app size
class DeferredLoader {
  /// Loads a widget that might be expensive in terms of code size
  /// Shows a loading indicator while loading
  static Widget loadDeferred({
    required Future<void> Function() loadFunction,
    required Widget Function() builder,
    Widget? loadingWidget,
  }) {
    return FutureBuilder(
      future: loadFunction(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          return builder();
        }
        return loadingWidget ??
            const Center(child: CircularProgressIndicator());
      },
    );
  }
}
