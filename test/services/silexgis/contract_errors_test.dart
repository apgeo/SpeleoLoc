import 'package:flutter_test/flutter_test.dart';
import 'package:speleoloc/services/silexgis/model/silexgis_problem.dart';

import 'contract_fixtures.dart';

/// Replays the three recorded refusals, and pins the two answers that carry no
/// `code` at all.
void main() {
  group('16-errors/cursor-invalid', () {
    final exchange = ContractExchange('16-errors/cursor-invalid');

    test('a resume position this server never issued is thrown away', () {
      expect(exchange.status, 400);
      final problem = SilexgisProblem.tryParse(
        exchange.status,
        exchange.responseBody,
      )!;
      expect(problem.code, SilexgisCodes.cursorInvalid);
      // Drop the cursor and read the set from the beginning, accepting that
      // this is a full re-read. Never resend it as sent.
      expect(problem.action, SilexgisAction.applyAndResubmit);
    });
  });

  group('16-errors/cursor-stale', () {
    final exchange = ContractExchange('16-errors/cursor-stale');

    test('a different status and code for the same decision on the device', () {
      expect(exchange.status, 409);
      final problem = SilexgisProblem.tryParse(
        exchange.status,
        exchange.responseBody,
      )!;
      expect(problem.code, SilexgisCodes.cursorStale);
      expect(problem.action, SilexgisAction.applyAndResubmit);

      // Same reflex as the invalid one, reached from a different pair — which
      // is exactly why the client branches on the action and not on the code.
      final invalid = SilexgisProblem.tryParse(
        400,
        ContractExchange('16-errors/cursor-invalid').responseBody,
      )!;
      expect(problem.action, invalid.action);
      expect(problem.status, isNot(invalid.status));
      expect(problem.code, isNot(invalid.code));
    });
  });

  group('16-errors/contract-unsupported', () {
    final exchange = ContractExchange('16-errors/contract-unsupported');

    test(
      'a batch pinned to a version this server cannot serve is refused whole',
      () {
        expect(exchange.status, 409);
        expect(exchange.requestBody['contractVersion'], 99);

        final problem = SilexgisProblem.tryParse(
          exchange.status,
          exchange.responseBody,
        )!;
        expect(problem.code, SilexgisCodes.contractUnsupported);
        expect(problem.action, SilexgisAction.stop);
        // The server's own version is in the detail, for a human. Nothing
        // branches on it: the version is read structurally from capabilities.
        expect(problem.detail, contains('contract version 1'));
      },
    );

    test('there are no per-row results at all', () {
      // The shape a client is most likely to get wrong: reading `rows` before
      // checking the status crashes on the one answer an un-updated phone is
      // most likely to meet.
      expect(exchange.responseBody.containsKey('rows'), isFalse);
      expect(
        exchange.responseBody.keys,
        unorderedEquals(<String>[
          'type',
          'title',
          'status',
          'detail',
          'code',
          'traceId',
        ]),
      );
    });
  });

  group('the two answers that carry no code', () {
    test('a 401 is re-auth even when the body says nothing useful', () {
      // Produced by authentication before the route runs, so no handler mints
      // a code. Every route in this slice answers it.
      final problem = SilexgisProblem.tryParse(401, <String, Object?>{
        'type': 'https://tools.ietf.org/html/rfc9110#section-15.5.2',
        'title': 'Unauthorized',
        'status': 401,
        'traceId': '00-f755a89a14e9ed9515a25af937676607-36e31dc4d28ba6ed-00',
      })!;
      expect(problem.code, isNull);
      expect(problem.action, SilexgisAction.reAuth);
    });

    test('a 401 is never mistaken for a transport failure', () {
      // A body that is not a problem document at all — a captive portal's HTML
      // page, say. Letting the "unparseable means transport" rule reach a 401
      // would retry an expired token for ever instead of refreshing it, and
      // sync would stop within the access token's lifetime with nothing in the
      // log but retries.
      final problem = SilexgisProblem.tryParse(401, '<html>Sign in</html>')!;
      expect(problem.action, SilexgisAction.reAuth);
    });

    test('the QR route\'s 429 carries no type either', () {
      final problem = SilexgisProblem.tryParse(429, <String, Object?>{
        'title': 'Too Many Requests',
        'status': 429,
        'traceId': '00-ae482e49bc8b75415e123c5e6814ebde-8b1a296096d91b5d-00',
      })!;
      expect(problem.code, isNull);
      expect(problem.type, isNull);
      expect(problem.action, SilexgisAction.retry);
    });

    test('any other unparseable 4xx is not a server verdict', () {
      expect(SilexgisProblem.tryParse(502, '<html>Bad Gateway</html>'), isNull);
      expect(SilexgisProblem.tryParse(404, 'not json'), isNull);
    });
  });

  group('the action vocabulary', () {
    test('names one action per documented code', () {
      const expected = <String, SilexgisAction>{
        SilexgisCodes.setNotFound: SilexgisAction.surfaceToUser,
        SilexgisCodes.cursorInvalid: SilexgisAction.applyAndResubmit,
        SilexgisCodes.cursorStale: SilexgisAction.applyAndResubmit,
        SilexgisCodes.rootNotFound: SilexgisAction.surfaceToUser,
        SilexgisCodes.cavingGroupNotFound: SilexgisAction.surfaceToUser,
        SilexgisCodes.cavingGroupForbidden: SilexgisAction.surfaceToUser,
        SilexgisCodes.setRevisionRequired: SilexgisAction.applyAndResubmit,
        SilexgisCodes.setConflict: SilexgisAction.applyAndResubmit,
        SilexgisCodes.validationFailed: SilexgisAction.stop,
        SilexgisCodes.contractUnsupported: SilexgisAction.stop,
        SilexgisCodes.batchTooLarge: SilexgisAction.applyAndResubmit,
        SilexgisCodes.batchConflict: SilexgisAction.retry,
        SilexgisCodes.qrNotFound: SilexgisAction.surfaceToUser,
      };
      for (final entry in expected.entries) {
        final problem = SilexgisProblem(status: 400, code: entry.key);
        expect(problem.action, entry.value, reason: entry.key);
      }
    });

    test('a 5xx is a transport-shaped failure whatever it carries', () {
      expect(const SilexgisProblem(status: 503).action, SilexgisAction.retry);
    });

    test('a code this build has never heard of does not loop', () {
      expect(
        const SilexgisProblem(status: 400, code: 'sync.invented_later').action,
        SilexgisAction.stop,
      );
    });
  });
}
