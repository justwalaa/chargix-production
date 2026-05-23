import 'package:flutter/material.dart';

import 'empty_state.dart';
import 'chargix_shimmer.dart';

/// Standard loading / empty / error / data wrapper for Firestore [StreamBuilder]s.
class FirebaseStreamView<T> extends StatelessWidget {
  const FirebaseStreamView({
    super.key,
    required this.stream,
    required this.builder,
    this.loading,
    this.emptyIcon = Icons.inbox_outlined,
    this.emptyTitle = 'Nothing here yet',
    this.emptyMessage = 'Check back soon for updates.',
    this.emptyActionLabel,
    this.onEmptyAction,
  });

  final Stream<T>? stream;
  final Widget Function(BuildContext context, T data) builder;
  final Widget? loading;
  final IconData emptyIcon;
  final String emptyTitle;
  final String emptyMessage;
  final String? emptyActionLabel;
  final VoidCallback? onEmptyAction;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<T>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return loading ?? const StationListSkeleton();
        }
        if (snapshot.hasError) {
          return ChargixEmptyState(
            icon: Icons.cloud_off_rounded,
            title: 'Connection issue',
            message: snapshot.error.toString(),
            actionLabel: 'Try again',
            onAction: () {
              (context as Element).markNeedsBuild();
            },
          );
        }
        final data = snapshot.data;
        if (data == null) {
          return ChargixEmptyState(
            icon: emptyIcon,
            title: emptyTitle,
            message: emptyMessage,
            actionLabel: emptyActionLabel,
            onAction: onEmptyAction,
          );
        }
        if (data is List && data.isEmpty) {
          return ChargixEmptyState(
            icon: emptyIcon,
            title: emptyTitle,
            message: emptyMessage,
            actionLabel: emptyActionLabel,
            onAction: onEmptyAction,
          );
        }
        return builder(context, data);
      },
    );
  }
}
