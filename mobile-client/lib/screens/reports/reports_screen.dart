import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

// ──────────────────────────────────────────────
//  Data models
// ──────────────────────────────────────────────

/// A single day's crying-event count
class _DayStat {
  const _DayStat({required this.dayLabel, required this.count});
  final String dayLabel;
  final int count;
}

/// A single cause + its percentage share
class _CauseStat {
  const _CauseStat({required this.label, required this.percentage});
  final String label;
  final double percentage;
}

// ──────────────────────────────────────────────
//  Mock data  🔧  Replace with real API data
// ──────────────────────────────────────────────

/// Daily: today's events distributed across 3-hour time slots
/// (ص = AM, م = PM). Each label marks the start of its slot.
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

/// Full time-range text for each daily slot (used for the peak hint).
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

/// Weekly: one bar per day (Sun → Sat)
const _weeklyStats = [
  _DayStat(dayLabel: 'ح', count: 2),
  _DayStat(dayLabel: 'خ', count: 5),
  _DayStat(dayLabel: 'ن', count: 8),
  _DayStat(dayLabel: 'ث', count: 3),
  _DayStat(dayLabel: 'ر', count: 7),
  _DayStat(dayLabel: 'أ', count: 4),
  _DayStat(dayLabel: 'س', count: 6),
];

/// Monthly: one bar per week
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
enum _ReportPeriod { daily, weekly, monthly }

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  _ReportPeriod _period = _ReportPeriod.weekly;

  // Touched bar index for tooltip highlight
  int _touchedBarIndex = -1;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Header ───────────────────────────────────────────
            const _ReportsHeader(),
            const SizedBox(height: 14),

            // ── Period selector ──────────────────────────────────
            _PeriodSelector(
              selected: _period,
              onChanged: (p) => setState(() {
                _period = p;
                _touchedBarIndex = -1;
              }),
            ),
            const SizedBox(height: 16),

            // ── Date range label ─────────────────────────────────
            _DateRangeLabel(period: _period),
            const SizedBox(height: 16),

            // ── Summary tiles ────────────────────────────────────
            const _SummaryTiles(),
            const SizedBox(height: 20),

            // ── Bar chart card ───────────────────────────────────
            _CryingBarChartCard(
              period: _period,
              touchedIndex: _touchedBarIndex,
              onBarTouched: (i) => setState(() => _touchedBarIndex = i),
            ),
            const SizedBox(height: 20),

            // ── Cause distribution ────────────────────────────────
            const _CauseDistributionCard(),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────
//  Header
// ──────────────────────────────────────────────
class _ReportsHeader extends StatelessWidget {
  const _ReportsHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('التقارير', style: AppTextStyles.screenTitle),
            const SizedBox(height: 3),
            Text(
              'ملخص المراقبة وإمكانية التصدير PDF',
              style: AppTextStyles.helperText,
            ),
          ],
        ),
        // PDF export button (icon only — stub)
        GestureDetector(
          onTap: () {},
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
            decoration: BoxDecoration(
              color: AppColors.cardSurface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.borderBeige, width: 1.2),
            ),
            child: const Icon(
              Icons.picture_as_pdf_outlined,
              size: 20,
              color: AppColors.alert,
            ),
          ),
        ),
      ],
    );
  }
}

// ──────────────────────────────────────────────
//  Period selector
// ──────────────────────────────────────────────
class _PeriodSelector extends StatelessWidget {
  const _PeriodSelector({required this.selected, required this.onChanged});

  final _ReportPeriod selected;
  final ValueChanged<_ReportPeriod> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 42,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.backgroundBeige,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          _Tab(
            label: 'يومي',
            isSelected: selected == _ReportPeriod.daily,
            onTap: () => onChanged(_ReportPeriod.daily),
          ),
          _Tab(
            label: 'أسبوعي',
            isSelected: selected == _ReportPeriod.weekly,
            onTap: () => onChanged(_ReportPeriod.weekly),
          ),
          _Tab(
            label: 'شهري',
            isSelected: selected == _ReportPeriod.monthly,
            onTap: () => onChanged(_ReportPeriod.monthly),
          ),
        ],
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(11),
          ),
          child: Text(
            label,
            style: AppTextStyles.fieldLabel.copyWith(
              color: isSelected ? Colors.white : AppColors.textSecondary,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────
//  Date range label
// ──────────────────────────────────────────────
class _DateRangeLabel extends StatelessWidget {
  const _DateRangeLabel({required this.period});

  final _ReportPeriod period;

  String get _label {
    switch (period) {
      case _ReportPeriod.daily:
        return '١٢ مارس ٢٠٢٦';
      case _ReportPeriod.weekly:
        return '٦ - ١٢ مارس ٢٠٢٦';
      case _ReportPeriod.monthly:
        return 'مارس ٢٠٢٦';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _ArrowBtn(icon: Icons.chevron_right_rounded),
        Text(
          _label,
          style: AppTextStyles.bodyText.copyWith(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        _ArrowBtn(icon: Icons.chevron_left_rounded),
      ],
    );
  }
}

class _ArrowBtn extends StatelessWidget {
  const _ArrowBtn({required this.icon});
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.borderBeige, width: 1),
      ),
      alignment: Alignment.center,
      child: Icon(icon, size: 18, color: AppColors.textSecondary),
    );
  }
}

// ──────────────────────────────────────────────
//  Summary tiles
// ──────────────────────────────────────────────
class _SummaryTiles extends StatelessWidget {
  const _SummaryTiles();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ── Full-width crying events tile ─────────────────────────
        _SummaryTile(
          label: 'أحداث البكاء',
          value: '١٨',
          icon: Icons.graphic_eq_rounded,
          iconBg: AppColors.iconBg,
          iconColor: AppColors.primary,
          fullWidth: true,
        ),
        const SizedBox(height: 12),
        // ── Two-column row ────────────────────────────────────────
        Row(
          children: [
            _SummaryTile(
              label: 'مدة المراقبة',
              value: '٣٨ ساعة',
              icon: Icons.timer_outlined,
              iconBg: AppColors.successBg,
              iconColor: AppColors.success,
            ),
            const SizedBox(width: 12),
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

  /// When true, the tile fills available width without Expanded
  /// (use outside a Row to span the full width).
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
    required this.touchedIndex,
    required this.onBarTouched,
  });

  final _ReportPeriod period;
  final int touchedIndex;
  final ValueChanged<int> onBarTouched;

  /// Returns the correct dataset for the active period
  List<_DayStat> get _stats {
    switch (period) {
      case _ReportPeriod.daily:
        return _dailyStats;
      case _ReportPeriod.weekly:
        return _weeklyStats;
      case _ReportPeriod.monthly:
        return _monthlyStats;
    }
  }

  /// Chart title that reflects the active period
  String get _chartTitle {
    switch (period) {
      case _ReportPeriod.daily:
        return 'أحداث البكاء اليوم';
      case _ReportPeriod.weekly:
        return 'أحداث البكاء خلال الأسبوع';
      case _ReportPeriod.monthly:
        return 'أحداث البكاء خلال الشهر';
    }
  }

  @override
  Widget build(BuildContext context) {
    final stats = _stats;
    final maxCount = stats.map((e) => e.count).reduce((a, b) => a > b ? a : b);
    // Round up so that maxY / 2 is always a whole number (clean Y-axis):
    // small counts → multiples of 2, larger counts → multiples of 10.
    final unit = maxCount <= 4 ? 2 : 10;
    final maxY = ((maxCount / unit).ceil() * unit).clamp(2, 200).toDouble();

    // Peak time slot (daily view only)
    final peakIndex = stats.indexWhere((e) => e.count == maxCount);
    final showPeak = period == _ReportPeriod.daily && maxCount > 0;

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
            _chartTitle,
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
                        width: period == _ReportPeriod.daily ? 18 : 22,
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
                '${(stat.percentage * 100).toInt()}٪',
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
                  // Background track
                  Container(
                    height: 8,
                    width: constraints.maxWidth,
                    decoration: BoxDecoration(
                      color: AppColors.backgroundBeige,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  // Fill
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
