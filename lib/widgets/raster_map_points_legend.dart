import 'package:flutter/material.dart';
import 'package:speleoloc/utils/localization.dart';

class RasterMapPointsLegend extends StatelessWidget {
  const RasterMapPointsLegend({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
      ),
      child: Wrap(
        spacing: 10,
        runSpacing: 4,
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _legendItemSmall(color: Colors.blue, label: LocServ.inst.t('legend_current'), size: 9),
              const SizedBox(height: 4),
              _legendItemLayered(label: LocServ.inst.t('legend_new')),
            ],
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _legendItemOutlinedSmall(color: Colors.blue, label: LocServ.inst.t('legend_original'), size: 9),
              const SizedBox(height: 4),
              _legendItemSmall(color: Colors.red, label: LocServ.inst.t('legend_existing'), size: 9),
            ],
          ),
        ],
      ),
    );
  }

  Widget _legendItemSmall({required Color color, required String label, double size = 10}) {
    return Row(
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 11)),
      ],
    );
  }

  Widget _legendItemOutlinedSmall({required Color color, required String label, double size = 10}) {
    return Row(
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: color, width: 2)),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 11)),
      ],
    );
  }

  Widget _legendItemLayered({required String label}) {
    const double big = 12;
    const double small = 7;
    return Row(
      children: [
        SizedBox(
          width: big,
          height: big,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(width: big, height: big, decoration: BoxDecoration(color: Colors.blue, shape: BoxShape.circle)),
              Container(width: small, height: small, decoration: BoxDecoration(color: Colors.orange, shape: BoxShape.circle)),
            ],
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 11)),
      ],
    );
  }
}
