import 'dart:async';

import 'package:rxdart/rxdart.dart';

mixin WatchCombinedStateMixin {
  Stream<bool> watchCombinedState<T>(
    List<Stream<T>> streams,
  ) {
    var watchCombinedStateSubject = PublishSubject<bool>();
    var subscriptions =
        List<StreamSubscription<T>>.filled(streams.length, null);
    var values = List<T>.filled(streams.length, null);

    for (int i = 0; i < streams.length; ++i) {
      int j = i;
      subscriptions[i] = streams[i].listen(
        (value) {
          values[j] = value;
          watchCombinedStateSubject.add(
            values.every((value) => value != null),
          );
        },
        onError: (_) {
          values[j] = null;
          watchCombinedStateSubject.add(false);
        },
      );
    }

    watchCombinedStateSubject.onCancel = () {
      subscriptions.forEach((subscription) => subscription.cancel());
      watchCombinedStateSubject.close();
    };

    return watchCombinedStateSubject.stream;
  }
}
