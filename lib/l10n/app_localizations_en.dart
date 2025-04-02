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

  @override
  String get number => 'Number';

  @override
  String get age => 'Age';

  @override
  String get collection => 'Collection';

  @override
  String get save => 'Save';

  @override
  String get clear_all => 'Clear All';

  @override
  String get saved_data => 'Saved Data';

  @override
  String get invoicePreview => 'Invoice Preview';  

  @override
  String get reports => 'Reports';

  @override
  String get data_for => 'Data for'; 

  @override
  String get entry => 'Entry'; 

  @override
  String get no_data_for_date => 'No data for date'; 

  @override
  String get select_date => 'Select Date'; 

  @override
  String get today => 'Today'; 

  @override
  String get yesterday => 'Yesterday'; 

  @override
  String get this_week => 'This Week'; 

  @override
  String get this_month => 'This Month'; 

  @override
  String get recent_collection => 'Recent Collection'; 

  @override
  String get total_collection => 'Total Collection';

  @override
  String get previous_collection => 'Previous Collection';

  @override
  String get total_clients => 'Total Clients';

  @override
  String get total_payments => 'Total Payments';

  @override
String get no_data_to_export => 'No data to export';

@override
String get csv_downloaded => 'CSV downloaded via browser';

@override
String get storage_permission_required => 'Storage permission is required to export CSV';

@override
String get downloads_directory_unavailable => 'Downloads directory not available';

@override
String get report_exported_to => 'Report exported to';

@override
String get failed_to_export_csv => 'Failed to export CSV';

@override
String get no_data_available => 'No data available';
}