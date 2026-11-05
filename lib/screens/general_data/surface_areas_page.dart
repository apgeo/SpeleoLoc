import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speleoloc/providers/providers.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/utils/localization.dart';
import 'package:speleoloc/services/range_code_generator.dart';
import 'package:speleoloc/screens/general_data/surface_area_dialog.dart';
import 'package:speleoloc/widgets/app_global_menu.dart';
import 'package:speleoloc/widgets/index_range_dialog.dart';
import 'package:speleoloc/widgets/place_code_batch_ui.dart';
import 'package:speleoloc/services/place_code/batch/place_code_batch_runner.dart';
import 'package:speleoloc/widgets/product_tour.dart';
import 'package:speleoloc/widgets/range_qr_launcher.dart';
import 'package:speleoloc/widgets/snack_bar_service.dart';

class SurfaceAreasPage extends ConsumerStatefulWidget {
  const SurfaceAreasPage({super.key});

  @override
  ConsumerState<SurfaceAreasPage> createState() => _SurfaceAreasPageState();
}

class _SurfaceAreasPageState extends ConsumerState<SurfaceAreasPage>
    with AppBarMenuMixin<SurfaceAreasPage>, ProductTourMixin<SurfaceAreasPage> {
  @override
  String get tourId => 'surface_areas';
  @override
  final TourKeySet tourKeys = TourKeySet();
  @override
  List<TourStepDef> get tourSteps => [
    TourStepDef(
      keyId: 'add',
      titleLocKey: 'tour_surface_areas_add_title',
      bodyLocKey: 'tour_surface_areas_add_body',
    ),
    TourStepDef(
      keyId: 'list',
      titleLocKey: 'tour_surface_areas_list_title',
      bodyLocKey: 'tour_surface_areas_list_body',
    ),
    TourStepDef(
      keyId: 'menu',
      titleLocKey: 'tour_surface_areas_menu_title',
      bodyLocKey: 'tour_surface_areas_menu_body',
    ),
  ];

  List<SurfaceArea> _areas = [];
  bool _changed = false;
  bool _showGenerateIcons = false;

  @override
  List<AppMenuItem> get screenMenuItems => [
    AppMenuItem(
      value: 'toggle_generate_icons',
      icon: _showGenerateIcons
          ? Icons.check_box
          : Icons.check_box_outline_blank,
      label: LocServ.inst.t('show_generate_codes_icons'),
    ),
  ];

  @override
  void onScreenMenuItemSelected(String value) {
    if (value == 'toggle_generate_icons') {
      setState(() => _showGenerateIcons = !_showGenerateIcons);
    }
  }

  @override
  void initState() {
    super.initState();
    _loadAreas();
  }

  void _loadAreas() async {
    final areas = await ref.read(caveRepositoryProvider).getSurfaceAreas();
    if (!mounted) return;
    setState(() {
      _areas = areas;
    });
  }

  Future<void> _showAddEditDialog({SurfaceArea? existing}) async {
    final result = await SurfaceAreaDialog.show(context, existing: existing);

    if (result == true) {
      _changed = true;
      _loadAreas();
      if (!mounted) return;
      SnackBarService.showSuccess(LocServ.inst.t('surface_area_saved'));
    }
  }

  Future<void> _confirmDelete(SurfaceArea area) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(LocServ.inst.t('confirm')),
        content: Text(LocServ.inst.t('delete_area_confirm')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(LocServ.inst.t('cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(LocServ.inst.t('yes')),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ref.read(caveRepositoryProvider).deleteSurfaceArea(area);
      } on Exception {
        SnackBarService.showError(LocServ.inst.t('delete_area_failed'));
        return;
      }
      _changed = true;
      _loadAreas();
      if (!mounted) return;
      SnackBarService.showSuccess(LocServ.inst.t('surface_area_deleted'));
    }
  }

  /// Pre-generate main-entrance QR codes for a range of cave local indices
  /// in [area] that have no recorded cave yet.
  Future<void> _generateEntranceQrRange(SurfaceArea area) async {
    final range = await showIndexRangeDialog(
      context,
      title: LocServ.inst.t('generate_entrance_qr_range'),
      maxSize: RangeCodeGenerator.maxRangeSize,
    );
    if (range == null || !mounted) return;
    final result = await ref
        .read(rangeCodeGeneratorProvider)
        .generateAreaEntranceCodes(
          area: area,
          start: range.start,
          end: range.end,
        );
    if (!mounted) return;
    await presentRangeCodeResult(context, result);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) Navigator.pop(context, _changed);
      },
      child: Scaffold(
        key: appMenuScaffoldKey,
        endDrawer: buildAppMenuEndDrawer(),
        appBar: AppBar(
          title: Text(LocServ.inst.t('manage_surface_areas')),
          actions: [
            IconButton(
              key: tourKeys['add'],
              onPressed: () => _showAddEditDialog(),
              icon: const Icon(Icons.add),
            ),
            KeyedSubtree(key: tourKeys['menu'], child: buildAppBarMenuButton()),
          ],
        ),
        body: ListView.separated(
          key: tourKeys['list'],
          itemCount: _areas.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final area = _areas[index];
            return ListTile(
              title: Text(area.title),
              subtitle: area.description != null && area.description!.isNotEmpty
                  ? Text(
                      area.description!,
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    )
                  : null,
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_showGenerateIcons)
                    IconButton(
                      onPressed: () => PlaceCodeBatchUi.run(
                        context,
                        runner: ref.read(placeCodeBatchRunnerProvider),
                        scope: PerAreaScope(area.uuid),
                        confirmTitle: LocServ.inst.t('generate_codes'),
                        confirmBody: LocServ.inst.t(
                          'generate_codes_confirm_area',
                        ),
                      ),
                      icon: const Icon(Icons.auto_awesome),
                      tooltip: LocServ.inst.t('generate_codes'),
                    ),
                  // Entrance QR range is always visible — it generates codes
                  // for not-yet-recorded caves, so it is useful independently
                  // of the existing-code batch toggle above.
                  IconButton(
                    onPressed: () => _generateEntranceQrRange(area),
                    icon: const Icon(Icons.qr_code_2),
                    tooltip: LocServ.inst.t('generate_entrance_qr_range'),
                  ),
                  IconButton(
                    onPressed: () => _showAddEditDialog(existing: area),
                    icon: const Icon(Icons.edit),
                  ),
                  IconButton(
                    onPressed: () => _confirmDelete(area),
                    icon: const Icon(Icons.delete),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
