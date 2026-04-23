import 'package:flutter/material.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/utils/localization.dart';
import 'package:speleoloc/widgets/product_tour.dart';

class CaveTripLogPage extends StatefulWidget {
  const CaveTripLogPage({super.key, required this.tripUuid});
  final Uuid tripUuid;

  @override
  State<CaveTripLogPage> createState() => _CaveTripLogPageState();
}

class _CaveTripLogPageState extends State<CaveTripLogPage> with ProductTourMixin<CaveTripLogPage> {
  @override
  String get tourId => 'cave_trip_log';
  @override
  final tourKeys = TourKeySet(['editor', 'save']);
  @override
  List<TourStepDef> get tourSteps => [
    TourStepDef(keyId: 'editor', titleLocKey: 'tour_cave_trip_log_editor_title', bodyLocKey: 'tour_cave_trip_log_editor_body', align: ContentAlign.top),
    TourStepDef(keyId: 'save', titleLocKey: 'tour_cave_trip_log_save_title', bodyLocKey: 'tour_cave_trip_log_save_body'),
  ];
  final TextEditingController _controller = TextEditingController();
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final trip = await (appDatabase.select(appDatabase.caveTrips)
          ..where((t) => t.uuid.equalsValue(widget.tripUuid)))
        .getSingleOrNull();
    if (mounted) {
      setState(() {
        _controller.text = trip?.log ?? '';
        _loading = false;
      });
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await appDatabase.updateTripLog(widget.tripUuid, _controller.text);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(LocServ.inst.t('trip_log_saved'))),
        );
        Navigator.pop(context);
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(LocServ.inst.t('trip_log_title')),
        actions: [
          if (_saving)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))),
            )
          else
            IconButton(
              key: tourKeys['save'],
              icon: const Icon(Icons.save),
              tooltip: LocServ.inst.t('save'),
              onPressed: _save,
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(12),
              child: TextField(
                key: tourKeys['editor'],
                controller: _controller,
                maxLines: null,
                expands: true,
                decoration: InputDecoration(
                  border: InputBorder.none,
                  hintText: LocServ.inst.t('trip_log_title'),
                ),
                style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
              ),
            ),
    );
  }
}
