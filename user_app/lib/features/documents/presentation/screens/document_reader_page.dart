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

part '../widgets/document_reader_page_widgets.dart';

final class DocumentReaderArgs {
  const DocumentReaderArgs({
    required this.title,
    required this.source,
    this.initialPage,
  });

  final String title;
  final String source;

  /// One-based page supplied by search results and converted to the zero-based
  /// page index expected by the native PDF viewer.
  final int? initialPage;
}

bool isSupportedDocumentSource(String value) {
  final source = value.trim();

  if (source.isEmpty) {
    return false;
  }

  final uri = Uri.tryParse(source);

  if (uri == null) {
    return false;
  }

  return uri.scheme == 'https' || uri.scheme == 'http' || uri.scheme == 'file';
}

class DocumentReaderPage extends StatefulWidget {
  const DocumentReaderPage({super.key, required this.args});

  final DocumentReaderArgs args;

  @override
  State<DocumentReaderPage> createState() => _DocumentReaderPageState();
}

class _DocumentReaderPageState extends State<DocumentReaderPage> {
  final Dio _dio = Dio(
    BaseOptions(
      followRedirects: true,
      receiveTimeout: const Duration(seconds: 90),
      connectTimeout: const Duration(seconds: 30),
    ),
  );

  CancelToken? _cancelToken;
  PDFViewController? _pdfController;

  late Future<String> _documentPath;

  double? _downloadProgress;

  int _currentPage = 0;
  int _pageCount = 0;

  bool _pdfRendered = false;
  bool _renderErrorShown = false;

  String get _source => widget.args.source.trim();

  String get _title {
    final value = widget.args.title.trim();

    return value.isEmpty ? 'Document reader' : value;
  }

  bool get _hasValidSource => isSupportedDocumentSource(_source);

  int get _initialPageIndex {
    final page = widget.args.initialPage ?? 1;
    return page > 1 ? page - 1 : 0;
  }

  @override
  void initState() {
    super.initState();

    _documentPath = _hasValidSource
        ? _prepareDocument()
        : Future<String>.value('');
  }

  @override
  void dispose() {
    _cancelToken?.cancel('Document reader closed');

    _dio.close(force: true);

    super.dispose();
  }

  // =========================================================================
  // PREPARE DOCUMENT
  // =========================================================================

  Future<String> _prepareDocument() async {
    final uri = Uri.parse(_source);

    // =======================================================================
    // LOCAL FILE
    // =======================================================================

    if (uri.scheme == 'file') {
      final filePath = uri.toFilePath();

      final file = File(filePath);

      if (!await file.exists()) {
        throw const FileSystemException('The local PDF could not be found.');
      }

      if (await file.length() == 0) {
        throw const FormatException('The local PDF is empty.');
      }

      return filePath;
    }

    // =======================================================================
    // REMOTE FILE
    // =======================================================================

    final directory = await getTemporaryDirectory();

    final cacheKey = sha256.convert(_source.codeUnits).toString();

    final target = File(
      path.join(directory.path, 'mediguide-pdf-$cacheKey.pdf'),
    );

    // Already cached.
    if (await target.exists() && await target.length() > 0) {
      return target.path;
    }

    final partial = File('${target.path}.part');

    if (await partial.exists()) {
      await partial.delete();
    }

    _cancelToken = CancelToken();

    if (mounted) {
      setState(() {
        _downloadProgress = null;
      });
    }

    try {
      await _dio.download(
        _source,
        partial.path,
        cancelToken: _cancelToken,
        options: Options(responseType: ResponseType.bytes),
        onReceiveProgress: (received, total) {
          if (!mounted || total <= 0) {
            return;
          }

          final progress = (received / total).clamp(0.0, 1.0);

          setState(() {
            _downloadProgress = progress;
          });
        },
      );

      if (!await partial.exists() || await partial.length() == 0) {
        throw const FormatException('The downloaded PDF is empty.');
      }

      await partial.rename(target.path);

      return target.path;
    } catch (_) {
      if (await partial.exists()) {
        await partial.delete();
      }

      rethrow;
    }
  }

  // =========================================================================
  // BUILD
  // =========================================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: AppSpacing.sm,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),

            if (_pageCount > 0)
              Text(
                'Page ${_currentPage + 1} of $_pageCount',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Open original PDF',
            onPressed: _hasValidSource ? _openOriginal : null,
            icon: const Icon(LucideIcons.externalLink),
          ),
        ],
      ),

      body: !_hasValidSource
          ? const _DocumentError(
              message: 'This document does not have a valid source.',
            )
          : FutureBuilder<String>(
              future: _documentPath,
              builder: (context, snapshot) {
                // ===========================================================
                // ERROR
                // ===========================================================

                if (snapshot.hasError) {
                  return _DocumentError(
                    message:
                        'The PDF could not be loaded. '
                        'Check your connection or open the original document.',
                    onRetry: _retry,
                    onOpenOriginal: _openOriginal,
                  );
                }

                // ===========================================================
                // LOADING
                // ===========================================================

                final filePath = snapshot.data;

                if (filePath == null || filePath.isEmpty) {
                  return _DocumentLoading(progress: _downloadProgress);
                }

                // ===========================================================
                // READER
                // ===========================================================

                return Stack(
                  children: [
                    Column(
                      children: [
                        Expanded(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: Theme.of(
                                context,
                              ).colorScheme.surfaceContainerHigh,
                            ),
                            child: Semantics(
                              label: 'PDF document viewer',
                              child: PDFView(
                                filePath: filePath,

                                defaultPage: _initialPageIndex,

                                enableSwipe: true,

                                swipeHorizontal: false,

                                autoSpacing: true,

                                pageFling: true,

                                pageSnap: true,

                                fitPolicy: FitPolicy.BOTH,

                                fitEachPage: true,

                                preventLinkNavigation: false,

                                onViewCreated: (controller) {
                                  _pdfController = controller;
                                },

                                onRender: (pages) {
                                  if (!mounted) {
                                    return;
                                  }

                                  setState(() {
                                    _pageCount = pages ?? 0;

                                    _pdfRendered = true;
                                  });
                                },

                                onPageChanged: (page, total) {
                                  if (!mounted) {
                                    return;
                                  }

                                  setState(() {
                                    _currentPage = page ?? 0;

                                    if (total != null) {
                                      _pageCount = total;
                                    }
                                  });
                                },

                                onError: (_) {
                                  _showRenderError();
                                },

                                onPageError: (page, error) {
                                  _showRenderError();
                                },
                              ),
                            ),
                          ),
                        ),

                        _DocumentNavigationBar(
                          currentPage: _currentPage,
                          pageCount: _pageCount,
                          onPrevious: _currentPage > 0
                              ? () {
                                  _goToPage(_currentPage - 1);
                                }
                              : null,
                          onNext:
                              _pageCount > 0 && _currentPage < _pageCount - 1
                              ? () {
                                  _goToPage(_currentPage + 1);
                                }
                              : null,
                          onOpenOriginal: _openOriginal,
                        ),
                      ],
                    ),

                    // =======================================================
                    // PDF RENDERING OVERLAY
                    // =======================================================
                    if (!_pdfRendered)
                      Positioned.fill(
                        child: IgnorePointer(
                          child: ColoredBox(
                            color: Theme.of(
                              context,
                            ).colorScheme.surface.withValues(alpha: 0.86),
                            child: const _PdfRenderingOverlay(),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
    );
  }

  // =========================================================================
  // RETRY
  // =========================================================================

  void _retry() {
    _cancelToken?.cancel('Retrying document download');

    setState(() {
      _downloadProgress = null;
      _currentPage = 0;
      _pageCount = 0;
      _pdfRendered = false;
      _renderErrorShown = false;

      _documentPath = _prepareDocument();
    });
  }

  // =========================================================================
  // OPEN ORIGINAL
  // =========================================================================

  Future<void> _openOriginal() async {
    final uri = Uri.tryParse(_source);

    if (uri == null) {
      _showMessage('The original document link is invalid.');

      return;
    }

    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!launched && mounted) {
        _showMessage('Unable to open the original PDF.');
      }
    } catch (_) {
      if (!mounted) {
        return;
      }

      _showMessage('Unable to open the original PDF.');
    }
  }

  // =========================================================================
  // PAGE NAVIGATION
  // =========================================================================

  Future<void> _goToPage(int page) async {
    if (page < 0) {
      return;
    }

    if (_pageCount > 0 && page >= _pageCount) {
      return;
    }

    try {
      await _pdfController?.setPage(page);
    } catch (_) {
      if (!mounted) {
        return;
      }

      _showMessage('Unable to open that page.');
    }
  }

  // =========================================================================
  // PDF RENDER ERROR
  // =========================================================================

  void _showRenderError() {
    if (!mounted || _renderErrorShown) {
      return;
    }

    _renderErrorShown = true;

    _showMessage(
      'A page could not be rendered. '
      'Try opening the original PDF.',
    );
  }

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

// ===========================================================================
// ERROR
// ===========================================================================
