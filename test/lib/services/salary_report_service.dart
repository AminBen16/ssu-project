import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:test/models/salary_model.dart';

class SalaryReportService {
  Future<Uint8List> generateSalaryPdf({
    required String schoolName,
    required String staffName,
    required String year,
    required List<SalaryPayment> payments,
  }) async {
    final pdf = pw.Document();
    final double totalPaid =
        payments.fold(0.0, (sum, item) => sum + item.amountPaid);

    // Group payments by month to calculate monthly totals.
    final Map<String, double> monthlyTotals = {};
    for (final payment in payments) {
      monthlyTotals.update(
        payment.month,
        (value) => value + payment.amountPaid,
        ifAbsent: () => payment.amountPaid,
      );
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return [
            _buildHeader(schoolName, staffName, year),
            pw.SizedBox(height: 20),
            _buildSalaryTable(payments),
            pw.Divider(),
            pw.SizedBox(height: 10),
            _buildMonthlySummary(monthlyTotals),
            pw.SizedBox(height: 20),
            _buildFooter(totalPaid),
          ];
        },
      ),
    );

    return pdf.save();
  }

  pw.Widget _buildHeader(String schoolName, String staffName, String year) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Text(
          schoolName.toUpperCase(),
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 18),
        ),
        pw.SizedBox(height: 10),
        pw.Text(
          'Salary Payment History for $year',
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16),
        ),
        pw.SizedBox(height: 5),
        pw.Text('Staff Member: $staffName'),
      ],
    );
  }

  pw.Widget _buildSalaryTable(List<SalaryPayment> payments) {
    final headers = ['Payment Date', 'Month', 'Amount Paid', 'Recorded By'];

    final data = payments.map((payment) {
      return [
        DateFormat.yMMMd().format(payment.paymentDate),
        payment.month,
        NumberFormat.currency(symbol: 'UGX ').format(payment.amountPaid),
        payment.recordedByName,
      ];
    }).toList();

    return pw.TableHelper.fromTextArray(
      headers: headers,
      data: data,
      border: pw.TableBorder.all(),
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
      cellHeight: 30,
      cellAlignments: {
        0: pw.Alignment.centerLeft,
        1: pw.Alignment.centerLeft,
        2: pw.Alignment.centerRight,
        3: pw.Alignment.centerLeft,
      },
      cellPadding: const pw.EdgeInsets.all(5),
    );
  }

  pw.Widget _buildMonthlySummary(Map<String, double> monthlyTotals) {
    if (monthlyTotals.isEmpty) {
      return pw.SizedBox.shrink();
    }

    // Define the correct order of months for sorting.
    const monthOrder = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];

    final sortedEntries = monthlyTotals.entries.toList()
      ..sort((a, b) =>
          monthOrder.indexOf(a.key).compareTo(monthOrder.indexOf(b.key)));

    final headers = ['Month', 'Total Paid'];
    final data = sortedEntries.map((entry) {
      return [
        entry.key,
        NumberFormat.currency(symbol: 'UGX ').format(entry.value),
      ];
    }).toList();

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Monthly Summary',
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16),
        ),
        pw.SizedBox(height: 10),
        pw.TableHelper.fromTextArray(
          headers: headers,
          data: data,
          border: pw.TableBorder.all(),
          headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
          cellAlignments: {
            0: pw.Alignment.centerLeft,
            1: pw.Alignment.centerRight
          },
          cellPadding: const pw.EdgeInsets.all(5),
        ),
      ],
    );
  }

  pw.Widget _buildFooter(double totalPaid) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.end,
      children: [
        pw.Text(
          'Total Paid for Year: ',
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14),
        ),
        pw.Text(
          NumberFormat.currency(symbol: 'UGX ').format(totalPaid),
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14),
        ),
      ],
    );
  }
}
