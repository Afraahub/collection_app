import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'field_model.dart';
import 'settings_screen.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import 'package:csv/csv.dart';
import 'package:universal_html/html.dart' as html;
import 'dart:typed_data'; // For handling bytes
import 'dart:ui' show kIsWeb; // Import for kIsWeb
import 'package:flutter_inappwebview/flutter_inappwebview.dart'; // For WebView
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:collectionapp/l10n/app_localizations.dart' show AppLocalizations;
import 'package:flutter/foundation.dart' as foundation;
import 'package:share_plus/share_plus.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter('hive_data');
  Hive.registerAdapter(FieldModelAdapter());
  await Hive.openBox<String>('settings');
  await Hive.openBox<List>('collection_data');
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  int _selectedIndex = 1;
  Locale _appLocale = Locale('en'); // Default Language
  
  final List<Widget> _screens = [];
  
  @override
  void initState() {
    super.initState();
    _screens.add(SettingsScreen(changeLanguage: _changeLanguage));
    _screens.add(CollectionScreen());
    _screens.add(ReportsScreen());
  }
  
  void _changeLanguage(Locale locale) {
    setState(() {
      _appLocale = locale;
    });
  }
  
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Collection App',
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      themeMode: ThemeMode.system,
      supportedLocales: const [
        Locale('en'), // English
        Locale('ta'), // Tamil
      ],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      locale: _appLocale,
      localeResolutionCallback: (locale, supportedLocales) {
        for (var supportedLocale in supportedLocales) {
          if (supportedLocale.languageCode == locale?.languageCode) {
            return supportedLocale;
          }
        }
        return supportedLocales.first; // Default to English
      },
      home: Builder(
        builder: (context) {
          // Use Builder to get the context with Localizations
          final localizations = AppLocalizations.of(context);
          
          return Scaffold(
            body: _screens[_selectedIndex],
            bottomNavigationBar: BottomNavigationBar(
              currentIndex: _selectedIndex,
              onTap: _onItemTapped,
              items: [
                BottomNavigationBarItem(
                  icon: Icon(Icons.settings), 
                  label: localizations.settings
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.list), 
                  label: localizations.collection
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.insert_chart), 
                  label: localizations.reports
                ),
              ],
            ),
          );
        }
      ),
    );
  }
}


class CollectionScreen extends StatefulWidget {
  @override
  _CollectionScreenState createState() => _CollectionScreenState();
}

class _CollectionScreenState extends State<CollectionScreen> {
  final _formKey = GlobalKey<FormState>();
  late Box<String> settingsBox;
  late Box<List> dataBox;
  List<FieldModel> fields = [];
  Map<String, TextEditingController> _controllers = {};
  List<Map<String, String>> savedData = [];

  final List<FieldModel> defaultFields = [
  FieldModel(name: 'Name', type: 'Text', isMandatory: true),
  FieldModel(name: 'Age', type: 'Number', isMandatory: true),
  FieldModel(name: 'Number', type: 'Number', isMandatory: true),
  FieldModel(name: 'Amount', type: 'Number', isMandatory: false),
  FieldModel(name: 'Address', type: 'Text', isMandatory: false),
];

String getLocalizedFieldName(BuildContext context, String fieldName) {
  final loc = AppLocalizations.of(context)!;

  switch (fieldName.toLowerCase()) {
    case 'name':
      return loc.name;
    case 'age':
      return loc.age;
    case 'number':
      return loc.number;
    case 'amount':
      return loc.amount;
    case 'address':
      return loc.address;
    default:
      return fieldName;
  }
}

  @override
  void initState() {
    super.initState();
    _loadFields();
    _loadSavedData();
  }

  Future<void> _loadFields() async {
    settingsBox = Hive.box<String>('settings');
    dataBox = Hive.box<List>('collection_data');

    String? storedFields = settingsBox.get('fields');

    if (storedFields != null && storedFields.isNotEmpty) {
      try {
        setState(() {
          fields = (jsonDecode(storedFields) as List)
              .map((e) => FieldModel.fromJson(e))
              .toList();
          print("Loaded fields: $fields"); // Debug print
        });
      } catch (e) {
        print("Error loading fields: $e"); // Debug print
        _resetToDefaultFields();
      }
    } else {
      _resetToDefaultFields();
    }

    _initializeControllers();
  }

  void _resetToDefaultFields() {
    setState(() {
      fields = defaultFields;
    });
    _saveFields();
  }

  void _saveFields() {
    settingsBox.put(
        'fields', jsonEncode(fields.map((e) => e.toJson()).toList()));
    print("Saved fields: ${settingsBox.get('fields')}"); // Debug print
  }

  void _initializeControllers() {
    for (var field in fields) {
      _controllers[field.name] = TextEditingController();
    }
  }

  void _loadSavedData() {
    dataBox = Hive.box<List>('collection_data');
    List<dynamic>? storedData = dataBox.get('data');

    if (storedData != null) {
      setState(() {
        savedData = storedData.cast<Map<String, String>>();
        print("Loaded saved data: $savedData"); // Debug print
      });
    } else {
      print("No saved data found in Hive box."); // Debug print
    }
  }

  void _clearAllFields() {
    setState(() {
      _controllers.forEach((key, controller) => controller.clear());
    });
  }

  Widget _buildField(FieldModel field) {
    if (field.type == 'Dropdown') {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6.0),
        child: DropdownButtonFormField<String>(
          value: _controllers[field.name]!.text.isNotEmpty
              ? _controllers[field.name]!.text
              : null,
          decoration: InputDecoration(
            prefixIcon: Icon(Icons.arrow_drop_down),
            labelText: '${field.name} ${field.isMandatory ? '*' : ''}',
            border: OutlineInputBorder(),
          ),
          items: field.options
              .map((option) =>
                  DropdownMenuItem(value: option, child: Text(option)))
              .toList(),
          onChanged: (value) {
            if (value != null) {
              _controllers[field.name]!.text = value;
            }
          },
          validator: (value) {
            if (field.isMandatory && (value == null || value.isEmpty)) {
              return '${field.name} is mandatory';
            }
            return null;
          },
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: TextFormField(
        controller: _controllers[field.name],
        decoration: InputDecoration(
          prefixIcon:
              Icon(field.type == 'Number' ? Icons.numbers : Icons.text_fields),
    labelText: '${getLocalizedFieldName(context, field.name)} ${field.isMandatory ? '*' : ''}',
          border: OutlineInputBorder(),
        ),
        keyboardType:
            field.type == 'Number' ? TextInputType.number : TextInputType.text,
        validator: (value) {
          if (field.isMandatory && (value == null || value.isEmpty)) {
            return '${field.name} is mandatory';
          }
          if (field.type == 'Number' &&
              !RegExp(r'^\d+$').hasMatch(value ?? '')) {
            return 'Only numbers allowed';
          }
          if (field.name.toLowerCase() == 'number' && value!.length != 10) {
            return 'Mobile number must be exactly 10 digits';
          }
          return null;
        },
      ),
    );
  }

  void _saveData() {
    if (_formKey.currentState!.validate()) {
      Map<String, String> newData = {};
      for (var field in fields) {
        newData[field.name] = _controllers[field.name]!.text;
      }
      newData['date'] =
          DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());

      setState(() {
        savedData.add(newData);
        _controllers.forEach((key, controller) => controller.clear());
      });

      dataBox.put('data', savedData);
      print("Saved data to Hive: $savedData"); // Debug print

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Data Saved Successfully')),
      );
    }
  }

  Future<void> _generateAndDownloadBill(Map<String, String> data) async {
    try {
      final pdf = pw.Document();
      final localizations = AppLocalizations.of(context)!; // Get localization
      pdf.addPage(
        pw.Page(
          build: (pw.Context context) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
              localizations.billReceipt, // Localized Bill Receipt
              style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
            ),
              pw.SizedBox(height: 20),
              pw.Text(
              '${localizations.date}: ${data['date']}', // Localized "Date"
              style: pw.TextStyle(fontSize: 16),
            ),
              pw.SizedBox(height: 20),
              pw.Table(
                border: pw.TableBorder.all(),
                children: [
                  pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(
                        localizations.field, // Localized "Field"
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(
                        localizations.value, // Localized "Value"
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),
                      ),
                    ],
                  ),
                  ...data.entries
                      .map((entry) => pw.TableRow(
                            children: [
                              pw.Padding(
                                padding: const pw.EdgeInsets.all(8),
                                child: pw.Text(entry.key),
                              ),
                              pw.Padding(
                                padding: const pw.EdgeInsets.all(8),
                                child: pw.Text(entry.value),
                              ),
                            ],
                          ))
                      .toList(),
                ],
              ),
            ],
          ),
        ),
      );

      final pdfBytes = await pdf.save();

      if (kIsWeb) {
        final blob = html.Blob([pdfBytes], 'application/pdf');
        final url = html.Url.createObjectUrlFromBlob(blob);
        final anchor = html.AnchorElement(href: url)
          ..setAttribute('download',
              'bill_${data['date']?.replaceAll(':', '-') ?? 'unknown'}_${DateTime.now().millisecondsSinceEpoch}.pdf')
          ..click();
        html.Url.revokeObjectUrl(url);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
  content: Text(AppLocalizations.of(context)!.bill_downloaded_browser),
),
        );
      } else {
        if (await Permission.storage.request().isDenied) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
  content: Text(AppLocalizations.of(context)!.storage_permission_required),
),
          );
          return;
        }

        Directory? directory;
        try {
          directory = await getDownloadsDirectory();
          if (directory == null) {
    throw Exception(AppLocalizations.of(context)!.downloadsDirectoryNotAvailable);
}
        } catch (e) {
          directory = await getApplicationDocumentsDirectory();
        }

        final fileName =
            'bill_${data['date']?.replaceAll(':', '-') ?? 'unknown'}_${DateTime.now().millisecondsSinceEpoch}.pdf';
        final file = File('${directory.path}/$fileName');

        await directory.create(recursive: true);
        await file.writeAsBytes(pdfBytes);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
  content: Text(AppLocalizations.of(context)!.bill_downloaded.replaceFirst('{path}', file.path)),
),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
  content: Text(AppLocalizations.of(context)!.failed_download_bill.replaceFirst('{error}', '$e')),
),
      );
    }
  }

  String _generateHtmlInvoice(Map<String, String> data) {
    return '''
    <!DOCTYPE html>
    <html lang="en">
    <head>
      <meta charset="UTF-8">
      <title>Invoice</title>
      <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        .invoice-box { max-width: 800px; margin: auto; padding: 30px; border: 1px solid #eee; box-shadow: 0 0 10px rgba(0, 0, 0, 0.15); }
        .invoice-box table { width: 100%; line-height: 1.5; border-collapse: collapse; }
        .invoice-box table td { padding: 5px; vertical-align: top; }
        .invoice-box table tr td:nth-child(2) { text-align: right; }
        .invoice-box .title { font-size: 24px; text-align: center; margin-bottom: 20px; }
        .invoice-box .header { background-color: #f7f7f7; font-weight: bold; }
      </style>
    </head>
    <body>
      <div class="invoice-box">
        <div class="title">Invoice Receipt</div>
        <table>
          <tr class="header">
            <td>Field</td>
            <td>Value</td>
          </tr>
          ${fields.map((field) => '''
            <tr>
              <td>${field.name}</td>
              <td>${data[field.name] ?? 'N/A'}</td>
            </tr>
          ''').join('')}
          <tr>
            <td>Date</td>
            <td>${data['date']}</td>
          </tr>
          <tr>
            <td><strong>Total Amount</strong></td>
            <td><strong>${data['Amount'] ?? '0'}</strong></td>
          </tr>
        </table>
        <p style="text-align: center; margin-top: 20px;">Thank you for your business!</p>
      </div>
    </body>
    </html>
    ''';
  }

  void _showInvoiceInWebView(Map<String, String> data) {
    final htmlContent = _generateHtmlInvoice(data);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => InvoiceWebViewScreen(htmlContent: htmlContent),
      ),
    );
  }

  Future<void> _exportToCsv() async {
    try {
      List<Map<String, String>> collectionInfo = savedData;

      if (collectionInfo.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.noDataToExport)),
        );
        return;
      }

      List<List<dynamic>> csvData = [
        collectionInfo.first.keys.toList(),
        ...collectionInfo.map((entry) => entry.values.toList()),
      ];

      String csv = const ListToCsvConverter().convert(csvData);

      if (kIsWeb) {
        final bytes = utf8.encode(csv);
        final blob = html.Blob([bytes], 'text/csv');
        final url = html.Url.createObjectUrlFromBlob(blob);
        final anchor = html.AnchorElement(href: url)
          ..setAttribute('download',
              'collection_${DateTime.now().millisecondsSinceEpoch}.csv')
          ..click();
        html.Url.revokeObjectUrl(url);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.csvDownloadedBrowser)),
        );
      } else {
        if (await Permission.storage.request().isDenied) {
          ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text(AppLocalizations.of(context)!.storagePermissionRequiredCsv)),
          );
          return;
        }

        Directory? directory;
        try {
          directory = await getDownloadsDirectory();
          if (directory == null) {
    throw Exception(AppLocalizations.of(context)!.downloadsDirectoryNotAvailable);
}
        } catch (e) {
          directory = await getApplicationDocumentsDirectory();
        }

        final fileName =
            'collection_${DateTime.now().millisecondsSinceEpoch}.csv';
        final file = File('${directory.path}/$fileName');

        await directory.create(recursive: true);
        await file.writeAsString(csv);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.csvExportedTo.replaceFirst('{path}', file.path))),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.failedToExportCsv.replaceFirst('{error}', e.toString()))),
      );
    }
  }

  String _getLocalizedFieldName(String key) {
  final localizations = AppLocalizations.of(context)!;

  // Match known fields to localization
  switch (key.toLowerCase()) {
    case 'name':
      return localizations.name;
    case 'age':
      return localizations.age;
    case 'number':
      return localizations.number;
    case 'amount':
      return localizations.amount;
    case 'address':
      return localizations.address;
    case 'date':
      return localizations.date;
    default:
      return key; // fallback for custom field names
  }
}


  Widget _buildSavedDataList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: savedData.length,
      itemBuilder: (context, index) {
        return Card(
          margin: EdgeInsets.symmetric(vertical: 4.0),
          child: ListTile(
            title: Text(
                                "${AppLocalizations.of(context)!.entry} ${index + 1}",
                              ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: savedData[index].entries.map((e) {
  final fieldLabel = _getLocalizedFieldName(e.key);
  return Text('$fieldLabel: ${e.value}');
}).toList(),

            ),
            trailing: Row(
  mainAxisSize: MainAxisSize.min,
  children: [
    IconButton(
      icon: Icon(Icons.remove_red_eye_outlined),
      onPressed: () => _showInvoiceInWebView(savedData[index]),
    ),
    IconButton(
      icon: Icon(Icons.print),
      onPressed: () => _generateAndDownloadBill(savedData[index]),
    ),
    IconButton(
      icon: Icon(Icons.delete, color: Colors.redAccent),
      onPressed: () {
        setState(() {
          savedData.removeAt(index);
          dataBox.put('data', savedData);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.entryDeleted)),
        );
      },
    ),
  ],
),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
   return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.collection),
        actions: [
          IconButton(
            icon: Icon(Icons.download),
            onPressed: _exportToCsv,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      ...fields.map((field) => _buildField(field)).toList(),
                      SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blueAccent,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                            ),
                            onPressed: _saveData,
                            child: Text(AppLocalizations.of(context)!.save,
                                style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.bold)),
                          ),
                          TextButton(
                            onPressed: _clearAllFields,
                            child: Text(AppLocalizations.of(context)!.clear_all,
                                style:
                                    TextStyle(color: Colors.red, fontSize: 16)),
                          ),
                        ],
                      ),
                      SizedBox(height: 20),
                      Text(AppLocalizations.of(context)!.saved_data,
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                      _buildSavedDataList(),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class InvoiceWebViewScreen extends StatelessWidget {
  final String htmlContent;

  const InvoiceWebViewScreen({Key? key, required this.htmlContent})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.invoicePreview),
      ),
      body: InAppWebView(
        initialData: InAppWebViewInitialData(
          data: htmlContent,
          mimeType: 'text/html',
          encoding: 'utf-8',
        ),
        initialOptions: InAppWebViewGroupOptions(
          crossPlatform: InAppWebViewOptions(
            javaScriptEnabled: true,
            useShouldOverrideUrlLoading: true,
          ),
        ),
        onWebViewCreated: (controller) {},
      ),
    );
  }
}

class ReportsScreen extends StatefulWidget {
  @override
  _ReportsScreenState createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  late Box<List> collectionBox;
  String selectedFilter = "Today";
  String? selectedDate;

  String getLocalizedField(String key) {
  switch (key) {
    case "Name":
      return AppLocalizations.of(context)!.name;
    case "Age":
      return AppLocalizations.of(context)!.age;
    case "Number":
      return AppLocalizations.of(context)!.number;
    case "Amount":
      return AppLocalizations.of(context)!.amount;
    case "Address":
      return AppLocalizations.of(context)!.address;
    case "date":
      return AppLocalizations.of(context)!.date;
    default:
      return key;
  }
}


  @override
  void initState() {
    super.initState();
    collectionBox = Hive.box<List>('collection_data');
    _storeDummyData();
  }

  void _storeDummyData() {
    DateTime yesterday = DateTime.now().subtract(Duration(days: 1));
    // ignore: unused_local_variable
    String formattedDate = DateFormat('yyyy-MM-dd').format(yesterday);
    List<dynamic>? existingData = collectionBox.get('data');

    if (existingData == null || existingData.isEmpty) {
      Map<String, String> dummyEntry = {
        "Name": "John Doe",
        "Age": "30",
        "Number": "1234567890",
        "Amount": "500",
        "Address": "123 Poultry Street",
        "date": DateFormat('yyyy-MM-dd HH:mm:ss').format(yesterday),
      };
      setState(() {
        collectionBox.put('data', [dummyEntry]);
      });
    }
  }

  List<Map<String, String>> getFilteredCollectionInfo({String? specificDate}) {
    String today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    String yesterday = DateFormat('yyyy-MM-dd')
        .format(DateTime.now().subtract(Duration(days: 1)));

    List<dynamic>? storedData = collectionBox.get('data');
    List<Map<String, String>> collectionInfo = (storedData ?? [])
        .map((item) => Map<String, String>.from(item as Map))
        .toList();

    if (specificDate != null) {
      return collectionInfo
          .where((entry) =>
              entry["date"]?.toString().startsWith(specificDate) ?? false)
          .toList();
    }

    if (selectedFilter == "Today") {
      return collectionInfo
          .where((entry) => entry["date"]?.toString().startsWith(today) ?? false)
          .toList();
    } else if (selectedFilter == "Yesterday") {
      return collectionInfo
          .where((entry) =>
              entry["date"]?.toString().startsWith(yesterday) ?? false)
          .toList();
    }

    return collectionInfo;
  }

  void _showDateDataPopup(String selectedDate) {
  List<Map<String, String>> filteredData = getFilteredCollectionInfo(specificDate: selectedDate);
  
  // Convert selectedDate format for display
  String displayDate = DateFormat('dd-MMM-yyyy').format(DateFormat('yyyy-MM-dd').parse(selectedDate));

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (context) {
      return Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
                "${AppLocalizations.of(context)!.data_for} $displayDate",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            SizedBox(height: 10),
            filteredData.isNotEmpty
                ? SizedBox(
                    height: MediaQuery.of(context).size.height * 0.5,
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: filteredData.length,
                      itemBuilder: (context, index) {
                        return Card(
                          margin: EdgeInsets.symmetric(vertical: 4.0),
                          child: ListTile(
                            title: Text(
                                "${AppLocalizations.of(context)!.entry} ${index + 1}",
                              ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: filteredData[index]
  .entries
  .map((e) {
    String label = getLocalizedField(e.key);
    String value = e.key == "date"
      ? DateFormat('dd-MMM-yyyy HH:mm:ss').format(DateFormat('yyyy-MM-dd HH:mm:ss').parse(e.value))
      : e.value;
    return Text('$label: $value');
  })
  .toList(),
                            ),
                          ),
                        );
                      },
                    ),
                  )
                : Center(
                      child: Text(AppLocalizations.of(context)!.no_data_available),
                    ),
          ],
        ),
      );
    },
  );
}

  Future<void> _pickDate() async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (pickedDate != null) {
      setState(() {
        selectedDate = DateFormat('yyyy-MM-dd').format(pickedDate);
      });
      _showDateDataPopup(selectedDate!);
    }
  }

  @override
  Widget build(BuildContext context) {
    List<Map<String, String>> collectionInfo = getFilteredCollectionInfo();

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.reports),
        centerTitle: true,
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ElevatedButton(
              onPressed: _pickDate,
              child: Text(selectedDate ?? AppLocalizations.of(context)!.select_date),
            ),
            SizedBox(height: 16),
            Wrap(
  spacing: 12, // Increased space between buttons
  runSpacing: 12, // Space between wrapped lines
  alignment: WrapAlignment.center,
  children: [
    _filterButton(AppLocalizations.of(context)!.today),
    _filterButton(AppLocalizations.of(context)!.yesterday),
    _filterButton(AppLocalizations.of(context)!.this_week),
    _filterButton(AppLocalizations.of(context)!.this_month),
  ],
),

            SizedBox(height: 16),
            _buildSummaryGrid(collectionInfo), // Updated type
            SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
  AppLocalizations.of(context)!.recent_collection,
  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black),
),
            ),
            SizedBox(height: 8),
            Expanded(
              child: collectionInfo.isNotEmpty
                  ? ListView.builder(
                      itemCount: collectionInfo.length,
                      itemBuilder: (context, index) {
                        return _listItem(collectionInfo[index], index);
                      },
                    )
                  : Center(
                      child: Text(
                        AppLocalizations.of(context)!.no_data_available,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryGrid(List<Map<String, String>> collectionInfo) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 4,
      physics: NeverScrollableScrollPhysics(),
      children: [
  _summaryCard(AppLocalizations.of(context)!.total_collection, _calculateTotal(collectionInfo, "count")),
  _summaryCard(AppLocalizations.of(context)!.previous_collection, _calculatePreviousTotal()),
  _summaryCard(AppLocalizations.of(context)!.total_clients, _calculateTotalClients(collectionInfo)),
  _summaryCard(AppLocalizations.of(context)!.total_payments, _calculateTotalPayments(collectionInfo)),
],

    );
  }

  String _calculateTotal(List<Map<String, String>> collectionInfo, String key) {
    return collectionInfo.length.toString();
  }

  String _calculateTotalPayments(List<Map<String, String>> collectionInfo) {
    double total = collectionInfo.fold(0.0, (sum, item) {
      return sum + (double.tryParse(item["Amount"] ?? '0') ?? 0.0);
    });
    return total.toStringAsFixed(2);
  }

  String _calculatePreviousTotal() {
    DateTime now = DateTime.now();
    List<dynamic>? storedData = collectionBox.get('data');
    List<Map<String, String>> collectionInfo = (storedData ?? [])
        .map((item) => Map<String, String>.from(item as Map))
        .toList();

    String filterDate = "";

    if (selectedFilter == "Today") {
      DateTime yesterday = now.subtract(Duration(days: 1));
      filterDate = DateFormat('yyyy-MM-dd').format(yesterday);
    } else if (selectedFilter == "Yesterday") {
      DateTime lastWeekSameDay = now.subtract(Duration(days: 7));
      filterDate = DateFormat('yyyy-MM-dd').format(lastWeekSameDay);
    } else if (selectedFilter == "This Week") {
      DateTime lastMonday = now.subtract(Duration(days: now.weekday + 6));
      DateTime lastSunday = lastMonday.add(Duration(days: 6));
      return collectionInfo
          .where((entry) {
            String date = entry["date"] ?? "";
            return date.compareTo(DateFormat('yyyy-MM-dd').format(lastMonday)) >= 0 &&
                date.compareTo(DateFormat('yyyy-MM-dd').format(lastSunday)) <= 0;
          })
          .length
          .toString();
    } else if (selectedFilter == "This Month") {
      DateTime firstDayPrevMonth = DateTime(now.year, now.month - 1, 1);
      DateTime lastDayPrevMonth = DateTime(now.year, now.month, 0);
      return collectionInfo
          .where((entry) {
            String date = entry["date"] ?? "";
            return date.compareTo(DateFormat('yyyy-MM-dd').format(firstDayPrevMonth)) >= 0 &&
                date.compareTo(DateFormat('yyyy-MM-dd').format(lastDayPrevMonth)) <= 0;
          })
          .length
          .toString();
    }

    return collectionInfo
        .where((entry) => entry["date"]?.startsWith(filterDate) ?? false)
        .length
        .toString();
  }

  String _calculateTotalClients(List<Map<String, String>> collectionInfo) {
    Set<String> uniqueClients = {};
    for (var entry in collectionInfo) {
      String? clientName = entry["Name"]?.trim();
      String? mobileNumber = entry["Number"]?.trim();
      if (clientName != null && mobileNumber != null && clientName.isNotEmpty && mobileNumber.isNotEmpty) {
        uniqueClients.add("$clientName|$mobileNumber");
      }
    }
    return uniqueClients.length.toString();
  }

  Widget _summaryCard(String title, String value) {
    return Container(
      padding: EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 2,
            offset: Offset(1, 1),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            title,
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600, fontSize: 13),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(color: Colors.black, fontSize: 15, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _filterButton(String text) {
  return ElevatedButton(
    style: ElevatedButton.styleFrom(
      padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16), // Bigger padding
      backgroundColor: selectedFilter == text ? Colors.blue : Colors.grey[300],
      foregroundColor: selectedFilter == text ? Colors.white : Colors.black,
      textStyle: TextStyle(fontSize: 14), // Bigger font
    ),
    onPressed: () {
      setState(() {
        selectedFilter = text;
        selectedDate = null;
      });
    },
    child: Text(text),
  );
}


  Widget _listItem(Map<String, String> item, int index) {
  return Card(
    margin: EdgeInsets.symmetric(vertical: 4.0),
    child: ListTile(
      title: Text("${AppLocalizations.of(context)!.entry} ${index + 1}"),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: item.entries.map((e) {
          String label = getLocalizedField(e.key);
          String value = e.value;
          return Text('$label: $value');
        }).toList(),
      ),
    ),
  );
}
}
