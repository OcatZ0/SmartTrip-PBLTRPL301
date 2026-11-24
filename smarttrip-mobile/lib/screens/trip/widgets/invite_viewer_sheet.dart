import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_config.dart';
import '../../../core/error/api_failure.dart';
import '../../../core/error/trip_error_message.dart';
import '../../../core/theme/app_colors.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/trip.dart';
import '../../../services/trip_service.dart';
import '../../../widgets/primary_button.dart';

/// F015 Mengundang Viewer: the owner invites a registered user by email or
/// through an invite link, sees who can view the trip and revokes access.
/// Viewers only read the trip.
class InviteViewerSheet extends ConsumerStatefulWidget {
  const InviteViewerSheet({super.key, required this.tripsId});

  final int tripsId;

  @override
  ConsumerState<InviteViewerSheet> createState() => _InviteViewerSheetState();
}

class _InviteViewerSheetState extends ConsumerState<InviteViewerSheet> {
  final _emailCtrl = TextEditingController();
  List<TripViewer>? _viewers;
  String? _loadError;
  String? _emailError;
  String? _inviteToken;
  bool _busy = false;

  TripService get _trips => ref.read(tripServiceProvider);

  @override
  void initState() {
    super.initState();
    _loadViewers();
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadViewers() async {
    try {
      final viewers = await _trips.fetchViewers(widget.tripsId);
      if (mounted) setState(() => _viewers = viewers);
    } catch (error) {
      if (mounted) setState(() => _loadError = tripErrorMessage(error, AppLocalizations.of(context)));
    }
  }

  /// Runs one API call with the buttons disabled; errors go to a snackbar.
  Future<void> _run(Future<void> Function() action) async {
    setState(() => _busy = true);
    try {
      await action();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(tripErrorMessage(error, AppLocalizations.of(context)))));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _invite() async {
    final email = _emailCtrl.text.trim();
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      setState(() => _emailError = 'Masukkan email yang valid.');
      return;
    }
    setState(() {
      _emailError = null;
      _busy = true;
    });
    try {
      final viewer = await _trips.inviteViewer(widget.tripsId, email);
      if (!mounted) return;
      setState(() {
        final current = _viewers ?? [];
        _viewers = [...current.where((v) => v.usersId != viewer.usersId), viewer];
      });
      _emailCtrl.clear();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${viewer.name} sekarang dapat melihat trip ini')));
    } on ValidationFailure catch (failure) {
      if (mounted) setState(() => _emailError = failure.firstError('email') ?? failure.message);
    } catch (error) {
      if (mounted) setState(() => _emailError = tripErrorMessage(error, AppLocalizations.of(context)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _remove(TripViewer viewer) => _run(() async {
        await _trips.removeViewer(widget.tripsId, viewer.usersId);
        if (mounted) setState(() => _viewers = _viewers?.where((v) => v.usersId != viewer.usersId).toList());
      });

  Future<void> _createLink() => _run(() async {
        final token = await _trips.createViewerInviteLink(widget.tripsId);
        if (mounted) setState(() => _inviteToken = token);
      });

  Future<void> _disableLink() => _run(() async {
        await _trips.disableViewerInviteLink(widget.tripsId);
        if (!mounted) return;
        setState(() => _inviteToken = null);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tautan undangan dimatikan. Viewer yang sudah bergabung tetap punya akses.')),
        );
      });

  Future<void> _copyLink(String link) async {
    final messenger = ScaffoldMessenger.of(context);
    await Clipboard.setData(ClipboardData(text: link));
    messenger.showSnackBar(const SnackBar(content: Text('Tautan undangan disalin')));
  }

  @override
  Widget build(BuildContext context) {
    final token = _inviteToken;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, 20 + MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Undang ke Itinerary', style: appText(18, FontWeight.w800, AppColors.ink, height: 24)),
            const SizedBox(height: 4),
            Text(
              'Viewer hanya dapat melihat trip ini, tidak dapat mengubahnya.',
              style: appText(13, FontWeight.w500, AppColors.inkMuted, height: 18),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              enabled: !_busy,
              onSubmitted: (_) => _invite(),
              style: appText(14, FontWeight.w600, AppColors.ink),
              decoration: InputDecoration(
                hintText: 'Email pengguna SmartTrip',
                hintStyle: appText(14, FontWeight.w500, AppColors.inkMuted),
                errorText: _emailError,
                prefixIcon: const Icon(Icons.mail_outline_rounded, color: AppColors.inkMuted),
                filled: true,
                fillColor: AppColors.field,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 12),
            PrimaryButton(label: 'Undang sebagai Viewer', isLoading: _busy, onPressed: _busy ? null : _invite),
            const SizedBox(height: 20),
            Text('Tautan undangan', style: appText(14, FontWeight.w800, AppColors.ink)),
            const SizedBox(height: 4),
            Text(
              'Penerima perlu login, lalu otomatis menjadi viewer.',
              style: appText(12, FontWeight.w500, AppColors.inkMuted, height: 16),
            ),
            const SizedBox(height: 8),
            if (token == null)
              OutlinedButton.icon(
                onPressed: _busy ? null : _createLink,
                icon: const Icon(Icons.link_rounded),
                label: const Text('Buat tautan undangan'),
              )
            else ...[
              _InviteLinkField(link: AppConfig.viewerInviteUrl(token), onCopy: _copyLink),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _busy ? null : _disableLink,
                  child: const Text('Matikan tautan'),
                ),
              ),
            ],
            const SizedBox(height: 16),
            Text('Yang dapat melihat', style: appText(14, FontWeight.w800, AppColors.ink)),
            const SizedBox(height: 4),
            _ViewerList(viewers: _viewers, error: _loadError, busy: _busy, onRemove: _remove),
          ],
        ),
      ),
    );
  }
}

class _InviteLinkField extends StatelessWidget {
  const _InviteLinkField({required this.link, required this.onCopy});

  final String link;
  final ValueChanged<String> onCopy;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(left: 14, right: 4),
      decoration: BoxDecoration(color: AppColors.field, borderRadius: BorderRadius.circular(14)),
      child: Row(
        children: [
          const Icon(Icons.link_rounded, size: 18, color: AppColors.inkMuted),
          const SizedBox(width: 8),
          Expanded(
            child: Text(link, maxLines: 1, overflow: TextOverflow.ellipsis, style: appText(13, FontWeight.w600, AppColors.ink)),
          ),
          IconButton(
            tooltip: 'Salin tautan',
            icon: const Icon(Icons.copy_rounded, size: 18, color: AppColors.sea600),
            onPressed: () => onCopy(link),
          ),
        ],
      ),
    );
  }
}

class _ViewerList extends StatelessWidget {
  const _ViewerList({required this.viewers, required this.error, required this.busy, required this.onRemove});

  final List<TripViewer>? viewers;
  final String? error;
  final bool busy;
  final ValueChanged<TripViewer> onRemove;

  @override
  Widget build(BuildContext context) {
    final muted = appText(13, FontWeight.w500, AppColors.inkMuted, height: 18);
    final list = viewers;
    if (error != null) return Text(error!, style: muted);
    if (list == null) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (list.isEmpty) return Text('Belum ada viewer.', style: muted);
    return Column(
      children: [
        for (final viewer in list)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const CircleAvatar(
              backgroundColor: AppColors.field,
              child: Icon(Icons.person_outline_rounded, color: AppColors.sea600),
            ),
            title: Text(viewer.name, style: appText(14, FontWeight.w700, AppColors.ink)),
            subtitle: Text(viewer.email, style: muted),
            trailing: IconButton(
              tooltip: 'Cabut akses',
              icon: const Icon(Icons.person_remove_outlined, color: AppColors.inkMuted),
              onPressed: busy ? null : () => onRemove(viewer),
            ),
          ),
      ],
    );
  }
}
