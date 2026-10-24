import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/home_repository.dart';
import '../home_providers.dart';

class JoinClassDialog extends ConsumerStatefulWidget {
  const JoinClassDialog({super.key});

  @override
  ConsumerState<JoinClassDialog> createState() => _JoinClassDialogState();
}

class _JoinClassDialogState extends ConsumerState<JoinClassDialog> {
  final _controller = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleJoin() async {
    if (!_formKey.currentState!.validate() || _isSubmitting) return;

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    final code = _controller.text.trim();
    try {
      final repo = ref.read(homeRepositoryProvider);
      final joined = await repo.joinClassroom(code);

      ref.invalidate(classroomsProvider);
      ref.invalidate(homeSummaryProvider);

      if (!mounted) return;
      Navigator.of(context).pop(true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Successfully joined "${joined.name}" (Code: ${joined.code ?? code})!',
          ),
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
      );
    } on ClassroomException catch (e) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _errorMessage = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _errorMessage =
            'Invalid class code or unable to join. Please verify the code.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.add_circle_outline_rounded, color: colors.primary),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Join a Classroom',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter the classroom code provided by your instructor.',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _controller,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(
                labelText: 'Class Code',
                hintText: 'e.g. CELL24, MATH28',
                prefixIcon: Icon(Icons.pin_rounded),
              ),
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return 'Please enter a class code';
                }
                if (val.trim().length < 4) {
                  return 'Code must be at least 4 characters';
                }
                return null;
              },
            ),
            const SizedBox(height: 8),
            Text(
              'Sample preview codes: CELL24 · MATH28 · PAST21 · PHYS40',
              style: TextStyle(fontSize: 11, color: colors.onSurfaceVariant),
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 12),
              Text(
                _errorMessage!,
                style: TextStyle(color: colors.error, fontSize: 12),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _isSubmitting ? null : _handleJoin,
          child: _isSubmitting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Join Class'),
        ),
      ],
    );
  }
}
