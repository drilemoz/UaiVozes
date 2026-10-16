import 'package:flutter/material.dart';

const violet = Color(0xFF8063D9);
const mint = Color(0xFF75E2D1);

ThemeData elevenTheme(Brightness brightness) {
  final dark = brightness == Brightness.dark;
  final base = ThemeData(
    brightness: brightness,
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: violet,
      brightness: brightness,
      surface: dark ? Colors.black : Colors.white,
      primary: dark ? const Color(0xFFB59AFF) : const Color(0xFF6041C1),
    ),
    scaffoldBackgroundColor: dark ? Colors.black : Colors.white,
  );
  return base.copyWith(
    appBarTheme: AppBarTheme(
      backgroundColor: dark ? Colors.black : Colors.white,
      scrolledUnderElevation: 0,
      elevation: 0,
      centerTitle: false,
    ),
    cardTheme: CardThemeData(
      color: dark ? const Color(0xFF0E0E13) : Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: dark ? const Color(0xFF292932) : const Color(0xFFE6E6E9)),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: dark ? const Color(0xFF08080C) : const Color(0xFFF9F9FB),
      indicatorColor: dark ? const Color(0xFF292139) : const Color(0xFFEDE4FF),
      labelTextStyle: WidgetStateProperty.all(const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
      height: 72,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: dark ? const Color(0xFF17171D) : const Color(0xFFF3F3F5),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(21), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(21), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(21),
        borderSide: BorderSide(color: dark ? const Color(0xFFB59AFF) : violet),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 17),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(0, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(17)),
    ),
    dividerTheme: DividerThemeData(color: dark ? const Color(0xFF282831) : const Color(0xFFE8E8EB)),
  );
}

class ElevenCard extends StatelessWidget {
  const ElevenCard({super.key, required this.child, this.padding = const EdgeInsets.all(18)});
  final Widget child;
  final EdgeInsetsGeometry padding;
  @override
  Widget build(BuildContext context) => Card(
        margin: EdgeInsets.zero,
        child: Padding(padding: padding, child: child),
      );
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key, this.action});
  final String text;
  final Widget? action;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 12, top: 13),
        child: Row(children: [
          Expanded(child: Text(text, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700))),
          if (action != null) action!,
        ]),
      );
}

void notice(BuildContext context, String message) {
  final messenger = ScaffoldMessenger.of(context);
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(SnackBar(content: Text(message)));
}

Future<bool> confirmSheet(BuildContext context,
    {required String title, required String message, String action = 'Confirmar', bool destructive = false}) async {
  return await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        backgroundColor: Theme.of(context).colorScheme.surface,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
        builder: (ctx) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 10, 24, 25),
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(destructive ? Icons.warning_amber_rounded : Icons.auto_awesome_rounded,
                  size: 34, color: destructive ? Theme.of(ctx).colorScheme.error : Theme.of(ctx).colorScheme.primary),
              const SizedBox(height: 16),
              Text(title, style: Theme.of(ctx).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Text(message, style: Theme.of(ctx).textTheme.bodyLarge),
              const SizedBox(height: 25),
              Row(children: [
                Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar'))),
                const SizedBox(width: 12),
                Expanded(child: FilledButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  style: destructive ? FilledButton.styleFrom(backgroundColor: Theme.of(ctx).colorScheme.error) : null,
                  child: Text(action),
                )),
              ]),
            ]),
          ),
        ),
      ) ?? false;
}

class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.icon, required this.title, required this.description, this.action});
  final IconData icon;
  final String title;
  final String description;
  final Widget? action;
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(25),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        CircleAvatar(radius: 34, backgroundColor: Theme.of(context).colorScheme.primaryContainer,
            child: Icon(icon, size: 32)),
        const SizedBox(height: 18),
        Text(title, textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 9),
        Text(description, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium),
        if (action != null) ...[const SizedBox(height: 15), action!],
      ]),
    ),
  );
}

const languages = <String, String>{
  'all': 'Todos idiomas',
  'pt': 'Português (Brasil)',
  'en': 'Inglês',
  'es': 'Espanhol',
  'fr': 'Francês',
  'de': 'Alemão',
  'it': 'Italiano',
  'ja': 'Japonês',
  'ko': 'Coreano',
  'hi': 'Hindi',
};
