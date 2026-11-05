import 'package:flutter_test/flutter_test.dart';
import 'package:pro_image_editor/pro_image_editor.dart';
import 'package:speleoloc/screens/documents/editors/image_editor_i18n.dart';
import 'package:speleoloc/utils/build_config.dart';
import 'package:speleoloc/utils/localization.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() => LocServ.inst.load());
  tearDown(() => LocServ.inst.setLocale(BuildConfig.defaultLocale));

  test('the photo editor speaks the app language', () async {
    await LocServ.inst.setLocale('ro');
    final i18n = buildImageEditorI18n();

    expect(i18n.paintEditor.bottomNavigationBarText, 'Desen');
    expect(i18n.cropRotateEditor.bottomNavigationBarText, 'Tăiere/ Rotire');
    expect(i18n.tuneEditor.bottomNavigationBarText, 'Ajustări');
    expect(i18n.done, 'Gata');
    expect(i18n.various.closeEditorWarningTitle, isNot('Close Image Editor?'));
  });

  test('English matches the package defaults, so nothing is lost', () async {
    await LocServ.inst.setLocale('en');
    final i18n = buildImageEditorI18n();
    const defaults = I18n();

    expect(i18n.cancel, defaults.cancel);
    expect(i18n.doneLoadingMsg, defaults.doneLoadingMsg);
    expect(i18n.importStateHistoryMsg, defaults.importStateHistoryMsg);
    expect(
      i18n.various.closeEditorWarningMessage,
      defaults.various.closeEditorWarningMessage,
    );
    expect(i18n.paintEditor.dashLine, defaults.paintEditor.dashLine);
    expect(i18n.textEditor.backgroundMode, defaults.textEditor.backgroundMode);
    expect(
      i18n.cropRotateEditor.bottomNavigationBarText,
      defaults.cropRotateEditor.bottomNavigationBarText,
    );
    expect(i18n.tuneEditor.luminance, defaults.tuneEditor.luminance);
    expect(i18n.filterEditor.filters.none, defaults.filterEditor.filters.none);
    expect(
      i18n.emojiEditor.categorySmileys,
      defaults.emojiEditor.categorySmileys,
    );
    expect(
      i18n.stickerEditor.bottomNavigationBarText,
      defaults.stickerEditor.bottomNavigationBarText,
    );
  });
}
