import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:csv/csv.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../models/category_model.dart';
import '../models/transaction_model.dart';

/// Builds CSV from transactions and opens the OS share sheet.
class ExportService {
  ExportService();

  final _df = DateFormat.yMMMd().add_jm();

  String buildCsvContent({
    required List<TransactionModel> rows,
    required List<CategoryModel> categories,
    required String currencySymbol,
  }) {
    final catMap = {for (final c in categories) c.id: c.name};
    final data = <List<String>>[
      ['date', 'type', 'amount', 'category', 'notes', 'tags', 'account'],
      ...rows.map((t) {
        return [
          _df.format(t.dateTime.toLocal()),
          t.type,
          t.amount.toStringAsFixed(2),
          catMap[t.categoryId] ?? '',
          t.notes ?? '',
          t.tags.join(';'),
          t.accountType,
        ];
      }),
    ];
    return const ListToCsvConverter().convert(data);
  }

  Future<File> writeCsvFile(String csv) async {
    final file = File(
      '${Directory.systemTemp.path}/expense_export_${DateTime.now().millisecondsSinceEpoch}.csv',
    );
    await file.writeAsString(csv);
    return file;
  }

  Future<String?> exportCsv({
    required List<TransactionModel> rows,
    required List<CategoryModel> categories,
    required String currencySymbol,
  }) async {
    final csv = buildCsvContent(
      rows: rows,
      categories: categories,
      currencySymbol: currencySymbol,
    );
    final fileName =
        'expense_export_${DateTime.now().millisecondsSinceEpoch}.csv';

    if (kIsWeb) {
      // Web has no local filesystem namespace; share as an in-memory CSV file.
      final csvFile = XFile.fromData(
        utf8.encode(csv),
        mimeType: 'text/csv',
        name: fileName,
      );
      await Share.shareXFiles(
        [csvFile],
        text: 'Transactions export',
        subject: 'Transactions export',
      );
      return null;
    }

    final file = await writeCsvFile(csv);
    await Share.shareXFiles([XFile(file.path)], text: 'Transactions export');
    return file.path;
  }
}
