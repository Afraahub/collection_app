// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get hello => 'Hello';
  @override
  String get welcome_message => 'Welcome to our app!';
  @override
  String get mandatory => 'Mandatory';
  @override
  String get choose_language => 'Choose Language';
  @override
  String get settings => 'Settings';
  @override
  String get name => 'Name';

  @override
  String get mobileNumber => 'Mobile Number';

  @override
  String get occupation => 'Occupation';

  @override
  String get address => 'Address';

  @override
  String get amount => 'Amount';
}