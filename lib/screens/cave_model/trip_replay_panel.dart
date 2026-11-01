import 'dart:async';

import 'package:flutter/material.dart';
import 'package:speleoloc/utils/localization.dart';

/// Steps through a trip's points on the 3D model: a scrubber over the points
/// in time order, and play / pause. [onStep] is told which point is reached.
class TripReplayPanel extends StatefulWidget {
  const TripReplayPanel({
    super.key,
    required this.pointLabels,
    required this.onStep,
    required this.onClose,
  });

  /// One line per point, in time order (place and time).
  final List<String> pointLabels;
  final ValueChanged<int> onStep;
  final VoidCallback onClose;

  @override
  State<TripReplayPanel> createState() => _TripReplayPanelState();
}

class _TripReplayPanelState extends State<TripReplayPanel> {
  static const _stepEvery = Duration(milliseconds: 1500);
  int _at = 0;
  Timer? _timer;

  void _go(int index) {
    setState(() => _at = index);
    widget.onStep(index);
  }

  void _toggle() {
    if (_timer != null) {
      _timer!.cancel();
      setState(() => _timer = null);
      return;
    }
    if (_at >= widget.pointLabels.length - 1) _go(0);
    setState(() {
      _timer = Timer.periodic(_stepEvery, (t) {
        if (_at >= widget.pointLabels.length - 1) {
          t.cancel();
          setState(() => _timer = null);
          return;
        }
        _go(_at + 1);
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final last = widget.pointLabels.length - 1;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Material(
          elevation: 4,
          borderRadius: BorderRadius.circular(12),
          color: Theme.of(context).colorScheme.surfaceContainerHigh,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        _timer == null ? Icons.play_arrow : Icons.pause,
                      ),
                      tooltip: LocServ.inst.t(
                        _timer == null
                            ? 'model_replay_play'
                            : 'model_replay_pause',
                      ),
                      onPressed: last > 0 ? _toggle : null,
                    ),
                    Expanded(
                      child: Text(
                        widget.pointLabels[_at],
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      tooltip: LocServ.inst.t('close'),
                      onPressed: widget.onClose,
                    ),
                  ],
                ),
                if (last > 0)
                  Slider(
                    value: _at.toDouble(),
                    max: last.toDouble(),
                    divisions: last,
                    onChanged: (v) => _go(v.round()),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
