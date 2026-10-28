import 'package:flutter_test/flutter_test.dart';
import 'package:speleoloc/services/silexgis/model/sync_review.dart';
import 'package:speleoloc/services/silexgis/model/sync_upload_section.dart';
import 'package:speleoloc/services/silexgis/silexgis_contract.dart';

import 'contract_fixtures.dart';

/// Replays the recorded reads of the reviews stream.
void main() {
  group('21-reviews-first-page', () {
    final exchange = ContractExchange('21-reviews-first-page');

    test('is a plain read of the set\'s reviews stream', () {
      expect(exchange.requestLine, startsWith('GET '));
      expect(exchange.requestTarget, SilexgisContract.reviewsPath('<set>'));
    });

    test('a turned-down edit carries the note and the server\'s row', () {
      final page = SyncReviewsPage.fromJson(exchange.responseBody);
      expect(page.setRevision, 1);
      expect(page.hasMore, isFalse);
      expect(page.nextCursor, isNotNull);

      final review = page.reviews.single;
      expect(review.reviewId, '<review>');
      expect(review.section, SyncUploadSection.rows);
      expect(review.rowId, '<entrance>');
      expect(review.outcome, SyncReviewOutcome.rejected);
      expect(review.note, 'Wrong shaft');
      expect(review.revision, isNotNull);
      expect(review.code, isNull);

      // Shaped exactly as the feature stream delivers it, so it goes through
      // the same applier.
      final current = review.currentRow!;
      expect(current.id, '<entrance>');
      expect(current.kind, 'caveEntrance');
      expect(current.name, 'Intrare');
      expect(current.geometry!.latitude, 45.61);
      expect(current.primaryParent!.parentId, '<cave>');
    });
  });

  group('22-reviews-current-withheld', () {
    final exchange = ContractExchange('22-reviews-current-withheld');

    test('the server\'s row is absent, not blurred', () {
      final review = SyncReviewsPage.fromJson(
        exchange.responseBody,
      ).reviews.single;
      expect(review.outcome, SyncReviewOutcome.rejected);
      expect(review.note, 'Wrong shaft');
      expect(review.current, isNull);
      expect(review.currentRow, isNull);
      expect(
        (exchange.responseBody['reviews']! as List).single as Map,
        isNot(contains('current')),
      );
    });
  });

  test('an edit accepted in part says so, with the server\'s row of any '
      'section', () {
    final review = SyncReview.fromJson(const <String, Object?>{
      'reviewId': 'r',
      'entity': 'tripRecordings',
      'rowId': 'x',
      'outcome': 'accepted',
      'partial': true,
      'revision': '2026-10-28T09:00:00Z',
      'current': <String, Object?>{'id': 'x', 'points': <Object?>[]},
    });
    expect(review.outcome, SyncReviewOutcome.accepted);
    expect(review.partial, isTrue);
    expect(review.current?['id'], 'x');
    // Not a feature, so not read as one.
    expect(review.currentRow, isNull);
  });

  test('an edit written whole names no part', () {
    final review = SyncReview.fromJson(const <String, Object?>{
      'reviewId': 'r',
      'entity': 'rows',
      'rowId': 'x',
      'outcome': 'accepted',
    });
    expect(review.partial, isFalse);
    expect(review.current, isNull);
  });

  test('an outcome this build has not heard of is kept, not guessed', () {
    final review = SyncReview.fromJson(const <String, Object?>{
      'reviewId': 'r',
      'entity': 'somethingNew',
      'rowId': 'x',
      'outcome': 'deferred',
    });
    expect(review.outcome, isNull);
    expect(review.rawOutcome, 'deferred');
    expect(review.section, isNull);
  });
}
