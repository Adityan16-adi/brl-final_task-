import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/clay_theme.dart';
import '../../../auth/application/auth_providers.dart';
import '../../domain/home_repository.dart';
import '../home_providers.dart';

class UploadMaterialDialog extends ConsumerStatefulWidget {
  const UploadMaterialDialog({super.key, this.initialClassId, this.initialSubject});

  final String? initialClassId;
  final String? initialSubject;

  @override
  ConsumerState<UploadMaterialDialog> createState() =>
      _UploadMaterialDialogState();
}

class _UploadMaterialDialogState extends ConsumerState<UploadMaterialDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _subjectCtrl = TextEditingController();
  final _detailsCtrl = TextEditingController();
  final _linkCtrl = TextEditingController();
  final _thumbnailUrlCtrl = TextEditingController();

  CourseMaterialType _selectedType = CourseMaterialType.notes;
  SelectedAttachmentItem? _pickedFile;
  bool _isUploading = false;
  double? _uploadProgress;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    if (widget.initialSubject != null && widget.initialSubject!.isNotEmpty) {
      _subjectCtrl.text = widget.initialSubject!;
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _subjectCtrl.dispose();
    _detailsCtrl.dispose();
    _linkCtrl.dispose();
    _thumbnailUrlCtrl.dispose();
    super.dispose();
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  Future<void> _pickFile() async {
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

      final file = files.first;
      final size = file.lengthSync() ?? (await file.length()) ?? 0;
      if (size > 25 * 1024 * 1024) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'File "${file.name}" exceeds the 25MB maximum limit. Please choose a smaller file.',
            ),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
        return;
      }

      final bytes = await file.readAsBytes();
      setState(() {
        _pickedFile = SelectedAttachmentItem(
          name: file.name,
          path: file.path,
          bytes: bytes,
          size: size,
        );
        if (_titleCtrl.text.trim().isEmpty) {
          // Pre-populate title with friendly filename
          _titleCtrl.text = file.name.replaceAll(RegExp(r'\.[a-zA-Z0-9]+$'), '');
        }
        _errorMessage = null;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to pick file: $e')),
      );
    }
  }

  Future<void> _handleUpload() async {
    if (!_formKey.currentState!.validate() || _isUploading) return;

    final link = _linkCtrl.text.trim();
    if (_pickedFile == null && link.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please attach a document/media file or provide a resource link.'),
        ),
      );
      return;
    }

    setState(() {
      _isUploading = true;
      _uploadProgress = 0.0;
      _errorMessage = null;
    });

    final currentUser = ref.read(currentUserProvider);
    final homeRepo = ref.read(homeRepositoryProvider);

    try {
      await homeRepo.uploadMaterial(
        classId: widget.initialClassId ?? 'class-general',
        title: _titleCtrl.text.trim(),
        subject: _subjectCtrl.text.trim().isEmpty ? 'General' : _subjectCtrl.text.trim(),
        type: _selectedType,
        details: _detailsCtrl.text.trim().isEmpty
            ? 'Course material resource.'
            : _detailsCtrl.text.trim(),
        link: link.isNotEmpty ? link : null,
        thumbnailUrl: _thumbnailUrlCtrl.text.trim().isEmpty
            ? null
            : _thumbnailUrlCtrl.text.trim(),
        uploadedBy: currentUser?.id,
        filePath: _pickedFile?.path,
        fileBytes: _pickedFile?.bytes,
        fileName: _pickedFile?.name,
        onProgress: (sent, total) {
          if (total > 0 && mounted) {
            setState(() {
              _uploadProgress = sent / total;
            });
          }
        },
      );

      if (mounted) {
        ref.invalidate(materialsProvider);
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Study material published successfully!'),
            backgroundColor: ClayTokens.mintDark,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isUploading = false;
          _errorMessage = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      ClayContainer(
                        width: 36,
                        height: 36,
                        depth: 2,
                        borderRadius: BorderRadius.circular(10),
                        color: ClayTokens.mint,
                        child: const Icon(
                          Icons.upload_file_rounded,
                          color: ClayTokens.mintDark,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Upload Study Material',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: colors.onSurface,
                              ),
                            ),
                            Text(
                              widget.initialSubject ?? 'Pragti Course Resource',
                              style: const TextStyle(
                                fontSize: 12,
                                color: ClayTokens.secondaryText,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, size: 20),
                        onPressed: _isUploading ? null : () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Title field
                  TextFormField(
                    controller: _titleCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Material Title *',
                      hintText: 'e.g. Lecture 4 Notes: Cell Transport',
                      prefixIcon: Icon(Icons.title_rounded),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Please provide a title';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),

                  // Subject field
                  TextFormField(
                    controller: _subjectCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Subject / Course *',
                      hintText: 'e.g. Biology, Mathematics, Physics',
                      prefixIcon: Icon(Icons.school_outlined),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Material Type Selector
                  Text(
                    'Material Category',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: colors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ChoiceChip(
                        avatar: const Icon(Icons.notes_rounded, size: 16),
                        label: const Text('Notes'),
                        selected: _selectedType == CourseMaterialType.notes,
                        onSelected: (_) =>
                            setState(() => _selectedType = CourseMaterialType.notes),
                      ),
                      ChoiceChip(
                        avatar: const Icon(Icons.play_circle_outline_rounded, size: 16),
                        label: const Text('Video'),
                        selected: _selectedType == CourseMaterialType.video,
                        onSelected: (_) =>
                            setState(() => _selectedType = CourseMaterialType.video),
                      ),
                      ChoiceChip(
                        avatar: const Icon(Icons.description_outlined, size: 16),
                        label: const Text('Document'),
                        selected: _selectedType == CourseMaterialType.document,
                        onSelected: (_) =>
                            setState(() => _selectedType = CourseMaterialType.document),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Pick file section
                  Text(
                    'Attach File (Max 25MB: PDF, Docs, PPT, Excel, ZIP, Media)',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: colors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 6),
                  if (_pickedFile == null)
                    OutlinedButton.icon(
                      icon: const Icon(Icons.file_upload_outlined, size: 18),
                      label: const Text('Choose File from Device'),
                      onPressed: _isUploading ? null : _pickFile,
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: colors.primaryContainer.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: colors.primary.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.insert_drive_file_rounded, color: colors.primary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _pickedFile!.name,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  _formatBytes(_pickedFile!.size),
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: colors.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close_rounded, size: 18),
                            tooltip: 'Remove file',
                            onPressed: _isUploading
                                ? null
                                : () => setState(() => _pickedFile = null),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 14),

                  // Resource Link / URL field
                  TextFormField(
                    controller: _linkCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Resource / Document Link',
                      hintText: 'https://drive.google.com/... or web URL',
                      prefixIcon: Icon(Icons.link_rounded),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Optional Thumbnail URL
                  TextFormField(
                    controller: _thumbnailUrlCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Thumbnail Image URL (Optional)',
                      hintText: 'https://.../preview.jpg',
                      prefixIcon: Icon(Icons.image_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Description
                  TextFormField(
                    controller: _detailsCtrl,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Description / Summary',
                      hintText: 'Brief summary of contents...',
                      prefixIcon: Icon(Icons.notes_outlined),
                    ),
                  ),

                  // Upload Progress
                  if (_isUploading && _uploadProgress != null) ...[
                    const SizedBox(height: 16),
                    LinearProgressIndicator(
                      value: _uploadProgress! > 0 ? _uploadProgress : null,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    const SizedBox(height: 6),
                    Center(
                      child: Text(
                        _uploadProgress! > 0
                            ? 'Uploading: ${(_uploadProgress! * 100).toInt()}%'
                            : 'Publishing resource...',
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
                            onPressed: _isUploading ? null : _handleUpload,
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

                  const SizedBox(height: 20),

                  // Upload button
                  SizedBox(
                    width: double.infinity,
                    child: ClayButton(
                      onPressed: _isUploading ? null : _handleUpload,
                      child: Center(
                        child: _isUploading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'Publish Study Material',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
