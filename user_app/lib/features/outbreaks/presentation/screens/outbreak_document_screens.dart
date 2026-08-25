import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:user_app/app/providers/app_providers.dart';
import 'package:user_app/app/router/route_names.dart';
import 'package:user_app/core/config/app_config.dart';
import 'package:user_app/core/widgets/app_error_view.dart';
import 'package:user_app/core/widgets/app_loading_view.dart';
import 'package:user_app/features/documents/presentation/screens/document_reader_page.dart';
import 'package:user_app/features/downloads/data/models/offline_download.dart';
import 'package:user_app/features/guidelines/data/models/guideline_publication.dart';
import 'package:user_app/features/outbreaks/data/models/outbreak_models.dart';
import 'package:user_app/features/outbreaks/data/repositories/outbreak_repository.dart';
import 'package:user_app/features/outbreaks/presentation/providers/outbreak_providers.dart';

class OutbreakDocumentsPage extends ConsumerStatefulWidget {
  const OutbreakDocumentsPage({super.key, required this.outbreakId});
  final String outbreakId;

  @override
  ConsumerState<OutbreakDocumentsPage> createState() =>
      _OutbreakDocumentsPageState();
}

class _OutbreakDocumentsPageState extends ConsumerState<OutbreakDocumentsPage> {
  final _search = TextEditingController();
  String _kind = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _apply() => ref
      .read(publicOutbreakDocumentsProvider(widget.outbreakId).notifier)
      .applyQuery(
        OutbreakDocumentQuery(search: _search.text, documentKind: _kind),
      );

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(publicOutbreakDocumentsProvider(widget.outbreakId));
    return Scaffold(
      appBar: AppBar(title: const Text('Official documents')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: SearchBar(
              controller: _search,
              hintText: 'Search title, number, authority or content',
              leading: const Icon(LucideIcons.search),
              onSubmitted: (_) => _apply(),
              trailing: [
                IconButton(
                  tooltip: 'Search',
                  onPressed: _apply,
                  icon: const Icon(LucideIcons.arrowRight),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 52,
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              children: [
                for (final entry in const <String, String>{
                  '': 'All',
                  'sop': 'SOPs',
                  'case_definition': 'Case definitions',
                  'ipc_protocol': 'IPC',
                  'treatment_protocol': 'Treatment',
                  'checklist': 'Checklists',
                  'form': 'Forms',
                }.entries)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(entry.value),
                      selected: _kind == entry.key,
                      onSelected: (_) {
                        setState(() => _kind = entry.key);
                        _apply();
                      },
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: state.when(
              loading: () => const AppLoadingView(
                message: 'Loading official documents...',
              ),
              error: (error, _) => AppErrorView(
                error: error,
                title: 'Documents unavailable',
                onRetry: () => ref.invalidate(
                  publicOutbreakDocumentsProvider(widget.outbreakId),
                ),
              ),
              data: (page) => RefreshIndicator(
                onRefresh: () => ref
                    .read(
                      publicOutbreakDocumentsProvider(
                        widget.outbreakId,
                      ).notifier,
                    )
                    .refresh(),
                child: ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  itemCount: page.items.isEmpty
                      ? 1
                      : page.items.length + (page.hasMore ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (page.items.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.only(top: 96),
                        child: Column(
                          children: [
                            Icon(LucideIcons.folderSearch, size: 56),
                            SizedBox(height: 16),
                            Text('No published documents match these filters.'),
                          ],
                        ),
                      );
                    }
                    if (index == page.items.length) {
                      return TextButton(
                        onPressed: () => ref
                            .read(
                              publicOutbreakDocumentsProvider(
                                widget.outbreakId,
                              ).notifier,
                            )
                            .loadMore(),
                        child: const Text('Load more'),
                      );
                    }
                    final item = page.items[index];
                    return Card(
                      child: ListTile(
                        leading: const Icon(LucideIcons.fileCheck2),
                        title: Text(item.title),
                        subtitle: Text(
                          [
                            item.documentKind.replaceAll('_', ' '),
                            item.issuingAuthority,
                            if (item.version.isNotEmpty) 'v${item.version}',
                          ].where((value) => value.isNotEmpty).join(' · '),
                        ),
                        trailing: const Icon(LucideIcons.chevronRight),
                        onTap: () => context.push(
                          AppRoutes.outbreakDocument(
                            widget.outbreakId,
                            item.id,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class OutbreakDocumentPage extends ConsumerStatefulWidget {
  const OutbreakDocumentPage({
    super.key,
    required this.outbreakId,
    required this.documentId,
  });
  final String outbreakId;
  final String documentId;

  @override
  ConsumerState<OutbreakDocumentPage> createState() =>
      _OutbreakDocumentPageState();
}

class _OutbreakDocumentPageState extends ConsumerState<OutbreakDocumentPage> {
  StreamSubscription<OfflineDownload>? _subscription;
  int _downloadRevision = 0;

  @override
  void initState() {
    super.initState();
    _subscription = ref
        .read(guidelineDownloadServiceProvider)
        .changes
        .where((item) => item.guidelineId == widget.documentId)
        .listen((_) {
          if (mounted) setState(() => _downloadRevision++);
        });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final key = (outbreakId: widget.outbreakId, documentId: widget.documentId);
    final state = ref.watch(publicOutbreakDocumentProvider(key));
    return Scaffold(
      appBar: AppBar(title: const Text('Official document')),
      body: state.when(
        loading: () => const AppLoadingView(message: 'Loading document...'),
        error: (error, _) => AppErrorView(
          error: error,
          title: 'Document unavailable',
          message: 'It may have expired or been withdrawn.',
          onRetry: () => ref.invalidate(publicOutbreakDocumentProvider(key)),
        ),
        data: (content) => _documentBody(content),
      ),
    );
  }

  Widget _documentBody(PublicContent<PublicOutbreakDocument> content) {
    final document = content.value;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          document.title,
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        if (content.cache.isOffline)
          const Chip(
            avatar: Icon(LucideIcons.cloudOff, size: 16),
            label: Text('Offline cached metadata'),
          ),
        if (_status(document) case final status?)
          Card(
            color: status.$2,
            child: ListTile(leading: Icon(status.$3), title: Text(status.$1)),
          ),
        Text(document.description),
        const SizedBox(height: 16),
        _metadata('Document type', document.documentKind.replaceAll('_', ' ')),
        _metadata('Authority', document.issuingAuthority),
        _metadata('Document number', document.documentNumber),
        _metadata('Version', document.version),
        _metadata('Audience', document.audience),
        _metadata('Language', document.language),
        _metadata('Effective', _date(document.effectiveDate)),
        _metadata('Review date', _date(document.reviewDate)),
        _metadata('Expires', _date(document.expiresAt)),
        const SizedBox(height: 20),
        FutureBuilder<OfflineDownload?>(
          key: ValueKey(_downloadRevision),
          future: ref
              .read(guidelineDownloadServiceProvider)
              .get(scope: 'public', id: '${document.id}:outbreak_document'),
          builder: (context, snapshot) => _actions(document, snapshot.data),
        ),
      ],
    );
  }

  Widget _actions(PublicOutbreakDocument document, OfflineDownload? offline) {
    final ready =
        offline?.status == OfflineDownloadStatus.ready &&
        offline!.localPath.isNotEmpty;
    final downloading =
        offline?.status == OfflineDownloadStatus.downloading ||
        offline?.status == OfflineDownloadStatus.queued;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (document.supportsInline)
          FilledButton.icon(
            onPressed: () => _readInline(document),
            icon: const Icon(LucideIcons.bookOpenText),
            label: const Text('Read document'),
          ),
        FilledButton.icon(
          onPressed: downloading
              ? null
              : () => ready ? _open(document, offline) : _download(document),
          icon: Icon(ready ? LucideIcons.bookOpen : LucideIcons.download),
          label: Text(ready ? 'Open offline copy' : 'Download for offline use'),
        ),
        if (downloading) ...[
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: (offline?.progress ?? 0) > 0 ? offline!.progress : null,
          ),
          TextButton(
            onPressed: () => ref
                .read(guidelineDownloadServiceProvider)
                .cancel(document.id, 'outbreak_document'),
            child: const Text('Cancel download'),
          ),
        ],
        OutlinedButton.icon(
          onPressed: () => _open(document, null),
          icon: const Icon(LucideIcons.externalLink),
          label: const Text('Open current online version'),
        ),
        if (ready)
          TextButton.icon(
            onPressed: () async {
              await ref.read(guidelineDownloadServiceProvider).remove(offline);
              if (mounted) setState(() => _downloadRevision++);
            },
            icon: const Icon(LucideIcons.trash2),
            label: const Text('Remove offline copy'),
          ),
      ],
    );
  }

  Future<void> _readInline(PublicOutbreakDocument document) async {
    try {
      final result = await ref
          .read(outbreakRepositoryProvider)
          .documentContent(document.id);
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => _MarkdownDocumentPage(
            title: document.title,
            source: result.value.content,
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Readable content is unavailable: $error')),
      );
    }
  }

  Future<OfflineDownload?> _download(PublicOutbreakDocument document) async {
    final uri = _downloadUri(document);
    if (uri == null) {
      _showUnavailable();
      return null;
    }
    try {
      return await ref
          .read(guidelineDownloadServiceProvider)
          .download(
            guidelineId: document.id,
            title: document.title,
            version: document.version,
            assetType: 'outbreak_document',
            scope: 'public',
            asset: GuidelineAsset(
              id: document.id,
              type: 'outbreak_document',
              mimeType: document.mimeType,
              checksum: document.checksumSha256,
              sizeBytes: document.fileSize,
              originalFilename: document.originalFilename,
              url: uri.toString(),
            ),
          );
    } catch (error) {
      if (!mounted) return null;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Download failed: $error')));
      return null;
    }
  }

  Future<void> _open(
    PublicOutbreakDocument document,
    OfflineDownload? offline,
  ) async {
    final local = offline?.localPath;
    final source = local != null && local.isNotEmpty
        ? Uri.file(local).toString()
        : _downloadUri(document)?.toString();
    if (source == null) return _showUnavailable();
    final mime = document.mimeType.toLowerCase();
    final filename = document.originalFilename.toLowerCase();
    if (mime == 'application/pdf' || filename.endsWith('.pdf')) {
      if (mounted) {
        context.push(
          AppRoutes.documentReader,
          extra: DocumentReaderArgs(title: document.title, source: source),
        );
      }
      return;
    }
    if (mime.contains('markdown') || filename.endsWith('.md')) {
      if ((local == null || local.isEmpty) && document.supportsInline) {
        return _readInline(document);
      }
      if (local == null || local.isEmpty) {
        final downloaded = await _download(document);
        if (downloaded?.status != OfflineDownloadStatus.ready) return;
        return _open(document, downloaded);
      }
      final text = await File(local).readAsString();
      if (mounted) {
        await Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) =>
                _MarkdownDocumentPage(title: document.title, source: text),
          ),
        );
      }
      return;
    }
    final uri = Uri.tryParse(source);
    if (uri == null ||
        !await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      _showUnavailable();
    }
  }

  Uri? _downloadUri(PublicOutbreakDocument document) {
    final relative = Uri.tryParse(document.downloadUrl.trim());
    if (relative == null || relative.hasAuthority || relative.hasFragment) {
      return null;
    }
    return Uri.parse('${AppConfig.current.apiBaseUrl}/').resolveUri(relative);
  }

  void _showUnavailable() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('This document is currently unavailable.')),
    );
  }

  Widget _metadata(String label, String value) {
    if (value.trim().isEmpty) return const SizedBox.shrink();
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(label),
      subtitle: Text(value),
    );
  }

  String _date(DateTime? value) =>
      value == null ? '' : value.toLocal().toIso8601String().split('T').first;

  (String, Color, IconData)? _status(PublicOutbreakDocument document) {
    final now = DateTime.now().toUtc();
    if (document.expiresAt != null && !document.expiresAt!.isAfter(now)) {
      return (
        'Expired — refresh before clinical use',
        Colors.red.shade50,
        LucideIcons.triangleAlert,
      );
    }
    if (document.reviewDate != null && !document.reviewDate!.isAfter(now)) {
      return (
        'Review date reached — check for an update',
        Colors.orange.shade50,
        LucideIcons.refreshCw,
      );
    }
    return null;
  }
}

class _MarkdownDocumentPage extends StatelessWidget {
  const _MarkdownDocumentPage({required this.title, required this.source});
  final String title;
  final String source;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(title)),
    body: Markdown(
      data: source,
      selectable: true,
      padding: const EdgeInsets.all(20),
      onTapLink: (_, href, _) async {
        final uri = Uri.tryParse(href ?? '');
        if (uri != null && uri.scheme == 'https') {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      },
      styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
        h1: Theme.of(
          context,
        ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800),
      ),
    ),
  );
}
