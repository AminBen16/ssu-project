import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:test/models/fee_balance_model.dart';
import 'package:test/models/school.dart';
import 'package:test/models/student_model.dart';

class PdfService {
  /// Generates a payment details PDF for a student.
  Future<Uint8List> generatePaymentDetailsPdf({
    required Student student,
    required double balance,
    required FeeBalance feeBalance,
    required School? school,
  }) async {
    final doc = pw.Document();
    final schoolName = school?.name ?? 'School Details';

    // Fetch logo image
    pw.ImageProvider? logoImage;
    if (school?.logoUrl != null && school!.logoUrl!.isNotEmpty) {
      try {
        logoImage = await networkImage(school.logoUrl!);
      } catch (e) {
        debugPrint('Could not fetch school logo for PDF: $e');
      }
    }

    final paidOnDate = feeBalance.lastPaymentDate;

    // Determine stamp color
    PdfColor stampColor = PdfColors.green;
    if (school?.paidStampColor != null) {
      final colorInt = int.tryParse(school!.paidStampColor!);
      if (colorInt != null && colorInt != 0) {
        stampColor = PdfColor.fromInt(colorInt);
      }
    }

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Stack(
            children: [
              if (logoImage != null)
                pw.Center(
                  child: pw.Opacity(
                    opacity: 0.1,
                    child: pw.Image(logoImage, fit: pw.BoxFit.contain),
                  ),
                ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  if (logoImage != null)
                    pw.Center(
                      child: pw.Container(
                        height: 80,
                        child: pw.Image(logoImage),
                      ),
                    ),
                  pw.Header(
                    level: 0,
                    child: pw.Text('$schoolName: Payment Details',
                        style: pw.Theme.of(context).header1,
                        textAlign: pw.TextAlign.center),
                  ),
                  pw.Paragraph(
                      text:
                          'Date: ${DateFormat.yMMMd().format(DateTime.now())}'),
                  pw.Divider(),
                  pw.SizedBox(height: 20),
                  pw.Paragraph(text: 'Student Name: ${student.fullName}'),
                  pw.Paragraph(text: 'Student ID: ${student.id}'),
                  pw.SizedBox(height: 20),
                  pw.Paragraph(
                    text:
                        'Outstanding Balance: ${NumberFormat.currency(symbol: 'UGX ').format(balance)}',
                    style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold, fontSize: 16),
                  ),
                  if (balance <= 0 && school?.nextTermBeginsOn != null) ...[
                    pw.SizedBox(height: 30),
                    pw.Center(
                      child: pw.Text(
                        'Next Term Begins On: ${DateFormat.yMMMMd().format(school!.nextTermBeginsOn!)}',
                        style: pw.TextStyle(fontStyle: pw.FontStyle.italic),
                      ),
                    ),
                  ],
                  pw.Spacer(),
                  if (school?.website != null && school!.website!.isNotEmpty)
                    pw.Center(
                      child: pw.BarcodeWidget(
                        barcode: pw.Barcode.qrCode(),
                        data: school.website!,
                        width: 60,
                        height: 60,
                      ),
                    ),
                  pw.SizedBox(height: 5),
                ],
              ),
              if (balance <= 0)
                pw.Center(
                  child: pw.Transform.rotate(
                    angle: -0.785, // -45 degrees in radians
                    child: pw.Column(
                      mainAxisSize: pw.MainAxisSize.min,
                      children: [
                        pw.Container(
                          padding: const pw.EdgeInsets.symmetric(
                              horizontal: 40, vertical: 10),
                          decoration: pw.BoxDecoration(
                            border: pw.Border.all(color: stampColor, width: 4),
                            borderRadius: pw.BorderRadius.circular(10),
                          ),
                          child: pw.Text(
                            'PAID',
                            style: pw.TextStyle(
                              fontSize: 80,
                              fontWeight: pw.FontWeight.bold,
                              color: stampColor.changeAlpha(0.3),
                            ),
                          ),
                        ),
                        if (paidOnDate != null)
                          pw.Text(
                            'On ${DateFormat.yMMMd().format(paidOnDate)}',
                            style: pw.TextStyle(
                                color: stampColor.changeAlpha(0.5),
                                fontSize: 14),
                          ),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );

    return doc.save();
  }
}

extension PdfColorExtension on PdfColor {
  /// Creates a new [PdfColor] with the same RGB values but a new alpha value.
  PdfColor changeAlpha(double alpha) => PdfColor(red, green, blue, alpha);
}
