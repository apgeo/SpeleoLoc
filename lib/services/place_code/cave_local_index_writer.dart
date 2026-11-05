import 'package:speleoloc/utils/uuid.dart';

/// Persists the cave index a place-code strategy allocates.
///
/// The index is part of every code minted for the cave, so the write must be
/// stamped and logged like any other edit: otherwise it never reaches other
/// devices, and each one allocates its own index for the same cave.
abstract interface class CaveLocalIndexWriter {
  Future<void> setCaveLocalIndex(Uuid caveUuid, String caveLocalIndex);
}
