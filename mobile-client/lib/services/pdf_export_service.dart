import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

/// Data transfer object for a single bar/slot in the crying trends chart.
class ReportTrendItem {
  const ReportTrendItem({
    required this.label,
    required this.count,
  });

  final String label;
  final int count;
}

/// Data transfer object for a single cause share in the cause distribution.
class ReportCauseItem {
  const ReportCauseItem({
    required this.label,
    required this.percentage,
  });

  final String label;
  final double percentage;
}

/// Generates and exports/shares the Mahd PDF report containing
/// the monitoring summary, crying trends, and cause distribution.
class PdfExportService {
  PdfExportService._();

  static final PdfExportService instance = PdfExportService._();

  // ── Mahd PDF Color Palette (matching AppColors) ──────────────────
  static const PdfColor _bgCream =
      PdfColor.fromInt(0xFFFBF5EF);

  static const PdfColor _bgBeige =
      PdfColor.fromInt(0xFFF4EBE2);

  static const PdfColor _cardSurface =
      PdfColor.fromInt(0xFFFFFFFF);

  static const PdfColor _primary =
      PdfColor.fromInt(0xFFCE7E52);

  static const PdfColor _primaryLight =
      PdfColor.fromInt(0xFFE9A97F);

  static const PdfColor _iconBg =
      PdfColor.fromInt(0xFFFDEADF);

  static const PdfColor _textPrimary =
      PdfColor.fromInt(0xFF3A2B23);

  static const PdfColor _textSecondary =
      PdfColor.fromInt(0xFF7C6355);

  static const PdfColor _borderBeige =
      PdfColor.fromInt(0xFFEFDDD0);

  static const PdfColor _borderLight =
      PdfColor.fromInt(0xFFF1E4D9);

  static const PdfColor _success =
      PdfColor.fromInt(0xFF7E9B7A);

  static const PdfColor _successBg =
      PdfColor.fromInt(0xFFEDF2EB);

  /// Builds the PDF document bytes and triggers the platform share/download sheet.
  Future<void> exportMonitoringReport({
    required String periodLabel,
    required String dateRangeLabel,
    required String totalCryEvents,
    required String monitoringDuration,
    required String latestCause,
    required String chartTitle,
    String? peakSlotHint,
    required List<ReportTrendItem> trendStats,
    required List<ReportCauseItem> causeStats,
  }) async {
    final pdfBytes = await generateReportBytes(
      periodLabel: periodLabel,
      dateRangeLabel: dateRangeLabel,
      totalCryEvents: totalCryEvents,
      monitoringDuration: monitoringDuration,
      latestCause: latestCause,
      chartTitle: chartTitle,
      peakSlotHint: peakSlotHint,
      trendStats: trendStats,
      causeStats: causeStats,
    );

    await Printing.sharePdf(
      bytes: pdfBytes,
      filename: 'mahd_monitoring_report.pdf',
    );
  }

  /// Generates the raw PDF bytes for the monitoring statistics report.
  Future<Uint8List> generateReportBytes({
    required String periodLabel,
    required String dateRangeLabel,
    required String totalCryEvents,
    required String monitoringDuration,
    required String latestCause,
    required String chartTitle,
    String? peakSlotHint,
    required List<ReportTrendItem> trendStats,
    required List<ReportCauseItem> causeStats,
    pw.Font? customRegularFont,
    pw.Font? customBoldFont,
  }) async {
    final regularFont =
        customRegularFont ??
        await PdfGoogleFonts.iBMPlexSansArabicRegular();

    final boldFont =
        customBoldFont ??
        await PdfGoogleFonts.iBMPlexSansArabicBold();

    pw.MemoryImage? logoImage;

    try {
      final logoBytes = await rootBundle.load(
        'assets/images/mahd-logo.png',
      );

      logoImage = pw.MemoryImage(
        logoBytes.buffer.asUint8List(),
      );
    } catch (_) {
      logoImage = null;
    }

    final doc = pw.Document(
      title: 'تقرير المراقبة والإحصائيات - مهد',
      author: 'تطبيق مهد',
    );

    final generatedAt = _formatGeneratedDate(
      DateTime.now(),
    );

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(
          34,
          28,
          34,
          24,
        ),
        theme: pw.ThemeData.withFont(
          base: regularFont,
          bold: boldFont,
          fontFallback: [
            pw.Font.helvetica(),
          ],
        ),
        build: (context) {
          return pw.Directionality(
            textDirection: pw.TextDirection.rtl,
            child: pw.Column(
              crossAxisAlignment:
                  pw.CrossAxisAlignment.stretch,
              children: [
                // ── 1. Report Header ───────────────────────────────────────
                _buildHeader(
                  logoImage: logoImage,
                  generatedAt: generatedAt,
                ),

                pw.SizedBox(height: 14),

                _buildDivider(),

                pw.SizedBox(height: 12),

                // ── Report information ─────────────────────────────────────
                _buildReportInformation(
                  periodLabel: periodLabel,
                  dateRangeLabel:
                      _toArabicDigits(dateRangeLabel),
                ),

                pw.SizedBox(height: 14),

                // ── 2. Summary Tiles ───────────────────────────────────────
                _buildSectionTitle(
                  'ملخص المراقبة',
                ),

                pw.SizedBox(height: 7),

                _buildSummaryTable(
                  totalCryEvents:
                      _toArabicDigits(totalCryEvents),
                  monitoringDuration:
                      _toArabicDigits(monitoringDuration),
                  latestCause: latestCause,
                ),

                pw.SizedBox(height: 15),

                // ── 3. Crying Trends Chart ─────────────────────────────────
                _buildSectionTitle(
                  'نشاط البكاء',
                ),

                pw.SizedBox(height: 5),

                if (peakSlotHint != null &&
                    peakSlotHint.isNotEmpty)
                  pw.Text(
                    _toArabicDigits(
                      peakSlotHint,
                    ),
                    style:
                        const pw.TextStyle(
                      fontSize: 9,
                      color:
                          _textSecondary,
                    ),
                  ),

                if (peakSlotHint != null &&
                    peakSlotHint.isNotEmpty)
                  pw.SizedBox(height: 5),

                _buildTrendsChart(
                  chartTitle: chartTitle,
                  trendStats: trendStats,
                ),

                pw.SizedBox(height: 15),

                // ── 4. Cause Distribution Card ─────────────────────────────
                _buildSectionTitle(
                  'توزيع الأسباب المحتملة',
                ),

                pw.SizedBox(height: 7),

                _buildCausesTable(
                  causeStats: causeStats,
                ),

                pw.Spacer(),

                // ── Report disclaimer ───────────────────────────────────────
                _buildDisclaimer(),

                pw.SizedBox(height: 10),

                _buildDivider(),

                pw.SizedBox(height: 6),

                // ── Footer ──────────────────────────────────────────────────
                pw.Row(
                  mainAxisAlignment:
                      pw.MainAxisAlignment
                          .spaceBetween,
                  children: [
                    pw.Text(
                      'تطبيق مهد — مراقبة ذكية للأطفال',
                      style:
                          const pw.TextStyle(
                        fontSize: 8,
                        color:
                            _textSecondary,
                      ),
                    ),
                    pw.Text(
                      'تقرير تم إنشاؤه بواسطة مهد',
                      style:
                          const pw.TextStyle(
                        fontSize: 8,
                        color:
                            _textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );

    return doc.save();
  }

  // ──────────────────────────────────────────────────────────────────
  //  PDF Building Blocks
  // ──────────────────────────────────────────────────────────────────

  pw.Widget _buildHeader({
    required pw.MemoryImage? logoImage,
    required String generatedAt,
  }) {
    return pw.Row(
      crossAxisAlignment:
          pw.CrossAxisAlignment.center,
      children: [
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment:
                pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'تقرير مراقبة الطفل',
                style:
                    const pw.TextStyle(
                  fontSize: 20,
                  fontWeight:
                      pw.FontWeight.bold,
                  color:
                      _textPrimary,
                ),
              ),
              pw.SizedBox(height: 3),
              pw.Text(
                'ملخص المراقبة وتحليل أنماط البكاء',
                style:
                    const pw.TextStyle(
                  fontSize: 9.5,
                  color:
                      _textSecondary,
                ),
              ),
              pw.SizedBox(height: 5),
              pw.Text(
                'تاريخ إصدار التقرير: $generatedAt',
                style:
                    const pw.TextStyle(
                  fontSize: 8.5,
                  color:
                      _textSecondary,
                ),
              ),
            ],
          ),
        ),

        if (logoImage != null)
          pw.SizedBox(
            width: 65,
            height: 42,
            child: pw.Image(
              logoImage,
              fit: pw.BoxFit.contain,
            ),
          )
        else
          pw.Text(
            'مهد',
            style:
                const pw.TextStyle(
              fontSize: 18,
              fontWeight:
                  pw.FontWeight.bold,
              color: _primary,
            ),
          ),
      ],
    );
  }

  pw.Widget _buildDivider() {
    return pw.Container(
      height: 1,
      color: _borderBeige,
    );
  }

  pw.Widget _buildReportInformation({
    required String periodLabel,
    required String dateRangeLabel,
  }) {
    return pw.Table(
      border: pw.TableBorder.all(
        color: _borderLight,
        width: 0.7,
      ),
      columnWidths: const {
        0: pw.FlexColumnWidth(2),
        1: pw.FlexColumnWidth(1),
        2: pw.FlexColumnWidth(2),
        3: pw.FlexColumnWidth(1),
      },
      children: [
        pw.TableRow(
          decoration:
              const pw.BoxDecoration(
            color: _bgCream,
          ),
          children: [
            // Because PDF tables keep their physical column order,
            // the cells are arranged so the Arabic report reads
            // correctly from right to left:
            // الفترة | القيمة | نوع التقرير | القيمة
            _buildTableCell(
              periodLabel,
            ),
            _buildTableCell(
              'نوع التقرير',
              bold: true,
              background:
                  _bgBeige,
            ),
            _buildTableCell(
              dateRangeLabel,
            ),
            _buildTableCell(
              'الفترة',
              bold: true,
              background:
                  _bgBeige,
            ),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildSectionTitle(
    String title,
  ) {
    return pw.Row(
      children: [
        pw.Container(
          width: 4,
          height: 17,
          color: _primary,
        ),
        pw.SizedBox(width: 7),
        pw.Text(
          title,
          style:
              const pw.TextStyle(
            fontSize: 12,
            fontWeight:
                pw.FontWeight.bold,
            color: _textPrimary,
          ),
        ),
      ],
    );
  }

  pw.Widget _buildSummaryTable({
    required String totalCryEvents,
    required String monitoringDuration,
    required String latestCause,
  }) {
    return pw.Table(
      border: pw.TableBorder.all(
        color: _borderLight,
        width: 0.7,
      ),
      columnWidths: const {
        0: pw.FlexColumnWidth(1),
        1: pw.FlexColumnWidth(1),
        2: pw.FlexColumnWidth(1),
      },
      children: [
        pw.TableRow(
          decoration:
              const pw.BoxDecoration(
            color: _bgBeige,
          ),
          children: [
            _buildTableCell(
              'أحداث البكاء',
              bold: true,
              centered: true,
            ),
            _buildTableCell(
              'مدة المراقبة',
              bold: true,
              centered: true,
            ),
            _buildTableCell(
              'آخر سبب محتمل',
              bold: true,
              centered: true,
            ),
          ],
        ),
        pw.TableRow(
          children: [
            _buildTableCell(
              totalCryEvents,
              centered: true,
              valueStyle: true,
            ),
            _buildTableCell(
              monitoringDuration,
              centered: true,
              valueStyle: true,
            ),
            _buildTableCell(
              latestCause,
              centered: true,
              valueStyle: true,
            ),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildTableCell(
    String text, {
    bool bold = false,
    bool centered = false,
    bool valueStyle = false,
    PdfColor? background,
  }) {
    return pw.Container(
      color: background,
      padding:
          const pw.EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 7,
      ),
      alignment: centered
          ? pw.Alignment.center
          : pw.Alignment.centerRight,
      child: pw.Text(
        _toArabicDigits(text),
        textAlign: centered
            ? pw.TextAlign.center
            : pw.TextAlign.right,
        style: pw.TextStyle(
          fontSize:
              valueStyle ? 11 : 9.5,
          fontWeight:
              bold || valueStyle
                  ? pw.FontWeight.bold
                  : pw.FontWeight.normal,
          color: valueStyle
              ? _primary
              : _textPrimary,
        ),
      ),
    );
  }

  pw.Widget _buildTrendsChart({
    required String chartTitle,
    required List<ReportTrendItem> trendStats,
  }) {
    final maxCount =
        trendStats.isEmpty
            ? 1
            : trendStats
                .map(
                  (e) => e.count,
                )
                .reduce(
                  (a, b) =>
                      a > b ? a : b,
                )
                .clamp(
                  1,
                  999,
                );

    const double maxBarHeight = 82;

    return pw.Container(
      width: double.infinity,
      padding:
          const pw.EdgeInsets.fromLTRB(
        12,
        10,
        12,
        10,
      ),
      decoration:
          pw.BoxDecoration(
        color: _cardSurface,

        // Simple report-style border around the chart area.
        border: pw.Border.all(
          color: _borderBeige,
          width: 0.8,
        ),
      ),
      child: pw.Column(
        crossAxisAlignment:
            pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            chartTitle,
            style:
                const pw.TextStyle(
              fontSize: 9.5,
              color:
                  _textSecondary,
            ),
          ),

          pw.SizedBox(height: 10),

          pw.Container(
            width: double.infinity,
            padding:
                const pw.EdgeInsets.fromLTRB(
              6,
              4,
              6,
              0,
            ),
            decoration:
                const pw.BoxDecoration(
              border: pw.Border(
                left: pw.BorderSide(
                  color: _borderLight,
                  width: 0.7,
                ),
                right: pw.BorderSide(
                  color: _borderLight,
                  width: 0.7,
                ),
                bottom: pw.BorderSide(
                  color: _borderBeige,
                  width: 0.9,
                ),
              ),
            ),
            child: pw.Row(
              mainAxisAlignment:
                  pw.MainAxisAlignment
                      .spaceAround,
              crossAxisAlignment:
                  pw.CrossAxisAlignment
                      .end,
              children:
                  trendStats.map(
                (stat) {
                  final ratio =
                      stat.count /
                          maxCount;

                  final barHeight =
                      (ratio *
                              maxBarHeight)
                          .clamp(
                    2.0,
                    maxBarHeight,
                  );

                  final isPeak =
                      stat.count ==
                              maxCount &&
                          maxCount > 0;

                  return pw.Column(
                    mainAxisSize:
                        pw.MainAxisSize.min,
                    children: [
                      pw.Text(
                        _toArabicDigits(
                          '${stat.count}',
                        ),
                        style:
                            pw.TextStyle(
                          fontSize: 8,
                          fontWeight:
                              isPeak
                                  ? pw.FontWeight
                                      .bold
                                  : pw.FontWeight
                                      .normal,
                          color: isPeak
                              ? _primary
                              : _textSecondary,
                        ),
                      ),

                      pw.SizedBox(
                        height: 3,
                      ),

                      pw.Container(
                        width: 22,
                        height:
                            maxBarHeight,
                        alignment:
                            pw.Alignment
                                .bottomCenter,
                        child:
                            pw.Container(
                          width: 16,
                          height:
                              stat.count ==
                                      0
                                  ? 1
                                  : barHeight,
                          color: isPeak
                              ? _primary
                              : _primaryLight,
                        ),
                      ),

                      pw.SizedBox(
                        height: 4,
                      ),

                      pw.Text(
                        _toArabicDigits(
                          stat.label,
                        ),
                        style:
                            const pw.TextStyle(
                          fontSize: 8,
                          color:
                              _textSecondary,
                        ),
                      ),

                      pw.SizedBox(
                        height: 4,
                      ),
                    ],
                  );
                },
              ).toList(),
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildCausesTable({
    required List<ReportCauseItem> causeStats,
  }) {
    final maxPct =
        causeStats.isEmpty
            ? 0
            : causeStats
                .map(
                  (e) => e.percentage,
                )
                .reduce(
                  (a, b) =>
                      a > b ? a : b,
                );

    return pw.Table(
      border: pw.TableBorder(
        horizontalInside:
            const pw.BorderSide(
          color: _borderLight,
          width: 0.6,
        ),
        bottom:
            const pw.BorderSide(
          color: _borderLight,
          width: 0.6,
        ),
      ),
      columnWidths: const {
        0: pw.FlexColumnWidth(3),
        1: pw.FlexColumnWidth(1),
        2: pw.FlexColumnWidth(4),
      },
      children: [
        pw.TableRow(
          decoration:
              const pw.BoxDecoration(
            color: _bgBeige,
          ),
          children: [
            _buildTableCell(
              'السبب المحتمل',
              bold: true,
            ),
            _buildTableCell(
              'النسبة',
              bold: true,
              centered: true,
            ),
            _buildTableCell(
              'التوزيع',
              bold: true,
            ),
          ],
        ),
        ...causeStats.map(
          (stat) {
            final percentage =
                (stat.percentage *
                        100)
                    .round();

            final isTop =
                stat.percentage ==
                    maxPct;

            return pw.TableRow(
              children: [
                _buildTableCell(
                  stat.label,
                  bold: isTop,
                ),
                _buildTableCell(
                  '${_toArabicDigits('$percentage')}٪',
                  centered: true,
                  bold: isTop,
                ),
                pw.Padding(
                  padding:
                      const pw.EdgeInsets
                          .symmetric(
                    horizontal: 8,
                    vertical: 9,
                  ),
                  child: pw.Container(
                    height: 6,
                    decoration:
                        pw.BoxDecoration(
                      color: _bgBeige,
                      borderRadius:
                          pw.BorderRadius
                              .circular(
                        3,
                      ),
                    ),
                    child: pw.Row(
                      children: [
                        pw.Expanded(
                          flex:
                              percentage
                                  .clamp(
                            1,
                            100,
                          ),
                          child:
                              pw.Container(
                            color: isTop
                                ? _primary
                                : _primaryLight,
                          ),
                        ),
                        if (percentage <
                            100)
                          pw.Expanded(
                            flex:
                                (100 -
                                        percentage)
                                    .clamp(
                              1,
                              100,
                            ),
                            child:
                                pw.SizedBox(),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  pw.Widget _buildDisclaimer() {
    return pw.Container(
      width: double.infinity,
      padding:
          const pw.EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 8,
      ),
      decoration:
          const pw.BoxDecoration(
        color: _bgCream,
        border: pw.Border(
          right: pw.BorderSide(
            color: _success,
            width: 3,
          ),
        ),
      ),
      child: pw.Text(
        'ملاحظة: يعرض هذا التقرير ملخصًا لبيانات المراقبة المسجلة بواسطة مهد. '
        'تصنيفات أسباب البكاء احتمالية ولا تمثل تشخيصًا طبيًا أو بديلًا عن استشارة المختص.',
        style:
            const pw.TextStyle(
          fontSize: 8.5,
          height: 1.5,
          color:
              _textSecondary,
        ),
      ),
    );
  }

  String _formatGeneratedDate(
    DateTime date,
  ) {
    const months = [
      'يناير',
      'فبراير',
      'مارس',
      'أبريل',
      'مايو',
      'يونيو',
      'يوليو',
      'أغسطس',
      'سبتمبر',
      'أكتوبر',
      'نوفمبر',
      'ديسمبر',
    ];

    final month =
        months[date.month - 1];

    return '${_toArabicDigits('${date.day}')} '
        '$month '
        '${_toArabicDigits('${date.year}')}';
  }

  String _toArabicDigits(
    String value,
  ) {
    const westernDigits = [
      '0',
      '1',
      '2',
      '3',
      '4',
      '5',
      '6',
      '7',
      '8',
      '9',
    ];

    const arabicDigits = [
      '٠',
      '١',
      '٢',
      '٣',
      '٤',
      '٥',
      '٦',
      '٧',
      '٨',
      '٩',
    ];

    var result = value;

    for (var i = 0;
        i < westernDigits.length;
        i++) {
      result = result.replaceAll(
        westernDigits[i],
        arabicDigits[i],
      );
    }

    return result;
  }
}