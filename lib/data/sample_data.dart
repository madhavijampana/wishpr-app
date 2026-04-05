import '../models/sample_activity.dart';

/// Local sample data for the home “Recent Activity” section (not synced to Firestore).
abstract final class SampleData {
  static const List<SampleActivity> recentActivity = [
    SampleActivity(
      title: 'Phrase practice',
      subtitle: 'Silver compass acknowledged',
      timeLabel: '2h ago',
    ),
    SampleActivity(
      title: 'Contact added',
      subtitle: 'Sam Rivera marked as trusted',
      timeLabel: 'Yesterday',
    ),
    SampleActivity(
      title: 'Guard session',
      subtitle: 'Ended after 45 minutes',
      timeLabel: 'Apr 1',
    ),
  ];
}
