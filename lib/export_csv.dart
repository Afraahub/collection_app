import 'dart:io';
import 'dart:convert';
import 'dart:html' as html; // Only for web
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class ExportCSVScreen extends StatefulWidget {
  @override
  _ExportCSVScreenState createState() => _ExportCSVScreenState();
}

class _ExportCSVScreenState extends State<ExportCSVScreen> {
  Future<void> _exportToCSV() async {
    var box = Hive.box<List>('collection_data');
    List<dynamic>? storedData = box.get('data');

    if (storedData == null || storedData.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No data to export')),
      );
      return;
    }

    List<List<dynamic>> csvData = [];
    csvData.add(["Name", "Age", "Number", "Amount", "Address", "Date"]);

    for (var item in storedData) {
      // ✅ Correctly convert LinkedHashMap to Map<String, String>
      Map<String, String> entry = Map<String, String>.from(
        item.map((key, value) => MapEntry(key.toString(), value.toString()))
      );

      csvData.add([
        entry["Name"] ?? "",
        entry["Age"] ?? "",
        entry["Number"] ?? "",
        entry["Amount"] ?? "",
        entry["Address"] ?? "",
        entry["date"] ?? ""
      ]);
    }

    String csv = const ListToCsvConverter().convert(csvData);

    if (kIsWeb) {
      // **Web Logic: Trigger Download in Browser**
      final blob = html.Blob([csv], 'text/csv');
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.AnchorElement(href: url)
        ..setAttribute("download", "collection_data.csv")
        ..click();

      html.Url.revokeObjectUrl(url);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('CSV file downloaded')),
      );
    } else {
      // **Mobile Logic: Save to External Storage**
      var status = await Permission.storage.request();
      if (!status.isGranted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Storage permission denied')),
        );
        return;
      }

      final directory = await getExternalStorageDirectory();
      final String filePath = "${directory!.path}/collection_data.csv";

      final File file = File(filePath);
      await file.writeAsString(csv);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('CSV Exported: $filePath')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Export CSV")),
      body: Center(
        child: ElevatedButton(
          onPressed: _exportToCSV,
          child: Text("Export Data to CSV"),
        ),
      ),
    );
  }
}
