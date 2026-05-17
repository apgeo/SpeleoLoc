import 'package:flutter_test/flutter_test.dart';
import 'package:speleoloc/services/place_code/batch/place_code_overwrite_policy.dart';

void main() {
  group('PlaceCodeOverwritePolicy', () {
    test('writes silently when existing is null/empty', () {
      final p = PlaceCodeOverwritePolicy();
      expect(
        p.decide(field: OverwriteField.pci, existing: null, computed: 'X'),
        OverwriteAction.write,
      );
      expect(
        p.decide(field: OverwriteField.pci, existing: '', computed: 'X'),
        OverwriteAction.write,
      );
    });

    test('skips silently when computed equals existing', () {
      final p = PlaceCodeOverwritePolicy();
      expect(
        p.decide(field: OverwriteField.pci, existing: 'X', computed: 'X'),
        OverwriteAction.skip,
      );
    });

    test('prompts on real conflict without a blanket', () {
      final p = PlaceCodeOverwritePolicy();
      expect(
        p.decide(field: OverwriteField.pci, existing: 'A', computed: 'B'),
        OverwriteAction.prompt,
      );
    });

    test('replaceAll latches per field', () {
      final p = PlaceCodeOverwritePolicy();
      // First conflict prompts; user picks replaceAll.
      expect(
        p.decide(field: OverwriteField.pci, existing: 'A', computed: 'B'),
        OverwriteAction.prompt,
      );
      final action = p.recordDecision(
        field: OverwriteField.pci,
        decision: OverwriteDecision.replaceAll,
      );
      expect(action, OverwriteAction.write);
      // Subsequent PCI conflicts auto-write.
      expect(
        p.decide(field: OverwriteField.pci, existing: 'C', computed: 'D'),
        OverwriteAction.write,
      );
      // QCRI conflicts still prompt (independent).
      expect(
        p.decide(field: OverwriteField.qcri, existing: 'C', computed: 'D'),
        OverwriteAction.prompt,
      );
    });

    test('keepAll latches per field', () {
      final p = PlaceCodeOverwritePolicy();
      p.recordDecision(
        field: OverwriteField.qcri,
        decision: OverwriteDecision.keepAll,
      );
      expect(
        p.decide(field: OverwriteField.qcri, existing: 'A', computed: 'B'),
        OverwriteAction.skip,
      );
      expect(
        p.decide(field: OverwriteField.pci, existing: 'A', computed: 'B'),
        OverwriteAction.prompt,
      );
    });

    test('cancelBatch latches globally', () {
      final p = PlaceCodeOverwritePolicy();
      final action = p.recordDecision(
        field: OverwriteField.pci,
        decision: OverwriteDecision.cancelBatch,
      );
      expect(action, OverwriteAction.cancel);
      expect(p.isCancelled, isTrue);
      expect(
        p.decide(field: OverwriteField.qcri, existing: 'A', computed: 'B'),
        OverwriteAction.cancel,
      );
    });

    test('one-shot replace/keep do not affect later prompts', () {
      final p = PlaceCodeOverwritePolicy();
      p.recordDecision(
        field: OverwriteField.pci,
        decision: OverwriteDecision.replace,
      );
      expect(
        p.decide(field: OverwriteField.pci, existing: 'A', computed: 'B'),
        OverwriteAction.prompt,
      );
      p.recordDecision(
        field: OverwriteField.pci,
        decision: OverwriteDecision.keep,
      );
      expect(
        p.decide(field: OverwriteField.pci, existing: 'A', computed: 'B'),
        OverwriteAction.prompt,
      );
    });
  });
}
