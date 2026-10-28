import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

SharedPreferences? _preferences;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  _preferences = await SharedPreferences.getInstance();
  runApp(const ProviderScope(child: TallyApp()));
}

enum Direction { iOwe, owedToMe }

enum DebtStatus { open, partlyPaid, overdue, paid }

class Payment {
  Payment(this.amount, this.date, {this.note = ''});
  final int amount;
  final DateTime date;
  final String note;
}

class Debt {
  Debt({
    required this.name,
    required this.direction,
    required this.total,
    this.dueDate,
    this.note = '',
    List<Payment>? payments,
  }) : payments = payments ?? [];
  final String name;
  final Direction direction;
  final int total;
  final DateTime? dueDate;
  final String note;
  final List<Payment> payments;
  int get paid => payments.fold(0, (sum, payment) => sum + payment.amount);
  int get balance => total - paid;
  DebtStatus get status {
    if (balance == 0) return DebtStatus.paid;
    if (dueDate != null &&
        DateUtils.dateOnly(
          dueDate!,
        ).isBefore(DateUtils.dateOnly(DateTime.now())))
      return DebtStatus.overdue;
    if (paid > 0) return DebtStatus.partlyPaid;
    return DebtStatus.open;
  }

  void record(int amount) {
    if (amount <= 0 || amount > balance)
      throw ArgumentError('Payment must be within the balance.');
    payments.add(Payment(amount, DateTime.now()));
  }
}

class DebtBook extends ChangeNotifier {
  DebtBook() {
    if (!const bool.fromEnvironment('dart.vm.product')) {
      debts.addAll([
        Debt(
          name: 'Juma',
          direction: Direction.iOwe,
          total: 180000,
          dueDate: DateTime.now().add(const Duration(days: 5)),
          payments: [
            Payment(60000, DateTime.now().subtract(const Duration(days: 9))),
          ],
        ),
        Debt(
          name: 'Asha',
          direction: Direction.owedToMe,
          total: 95000,
          dueDate: DateTime.now().subtract(const Duration(days: 2)),
        ),
        Debt(
          name: 'Mama',
          direction: Direction.iOwe,
          total: 70000,
          payments: [
            Payment(70000, DateTime.now().subtract(const Duration(days: 3))),
          ],
        ),
        Debt(
          name: 'Neema',
          direction: Direction.owedToMe,
          total: 42000,
          dueDate: DateTime.now().add(const Duration(days: 3)),
        ),
      ]);
    }
  }
  final List<Debt> debts = [];
  void add(Debt debt) {
    debts.insert(0, debt);
    notifyListeners();
  }

  void update() => notifyListeners();
}

final debtBookProvider = ChangeNotifierProvider((ref) => DebtBook());
final localeProvider = StateProvider<Locale>(
  (ref) => Locale(
    _preferences?.getString('language') ??
        (WidgetsBinding.instance.platformDispatcher.locale.languageCode == 'sw'
            ? 'sw'
            : 'en'),
  ),
);
final themeProvider = StateProvider<ThemeMode>((ref) {
  final stored = _preferences?.getString('theme');
  return ThemeMode.values.firstWhere(
    (mode) => mode.name == stored,
    orElse: () => ThemeMode.system,
  );
});
final profileImageProvider = StateProvider<String?>(
  (ref) => _preferences?.getString('profile_photo'),
);

void setLocale(WidgetRef ref, Locale locale) {
  ref.read(localeProvider.notifier).state = locale;
  _preferences?.setString('language', locale.languageCode);
}

void setTheme(WidgetRef ref, ThemeMode mode) {
  ref.read(themeProvider.notifier).state = mode;
  _preferences?.setString('theme', mode.name);
}

class TallyApp extends ConsumerWidget {
  const TallyApp({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = GoRouter(
      routes: [GoRoute(path: '/', builder: (_, __) => const MainShell())],
    );
    return MaterialApp.router(
      title: 'Tally',
      debugShowCheckedModeBanner: false,
      routerConfig: router,
      locale: ref.watch(localeProvider),
      supportedLocales: const [Locale('en'), Locale('sw')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      themeMode: ref.watch(themeProvider),
      theme: _theme(Brightness.light),
      darkTheme: _theme(Brightness.dark),
    );
  }

  ThemeData _theme(Brightness brightness) {
    const teal = Color(0xff0f766e);
    final dark = brightness == Brightness.dark;
    final scheme = ColorScheme.fromSeed(
      seedColor: teal,
      brightness: brightness,
      surface: dark ? const Color(0xff121b19) : const Color(0xfff5f7f4),
    ).copyWith(primary: teal, secondary: const Color(0xffd59a4c));
    return ThemeData(
      colorScheme: scheme,
      useMaterial3: true,
      fontFamily: 'Poppins',
      scaffoldBackgroundColor: scheme.surface,
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        centerTitle: false,
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          fontSize: 32,
          height: 1.15,
          fontWeight: FontWeight.w700,
          letterSpacing: -1.1,
        ),
        headlineMedium: TextStyle(
          fontSize: 27,
          height: 1.2,
          fontWeight: FontWeight.w700,
          letterSpacing: -.7,
        ),
        headlineSmall: TextStyle(
          fontSize: 23,
          height: 1.25,
          fontWeight: FontWeight.w700,
          letterSpacing: -.45,
        ),
        titleLarge: TextStyle(
          fontSize: 19,
          height: 1.35,
          fontWeight: FontWeight.w600,
          letterSpacing: -.25,
        ),
        titleMedium: TextStyle(
          fontSize: 15,
          height: 1.4,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: TextStyle(fontSize: 15, height: 1.5),
        bodyMedium: TextStyle(fontSize: 13, height: 1.5),
        bodySmall: TextStyle(fontSize: 11, height: 1.45),
      ),
      cardTheme: CardThemeData(
        color: dark ? const Color(0xff1b2724) : Colors.white,
        elevation: dark ? 0 : 1,
        shadowColor: const Color(0xff173c35).withValues(alpha: .06),
        margin: const EdgeInsets.symmetric(vertical: 6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: dark ? const Color(0xff202d29) : const Color(0xfff1f4f1),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 15,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: teal, width: 1.5),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 76,
        backgroundColor: dark ? const Color(0xff17211f) : Colors.white,
        indicatorColor:
            dark ? const Color(0xff24423c) : const Color(0xffdff0e9),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            fontFamily: 'Poppins',
            fontSize: 10,
            fontWeight:
                states.contains(WidgetState.selected)
                    ? FontWeight.w600
                    : FontWeight.w400,
          ),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: teal,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        elevation: 3,
      ),
    );
  }
}

class Words {
  Words(this.locale);
  final Locale locale;
  bool get sw => locale.languageCode == 'sw';
  String get home => sw ? 'Nyumbani' : 'Home';
  String get debts => sw ? 'Madeni' : 'Debts';
  String get plan => sw ? 'Mpango' : 'Plan';
  String get settings => sw ? 'Mipangilio' : 'Settings';
  String get owe => sw ? 'Unadaiwa' : 'You owe';
  String get owed => sw ? 'Unadai' : 'You are owed';
  String get add => sw ? 'Ongeza deni' : 'Add debt';
  String get person => sw ? 'Jina la mtu' : 'Person name';
  String get amount => sw ? 'Kiasi (TSh)' : 'Amount (TSh)';
  String get due => sw ? 'Tarehe ya mwisho' : 'Due date';
  String get noDue => sw ? 'Hakuna tarehe' : 'No due date';
  String get balance => sw ? 'Salio' : 'Balance';
  String get save => sw ? 'Hifadhi deni' : 'Save debt';
  String get payment => sw ? 'Rekodi malipo' : 'Record payment';
  String get search => sw ? 'Tafuta jina' : 'Search by name';
  String get all => sw ? 'Yote' : 'All';
  String get open => sw ? 'Wazi' : 'Open';
  String get partial => sw ? 'Imelipwa sehemu' : 'Partly paid';
  String get overdue => sw ? 'Yamechelewa' : 'Overdue';
  String get paid => sw ? 'Imelipwa' : 'Paid';
  String get progress => sw ? 'Maendeleo ya kulipa' : 'Debt-free progress';
  String get encouragement =>
      sw
          ? 'Kila hatua ndogo inakupeleka mbele.'
          : 'Every small step moves you forward.';
  String get dueSoon => sw ? 'Yanayokaribia' : 'Due soon';
  String get totalPaid => sw ? 'Jumla iliyolipwa' : 'Total paid';
  String get greeting => sw ? 'KARIBU TENA' : 'WELCOME BACK';
  String get appearance => sw ? 'Muonekano' : 'Appearance';
  String get system => sw ? 'Mfumo' : 'System';
  String get light => sw ? 'Mwangaza' : 'Light';
  String get dark => sw ? 'Giza' : 'Dark';
  String get profilePhoto => sw ? 'Picha ya wasifu' : 'Profile photo';
  String get changePhoto => sw ? 'Chagua picha' : 'Choose a photo';
  String get privatePhoto =>
      sw
          ? 'Picha yako inabaki kwenye kifaa hiki.'
          : 'Your photo stays on this device.';
  String get netBalance => sw ? 'Tofauti ya salio' : 'Net balance';
  String get snapshot => sw ? 'Muhtasari wa madeni' : 'Your debt snapshot';
  String get photoError =>
      sw ? 'Picha haikuweza kufunguliwa.' : 'Could not open the photo picker.';
  String get debtsSubtitle =>
      sw
          ? 'Yapange madeni yako kwa utulivu.'
          : 'A clear view of what comes in and goes out.';
  String get planSubtitle =>
      sw
          ? 'Lipa kwa hatua zinazowezekana.'
          : 'Small, steady steps toward being debt free.';
  String get settingsSubtitle =>
      sw ? 'Badilisha Tally ikufae.' : 'Make Tally feel like yours.';
  String status(DebtStatus s) => switch (s) {
    DebtStatus.open => open,
    DebtStatus.partlyPaid => partial,
    DebtStatus.overdue => overdue,
    DebtStatus.paid => paid,
  };
}

String money(int amount) =>
    'TSh ${amount.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => ',')}';

class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key});
  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  int selected = 0;
  @override
  Widget build(BuildContext context) {
    final w = Words(ref.watch(localeProvider));
    final pages = [
      HomePage(onDebts: () => setState(() => selected = 1)),
      const DebtsPage(),
      const PlanPage(),
      const SettingsPage(),
    ];
    return Scaffold(
      body: IndexedStack(index: selected, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: selected,
        onDestinationSelected: (i) => setState(() => selected = i),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.home_outlined),
            selectedIcon: const Icon(Icons.home_rounded),
            label: w.home,
          ),
          NavigationDestination(
            icon: const Icon(Icons.receipt_long_outlined),
            selectedIcon: const Icon(Icons.receipt_long_rounded),
            label: w.debts,
          ),
          NavigationDestination(
            icon: const Icon(Icons.auto_graph_outlined),
            selectedIcon: const Icon(Icons.auto_graph_rounded),
            label: w.plan,
          ),
          NavigationDestination(
            icon: const Icon(Icons.tune),
            label: w.settings,
          ),
        ],
      ),
      floatingActionButton:
          selected < 2
              ? FloatingActionButton.extended(
                onPressed: () => showAddDebt(context, ref),
                icon: const Icon(Icons.add),
                label: Text(w.add),
              )
              : null,
    );
  }
}

class HomeHeader extends ConsumerWidget {
  const HomeHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final w = Words(ref.watch(localeProvider));
    final photoPath = ref.watch(profileImageProvider);
    final mode = ref.watch(themeProvider);
    final dark =
        mode == ThemeMode.dark ||
        (mode == ThemeMode.system &&
            MediaQuery.platformBrightnessOf(context) == Brightness.dark);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Semantics(
            button: true,
            label: w.changePhoto,
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () => _showProfileOptions(context, ref),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [Color(0xffdff1e9), Color(0xffb8ddd0)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.surface,
                        width: 3,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xff0f766e).withValues(alpha: .16),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child:
                        photoPath == null
                            ? const Icon(
                              Icons.person_rounded,
                              size: 28,
                              color: Color(0xff0f766e),
                            )
                            : Image.file(
                              File(photoPath),
                              fit: BoxFit.cover,
                              errorBuilder:
                                  (_, __, ___) => const Icon(
                                    Icons.person_rounded,
                                    size: 28,
                                    color: Color(0xff0f766e),
                                  ),
                            ),
                  ),
                  Positioned(
                    right: -1,
                    bottom: -1,
                    child: Container(
                      width: 17,
                      height: 17,
                      decoration: BoxDecoration(
                        color: const Color(0xff0f766e),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Theme.of(context).colorScheme.surface,
                          width: 2,
                        ),
                      ),
                      child: const Icon(
                        Icons.add,
                        size: 11,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  w.greeting,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.15,
                  ),
                ),
                Text(
                  'Tally',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: -.55,
                  ),
                ),
              ],
            ),
          ),
          _LocalePill(locale: ref.watch(localeProvider)),
          const SizedBox(width: 3),
          PopupMenuButton<ThemeMode>(
            tooltip: w.appearance,
            initialValue: mode,
            onSelected: (value) => setTheme(ref, value),
            icon: Icon(
              dark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
              color: Theme.of(context).colorScheme.primary,
              size: 21,
            ),
            itemBuilder:
                (_) => [
                  PopupMenuItem(
                    value: ThemeMode.system,
                    child: _ThemeMenuItem(
                      icon: Icons.brightness_auto_rounded,
                      label: w.system,
                      selected: mode == ThemeMode.system,
                    ),
                  ),
                  PopupMenuItem(
                    value: ThemeMode.light,
                    child: _ThemeMenuItem(
                      icon: Icons.light_mode_rounded,
                      label: w.light,
                      selected: mode == ThemeMode.light,
                    ),
                  ),
                  PopupMenuItem(
                    value: ThemeMode.dark,
                    child: _ThemeMenuItem(
                      icon: Icons.dark_mode_rounded,
                      label: w.dark,
                      selected: mode == ThemeMode.dark,
                    ),
                  ),
                ],
          ),
        ],
      ),
    );
  }
}

class _ThemeMenuItem extends StatelessWidget {
  const _ThemeMenuItem({
    required this.icon,
    required this.label,
    required this.selected,
  });
  final IconData icon;
  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, size: 19),
      const SizedBox(width: 10),
      Expanded(child: Text(label)),
      if (selected) const Icon(Icons.check_rounded, size: 17),
    ],
  );
}

class _LocalePill extends ConsumerWidget {
  const _LocalePill({required this.locale});
  final Locale locale;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest.withValues(alpha: .72),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _LocaleOption(code: 'EN', locale: locale),
          _LocaleOption(code: 'SW', locale: locale),
        ],
      ),
    );
  }
}

class _LocaleOption extends ConsumerWidget {
  const _LocaleOption({required this.code, required this.locale});
  final String code;
  final Locale locale;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = locale.languageCode == code.toLowerCase();
    return Semantics(
      button: true,
      selected: selected,
      label: code == 'EN' ? 'English' : 'Kiswahili',
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => setLocale(ref, Locale(code.toLowerCase())),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
          decoration: BoxDecoration(
            color:
                selected
                    ? Theme.of(context).colorScheme.surface
                    : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow:
                selected
                    ? [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: .07),
                        blurRadius: 5,
                        offset: const Offset(0, 2),
                      ),
                    ]
                    : null,
          ),
          child: Text(
            code,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color:
                  selected
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}

Future<void> _pickProfilePhoto(BuildContext context, WidgetRef ref) async {
  final w = Words(ref.read(localeProvider));
  try {
    final image = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 88,
      maxWidth: 640,
      maxHeight: 640,
    );
    if (image != null) {
      ref.read(profileImageProvider.notifier).state = image.path;
      await _preferences?.setString('profile_photo', image.path);
    }
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(w.photoError)));
    }
  }
}

Future<void> _showProfileOptions(BuildContext context, WidgetRef ref) async {
  final w = Words(ref.read(localeProvider));
  await showModalBottomSheet<void>(
    context: context,
    useSafeArea: true,
    showDragHandle: true,
    builder:
        (sheetContext) => Consumer(
          builder: (context, ref, _) {
            final path = ref.watch(profileImageProvider);
            return Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: 42,
                    backgroundColor: const Color(0xffdff1e9),
                    child:
                        path == null
                            ? const Icon(
                              Icons.person_rounded,
                              size: 42,
                              color: Color(0xff0f766e),
                            )
                            : ClipOval(
                              child: Image.file(
                                File(path),
                                width: 84,
                                height: 84,
                                fit: BoxFit.cover,
                                errorBuilder:
                                    (_, __, ___) => const Icon(
                                      Icons.person_rounded,
                                      size: 42,
                                      color: Color(0xff0f766e),
                                    ),
                              ),
                            ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    w.profilePhoto,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 5),
                  Text(
                    w.privatePhoto,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () async {
                        Navigator.pop(sheetContext);
                        await _pickProfilePhoto(context, ref);
                      },
                      icon: const Icon(Icons.photo_library_outlined),
                      label: Text(w.changePhoto),
                    ),
                  ),
                  if (path != null)
                    TextButton.icon(
                      onPressed: () async {
                        ref.read(profileImageProvider.notifier).state = null;
                        await _preferences?.remove('profile_photo');
                        if (sheetContext.mounted) Navigator.pop(sheetContext);
                      },
                      icon: const Icon(Icons.delete_outline_rounded),
                      label: Text(w.sw ? 'Ondoa picha' : 'Remove photo'),
                    ),
                ],
              ),
            );
          },
        ),
  );
}

class HomePage extends ConsumerWidget {
  const HomePage({super.key, required this.onDebts});
  final VoidCallback onDebts;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final w = Words(ref.watch(localeProvider));
    final debts =
        ref.watch(debtBookProvider).debts.where((d) => d.balance > 0).toList();
    final owe = debts
        .where((d) => d.direction == Direction.iOwe)
        .fold(0, (s, d) => s + d.balance);
    final owed = debts
        .where((d) => d.direction == Direction.owedToMe)
        .fold(0, (s, d) => s + d.balance);
    final personal =
        ref
            .watch(debtBookProvider)
            .debts
            .where((d) => d.direction == Direction.iOwe)
            .toList();
    final total = personal.fold(0, (s, d) => s + d.total);
    final paid = personal.fold(0, (s, d) => s + d.paid);
    final late = debts.where((d) => d.status == DebtStatus.overdue).toList();
    final soon =
        debts
            .where(
              (d) =>
                  d.dueDate != null &&
                  !d.dueDate!.isBefore(DateTime.now()) &&
                  d.dueDate!.difference(DateTime.now()).inDays <= 7,
            )
            .toList();
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 110),
        children: [
          const HomeHeader(),
          const SizedBox(height: 10),
          _BalancePanel(
            owe: owe,
            owed: owed,
            label: w.netBalance,
            net: owed - owe,
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          w.progress,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                      Text('${total == 0 ? 0 : paid * 100 ~/ total}%'),
                    ],
                  ),
                  const SizedBox(height: 10),
                  LinearProgressIndicator(
                    value: total == 0 ? 0 : paid / total,
                    minHeight: 8,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  const SizedBox(height: 8),
                  Text(w.encouragement),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          if (late.isNotEmpty) ...[
            _Heading(w.overdue, late.length),
            ...late.map((d) => DebtCard(debt: d)),
          ],
          _Heading(w.dueSoon, soon.length),
          if (soon.isEmpty)
            Text(
              w.sw
                  ? 'Hakuna malipo yanayokaribia.'
                  : 'Nothing due in the next 7 days.',
            )
          else
            ...soon.map((d) => DebtCard(debt: d)),
          const SizedBox(height: 14),
          Text('${w.totalPaid}: ${money(paid)}'),
        ],
      ),
    );
  }
}

class _BalancePanel extends ConsumerWidget {
  const _BalancePanel({
    required this.owe,
    required this.owed,
    required this.net,
    required this.label,
  });

  final int owe;
  final int owed;
  final int net;
  final String label;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final w = Words(ref.watch(localeProvider));
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xff155e58), Color(0xff0f766e), Color(0xff268578)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: const Color(0xff0f766e).withValues(alpha: .2),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 35,
                height: 35,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .13),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.account_balance_wallet_outlined,
                  size: 19,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  w.snapshot,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Icon(
                Icons.more_horiz_rounded,
                color: Colors.white.withValues(alpha: .72),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _HeroAmount(
                  label: w.owe,
                  amount: owe,
                  icon: Icons.south_west_rounded,
                ),
              ),
              Container(
                width: 1,
                height: 50,
                color: Colors.white.withValues(alpha: .19),
                margin: const EdgeInsets.symmetric(horizontal: 14),
              ),
              Expanded(
                child: _HeroAmount(
                  label: w.owed,
                  amount: owed,
                  icon: Icons.north_east_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .12),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withValues(alpha: .1)),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.swap_horiz_rounded,
                  size: 18,
                  color: Colors.white.withValues(alpha: .8),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: .8),
                      fontSize: 11,
                    ),
                  ),
                ),
                Text(
                  money(net),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
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

class _HeroAmount extends StatelessWidget {
  const _HeroAmount({
    required this.label,
    required this.amount,
    required this.icon,
  });
  final String label;
  final int amount;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Icon(icon, size: 14, color: Colors.white.withValues(alpha: .76)),
          const SizedBox(width: 5),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white.withValues(alpha: .78),
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
      const SizedBox(height: 7),
      FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: Text(
          money(amount),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 19,
            fontWeight: FontWeight.w700,
            letterSpacing: -.3,
          ),
        ),
      ),
    ],
  );
}

class _Amount extends StatelessWidget {
  const _Amount({
    required this.label,
    required this.amount,
    required this.color,
  });
  final String label;
  final int amount;
  final Color color;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label),
      const SizedBox(height: 6),
      FittedBox(
        child: Text(
          money(amount),
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
      ),
    ],
  );
}

class _Heading extends StatelessWidget {
  const _Heading(this.label, this.count);
  final String label;
  final int count;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Text(
      '$label  |  $count',
      style: const TextStyle(fontWeight: FontWeight.w700),
    ),
  );
}

class _PageHeading extends StatelessWidget {
  const _PageHeading({required this.title, required this.subtitle});
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(4, 8, 4, 18),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    ),
  );
}

class DebtsPage extends ConsumerStatefulWidget {
  const DebtsPage({super.key});
  @override
  ConsumerState<DebtsPage> createState() => _DebtsPageState();
}

class _DebtsPageState extends ConsumerState<DebtsPage> {
  Direction direction = Direction.iOwe;
  String query = '';
  String filter = 'All';
  @override
  Widget build(BuildContext context) {
    final w = Words(ref.watch(localeProvider));
    final list =
        ref
            .watch(debtBookProvider)
            .debts
            .where(
              (d) =>
                  d.direction == direction &&
                  d.name.toLowerCase().contains(query.toLowerCase()),
            )
            .toList();
    final matches =
        filter == 'All' || filter == w.all
            ? list
            : list.where((d) => w.status(d.status) == filter).toList();
    final filters = [w.all, w.open, w.partial, w.overdue, w.paid];
    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
            child: _PageHeading(title: w.debts, subtitle: w.debtsSubtitle),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SegmentedButton<Direction>(
              segments: [
                ButtonSegment(
                  value: Direction.iOwe,
                  label: Text(w.sw ? 'Ninadaiwa' : 'I owe'),
                ),
                ButtonSegment(
                  value: Direction.owedToMe,
                  label: Text(w.sw ? 'Ninadai' : 'Owed to me'),
                ),
              ],
              selected: {direction},
              onSelectionChanged: (s) => setState(() => direction = s.first),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              onChanged: (v) => setState(() => query = v),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: w.search,
              ),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children:
                  filters
                      .map(
                        (f) => Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: ChoiceChip(
                            label: Text(f),
                            selected: filter == f,
                            onSelected: (_) => setState(() => filter = f),
                          ),
                        ),
                      )
                      .toList(),
            ),
          ),
          Expanded(
            child:
                matches.isEmpty
                    ? Center(
                      child: Text(w.sw ? 'Hakuna madeni bado' : 'No debts yet'),
                    )
                    : ListView(
                      padding: const EdgeInsets.all(14),
                      children: matches.map((d) => DebtCard(debt: d)).toList(),
                    ),
          ),
        ],
      ),
    );
  }
}

class DebtCard extends ConsumerWidget {
  const DebtCard({super.key, required this.debt});
  final Debt debt;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final w = Words(ref.watch(localeProvider));
    final color =
        debt.status == DebtStatus.overdue
            ? const Color(0xffba625a)
            : debt.direction == Direction.iOwe
            ? const Color(0xffa8633c)
            : const Color(0xff0f766e);
    return Card(
      child: InkWell(
        onTap: () => showDebtDetails(context, ref, debt),
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Row(
            children: [
              CircleAvatar(
                radius: 23,
                backgroundColor: color.withValues(alpha: .12),
                child: Text(
                  debt.name[0].toUpperCase(),
                  style: TextStyle(color: color, fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            debt.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: .11),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            w.status(debt.status),
                            style: TextStyle(
                              color: color,
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${w.balance}: ${money(debt.balance)}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 9),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: debt.total == 0 ? 0 : debt.paid / debt.total,
                        minHeight: 5,
                        color: color,
                        backgroundColor: color.withValues(alpha: .12),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      debt.dueDate == null
                          ? w.noDue
                          : '${w.due}: ${debt.dueDate!.day}/${debt.dueDate!.month}/${debt.dueDate!.year}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<void> showAddDebt(BuildContext context, WidgetRef ref) async {
  final w = Words(ref.read(localeProvider));
  final name = TextEditingController();
  final amount = TextEditingController();
  Direction direction = Direction.iOwe;
  DateTime? due;
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder:
        (ctx) => StatefulBuilder(
          builder:
              (ctx, refresh) => Padding(
                padding: EdgeInsets.fromLTRB(
                  20,
                  20,
                  20,
                  MediaQuery.of(ctx).viewInsets.bottom + 20,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(w.add, style: Theme.of(ctx).textTheme.titleLarge),
                    SegmentedButton<Direction>(
                      segments: [
                        ButtonSegment(
                          value: Direction.iOwe,
                          label: Text(w.sw ? 'Ninadaiwa' : 'I owe'),
                        ),
                        ButtonSegment(
                          value: Direction.owedToMe,
                          label: Text(w.sw ? 'Ninadai' : 'Owed to me'),
                        ),
                      ],
                      selected: {direction},
                      onSelectionChanged:
                          (s) => refresh(() => direction = s.first),
                    ),
                    TextField(
                      controller: name,
                      decoration: InputDecoration(labelText: w.person),
                    ),
                    TextField(
                      controller: amount,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(labelText: w.amount),
                    ),
                    TextButton(
                      onPressed: () async {
                        due = await showDatePicker(
                          context: ctx,
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(
                            const Duration(days: 3650),
                          ),
                          initialDate: DateTime.now().add(
                            const Duration(days: 7),
                          ),
                        );
                        refresh(() {});
                      },
                      child: Text(
                        due == null
                            ? w.due
                            : '${due!.day}/${due!.month}/${due!.year}',
                      ),
                    ),
                    FilledButton(
                      onPressed: () {
                        final total = int.tryParse(amount.text);
                        if (name.text.trim().isEmpty ||
                            total == null ||
                            total <= 0) {
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            SnackBar(
                              content: Text(
                                w.sw
                                    ? 'Weka jina na kiasi sahihi.'
                                    : 'Enter a name and valid amount.',
                              ),
                            ),
                          );
                          return;
                        }
                        ref
                            .read(debtBookProvider)
                            .add(
                              Debt(
                                name: name.text.trim(),
                                direction: direction,
                                total: total,
                                dueDate: due,
                              ),
                            );
                        Navigator.pop(ctx);
                      },
                      child: Text(w.save),
                    ),
                  ],
                ),
              ),
        ),
  );
}

Future<void> showDebtDetails(
  BuildContext context,
  WidgetRef ref,
  Debt debt,
) async {
  final w = Words(ref.read(localeProvider));
  await showModalBottomSheet<void>(
    context: context,
    useSafeArea: true,
    builder:
        (ctx) => StatefulBuilder(
          builder:
              (ctx, refresh) => Padding(
                padding: const EdgeInsets.all(22),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(debt.name, style: Theme.of(ctx).textTheme.titleLarge),
                    Text(w.status(debt.status)),
                    Text(
                      money(debt.balance),
                      style: Theme.of(ctx).textTheme.headlineMedium,
                    ),
                    Text('${w.totalPaid}: ${money(debt.paid)}'),
                    FilledButton(
                      onPressed:
                          debt.balance == 0
                              ? null
                              : () async {
                                final c = TextEditingController(
                                  text: '${debt.balance}',
                                );
                                final value = await showDialog<int>(
                                  context: ctx,
                                  builder:
                                      (d) => AlertDialog(
                                        title: Text(w.payment),
                                        content: TextField(
                                          controller: c,
                                          keyboardType: TextInputType.number,
                                          decoration: InputDecoration(
                                            labelText: w.amount,
                                          ),
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.pop(d),
                                            child: Text(
                                              w.sw ? 'Ghairi' : 'Cancel',
                                            ),
                                          ),
                                          FilledButton(
                                            onPressed:
                                                () => Navigator.pop(
                                                  d,
                                                  int.tryParse(c.text),
                                                ),
                                            child: Text(w.payment),
                                          ),
                                        ],
                                      ),
                                );
                                if (value != null) {
                                  try {
                                    debt.record(value);
                                    ref.read(debtBookProvider).update();
                                    refresh(() {});
                                  } catch (_) {
                                    ScaffoldMessenger.of(ctx).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          w.sw
                                              ? 'Kiasi kinazidi salio.'
                                              : 'Payment exceeds the balance.',
                                        ),
                                      ),
                                    );
                                  }
                                }
                              },
                      child: Text(w.payment),
                    ),
                    ...debt.payments.map(
                      (p) => ListTile(
                        title: Text(money(p.amount)),
                        subtitle: Text(
                          '${p.date.day}/${p.date.month}/${p.date.year}',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
        ),
  );
}

class PlanPage extends ConsumerStatefulWidget {
  const PlanPage({super.key});
  @override
  ConsumerState<PlanPage> createState() => _PlanPageState();
}

class _PlanPageState extends ConsumerState<PlanPage> {
  final amount = TextEditingController(text: '20000');
  @override
  Widget build(BuildContext context) {
    final w = Words(ref.watch(localeProvider));
    final debts =
        ref
            .watch(debtBookProvider)
            .debts
            .where((d) => d.direction == Direction.iOwe && d.balance > 0)
            .toList();
    final balance = debts.fold(0, (s, d) => s + d.balance);
    final weekly = int.tryParse(amount.text) ?? 0;
    final days = weekly <= 0 ? 0 : (balance / weekly * 7).ceil();
    final date = DateTime.now().add(Duration(days: days));
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _PageHeading(title: w.plan, subtitle: w.planSubtitle),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    money(balance),
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  TextField(
                    controller: amount,
                    onChanged: (_) => setState(() {}),
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: w.sw ? 'Kiasi kwa wiki' : 'Amount per week',
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    weekly > 0
                        ? '${w.sw ? 'Kwa kulipa' : 'Pay'} ${money(weekly)} ${w.sw ? 'kwa wiki, utakamilisha karibu' : 'per week to finish around'} ${date.day}/${date.month}/${date.year}.'
                        : (w.sw
                            ? 'Weka kiasi cha wiki.'
                            : 'Enter a weekly amount.'),
                  ),
                  const SizedBox(height: 16),
                  ...debts.map(
                    (d) => ListTile(
                      title: Text(d.name),
                      trailing: Text(money(d.balance)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final w = Words(ref.watch(localeProvider));
    final locale = ref.watch(localeProvider);
    final theme = ref.watch(themeProvider);
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _PageHeading(title: w.settings, subtitle: w.settingsSubtitle),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.language_rounded),
                  title: Text(w.sw ? 'Lugha' : 'Language'),
                  trailing: DropdownButton<Locale>(
                    value: locale,
                    items: const [
                      DropdownMenuItem(
                        value: Locale('en'),
                        child: Text('English'),
                      ),
                      DropdownMenuItem(
                        value: Locale('sw'),
                        child: Text('Kiswahili'),
                      ),
                    ],
                    onChanged: (v) {
                      if (v != null) setLocale(ref, v);
                    },
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.palette_outlined),
                  title: Text(w.appearance),
                  trailing: DropdownButton<ThemeMode>(
                    value: theme,
                    items: [
                      DropdownMenuItem(
                        value: ThemeMode.system,
                        child: Text(w.system),
                      ),
                      DropdownMenuItem(
                        value: ThemeMode.light,
                        child: Text(w.light),
                      ),
                      DropdownMenuItem(
                        value: ThemeMode.dark,
                        child: Text(w.dark),
                      ),
                    ],
                    onChanged: (v) {
                      if (v != null) setTheme(ref, v);
                    },
                  ),
                ),
              ],
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.lock_outline),
              title: Text(w.sw ? 'Faragha' : 'Privacy'),
              subtitle: Text(
                w.sw
                    ? 'Data yako inabaki kwenye kifaa hiki.'
                    : 'Your demo data stays in this session.',
              ),
            ),
          ),
          Center(child: Text('Tally | TSh')),
        ],
      ),
    );
  }
}
