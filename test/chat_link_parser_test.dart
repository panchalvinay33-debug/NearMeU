import 'package:flutter_test/flutter_test.dart';
import 'package:nearmeu/widgets/chat/linkified_message_text.dart';

void main() {
  test('parses safe http and https links from mixed text', () {
    final segments = ChatLinkParser.parse(
      'Open https://example.com and http://example.org now',
    );

    expect(segments.where((segment) => segment.isLink).length, 2);
    expect(
      segments.where((segment) => segment.isLink).map((segment) => segment.uri!.scheme),
      containsAll(<String>['https', 'http']),
    );
  });

  test('does not linkify unsafe schemes', () {
    final segments = ChatLinkParser.parse(
      'javascript:alert(1) file:///tmp/test intent://open',
    );

    expect(segments.any((segment) => segment.isLink), isFalse);
  });

  test('trims trailing punctuation from a link', () {
    final segments = ChatLinkParser.parse('Visit https://example.com/test).');
    final link = segments.firstWhere((segment) => segment.isLink);

    expect(link.uri.toString(), 'https://example.com/test');
  });
}
