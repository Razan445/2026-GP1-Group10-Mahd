import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../screens/history/history_screen.dart';

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

/// Generates and exports/shares the comprehensive Mahd PDF report containing
/// both monitoring statistics and chronological event history.
class PdfExportService {
  PdfExportService._();

  static final PdfExportService instance = PdfExportService._();

  // ── Mahd PDF Color Palette (matching AppColors) ──────────────────
  static const PdfColor _bgCream = PdfColor.fromInt(0xFFFBF5EF);
  static const PdfColor _bgBeige = PdfColor.fromInt(0xFFF4EBE2);
  static const PdfColor _cardSurface = PdfColor.fromInt(0xFFFFFFFF);
  static const PdfColor _primary = PdfColor.fromInt(0xFFCE7E52);
  static const PdfColor _primaryLight = PdfColor.fromInt(0xFFE9A97F);
  static const PdfColor _iconBg = PdfColor.fromInt(0xFFFDEADF);
  static const PdfColor _textPrimary = PdfColor.fromInt(0xFF3A2B23);
  static const PdfColor _textSecondary = PdfColor.fromInt(0xFF7C6355);
  static const PdfColor _borderBeige = PdfColor.fromInt(0xFFEFDDD0);
  static const PdfColor _borderLight = PdfColor.fromInt(0xFFF1E4D9);
  static const PdfColor _alert = PdfColor.fromInt(0xFFBE5A43);
  static const PdfColor _alertBg = PdfColor.fromInt(0xFFFDF1EC);
  static const PdfColor _alertBorder = PdfColor.fromInt(0xFFF1CFC6);
  static const PdfColor _success = PdfColor.fromInt(0xFF7E9B7A);
  static const PdfColor _successBg = PdfColor.fromInt(0xFFEDF2EB);

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
    required List<HistoryEvent> historyEvents,
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
      historyEvents: historyEvents,
    );

    await Printing.sharePdf(
      bytes: pdfBytes,
      filename: 'mahd_monitoring_report.pdf',
    );
  }

  /// Generates the raw PDF bytes for the monitoring history & statistics report.
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
    required List<HistoryEvent> historyEvents,
    pw.Font? customRegularFont,
    pw.Font? customBoldFont,
  }) async {
    final regularFont =
        customRegularFont ?? await PdfGoogleFonts.iBMPlexSansArabicRegular();
    final boldFont =
        customBoldFont ?? await PdfGoogleFonts.iBMPlexSansArabicBold();

    pw.MemoryImage? logoImage;
    try {
      final logoBytes = await rootBundle.load('assets/images/mahd-logo.png');
      logoImage = pw.MemoryImage(logoBytes.buffer.asUint8List());
    } catch (_) {
      logoImage = null;
    }

    // Sort events chronologically (newest first)
    final sortedEvents = List<HistoryEvent>.from(historyEvents)
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

    final doc = pw.Document(
      title: 'تقرير المراقبة والإحصائيات - مهد',
      author: 'تطبيق مهد',
    );

    doc.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          pageFormat: PdfPageFormat.a4,
          textDirection: pw.TextDirection.rtl,
          margin: const pw.EdgeInsets.all(28),
          theme: pw.ThemeData.withFont(
            base: regularFont,
            bold: boldFont,
            fontFallback: [pw.Font.helvetica()],
          ),
          buildBackground: (_) => pw.FullPage(
            ignoreMargins: true,
            child: pw.Container(color: _bgCream),
          ),
        ),
        footer: (context) => pw.Container(
          margin: const pw.EdgeInsets.only(top: 12),
          padding: const pw.EdgeInsets.only(top: 8),
          decoration: const pw.BoxDecoration(
            border: pw.Border(
              top: pw.BorderSide(color: _borderBeige, width: 0.8),
            ),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'تطبيق مهد — مراقبة صوتية ذكية للأطفال',
                style: const pw.TextStyle(
                  fontSize: 9.5,
                  color: _textSecondary,
                ),
              ),
              pw.Text(
                'صفحة ${context.pageNumber} من ${context.pagesCount}',
                style: const pw.TextStyle(
                  fontSize: 9.5,
                  color: _textSecondary,
                ),
              ),
            ],
          ),
        ),
        build: (context) => [
          // ── 1. Report Header ───────────────────────────────────────
          _buildHeader(
            logoImage: logoImage,
            periodLabel: periodLabel,
            dateRangeLabel: dateRangeLabel,
          ),
          pw.SizedBox(height: 16),

          // ── 2. Summary Tiles ───────────────────────────────────────
          _buildSectionTitle('ملخص المراقبة'),
          pw.SizedBox(height: 8),
          _buildSummaryRow(
            totalCryEvents: totalCryEvents,
            monitoringDuration: monitoringDuration,
            latestCause: latestCause,
          ),
          pw.SizedBox(height: 16),

          // ── 3. Crying Trends Chart & Causes Side-by-Side / Stacked ─
          _buildTrendsCard(
            chartTitle: chartTitle,
            peakSlotHint: peakSlotHint,
            trendStats: trendStats,
          ),
          pw.SizedBox(height: 14),

          // ── 4. Cause Distribution Card ─────────────────────────────
          _buildCausesCard(causeStats: causeStats),
          pw.SizedBox(height: 18),

          // ── 5. Chronological Monitoring History ────────────────────
          _buildSectionTitle('سجل الأحداث المرصودة (الترتيب الزمني)'),
          pw.SizedBox(height: 8),
          ..._buildHistoryEventsList(sortedEvents),
        ],
      ),
    );

    return doc.save();
  }

  // ──────────────────────────────────────────────────────────────────
  //  PDF Building Blocks
  // ──────────────────────────────────────────────────────────────────

  pw.Widget _buildHeader({
    required pw.MemoryImage? logoImage,
    required String periodLabel,
    required String dateRangeLabel,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: pw.BoxDecoration(
        color: _cardSurface,
        borderRadius: pw.BorderRadius.circular(16),
        border: pw.Border.all(color: _borderBeige, width: 1),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'تقرير المراقبة والإحصائيات',
                style: const pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                  color: _textPrimary,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                'سجل الأحداث المرصودة وملخص أنماط بكاء الطفل',
                style: const pw.TextStyle(
                  fontSize: 11,
                  color: _textSecondary,
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Row(
                children: [
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: pw.BoxDecoration(
                      color: _primary,
                      borderRadius: pw.BorderRadius.circular(20),
                    ),
                    child: pw.Text(
                      'التقرير: $periodLabel',
                      style: const pw.TextStyle(
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.white,
                      ),
                    ),
                  ),
                  pw.SizedBox(width: 8),
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: pw.BoxDecoration(
                      color: _bgBeige,
                      borderRadius: pw.BorderRadius.circular(20),
                    ),
                    child: pw.Text(
                      'الفترة: $dateRangeLabel',
                      style: const pw.TextStyle(
                        fontSize: 10,
                        color: _textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (logoImage != null)
            pw.Container(
              width: 56,
              height: 56,
              alignment: pw.Alignment.center,
              child: pw.Image(logoImage, fit: pw.BoxFit.contain),
            )
          else
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 8,
              ),
              decoration: pw.BoxDecoration(
                color: _iconBg,
                borderRadius: pw.BorderRadius.circular(12),
              ),
              child: pw.Text(
                'مهد',
                style: const pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                  color: _primary,
                ),
              ),
            ),
        ],
      ),
    );
  }

  pw.Widget _buildSectionTitle(String title) {
    return pw.Text(
      title,
      style: const pw.TextStyle(
        fontSize: 14,
        fontWeight: pw.FontWeight.bold,
        color: _textPrimary,
      ),
    );
  }

  pw.Widget _buildSummaryRow({
    required String totalCryEvents,
    required String monitoringDuration,
    required String latestCause,
  }) {
    return pw.Row(
      children: [
        pw.Expanded(
          child: _buildSummaryTile(
            label: 'أحداث البكاء',
            value: totalCryEvents,
            accentBg: _iconBg,
            accentColor: _primary,
          ),
        ),
        pw.SizedBox(width: 10),
        pw.Expanded(
          child: _buildSummaryTile(
            label: 'مدة المراقبة',
            value: monitoringDuration,
            accentBg: _successBg,
            accentColor: _success,
          ),
        ),
        pw.SizedBox(width: 10),
        pw.Expanded(
          child: _buildSummaryTile(
            label: 'آخر سبب محتمل',
            value: latestCause,
            accentBg: _bgBeige,
            accentColor: _primaryLight,
          ),
        ),
      ],
    );
  }

  pw.Widget _buildSummaryTile({
    required String label,
    required String value,
    required PdfColor accentBg,
    required PdfColor accentColor,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: pw.BoxDecoration(
        color: _cardSurface,
        borderRadius: pw.BorderRadius.circular(14),
        border: pw.Border.all(color: _borderLight, width: 1),
      ),
      child: pw.Row(
        children: [
          pw.Container(
            width: 10,
            height: 32,
            decoration: pw.BoxDecoration(
              color: accentColor,
              borderRadius: pw.BorderRadius.circular(5),
            ),
          ),
          pw.SizedBox(width: 10),
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  value,
                  style: const pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                    color: _textPrimary,
                  ),
                ),
                pw.SizedBox(height: 2),
                pw.Text(
                  label,
                  style: const pw.TextStyle(
                    fontSize: 10,
                    color: _textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildTrendsCard({
    required String chartTitle,
    required String? peakSlotHint,
    required List<ReportTrendItem> trendStats,
  }) {
    final maxCount = trendStats.isEmpty
        ? 1
        : trendStats
            .map((e) => e.count)
            .reduce((a, b) => a > b ? a : b)
            .clamp(1, 999);

    const double maxBarHeight = 82.0;

    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: _cardSurface,
        borderRadius: pw.BorderRadius.circular(16),
        border: pw.Border.all(color: _borderLight, width: 1),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                chartTitle,
                style: const pw.TextStyle(
                  fontSize: 13,
                  fontWeight: pw.FontWeight.bold,
                  color: _textPrimary,
                ),
              ),
              if (peakSlotHint != null && peakSlotHint.isNotEmpty)
                pw.Text(
                  peakSlotHint,
                  style: const pw.TextStyle(
                    fontSize: 10.5,
                    color: _textSecondary,
                  ),
                ),
            ],
          ),
          pw.SizedBox(height: 14),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: trendStats.map((stat) {
              final ratio = stat.count / maxCount;
              final barHeight = (ratio * maxBarHeight).clamp(4.0, maxBarHeight);
              final isPeak = stat.count == maxCount && maxCount > 0;

              return pw.Column(
                mainAxisSize: pw.MainAxisSize.min,
                children: [
                  pw.Text(
                    '${stat.count}',
                    style: pw.TextStyle(
                      fontSize: 9.5,
                      fontWeight: isPeak
                          ? pw.FontWeight.bold
                          : pw.FontWeight.normal,
                      color: isPeak ? _primary : _textSecondary,
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Container(
                    width: 22,
                    height: maxBarHeight,
                    alignment: pw.Alignment.bottomCenter,
                    decoration: pw.BoxDecoration(
                      color: _bgBeige,
                      borderRadius: pw.BorderRadius.circular(6),
                    ),
                    child: pw.Container(
                      width: 22,
                      height: stat.count == 0 ? 3 : barHeight,
                      decoration: pw.BoxDecoration(
                        color: isPeak ? _primary : _primaryLight,
                        borderRadius: pw.BorderRadius.circular(6),
                      ),
                    ),
                  ),
                  pw.SizedBox(height: 5),
                  pw.Text(
                    stat.label,
                    style: const pw.TextStyle(
                      fontSize: 10,
                      color: _textSecondary,
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildCausesCard({
    required List<ReportCauseItem> causeStats,
  }) {
    final maxPct = causeStats.isEmpty
        ? 1.0
        : causeStats
            .map((e) => e.percentage)
            .reduce((a, b) => a > b ? a : b);

    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: _cardSurface,
        borderRadius: pw.BorderRadius.circular(16),
        border: pw.Border.all(color: _borderLight, width: 1),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'توزيع الأسباب المحتملة للبكاء',
            style: const pw.TextStyle(
              fontSize: 13,
              fontWeight: pw.FontWeight.bold,
              color: _textPrimary,
            ),
          ),
          pw.SizedBox(height: 12),
          ...causeStats.map((stat) {
            final isTop = stat.percentage == maxPct;
            final pctInt = (stat.percentage * 100).round();
            final flexFilled = pctInt.clamp(1, 100);
            final flexEmpty = (100 - flexFilled).clamp(0, 99);

            return pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 10),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        stat.label,
                        style: pw.TextStyle(
                          fontSize: 11,
                          fontWeight: isTop
                              ? pw.FontWeight.bold
                              : pw.FontWeight.normal,
                          color: _textPrimary,
                        ),
                      ),
                      pw.Text(
                        '$pctInt%',
                        style: pw.TextStyle(
                          fontSize: 11,
                          fontWeight: pw.FontWeight.bold,
                          color: isTop ? _primary : _textSecondary,
                        ),
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 4),
                  pw.Container(
                    height: 7,
                    decoration: pw.BoxDecoration(
                      color: _bgBeige,
                      borderRadius: pw.BorderRadius.circular(4),
                    ),
                    child: pw.Row(
                      children: [
                        pw.Expanded(
                          flex: flexFilled,
                          child: pw.Container(
                            decoration: pw.BoxDecoration(
                              color: isTop ? _primary : _primaryLight,
                              borderRadius: pw.BorderRadius.circular(4),
                            ),
                          ),
                        ),
                        if (flexEmpty > 0)
                          pw.Expanded(
                            flex: flexEmpty,
                            child: pw.SizedBox(),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  List<pw.Widget> _buildHistoryEventsList(List<HistoryEvent> events) {
    if (events.isEmpty) {
      return [
        pw.Container(
          padding: const pw.EdgeInsets.all(16),
          decoration: pw.BoxDecoration(
            color: _cardSurface,
            borderRadius: pw.BorderRadius.circular(14),
            border: pw.Border.all(color: _borderLight, width: 1),
          ),
          alignment: pw.Alignment.center,
          child: pw.Text(
            'لا توجد أحداث مسجّلة في السجل حالياً.',
            style: const pw.TextStyle(
              fontSize: 11,
              color: _textSecondary,
            ),
          ),
        ),
      ];
    }

    return events.map((event) {
      final isAlert = event.isAlert;
      final badgeText = event.confidence ?? _eventTypeLabel(event.type);

      return pw.Container(
        margin: const pw.EdgeInsets.only(bottom: 8),
        padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: pw.BoxDecoration(
          color: isAlert ? _alertBg : _cardSurface,
          borderRadius: pw.BorderRadius.circular(14),
          border: pw.Border.all(
            color: isAlert ? _alertBorder : _borderLight,
            width: 1,
          ),
        ),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Row(
                    children: [
                      pw.Container(
                        width: 8,
                        height: 8,
                        decoration: pw.BoxDecoration(
                          color: isAlert ? _alert : _primary,
                          shape: pw.BoxShape.circle,
                        ),
                      ),
                      pw.SizedBox(width: 6),
                      pw.Text(
                        event.title,
                        style: pw.TextStyle(
                          fontSize: 11.5,
                          fontWeight: pw.FontWeight.bold,
                          color: isAlert ? _alert : _textPrimary,
                        ),
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 2),
                  pw.Text(
                    event.description,
                    style: const pw.TextStyle(
                      fontSize: 10,
                      color: _textSecondary,
                    ),
                  ),
                  pw.SizedBox(height: 3),
                  pw.Text(
                    _formatDateTime(event.timestamp),
                    style: const pw.TextStyle(
                      fontSize: 9.5,
                      color: _textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            pw.SizedBox(width: 10),
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(
                horizontal: 9,
                vertical: 4,
              ),
              decoration: pw.BoxDecoration(
                color: isAlert ? _alert : _bgBeige,
                borderRadius: pw.BorderRadius.circular(12),
              ),
              child: pw.Text(
                badgeText,
                style: pw.TextStyle(
                  fontSize: 9.5,
                  fontWeight: pw.FontWeight.bold,
                  color: isAlert ? PdfColors.white : _textPrimary,
                ),
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  String _eventTypeLabel(HistoryEventType type) {
    switch (type) {
      case HistoryEventType.cry:
        return 'بكاء';
      case HistoryEventType.temperature:
        return 'تنبيه حرارة';
      case HistoryEventType.humidity:
        return 'تنبيه رطوبة';
      case HistoryEventType.unclassified:
        return 'غير محدد';
    }
  }

  String _formatDateTime(DateTime dt) {
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
    final h = dt.hour > 12
        ? dt.hour - 12
        : dt.hour == 0
            ? 12
            : dt.hour;
    final period = dt.hour >= 12 ? 'م' : 'ص';
    final m = dt.minute.toString().padLeft(2, '0');
    return '${dt.day} ${months[dt.month - 1]} ${dt.year} - $h:$m $period';
  }
}
