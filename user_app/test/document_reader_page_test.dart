import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:user_app/features/documents/presentation/screens/document_reader_page.dart';

void main() {
  test('document reader accepts only supported local and web sources', () {
    expect(
      isSupportedDocumentSource('https://example.test/report.pdf'),
      isTrue,
    );
    expect(isSupportedDocumentSource('http://localhost/report.pdf'), isTrue);
    expect(isSupportedDocumentSource('file:///tmp/report.pdf'), isTrue);
    expect(isSupportedDocumentSource('javascript:alert(1)'), isFalse);
    expect(
      isSupportedDocumentSource('data:application/pdf;base64,abc'),
      isFalse,
    );
    expect(isSupportedDocumentSource(''), isFalse);
  });

  testWidgets('document reader presents a safe designed invalid-source state', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: DocumentReaderPage(
          args: DocumentReaderArgs(
            title: 'Clinical guideline',
            source: 'javascript:alert(1)',
          ),
        ),
      ),
    );

    expect(find.text('Clinical guideline'), findsOneWidget);
    expect(find.text('Document unavailable'), findsOneWidget);
    expect(
      find.text('This document does not have a valid source.'),
      findsOneWidget,
    );
  });
}
