import 'package:flutter/material.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/utils/localization.dart';

/// Header + tab-bar + TabBarView for the raster-maps section of the
/// cave-place page. Render is conditional: caller passes a non-empty
/// [rasterMaps] list. The arrow buttons drive [tabController] directly;
/// [currentTabIndex] is mirrored in for enable/disable state.
class CavePlaceRasterMapsSection extends StatelessWidget {
  const CavePlaceRasterMapsSection({
    super.key,
    required this.rasterMaps,
    required this.tabController,
    required this.currentTabIndex,
    required this.buildMapTab,
    this.tabsKey,
  });

  final List<RasterMap> rasterMaps;
  final TabController? tabController;
  final int currentTabIndex;
  final Widget Function(RasterMap rm) buildMapTab;
  final Key? tabsKey;

  static final _imageExtRe = RegExp(r'\.(jpg|jpeg|png|bmp)$');

  @override
  Widget build(BuildContext context) {
    if (rasterMaps.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 0.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Text(
              '${LocServ.inst.t('raster_maps')}:',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          DefaultTabController(
            key: tabsKey,
            length: rasterMaps.length,
            child: Column(
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: currentTabIndex > 0
                          ? () => tabController?.animateTo(currentTabIndex - 1)
                          : null,
                      icon: const Icon(Icons.arrow_left),
                    ),
                    Expanded(
                      child: TabBar(
                        controller: tabController,
                        isScrollable: true,
                        tabs: rasterMaps
                            .map(
                              (rm) => Tab(
                                text: rm.title.isEmpty
                                    ? rm.fileName.replaceAll(_imageExtRe, '')
                                    : rm.title,
                              ),
                            )
                            .toList(),
                      ),
                    ),
                    IconButton(
                      onPressed: currentTabIndex <
                              (tabController?.length ?? 0) - 1
                          ? () => tabController?.animateTo(currentTabIndex + 1)
                          : null,
                      icon: const Icon(Icons.arrow_right),
                    ),
                  ],
                ),
                SizedBox(
                  height: 350,
                  child: TabBarView(
                    controller: tabController,
                    children:
                        rasterMaps.map((rm) => buildMapTab(rm)).toList(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
