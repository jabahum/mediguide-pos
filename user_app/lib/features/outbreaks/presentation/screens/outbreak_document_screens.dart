import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:share_plus/share_plus.dart';
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

part '../widgets/outbreak_document_screens_widgets.dart';

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
    this.initialDocument,
  });
  final String outbreakId;
  final String documentId;
  final PublicOutbreakDocument? initialDocument;

  @override
  ConsumerState<OutbreakDocumentPage> createState() =>
      _OutbreakDocumentPageState();
}

class _OutbreakDocumentPageState extends ConsumerState<OutbreakDocumentPage> {
  StreamSubscription<OfflineDownload>? _subscription;
  int _downloadRevision = 0;
  bool _openedInitialMatch = false;

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
    WidgetsBinding.instance.addPostFrameCallback((_) => _openInitialMatch());
  }

  Future<void> _openInitialMatch() async {
    if (_openedInitialMatch || !mounted) return;
    final document = widget.initialDocument;
    if (document == null ||
        (document.matchingSectionId.isEmpty &&
            document.matchingHeading.isEmpty &&
            document.matchingPdfPage == null)) {
      return;
    }
    _openedInitialMatch = true;
    if (document.supportsInline &&
        (document.matchingSectionId.isNotEmpty ||
            document.matchingHeading.isNotEmpty)) {
      await _readInline(
        document,
        matchingHeading: document.matchingHeading,
        matchingSectionId: document.matchingSectionId,
      );
      return;
    }
    if (document.matchingPdfPage != null) {
      await _open(document, null, initialPage: document.matchingPdfPage);
    }
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
        if (!document.supportsInline) const OutbreakUnsupportedFormatNotice(),
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
          onPressed: () => _openOriginal(document),
          icon: const Icon(LucideIcons.externalLink),
          label: const Text('Open original'),
        ),
        OutlinedButton.icon(
          onPressed: () => _shareDocument(document),
          icon: const Icon(LucideIcons.share2),
          label: const Text('Share'),
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

  Future<void> _readInline(
    PublicOutbreakDocument document, {
    String? matchingHeading,
    String? matchingSectionId,
  }) async {
    try {
      final result = await ref
          .read(outbreakRepositoryProvider)
          .documentContent(document.id);
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => OutbreakMarkdownReaderPage(
            document: document,
            content: result.value,
            cache: result.cache,
            matchingHeading: _resolvedHeading(
              result.value,
              matchingHeading,
              matchingSectionId,
            ),
            onOpenOriginal: () => _openOriginal(document),
            onSaveOffline: () => _download(document),
            onShare: () => _shareDocument(document),
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

  String? _resolvedHeading(
    OutbreakDocumentContent content,
    String? heading,
    String? sectionId,
  ) {
    if (heading?.trim().isNotEmpty == true) return heading!.trim();
    if (sectionId?.trim().isNotEmpty != true) return null;
    for (final section in content.sections) {
      if (section.id == sectionId) return section.heading;
    }
    return null;
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
    OfflineDownload? offline, {
    int? initialPage,
  }) async {
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
          extra: DocumentReaderArgs(
            title: document.title,
            source: source,
            initialPage: initialPage,
          ),
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
            builder: (_) => OutbreakMarkdownReaderPage(
              document: document,
              content: OutbreakDocumentContent(
                documentId: document.id,
                outbreakId: document.outbreakId,
                title: document.title,
                content: text,
                contentFormat: 'markdown',
                mimeType: document.mimeType,
                checksumSha256: document.checksumSha256,
                publishedAt: document.publishedAt,
                effectiveDate: document.effectiveDate,
                reviewDate: document.reviewDate,
                expiresAt: document.expiresAt,
                downloadUrl: document.downloadUrl,
                originalAvailable: document.downloadUrl.isNotEmpty,
                canReadInline: true,
              ),
              cache: const PublicCacheMetadata(
                cachedAt: null,
                lastVerifiedAt: null,
                isOffline: true,
                isStale: false,
                isWithdrawn: false,
              ),
              onOpenOriginal: () => _openOriginal(document),
              onSaveOffline: () => _download(document),
              onShare: () => _shareDocument(document),
            ),
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

  Future<void> _openOriginal(PublicOutbreakDocument document) async {
    final uri = _downloadUri(document);
    if (uri == null ||
        !await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      _showUnavailable();
    }
  }

  Future<void> _shareDocument(PublicOutbreakDocument document) async {
    final uri = _downloadUri(document);
    final text = [
      document.title,
      if (document.issuingAuthority.isNotEmpty) document.issuingAuthority,
      if (uri != null) uri.toString(),
    ].join('\n');
    await SharePlus.instance.share(
      ShareParams(text: text, subject: document.title),
    );
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

class OutbreakMarkdownReaderPage extends StatefulWidget {
  const OutbreakMarkdownReaderPage({
    super.key,
    required this.document,
    required this.content,
    required this.cache,
    required this.onOpenOriginal,
    required this.onSaveOffline,
    required this.onShare,
    this.matchingHeading,
  });
  final PublicOutbreakDocument document;
  final OutbreakDocumentContent content;
  final PublicCacheMetadata cache;
  final Future<void> Function() onOpenOriginal;
  final Future<void> Function() onSaveOffline;
  final Future<void> Function() onShare;
  final String? matchingHeading;

  @override
  State<OutbreakMarkdownReaderPage> createState() =>
      _OutbreakMarkdownReaderPageState();
}

class _OutbreakMarkdownReaderPageState
    extends State<OutbreakMarkdownReaderPage> {
  final ScrollController _controller = ScrollController();
  final TextEditingController _search = TextEditingController();
  bool _searchVisible = false;
  int _matchIndex = 0;
  int _initialMatchAttempts = 0;

  String get _source => widget.content.content;

  List<int> get _matches {
    final query = _search.text.trim().toLowerCase();
    if (query.isEmpty) return const <int>[];
    final source = _source.toLowerCase();
    final matches = <int>[];
    var offset = 0;
    while (offset < source.length) {
      final index = source.indexOf(query, offset);
      if (index < 0) break;
      matches.add(index);
      offset = index + query.length;
    }
    return matches;
  }

  List<({String id, String heading, int level, int offset})> get _headings {
    if (widget.content.sections.isNotEmpty) {
      return widget.content.sections
          .map((section) {
            final offset = _source.toLowerCase().indexOf(
              section.heading.toLowerCase(),
            );
            return (
              id: section.id,
              heading: section.heading,
              level: section.level,
              offset: offset < 0 ? 0 : offset,
            );
          })
          .toList(growable: false);
    }
    return RegExp(r'^(#{1,6})\s+(.+)$', multiLine: true)
        .allMatches(_source)
        .map(
          (match) => (
            id: 'heading-${match.start}',
            heading: match.group(2)?.trim() ?? '',
            level: match.group(1)?.length ?? 1,
            offset: match.start,
          ),
        )
        .where((heading) => heading.heading.isNotEmpty)
        .toList(growable: false);
  }

  @override
  void initState() {
    super.initState();
    _scheduleInitialMatch();
  }

  @override
  void dispose() {
    _controller.dispose();
    _search.dispose();
    super.dispose();
  }

  void _scheduleInitialMatch() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _initialMatchAttempts++;
      final moved = _scrollToMatch();
      // The Markdown scroll position may attach one frame after the parent
      // page. Retry briefly so deep links reliably land on their match.
      if (!moved && _initialMatchAttempts < 3) _scheduleInitialMatch();
    });
  }

  bool _scrollToMatch() {
    final heading = widget.matchingHeading?.trim() ?? '';
    if (heading.isEmpty || !_controller.hasClients || _source.isEmpty) {
      return heading.isEmpty;
    }
    final index = _source.toLowerCase().indexOf(heading.toLowerCase());
    if (index < 0) return true;
    if (_controller.position.maxScrollExtent <= 0 && index > 0) return false;
    _scrollToOffset(index);
    return true;
  }

  void _scrollToOffset(int sourceOffset) {
    if (!_controller.hasClients || _source.isEmpty) return;
    final ratio = (sourceOffset / _source.length).clamp(0.0, 1.0);
    _controller.jumpTo(_controller.position.maxScrollExtent * ratio);
  }

  void _moveMatch(int delta) {
    final matches = _matches;
    if (matches.isEmpty) return;
    setState(() {
      _matchIndex = (_matchIndex + delta) % matches.length;
      if (_matchIndex < 0) _matchIndex += matches.length;
    });
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _scrollToOffset(matches[_matchIndex]),
    );
  }

  Future<void> _showContents() async {
    final headings = _headings;
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: headings.isEmpty
            ? const Padding(
                padding: EdgeInsets.all(24),
                child: Text('No structured headings are available.'),
              )
            : ListView(
                shrinkWrap: true,
                children: [
                  const ListTile(
                    title: Text('Table of contents'),
                    leading: Icon(LucideIcons.listTree),
                  ),
                  for (final heading in headings)
                    ListTile(
                      contentPadding: EdgeInsets.only(
                        left: 16.0 + ((heading.level - 1).clamp(0, 4) * 14),
                        right: 16,
                      ),
                      title: Text(heading.heading),
                      onTap: () {
                        Navigator.pop(sheetContext);
                        WidgetsBinding.instance.addPostFrameCallback(
                          (_) => _scrollToOffset(heading.offset),
                        );
                      },
                    ),
                ],
              ),
      ),
    );
  }

  String _date(DateTime? value) =>
      value == null ? '' : value.toLocal().toIso8601String().split('T').first;

  Widget? _lifecycleWarning() {
    final now = DateTime.now().toUtc();
    if (widget.content.expiresAt != null &&
        !widget.content.expiresAt!.isAfter(now)) {
      return const _ReaderWarning(
        text: 'This document has expired. Refresh before clinical use.',
        icon: LucideIcons.triangleAlert,
        critical: true,
      );
    }
    if (widget.content.reviewDate != null &&
        !widget.content.reviewDate!.isAfter(now)) {
      return const _ReaderWarning(
        text: 'The clinical review date has been reached. Check for an update.',
        icon: LucideIcons.refreshCw,
      );
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final matches = _matches;
    if (_matchIndex >= matches.length) _matchIndex = 0;
    final warning = _lifecycleWarning();
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.document.title),
        actions: [
          IconButton(
            tooltip: 'Search this document',
            onPressed: () => setState(() => _searchVisible = !_searchVisible),
            icon: const Icon(LucideIcons.search),
          ),
          IconButton(
            tooltip: 'Table of contents',
            onPressed: _showContents,
            icon: const Icon(LucideIcons.listTree),
          ),
        ],
      ),
      body: Column(
        children: [
          if (_searchVisible)
            Material(
              color: Theme.of(context).colorScheme.surfaceContainerLow,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _search,
                        autofocus: true,
                        textInputAction: TextInputAction.search,
                        decoration: const InputDecoration(
                          hintText: 'Find in document',
                          prefixIcon: Icon(LucideIcons.search),
                        ),
                        onChanged: (_) => setState(() => _matchIndex = 0),
                        onSubmitted: (_) => _moveMatch(0),
                      ),
                    ),
                    Semantics(
                      liveRegion: true,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Text(
                          matches.isEmpty
                              ? '0 matches'
                              : '${_matchIndex + 1}/${matches.length}',
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Previous match',
                      onPressed: matches.isEmpty ? null : () => _moveMatch(-1),
                      icon: const Icon(LucideIcons.chevronUp),
                    ),
                    IconButton(
                      tooltip: 'Next match',
                      onPressed: matches.isEmpty ? null : () => _moveMatch(1),
                      icon: const Icon(LucideIcons.chevronDown),
                    ),
                  ],
                ),
              ),
            ),
          if (_searchVisible && matches.isNotEmpty)
            _SearchMatchPreview(
              source: _source,
              query: _search.text,
              offset: matches[_matchIndex],
            ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Row(
              children: [
                _ReaderChip(
                  icon: LucideIcons.landmark,
                  label: widget.document.issuingAuthority.isEmpty
                      ? 'Official source'
                      : widget.document.issuingAuthority,
                ),
                if (widget.document.version.isNotEmpty)
                  _ReaderChip(
                    icon: LucideIcons.gitBranch,
                    label: 'Version ${widget.document.version}',
                  ),
                if (widget.content.publishedAt != null)
                  _ReaderChip(
                    icon: LucideIcons.calendarDays,
                    label: 'Published ${_date(widget.content.publishedAt)}',
                  ),
                if (widget.cache.isOffline)
                  _ReaderChip(
                    icon: LucideIcons.cloudOff,
                    label: widget.cache.isStale
                        ? 'Offline · may be stale'
                        : 'Offline copy',
                  ),
              ],
            ),
          ),
          if (warning != null) warning,
          Expanded(
            child: Markdown(
              key: const Key('outbreak-document-markdown'),
              data: _source,
              controller: _controller,
              selectable: true,
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
              onTapLink: (_, href, _) async {
                final uri = Uri.tryParse(href ?? '');
                if (uri != null && uri.scheme == 'https') {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              },
              styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context))
                  .copyWith(
                    h1: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            children: [
              TextButton.icon(
                onPressed: widget.onOpenOriginal,
                icon: const Icon(LucideIcons.fileDown),
                label: const Text('Open original'),
              ),
              TextButton.icon(
                onPressed: widget.onSaveOffline,
                icon: const Icon(LucideIcons.download),
                label: const Text('Save offline'),
              ),
              TextButton.icon(
                onPressed: widget.onShare,
                icon: const Icon(LucideIcons.share2),
                label: const Text('Share'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
