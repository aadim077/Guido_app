import 'package:flutter/material.dart';

class ContentRenderer extends StatelessWidget {
  final String content;

  const ContentRenderer({super.key, required this.content});

  @override
  Widget build(BuildContext context) {
    final blocks = _parseBlocks(content);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: blocks.map((block) {
        if (block.isCode) {
          return _CodeBlock(code: block.text);
        }
        return _TextBlock(text: block.text);
      }).toList(),
    );
  }

  List<_ContentBlock> _parseBlocks(String raw) {
    final result = <_ContentBlock>[];
    final parts = raw.split('```');
    for (var i = 0; i < parts.length; i++) {
      final part = parts[i].trim();
      if (part.isEmpty) continue;
      if (i % 2 == 1) {
        final lines = part.split('\n');
        final lang = lines.first.trim().toLowerCase();
        final isLangTag = lang == 'python' || lang == 'py' || lang == 'bash' || lang == 'text';
        final code = isLangTag ? lines.skip(1).join('\n') : part;
        result.add(_ContentBlock(text: code, isCode: true));
      } else {
        result.add(_ContentBlock(text: part, isCode: false));
      }
    }
    return result;
  }
}

class _ContentBlock {
  final String text;
  final bool isCode;

  const _ContentBlock({required this.text, required this.isCode});
}

class _TextBlock extends StatelessWidget {
  final String text;

  const _TextBlock({required this.text});

  @override
  Widget build(BuildContext context) {
    final lines = text.split('\n');
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: lines.map((line) {
          final trimmed = line.trim();
          if (trimmed.isEmpty) return const SizedBox(height: 6);
          if (trimmed.startsWith('# ')) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                trimmed.substring(2),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
            );
          }
          if (trimmed.startsWith('## ')) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                trimmed.substring(3),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            );
          }
          if (trimmed.startsWith('- ') || trimmed.startsWith('* ')) {
            return Padding(
              padding: const EdgeInsets.only(left: 8, bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('• ', style: TextStyle(fontSize: 14, color: Color(0xFF2563EB))),
                  Expanded(
                    child: Text(
                      trimmed.substring(2),
                      style: const TextStyle(fontSize: 14, height: 1.6, color: Color(0xFF374151)),
                    ),
                  ),
                ],
              ),
            );
          }
          return Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              trimmed,
              style: const TextStyle(fontSize: 14, height: 1.6, color: Color(0xFF374151)),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _CodeBlock extends StatelessWidget {
  final String code;

  const _CodeBlock({required this.code});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF313244), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFF313244))),
            ),
            child: Row(
              children: [
                Container(
                    width: 10, height: 10, decoration: BoxDecoration(color: const Color(0xFFFF5F57), shape: BoxShape.circle)),
                const SizedBox(width: 6),
                Container(
                    width: 10, height: 10, decoration: BoxDecoration(color: const Color(0xFFFFBD2E), shape: BoxShape.circle)),
                const SizedBox(width: 6),
                Container(
                    width: 10, height: 10, decoration: BoxDecoration(color: const Color(0xFF28C840), shape: BoxShape.circle)),
                const SizedBox(width: 10),
                const Text('python',
                    style: TextStyle(color: Color(0xFF6C6F85), fontSize: 11, fontFamily: 'monospace')),
              ],
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.all(14),
            child: Text(
              code,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 13,
                color: Color(0xFFCDD6F4),
                height: 1.6,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
