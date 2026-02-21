/// Enums for user preferences
enum MusicPreference {
  none,
  soft,
  loud;

  String get displayName {
    switch (this) {
      case MusicPreference.none:
        return 'No Music';
      case MusicPreference.soft:
        return 'Soft Music';
      case MusicPreference.loud:
        return 'Loud Music';
    }
  }

  String get icon {
    switch (this) {
      case MusicPreference.none:
        return '🔇';
      case MusicPreference.soft:
        return '🎵';
      case MusicPreference.loud:
        return '🔊';
    }
  }
}

enum TalkPreference {
  quiet,
  normal,
  talkative;

  String get displayName {
    switch (this) {
      case TalkPreference.quiet:
        return 'Quiet Ride';
      case TalkPreference.normal:
        return 'Normal Chat';
      case TalkPreference.talkative:
        return 'Love to Talk';
    }
  }

  String get icon {
    switch (this) {
      case TalkPreference.quiet:
        return '🤫';
      case TalkPreference.normal:
        return '💬';
      case TalkPreference.talkative:
        return '🗣️';
    }
  }
}

enum GenderPreference {
  any,
  male,
  female,
  same;

  String get displayName {
    switch (this) {
      case GenderPreference.any:
        return 'Any Gender';
      case GenderPreference.male:
        return 'Male Only';
      case GenderPreference.female:
        return 'Female Only';
      case GenderPreference.same:
        return 'Same Gender';
    }
  }
}

enum RideFrequency {
  daily,
  weekly,
  occasional;

  String get displayName {
    switch (this) {
      case RideFrequency.daily:
        return 'Daily Commute';
      case RideFrequency.weekly:
        return 'Weekly';
      case RideFrequency.occasional:
        return 'Occasional';
    }
  }

  String get icon {
    switch (this) {
      case RideFrequency.daily:
        return '📅';
      case RideFrequency.weekly:
        return '📆';
      case RideFrequency.occasional:
        return '🗓️';
    }
  }
}
