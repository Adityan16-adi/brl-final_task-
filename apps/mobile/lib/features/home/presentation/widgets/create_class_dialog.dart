import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/home_repository.dart';
import '../home_providers.dart';

class CreateClassDialog extends ConsumerStatefulWidget {
  const CreateClassDialog({super.key});

  @override
  ConsumerState<CreateClassDialog> createState() => _CreateClassDialogState();
}

class _CreateClassDialogState extends ConsumerState<CreateClassDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _subjectController = TextEditingController();
  final _scheduleController = TextEditingController();
  final _descController = TextEditingController();

  bool _startNow = false;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  int _durationMinutes = 60;

  bool _isSubmitting = false;
  String? _errorMessage;
  ClassroomItem? _createdClassroom;
  bool _copied = false;

  @override
  void initState() {
    super.initState();
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    _selectedDate = tomorrow;
    _selectedTime = const TimeOfDay(hour: 10, minute: 0);
    _updateScheduleText();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _subjectController.dispose();
    _scheduleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  void _updateScheduleText() {
    if (_startNow) {
      _scheduleController.text = 'Started Now · Live Session';
      return;
    }

    if (_selectedDate != null && _selectedTime != null) {
      final d = _selectedDate!;
      final dateStr =
          '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
      final hour = _selectedTime!.hourOfPeriod == 0
          ? 12
          : _selectedTime!.hourOfPeriod;
      final minute = _selectedTime!.minute.toString().padLeft(2, '0');
      final period = _selectedTime!.period == DayPeriod.am ? 'AM' : 'PM';
      final durationStr = _durationMinutes >= 60
          ? '${(_durationMinutes / 60).toStringAsFixed(_durationMinutes % 60 == 0 ? 0 : 1)}h'
          : '${_durationMinutes}m';

      _scheduleController.text =
          '$dateStr · $hour:$minute $period ($durationStr)';
    }
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _updateScheduleText();
      });
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        _selectedTime = picked;
        _updateScheduleText();
      });
    }
  }

  Future<void> _handleCreate() async {
    if (!_formKey.currentState!.validate() || _isSubmitting) return;

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final repo = ref.read(homeRepositoryProvider);
      final finalSchedule = _scheduleController.text.trim();

      final created = await repo.createClassroom(
        name: _nameController.text.trim(),
        subject: _subjectController.text.trim(),
        description: _descController.text.trim(),
        schedule: finalSchedule.isNotEmpty ? finalSchedule : 'Flexible Online',
      );

      ref.invalidate(classroomsProvider);
      ref.invalidate(homeSummaryProvider);
      ref.invalidate(scheduleProvider);

      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _createdClassroom = created;
      });
    } on ClassroomException catch (e) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _errorMessage = e.message;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _errorMessage = 'An unexpected error occurred. Please try again.';
      });
    }
  }

  void _copyJoinCode() {
    if (_createdClassroom?.code == null) return;
    Clipboard.setData(ClipboardData(text: _createdClassroom!.code!));
    setState(() => _copied = true);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Join code "${_createdClassroom!.code}" copied to clipboard!',
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    if (_createdClassroom != null) {
      return AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusDialog),
        ),
        title: const Row(
          children: [
            Icon(
              Icons.check_circle_rounded,
              color: AppTheme.statusGraded,
              size: 26,
            ),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Classroom Created!',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your classroom "${_createdClassroom!.name}" is ready.',
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: colors.primaryContainer.withAlpha(50),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: colors.primary.withAlpha(80)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'SHAREABLE JOIN CODE',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: colors.primary,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 12,
                    runSpacing: 10,
                    children: [
                      Text(
                        _createdClassroom!.code ?? '------',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: colors.primary,
                          letterSpacing: 2.0,
                        ),
                      ),
                      FilledButton.tonalIcon(
                        onPressed: _copyJoinCode,
                        icon: Icon(
                          _copied ? Icons.check_rounded : Icons.copy_rounded,
                          size: 16,
                        ),
                        label: Text(_copied ? 'Copied' : 'Copy Code'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Students can use this join code to enroll immediately.',
              style: TextStyle(fontSize: 12, color: colors.onSurfaceVariant),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(_createdClassroom),
            child: const Text('Done'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.of(context).pop(_createdClassroom),
            icon: const Icon(Icons.meeting_room_rounded, size: 18),
            label: const Text('Open Classroom'),
          ),
        ],
      );
    }

    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusDialog),
      ),
      title: Row(
        children: [
          Icon(Icons.add_business_rounded, color: colors.primary),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Create a Classroom',
              style: TextStyle(fontWeight: FontWeight.bold),
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
              Text(
                'Set up a new virtual classroom and configure its schedule.',
                style: TextStyle(fontSize: 13, color: colors.onSurfaceVariant),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                enabled: !_isSubmitting,
                decoration: const InputDecoration(
                  labelText: 'Class Name *',
                  hintText: 'e.g. Advanced Astrophysics',
                  prefixIcon: Icon(Icons.school_rounded),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Please enter a classroom name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _subjectController,
                enabled: !_isSubmitting,
                decoration: const InputDecoration(
                  labelText: 'Subject *',
                  hintText: 'e.g. Astronomy, Physics, Biology',
                  prefixIcon: Icon(Icons.menu_book_rounded),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Please enter the course subject';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Scheduling Mode Card
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colors.surfaceContainerHighest.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: colors.outlineVariant.withValues(alpha: 0.5),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Expanded(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.flash_on_rounded,
                                size: 18,
                                color: Colors.amber,
                              ),
                              SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  'Start Class Session Now',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: _startNow,
                          onChanged: _isSubmitting
                              ? null
                              : (val) {
                                  setState(() {
                                    _startNow = val;
                                    _updateScheduleText();
                                  });
                                },
                        ),
                      ],
                    ),
                    if (!_startNow) ...[
                      const Divider(height: 18),
                      const Text(
                        'Scheduled Date & Time:',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _isSubmitting ? null : _pickDate,
                              icon: const Icon(
                                Icons.calendar_today_rounded,
                                size: 14,
                              ),
                              label: Text(
                                _selectedDate != null
                                    ? '${_selectedDate!.month}/${_selectedDate!.day}/${_selectedDate!.year}'
                                    : 'Pick Date',
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _isSubmitting ? null : _pickTime,
                              icon: const Icon(
                                Icons.access_time_rounded,
                                size: 14,
                              ),
                              label: Text(
                                _selectedTime != null
                                    ? _selectedTime!.format(context)
                                    : 'Pick Time',
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<int>(
                        decoration: const InputDecoration(
                          labelText: 'Estimated Duration',
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
                        ),
                        initialValue: _durationMinutes,
                        items: const [
                          DropdownMenuItem(
                            value: 30,
                            child: Text('30 Minutes'),
                          ),
                          DropdownMenuItem(
                            value: 45,
                            child: Text('45 Minutes'),
                          ),
                          DropdownMenuItem(value: 60, child: Text('1 Hour')),
                          DropdownMenuItem(value: 90, child: Text('1.5 Hours')),
                          DropdownMenuItem(value: 120, child: Text('2 Hours')),
                        ],
                        onChanged: _isSubmitting
                            ? null
                            : (val) {
                                if (val != null) {
                                  setState(() {
                                    _durationMinutes = val;
                                    _updateScheduleText();
                                  });
                                }
                              },
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _scheduleController,
                enabled: !_isSubmitting,
                decoration: const InputDecoration(
                  labelText: 'Schedule (Optional)',
                  prefixIcon: Icon(Icons.event_note_rounded),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descController,
                enabled: !_isSubmitting,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Description (Optional)',
                  hintText: 'Brief summary of the course topics',
                  prefixIcon: Icon(Icons.notes_rounded),
                ),
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: colors.errorContainer,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: colors.error.withAlpha(80)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.error_outline_rounded,
                        size: 18,
                        color: colors.error,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(
                            color: colors.onErrorContainer,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _isSubmitting ? null : _handleCreate,
          child: _isSubmitting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text(_startNow ? 'Start Classroom Now' : 'Create Class'),
        ),
      ],
    );
  }
}
