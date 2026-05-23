import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../data/chargix_data.dart';
import '../../models/charging_session_model.dart';
import '../../theme/tokens/tokens.dart';
import '../../widgets/chargix/empty_state.dart';
import '../../widgets/chargix/firebase_stream_view.dart';
import '../../widgets/chargix/premium_card.dart';

class ChargingHistoryScreen extends StatelessWidget {
  const ChargingHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Charging history')),
        body: const ChargixEmptyState(
          icon: Icons.lock_outline_rounded,
          title: 'Sign in required',
          message: 'Your completed sessions appear here after charging.',
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Charging history')),
      body: FirebaseStreamView<List<ChargingSessionModel>>(
        stream: ChargixData.chargingSessions.watchSessionsForUser(uid),
        emptyIcon: Icons.bolt_outlined,
        emptyTitle: 'No sessions yet',
        emptyMessage: 'Start a charging session to build your history.',
        builder: (context, sessions) {
          return ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.screenGutter),
            itemCount: sessions.length,
            separatorBuilder: (context, index) =>
                const SizedBox(height: AppSpacing.md),
            itemBuilder: (context, index) {
              final s = sessions[index];
              final ended = s.endedAt;
              final subtitle = ended != null
                  ? 'Ended ${ended.toLocal()}'
                  : 'In progress';
              return PremiumCard(
                child: Row(
                  children: [
                    Icon(Icons.bolt_rounded,
                        color: Theme.of(context).colorScheme.primary),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${s.energyDeliveredKwh?.toStringAsFixed(1) ?? '—'} kWh',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          Text(subtitle),
                        ],
                      ),
                    ),
                    Text(
                      s.status.value.toUpperCase(),
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
