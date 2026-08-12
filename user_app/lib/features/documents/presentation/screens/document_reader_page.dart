import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';

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
  late final Future<String> _documentPath = _prepareDocument();

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
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.args.title.isEmpty ? 'Document reader' : widget.args.title,
        ),
        actions: [
          IconButton(
            tooltip: 'Open in another app',
            onPressed: isSupportedDocumentSource(source)
                ? () => launchUrl(
                    Uri.parse(source),
                    mode: LaunchMode.externalApplication,
                  )
                : null,
            icon: const Icon(LucideIcons.externalLink),
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
                    message: 'Unable to load this PDF. ${snapshot.error}',
                  );
                }
                final filePath = snapshot.data;
                if (filePath == null) {
                  return const Center(child: CircularProgressIndicator());
                }
                return Semantics(
                  label: 'PDF document viewer',
                  child: PDFView(
                    filePath: filePath,
                    enableSwipe: true,
                    swipeHorizontal: false,
                    autoSpacing: true,
                    pageFling: true,
                    onError: (error) {
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('PDF rendering failed: $error')),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
}

class _DocumentError extends StatelessWidget {
  const _DocumentError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(LucideIcons.fileWarning, size: 48),
          const SizedBox(height: 16),
          Text(message, textAlign: TextAlign.center),
        ],
      ),
    ),
  );
}
