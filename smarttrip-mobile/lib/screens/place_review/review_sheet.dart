import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/auth/session_controller.dart';
import '../../core/error/api_failure.dart';
import '../../core/error/trip_error_message.dart';
import '../../core/theme/app_colors.dart';
import '../../l10n/app_localizations.dart';
import '../../models/place.dart';
import '../../services/place_service.dart';
import '../../widgets/place_photo.dart' as photo;
import '../../widgets/primary_button.dart';
import '../catalog/place_detail_screen.dart' show placeDetailProvider;

/// F014 / UC-016 Mengelola Ulasan: a bottom sheet to write, change or delete
/// the user's one review of a place. Opened from the place detail or a trip
/// stop; a stop passes [itineraryItemsId] so a new review is linked to it (A3).
class ReviewSheet extends ConsumerStatefulWidget {
  const ReviewSheet({super.key, required this.placesId, this.itineraryItemsId});

  final int placesId;
  final int? itineraryItemsId;

  /// The same limit as the API.
  static const maxCommentLength = 2000;

  static Future<void> show(BuildContext context, {required int placesId, int? itineraryItemsId}) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => ReviewSheet(placesId: placesId, itineraryItemsId: itineraryItemsId),
    );
  }

  @override
  ConsumerState<ReviewSheet> createState() => _ReviewSheetState();
}

class _ReviewSheetState extends ConsumerState<ReviewSheet> {
  final _commentCtrl = TextEditingController();
  int _rating = 0;
  bool _prefilled = false;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  PlaceReview? _ownReview(PlaceDetail detail) {
    final usersId = ref.read(sessionControllerProvider).valueOrNull?.usersId;
    if (usersId == null) return null;
    for (final review in detail.reviews) {
      if (review.usersId == usersId) return review;
    }
    return null;
  }

  static String _ratingLabel(int rating) => switch (rating) {
        5 => 'Luar biasa',
        4 => 'Sangat puas',
        3 => 'Cukup baik',
        2 => 'Kurang puas',
        1 => 'Mengecewakan',
        _ => 'Pilih 1 sampai 5 bintang',
      };

  Future<void> _save(PlaceReview? own) async {
    if (_rating < 1) {
      setState(() => _error = 'Pilih rating 1 sampai 5 bintang.');
      return;
    }
    final comment = _commentCtrl.text.trim();
    await _run(() {
      final service = ref.read(placeServiceProvider);
      return own == null
          ? service.createReview(widget.placesId,
              rating: _rating, comment: comment.isEmpty ? null : comment, itineraryItemsId: widget.itineraryItemsId)
          : service.updateReview(own.placeReviewsId, rating: _rating, comment: comment.isEmpty ? null : comment);
    }, done: own == null ? 'Ulasan terkirim. Terima kasih!' : 'Ulasan diperbarui.');
  }

  Future<void> _delete(PlaceReview own) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Hapus ulasan?'),
        content: const Text('Ulasanmu untuk tempat ini akan dihapus dan rating tempat ikut diperbarui.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: const Text('Batal')),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: TextButton.styleFrom(foregroundColor: Theme.of(dialogContext).colorScheme.error),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await _run(() => ref.read(placeServiceProvider).deleteReview(own.placeReviewsId), done: 'Ulasan dihapus.');
  }

  Future<void> _run(Future<void> Function() call, {required String done}) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await call();
    } on ValidationFailure catch (failure) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = failure.firstError('rating') ?? failure.firstError('comment') ?? failure.message;
        });
      }
      return;
    } catch (error) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = tripErrorMessage(error, AppLocalizations.of(context));
        });
      }
      return;
    }
    if (!mounted) return;
    ref.invalidate(placeDetailProvider(widget.placesId));
    final messenger = ScaffoldMessenger.of(context);
    Navigator.of(context).pop();
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(done)));
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(placeDetailProvider(widget.placesId));
    final detail = state.valueOrNull;
    final own = detail == null ? null : _ownReview(detail);
    final errorColor = Theme.of(context).colorScheme.error;

    if (detail != null && !_prefilled) {
      _prefilled = true;
      if (own != null) {
        _rating = own.rating;
        _commentCtrl.text = own.comment ?? '';
      }
    }

    if (detail == null) {
      return SizedBox(
        height: 200,
        child: Center(
          child: state.hasError
              ? Text(tripErrorMessage(state.error!, AppLocalizations.of(context)))
              : const CircularProgressIndicator(),
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, 20 + MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: SizedBox(width: 56, height: 56, child: photo.PlacePhoto(url: detail.heroPhotoUrl)),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(own == null ? 'Beri Ulasan' : 'Ubah Ulasan', style: appText(18, FontWeight.w800, AppColors.ink, height: 24)),
                      const SizedBox(height: 2),
                      Text(
                        detail.summary.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: appText(13, FontWeight.w500, AppColors.inkMuted, height: 18),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.fromLTRB(12, 14, 12, 14),
              decoration: BoxDecoration(color: AppColors.field, borderRadius: BorderRadius.circular(16)),
              child: Column(
                children: [
                  Text('Bagaimana pengalamanmu?', style: appText(14, FontWeight.w700, AppColors.ink)),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (var star = 1; star <= 5; star++)
                        // Plain stars: IconButton's hover circle covered the text around them.
                        Semantics(
                          button: true,
                          label: '$star bintang',
                          child: MouseRegion(
                            cursor: _busy ? SystemMouseCursors.basic : SystemMouseCursors.click,
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: _busy
                                  ? null
                                  : () => setState(() {
                                        _rating = star;
                                        _error = null;
                                      }),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                                child: Icon(
                                  star <= _rating ? Icons.star_rounded : Icons.star_outline_rounded,
                                  size: 36,
                                  color: star <= _rating ? AppColors.sun400 : AppColors.line,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  Text(_ratingLabel(_rating), style: appText(12, FontWeight.w600, AppColors.inkMuted)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text.rich(
              TextSpan(children: [
                const TextSpan(text: 'Komentar '),
                TextSpan(text: '(opsional)', style: appText(13, FontWeight.w500, AppColors.inkMuted)),
              ]),
              style: appText(14, FontWeight.w700, AppColors.ink),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _commentCtrl,
              enabled: !_busy,
              minLines: 3,
              maxLines: 6,
              maxLength: ReviewSheet.maxCommentLength,
              // The limit is still enforced; the counter only shows near it.
              buildCounter: (_, {required currentLength, required isFocused, maxLength}) =>
                  currentLength < ReviewSheet.maxCommentLength - 200
                      ? null
                      : Text('$currentLength/$maxLength', style: appText(12, FontWeight.w500, AppColors.inkMuted)),
              style: appText(14, FontWeight.w600, AppColors.ink, height: 20),
              decoration: InputDecoration(
                hintText: 'Ceritakan pengalaman atau tips untuk wisatawan lain',
                hintStyle: appText(14, FontWeight.w500, AppColors.inkMuted),
                filled: true,
                fillColor: AppColors.field,
                contentPadding: const EdgeInsets.all(14),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
              ),
            ),
            if (_error case final error?) ...[
              const SizedBox(height: 8),
              Text(error, style: appText(12, FontWeight.w600, errorColor, height: 16)),
            ],
            const SizedBox(height: 16),
            if (own == null)
              PrimaryButton(label: 'Kirim Ulasan', isLoading: _busy, onPressed: _busy ? null : () => _save(own))
            else
              Row(
                children: [
                  SizedBox(
                    height: 52,
                    child: OutlinedButton.icon(
                      onPressed: _busy ? null : () => _delete(own),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: errorColor,
                        side: BorderSide(color: errorColor.withValues(alpha: 0.5)),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      icon: const Icon(Icons.delete_outline_rounded, size: 20),
                      label: Text('Hapus', style: appText(15, FontWeight.w700, errorColor)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: PrimaryButton(
                      label: 'Simpan Perubahan',
                      isLoading: _busy,
                      onPressed: _busy ? null : () => _save(own),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
