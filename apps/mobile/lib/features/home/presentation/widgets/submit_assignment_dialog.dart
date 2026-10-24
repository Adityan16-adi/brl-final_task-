import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/home_repository.dart';
import '../home_providers.dart';

class SubmitAssignmentDialog extends ConsumerStatefulWidget {
  const SubmitAssignmentDialog({required this.assignment, super.key});

  final AssignmentItem assignment;

  @override
  ConsumerState<SubmitAssignmentDialog> createState() =>
      _SubmitAssignmentDialogState();
}

class _SubmitAssignmentDialogState
    extends ConsumerState<SubmitAssignmentDialog> {
  final _textController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    if (widget.assignment.submittedText != null) {
      _textController.text = widget.assignment.submittedText!;
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate() || _isSubmitting) return;

    setState(() => _isSubmitting = true);

    final repo = ref.read(homeRepositoryProvider);
    final success = await repo.submitAssignment(
      widget.assignment.id,
      _textController.text.trim(),
    );

    if (!mounted) return;

    if (success) {
      ref.invalidate(assignmentsProvider);
      ref.invalidate(homeSummaryProvider);
      Navigator.of(context).pop(true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Assignment "${widget.assignment.title}" submitted successfully!',
          ),
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
      );
    } else {
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to submit assignment. Please try again.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isGraded = widget.assignment.status == AssignmentStatus.graded;
    final isSubmitted = widget.assignment.status == AssignmentStatus.submitted;

    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.assignment_turned_in_rounded, color: colors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              widget.assignment.title,
              style: const TextStyle(fontSize: 18),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: colors.primaryContainer,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      widget.assignment.subject,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: colors.onPrimaryContainer,
                      ),
                    ),
                  ),
                  Text(
                    '${widget.assignment.points} Points',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    '• Due: ${widget.assignment.dueDate}',
                    style: TextStyle(
                      fontSize: 12,
                      color: colors.error,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                widget.assignment.description,
                style: const TextStyle(fontSize: 13, height: 1.4),
              ),
              const Divider(height: 24),
              if (isGraded) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: Colors.green.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.check_circle_rounded,
                            color: Colors.green,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Graded: ${widget.assignment.marks ?? 0}/${widget.assignment.points} Marks',
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                      if (widget.assignment.feedback != null) ...[
                        const SizedBox(height: 6),
                        Text(
                          'Feedback: "${widget.assignment.feedback}"',
                          style: const TextStyle(
                            fontSize: 13,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
              Text(
                isGraded || isSubmitted
                    ? 'Your Submission'
                    : 'Submit Solution / Notes',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _textController,
                readOnly: isGraded,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'Enter your answers, calculations, or submission notes here...',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                validator: (val) {
                  if (isGraded) return null;
                  if (val == null || val.trim().isEmpty) {
                    return 'Please enter your submission text or response';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(isGraded ? 'Close' : 'Cancel'),
        ),
        if (!isGraded)
          FilledButton(
            onPressed: _isSubmitting ? null : _handleSubmit,
            child: _isSubmitting
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(isSubmitted ? 'Update Submission' : 'Turn In'),
          ),
      ],
    );
  }
}
