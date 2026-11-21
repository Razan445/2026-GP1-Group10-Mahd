
import 'dart:convert';

import 'package:flutter/services.dart';
import '../core/utils/child_age_formatter.dart';

/// Read-only, source-backed educational content for the Mahd prototype.
/// This class does not write any data to Firebase.
class ChildContentRepository {
  ChildContentRepository._(this._data);

  static const String assetPath =
      'assets/data/mahd_child_content_ar.json';

  final Map<String, dynamic> _data;

  static Future<ChildContentRepository>? _cachedLoad;

  static Future<ChildContentRepository> load() =>
      _cachedLoad ??= _loadFromAssets().catchError((Object error) {
        _cachedLoad = null; // Retry if the asset was temporarily unavailable.
        throw error;
      });

  static Future<ChildContentRepository> _loadFromAssets() async {
    final source = await rootBundle.loadString(assetPath);
    final parsed = jsonDecode(source);
    if (parsed is! Map<String, dynamic>) {
      throw const FormatException('Mahd content: invalid JSON root.');
    }
    for (final section in ['growthFacts', 'milestones', 'activities']) {
      if (parsed[section] is! List) {
        throw FormatException('Mahd content: missing section $section.');
      }
    }
    return ChildContentRepository._(parsed);
  }

  List<Map<String, dynamic>> _rows(String name) =>
      (_data[name] as List)
          .map((row) => Map<String, dynamic>.from(row as Map))
          .toList(growable: false);

  Map<String, dynamic> get disclaimer =>
      Map<String, dynamic>.from(
        _data['globalSafetyAndDisclaimer'] as Map,
      );

  List<int> get milestoneStages =>
      List<int>.from(_data['ageGroupsMonths'] as List);

  /// Returns whole completed calendar months (never rounds days / 30).
  /// Returns -1 when birth date is in the future.
  static int completedMonths(DateTime dateOfBirth, DateTime now) =>
      ChildAgeFormatter.completedMonths(dateOfBirth, now);

  /// CDC recommends using the younger checklist for ages between checklists.
  /// This assumes actual chronological age; correct for prematurity only if
  /// the baby's verified due date / gestational age is available.
  int? matchingChecklistAge(int completedAgeMonths) {
    if (completedAgeMonths < 2 || completedAgeMonths > 60) return null;

    int? matching;
    for (final stage in milestoneStages) {
      if (stage <= completedAgeMonths &&
          (matching == null || stage > matching)) {
        matching = stage;
      }
    }
    return matching;
  }

  List<Map<String, dynamic>> milestonesForAge(int completedAgeMonths) {
    final stage = matchingChecklistAge(completedAgeMonths);
    if (stage == null) return const [];

    return _rows('milestones')
        .where((item) => item['ageMonths'] == stage)
        .toList(growable: false);
  }

  /// Product display rule: activities come from the page matching the
  /// selected younger CDC checklist (not a separate CDC age rule for activities).
  List<Map<String, dynamic>> activitiesForAge(int completedAgeMonths) {
    final stage = matchingChecklistAge(completedAgeMonths);
    if (stage == null) return const [];

    return _rows('activities')
        .where((item) => item['ageMonths'] == stage)
        .toList(growable: false);
  }

  /// Home preview reserves the third CDC activity so that it never duplicates
  /// either of the first two activities in the Child Development tab.
  /// This is a Mahd presentation choice, not a CDC age/selection guideline.
  Map<String, dynamic>? featuredActivityForAge(int completedAgeMonths) {
    final items = activitiesForAge(completedAgeMonths);
    if (items.isEmpty) return null;
    return items.length >= 3 ? items[2] : items.last;
  }

  /// All other activities can cycle through two dedicated cards.
  List<Map<String, dynamic>> screenActivitiesForAge(int completedAgeMonths) {
    final items = activitiesForAge(completedAgeMonths);
    final featured = featuredActivityForAge(completedAgeMonths);
    if (featured == null) return const [];

    return items.where((item) => item['id'] != featured['id']).toList();
  }

  /// Each growth fact keeps its cited source period in the JSON metadata.
  /// The JSON also retains the original attributed Arabic wording; only the
  /// copy rendered to parents removes organization names. This does not alter
  /// the underlying claim or erase its source for academic verification.
  static String _parentFacingGrowthText(String original) => original
      .replaceFirst('تذكر AAP أن ', '')
      .replaceFirst('تذكر NHS أن ', '')
      .replaceFirst('وتقدّر AAP زيادتها', 'وتُقدّر زيادتها')
      .replaceFirst(' في مرجع AAP', '')
      .replaceFirst(' وفق الوصف الوارد لدى AAP', '')
      .replaceFirst(' وفق التوقيت التقريبي لدى NHS', '');

  /// Boundaries that start a new age period are exclusive for the previous
  /// period. For example, 8–12 months means 8 <= age < 12, not an age of
  /// 12 months and 20 days. The same is true for the 12–24 and 24–36 periods.
  /// Month 1 is excluded from the newborn 0–1-month period. Other endpoints
  /// (e.g. 1–4 months) retain the source dataset's inclusive upper month;
  /// the 36–60-month interval remains inclusive because the cited 3–6-year
  /// source continues beyond the app's 5-year content limit.
  static bool _isWithinGrowthRange(
    Map<String, dynamic> range,
    int completedAgeMonths,
  ) {
    final from = range['from'] as int;
    final to = range['to'] as int;

    if (completedAgeMonths < from || completedAgeMonths > to) {
      return false;
    }

    final boundaryStartsAnotherPeriod =
        from < to && (to == 1 || to == 12 || to == 24 || to == 36);

    return !(boundaryStartsAnotherPeriod && completedAgeMonths == to);
  }

  /// IMPORTANT: Growth facts use their own documented age coverage, not the
  /// younger-checklist rule for developmental milestones. We deliberately do
  /// not round a child aged 12 months and 20 days back to the 8–12-month facts.
  /// sourceUrl, sourceSection, sourceEvidenceSummaryEn and warnings remain in
  /// the JSON; they are not rendered in parent-facing cards.
  List<Map<String, dynamic>> growthFactsForAge(int completedAgeMonths) {
    if (completedAgeMonths < 0 || completedAgeMonths > 60) {
      return const [];
    }

    final matching = _rows('growthFacts').where((item) {
      final range = Map<String, dynamic>.from(
        item['displayAgeRangeMonths'] as Map,
      );

      return _isWithinGrowthRange(range, completedAgeMonths);
    }).toList(growable: false);

    matching.sort((a, b) {
      final differenceA =
          (a['ageMonths'] as int) - completedAgeMonths;
      final differenceB =
          (b['ageMonths'] as int) - completedAgeMonths;

      return differenceA.abs().compareTo(differenceB.abs());
    });

    return matching.map((item) {
      final copy = Map<String, dynamic>.from(item);

      copy['textAr'] = _parentFacingGrowthText(
        (item['textAr'] as String?) ?? '',
      );

      return copy;
    }).toList(growable: false);
  }
}
