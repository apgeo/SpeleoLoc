import 'package:flutter/material.dart';
import 'package:speleoloc/services/silexgis/silexgis_profile.dart';
import 'package:speleoloc/services/silexgis/silexgis_served_parts.dart';
import 'package:speleoloc/utils/localization.dart';

/// One line per optional part of sync: whether the installation offered it
/// on the last run, and what this device does with it.
class SilexgisServedPartsCard extends StatelessWidget {
  const SilexgisServedPartsCard({required this.profile, super.key});

  final SilexgisProfile profile;

  @override
  Widget build(BuildContext context) {
    final known = profile.servedFeatures != null;
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          ListTile(
            leading: const Icon(Icons.dns_outlined),
            title: Text(LocServ.inst.t('silexgis_parts_title')),
            subtitle: Text(
              LocServ.inst.t(
                known ? 'silexgis_parts_as_of' : 'silexgis_parts_unknown',
              ),
            ),
          ),
          for (final part in SilexgisServedPart.values)
            _PartTile(part: part, profile: profile),
        ],
      ),
    );
  }
}

class _PartTile extends StatelessWidget {
  const _PartTile({required this.part, required this.profile});

  final SilexgisServedPart part;
  final SilexgisProfile profile;

  @override
  Widget build(BuildContext context) {
    final served = part.servedBy(profile);
    final scheme = Theme.of(context).colorScheme;
    return ListTile(
      dense: true,
      leading: Icon(switch (served) {
        true => Icons.check_circle_outline,
        false => Icons.remove_circle_outline,
        null => Icons.help_outline,
      }, color: served == true ? scheme.primary : scheme.outline),
      title: Text(_name(part)),
      subtitle: served == null
          ? null
          : Text(
              '${LocServ.inst.t(served ? 'silexgis_part_served' : 'silexgis_part_not_served')}'
              ' · ${_use(part, served: served)}',
            ),
    );
  }

  static String _name(SilexgisServedPart part) => switch (part) {
    SilexgisServedPart.documents => LocServ.inst.t('silexgis_part_documents'),
    SilexgisServedPart.documentUpload => LocServ.inst.t(
      'silexgis_part_document_upload',
    ),
    SilexgisServedPart.trips => LocServ.inst.t('silexgis_part_trips'),
    SilexgisServedPart.rasters => LocServ.inst.t('silexgis_part_rasters'),
    SilexgisServedPart.reviews => LocServ.inst.t('silexgis_part_reviews'),
    SilexgisServedPart.people => LocServ.inst.t('silexgis_part_people'),
  };

  String _use(SilexgisServedPart part, {required bool served}) =>
      switch (part) {
        SilexgisServedPart.documents => LocServ.inst.t(
          served ? 'silexgis_part_documents_on' : 'silexgis_part_documents_off',
        ),
        SilexgisServedPart.documentUpload =>
          served
              ? switch (SilexgisFileSending.of(profile)) {
                  SilexgisFileSending.off => LocServ.inst.t(
                    'silexgis_part_upload_off_here',
                  ),
                  SilexgisFileSending.wifiOrAsk => LocServ.inst.t(
                    'silexgis_part_upload_wifi_ask',
                  ),
                  SilexgisFileSending.wifiOnly => LocServ.inst.t(
                    'silexgis_part_upload_wifi',
                  ),
                  SilexgisFileSending.anyNetwork => LocServ.inst.t(
                    'silexgis_part_upload_any',
                  ),
                }
              : LocServ.inst.t('silexgis_part_upload_off'),
        SilexgisServedPart.trips => LocServ.inst.t(
          served ? 'silexgis_part_trips_on' : 'silexgis_part_trips_off',
        ),
        SilexgisServedPart.rasters => LocServ.inst.t(
          served ? 'silexgis_part_rasters_on' : 'silexgis_part_rasters_off',
        ),
        SilexgisServedPart.reviews => LocServ.inst.t(
          served ? 'silexgis_part_reviews_on' : 'silexgis_part_reviews_off',
        ),
        SilexgisServedPart.people => LocServ.inst.t(
          served ? 'silexgis_part_people_on' : 'silexgis_part_people_off',
        ),
      };
}
