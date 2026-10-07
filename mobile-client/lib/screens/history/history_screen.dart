import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

// ──────────────────────────────────────────────
//  Data model
// ──────────────────────────────────────────────

enum HistoryEventType { cry, alert, unclassified }

class HistoryEvent {
  const HistoryEvent({
    required this.type,
    required this.title,
    required this.description,
    required this.timestamp,
    this.confidence,
    this.isAlert = false,
  });

  final HistoryEventType type;
  final String title;
  final String description;
  final DateTime timestamp;

  /// Optional confidence percentage label (e.g. "٨٦٪")
  final String? confidence;

  /// True = the card gets the red-alert treatment
  final bool isAlert;
}

// ──────────────────────────────────────────────
//  Mock data  🔧  Replace with real API data
// ──────────────────────────────────────────────
final List<HistoryEvent> _mockEvents = [
  // ─── Today ───────────────────────────────────────────────────
  HistoryEvent(
    type: HistoryEventType.alert,
    title: 'صوت قد يرتبط بسقوط',
    description: 'تم رصد صوت غير اعتيادي قد يشير إلى سقوط',
    timestamp: DateTime(2025, 3, 12, 10, 44),
    isAlert: true,
  ),
  HistoryEvent(
    type: HistoryEventType.cry,
    title: 'بكاء - الجوع',
    description: 'نمط بكاء منتظم يشير إلى الجوع',
    timestamp: DateTime(2025, 3, 12, 10, 42),
    confidence: '٨٦٪',
  ),
  HistoryEvent(
    type: HistoryEventType.unclassified,
    title: 'بكاء - غير محدد',
    description: 'صوت غير محدد الفئة',
    timestamp: DateTime(2025, 3, 12, 8, 15),
    confidence: 'أقل من ٣٥٪',
  ),
  // ─── Yesterday ───────────────────────────────────────────────
  HistoryEvent(
    type: HistoryEventType.cry,
    title: 'بكاء - ألم بطن أو غازات',
    description: 'نمط بكاء يرتبط بآلام البطن',
    timestamp: DateTime(2025, 3, 11, 23, 0),
    confidence: '٢٧٪',
  ),
  HistoryEvent(
    type: HistoryEventType.cry,
    title: 'بكاء - تعب ونعاس',
    description: 'نمط بكاء يدل على التعب والنعاس',
    timestamp: DateTime(2025, 3, 11, 21, 5),
    confidence: '٣٨٪',
  ),
  // ─── Two days ago ────────────────────────────────────────────
  HistoryEvent(
    type: HistoryEventType.cry,
    title: 'بكاء - الجوع',
    description: 'نمط بكاء منتظم يشير إلى الجوع',
    timestamp: DateTime(2025, 3, 10, 14, 30),
    confidence: '٩١٪',
  ),
  HistoryEvent(
    type: HistoryEventType.alert,
    title: 'تنبيه درجة الحرارة',
    description: 'ارتفاع في درجة حرارة الغرفة',
    timestamp: DateTime(2025, 3, 10, 11, 45),
    isAlert: true,
  ),
];

// ──────────────────────────────────────────────
//  Screen
// ──────────────────────────────────────────────
enum _HistoryFilter { all, cry, important }

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  _HistoryFilter _filter = _HistoryFilter.all;

  List<HistoryEvent> get _filtered {
    switch (_filter) {
      case _HistoryFilter.cry:
        return _mockEvents
            .where((e) => e.type == HistoryEventType.cry)
            .toList();
      case _HistoryFilter.important:
        return _mockEvents.where((e) => e.isAlert).toList();
      case _HistoryFilter.all:
        return _mockEvents;
    }
  }

  @override
  Widget build(BuildContext context) {
    final events = _filtered;

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Header ─────────────────────────────────────────────
          const _HistoryHeader(),

          // ── Filter chips ───────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: _FilterChips(
              selected: _filter,
              onChanged: (f) => setState(() => _filter = f),
            ),
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
          Text(
            'جميع الأحداث المرصودة مع أوقاتها',
            style: AppTextStyles.helperText,
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────
//  Filter chips
// ──────────────────────────────────────────────
class _FilterChips extends StatelessWidget {
  const _FilterChips({required this.selected, required this.onChanged});

  final _HistoryFilter selected;
  final ValueChanged<_HistoryFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _Chip(
          label: 'الكل',
          isSelected: selected == _HistoryFilter.all,
          onTap: () => onChanged(_HistoryFilter.all),
        ),
        const SizedBox(width: 8),
        _Chip(
          label: 'بكاء',
          isSelected: selected == _HistoryFilter.cry,
          onTap: () => onChanged(_HistoryFilter.cry),
        ),
        const SizedBox(width: 8),
        _Chip(
          label: 'أصوات مهمة',
          isSelected: selected == _HistoryFilter.important,
          onTap: () => onChanged(_HistoryFilter.important),
        ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.cardSurface,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.borderBeige,
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.fieldLabel.copyWith(
            color: isSelected ? Colors.white : AppColors.textSecondary,
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
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
//  Event card
// ──────────────────────────────────────────────
class _EventCard extends StatelessWidget {
  const _EventCard({required this.event});

  final HistoryEvent event;

  @override
  Widget build(BuildContext context) {
    final isAlert = event.isAlert;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(
        color: isAlert ? AppColors.alertBg : AppColors.cardSurface,
        borderRadius: BorderRadius.circular(18),
        border: isAlert
            ? Border.all(color: AppColors.alertBorder, width: 1.2)
            : Border.all(color: AppColors.borderLight, width: 1),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A785037),
            blurRadius: 12,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
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
                    color: isAlert ? AppColors.alert : AppColors.textPrimary,
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
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
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
    );
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour > 12 ? dt.hour - 12 : dt.hour == 0 ? 12 : dt.hour;
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
    IconData icon;
    Color iconColor;
    Color bgColor;

    if (event.isAlert) {
      icon = Icons.warning_rounded;
      iconColor = AppColors.alert;
      bgColor = AppColors.alert;
    } else if (event.type == HistoryEventType.cry) {
      icon = Icons.graphic_eq_rounded;
      iconColor = AppColors.primary;
      bgColor = AppColors.iconBg;
    } else {
      icon = Icons.access_time_rounded;
      iconColor = AppColors.textSecondary;
      bgColor = AppColors.unclassified;
    }

    if (event.isAlert) {
      // Filled rounded square for alert
      return Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(13),
        ),
        alignment: Alignment.center,
        child: Icon(icon, color: Colors.white, size: 20),
      );
    }

    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(13),
      ),
      alignment: Alignment.center,
      child: Icon(icon, color: iconColor, size: 20),
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
