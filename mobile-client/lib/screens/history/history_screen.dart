import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../services/pdf_export_service.dart';
import '../../widgets/app_snack_bar.dart';
import '../../widgets/primary_button.dart';

// ──────────────────────────────────────────────
//  Data model
// ──────────────────────────────────────────────

enum HistoryEventType { cry, unclassified }

enum ExportPeriod { daily, weekly, monthly, custom }

class HistoryEvent {
  const HistoryEvent({
    required this.type,
    required this.title,
    required this.description,
    required this.timestamp,
    required this.temperature,
    required this.humidity,
    this.confidence,
  });

  final HistoryEventType type;
  final String title;
  final String description;
  final DateTime timestamp;

  /// Room temperature recorded at the moment of the cry event (e.g. "24°م")
  final String temperature;

  /// Room humidity recorded at the moment of the cry event (e.g. "45%")
  final String humidity;

  /// Optional confidence percentage label (e.g. "٨٦٪")
  final String? confidence;
}

class _DayStat {
  const _DayStat({required this.dayLabel, required this.count});
  final String dayLabel;
  final int count;
}

class _CauseStat {
  const _CauseStat({required this.label, required this.percentage});
  final String label;
  final double percentage;
}

// ──────────────────────────────────────────────
//  Mock data  🔧  Replace with real API data
// ──────────────────────────────────────────────
final List<HistoryEvent> _mockEvents = [
  // ─── Today ───────────────────────────────────────────────────
  HistoryEvent(
    type: HistoryEventType.cry,
    title: 'بكاء - الجوع',
    description: 'نمط بكاء منتظم يشير إلى الجوع',
    timestamp: DateTime(2025, 3, 12, 10, 42),
    temperature: '24°م',
    humidity: '45%',
    confidence: '٨٦٪',
  ),
  HistoryEvent(
    type: HistoryEventType.unclassified,
    title: 'بكاء - غير محدد',
    description: 'صوت غير محدد الفئة',
    timestamp: DateTime(2025, 3, 12, 8, 15),
    temperature: '23°م',
    humidity: '48%',
    confidence: 'أقل من ٣٥٪',
  ),
  // ─── Yesterday ───────────────────────────────────────────────
  HistoryEvent(
    type: HistoryEventType.cry,
    title: 'بكاء - ألم بطن أو غازات',
    description: 'نمط بكاء يرتبط بآلام البطن',
    timestamp: DateTime(2025, 3, 11, 23, 0),
    temperature: '25°م',
    humidity: '42%',
    confidence: '٢٧٪',
  ),
  HistoryEvent(
    type: HistoryEventType.cry,
    title: 'بكاء - تعب ونعاس',
    description: 'نمط بكاء يدل على التعب والنعاس',
    timestamp: DateTime(2025, 3, 11, 21, 5),
    temperature: '23°م',
    humidity: '50%',
    confidence: '٣٨٪',
  ),
  // ─── Two days ago ────────────────────────────────────────────
  HistoryEvent(
    type: HistoryEventType.cry,
    title: 'بكاء - الجوع',
    description: 'نمط بكاء منتظم يشير إلى الجوع',
    timestamp: DateTime(2025, 3, 10, 14, 30),
    temperature: '24°م',
    humidity: '46%',
    confidence: '٩١٪',
  ),
];

const _dailyStats = [
  _DayStat(dayLabel: '١٢ص', count: 1),
  _DayStat(dayLabel: '٣ص', count: 2),
  _DayStat(dayLabel: '٦ص', count: 0),
  _DayStat(dayLabel: '٩ص', count: 1),
  _DayStat(dayLabel: '١٢م', count: 0),
  _DayStat(dayLabel: '٣م', count: 1),
  _DayStat(dayLabel: '٦م', count: 3),
  _DayStat(dayLabel: '٩م', count: 2),
];

const _dailySlotRanges = [
  '١٢ص - ٣ص',
  '٣ص - ٦ص',
  '٦ص - ٩ص',
  '٩ص - ١٢م',
  '١٢م - ٣م',
  '٣م - ٦م',
  '٦م - ٩م',
  '٩م - ١٢ص',
];

const _weeklyStats = [
  _DayStat(dayLabel: 'ح', count: 2),
  _DayStat(dayLabel: 'خ', count: 5),
  _DayStat(dayLabel: 'ن', count: 8),
  _DayStat(dayLabel: 'ث', count: 3),
  _DayStat(dayLabel: 'ر', count: 7),
  _DayStat(dayLabel: 'أ', count: 4),
  _DayStat(dayLabel: 'س', count: 6),
];

const _monthlyStats = [
  _DayStat(dayLabel: 'أ١', count: 12),
  _DayStat(dayLabel: 'أ٢', count: 18),
  _DayStat(dayLabel: 'أ٣', count: 9),
  _DayStat(dayLabel: 'أ٤', count: 15),
];

const _causeStats = [
  _CauseStat(label: 'الجوع', percentage: 0.40),
  _CauseStat(label: 'ألم بطن أو غازات', percentage: 0.28),
  _CauseStat(label: 'تعب ونعاس', percentage: 0.18),
  _CauseStat(label: 'غير محدد', percentage: 0.14),
];

// ──────────────────────────────────────────────
//  Screen
// ──────────────────────────────────────────────
class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  Future<void> _openExportSheet(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _ExportReportSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final events = _mockEvents;

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Header with top-left Export button ─────────────────
          _HistoryHeader(
            onExportTap: () => _openExportSheet(context),
          ),

          // ── List or empty state ─────────────────────────────────
          Expanded(
            child: events.isEmpty
                ? const _EmptyState()
                : _HistoryList(events: events),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────
//  Header
// ──────────────────────────────────────────────
class _HistoryHeader extends StatelessWidget {
  const _HistoryHeader({required this.onExportTap});

  final VoidCallback onExportTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text('السجل', style: AppTextStyles.screenTitle),
          InkWell(
            onTap: onExportTap,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(14),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x1FCE7E52),
                    blurRadius: 10,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.ios_share_rounded,
                    size: 16,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'تصدير السجل',
                    style: AppTextStyles.buttonText.copyWith(
                      fontSize: 12.5,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────
//  Export & Period Selection Sheet + Report Graphs
// ──────────────────────────────────────────────
class _ExportReportSheet extends StatefulWidget {
  const _ExportReportSheet();

  @override
  State<_ExportReportSheet> createState() => _ExportReportSheetState();
}

class _ExportReportSheetState extends State<_ExportReportSheet> {
  ExportPeriod _selectedPeriod = ExportPeriod.weekly;
  DateTime _customStart = DateTime(2026, 3, 1);
  DateTime _customEnd = DateTime(2026, 3, 12);
  bool _isExporting = false;
  bool _showExportedGraphs = false;
  int _touchedBarIndex = -1;

  String get _periodLabel {
    switch (_selectedPeriod) {
      case ExportPeriod.daily:
        return 'يوم';
      case ExportPeriod.weekly:
        return 'أسبوع';
      case ExportPeriod.monthly:
        return 'شهر';
      case ExportPeriod.custom:
        return 'فترة مخصصة';
    }
  }

  String _formatDate(DateTime d) => '${d.day}/${d.month}/${d.year}';

  String get _dateRangeLabel {
    switch (_selectedPeriod) {
      case ExportPeriod.daily:
        return '١٢ مارس ٢٠٢٦';
      case ExportPeriod.weekly:
        return '٦ - ١٢ مارس ٢٠٢٦';
      case ExportPeriod.monthly:
        return 'مارس ٢٠٢٦';
      case ExportPeriod.custom:
        return '${_formatDate(_customStart)} - ${_formatDate(_customEnd)}';
    }
  }

  String get _chartTitle {
    switch (_selectedPeriod) {
      case ExportPeriod.daily:
        return 'أحداث البكاء خلال اليوم';
      case ExportPeriod.weekly:
        return 'أحداث البكاء خلال الأسبوع';
      case ExportPeriod.monthly:
        return 'أحداث البكاء خلال الشهر';
      case ExportPeriod.custom:
        return 'أحداث البكاء خلال الفترة المحددة';
    }
  }

  List<_DayStat> get _activeStats {
    switch (_selectedPeriod) {
      case ExportPeriod.daily:
        return _dailyStats;
      case ExportPeriod.weekly:
      case ExportPeriod.custom:
        return _weeklyStats;
      case ExportPeriod.monthly:
        return _monthlyStats;
    }
  }

  Future<void> _pickCustomDate({required bool isStart}) async {
    final initial = isStart ? _customStart : _customEnd;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2024, 1, 1),
      lastDate: DateTime(2027, 12, 31),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: AppColors.backgroundCream,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked == null) return;
    setState(() {
      if (isStart) {
        _customStart = picked;
        if (_customEnd.isBefore(_customStart)) {
          _customEnd = _customStart;
        }
      } else {
        _customEnd = picked;
        if (_customStart.isAfter(_customEnd)) {
          _customStart = _customEnd;
        }
      }
    });
  }

  Future<void> _handleExport() async {
    if (_isExporting) return;

    setState(() => _isExporting = true);

    try {
      final stats = _activeStats;
      final maxCount = stats.map((e) => e.count).reduce((a, b) => a > b ? a : b);
      final peakIndex = stats.indexWhere((e) => e.count == maxCount);
      final peakSlotHint = (_selectedPeriod == ExportPeriod.daily && maxCount > 0)
          ? 'أكثر فترة بكاء: ${_dailySlotRanges[peakIndex]}'
          : null;

      await PdfExportService.instance.exportMonitoringReport(
        periodLabel: _periodLabel,
        dateRangeLabel: _dateRangeLabel,
        totalCryEvents: '١٨',
        monitoringDuration: '٣٨ ساعة',
        latestCause: 'الجوع',
        chartTitle: _chartTitle,
        peakSlotHint: peakSlotHint,
        trendStats: stats
            .map((s) => ReportTrendItem(label: s.dayLabel, count: s.count))
            .toList(),
        causeStats: _causeStats
            .map((c) => ReportCauseItem(label: c.label, percentage: c.percentage))
            .toList(),
      );

      if (!mounted) return;
      setState(() {
        _showExportedGraphs = true;
      });
      AppSnackBar.show(
        context,
        'تم تصدير تقرير السجل بصيغة PDF بنجاح',
        type: AppSnackBarType.success,
      );
    } catch (e) {
      debugPrint('PDF export error: $e');
      if (!mounted) return;
      // نعرض الرسوم البيانية للتقرير حتى لو ألغى المستخدم نافذة المشاركة
      setState(() {
        _showExportedGraphs = true;
      });
      AppSnackBar.show(
        context,
        'تم تجهيز ملخص التقرير والرسوم البيانية',
        type: AppSnackBarType.info,
      );
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.of(context).size.height * 0.88;

    return Container(
      constraints: BoxConstraints(maxHeight: maxHeight),
      decoration: const BoxDecoration(
        color: AppColors.backgroundCream,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.borderBeige,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ── Sheet Header ───────────────────────────────────
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _showExportedGraphs
                                  ? 'ملخص وتقرير السجل المُصدَّر'
                                  : 'تصدير تقرير السجل',
                              style: AppTextStyles.screenTitle.copyWith(
                                fontSize: 18,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              _showExportedGraphs
                                  ? 'الفترة: $_periodLabel ($_dateRangeLabel)'
                                  : 'حددي المدة الزمنية لتصدير التقرير وعرض الإحصائيات',
                              style: AppTextStyles.helperText.copyWith(
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(
                            Icons.close_rounded,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // ── Period Selector (يوم، أسبوع، شهر، فترة مخصصة) ──
                    _PeriodSelectorBar(
                      selected: _selectedPeriod,
                      onChanged: (p) => setState(() {
                        _selectedPeriod = p;
                        _touchedBarIndex = -1;
                      }),
                    ),

                    // ── Custom Date Range Picker (when custom is chosen) ──
                    if (_selectedPeriod == ExportPeriod.custom) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.cardSurface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.borderBeige),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: _DateBox(
                                label: 'من تاريخ',
                                dateText: _formatDate(_customStart),
                                onTap: () => _pickCustomDate(isStart: true),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _DateBox(
                                label: 'إلى تاريخ',
                                dateText: _formatDate(_customEnd),
                                onTap: () => _pickCustomDate(isStart: false),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ] else ...[
                      const SizedBox(height: 12),
                      Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.backgroundBeige,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            'الفترة المحددة: $_dateRangeLabel',
                            style: AppTextStyles.helperText.copyWith(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 18),

                    // ── Export Button ──────────────────────────────────
                    PrimaryButton(
                      label: _showExportedGraphs
                          ? 'إعادة تصدير ملف PDF'
                          : 'تصدير التقرير',
                      isLoading: _isExporting,
                      onPressed: _handleExport,
                    ),

                    // ── Report Graphs (Shown once user exports) ─────────
                    if (_showExportedGraphs) ...[
                      const SizedBox(height: 22),
                      const _SummaryTiles(),
                      const SizedBox(height: 16),
                      _CryingBarChartCard(
                        period: _selectedPeriod,
                        stats: _activeStats,
                        chartTitle: _chartTitle,
                        touchedIndex: _touchedBarIndex,
                        onBarTouched: (i) =>
                            setState(() => _touchedBarIndex = i),
                      ),
                      const SizedBox(height: 16),
                      const _CauseDistributionCard(),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PeriodSelectorBar extends StatelessWidget {
  const _PeriodSelectorBar({
    required this.selected,
    required this.onChanged,
  });

  final ExportPeriod selected;
  final ValueChanged<ExportPeriod> onChanged;

  @override
  Widget build(BuildContext context) {
    const items = [
      (ExportPeriod.daily, 'يوم'),
      (ExportPeriod.weekly, 'أسبوع'),
      (ExportPeriod.monthly, 'شهر'),
      (ExportPeriod.custom, 'فترة مخصصة'),
    ];

    return Container(
      height: 44,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.backgroundBeige,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: items.map((item) {
          final isSelected = selected == item.$1;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(item.$1),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Text(
                  item.$2,
                  style: AppTextStyles.fieldLabel.copyWith(
                    color: isSelected ? Colors.white : AppColors.textSecondary,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    fontSize: 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _DateBox extends StatelessWidget {
  const _DateBox({
    required this.label,
    required this.dateText,
    required this.onTap,
  });

  final String label;
  final String dateText;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.backgroundCream,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.borderLight),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.calendar_today_rounded,
              size: 15,
              color: AppColors.primary,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: AppTextStyles.helperText.copyWith(fontSize: 10.5),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    dateText,
                    style: AppTextStyles.cardTitle.copyWith(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────
//  Summary tiles (displayed after export)
// ──────────────────────────────────────────────
class _SummaryTiles extends StatelessWidget {
  const _SummaryTiles();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        _SummaryTile(
          label: 'أحداث البكاء',
          value: '١٨',
          icon: Icons.graphic_eq_rounded,
          iconBg: AppColors.iconBg,
          iconColor: AppColors.primary,
          fullWidth: true,
        ),
        SizedBox(height: 12),
        Row(
          children: [
            _SummaryTile(
              label: 'مدة المراقبة',
              value: '٣٨ ساعة',
              icon: Icons.timer_outlined,
              iconBg: AppColors.successBg,
              iconColor: AppColors.success,
            ),
            SizedBox(width: 12),
            _SummaryTile(
              label: 'آخر سبب محتمل',
              value: 'الجوع',
              icon: Icons.restaurant_outlined,
              iconBg: AppColors.backgroundBeige,
              iconColor: AppColors.primaryLight,
            ),
          ],
        ),
      ],
    );
  }
}

class _SummaryTile extends StatelessWidget {
  const _SummaryTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    this.fullWidth = false,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final bool fullWidth;

  @override
  Widget build(BuildContext context) {
    final card = Container(
      width: fullWidth ? double.infinity : null,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A785037),
            blurRadius: 12,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Icon(icon, size: 19, color: iconColor),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: AppTextStyles.cardTitle.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
                Text(
                  label,
                  style: AppTextStyles.helperText.copyWith(fontSize: 11),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );

    return fullWidth ? card : Expanded(child: card);
  }
}

// ──────────────────────────────────────────────
//  Crying bar chart card
// ──────────────────────────────────────────────
class _CryingBarChartCard extends StatelessWidget {
  const _CryingBarChartCard({
    required this.period,
    required this.stats,
    required this.chartTitle,
    required this.touchedIndex,
    required this.onBarTouched,
  });

  final ExportPeriod period;
  final List<_DayStat> stats;
  final String chartTitle;
  final int touchedIndex;
  final ValueChanged<int> onBarTouched;

  @override
  Widget build(BuildContext context) {
    final maxCount = stats.map((e) => e.count).reduce((a, b) => a > b ? a : b);
    final unit = maxCount <= 4 ? 2 : 10;
    final maxY = ((maxCount / unit).ceil() * unit).clamp(2, 200).toDouble();

    final peakIndex = stats.indexWhere((e) => e.count == maxCount);
    final showPeak = period == ExportPeriod.daily && maxCount > 0;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 12),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A785037),
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            chartTitle,
            style: AppTextStyles.cardTitle.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          if (showPeak) ...[
            const SizedBox(height: 4),
            Text(
              'أكثر فترة بكاء: ${_dailySlotRanges[peakIndex]}',
              style: AppTextStyles.helperText.copyWith(
                fontSize: 11.5,
                color: AppColors.textSecondary,
              ),
            ),
          ],
          const SizedBox(height: 20),
          SizedBox(
            height: 160,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxY,
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => AppColors.darkSurface,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      return BarTooltipItem(
                        '${rod.toY.toInt()}',
                        AppTextStyles.helperText.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      );
                    },
                  ),
                  touchCallback: (event, response) {
                    if (response == null ||
                        response.spot == null ||
                        !event.isInterestedForInteractions) {
                      onBarTouched(-1);
                      return;
                    }
                    onBarTouched(response.spot!.touchedBarGroupIndex);
                  },
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final i = value.toInt();
                        if (i < 0 || i >= stats.length) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            stats[i].dayLabel,
                            style: AppTextStyles.helperText.copyWith(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        );
                      },
                      reservedSize: 26,
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: maxY / 2,
                      reservedSize: 28,
                      getTitlesWidget: (value, meta) {
                        if (value == 0 ||
                            value == maxY / 2 ||
                            value == maxY) {
                          return Text(
                            '${value.toInt()}',
                            style: AppTextStyles.helperText.copyWith(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: maxY / 2,
                  getDrawingHorizontalLine: (value) => const FlLine(
                    color: AppColors.borderLight,
                    strokeWidth: 1,
                    dashArray: [4, 4],
                  ),
                ),
                borderData: FlBorderData(show: false),
                barGroups: stats.asMap().entries.map((entry) {
                  final i = entry.key;
                  final stat = entry.value;
                  final isTouched = i == touchedIndex;

                  return BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: stat.count.toDouble(),
                        color: isTouched
                            ? AppColors.primaryDark
                            : AppColors.primary,
                        width: period == ExportPeriod.daily ? 18 : 22,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(8),
                        ),
                        backDrawRodData: BackgroundBarChartRodData(
                          show: true,
                          toY: maxY,
                          color: AppColors.backgroundBeige,
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────
//  Cause distribution card
// ──────────────────────────────────────────────
class _CauseDistributionCard extends StatelessWidget {
  const _CauseDistributionCard();

  @override
  Widget build(BuildContext context) {
    final maxPct = _causeStats.map((e) => e.percentage).reduce(
      (a, b) => a > b ? a : b,
    );

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A785037),
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'توزيع الأسباب المحتملة',
            style: AppTextStyles.cardTitle.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),
          ..._causeStats.map(
            (stat) => _CauseRow(stat: stat, maxPct: maxPct),
          ),
        ],
      ),
    );
  }
}

class _CauseRow extends StatelessWidget {
  const _CauseRow({required this.stat, required this.maxPct});

  final _CauseStat stat;
  final double maxPct;

  @override
  Widget build(BuildContext context) {
    final isTop = stat.percentage == maxPct;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                stat.label,
                style: AppTextStyles.helperText.copyWith(
                  fontSize: 12.5,
                  color: AppColors.textPrimary,
                  fontWeight: isTop ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
              Text(
                '${(stat.percentage * 100).toInt()}%',
                style: AppTextStyles.helperText.copyWith(
                  fontSize: 12.5,
                  color: isTop ? AppColors.primary : AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          LayoutBuilder(
            builder: (context, constraints) {
              return Stack(
                children: [
                  Container(
                    height: 8,
                    width: constraints.maxWidth,
                    decoration: BoxDecoration(
                      color: AppColors.backgroundBeige,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  Container(
                    height: 8,
                    width: constraints.maxWidth * stat.percentage,
                    decoration: BoxDecoration(
                      color: isTop ? AppColors.primary : AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────
//  Grouped list
// ──────────────────────────────────────────────
class _HistoryList extends StatelessWidget {
  const _HistoryList({required this.events});

  final List<HistoryEvent> events;

  /// Groups events by date label (today / yesterday / date string)
  Map<String, List<HistoryEvent>> _group() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    final Map<String, List<HistoryEvent>> groups = {};

    for (final e in events) {
      final d = DateTime(e.timestamp.year, e.timestamp.month, e.timestamp.day);
      String key;
      if (d == today) {
        key = 'اليوم · ${_weekday(d.weekday)} ${d.day} ${_month(d.month)}';
      } else if (d == yesterday) {
        key = 'أمس · ${_weekday(d.weekday)} ${d.day} ${_month(d.month)}';
      } else {
        key = '${_weekday(d.weekday)} ${d.day} ${_month(d.month)}';
      }
      groups.putIfAbsent(key, () => []).add(e);
    }
    return groups;
  }

  String _weekday(int w) {
    const days = [
      'الاثنين',
      'الثلاثاء',
      'الأربعاء',
      'الخميس',
      'الجمعة',
      'السبت',
      'الأحد',
    ];
    return days[(w - 1) % 7];
  }

  String _month(int m) {
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
    return months[m - 1];
  }

  @override
  Widget build(BuildContext context) {
    final groups = _group();

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      children: [
        for (final entry in groups.entries) ...[
          // ── Date label ─────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.only(bottom: 10, top: 4),
            child: Text(
              entry.key,
              style: AppTextStyles.helperText.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
          ),
          // ── Event cards ─────────────────────────────────────────
          ...entry.value.map((e) => _EventCard(event: e)),
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}

// ──────────────────────────────────────────────
//  Event card (Cry + Temperature & Humidity)
// ──────────────────────────────────────────────
class _EventCard extends StatelessWidget {
  const _EventCard({required this.event});

  final HistoryEvent event;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.borderLight, width: 1),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A785037),
            blurRadius: 12,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // ── Icon ─────────────────────────────────────────────
              _EventIcon(event: event),
              const SizedBox(width: 12),

              // ── Text ─────────────────────────────────────────────
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.title,
                      style: AppTextStyles.cardTitle.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _formatTime(event.timestamp),
                      style: AppTextStyles.helperText.copyWith(fontSize: 11.5),
                    ),
                  ],
                ),
              ),

              // ── Confidence badge ──────────────────────────────────
              if (event.confidence != null) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.unclassified,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    event.confidence!,
                    style: AppTextStyles.helperText.copyWith(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ],
          ),

          const SizedBox(height: 10),

          // ── Room Temperature & Humidity at the time of crying ──
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: AppColors.backgroundCream,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.thermostat_rounded,
                        size: 15,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        'درجة الحرارة: ',
                        style: AppTextStyles.featureDesc.copyWith(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      Text(
                        event.temperature,
                        style: AppTextStyles.cardTitle.copyWith(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 1,
                  height: 14,
                  color: AppColors.borderBeige,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.water_drop_outlined,
                        size: 15,
                        color: AppColors.success,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        'الرطوبة: ',
                        style: AppTextStyles.featureDesc.copyWith(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      Text(
                        event.humidity,
                        style: AppTextStyles.cardTitle.copyWith(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour > 12
        ? dt.hour - 12
        : dt.hour == 0
            ? 12
            : dt.hour;
    final period = dt.hour >= 12 ? 'م' : 'ص';
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m $period';
  }
}

// ──────────────────────────────────────────────
//  Event icon widget
// ──────────────────────────────────────────────
class _EventIcon extends StatelessWidget {
  const _EventIcon({required this.event});

  final HistoryEvent event;

  @override
  Widget build(BuildContext context) {
    final bool isCry = event.type == HistoryEventType.cry;

    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: isCry ? AppColors.iconBg : AppColors.unclassified,
        borderRadius: BorderRadius.circular(13),
      ),
      alignment: Alignment.center,
      child: Icon(
        isCry ? Icons.graphic_eq_rounded : Icons.access_time_rounded,
        color: isCry ? AppColors.primary : AppColors.textSecondary,
        size: 20,
      ),
    );
  }
}

// ──────────────────────────────────────────────
//  Empty state
// ──────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: const BoxDecoration(
                color: AppColors.iconBg,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: const Icon(
                Icons.access_time_rounded,
                size: 40,
                color: AppColors.primaryLight,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'لا توجد أحداث مسجّلة',
              style: AppTextStyles.screenTitle.copyWith(fontSize: 18),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'ابدئي جلسة مراقبة وستظهر الأحداث هنا مع أوقاتها.',
              style: AppTextStyles.helperText,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 50,
              child: TextButton(
                onPressed: () {},
                style: TextButton.styleFrom(
                  backgroundColor: AppColors.darkSurface,
                  foregroundColor: AppColors.darkSurfaceText,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                ),
                child: Text(
                  'بدء المراقبة',
                  style: AppTextStyles.buttonText.copyWith(
                    color: AppColors.darkSurfaceText,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
