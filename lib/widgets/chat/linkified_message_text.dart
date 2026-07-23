import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

class ChatTextSegment {
  const ChatTextSegment.text(this.text) : uri = null;
  const ChatTextSegment.link(this.text, this.uri);

  final String text;
  final Uri? uri;

  bool get isLink => uri != null;
}

class ChatLinkParser {
  static final RegExp _urlPattern = RegExp(
    r'https?://[^\s<>()]+',
    caseSensitive: false,
  );

  static List<ChatTextSegment> parse(String text) {
    final segments = <ChatTextSegment>[];
    var index = 0;

    for (final match in _urlPattern.allMatches(text)) {
      if (match.start > index) {
        segments.add(ChatTextSegment.text(text.substring(index, match.start)));
      }

      var raw = match.group(0)!;
      var trailing = '';
      while (raw.isNotEmpty && '.,!?;:)]}'.contains(raw[raw.length - 1])) {
        trailing = raw[raw.length - 1] + trailing;
        raw = raw.substring(0, raw.length - 1);
      }

      final uri = _safeUri(raw);
      if (uri == null) {
        segments.add(ChatTextSegment.text(match.group(0)!));
      } else {
        segments.add(ChatTextSegment.link(raw, uri));
        if (trailing.isNotEmpty) {
          segments.add(ChatTextSegment.text(trailing));
        }
      }
      index = match.end;
    }

    if (index < text.length) {
      segments.add(ChatTextSegment.text(text.substring(index)));
    }

    return segments.isEmpty
        ? <ChatTextSegment>[ChatTextSegment.text(text)]
        : segments;
  }

  static Uri? _safeUri(String raw) {
    final uri = Uri.tryParse(raw);
    if (uri == null || uri.host.trim().isEmpty) return null;
    final scheme = uri.scheme.toLowerCase();
    if (scheme != 'http' && scheme != 'https') return null;
    return uri;
  }
}

class LinkifiedMessageText extends StatelessWidget {
  const LinkifiedMessageText({
    super.key,
    required this.text,
    this.baseStyle,
    this.isMe = false,
  });

  final String text;
  final TextStyle? baseStyle;
  final bool isMe;

  Future<void> _open(BuildContext context, Uri uri) async {
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open this link.')),
      );
    }
  }

  Future<void> _copy(BuildContext context, Uri uri) async {
    await Clipboard.setData(ClipboardData(text: uri.toString()));
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Link copied')));
  }

  @override
  Widget build(BuildContext context) {
    final normalStyle =
        baseStyle ??
        const TextStyle(color: Colors.white, fontSize: 15.5, height: 1.4);
    final linkStyle = normalStyle.copyWith(
      color: isMe ? const Color(0xFFE7D4FF) : const Color(0xFF8B5CF6),
      decoration: TextDecoration.underline,
      decorationColor: isMe ? const Color(0xFFE7D4FF) : const Color(0xFF8B5CF6),
      fontWeight: FontWeight.w700,
    );
    final segments = ChatLinkParser.parse(text);

    return Text.rich(
      TextSpan(
        children: segments.map((segment) {
          if (!segment.isLink) {
            return TextSpan(text: segment.text, style: normalStyle);
          }

          final uri = segment.uri!;
          final recognizer = TapGestureRecognizer()
            ..onTap = () {
              _open(context, uri);
            }
            ..onSecondaryTap = () {
              _copy(context, uri);
            };

          return TextSpan(
            text: segment.text,
            style: linkStyle,
            recognizer: recognizer,
          );
        }).toList(),
      ),
    );
  }
}
