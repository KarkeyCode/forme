import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../services/app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';

final _fmt = NumberFormat.decimalPattern('en_US');

class RewardsScreen extends StatelessWidget {
  const RewardsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();

    return Scaffold(
      body: BlurBackground(
        child: SafeArea(
          child: Column(children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 12, 0),
              child: Row(children: [
                IconButton(
                  onPressed: () => context.canPop() ? context.pop() : context.go('/home'),
                  icon: Icon(Icons.arrow_back, color: context.fg),
                ),
                Text('rewards',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: context.fg)),
              ]),
            ),
            // Balance
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 6, 20, 0),
              child: GlassCard(
                child: Row(children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: MaeveColors.green.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.track_changes, color: MaeveColors.green),
                  ),
                  const SizedBox(width: 14),
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('your balance', style: TextStyle(fontSize: 13, color: context.fg.withValues(alpha: 0.6))),
                    Text('${_fmt.format(s.points)} points',
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: context.fg)),
                  ]),
                ]),
              ),
            ),
            const SizedBox(height: 14),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 90),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 14,
                  crossAxisSpacing: 14,
                  childAspectRatio: 0.82,
                ),
                itemCount: kGiftCards.length,
                itemBuilder: (_, i) => _GiftTile(index: i),
              ),
            ),
          ]),
        ),
      ),
      // Prototype banner
      bottomNavigationBar: Container(
        color: MaeveColors.red.withValues(alpha: context.isDark ? 0.18 : 0.12),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Icon(Icons.construction, color: MaeveColors.red, size: 18),
              const SizedBox(width: 8),
              Flexible(
                child: Text('Prototype — redemptions are a demo and won\'t be fulfilled.',
                    style: TextStyle(fontSize: 12.5, color: context.fg, fontWeight: FontWeight.w500)),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

class _GiftTile extends StatelessWidget {
  const _GiftTile({required this.index});
  final int index;

  void _claim(BuildContext context) {
    final s = context.read<AppState>();
    final g = kGiftCards[index];
    if (s.claimedGiftCards.contains(index)) return;
    if (!s.canClaim(g)) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('You need ${_fmt.format(g.cost)} points for this')));
      return;
    }
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Redeem ${g.brand} ${g.amount}?'),
        content: Text('This will deduct ${_fmt.format(g.cost)} points.\n\nNote: this is a prototype — no real gift card is issued.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              s.claimGiftCard(index);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${g.brand} redeemed (demo) — check back when rewards go live')));
            },
            child: const Text('Redeem'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final g = kGiftCards[index];
    final claimed = s.claimedGiftCards.contains(index);
    final affordable = s.canClaim(g);
    final accent = Color(g.color);

    return GlassCard(
      padding: const EdgeInsets.all(14),
      onTap: () => _claim(context),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(color: accent.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(12)),
          child: Icon(Icons.card_giftcard, color: accent, size: 22),
        ),
        const Spacer(),
        Text(g.brand, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: context.fg)),
        Text(g.amount, style: TextStyle(fontSize: 13, color: context.fg.withValues(alpha: 0.6))),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 8),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: claimed
                ? MaeveColors.green.withValues(alpha: 0.15)
                : affordable
                    ? context.fg.withValues(alpha: 0.9)
                    : context.fg.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            claimed ? 'redeemed' : '${_fmt.format(g.cost)} pts',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: claimed
                  ? MaeveColors.green
                  : affordable
                      ? (context.isDark ? Colors.black : Colors.white)
                      : context.fg.withValues(alpha: 0.5),
            ),
          ),
        ),
      ]),
    );
  }
}
