import 'dart:io';
import 'dart:convert';
import 'dart:html' as html;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:intl/intl.dart';

Future<void> exportToCSV(BuildContext context, List<Map<String, String>> filteredData, String filterName) async {
  if (filteredData.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('No data to export')),
    );
    return;
  }
  
  List<List<dynamic>> csvData = [];
  csvData.add(["Name", "Age", "Number", "Amount", "Address", "Date"]);
  
  for (var entry in filteredData) {
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
  String fileName = "collection_data_${filterName.toLowerCase().replaceAll(' ', '_')}.csv";
  
  if (kIsWeb) {
    final blob = html.Blob([csv], 'text/csv');
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..setAttribute("download", fileName)
      ..click();
    
    html.Url.revokeObjectUrl(url);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$filterName data exported to CSV')),
    );
  } else {
    var status = await Permission.storage.request();
    if (!status.isGranted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Storage permission denied')),
      );
      return;
    }
    
    final directory = await getExternalStorageDirectory();
    final String filePath = "${directory!.path}/$fileName";
    
    final File file = File(filePath);
    await file.writeAsString(csv);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$filterName data exported to: $filePath')),
    );
  }
}