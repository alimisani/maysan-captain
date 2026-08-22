import 'package:flutter/services.dart';
import 'package:intl/intl.dart' as intl;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../constants/app_constants.dart';
import '../../models/ride_order.dart';

class PdfService {
  static Future<void> generateAndPrintInvoice(RideOrder order, {bool isArabic = true}) async {
    final pdf = pw.Document();

    // Use PdfGoogleFonts for perfect Arabic HarfBuzz glyph shaping and connecting letters
    pw.Font arabicFont;
    pw.Font arabicBoldFont;
    try {
      arabicFont = await PdfGoogleFonts.cairoRegular();
      arabicBoldFont = await PdfGoogleFonts.cairoBold();
    } catch (_) {
      try {
        final fontData = await rootBundle.load('assets/fonts/Cairo-Regular.ttf');
        arabicFont = pw.Font.ttf(fontData);
        final boldData = await rootBundle.load('assets/fonts/Cairo-Bold.ttf');
        arabicBoldFont = pw.Font.ttf(boldData);
      } catch (_) {
        arabicFont = pw.Font.helvetica();
        arabicBoldFont = pw.Font.helveticaBold();
      }
    }

    Uint8List? logoBytes;
    try {
      final logoData = await rootBundle.load('assets/icon/app.png');
      logoBytes = logoData.buffer.asUint8List();
    } catch (_) {}

    final dateStr = intl.DateFormat('yyyy-MM-dd HH:mm').format(order.createdAt);
    final numberFormat = intl.NumberFormat('#,###');

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        theme: pw.ThemeData.withFont(
          base: arabicFont,
          bold: arabicBoldFont,
        ),
        textDirection: pw.TextDirection.rtl,
        build: (pw.Context context) {
          return pw.Container(
            padding: const pw.EdgeInsets.all(28),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.blueGrey800, width: 1.5),
              borderRadius: pw.BorderRadius.circular(12),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.stretch,
              children: [
                // Header: Logo and Title
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'كابتن ميسان - Maysan Captain',
                          style: pw.TextStyle(
                            fontSize: 22,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.blue800,
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          'محافظة ميسان - جمهورية العراق',
                          style: const pw.TextStyle(
                            fontSize: 12,
                            color: PdfColors.grey700,
                          ),
                        ),
                        pw.Text(
                          'هاتف الإدارة: ${AppConstants.adminPhone}',
                          style: const pw.TextStyle(
                            fontSize: 11,
                            color: PdfColors.grey700,
                          ),
                        ),
                      ],
                    ),
                    if (logoBytes != null)
                      pw.Container(
                        width: 70,
                        height: 70,
                        child: pw.Image(pw.MemoryImage(logoBytes)),
                      ),
                  ],
                ),
                pw.Divider(thickness: 1.5, color: PdfColors.blue800, height: 28),

                // Invoice Banner
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.blue50,
                    borderRadius: pw.BorderRadius.circular(8),
                  ),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        'فاتورة رحلة وتوصيل رسمية',
                        style: pw.TextStyle(
                          fontSize: 16,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.blue900,
                        ),
                      ),
                      pw.Text(
                        'رقم الطلب: #${order.orderNumber}',
                        style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.blue900,
                        ),
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 20),

                // Trip Information Box
                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    // Customer & Driver Details
                    pw.Expanded(
                      child: pw.Container(
                        padding: const pw.EdgeInsets.all(12),
                        decoration: pw.BoxDecoration(
                          color: PdfColors.grey100,
                          borderRadius: pw.BorderRadius.circular(8),
                        ),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              'بيانات الطلب والعميل:',
                              style: pw.TextStyle(
                                fontSize: 13,
                                fontWeight: pw.FontWeight.bold,
                                color: PdfColors.blue800,
                              ),
                            ),
                            pw.SizedBox(height: 6),
                            pw.Text('اسم الزبون: ${order.customerName ?? "زبون ميسان"}'),
                            pw.Text('رقم الهاتف: ${order.customerPhone ?? "غير متوفر"}'),
                            pw.Text('نوع الخدمة: ${order.isRide ? "توصيل ركاب" : "توصيل طرد/شحنة"}'),
                            pw.Text('تاريخ الطلب: $dateStr'),
                          ],
                        ),
                      ),
                    ),
                    pw.SizedBox(width: 14),
                    // Driver & Vehicle Details
                    pw.Expanded(
                      child: pw.Container(
                        padding: const pw.EdgeInsets.all(12),
                        decoration: pw.BoxDecoration(
                          color: PdfColors.grey100,
                          borderRadius: pw.BorderRadius.circular(8),
                        ),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              'بيانات الكابتن والمركبة:',
                              style: pw.TextStyle(
                                fontSize: 13,
                                fontWeight: pw.FontWeight.bold,
                                color: PdfColors.blue800,
                              ),
                            ),
                            pw.SizedBox(height: 6),
                            pw.Text('اسم الكابتن: ${order.driverName ?? "كابتن معتمد"}'),
                            pw.Text('رقم الهاتف: ${order.driverPhone ?? "غير متوفر"}'),
                            pw.Text('معلومات المركبة: ${order.vehicleInfo ?? "سيارة أجرة"}'),
                            pw.Text('المسافة المقطوعة: ${order.distanceKm} كم'),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 20),

                // Route Table
                pw.Table(
                  border: pw.TableBorder.all(color: PdfColors.grey400),
                  children: [
                    pw.TableRow(
                      decoration: const pw.BoxDecoration(color: PdfColors.blue100),
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text('النقطة', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text('الموقع / العنوان في محافظة ميسان', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        ),
                      ],
                    ),
                    pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text('الانطلاق (البداية)'),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(order.pickupAddress),
                        ),
                      ],
                    ),
                    pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text('الوصول (الوجهة)'),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(order.dropoffAddress),
                        ),
                      ],
                    ),
                  ],
                ),
                pw.SizedBox(height: 24),

                // Fare Summary Box
                pw.Container(
                  padding: const pw.EdgeInsets.all(16),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.green50,
                    borderRadius: pw.BorderRadius.circular(8),
                    border: pw.Border.all(color: PdfColors.green700, width: 1.2),
                  ),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        'إجمالي المبلغ المستحق:',
                        style: pw.TextStyle(
                          fontSize: 16,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.green900,
                        ),
                      ),
                      pw.Text(
                        '${numberFormat.format(order.finalFare.toInt())} دينار عراقي',
                        style: pw.TextStyle(
                          fontSize: 20,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.green900,
                        ),
                      ),
                    ],
                  ),
                ),

                pw.Spacer(),

                // Footer
                pw.Divider(thickness: 1, color: PdfColors.grey400),
                pw.SizedBox(height: 6),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'تطبيق كابتن ميسان | شركة ميسان تك للبرمجيات',
                      style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
                    ),
                    pw.Text(
                      'شكراً لاستخدامكم خدمات كابتن ميسان',
                      style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Maysan_Captain_Invoice_${order.orderNumber}.pdf',
    );
  }
}
