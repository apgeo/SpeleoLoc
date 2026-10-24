import 'package:flutter_test/flutter_test.dart';
import 'package:speleoloc/services/trip_participants.dart';

void main() {
  test('splits on commas, trims and drops blanks', () {
    expect(TripParticipants.parse(' Ana, Bogdan ,, Cristi ,'), [
      'Ana',
      'Bogdan',
      'Cristi',
    ]);
  });

  test('keeps each name once, the first spelling winning', () {
    expect(TripParticipants.parse('Ana, ana, ANA, Dan'), ['Ana', 'Dan']);
  });

  test('nothing typed is no participants', () {
    expect(TripParticipants.parse(null), isEmpty);
    expect(TripParticipants.parse('  , ,'), isEmpty);
    expect(TripParticipants.format(const []), isNull);
  });

  test('stores them comma-separated', () {
    expect(TripParticipants.format(['Ana', ' Bogdan ']), 'Ana, Bogdan');
  });

  test('adding appends, unless the name is already there', () {
    expect(
      TripParticipants.add('Ana, Bogdan', 'Cristi'),
      'Ana, Bogdan, Cristi',
    );
    expect(TripParticipants.add('Ana, Bogdan', 'bogdan'), 'Ana, Bogdan');
    expect(TripParticipants.add('', 'Ana'), 'Ana');
  });
}
