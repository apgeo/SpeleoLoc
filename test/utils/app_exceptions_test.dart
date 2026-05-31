import 'package:flutter_test/flutter_test.dart';
import 'package:speleoloc/utils/app_exceptions.dart';

void main() {
  group('AppException hierarchy', () {
    test('all concrete exceptions implement Exception and AppException', () {
      const db = DbException('bad query');
      const v = ValidationException('empty');
      const io = IoException('no file');
      expect(db, isA<Exception>());
      expect(db, isA<AppException>());
      expect(v, isA<AppException>());
      expect(io, isA<AppException>());
    });

    test('message and cause are exposed', () {
      final cause = FormatException('boom');
      final e = DbException('insert failed', cause: cause);
      expect(e.message, 'insert failed');
      expect(e.cause, same(cause));
    });

    test('toString without cause renders runtimeType + message only', () {
      const e = ValidationException('title is required');
      expect(e.toString(), 'ValidationException: title is required');
    });

    test('toString with cause appends the cause text', () {
      final cause = FormatException('bad json');
      final e = DbException('parse failed', cause: cause);
      expect(e.toString(), contains('DbException: parse failed'));
      expect(e.toString(), contains('(cause: '));
      expect(e.toString(), contains('bad json'));
    });

    test('ValidationException carries an optional field id', () {
      const e = ValidationException('empty', field: 'title');
      expect(e.field, 'title');
    });

    test('IoException carries an optional path', () {
      const e = IoException('not found', path: '/tmp/x');
      expect(e.path, '/tmp/x');
    });

    test('subtypes are distinguishable in catch blocks', () {
      try {
        throw const ValidationException('x');
      } on DbException {
        fail('should not match DbException');
      } on ValidationException catch (e) {
        expect(e.message, 'x');
      }
    });
  });
}
