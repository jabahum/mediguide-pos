import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:user_app/core/constants/app_spacing.dart';
import 'package:user_app/shared/widgets/clinical_icon_tile.dart';

final class DocumentReaderArgs {
  const DocumentReaderArgs({required this.title, required this.source});

  final String title;
  final String source;
}

bool isSupportedDocumentSource(String value) {
  final source = value.trim();
  if (source.isEmpty) return false;
  final uri = Uri.tryParse(source);
  if (uri == null) return false;
  return uri.scheme == 'https' || uri.scheme == 'http' || uri.scheme == 'file';
}

class DocumentReaderPage extends StatefulWidget {
  const DocumentReaderPage({super.key, required this.args});

  final DocumentReaderArgs args;

  @override
  State<DocumentReaderPage> createState() => _DocumentReaderPageState();
}

class _DocumentReaderPageState extends State<DocumentReaderPage> {
  CancelToken? _cancelToken;
  PDFViewController? _pdfController;
  late Future<String> _documentPath;
  double? _downloadProgress;
  int _currentPage = 0;
  int _pageCount = 0;

  @override
  void initState() {
    super.initState();
    _documentPath = isSupportedDocumentSource(widget.args.source)
        ? _prepareDocument()
        : Future<String>.value('');
  }

  @override
  void dispose() {
    _cancelToken?.cancel('Document reader closed');
    super.dispose();
  }

  Future<String> _prepareDocument() async {
    final source = widget.args.source.trim();
    final uri = Uri.parse(source);
    if (uri.scheme == 'file') return uri.toFilePath();

    final directory = await getTemporaryDirectory();
    final name = sha256.convert(source.codeUnits).toString();
    final target = File(path.join(directory.path, 'mediguide-pdf-$name.pdf'));
    if (await target.exists() && await target.length() > 0) return target.path;

    final partial = File('${target.path}.part');
    if (await partial.exists()) await partial.delete();
    _cancelToken = CancelToken();
    try {
      await Dio().download(
        source,
        partial.path,
        cancelToken: _cancelToken,
        options: Options(
          followRedirects: true,
          receiveTimeout: const Duration(seconds: 90),
        ),
        onReceiveProgress: (received, total) {
          if (!mounted || total <= 0) return;
          setState(() => _downloadProgress = received / total);
        },
      );
      if (await partial.length() == 0) {
        throw const FormatException('The downloaded PDF is empty.');
      }
      await partial.rename(target.path);
      return target.path;
    } catch (_) {
      if (await partial.exists()) await partial.delete();
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    final source = widget.args.source.trim();
    final title = widget.args.title.trim().isEmpty
        ? 'Document reader'
        : widget.args.title.trim();
    return Scaffold(
      appBar: AppBar(
        title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: [
          IconButton(
            tooltip: 'Open original PDF',
            onPressed: isSupportedDocumentSource(source) ? _openOriginal : null,
            icon: const Icon(LucideIcons.fileDown),
          ),
        ],
      ),
      body: !isSupportedDocumentSource(source)
          ? const _DocumentError(
              message: 'This document does not have a valid source.',
            )
          : FutureBuilder<String>(
              future: _documentPath,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return _DocumentError(
                    message:
                        'The PDF could not be loaded. Check your connection '
                        'or open the original document.',
                    onRetry: _retry,
                    onOpenOriginal: _openOriginal,
                  );
                }
                final filePath = snapshot.data;
                if (filePath == null) {
                  return _DocumentLoading(progress: _downloadProgress);
                }
                return Column(
                  children: [
                    Expanded(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).colorScheme.surfaceContainerHighest,
                        ),
                        child: Semantics(
                          label: 'PDF document viewer',
                          child: PDFView(
                            filePath: filePath,
                            enableSwipe: true,
                            swipeHorizontal: false,
                            autoSpacing: true,
                            pageFling: true,
                            fitEachPage: true,
                            onViewCreated: (controller) =>
                                _pdfController = controller,
                            onRender: (pages) {
                              if (!mounted) return;
                              setState(() => _pageCount = pages ?? 0);
                            },
                            onPageChanged: (page, total) {
                              if (!mounted) return;
                              setState(() {
                                _currentPage = page ?? 0;
                                _pageCount = total ?? _pageCount;
                              });
                            },
                            onError: (_) => _showRenderError(),
                            onPageError: (page, error) => _showRenderError(),
                          ),
                        ),
                      ),
                    ),
                    _DocumentNavigationBar(
                      currentPage: _currentPage,
                      pageCount: _pageCount,
                      onPrevious: _currentPage > 0
                          ? () => _goToPage(_currentPage - 1)
                          : null,
                      onNext: _pageCount > 0 && _currentPage < _pageCount - 1
                          ? () => _goToPage(_currentPage + 1)
                          : null,
                      onOpenOriginal: _openOriginal,
                    ),
                  ],
                );
              },
            ),
    );
  }

  void _retry() {
    _cancelToken?.cancel('Retrying document download');
    setState(() {
      _downloadProgress = null;
      _currentPage = 0;
      _pageCount = 0;
      _documentPath = _prepareDocument();
    });
  }

  Future<void> _openOriginal() async {
    await launchUrl(
      Uri.parse(widget.args.source.trim()),
      mode: LaunchMode.externalApplication,
    );
  }

  Future<void> _goToPage(int page) async {
    await _pdfController?.setPage(page);
  }

  void _showRenderError() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('This page could not be rendered. Try the original PDF.'),
      ),
    );
  }
}

class _DocumentError extends StatelessWidget {
  const _DocumentError({
    required this.message,
    this.onRetry,
    this.onOpenOriginal,
  });

  final String message;
  final VoidCallback? onRetry;
  final VoidCallback? onOpenOriginal;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const ClinicalIconTile(
            icon: LucideIcons.fileWarning,
            size: 72,
            iconSize: 34,
          ),
          AppSpacing.gapLg,
          Text(
            'Document unavailable',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
            textAlign: TextAlign.center,
          ),
          AppSpacing.gapSm,
          Text(
            message,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          if (onRetry != null) ...[
            AppSpacing.gapLg,
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(LucideIcons.refreshCw),
              label: const Text('Try again'),
            ),
          ],
          if (onOpenOriginal != null) ...[
            AppSpacing.gapSm,
            TextButton.icon(
              onPressed: onOpenOriginal,
              icon: const Icon(LucideIcons.externalLink),
              label: const Text('Open original PDF'),
            ),
          ],
        ],
      ),
    ),
  );
}

class _DocumentLoading extends StatelessWidget {
  const _DocumentLoading({required this.progress});

  final double? progress;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: AppSpacing.paddingLg,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const ClinicalIconTile(
            icon: LucideIcons.fileText,
            size: 72,
            iconSize: 34,
          ),
          AppSpacing.gapLg,
          Text(
            'Preparing document',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          AppSpacing.gapSm,
          Text(
            progress == null
                ? 'Loading the clinical document…'
                : 'Downloaded ${(progress! * 100).round()}%',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          AppSpacing.gapMd,
          SizedBox(width: 220, child: LinearProgressIndicator(value: progress)),
        ],
      ),
    ),
  );
}

class _DocumentNavigationBar extends StatelessWidget {
  const _DocumentNavigationBar({
    required this.currentPage,
    required this.pageCount,
    required this.onPrevious,
    required this.onNext,
    required this.onOpenOriginal,
  });

  final int currentPage;
  final int pageCount;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;
  final VoidCallback onOpenOriginal;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return SafeArea(
      top: false,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.surface,
          border: Border(top: BorderSide(color: colors.outlineVariant)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xs,
          ),
          child: Row(
            children: [
              IconButton(
                tooltip: 'Previous page',
                onPressed: onPrevious,
                icon: const Icon(LucideIcons.chevronLeft),
              ),
              Expanded(
                child: Semantics(
                  liveRegion: true,
                  child: Text(
                    pageCount == 0
                        ? 'Preparing pages'
                        : 'Page ${currentPage + 1} of $pageCount',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Next page',
                onPressed: onNext,
                icon: const Icon(LucideIcons.chevronRight),
              ),
              IconButton(
                tooltip: 'Open original PDF',
                onPressed: onOpenOriginal,
                icon: const Icon(LucideIcons.externalLink),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
