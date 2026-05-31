import 'package:flutter/material.dart';
import 'package:smart_sprint/features/workspace/model/enums.dart';
import 'package:smart_sprint/features/workspace/model/organization.dart';

/// Central place that maps backend JSON primitives ↔ Flutter types.
///
/// Why string icon keys instead of raw codepoints: building `IconData` from a
/// non-constant int breaks Flutter's icon tree-shaking on release/web. So the
/// backend stores a stable **key** and we resolve it to a `const IconData` here.

// ─── Icons ────────────────────────────────────────────────────────────────────

const Map<String, IconData> _iconByKey = {
  // org + workspace icons share one registry (keys are unique)
  'person': Icons.person_rounded,
  'groups': Icons.groups_rounded,
  'hexagon': Icons.hexagon_rounded,
  'building': Icons.apartment_rounded,
  'rocket': Icons.rocket_launch_rounded,
  'phone': Icons.phone_iphone_rounded,
  'palette': Icons.palette_rounded,
  'dns': Icons.dns_rounded,
  'campaign': Icons.campaign_rounded,
  'science': Icons.science_rounded,
  'check': Icons.check_circle_rounded,
  'school': Icons.school_rounded,
  'folder': Icons.folder_rounded,
};

/// Resolve an icon key to a const IconData (falls back to a neutral icon).
IconData iconFromKey(String? key) => _iconByKey[key] ?? Icons.folder_rounded;

/// Reverse lookup so the create flows can send a key for a chosen IconData.
String iconKeyFor(IconData icon) {
  for (final entry in _iconByKey.entries) {
    if (entry.value.codePoint == icon.codePoint) return entry.key;
  }
  return 'folder';
}

// ─── Colors ───────────────────────────────────────────────────────────────────

Color colorFromInt(int? argb) => Color(argb ?? 0xFF6C47FF);

int colorToInt(Color color) => color.toARGB32();

// ─── Enums (stored as Dart enum .name on the backend) ─────────────────────────

T _byName<T extends Enum>(List<T> values, String? name, T fallback) {
  for (final v in values) {
    if (v.name == name) return v;
  }
  return fallback;
}

TaskStatus taskStatusFromName(String? n) =>
    _byName(TaskStatus.values, n, TaskStatus.todo);

TaskPriority taskPriorityFromName(String? n) =>
    _byName(TaskPriority.values, n, TaskPriority.normal);

TaskPriority? taskPriorityFromNameOrNull(String? n) =>
    n == null ? null : taskPriorityFromName(n);

SprintStatus sprintStatusFromName(String? n) =>
    _byName(SprintStatus.values, n, SprintStatus.planned);

ActivityKind activityKindFromName(String? n) =>
    _byName(ActivityKind.values, n, ActivityKind.edited);

OrgType orgTypeFromName(String? n) => _byName(OrgType.values, n, OrgType.team);

// ─── Dates ────────────────────────────────────────────────────────────────────

DateTime? dateFromIso(String? iso) =>
    (iso == null || iso.isEmpty) ? null : DateTime.tryParse(iso);

DateTime dateOrNow(String? iso) => dateFromIso(iso) ?? DateTime.now();

// ─── Avatar colour (deterministic per user id — backend stores no colour) ─────

const List<Color> _avatarPalette = [
  Color(0xFF7C6AF7),
  Color(0xFF34D399),
  Color(0xFFFBBF24),
  Color(0xFFF472B6),
  Color(0xFF60A5FA),
  Color(0xFFF87171),
  Color(0xFF2DD4BF),
  Color(0xFFA78BFA),
];

Color avatarColorFor(String userId) {
  var hash = 0;
  for (final unit in userId.codeUnits) {
    hash = (hash * 31 + unit) & 0x7fffffff;
  }
  return _avatarPalette[hash % _avatarPalette.length];
}
