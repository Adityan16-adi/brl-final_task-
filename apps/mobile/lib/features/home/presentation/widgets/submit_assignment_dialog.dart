import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../auth/application/auth_providers.dart';
import '../../../../core/errors/error_message_helper.dart';
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
  final _linkController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  final List<SelectedAttachmentItem> _selectedFiles = [];
  bool _isSubmitting = false;
  double? _uploadProgress;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    if (widget.assignment.submittedText != null) {
      _textController.text = widget.assignment.submittedText!;
    }
    final existingLink = widget.assignment.submittedLink ??
        (widget.assignment.submittedFileUrl != null &&
                widget.assignment.submittedFileUrl!.startsWith('http')
            ? widget.assignment.submittedFileUrl
            : null);
    if (existingLink != null) {
      _linkController.text = existingLink;
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _linkController.dispose();
    super.dispose();
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  Future<void> _openUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        return;
      }
    } catch (_) {}
    await Clipboard.setData(ClipboardData(text: url));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Resource link copied to clipboard.')),
      );
    }
  }

  Future<void> _pickFiles() async {
    try {
      final List<PlatformFile> files = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: [
          'pdf',
          'doc',
          'docx',
          'ppt',
          'pptx',
          'xls',
          'xlsx',
          'txt',
          'csv',
          'mp4',
          'webm',
          'mov',
          'jpg',
          'jpeg',
          'png',
          'webp',
          'zip',
        ],
      );
      if (files.isEmpty) return;

      for (final file in files) {
        final size = file.lengthSync() ?? (await file.length()) ?? 0;
        if (size > 25 * 1024 * 1024) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'File "${file.name}" exceeds 25MB maximum limit. Please choose a smaller file.',
              ),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
          continue;
        }
        final bytes = await file.readAsBytes();
        setState(() {
          _selectedFiles.add(
            SelectedAttachmentItem(
              name: file.name,
              path: file.path,
              bytes: bytes,
              size: size,
            ),
          );
          _errorMessage = null;
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to select file: $e')),
      );
    }
  }

  Future<void> _takePhoto() async {
    try {
      final picker = ImagePicker();
      final photo = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );
      if (photo == null) return;
      final bytes = await photo.readAsBytes();
      if (bytes.length > 25 * 1024 * 1024) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Captured photo exceeds 25MB maximum limit.'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
        return;
      }
      setState(() {
        _selectedFiles.add(
          SelectedAttachmentItem(
            name: photo.name,
            path: photo.path,
            bytes: bytes,
            size: bytes.length,
            mimeType: photo.mimeType ?? 'image/jpeg',
          ),
        );
        _errorMessage = null;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Camera access failed: $e')),
      );
    }
  }

  Future<void> _pickPhoto() async {
    try {
      final picker = ImagePicker();
      final photo = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      if (photo == null) return;
      final bytes = await photo.readAsBytes();
      if (bytes.length > 25 * 1024 * 1024) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Selected photo exceeds 25MB maximum limit.'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
        return;
      }
      setState(() {
        _selectedFiles.add(
          SelectedAttachmentItem(
            name: photo.name,
            path: photo.path,
            bytes: bytes,
            size: bytes.length,
            mimeType: photo.mimeType ?? 'image/jpeg',
          ),
        );
        _errorMessage = null;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gallery access failed: $e')),
      );
    }
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate() || _isSubmitting) return;

    final text = _textController.text.trim();
    final link = _linkController.text.trim();

    if (text.isEmpty &&
        link.isEmpty &&
        _selectedFiles.isEmpty &&
        widget.assignment.attachments.isEmpty &&
        (widget.assignment.submittedFileUrl == null ||
            widget.assignment.submittedFileUrl!.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please provide written notes, a link, or attach at least one file/photo.',
          ),
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
      _uploadProgress = 0.0;
      _errorMessage = null;
    });

    try {
      final repo = ref.read(homeRepositoryProvider);
      final user = ref.read(currentUserProvider);

      final success = await repo.submitAssignment(
        widget.assignment.id,
        text,
        studentId: user?.uid,
        link: link.isNotEmpty ? link : null,
        localFiles: _selectedFiles.isNotEmpty ? _selectedFiles : null,
        fileUrl: link.isNotEmpty ? link : null,
        onProgress: (sent, total) {
          if (total > 0 && mounted) {
            setState(() {
              _uploadProgress = sent / total;
            });
          }
        },
      );

      if (!mounted) return;

      if (success) {
        HapticFeedback.lightImpact();
        ref.invalidate(assignmentsProvider);
        ref.invalidate(homeSummaryProvider);
        ref.invalidate(scheduleProvider);
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
        setState(() {
          _isSubmitting = false;
          _errorMessage =
              'Submission rejected by server. Please verify attachments and try again.';
        });
      }
    } catch (err) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _errorMessage = ErrorMessageHelper.format(err, fallback: 'Failed to submit assignment. Please try again.');
      });
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

              // Reference file attached by teacher
              if (widget.assignment.attachmentUrl != null &&
                  widget.assignment.attachmentUrl!.isNotEmpty) ...[
                const SizedBox(height: 10),
                InkWell(
                  onTap: () => _openUrl(widget.assignment.attachmentUrl!),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: colors.surfaceContainerHighest.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: colors.outlineVariant.withValues(alpha: 0.5),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.attachment_rounded, size: 16),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Reference: ${widget.assignment.attachmentName ?? widget.assignment.attachmentUrl}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.blue,
                              decoration: TextDecoration.underline,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const Icon(Icons.open_in_new_rounded, size: 14, color: Colors.blue),
                      ],
                    ),
                  ),
                ),
              ],
              const Divider(height: 24),

              // Graded feedback card
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

              // Solution / Notes
              Text(
                isGraded || isSubmitted
                    ? 'Your Written Solution / Notes'
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
                  final textEmpty = val == null || val.trim().isEmpty;
                  final linkEmpty = _linkController.text.trim().isEmpty;
                  if (textEmpty && linkEmpty && _selectedFiles.isEmpty) {
                    return 'Please enter written notes or attach a file link';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),

              // Document or Link
              Text(
                'Submission Attachment / Document Link (Optional)',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                  color: colors.onSurface,
                ),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _linkController,
                readOnly: isGraded,
                decoration: const InputDecoration(
                  hintText: 'https://docs.google.com/... or project link',
                  prefixIcon: Icon(Icons.link_rounded, size: 18),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 16),

              // Previously submitted attachments
              if (widget.assignment.attachments.isNotEmpty) ...[
                Text(
                  'Existing Attached Files',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                    color: colors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 6),
                ...widget.assignment.attachments.map(
                  (att) => Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: colors.surfaceContainerHighest.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.file_present_rounded, size: 18, color: Colors.blue),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            att.name.isNotEmpty ? att.name : att.url,
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.open_in_new_rounded, size: 16),
                          tooltip: 'Open attachment',
                          onPressed: () => _openUrl(att.url),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
              ],

              // Attachment picker section (if not graded)
              if (!isGraded) ...[
                Text(
                  'Attach Files or Photos (Max 25MB)',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                    color: colors.onSurface,
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    OutlinedButton.icon(
                      icon: const Icon(Icons.file_upload_outlined, size: 16),
                      label: const Text('Add Document'),
                      onPressed: _isSubmitting ? null : _pickFiles,
                    ),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.camera_alt_outlined, size: 16),
                      label: const Text('Camera'),
                      onPressed: _isSubmitting ? null : _takePhoto,
                    ),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.photo_outlined, size: 16),
                      label: const Text('Gallery'),
                      onPressed: _isSubmitting ? null : _pickPhoto,
                    ),
                  ],
                ),

                // Selected local files list
                if (_selectedFiles.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  ..._selectedFiles.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final item = entry.value;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: colors.primaryContainer.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: colors.primary.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            item.mimeType?.startsWith('image/') == true
                                ? Icons.image_rounded
                                : Icons.insert_drive_file_rounded,
                            size: 18,
                            color: colors.primary,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.name,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  _formatBytes(item.size),
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: colors.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close_rounded, size: 16),
                            tooltip: 'Remove',
                            onPressed: _isSubmitting
                                ? null
                                : () => setState(() => _selectedFiles.removeAt(idx)),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ],

              // Upload progress indicator
              if (_isSubmitting && _uploadProgress != null) ...[
                const SizedBox(height: 16),
                LinearProgressIndicator(
                  value: _uploadProgress! > 0 ? _uploadProgress : null,
                  borderRadius: BorderRadius.circular(4),
                ),
                const SizedBox(height: 6),
                Center(
                  child: Text(
                    _uploadProgress! > 0
                        ? 'Uploading attachments: ${(_uploadProgress! * 100).toInt()}%'
                        : 'Submitting solution...',
                    style: TextStyle(
                      fontSize: 11,
                      color: colors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],

              // Error banner with retry
              if (_errorMessage != null) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: colors.errorContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline_rounded,
                          size: 18, color: colors.onErrorContainer),
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
                      TextButton(
                        onPressed: _isSubmitting ? null : _handleSubmit,
                        child: Text(
                          'Retry',
                          style: TextStyle(
                            color: colors.onErrorContainer,
                            fontWeight: FontWeight.bold,
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
