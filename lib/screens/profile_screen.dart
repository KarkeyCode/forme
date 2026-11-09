import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../services/app_state.dart';
import '../services/notification_service.dart';
import '../theme.dart';
import '../widgets/avatar.dart';
import '../widgets/common.dart';
import 'avatar_crop_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<void> _pickPhoto(BuildContext context, AppState s) async {
    final path = await pickGalleryImage();
    if (path == null || !context.mounted) return;
    final cropped = await cropAvatar(context, path);
    if (cropped != null) s.setPhotoPath(cropped);
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final p = s.profile;
    final name = p.displayName;
    final avatar = avatarProvider(p.photoPath);

    Widget item(IconData i, String t, {Widget? trailing, VoidCallback? onTap, Color? color}) => ListTile(
          leading: Icon(i, color: color ?? context.fg),
          title: Text(t, style: TextStyle(color: color ?? context.fg)),
          trailing: trailing,
          onTap: onTap,
        );

    return BlurBackground(
      child: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
          children: [
            Text('Profile', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: context.fg)),
            const SizedBox(height: 18),
            GlassCard(
              child: Row(children: [
                GestureDetector(
                  onTap: () => _pickPhoto(context, s),
                  child: Stack(children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: context.fg,
                      backgroundImage: avatar,
                      child: avatar == null
                          ? MaeveLogo(size: 22, color: context.isDark ? Colors.black : Colors.white)
                          : null,
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: MaeveColors.blue,
                          shape: BoxShape.circle,
                          border: Border.all(color: context.isDark ? const Color(0xFF141414) : Colors.white, width: 2),
                        ),
                        child: const Icon(Icons.photo_camera, size: 12, color: Colors.white),
                      ),
                    ),
                  ]),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(name,
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: context.fg)),
                    if (p.username.isNotEmpty)
                      Text('@${p.username}', style: TextStyle(fontSize: 12, color: context.fg.withValues(alpha: 0.55))),
                    if (p.email.isNotEmpty)
                      Text(p.email, style: TextStyle(fontSize: 12, color: context.fg.withValues(alpha: 0.55))),
                    Text('${s.points} points · ${s.isPro ? 'PRO' : 'Free Version'}',
                        style: TextStyle(color: context.fg.withValues(alpha: 0.6))),
                  ]),
                ),
                if (p.provider.isNotEmpty)
                  Opacity(
                    opacity: 0.85,
                    child: authProviderIcon(p.provider,
                        size: 22, iconColor: context.fg.withValues(alpha: 0.6)),
                  ),
              ]),
            ),
            const SizedBox(height: 14),

            // My health profile overview
            _sectionLabel(context, 'My Health Profile'),
            GlassCard(
              onTap: () => context.push('/overview'),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  const Icon(Icons.monitor_heart_outlined, color: MaeveColors.green),
                  const SizedBox(width: 8),
                  Text('Health Profile', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: context.fg)),
                  const Spacer(),
                  Icon(Icons.chevron_right, color: context.fg.withValues(alpha: 0.5)),
                ]),
                const SizedBox(height: 12),
                if (p.hasBody)
                  Wrap(spacing: 10, runSpacing: 10, children: [
                    _chip(context, 'Height', '${p.heightCm!.round()} cm'),
                    _chip(context, 'Weight', '${p.weightKg!.round()} kg'),
                    if (p.bmi != null) _chip(context, 'BMI', p.bmi!.toStringAsFixed(1)),
                    _chip(context, 'Resting HR', '${s.restingHr} bpm'),
                    _chip(context, 'Stress', '${s.currentStress}/100'),
                    if (p.bodyFatPct != null) _chip(context, 'Body Fat', '${p.bodyFatPct!.round()}%'),
                  ])
                else
                  Text('Add your body stats to see your full health profile.',
                      style: TextStyle(fontSize: 13, color: context.fg.withValues(alpha: 0.6))),
                const SizedBox(height: 12),
                Text('Tap to view body stats, steps, heart rate, stress & body composition',
                    style: TextStyle(fontSize: 12, color: context.fg.withValues(alpha: 0.5))),
              ]),
            ),
            const SizedBox(height: 14),

            // Connected accounts
            _sectionLabel(context, 'Connected Accounts'),
            GlassCard(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Column(children: [
                for (final prov in const ['google', 'email', 'github', 'microsoft'])
                  _AccountRow(provider: prov),
              ]),
            ),
            const SizedBox(height: 14),

            _sectionLabel(context, 'Settings'),
            GlassCard(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Column(children: [
                item(Icons.card_giftcard, 'Rewards & Gift Cards',
                    trailing: Icon(Icons.chevron_right, color: context.fg.withValues(alpha: 0.4)),
                    onTap: () => context.push('/rewards')),
                // Appearance: light / dark / auto
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
                  child: Row(children: [
                    Icon(Icons.brightness_6_outlined, color: context.fg),
                    const SizedBox(width: 12),
                    Text('Appearance', style: TextStyle(color: context.fg, fontSize: 16)),
                    const Spacer(),
                    _ThemeToggle(mode: s.themeMode, onChanged: s.setThemeMode),
                  ]),
                ),
                item(Icons.vibration, 'Haptics',
                    trailing: Switch(value: s.hapticsEnabled, onChanged: s.setHaptics)),
                item(Icons.favorite_border, 'Reconnect Health Data', onTap: () async {
                  final ok = await s.requestHealth();
                  if (ok) await s.refreshSteps();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text(ok ? 'Health Connect linked' : 'Health Connect not available, using demo data')));
                  }
                }),
                item(Icons.notifications_active_outlined, 'Reminders',
                    trailing: Switch(
                      value: s.notificationsEnabled,
                      onChanged: (v) async {
                        s.setReminderPrefs(notifications: v);
                        if (v) await NotificationService.instance.requestPermission();
                        await NotificationService.instance.sync(
                          enabled: v,
                          waterReminders: s.waterRemindersEnabled,
                          workoutHour: s.workoutHour,
                          workoutMinute: s.workoutMinute,
                        );
                      },
                    )),
                item(Icons.water_drop_outlined, 'Daily Water Goal',
                    trailing: Text('${(s.waterGoalMl / 1000).toStringAsFixed(s.waterGoalMl % 1000 == 0 ? 0 : 1)} L',
                        style: TextStyle(color: context.fg.withValues(alpha: 0.6), fontWeight: FontWeight.w600)),
                    onTap: () => _editWaterGoal(context, s)),
                item(Icons.workspace_premium_outlined, s.isPro ? 'Manage PRO' : 'Upgrade To PRO',
                    onTap: () => context.push('/pro')),
                if (s.isPro)
                  item(Icons.remove_circle_outline, 'Cancel PRO (Demo)', onTap: () => s.setPro(false)),
                item(Icons.info_outline, 'About Us',
                    trailing: Icon(Icons.chevron_right, color: context.fg.withValues(alpha: 0.4)),
                    onTap: () => context.push('/about')),
                if (s.signedIn)
                  item(Icons.logout, 'Sign Out', onTap: () async {
                    await s.signOut();
                    if (context.mounted) context.go('/onboarding');
                  }),
              ]),
            ),
            const SizedBox(height: 14),

            // Dev Test Tools
            _sectionLabel(context, 'Dev Test Tools'),
            GlassCard(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Column(children: [
                item(Icons.restart_alt, 'Replay Onboarding', color: MaeveColors.red, onTap: () {
                  s.resetOnboarding();
                  context.go('/onboarding');
                }),
              ]),
            ),
            const SizedBox(height: 20),
            Center(
              child: Text('FORME v1.3.0',
                  style: TextStyle(fontSize: 12, color: context.fg.withValues(alpha: 0.4))),
            ),
          ],
        ),
      ),
    );
  }

  void _editWaterGoal(BuildContext context, AppState s) {
    var goal = s.waterGoalMl;
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Daily Water Goal'),
        content: StatefulBuilder(
          builder: (ctx, setLocal) => Column(mainAxisSize: MainAxisSize.min, children: [
            Text('${(goal / 1000).toStringAsFixed(2)} L  ·  ${(goal / 250).round()} glasses',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            Slider(
              value: goal.toDouble(),
              min: 1000,
              max: 5000,
              divisions: 16,
              label: '${(goal / 1000).toStringAsFixed(2)} L',
              onChanged: (v) => setLocal(() => goal = (v / 250).round() * 250),
            ),
          ]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              s.setWaterGoal(goal);
              Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(BuildContext context, String t) => Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 8),
        child: Text(t, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: context.fg.withValues(alpha: 0.5))),
      );

  Widget _chip(BuildContext context, String label, String value) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: context.fg.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: TextStyle(fontSize: 11, color: context.fg.withValues(alpha: 0.55))),
          Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: context.fg)),
        ]),
      );
}

/// A compact light / dark / auto segmented control.
class _ThemeToggle extends StatelessWidget {
  const _ThemeToggle({required this.mode, required this.onChanged});
  final ThemeMode mode;
  final ValueChanged<ThemeMode> onChanged;

  @override
  Widget build(BuildContext context) {
    Widget seg(ThemeMode m, IconData icon) {
      final sel = mode == m;
      return GestureDetector(
        onTap: () => onChanged(m),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: sel ? context.fg : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon,
              size: 18,
              color: sel ? (context.isDark ? Colors.black : Colors.white) : context.fg.withValues(alpha: 0.6)),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: context.fg.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        seg(ThemeMode.light, Icons.light_mode_outlined),
        seg(ThemeMode.dark, Icons.dark_mode_outlined),
        seg(ThemeMode.system, Icons.brightness_auto_outlined),
      ]),
    );
  }
}

/// A row in the Connected Accounts list: shows the provider logo, its status,
/// and a connect / disconnect action (prototype — no real OAuth linking).
class _AccountRow extends StatelessWidget {
  const _AccountRow({required this.provider});
  final String provider;

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final isPrimary = s.profile.provider == provider;
    final linked = isPrimary || s.linkedProviders.contains(provider);
    final iconColor = provider == 'microsoft' ? const Color(0xFF00A4EF) : context.fg;

    Widget trailing;
    if (isPrimary) {
      trailing = Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
            color: MaeveColors.green.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(20)),
        child: const Text('Primary',
            style: TextStyle(fontSize: 12, color: MaeveColors.green, fontWeight: FontWeight.w700)),
      );
    } else if (linked) {
      trailing = TextButton(
        onPressed: () => s.unlinkProvider(provider),
        child: Text('Disconnect', style: TextStyle(color: context.fg.withValues(alpha: 0.6), fontSize: 13)),
      );
    } else {
      trailing = OutlinedButton(
        style: OutlinedButton.styleFrom(
          foregroundColor: context.fg,
          side: BorderSide(color: context.fg.withValues(alpha: 0.25)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          visualDensity: VisualDensity.compact,
        ),
        onPressed: () {
          s.linkProvider(provider);
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('${authProviderLabel(provider)} connected')));
        },
        child: const Text('Connect'),
      );
    }

    return ListTile(
      leading: SizedBox(width: 26, child: Center(child: authProviderIcon(provider, size: 22, iconColor: iconColor))),
      title: Text(authProviderLabel(provider), style: TextStyle(color: context.fg)),
      subtitle: Text(
        isPrimary ? 'Your main sign in' : (linked ? 'Connected' : 'Not connected'),
        style: TextStyle(fontSize: 12, color: context.fg.withValues(alpha: 0.5)),
      ),
      trailing: trailing,
    );
  }
}
