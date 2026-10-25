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
  bool _isUploading = false;
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

  Future<void> _handleUpload() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isUploading = true;
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
        link: _linkCtrl.text.trim().isEmpty ? null : _linkCtrl.text.trim(),
        thumbnailUrl: _thumbnailUrlCtrl.text.trim().isEmpty
            ? null
            : _thumbnailUrlCtrl.text.trim(),
        uploadedBy: currentUser?.id,
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
                        child: const Icon(
                          Icons.upload_file_rounded,
                          color: ClayTokens.deepIndigo,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Upload Study Material',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: colors.onSurface,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, size: 20),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  if (_errorMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.red, fontSize: 12),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Title field
                  TextFormField(
                    controller: _titleCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Material Title *',
                      hintText: 'e.g. Chapter 4 Lecture Slides',
                      prefixIcon: Icon(Icons.title_rounded),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Please enter a title';
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
                      hintText: 'e.g. Physics, Biology',
                      prefixIcon: Icon(Icons.subject_rounded),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Please enter a subject';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),

                  // Material Category selector
                  Text(
                    'Category / Format',
                    style: TextStyle(
                      fontSize: 13,
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
                  const SizedBox(height: 14),

                  // Resource Link / URL field
                  TextFormField(
                    controller: _linkCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Resource / Document Link',
                      hintText: 'https://drive.google.com/... or pdf url',
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
