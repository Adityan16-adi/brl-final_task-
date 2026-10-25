import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../auth/application/auth_providers.dart';
import '../../domain/home_repository.dart';
import '../home_providers.dart';

class CreateAssignmentDialog extends ConsumerStatefulWidget {
  const CreateAssignmentDialog({super.key});

  @override
  ConsumerState<CreateAssignmentDialog> createState() =>
      _CreateAssignmentDialogState();
}

class _CreateAssignmentDialogState
    extends ConsumerState<CreateAssignmentDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _subjectController = TextEditingController();
  final _classIdController = TextEditingController();
  final _dueDateController = TextEditingController();
  final _pointsController = TextEditingController(text: '20');
  final _descController = TextEditingController();
  final _attachmentUrlController = TextEditingController();
  final _attachmentNameController = TextEditingController();

  DateTime _selectedDueDate = DateTime.now().add(const Duration(days: 7));
  TimeOfDay _selectedDueTime = const TimeOfDay(hour: 23, minute: 59);

  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _formatDueDate();
  }

  void _formatDueDate() {
    final d = _selectedDueDate;
    final t = _selectedDueTime;
    final dateStr =
        '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    final hour = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
    final minute = t.minute.toString().padLeft(2, '0');
    final period = t.period == DayPeriod.am ? 'AM' : 'PM';
    _dueDateController.text = '$dateStr $hour:$minute $period';
  }

  Future<void> _pickDueDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDueDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (pickedDate != null && mounted) {
      final pickedTime = await showTimePicker(
        context: context,
        initialTime: _selectedDueTime,
      );
      if (pickedTime != null && mounted) {
        setState(() {
          _selectedDueDate = pickedDate;
          _selectedDueTime = pickedTime;
          _formatDueDate();
        });
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _subjectController.dispose();
    _classIdController.dispose();
    _dueDateController.dispose();
    _pointsController.dispose();
    _descController.dispose();
    _attachmentUrlController.dispose();
    _attachmentNameController.dispose();
    super.dispose();
  }

  Future<void> _handleCreate() async {
    if (!_formKey.currentState!.validate() || _isSubmitting) return;

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final repo = ref.read(homeRepositoryProvider);
      final user = ref.read(currentUserProvider);
      final points = int.tryParse(_pointsController.text.trim()) ?? 20;

      // Ensure a valid classId is resolved
      String targetClassId = _classIdController.text.trim();
      if (targetClassId.isEmpty) {
        final classesAsync = ref.read(classroomsProvider).value ?? [];
        if (classesAsync.isNotEmpty) {
          targetClassId = classesAsync.first.id;
        } else {
          targetClassId = '6adc9d63e058a8442a8f1520';
        }
      }

      // Convert selected date/time to ISO-8601 for backend standard
      final isoDue = DateTime(
        _selectedDueDate.year,
        _selectedDueDate.month,
        _selectedDueDate.day,
        _selectedDueTime.hour,
        _selectedDueTime.minute,
      ).toIso8601String();

      final created = await repo.createAssignment(
        classId: targetClassId,
        title: _titleController.text.trim(),
        subject: _subjectController.text.trim(),
        dueDate: isoDue,
        points: points,
        description: _descController.text.trim(),
        createdBy: user?.uid ?? 'mock-teacher-01',
        attachmentUrl: _attachmentUrlController.text.trim(),
        attachmentName: _attachmentNameController.text.trim(),
      );

      ref.invalidate(assignmentsProvider);
      ref.invalidate(homeSummaryProvider);
      ref.invalidate(scheduleProvider);

      if (!mounted) return;
      Navigator.of(context).pop(created);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Assignment "${created.title}" published successfully!',
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
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _errorMessage = 'Unable to create assignment: ${e.toString()}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final classroomsAsync = ref.watch(classroomsProvider);
    final availableClasses = classroomsAsync.value ?? [];

    // Auto-select class ID if empty
    if (_classIdController.text.isEmpty && availableClasses.isNotEmpty) {
      _classIdController.text = availableClasses.first.id;
      if (_subjectController.text.isEmpty) {
        _subjectController.text = availableClasses.first.subject;
      }
    }

    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusDialog),
      ),
      title: Row(
        children: [
          Icon(Icons.add_task_rounded, color: colors.primary),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Create Assignment',
              style: TextStyle(fontSize: 18),
              overflow: TextOverflow.ellipsis,
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
              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(10),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: colors.errorContainer,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: colors.error.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.error_outline_rounded,
                        size: 16,
                        color: colors.onErrorContainer,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(
                            fontSize: 12,
                            color: colors.onErrorContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              TextFormField(
                controller: _titleController,
                enabled: !_isSubmitting,
                decoration: const InputDecoration(
                  labelText: 'Assignment Title *',
                  hintText: 'e.g. Newton’s Laws Lab Report',
                  isDense: true,
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Title is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              if (availableClasses.isNotEmpty) ...[
                DropdownButtonFormField<String>(
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Target Classroom *',
                    isDense: true,
                  ),
                  initialValue: _classIdController.text.isNotEmpty
                      ? _classIdController.text
                      : availableClasses.first.id,
                  items: availableClasses.map((c) {
                    return DropdownMenuItem(
                      value: c.id,
                      child: Text(
                        '${c.name} (${c.subject})',
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  onChanged: _isSubmitting
                      ? null
                      : (val) {
                          if (val != null) {
                            setState(() {
                              _classIdController.text = val;
                              final selected = availableClasses.firstWhere(
                                (c) => c.id == val,
                              );
                              if (_subjectController.text.isEmpty) {
                                _subjectController.text = selected.subject;
                              }
                            });
                          }
                        },
                ),
                const SizedBox(height: 12),
              ],
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _subjectController,
                      enabled: !_isSubmitting,
                      decoration: const InputDecoration(
                        labelText: 'Subject *',
                        hintText: 'e.g. Physics',
                        isDense: true,
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Subject is required';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _pointsController,
                      enabled: !_isSubmitting,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Max Marks',
                        hintText: '20',
                        isDense: true,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _dueDateController,
                readOnly: true,
                enabled: !_isSubmitting,
                onTap: _pickDueDate,
                decoration: InputDecoration(
                  labelText: 'Due Date & Time *',
                  hintText: 'Select due date & time',
                  prefixIcon: const Icon(
                    Icons.calendar_today_rounded,
                    size: 18,
                  ),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.edit_calendar_rounded, size: 18),
                    onPressed: _pickDueDate,
                  ),
                  isDense: true,
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Due date is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descController,
                enabled: !_isSubmitting,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Instructions / Guidelines',
                  hintText: 'Provide guidelines, reference materials, and expectations...',
                  alignLabelWithHint: true,
                  isDense: true,
                ),
              ),
              const SizedBox(height: 12),

              // Attachment Link & Document Reference Section
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: colors.surfaceContainerHighest.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: colors.outlineVariant.withValues(alpha: 0.5),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.attach_file_rounded,
                          size: 16,
                          color: colors.primary,
                        ),
                        const SizedBox(width: 6),
                        const Expanded(
                          child: Text(
                            'Attachment / Reference URL (Optional)',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _attachmentUrlController,
                      enabled: !_isSubmitting,
                      decoration: const InputDecoration(
                        labelText: 'File or Resource URL',
                        hintText: 'https://storage.example.com/handout.pdf',
                        isDense: true,
                      ),
                    ),
                  ],
                ),
              ),
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
              : const Text('Publish Assignment'),
        ),
      ],
    );
  }
}
