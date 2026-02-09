import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:test/models/student_model.dart';
import 'package:test/models/fee_balance_model.dart';
import 'package:test/models/school.dart';

class PdfService {
  /// Generates a generic PDF document from provided data
  Future<Uint8List> generatePdf(Map<String, dynamic> data) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Document Title',
                  style: pw.TextStyle(
                      fontSize: 24, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 20),
              ...data.entries.map((entry) => pw.Text(
                  '${entry.key}: ${entry.value}',
                  style: const pw.TextStyle(fontSize: 14))),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  /// Generates a payment details PDF with formatted payment information
  Future<Uint8List> generatePaymentDetailsPdf(
    Student student,
    double balance,
    FeeBalance feeBalance,
    School school,
  ) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Text('Payment Details',
                  style: pw.TextStyle(
                      fontSize: 24, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 20),

              // Student Information
              pw.Text('Student Information:',
                  style: pw.TextStyle(
                      fontSize: 16, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 10),
              pw.Text('Name: ${student.fullName}'),
              pw.Text('ID: ${student.id}'),
              pw.Text('Class: ${student.className}'),
              pw.SizedBox(height: 20),

              // Payment Information
              pw.Text('Payment Information:',
                  style: pw.TextStyle(
                      fontSize: 16, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 10),
              pw.Text('Balance: $balance UGX'),
              pw.Text('School: ${school.name}'),
              pw.SizedBox(height: 20),

              // Footer
              pw.Spacer(),
              pw.Text(
                  'Generated on: ${DateTime.now().toString().split('.')[0]}',
                  style:
                      const pw.TextStyle(fontSize: 10, color: PdfColors.grey)),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }
}
