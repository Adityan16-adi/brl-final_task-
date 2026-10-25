import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/clay_theme.dart';
import '../../../../core/widgets/demo_data_badge.dart';
import '../../../auth/application/auth_providers.dart';
import '../../domain/home_repository.dart';
import '../home_providers.dart';
import 'upload_material_dialog.dart';

class MaterialsView extends ConsumerStatefulWidget {
  const MaterialsView({super.key});

  @override
  ConsumerState<MaterialsView> createState() => _MaterialsViewState();
}

class _MaterialsViewState extends ConsumerState<MaterialsView> {
  CourseMaterialType? _filterType;
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final materialsAsync = ref.watch(materialsProvider);
    final currentUser = ref.watch(currentUserProvider);
    final isTeacher = ref.watch(isTeacherProvider);
    final colors = Theme.of(context).colorScheme;

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(materialsProvider),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
        children: [
          if (isTeacher) ...[
            SizedBox(
              width: double.infinity,
              child: ClayButton(
                onPressed: () => showDialog<void>(
                  context: context,
                  builder: (_) => const UploadMaterialDialog(),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.upload_file_rounded,
                      size: 18,
                      color: Colors.white,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Upload Study Material',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
          ],
          // Search bar
          ClayContainer(
            depth: 3,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
            borderRadius: BorderRadius.circular(16),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search study materials, notes, videos...',
                hintStyle: TextStyle(
                  fontSize: 13,
                  color: ClayTokens.secondaryText,
                ),
                prefixIcon: Icon(Icons.search_rounded, size: 20),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 10),
              ),
              onChanged: (val) =>
                  setState(() => _searchQuery = val.trim().toLowerCase()),
            ),
          ),
          const SizedBox(height: 14),

          // Filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                FilterChip(
                  label: const Text('All Types'),
                  selected: _filterType == null,
                  onSelected: (_) => setState(() => _filterType = null),
                ),
                const SizedBox(width: 8),
                FilterChip(
                  avatar: const Icon(Icons.notes_rounded, size: 16),
                  label: const Text('Notes'),
                  selected: _filterType == CourseMaterialType.notes,
                  onSelected: (_) =>
                      setState(() => _filterType = CourseMaterialType.notes),
                ),
                const SizedBox(width: 8),
                FilterChip(
                  avatar: const Icon(
                    Icons.play_circle_outline_rounded,
                    size: 16,
                  ),
                  label: const Text('Videos'),
                  selected: _filterType == CourseMaterialType.video,
                  onSelected: (_) =>
                      setState(() => _filterType = CourseMaterialType.video),
                ),
                const SizedBox(width: 8),
                FilterChip(
                  avatar: const Icon(Icons.description_outlined, size: 16),
                  label: const Text('Documents'),
                  selected: _filterType == CourseMaterialType.document,
                  onSelected: (_) =>
                      setState(() => _filterType = CourseMaterialType.document),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          materialsAsync.when(
            data: (materials) {
              final isDemoOrFallback = (currentUser?.isDemo == true) ||
                  materials.any((m) =>
                      m.id.startsWith('mat-cell') ||
                      m.id.startsWith('mat-calc') ||
                      m.id.startsWith('mat-hist'));

              final filtered = materials.where((m) {
                if (_filterType != null && m.type != _filterType) {
                  return false;
                }
                if (_searchQuery.isNotEmpty) {
                  final matchTitle = m.title.toLowerCase().contains(
                    _searchQuery,
                  );
                  final matchSub = m.subject.toLowerCase().contains(
                    _searchQuery,
                  );
                  final matchDet = m.details.toLowerCase().contains(
                    _searchQuery,
                  );
                  if (!matchTitle && !matchSub && !matchDet) return false;
                }
                return true;
              }).toList();

              if (filtered.isEmpty) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (isDemoOrFallback)
                      const DemoDataBadge(
                        message: 'Demo Data — Showing curated demonstration study materials',
                      ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 48),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ClayContainer(
                              width: 64,
                              height: 64,
                              depth: 4,
                              borderRadius: BorderRadius.circular(20),
                              child: const Center(
                                child: Icon(
                                  Icons.folder_open_rounded,
                                  size: 32,
                                  color: ClayTokens.deepIndigo,
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              _filterType != null || _searchQuery.isNotEmpty
                                  ? 'No matching materials found'
                                  : 'No materials available yet.',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            if (_filterType != null || _searchQuery.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              TextButton.icon(
                                onPressed: () => setState(() {
                                  _filterType = null;
                                  _searchQuery = '';
                                }),
                                icon: const Icon(Icons.refresh_rounded, size: 16),
                                label: const Text('Reset filters'),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (isDemoOrFallback)
                    const DemoDataBadge(
                      message: 'Demo Data — Showing curated demonstration study materials',
                    ),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isWide = constraints.maxWidth >= 600;

                      if (isWide) {
                        return Wrap(
                          spacing: 14,
                          runSpacing: 14,
                          children: filtered.map((item) {
                            final cardWidth = (constraints.maxWidth - 14) / 2;
                            return SizedBox(
                              width: cardWidth,
                              child: _MaterialCard(item: item),
                            );
                          }).toList(),
                        );
                      }

                      return Column(
                        children: filtered
                            .map(
                              (item) => Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: _MaterialCard(item: item),
                              ),
                            )
                            .toList(),
                      );
                    },
                  ),
                ],
              );
            },
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: CircularProgressIndicator(),
              ),
            ),
            error: (err, _) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.error_outline_rounded,
                      size: 48,
                      color: colors.error,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Failed to load materials: $err',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: () => ref.invalidate(materialsProvider),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MaterialCard extends StatelessWidget {
  const _MaterialCard({required this.item});

  final MaterialItem item;

  IconData _getTypeIcon(CourseMaterialType type) {
    switch (type) {
      case CourseMaterialType.notes:
        return Icons.edit_note_rounded;
      case CourseMaterialType.video:
        return Icons.play_circle_fill_rounded;
      case CourseMaterialType.document:
        return Icons.picture_as_pdf_rounded;
    }
  }

  Color _getTypeColor(CourseMaterialType type) {
    switch (type) {
      case CourseMaterialType.notes:
        return ClayTokens.deepIndigo;
      case CourseMaterialType.video:
        return Colors.redAccent.shade400;
      case CourseMaterialType.document:
        return const Color(0xFF0D9488);
    }
  }

  Color _getTypeBg(CourseMaterialType type) {
    switch (type) {
      case CourseMaterialType.notes:
        return ClayTokens.softLavender;
      case CourseMaterialType.video:
        return const Color(0xFFFFECEE);
      case CourseMaterialType.document:
        return ClayTokens.mint;
    }
  }

  String _getTypeLabel(CourseMaterialType type) {
    switch (type) {
      case CourseMaterialType.notes:
        return 'Lecture Note';
      case CourseMaterialType.video:
        return 'Video Lecture';
      case CourseMaterialType.document:
        return 'Document';
    }
  }

  void _showDetails(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final typeColor = _getTypeColor(item.type);
    final typeBg = _getTypeBg(item.type);

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetCtx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(sheetCtx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colors.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  ClayContainer(
                    width: 48,
                    height: 48,
                    depth: 4,
                    color: typeBg,
                    borderRadius: BorderRadius.circular(14),
                    child: Icon(
                      _getTypeIcon(item.type),
                      color: typeColor,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.subject,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: colors.primary,
                          ),
                        ),
                        Text(
                          _getTypeLabel(item.type),
                          style: TextStyle(
                            fontSize: 11,
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                item.title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                item.details,
                style: TextStyle(
                  fontSize: 14,
                  color: colors.onSurfaceVariant,
                  height: 1.4,
                ),
              ),
              if (item.createdAt != null) ...[
                const SizedBox(height: 8),
                Text(
                  'Added: ${item.createdAt}',
                  style: TextStyle(fontSize: 12, color: colors.outline),
                ),
              ],
              const SizedBox(height: 20),
              if (item.link != null) ...[
                ClayContainer(
                  depth: 2,
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      const Icon(Icons.link_rounded, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          item.link!,
                          style: const TextStyle(
                            fontSize: 13,
                            fontFamily: 'monospace',
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        tooltip: 'Copy link',
                        icon: const Icon(Icons.copy_rounded, size: 18),
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: item.link!));
                          ScaffoldMessenger.of(sheetCtx).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Resource link copied to clipboard!',
                              ),
                              backgroundColor: ClayTokens.deepIndigo,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
              ClayButton(
                isFullWidth: true,
                onPressed: () {
                  Navigator.of(sheetCtx).pop();
                  if (item.link != null) {
                    Clipboard.setData(ClipboardData(text: item.link!));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Copied link for "${item.title}" to clipboard!',
                        ),
                        backgroundColor: ClayTokens.deepIndigo,
                      ),
                    );
                  }
                },
                icon: Icons.download_rounded,
                child: const Text('Access Material Resource'),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final typeColor = _getTypeColor(item.type);
    final typeBg = _getTypeBg(item.type);

    return ClayCard(
      depth: 5,
      onTap: () => _showDetails(context),
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (item.thumbnailUrl != null && item.thumbnailUrl!.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                item.thumbnailUrl!,
                width: 44,
                height: 44,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => ClayContainer(
                  width: 44,
                  height: 44,
                  depth: 3,
                  color: typeBg,
                  borderRadius: BorderRadius.circular(12),
                  child: Icon(
                    _getTypeIcon(item.type),
                    color: typeColor,
                    size: 24,
                  ),
                ),
              ),
            )
          else
            ClayContainer(
              width: 44,
              height: 44,
              depth: 3,
              color: typeBg,
              borderRadius: BorderRadius.circular(12),
              child: Icon(_getTypeIcon(item.type), color: typeColor, size: 24),
            ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    ClayBadge(
                      label: item.subject,
                      backgroundColor: ClayTokens.softLavender,
                      textColor: ClayTokens.deepIndigo,
                      fontSize: 10,
                    ),
                    const Spacer(),
                    Text(
                      _getTypeLabel(item.type),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  item.title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  item.details,
                  style: TextStyle(
                    fontSize: 12,
                    color: colors.onSurfaceVariant,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    if (item.createdAt != null) ...[
                      Icon(
                        Icons.schedule_rounded,
                        size: 12,
                        color: colors.outline,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        item.createdAt!,
                        style: TextStyle(fontSize: 11, color: colors.outline),
                      ),
                    ],
                    const Spacer(),
                    const Text(
                      'View Details →',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: ClayTokens.deepIndigo,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
