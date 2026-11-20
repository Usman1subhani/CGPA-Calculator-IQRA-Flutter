import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

class ShareResultButton extends StatelessWidget {
  final String resultType;
  final double value;
  final int creditHours;
  final List<String> details;

  const ShareResultButton({
    super.key,
    required this.resultType,
    required this.value,
    required this.creditHours,
    this.details = const [],
  });

  Future<void> _share() async {
    final lines = [
      '$resultType: ${value.toStringAsFixed(2)}',
      'Credit hours: $creditHours',
      ...details.where((detail) => detail.trim().isNotEmpty),
    ];
    await SharePlus.instance.share(ShareParams(text: lines.join('\n')));
  }

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: _share,
      icon: const Icon(Icons.share_rounded),
      label: const Text('Share result'),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(50),
        shape: const StadiumBorder(),
      ),
    );
  }
}
