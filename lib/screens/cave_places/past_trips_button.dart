import 'package:flutter/material.dart';
import 'package:speleoloc/utils/localization.dart';

/// A small outlined button that shows the number of past trips for a cave
/// and opens the trip-history page when tapped.
///
/// Extracted from [CavePlacesListPage] during Phase 2.2 of the refactoring.
class PastTripsButton extends StatelessWidget {
  const PastTripsButton({
    super.key,
    required this.pastTripsCount,
    required this.onPressed,
  });

  final int pastTripsCount;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    if (pastTripsCount <= 0) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 2),
      child: OutlinedButton.icon(
        icon: const Icon(Icons.history, size: 16),
        label: Text('${LocServ.inst.t('trip_history')} ($pastTripsCount)'),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          textStyle: const TextStyle(fontSize: 13),
        ),
        onPressed: onPressed,
      ),
    );
  }
}
