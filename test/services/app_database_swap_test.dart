import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/providers/providers.dart';
import 'package:speleoloc/services/service_locator.dart';

void main() {
  test(
    'replaceAppDatabase swaps the global and rewires provider dependents',
    () async {
      // Simulate app start: process-wide DB + root container, no overrides so
      // appDatabaseProvider resolves through the global (the production path).
      final db1 = AppDatabase.forTesting(NativeDatabase.memory());
      appDatabase = db1;
      final container = ProviderContainer();
      addTearDown(container.dispose);
      initRootContainer(container);

      expect(container.read(appDatabaseProvider), same(db1));
      final cfgBefore = container.read(configurationRepositoryProvider);
      await cfgBefore.writeString('swap_probe', 'one');
      expect(await cfgBefore.readString('swap_probe'), 'one');

      // Simulate a restore: old DB closed, new instance swapped in.
      final db2 = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db2.close);
      await db1.close();
      replaceAppDatabase(db2);

      // The global and the provider both serve the new instance…
      expect(appDatabase, same(db2));
      expect(container.read(appDatabaseProvider), same(db2));

      // …and dependent providers were rebuilt against it instead of keeping
      // the closed db1 (which is exactly the pre-fix failure mode: reads
      // through the old repository would throw on the closed database).
      final cfgAfter = container.read(configurationRepositoryProvider);
      expect(cfgAfter, isNot(same(cfgBefore)));
      expect(await cfgAfter.readString('swap_probe'), isNull);
      await cfgAfter.writeString('swap_probe', 'two');
      expect(await cfgAfter.readString('swap_probe'), 'two');

      // The legacy service_locator getters resolve fresh as well.
      expect(await configurationRepository.readString('swap_probe'), 'two');
    },
  );
}
