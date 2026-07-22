import 'package:flutter_test/flutter_test.dart';
import 'package:nearmeu/widgets/chat/linkified_message_text.dart';

void main() {
  test('detects valid http link', () {
    final segments = ChatLinkParser.parse('http://example.com');
    expect(segments.single.isLink, isTrue);
  });

  test('detects valid https link', () {
    final segments = ChatLinkParser.parse('https://example.com/path');
    expect(segments.single.uri.toString(), 'https://example.com/path');
  });

  test('keeps mixed text and link order', () {
    final segments = ChatLinkParser.parse('Visit https://example.com today');
    expect(segments.map((s) => s.text), ['Visit ', 'https://example.com', ' today']);
    expect(segments[1].isLink, isTrue);
  });

  test('ignores malformed link', () {
    final segments = ChatLinkParser.parse('broken http:// now');
    expect(segments.any((s) => s.isLink), isFalse);
  });

  test('blocks unsafe schemes', () {
    final segments = ChatLinkParser.parse('javascript:alert(1) file:///tmp/a intent://x');
    expect(segments.any((s) => s.isLink), isFalse);
  });

  test('long link remains one wrapping link segment', () {
    final url = 'https://example.com/${'very-long-path-' * 12}';
    final segments = ChatLinkParser.parse('Read $url');
    expect(segments.last.isLink, isTrue);
    expect(segments.last.text, url);
  });
}
