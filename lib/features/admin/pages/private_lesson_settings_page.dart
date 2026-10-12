import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../../theme/app_snack_bars.dart';
import '../../../theme/app_theme.dart';
import '../../../theme/pilates_loading_indicator.dart';
import '../../bookings/data/booking_gateway.dart';

class PrivateLessonSettingsPage extends StatefulWidget {
  const PrivateLessonSettingsPage({super.key, required this.bookings});

  final AdminBookingGateway bookings;

  @override
  State<PrivateLessonSettingsPage> createState() =>
      _PrivateLessonSettingsPageState();
}

class _PrivateLessonSettingsPageState extends State<PrivateLessonSettingsPage> {
  late Future<bool> _enabled = widget.bookings.isPrivateLessonFeatureEnabled();
  bool _saving = false;

  Future<void> _setEnabled(bool enabled) async {
    setState(() => _saving = true);
    try {
      await widget.bookings.setPrivateLessonFeatureEnabled(enabled: enabled);
      if (!mounted) return;
      setState(() {
        _enabled = Future.value(enabled);
      });
      AppNotifications.success(AppLocalizations.of(context).text(enabled
          ? 'privateLessonFeatureOpened'
          : 'privateLessonFeatureClosed'));
    } catch (_) {
      if (mounted) {
        AppNotifications.error(
            AppLocalizations.of(context).text('privateLessonFeatureSaveError'));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(strings.text('privateLessonSettings'))),
      body: FutureBuilder<bool>(
        future: _enabled,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: PilatesLoadingIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: TextButton.icon(
                onPressed: () => setState(() =>
                    _enabled = widget.bookings.isPrivateLessonFeatureEnabled()),
                icon: const Icon(Icons.refresh),
                label: Text(strings.text('tryAgain')),
              ),
            );
          }
          final enabled = snapshot.data!;
          return ListView(padding: const EdgeInsets.all(24), children: [
            Text(strings.text('privateLessonSettings'),
                style: Theme.of(context).textTheme.headlineLarge),
            const SizedBox(height: 8),
            Text(strings.text('privateLessonSettingsDetail'),
                style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: 24),
            SwitchListTile.adaptive(
              contentPadding: const EdgeInsets.symmetric(horizontal: 18),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(color: Color(0xFFD8DED5))),
              title: Text(strings.text('privateLessonFeature')),
              subtitle: Text(strings.text(enabled
                  ? 'privateLessonFeatureOpenDetail'
                  : 'privateLessonFeatureClosedDetail')),
              value: enabled,
              activeTrackColor: AppTheme.sage,
              activeThumbColor: Colors.white,
              onChanged: _saving ? null : _setEnabled,
            ),
          ]);
        },
      ),
    );
  }
}
