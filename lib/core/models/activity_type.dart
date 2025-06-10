enum ActivityType {
  laying(1, 'Laying Down'),
  sitting(4, 'Sitting'),
  standing(3, 'Standing'),
  walking(0, 'Walking'),
  walkingDownstairs(2, 'Walking Downstairs'),
  walkingUpstairs(5, 'Walking Upstairs');

  const ActivityType(this.value, this.displayName);

  final int value;
  final String displayName;

  static ActivityType fromValue(int value) {
    return ActivityType.values.firstWhere(
      (activity) => activity.value == value,
      orElse: () => ActivityType.standing,
    );
  }

  static String getDisplayName(int value) {
    return fromValue(value).displayName;
  }
}
