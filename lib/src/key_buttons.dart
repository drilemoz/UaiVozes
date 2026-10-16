import 'package:flutter/material.dart';

/// Quatro ações compactas na mesma linha, inclusive em smartphones estreitos.
class KeyActionsRow extends StatelessWidget {
  const KeyActionsRow({super.key, required this.paste, required this.test,
    required this.save, required this.getKey, this.busy = false});
  final VoidCallback paste;
  final VoidCallback test;
  final VoidCallback save;
  final VoidCallback getKey;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    Widget action(IconData icon, String label, VoidCallback callback) =>
      Expanded(child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: busy ? null : callback,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 1),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, size: 23, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 4),
            Text(label, maxLines: 1, textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w600)),
          ]),
        ),
      ));
    return Row(children: [
      action(Icons.content_paste_rounded, 'Colar', paste),
      action(Icons.wifi_tethering_rounded, 'Testar', test),
      action(Icons.shield_outlined, 'Guardar', save),
      action(Icons.open_in_new_rounded, 'Obter chave', getKey),
    ]);
  }
}
