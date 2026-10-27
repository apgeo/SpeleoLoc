import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/providers/providers.dart';
import 'package:speleoloc/utils/localization.dart';
import 'package:speleoloc/widgets/snack_bar_service.dart';

/// "Caver on *installation*": which caver of the club's server a phone user
/// is.
///
/// Shows nothing without an active server profile, or while the installation
/// does not offer its people directory to this account. There is no "none"
/// entry: a link cannot be undone from a phone, only by whoever keeps the
/// roster in the browser.
class SilexgisCaverPicker extends ConsumerWidget {
  const SilexgisCaverPicker({required this.userUuid, super.key});

  final Uuid userUuid;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final choice = ref.watch(silexgisCaverChoiceProvider(userUuid)).value;
    if (choice == null) return const SizedBox.shrink();

    final listed = choice.cavers.any((c) => c.caverId == choice.caverId);
    final helper = choice.pending
        ? LocServ.inst.t('silexgis_caver_pending')
        : choice.chosenOnServer
        ? LocServ.inst.t('silexgis_caver_from_server')
        : null;

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: DropdownButtonFormField<String>(
        initialValue: listed ? choice.caverId : null,
        isExpanded: true,
        decoration: InputDecoration(
          labelText: LocServ.inst.t('silexgis_caver_on', <String, String>{
            'installation': choice.installation,
          }),
          helperText: helper,
        ),
        hint: Text(LocServ.inst.t('silexgis_caver_none')),
        items: <DropdownMenuItem<String>>[
          for (final caver in choice.cavers)
            DropdownMenuItem<String>(
              value: caver.caverId,
              child: Text(
                caver.isMe
                    ? LocServ.inst.t('silexgis_caver_me', <String, String>{
                        'name': caver.fullName,
                      })
                    : caver.fullName,
                overflow: TextOverflow.ellipsis,
              ),
            ),
        ],
        onChanged: (caverId) async {
          if (caverId == null || caverId == choice.caverId) return;
          try {
            await ref
                .read(silexgisPeopleServiceProvider)
                .choose(userUuid, caverId);
          } on Exception catch (e) {
            SnackBarService.showError(e);
          }
          ref.invalidate(silexgisCaverChoiceProvider(userUuid));
        },
      ),
    );
  }
}
