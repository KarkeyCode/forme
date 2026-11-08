import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'auth/auth_service.dart';
import 'health_service.dart';

class FoodEntry {
  FoodEntry(this.label, this.kcal, this.time);
  final String label;
  final int kcal; // negative = burned
  final DateTime time;

  Map<String, dynamic> toJson() =>
      {'l': label, 'k': kcal, 't': time.millisecondsSinceEpoch};
  factory FoodEntry.fromJson(Map<String, dynamic> j) => FoodEntry(
      j['l'] as String, j['k'] as int, DateTime.fromMillisecondsSinceEpoch(j['t'] as int));
}

enum StepRange { week, month, total }

enum Sex { male, female, other }

/// The user's manually-entered or health-synced body profile.
class UserProfile {
  UserProfile({
    this.name = '',
    this.email = '',
    this.provider = '',
    this.nickname = '',
    this.legalName = '',
    this.username = '',
    this.heightCm,
    this.weightKg,
    this.age,
    this.sex,
    List<String>? goals,
    this.bodyFatPct,
    this.syncedFromHealth = false,
    this.photoPath = '',
  }) : goals = goals ?? [];

  String name;
  String email;
  String provider; // 'google' | 'apple' | 'email' | ''
  String nickname;
  String legalName;
  String username;
  double? heightCm;
  double? weightKg;
  int? age;
  Sex? sex;
  List<String> goals;
  double? bodyFatPct;
  bool syncedFromHealth;
  String photoPath; // local gallery image path for the avatar ('' = none)

  /// What to greet the user as, preferring their chosen nickname.
  String get displayName =>
      nickname.isNotEmpty ? nickname : (name.isNotEmpty ? name : 'Forme User');

  bool get hasBody => heightCm != null && weightKg != null;

  double? get bmi {
    if (heightCm == null || weightKg == null || heightCm == 0) return null;
    final m = heightCm! / 100;
    return weightKg! / (m * m);
  }

  /// Basal metabolic rate (Mifflin-St Jeor), used for the overview.
  int? get bmr {
    if (heightCm == null || weightKg == null || age == null) return null;
    final base = 10 * weightKg! + 6.25 * heightCm! - 5 * age!;
    final s = switch (sex) {
      Sex.male => 5,
      Sex.female => -161,
      _ => -78, // average
    };
    return (base + s).round();
  }

  double? get leanMassKg =>
      (weightKg != null && bodyFatPct != null) ? weightKg! * (1 - bodyFatPct! / 100) : null;

  Map<String, dynamic> toJson() => {
        'name': name,
        'email': email,
        'provider': provider,
        'nickname': nickname,
        'legalName': legalName,
        'username': username,
        'h': heightCm,
        'w': weightKg,
        'age': age,
        'sex': sex?.index,
        'goals': goals,
        'bf': bodyFatPct,
        'sync': syncedFromHealth,
        'photo': photoPath,
      };

  factory UserProfile.fromJson(Map<String, dynamic> j) => UserProfile(
        name: (j['name'] ?? '') as String,
        email: (j['email'] ?? '') as String,
        provider: (j['provider'] ?? '') as String,
        nickname: (j['nickname'] ?? '') as String,
        legalName: (j['legalName'] ?? '') as String,
        username: (j['username'] ?? '') as String,
        heightCm: (j['h'] as num?)?.toDouble(),
        weightKg: (j['w'] as num?)?.toDouble(),
        age: j['age'] as int?,
        sex: j['sex'] == null ? null : Sex.values[j['sex'] as int],
        goals: (j['goals'] as List?)?.map((e) => e as String).toList() ??
            // migrate the old single 'goal' field
            [if (j['goal'] != null && (j['goal'] as String).isNotEmpty) j['goal'] as String],
        bodyFatPct: (j['bf'] as num?)?.toDouble(),
        syncedFromHealth: (j['sync'] ?? false) as bool,
        photoPath: (j['photo'] ?? '') as String,
      );
}

/// A reward that points can be redeemed for (prototype — not fulfilled).
class GiftCard {
  const GiftCard(this.brand, this.amount, this.cost, this.color);
  final String brand;
  final String amount; // e.g. "$10"
  final int cost; // points
  final int color; // brand accent (ARGB)
}

const kGiftCards = [
  GiftCard('Amazon', '\$10', 2000, 0xFFFF9900),
  GiftCard('Spotify', '3 months', 2500, 0xFF1DB954),
  GiftCard('Apple', '\$15', 3000, 0xFFA2AAAD),
  GiftCard('Uber Eats', '\$20', 3500, 0xFF06C167),
  GiftCard('Nike', '\$25', 5000, 0xFFF04E23),
  GiftCard('Starbucks', '\$10', 2200, 0xFF00704A),
];

class AppState extends ChangeNotifier {
  late SharedPreferences _prefs;
  final health = HealthService();
  final auth = createAuthService();

  bool onboarded = false;
  bool darkMode = false;
  bool isPro = false;
  int points = 1340;
  List<FoodEntry> foods = [];
  Set<int> completedExercises = {};

  // Auth + profile
  bool get signedIn => profile.provider.isNotEmpty;
  UserProfile profile = UserProfile();
  List<int> claimedGiftCards = []; // indexes into kGiftCards

  StepRange range = StepRange.week;
  Map<StepRange, int> steps = {StepRange.week: 8204, StepRange.month: 34120, StepRange.total: 212480};
  List<double> weekSteps = [5200, 7400, 6100, 9800, 7200, 10400, 8204];
  // Weekly series for the swipeable metric graphs (demo data; HR/stress have
  // no cross-platform health API so these stay synthetic).
  List<double> weekHeartRate = [68, 72, 70, 76, 69, 74, 71];
  List<double> weekStress = [32, 46, 38, 55, 41, 48, 36];
  int restingHr = 62;
  int currentStress = 38;
  bool usingRealSteps = false;

  // ---- Water tracking ----
  int waterGoalMl = 2000; // 1000..5000
  int waterLoggedMl = 0; // today
  String _waterDate = '';
  static const kGlassMl = 250;
  static const kMaxWaterMl = 5000; // can't drink more than 5L

  // ---- Reminders / notifications ----
  // Off by default — the user opts in during onboarding or from settings.
  bool notificationsEnabled = false;
  bool waterRemindersEnabled = false;
  int workoutHour = 18; // preferred workout time (24h)
  int workoutMinute = 0;

  double get waterProgress => (waterLoggedMl / waterGoalMl).clamp(0.0, 1.0);
  int get glassesLogged => waterLoggedMl ~/ kGlassMl;

  /// PRO perk: 25% more points per task (workouts, water, etc.).
  double get pointsMultiplier => isPro ? 1.25 : 1.0;
  int scaledPoints(int base) => (base * pointsMultiplier).round();
  int get waterPointsPerGlass => scaledPoints(5);

  Future<void> load() async {
    _prefs = await SharedPreferences.getInstance();
    onboarded = _prefs.getBool('onboarded') ?? false;
    darkMode = _prefs.getBool('dark') ?? false;
    isPro = _prefs.getBool('pro') ?? false;
    points = _prefs.getInt('points') ?? 1340;
    completedExercises =
        (_prefs.getStringList('done') ?? []).map(int.parse).toSet();
    claimedGiftCards =
        (_prefs.getStringList('claimed') ?? []).map(int.parse).toList();
    // Water + reminders
    waterGoalMl = _prefs.getInt('waterGoal') ?? 2000;
    waterLoggedMl = _prefs.getInt('waterLogged') ?? 0;
    _waterDate = _prefs.getString('waterDate') ?? '';
    _rolloverWater();
    notificationsEnabled = _prefs.getBool('notif') ?? false;
    waterRemindersEnabled = _prefs.getBool('waterRemind') ?? false;
    workoutHour = _prefs.getInt('woHour') ?? 18;
    workoutMinute = _prefs.getInt('woMin') ?? 0;
    final profRaw = _prefs.getString('profile');
    if (profRaw != null) {
      profile = UserProfile.fromJson(jsonDecode(profRaw) as Map<String, dynamic>);
    }
    final raw = _prefs.getString('foods');
    if (raw != null) {
      foods = (jsonDecode(raw) as List)
          .map((e) => FoodEntry.fromJson(e as Map<String, dynamic>))
          .toList();
    } else {
      final now = DateTime.now();
      foods = [
        FoodEntry('A banana', 105, now),
        FoodEntry('Half a bowl of oatmeal', 220, now),
        FoodEntry('Grilled Chicken salad', 480, now),
        FoodEntry('Ran 5km 3hrs ago', -435, now),
      ];
    }
    if (onboarded) refreshSteps();
  }

  Future<void> refreshSteps() async {
    final r = await health.fetch();
    if (r != null) {
      steps = r.totals;
      weekSteps = r.week;
      usingRealSteps = true;
      notifyListeners();
    }
  }

  Future<bool> requestHealth() => health.requestPermission();

  // ---- Auth ----------------------------------------------------------------

  Future<bool> signIn(Future<AuthUser?> Function() method) async {
    final user = await method();
    if (user == null) return false;
    profile
      ..name = user.name
      ..email = user.email
      ..provider = user.provider;
    _saveProfile();
    notifyListeners();
    return true;
  }

  Future<bool> signInWithGoogle({String? email}) =>
      signIn(() => auth.signInWithGoogle(email: email));
  Future<bool> signInWithApple({String? email}) =>
      signIn(() => auth.signInWithApple(email: email));
  Future<bool> signInWithEmail(String email, String password) =>
      signIn(() => auth.signInWithEmail(email, password));

  Future<void> signOut() async {
    await auth.signOut();
    profile = UserProfile();
    _saveProfile();
    notifyListeners();
  }

  // ---- Profile -------------------------------------------------------------

  void saveProfile(UserProfile p) {
    profile = p;
    _saveProfile();
    notifyListeners();
  }

  /// Set (or clear with '') the local gallery photo used for the avatar.
  void setPhotoPath(String path) {
    profile.photoPath = path;
    _saveProfile();
    notifyListeners();
  }

  /// Pull body stats, heart rate and body composition from connected health
  /// data (falls back to demo values on web / when nothing is available).
  /// Stress has no standard Health Connect metric, so it's estimated from
  /// heart rate.
  Future<void> syncProfileFromHealth() async {
    final ok = await requestHealth();
    final v = await health.fetchBody();
    if (v != null) {
      if (v.heightCm != null) profile.heightCm = v.heightCm;
      if (v.weightKg != null) profile.weightKg = v.weightKg;
      if (v.bodyFatPct != null) profile.bodyFatPct = v.bodyFatPct;
      if (v.restingHr != null) restingHr = v.restingHr!;
      if (v.weekHeartRate != null && v.weekHeartRate!.isNotEmpty) {
        weekHeartRate = v.weekHeartRate!;
      }
    }
    // Sensible demo defaults so the overview is populated in the prototype.
    profile
      ..heightCm ??= 178
      ..weightKg ??= 74
      ..age ??= 24
      ..sex ??= Sex.male
      ..bodyFatPct ??= 17
      ..syncedFromHealth = ok || !kIsWeb;
    // Estimate stress from heart rate (no standard health stress metric).
    weekStress = [for (final hr in weekHeartRate) _stressFromHr(hr).toDouble()];
    currentStress = _stressFromHr(weekHeartRate.last);
    _saveProfile();
    notifyListeners();
  }

  int _stressFromHr(double hr) => ((hr - 55) * 1.7).clamp(6, 96).round();

  // ---- Water ---------------------------------------------------------------

  String _todayKey() {
    final n = DateTime.now();
    return '${n.year}-${n.month}-${n.day}';
  }

  void _rolloverWater() {
    final k = _todayKey();
    if (_waterDate != k) {
      _waterDate = k;
      waterLoggedMl = 0;
      _prefs.setInt('waterLogged', 0);
      _prefs.setString('waterDate', k);
    }
  }

  /// Log a glass of water. Awards 5 points per effective log, but only up to
  /// the 5L daily cap (you can't realistically drink more than 5L).
  void logWater([int ml = kGlassMl]) {
    _rolloverWater();
    if (waterLoggedMl >= kMaxWaterMl) return;
    final before = waterLoggedMl;
    waterLoggedMl = (waterLoggedMl + ml).clamp(0, kMaxWaterMl);
    if (waterLoggedMl > before) {
      points += waterPointsPerGlass;
      _prefs.setInt('points', points);
    }
    _prefs.setInt('waterLogged', waterLoggedMl);
    notifyListeners();
  }

  /// Remove the last glass (and the points it earned) — for mistaps.
  void undoWater([int ml = kGlassMl]) {
    _rolloverWater();
    if (waterLoggedMl <= 0) return;
    waterLoggedMl = (waterLoggedMl - ml).clamp(0, kMaxWaterMl);
    points = (points - waterPointsPerGlass).clamp(0, 1 << 31);
    _prefs.setInt('waterLogged', waterLoggedMl);
    _prefs.setInt('points', points);
    notifyListeners();
  }

  void setWaterGoal(int ml) {
    waterGoalMl = ml.clamp(1000, kMaxWaterMl);
    _prefs.setInt('waterGoal', waterGoalMl);
    notifyListeners();
  }

  void setReminderPrefs({bool? notifications, bool? water, int? hour, int? minute}) {
    if (notifications != null) {
      notificationsEnabled = notifications;
      _prefs.setBool('notif', notifications);
    }
    if (water != null) {
      waterRemindersEnabled = water;
      _prefs.setBool('waterRemind', water);
    }
    if (hour != null) {
      workoutHour = hour;
      _prefs.setInt('woHour', hour);
    }
    if (minute != null) {
      workoutMinute = minute;
      _prefs.setInt('woMin', minute);
    }
    notifyListeners();
  }

  // ---- Gift cards ----------------------------------------------------------

  bool canClaim(GiftCard g) => points >= g.cost;

  bool claimGiftCard(int index) {
    final g = kGiftCards[index];
    if (points < g.cost || claimedGiftCards.contains(index)) return false;
    points -= g.cost;
    claimedGiftCards.add(index);
    _prefs.setInt('points', points);
    _prefs.setStringList('claimed', claimedGiftCards.map((e) => '$e').toList());
    notifyListeners();
    return true;
  }

  // ---- Onboarding / settings ----------------------------------------------

  void completeOnboarding() {
    onboarded = true;
    _prefs.setBool('onboarded', true);
    notifyListeners();
    refreshSteps();
  }

  void resetOnboarding() {
    onboarded = false;
    _prefs.setBool('onboarded', false);
    notifyListeners();
  }

  void toggleDark() {
    darkMode = !darkMode;
    _prefs.setBool('dark', darkMode);
    notifyListeners();
  }

  void setPro(bool v) {
    isPro = v;
    _prefs.setBool('pro', v);
    notifyListeners();
  }

  void setRange(StepRange r) {
    range = r;
    notifyListeners();
  }

  void addFood(FoodEntry e) {
    foods.add(e);
    _saveFoods();
    notifyListeners();
  }

  void removeFood(int i) {
    foods.removeAt(i);
    _saveFoods();
    notifyListeners();
  }

  void toggleExercise(int i, int reward) {
    final r = scaledPoints(reward); // PRO earns 25% more
    if (completedExercises.remove(i)) {
      points -= r;
    } else {
      completedExercises.add(i);
      points += r;
    }
    _prefs.setStringList('done', completedExercises.map((e) => '$e').toList());
    _prefs.setInt('points', points);
    notifyListeners();
  }

  int get totalKcal => foods.fold(0, (a, e) => a + e.kcal);

  void _saveFoods() =>
      _prefs.setString('foods', jsonEncode(foods.map((e) => e.toJson()).toList()));

  void _saveProfile() =>
      _prefs.setString('profile', jsonEncode(profile.toJson()));
}
