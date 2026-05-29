import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../theme/tokens/tokens.dart';
import '../widgets/auth/session_loading_screen.dart';
import '../widgets/chargix/empty_state.dart';
import '../widgets/chargix/premium_card.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pending Stations'),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('stations')
            .where('status', whereIn: ['pending', 'pendingApproval'])
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const SessionLoadingScreen(message: 'Loading queue…');
          }
          if (snapshot.hasError) {
            return ChargixEmptyState(
              icon: Icons.cloud_off_rounded,
              title: 'Could not load stations',
              message: snapshot.error.toString(),
            );
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return const ChargixEmptyState(
              icon: Icons.fact_check_outlined,
              title: 'No pending stations',
              message: 'New partner registrations will appear here.',
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(AppSpacing.screenGutter),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final station =
              docs[index].data();

              final docId = docs[index].id;

              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: PremiumCard(
                  child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,
                    children: [
                      Text(
                        station['name'] ?? 'Unnamed',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),

                      const SizedBox(height: 8),

                      Text(
                        station['ownerPhoneE164']?.toString() ??
                            station['phone']?.toString() ??
                            '',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                      ),

                      const SizedBox(height: 16),

                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () async {
                                await FirebaseFirestore
                                    .instance
                                    .collection('stations')
                                    .doc(docId)
                                    .update({
                                  'status': 'approved',
                                  'isPublic': true,
                                  'availablePorts': 1,
                                });
                              },
                              child: const Text('Approve'),
                            ),
                          ),

                          const SizedBox(width: 12),

                          Expanded(
                            child: ElevatedButton(
                              onPressed: () async {
                                await FirebaseFirestore
                                    .instance
                                    .collection('stations')
                                    .doc(docId)
                                    .update({
                                  'status': 'rejected',
                                });
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    Theme.of(context).colorScheme.error,
                              ),
                              child: const Text('Reject'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}