import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

class ChatTextSegment {
  final String text;
  final Uri? uri;

  const ChatTextSegment.text(this.text) : uri = null;
  const ChatTextSegment.link(this.text, this.uri);

  bool get isLink => uri != null;
}

class ChatLinkParser {
  static final RegExp _urlPattern = RegExp(r'https?://[^\s<>()]+', caseSensitive: false);

  static List<ChatTextSegment> parse(String text) {
    final segments = <ChatTextSegment>[];
    var index = 0;

    for (final match in _urlPattern.allMatches(text)) {
      if (match.start > index) {
        segments.add(ChatTextSegment.text(text.substring(index, match.start)));
      }

      var raw = match.group(0)!;
      var trailing = '';
      while (raw.isNotEmpty && '.,!?;:)'.contains(raw[raw.length - 1])) {
        trailing = raw[raw.length - 1] + trailing;
        raw = raw.substring(0, raw.length - 1);
      }

      final uri = _safeUri(raw);
      if (uri == null) {
        segments.add(ChatTextSegment.text(match.group(0)!));
      } else {
        segments.add(ChatTextSegment.link(raw, uri));
        if (trailing.isNotEmpty) segments.add(ChatTextSegment.text(trailing));
      }
      index = match.end;
    }

    if (index < text.length) {
      segments.add(ChatTextSegment.text(text.substring(index)));
    }

    return segments.isEmpty ? [ChatTextSegment.text(text)] : segments;
  }

  static Uri? _safeUri(String raw) {
    final uri = Uri.tryParse(raw);
    if (uri == null || !uri.hasScheme || uri.host.trim().isEmpty) return null;
    final scheme = uri.scheme.toLowerCase();
    if (scheme != 'http' && scheme != 'https') return null;
    return uri;
  }
}

class LinkifiedMessageText extends StatelessWidget {
  final String text;
  final bool isMe;
  final Future<bool> Function(Uri uri)? launchUrlOverride;

  const LinkifiedMessageText({
    super.key,
    required this.text,
    required this.isMe,
    this.launchUrlOverride,
  });

  Future<void> _open(Uri uri) async {
    if (launchUrlOverride != null) {
      await launchUrlOverride!(uri);
      return;
    }
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _copy(BuildContext context, Uri uri) async {
    await Clipboard.setData(ClipboardData(text: uri.toString()));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Link copied')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final baseStyle = const TextStyle(color: Colors.white, fontSize: 15.5, height: 1.4);
    final linkStyle = baseStyle.copyWith(
      color: isMe ? const Color(0xFFE7D4FF) : Colors.purpleAccent,
      decoration: TextDecoration.underline,
      decorationColor: isMe ? const Color(0xFFE7D4FF) : Colors.purpleAccent,
      fontWeight: FontWeight.w700,
    );

    return SelectableText.rich(
      TextSpan(
        children: ChatLinkParser.parse(text).map((segment) {
          if (!segment.isLink) return TextSpan(text: segment.text, style: baseStyle);
          final uri = segment.uri!;
          return TextSpan(
            text: segment.text,
            style: linkStyle,
            recognizer: TapGestureRecognizer()..onTap = () => _open(uri),
          );
        }).toList(),
      ),
      onTap: () {},
      contextMenuBuilder: (context, editableTextState) {
        final link = ChatLinkParser.parse(text).where((s) => s.isLink).firstOrNull;
        if (link == null) return AdaptiveTextSelectionToolbar.buttonItems(anchors: editableTextState.contextMenuAnchors, buttonItems: editableTextState.contextMenuButtonItems);
        return AdaptiveTextSelectionToolbar.buttonItems(
          anchors: editableTextState.contextMenuAnchors,
          buttonItems: [
            ContextMenuButtonItem(label: 'Copy link', onPressed: () => _copy(context, link.uri!)),
            ...editableTextState.contextMenuButtonItems,
          ],
        );
      },
    );
  }
}
