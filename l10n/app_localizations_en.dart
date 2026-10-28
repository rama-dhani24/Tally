// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Tally';

  @override
  String get home => 'Home';

  @override
  String get debts => 'Debts';

  @override
  String get plan => 'Plan';

  @override
  String get settings => 'Settings';

  @override
  String get youOwe => 'You owe';

  @override
  String get owedToYou => 'You are owed';

  @override
  String get addDebt => 'Add debt';

  @override
  String get nameRequired => 'Enter a person\'s name';

  @override
  String get amountRequired => 'Enter an amount greater than zero';

  @override
  String get paymentExceedsBalance => 'Payment cannot exceed the balance';

  @override
  String get open => 'Open';

  @override
  String get partlyPaid => 'Partly paid';

  @override
  String get overdue => 'Overdue';

  @override
  String get paid => 'Paid';

  @override
  String get dueSoon => 'Due soon';

  @override
  String get recordPayment => 'Record payment';

  @override
  String get paymentHistory => 'Payment history';

  @override
  String get noDebts => 'No debts yet';

  @override
  String get language => 'Language';

  @override
  String get appearance => 'Appearance';

  @override
  String get currency => 'Currency symbol';

  @override
  String get reminders => 'Gentle reminders';

  @override
  String get privacy => 'Privacy';

  @override
  String get exportData => 'Export data';

  @override
  String get firstPayment => 'First payment recorded';

  @override
  String get debtCleared => 'Debt cleared';

  @override
  String get welcomeBack => 'Welcome back';

  @override
  String get debtSnapshot => 'Your debt snapshot';

  @override
  String get netBalance => 'Net balance';

  @override
  String get changeProfilePhoto => 'Choose a profile photo';

  @override
  String get photoPrivacy => 'Your photo stays on this device.';

  @override
  String get debtsSubtitle => 'A clear view of what comes in and goes out.';

  @override
  String get planSubtitle => 'Small, steady steps toward being debt free.';

  @override
  String get settingsSubtitle => 'Make Tally feel like yours.';
}
