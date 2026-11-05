import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:speleoloc/utils/one_at_a_time.dart';

/// Recorder buttons start, stop, pause and resume one at a time, and Save has
/// to wait for whichever of them is still running rather than give up.
void main() {
  test('a call while another runs is dropped', () async {
    final gate = OneAtATime();
    final release = Completer<void>();
    var runs = 0;

    final first = gate.run(() async {
      runs++;
      await release.future;
    });
    expect(gate.busy, isTrue);
    await gate.run(() async => runs++);
    expect(runs, 1);

    release.complete();
    await first;
    expect(gate.busy, isFalse);
  });

  test('idle waits for the running action to finish', () async {
    final gate = OneAtATime();
    final release = Completer<void>();
    var finished = false;

    unawaited(
      gate.run(() async {
        await release.future;
        finished = true;
      }),
    );
    var idle = false;
    unawaited(gate.idle.then((_) => idle = true));
    await Future<void>.delayed(Duration.zero);
    expect(idle, isFalse);

    release.complete();
    await Future<void>.delayed(Duration.zero);
    expect(finished, isTrue);
    expect(idle, isTrue);
  });

  test('idle also waits for an action started while waiting', () async {
    final gate = OneAtATime();
    final first = Completer<void>();
    final second = Completer<void>();

    unawaited(gate.run(() => first.future));
    // Wakes up after the gate is free but before idle does.
    unawaited(first.future.then((_) => gate.run(() => second.future)));
    var idle = false;
    unawaited(gate.idle.then((_) => idle = true));
    first.complete();
    await Future<void>.delayed(Duration.zero);
    expect(gate.busy, isTrue);
    expect(idle, isFalse);

    second.complete();
    await Future<void>.delayed(Duration.zero);
    expect(idle, isTrue);
  });

  test('idle completes even when the action failed', () async {
    final gate = OneAtATime();
    final failing = gate.run(() async => throw StateError('recorder gone'));
    await expectLater(failing, throwsStateError);
    await gate.idle;
    expect(gate.busy, isFalse);
  });

  test('idle completes at once when nothing runs', () async {
    await OneAtATime().idle;
  });
}
