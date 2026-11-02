import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:intl/intl.dart';
import '../../../core/models/comment_model.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_sizes.dart';

String formatCommentTime(DateTime createdAt, {DateTime? now}) {
  final diff = (now ?? DateTime.now()).difference(createdAt);

  if (diff.inMinutes < 1) return 'Vừa xong';
  if (diff.inHours < 1) return '${diff.inMinutes} phút trước';
  if (diff.inDays < 1) return '${diff.inHours} giờ trước';
  if (diff.inDays < 7) return '${diff.inDays} ngày trước';
  return DateFormat('dd/MM/yyyy').format(createdAt);
}

class CommentTimelineWidget extends StatefulWidget {
  final List<TaskComment> comments;

  /// `null` khi chưa đăng nhập: chỉ xem, không gửi được bình luận.
  final String? currentUserId;
  final ValueChanged<String> onSend;

  const CommentTimelineWidget({
    super.key,
    required this.comments,
    required this.currentUserId,
    required this.onSend,
  });

  @override
  State<CommentTimelineWidget> createState() => _CommentTimelineWidgetState();
}

class _CommentTimelineWidgetState extends State<CommentTimelineWidget> {
  final _inputController = TextEditingController();

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  void _submit() {
    final content = _inputController.text.trim();
    if (content.isEmpty) return;
    widget.onSend(content);
    _inputController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final canSend = widget.currentUserId != null;
    final sorted = [...widget.comments]
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (sorted.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSizes.p16),
            child: Text(
              'Chưa có bình luận nào.',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color: AppColors.statusCancelled,
              ),
            ),
          ),
        for (final comment in sorted)
          _CommentBubble(
            key: ValueKey(comment.id),
            comment: comment,
            isMine: comment.authorId == widget.currentUserId,
          ),
        const SizedBox(height: AppSizes.p8),
        TextField(
          controller: _inputController,
          enabled: canSend,
          minLines: 1,
          maxLines: 4,
          textInputAction: TextInputAction.send,
          onSubmitted: (_) => _submit(),
          decoration: InputDecoration(
            hintText: canSend ? 'Viết bình luận...' : 'Đăng nhập để bình luận',
            isDense: true,
            suffixIcon: IconButton(
              tooltip: 'Gửi bình luận',
              icon: Icon(
                IconsaxPlusLinear.send_1,
                color: canSend ? Theme.of(context).primaryColor : null,
              ),
              onPressed: canSend ? _submit : null,
            ),
          ),
        ),
      ],
    );
  }
}

class _CommentBubble extends StatelessWidget {
  final TaskComment comment;
  final bool isMine;

  const _CommentBubble({
    super.key,
    required this.comment,
    required this.isMine,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor;
    final initial = comment.authorName.trim().isEmpty
        ? '?'
        : comment.authorName.trim().characters.first.toUpperCase();

    final bubble = Container(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.sizeOf(context).width * 0.7,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.p12,
        vertical: AppSizes.p8,
      ),
      decoration: BoxDecoration(
        color: isMine ? primary : Theme.of(context).cardColor,
        border: isMine ? null : Border.all(color: AppColors.divider),
        borderRadius: BorderRadius.only(
          topLeft: AppSizes.radius16,
          topRight: AppSizes.radius16,
          bottomLeft: isMine ? AppSizes.radius16 : AppSizes.radius4,
          bottomRight: isMine ? AppSizes.radius4 : AppSizes.radius16,
        ),
      ),
      child: Text(
        comment.content,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 14,
          color: isMine ? Colors.white : null,
        ),
      ),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSizes.p4),
      child: Row(
        mainAxisAlignment:
            isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isMine) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: primary.withAlpha(30),
              child: Text(
                initial,
                style: TextStyle(color: primary, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: AppSizes.p8),
          ],
          Column(
            crossAxisAlignment:
                isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              if (!isMine)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSizes.p4),
                  child: Text(
                    comment.authorName,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              bubble,
              Padding(
                padding: const EdgeInsets.only(top: AppSizes.p4),
                child: Text(
                  formatCommentTime(comment.createdAt),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    color: AppColors.statusCancelled,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
