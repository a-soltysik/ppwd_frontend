enum ActivityType {
  laying(0, 'Laying Down'),
  sitting(1, 'Sitting'),
  standing(2, 'Standing'),
  walking(3, 'Walking'),
  walkingDownstairs(4, 'Walking Downstairs'),
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
