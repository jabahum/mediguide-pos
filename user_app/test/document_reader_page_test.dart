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
}
