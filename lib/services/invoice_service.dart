import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/order_model.dart';
import '../models/user_model.dart';
import 'invoice_downloader.dart';

class InvoiceService {
  /// Generate and download the invoice PDF for the given order.
  static Future<void> downloadInvoice({
    required BuildContext context,
    required OrderModel order,
    UserModel? user,
  }) async {
    try {
      final pdfBytes = await generateInvoicePdf(order: order, user: user);

      String rawId = order.id.toString().trim();
      String displayId = rawId;
      if (!displayId.toUpperCase().startsWith('GFM-')) {
        displayId = 'GFM-$displayId';
      }
      displayId = displayId.replaceAll('#', '');

      final filename = 'Invoice_$displayId.pdf';

      await saveAndDownloadPdf(bytes: pdfBytes, filename: filename);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Invoice $filename generated successfully!'),
            backgroundColor: const Color(0xFF2E7D32),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error generating/downloading invoice: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to download invoice: ${e.toString().replaceAll('Exception: ', '')}',
            ),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  /// Builds the complete PDF document matching the reference layout and returns its bytes.
  static Future<Uint8List> generateInvoicePdf({
    required OrderModel order,
    UserModel? user,
  }) async {
    final pdf = pw.Document();

    // 1. Load Fonts
    pw.Font fontRegular;
    pw.Font fontBold;
    final List<pw.Font> fallbackFonts = [];

    try {
      final fontData = await rootBundle.load('assets/fonts/segoeui.ttf');
      final fontBoldData = await rootBundle.load('assets/fonts/segoeuib.ttf');
      fontRegular = pw.Font.ttf(fontData);
      fontBold = pw.Font.ttf(fontBoldData);
    } catch (_) {
      try {
        fontRegular = await PdfGoogleFonts.robotoRegular();
        fontBold = await PdfGoogleFonts.robotoBold();
      } catch (_) {
        fontRegular = pw.Font.helvetica();
        fontBold = pw.Font.helveticaBold();
      }
    }

    // Load Tamil Unicode Fonts (for item names and addresses written in Tamil)
    try {
      final tamilData = await rootBundle.load(
        'assets/fonts/NotoSansTamil-Regular.ttf',
      );
      final tamilFont = pw.Font.ttf(tamilData);
      fallbackFonts.add(tamilFont);
    } catch (e) {
      debugPrint('Could not load NotoSansTamil-Regular.ttf: $e');
    }

    try {
      final tamilBoldData = await rootBundle.load(
        'assets/fonts/NotoSansTamil-Bold.ttf',
      );
      final tamilBoldFont = pw.Font.ttf(tamilBoldData);
      fallbackFonts.add(tamilBoldFont);
    } catch (e) {
      debugPrint('Could not load NotoSansTamil-Bold.ttf: $e');
    }

    // 2. Load Assets (Logo & Veggies banner)
    pw.MemoryImage? logoImage;
    try {
      final logoBytes = (await rootBundle.load(
        'assets/images/invoice_logo.png',
      )).buffer.asUint8List();
      logoImage = pw.MemoryImage(logoBytes);
    } catch (e) {
      debugPrint('Could not load invoice_logo.png: $e');
    }

    pw.MemoryImage? veggiesImage;
    try {
      final veggiesBytes = (await rootBundle.load(
        'assets/images/invoice_veggies.png',
      )).buffer.asUint8List();
      veggiesImage = pw.MemoryImage(veggiesBytes);
    } catch (e) {
      debugPrint('Could not load invoice_veggies.png: $e');
    }

    // 3. Pre-fetch Item Images (with timeout and error handling)
    final Map<int, pw.MemoryImage> itemImagesMap = {};
    for (int i = 0; i < order.items.length; i++) {
      final item = order.items[i];
      if (item.images.isNotEmpty) {
        final url = item.images.first;
        if (url.startsWith('http')) {
          try {
            final res = await http
                .get(Uri.parse(url))
                .timeout(const Duration(milliseconds: 2500));
            if (res.statusCode == 200 && res.bodyBytes.isNotEmpty) {
              itemImagesMap[i] = pw.MemoryImage(res.bodyBytes);
            }
          } catch (_) {
            // Silently ignore image load failure for PDF
          }
        }
      }
    }

    // 4. Resolve Order Meta
    String rawId = order.id.toString().trim();
    String displayOrderId = rawId;
    if (!displayOrderId.startsWith('#')) {
      if (!displayOrderId.toUpperCase().startsWith('GFM-')) {
        displayOrderId = '#GFM-$displayOrderId';
      } else {
        displayOrderId = '#$displayOrderId';
      }
    }

    String orderDate = '23/10/2026';
    String orderTime = '01:00:53';
    // Use order creation date and time from data.createdAt
    final dateStr = (order.createdAt != null && order.createdAt!.trim().isNotEmpty)
        ? order.createdAt
        : order.effectiveCreatedAt;
    if (dateStr != null && dateStr.isNotEmpty) {
      String cleanDate = dateStr.trim();
      if (cleanDate.endsWith('Z') || cleanDate.endsWith('z')) {
        cleanDate = cleanDate.substring(0, cleanDate.length - 1);
      }
      cleanDate = cleanDate.replaceAll(RegExp(r'[+-]00:?00$'), '');
      final dt = DateTime.tryParse(cleanDate) ?? DateTime.tryParse(dateStr);
      if (dt != null) {
        final day = dt.day.toString().padLeft(2, '0');
        final month = dt.month.toString().padLeft(2, '0');
        final year = dt.year.toString();
        orderDate = '$day/$month/$year';

        final hour = dt.hour.toString().padLeft(2, '0');
        final min = dt.minute.toString().padLeft(2, '0');
        final sec = dt.second.toString().padLeft(2, '0');
        orderTime = '$hour:$min:$sec';
      }
    }

    final rawPayment =
        (order.paymentMethod?['name'] ??
                order.paymentMethod?['type'] ??
                order.paymentMethod?['paymentType'] ??
                'COD')
            .toString();

    final isCod =
        rawPayment.toLowerCase().contains('cod') ||
        rawPayment.toLowerCase().contains('cash');
    final paymentShort = isCod ? 'Cash on Delivery' : rawPayment;
    final paymentFull = isCod
        ? 'Payment Method: Cash on Delivery (COD)'
        : 'Payment Method: $rawPayment';

    // 5. Resolve Customer & Address
    final addr = order.address;
    String getNonEmpty(List<dynamic> options) {
      for (var opt in options) {
        if (opt != null && opt.toString().trim().isNotEmpty) {
          return opt.toString().trim();
        }
      }
      return '';
    }

    final customerName = getNonEmpty([
      addr?['fullName'],
      addr?['full_name'],
      addr?['name'],
      addr?['receiverName'],
      addr?['userName'],
      user?.fullName,
      'Customer',
    ]);

    final doorName = getNonEmpty([
      addr?['buildingName'],
      addr?['building_name'],
      addr?['addressLine1'],
      addr?['street'],
      addr?['door'],
      'Door',
    ]);

    final streetName = getNonEmpty([
      addr?['streetName'],
      addr?['street_name'],
      addr?['addressLine2'],
    ]);
    final city = getNonEmpty([addr?['city']]);
    final state = getNonEmpty([addr?['state']]);
    final pincode = getNonEmpty([
      addr?['pincode'],
      addr?['pinCode'],
      addr?['zip'],
    ]);

    final addressParts = <String>[];
    if (streetName.isNotEmpty) addressParts.add(streetName);
    if (city.isNotEmpty) addressParts.add(city);
    if (state.isNotEmpty) addressParts.add(state);
    var line2 = addressParts.join(', ');
    if (pincode.isNotEmpty) {
      line2 = line2.isNotEmpty ? '$line2 - $pincode' : pincode;
    }
    if (line2.isEmpty) {
      line2 = 'Delivery, Thangachimadam, Tamilnadu - 623529';
    }

    final phone = getNonEmpty([
      addr?['phoneNumber'],
      addr?['phone_number'],
      addr?['mobileNumber'],
      addr?['mobile_number'],
      addr?['phone'],
      addr?['mobile'],
      user?.phoneNumber,
    ]);

    // 6. Calculations
    final origSub = order.calculatedOriginalSubTotal;
    final offerSavings = order.calculatedTotalSavings;
    final subTotal = order.calculatedSubTotal;
    final isFreeDelivery = order.isFreeDelivery;
    final deliveryFee = order.deliveryFee;
    final totalPayable = order.effectiveAmount;

    // Build PDF Page
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        theme: pw.ThemeData.withFont(
          base: fontRegular,
          bold: fontBold,
          fontFallback: fallbackFonts,
        ),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // ----------------- TOP HEADER ROW -----------------
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  // Left side: Logo + Contact Info
                  pw.Expanded(
                    flex: 12,
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        if (logoImage != null)
                          pw.Image(
                            logoImage,
                            width: 195,
                            height: 48,
                            fit: pw.BoxFit.contain,
                          )
                        else
                          pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text(
                                'Grace',
                                style: pw.TextStyle(
                                  fontSize: 22,
                                  fontWeight: pw.FontWeight.bold,
                                  color: PdfColor.fromHex('114224'),
                                ),
                              ),
                              pw.Text(
                                'Fresh Market',
                                style: pw.TextStyle(
                                  fontSize: 20,
                                  fontWeight: pw.FontWeight.bold,
                                  color: PdfColor.fromHex('2E7D32'),
                                ),
                              ),
                            ],
                          ),
                        pw.SizedBox(height: 8),

                        // Address Row
                        pw.Row(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Container(
                              width: 8,
                              height: 8,
                              margin: const pw.EdgeInsets.only(
                                top: 2,
                                right: 6,
                              ),
                              decoration: pw.BoxDecoration(
                                color: PdfColor.fromHex('1B5E20'),
                                shape: pw.BoxShape.circle,
                              ),
                            ),
                            pw.Expanded(
                              child: pw.Text(
                                'Nearby Yagappa Stop, Thangachimadam,\nRameswaram, Tamilnadu - 623529',
                                style: pw.TextStyle(
                                  fontSize: 8.5,
                                  color: PdfColor.fromHex('1F2937'),
                                  lineSpacing: 1.2,
                                ),
                              ),
                            ),
                          ],
                        ),
                        pw.SizedBox(height: 4),

                        // Phone Row
                        pw.Row(
                          children: [
                            pw.Container(
                              width: 8,
                              height: 8,
                              margin: const pw.EdgeInsets.only(right: 6),
                              decoration: pw.BoxDecoration(
                                color: PdfColor.fromHex('1B5E20'),
                                shape: pw.BoxShape.circle,
                              ),
                            ),
                            pw.Text(
                              '8015413414',
                              style: pw.TextStyle(
                                fontSize: 8.5,
                                color: PdfColor.fromHex('1F2937'),
                              ),
                            ),
                          ],
                        ),
                        pw.SizedBox(height: 4),

                        // Email Row
                        pw.Row(
                          children: [
                            pw.Container(
                              width: 8,
                              height: 8,
                              margin: const pw.EdgeInsets.only(right: 6),
                              decoration: pw.BoxDecoration(
                                color: PdfColor.fromHex('1B5E20'),
                                shape: pw.BoxShape.circle,
                              ),
                            ),
                            pw.Text(
                              'gracefreshmarket@gmail.com',
                              style: pw.TextStyle(
                                fontSize: 8.5,
                                color: PdfColor.fromHex('1F2937'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  pw.SizedBox(width: 14),

                  // Right side: Veggies Banner + Invoice Info Card
                  pw.Expanded(
                    flex: 11,
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        if (veggiesImage != null)
                          pw.Image(
                            veggiesImage,
                            width: 235,
                            height: 60,
                            fit: pw.BoxFit.contain,
                          )
                        else
                          pw.Container(
                            padding: const pw.EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 6,
                            ),
                            decoration: pw.BoxDecoration(
                              color: PdfColor.fromHex('114D25'),
                              borderRadius: pw.BorderRadius.circular(6),
                            ),
                            child: pw.Text(
                              'INVOICE',
                              style: pw.TextStyle(
                                color: PdfColors.white,
                                fontWeight: pw.FontWeight.bold,
                                fontSize: 14,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ),

                        pw.SizedBox(height: 6),

                        // Info Card
                        pw.Container(
                          width: 220,
                          padding: const pw.EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
                          decoration: pw.BoxDecoration(
                            color: PdfColors.white,
                            borderRadius: pw.BorderRadius.circular(8),
                            border: pw.Border.all(
                              color: PdfColor.fromHex('D1D5DB'),
                              width: 0.8,
                            ),
                          ),
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              // Invoice No
                              _buildCardRow(
                                'Invoice No',
                                displayOrderId,
                                isAccent: true,
                              ),
                              pw.SizedBox(height: 4),
                              // Order Date
                              _buildCardRow('Order Date', orderDate),
                              pw.SizedBox(height: 4),
                              // Order Time
                              _buildCardRow('Order Time', orderTime),
                              pw.SizedBox(height: 4),
                              // Payment
                              _buildCardRow('Payment', paymentShort),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              pw.SizedBox(height: 8),

              // Curved / Accent Divider Line under Header
              pw.Container(
                height: 1.5,
                decoration: pw.BoxDecoration(color: PdfColor.fromHex('2E7D32')),
              ),

              pw.SizedBox(height: 12),

              // ----------------- BILL TO / DELIVERY ADDRESS -----------------
              pw.Container(
                width: double.infinity,
                decoration: pw.BoxDecoration(
                  color: PdfColors.white,
                  borderRadius: pw.BorderRadius.circular(8),
                  border: pw.Border.all(
                    color: PdfColor.fromHex('C8E6C9'),
                    width: 0.9,
                  ),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    // Header Bar
                    pw.Container(
                      width: double.infinity,
                      padding: const pw.EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: pw.BoxDecoration(
                        color: PdfColor.fromHex('114D25'),
                        borderRadius: const pw.BorderRadius.only(
                          topLeft: pw.Radius.circular(7),
                          topRight: pw.Radius.circular(7),
                        ),
                      ),
                      child: pw.Row(
                        children: [
                          pw.Container(
                            width: 6,
                            height: 6,
                            margin: const pw.EdgeInsets.only(right: 6),
                            decoration: const pw.BoxDecoration(
                              color: PdfColors.white,
                              shape: pw.BoxShape.circle,
                            ),
                          ),
                          pw.Text(
                            'BILL TO / DELIVERY ADDRESS',
                            style: pw.TextStyle(
                              color: PdfColors.white,
                              fontWeight: pw.FontWeight.bold,
                              fontSize: 10,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Address Details
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(10),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            customerName,
                            style: pw.TextStyle(
                              fontSize: 10.5,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColor.fromHex('111827'),
                              fontFallback: fallbackFonts,
                            ),
                          ),
                          pw.SizedBox(height: 2),
                          if (doorName.isNotEmpty) ...[
                            pw.Text(
                              doorName,
                              style: pw.TextStyle(
                                fontSize: 9,
                                color: PdfColor.fromHex('374151'),
                                fontFallback: fallbackFonts,
                              ),
                            ),
                            pw.SizedBox(height: 2),
                          ],
                          pw.Text(
                            line2,
                            style: pw.TextStyle(
                              fontSize: 9,
                              color: PdfColor.fromHex('374151'),
                              fontFallback: fallbackFonts,
                            ),
                          ),
                          if (phone.isNotEmpty) ...[
                            pw.SizedBox(height: 2),
                            pw.Text(
                              'Phone: $phone',
                              style: pw.TextStyle(
                                fontSize: 9,
                                color: PdfColor.fromHex('374151'),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 12),

              // ----------------- ITEMS TABLE -----------------
              pw.Container(
                decoration: pw.BoxDecoration(
                  color: PdfColors.white,
                  borderRadius: pw.BorderRadius.circular(8),
                  border: pw.Border.all(
                    color: PdfColor.fromHex('D1D5DB'),
                    width: 0.8,
                  ),
                ),
                child: pw.Column(
                  children: [
                    // Table Header
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 7,
                      ),
                      decoration: pw.BoxDecoration(
                        color: PdfColor.fromHex('114D25'),
                        borderRadius: const pw.BorderRadius.only(
                          topLeft: pw.Radius.circular(7),
                          topRight: pw.Radius.circular(7),
                        ),
                      ),
                      child: pw.Row(
                        children: [
                          pw.SizedBox(
                            width: 30,
                            child: pw.Text(
                              '#',
                              style: pw.TextStyle(
                                color: PdfColors.white,
                                fontWeight: pw.FontWeight.bold,
                                fontSize: 9.5,
                              ),
                            ),
                          ),
                          pw.Expanded(
                            flex: 4,
                            child: pw.Text(
                              'Item',
                              style: pw.TextStyle(
                                color: PdfColors.white,
                                fontWeight: pw.FontWeight.bold,
                                fontSize: 9.5,
                              ),
                            ),
                          ),
                          pw.SizedBox(
                            width: 65,
                            child: pw.Center(
                              child: pw.Text(
                                'Qty',
                                style: pw.TextStyle(
                                  color: PdfColors.white,
                                  fontWeight: pw.FontWeight.bold,
                                  fontSize: 9.5,
                                ),
                              ),
                            ),
                          ),
                          pw.SizedBox(
                            width: 90,
                            child: pw.Center(
                              child: pw.Text(
                                'Unit Price',
                                style: pw.TextStyle(
                                  color: PdfColors.white,
                                  fontWeight: pw.FontWeight.bold,
                                  fontSize: 9.5,
                                ),
                              ),
                            ),
                          ),
                          pw.SizedBox(
                            width: 80,
                            child: pw.Align(
                              alignment: pw.Alignment.centerRight,
                              child: pw.Text(
                                'Amount',
                                style: pw.TextStyle(
                                  color: PdfColors.white,
                                  fontWeight: pw.FontWeight.bold,
                                  fontSize: 9.5,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Table Rows
                    ...List.generate(order.items.length, (index) {
                      final item = order.items[index];
                      final isEvenRow = index % 2 == 1;
                      final rowBg = isEvenRow
                          ? PdfColor.fromHex('F7FAF7')
                          : PdfColors.white;
                      final isLast = index == order.items.length - 1;

                      final unitPrice =
                          item.subcategoryAmount ??
                          (item.itemTotal /
                              (item.quantity > 0 ? item.quantity : 1));
                      final unitPriceStr = '₹${unitPrice.toStringAsFixed(2)}';
                      final priceWithUnit = item.isGramType
                          ? '$unitPriceStr / KG'
                          : unitPriceStr;

                      final itemImg = itemImagesMap[index];

                      return pw.Container(
                        padding: const pw.EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                        decoration: pw.BoxDecoration(
                          color: rowBg,
                          border: isLast
                              ? null
                              : pw.Border(
                                  bottom: pw.BorderSide(
                                    color: PdfColor.fromHex('E5E7EB'),
                                    width: 0.5,
                                  ),
                                ),
                          borderRadius: isLast
                              ? const pw.BorderRadius.only(
                                  bottomLeft: pw.Radius.circular(7),
                                  bottomRight: pw.Radius.circular(7),
                                )
                              : null,
                        ),
                        child: pw.Row(
                          crossAxisAlignment: pw.CrossAxisAlignment.center,
                          children: [
                            // # Col
                            pw.SizedBox(
                              width: 30,
                              child: pw.Text(
                                '${index + 1}',
                                style: pw.TextStyle(
                                  fontSize: 9.5,
                                  fontWeight: pw.FontWeight.bold,
                                  color: PdfColor.fromHex('111827'),
                                ),
                              ),
                            ),

                            // Item Col (Thumbnail + Name + Subtext)
                            pw.Expanded(
                              flex: 4,
                              child: pw.Row(
                                crossAxisAlignment:
                                    pw.CrossAxisAlignment.center,
                                children: [
                                  if (itemImg != null)
                                    pw.Container(
                                      width: 36,
                                      height: 36,
                                      margin: const pw.EdgeInsets.only(
                                        right: 8,
                                      ),
                                      decoration: pw.BoxDecoration(
                                        color: PdfColor.fromHex('F3F4F6'),
                                        borderRadius: pw.BorderRadius.circular(
                                          5,
                                        ),
                                      ),
                                      child: pw.ClipRRect(
                                        horizontalRadius: 5,
                                        verticalRadius: 5,
                                        child: pw.Image(
                                          itemImg,
                                          fit: pw.BoxFit.cover,
                                        ),
                                      ),
                                    )
                                  else
                                    pw.SizedBox(width: 4),

                                  pw.Expanded(
                                    child: pw.Column(
                                      crossAxisAlignment:
                                          pw.CrossAxisAlignment.start,
                                      mainAxisAlignment:
                                          pw.MainAxisAlignment.center,
                                      children: [
                                        pw.Text(
                                          item.subcategoryName ?? 'Item',
                                          style: pw.TextStyle(
                                            fontSize: 9.5,
                                            fontWeight: pw.FontWeight.bold,
                                            color: PdfColor.fromHex('111827'),
                                            fontFallback: fallbackFonts,
                                          ),
                                          maxLines: 2,
                                        ),
                                        if (item.hasOffer &&
                                            item.totalOfferAmount > 0) ...[
                                          pw.SizedBox(height: 2),
                                          pw.Text(
                                            'Original: ₹${item.totalOriginalAmount.toStringAsFixed(2)} | Savings: ₹${item.totalOfferAmount.toStringAsFixed(2)}',
                                            style: pw.TextStyle(
                                              fontSize: 7.5,
                                              color: PdfColor.fromHex('6B7280'),
                                              fontFallback: fallbackFonts,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Qty Col
                            pw.SizedBox(
                              width: 65,
                              child: pw.Center(
                                child: pw.Text(
                                  item.formattedQuantityDisplay,
                                  style: pw.TextStyle(
                                    fontSize: 9.5,
                                    color: PdfColor.fromHex('111827'),
                                  ),
                                ),
                              ),
                            ),

                            // Unit Price Col
                            pw.SizedBox(
                              width: 90,
                              child: pw.Center(
                                child: pw.Text(
                                  priceWithUnit,
                                  style: pw.TextStyle(
                                    fontSize: 9.5,
                                    color: PdfColor.fromHex('111827'),
                                  ),
                                ),
                              ),
                            ),

                            // Amount Col
                            pw.SizedBox(
                              width: 80,
                              child: pw.Align(
                                alignment: pw.Alignment.centerRight,
                                child: pw.Text(
                                  '₹${item.itemTotal.toStringAsFixed(2)}',
                                  style: pw.TextStyle(
                                    fontSize: 9.5,
                                    fontWeight: pw.FontWeight.bold,
                                    color: PdfColor.fromHex('111827'),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),

              pw.SizedBox(height: 12),

              // ----------------- CALCULATIONS SUMMARY BOX -----------------
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: pw.BoxDecoration(
                  color: PdfColors.white,
                  borderRadius: pw.BorderRadius.circular(8),
                  border: pw.Border.all(
                    color: PdfColor.fromHex('D1D5DB'),
                    width: 0.8,
                  ),
                ),
                child: pw.Column(
                  children: [
                    if (offerSavings > 0) ...[
                      // Original Subtotal
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text(
                            'Original Subtotal',
                            style: pw.TextStyle(
                              fontSize: 9.5,
                              color: PdfColor.fromHex('4B5563'),
                            ),
                          ),
                          pw.Text(
                            '₹${origSub.toStringAsFixed(2)}',
                            style: pw.TextStyle(
                              fontSize: 9.5,
                              color: PdfColor.fromHex('6B7280'),
                            ),
                          ),
                        ],
                      ),
                      pw.SizedBox(height: 6),

                      // Offer Savings
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text(
                            'Offer Savings',
                            style: pw.TextStyle(
                              fontSize: 9.5,
                              color: PdfColor.fromHex('4B5563'),
                            ),
                          ),
                          pw.Text(
                            '-₹${offerSavings.toStringAsFixed(2)}',
                            style: pw.TextStyle(
                              fontSize: 9.5,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColor.fromHex('1B5E20'),
                            ),
                          ),
                        ],
                      ),
                      pw.SizedBox(height: 6),
                    ],

                    // Subtotal Row with highlighted background
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 5,
                      ),
                      decoration: pw.BoxDecoration(
                        color: PdfColor.fromHex('EEF3EE'),
                        borderRadius: pw.BorderRadius.circular(5),
                      ),
                      child: pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text(
                            'Subtotal (${order.items.length} items)',
                            style: pw.TextStyle(
                              fontSize: 9.5,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColor.fromHex('111827'),
                            ),
                          ),
                          pw.Text(
                            '₹${subTotal.toStringAsFixed(2)}',
                            style: pw.TextStyle(
                              fontSize: 9.5,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColor.fromHex('111827'),
                            ),
                          ),
                        ],
                      ),
                    ),

                    pw.SizedBox(height: 6),

                    // Delivery Fee
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(
                          'Delivery Fee',
                          style: pw.TextStyle(
                            fontSize: 9.5,
                            color: PdfColor.fromHex('4B5563'),
                          ),
                        ),
                        if (isFreeDelivery)
                          pw.Text(
                            'FREE',
                            style: pw.TextStyle(
                              fontSize: 9.5,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColor.fromHex('1B5E20'),
                            ),
                          )
                        else
                          pw.Text(
                            '₹${deliveryFee.toStringAsFixed(2)}',
                            style: pw.TextStyle(
                              fontSize: 9.5,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColor.fromHex('111827'),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 10),

              // ----------------- TOTAL PAYABLE BANNER -----------------
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: pw.BoxDecoration(
                  color: PdfColor.fromHex('114D25'),
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'TOTAL PAYABLE',
                      style: pw.TextStyle(
                        color: PdfColors.white,
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 12.5,
                        letterSpacing: 0.5,
                      ),
                    ),
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      decoration: pw.BoxDecoration(
                        color: PdfColors.white,
                        borderRadius: pw.BorderRadius.circular(6),
                      ),
                      child: pw.Text(
                        '₹${totalPayable.toStringAsFixed(2)}',
                        style: pw.TextStyle(
                          color: PdfColor.fromHex('114D25'),
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 15.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 10),

              // ----------------- PAYMENT METHOD FOOTER -----------------
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 7,
                ),
                decoration: pw.BoxDecoration(
                  color: PdfColor.fromHex('EBF1EB'),
                  borderRadius: pw.BorderRadius.circular(6),
                ),
                child: pw.Row(
                  children: [
                    pw.Container(
                      width: 14,
                      height: 10,
                      margin: const pw.EdgeInsets.only(right: 8),
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(
                          color: PdfColor.fromHex('1B5E20'),
                          width: 1.2,
                        ),
                        borderRadius: pw.BorderRadius.circular(2),
                      ),
                    ),
                    pw.Text(
                      paymentFull,
                      style: pw.TextStyle(
                        fontSize: 9.5,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColor.fromHex('1F2937'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildCardRow(
    String label,
    String value, {
    bool isAccent = false,
  }) {
    return pw.Row(
      children: [
        pw.Container(
          width: 5,
          height: 5,
          margin: const pw.EdgeInsets.only(right: 6),
          decoration: pw.BoxDecoration(
            color: PdfColor.fromHex('1B5E20'),
            shape: pw.BoxShape.circle,
          ),
        ),
        pw.SizedBox(
          width: 65,
          child: pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: 8.5,
              color: PdfColor.fromHex('374151'),
            ),
          ),
        ),
        pw.Text(
          ' :  ',
          style: pw.TextStyle(fontSize: 8.5, color: PdfColor.fromHex('374151')),
        ),
        pw.Expanded(
          child: pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 8.5,
              fontWeight: pw.FontWeight.bold,
              color: isAccent
                  ? PdfColor.fromHex('1B5E20')
                  : PdfColor.fromHex('1F2937'),
            ),
          ),
        ),
      ],
    );
  }
}
