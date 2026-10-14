// Forwards the name the generated plugin registrant expects to the one
// flutter_sound's Linux stub actually exports. See the note beside the
// plugin include in linux/CMakeLists.txt.
#ifndef RUNNER_SHIMS_FLUTTER_SOUND_PLUGIN_H_
#define RUNNER_SHIMS_FLUTTER_SOUND_PLUGIN_H_

#include <taudio/taudio_plugin.h>

static inline void flutter_sound_plugin_register_with_registrar(
    FlPluginRegistrar* registrar) {
  taudio_plugin_register_with_registrar(registrar);
}

#endif  // RUNNER_SHIMS_FLUTTER_SOUND_PLUGIN_H_
