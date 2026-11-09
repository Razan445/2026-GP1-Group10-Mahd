import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

// ──────────────────────────────────────────────
//  Data model
// ──────────────────────────────────────────────

enum HistoryEventType { cry, unclassified }

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

// ──────────────────────────────────────────────
//  Screen
// ──────────────────────────────────────────────
class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final events = _mockEvents;

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Header ─────────────────────────────────────────────
          const _HistoryHeader(),

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
  const _HistoryHeader();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('السجل', style: AppTextStyles.screenTitle),
          const SizedBox(height: 4),
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
