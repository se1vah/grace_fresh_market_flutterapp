// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/api_service.dart';
import '../../theme/app_theme.dart';

/// Reusable CMS Modal Popup Dialog for Terms of Service, Privacy Policy, etc.
class CmsPopupDialog extends StatefulWidget {
  final int cmsId;
  final String title;

  const CmsPopupDialog({super.key, required this.cmsId, required this.title});

  /// Helper static method to open the CMS popup dialog cleanly
  static Future<void> show(
    BuildContext context, {
    required int cmsId,
    required String title,
  }) {
    return showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: Colors.black.withOpacity(0.6),
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (context, animation, secondaryAnimation) {
        return CmsPopupDialog(cmsId: cmsId, title: title);
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutBack,
        );
        return ScaleTransition(
          scale: Tween<double>(begin: 0.85, end: 1.0).animate(curvedAnimation),
          child: FadeTransition(opacity: animation, child: child),
        );
      },
    );
  }

  @override
  State<CmsPopupDialog> createState() => _CmsPopupDialogState();
}

class _CmsPopupDialogState extends State<CmsPopupDialog> {
  final ApiService _apiService = ApiService();

  bool _isLoading = true;
  String? _errorMessage;
  String? _content;
  String? _displayTitle;
  // ignore: unused_field
  String? _updatedAt;

  @override
  void initState() {
    super.initState();
    _fetchCmsContent();
  }

  Future<void> _fetchCmsContent() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final res = await _apiService.getCmsContent(widget.cmsId);
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _content = res['content'];
        _displayTitle = res['title'] ?? widget.title;
        _updatedAt = res['updatedAt'];
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Unable to load content.\nPlease try again later.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final maxModalHeight = screenSize.height * 0.80;

    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: screenSize.width < 600 ? screenSize.width * 0.92 : 560,
          constraints: BoxConstraints(
            maxHeight: maxModalHeight,
            minHeight: 280,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Modal Header with Title & Close 'X' button
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                decoration: const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Color(0xFFEEEEEE), width: 1.0),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _displayTitle ?? widget.title,
                        style: GoogleFonts.outfit(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.darkGreen,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.black87),
                      onPressed: () => Navigator.of(context).pop(),
                      tooltip: 'Close',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),

              // Modal Scrollable Body Content
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20.0),
                  child: _buildBody(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return SizedBox(
        height: 200,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(
                strokeWidth: 2.5,
                color: AppTheme.darkGreen,
              ),
              const SizedBox(height: 16),
              Text(
                'Loading...',
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_errorMessage != null) {
      return SizedBox(
        height: 220,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                color: AppTheme.deleteRed,
                size: 40,
              ),
              const SizedBox(height: 12),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  color: AppTheme.textDark,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _fetchCmsContent,
                icon: const Icon(Icons.refresh, size: 18),
                label: Text(
                  'Try Again',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.darkGreen,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [_CmsContentRenderer(htmlOrText: _content ?? '')],
    );
  }
}

/// Lightweight, safe HTML & Formatted Text Renderer for CMS content
class _CmsContentRenderer extends StatelessWidget {
  final String htmlOrText;

  const _CmsContentRenderer({required this.htmlOrText});

  @override
  Widget build(BuildContext context) {
    if (htmlOrText.trim().isEmpty) {
      return Text(
        'No content available.',
        style: GoogleFonts.outfit(color: Colors.grey.shade600, fontSize: 14),
      );
    }

    // Clean html string or plain text blocks
    final blocks = _parseBlocks(htmlOrText);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: blocks.map((block) => _buildBlockWidget(block)).toList(),
    );
  }

  List<_CmsBlock> _parseBlocks(String input) {
    final List<_CmsBlock> blocks = [];
    String text = input;

    // Normalize break lines
    text = text.replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n');

    // Split into paragraphs / tags
    final tagRegex = RegExp(
      r'<(h[1-6]|p|ul|ol|li|table|blockquote)[^>]*>(.*?)</\1>',
      caseSensitive: false,
      dotAll: true,
    );

    final matches = tagRegex.allMatches(text);

    if (matches.isEmpty) {
      // Plain text or markdown line splitting fallback
      final lines = text.split(RegExp(r'\n\s*\n'));
      for (final line in lines) {
        final trimmed = line.trim();
        if (trimmed.isEmpty) continue;

        if (RegExp(r'^\d+\.\s+').hasMatch(trimmed) || trimmed.startsWith('#')) {
          blocks.add(_CmsBlock(type: 'heading', content: trimmed));
        } else if (trimmed.startsWith('- ') || trimmed.startsWith('* ')) {
          blocks.add(_CmsBlock(type: 'ul', content: trimmed));
        } else {
          blocks.add(_CmsBlock(type: 'p', content: trimmed));
        }
      }
      return blocks;
    }

    int lastEnd = 0;
    for (final match in matches) {
      if (match.start > lastEnd) {
        final preText = text.substring(lastEnd, match.start).trim();
        if (preText.isNotEmpty) {
          blocks.add(_CmsBlock(type: 'p', content: preText));
        }
      }

      final tagName = match.group(1)!.toLowerCase();
      final innerContent = match.group(2)!.trim();

      if (tagName.startsWith('h')) {
        blocks.add(_CmsBlock(type: 'heading', content: innerContent));
      } else if (tagName == 'ul' || tagName == 'ol') {
        blocks.add(_CmsBlock(type: tagName, content: innerContent));
      } else if (tagName == 'table') {
        blocks.add(_CmsBlock(type: 'table', content: innerContent));
      } else {
        blocks.add(_CmsBlock(type: 'p', content: innerContent));
      }

      lastEnd = match.end;
    }

    if (lastEnd < text.length) {
      final postText = text.substring(lastEnd).trim();
      if (postText.isNotEmpty) {
        blocks.add(_CmsBlock(type: 'p', content: postText));
      }
    }

    return blocks;
  }

  Widget _buildBlockWidget(_CmsBlock block) {
    switch (block.type) {
      case 'heading':
        final clean = _stripTags(block.content);
        return Padding(
          padding: const EdgeInsets.only(top: 14.0, bottom: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                clean,
                style: GoogleFonts.outfit(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.darkGreen,
                ),
              ),
              const SizedBox(height: 4),
              const Divider(color: Color(0xFFEEEEEE), height: 1),
            ],
          ),
        );

      case 'ul':
      case 'ol':
        final liRegex = RegExp(
          r'<li[^>]*>(.*?)</li>',
          caseSensitive: false,
          dotAll: true,
        );
        final matches = liRegex.allMatches(block.content);
        final items = matches.isNotEmpty
            ? matches.map((m) => _stripTags(m.group(1)!)).toList()
            : block.content
                  .split('\n')
                  .map(
                    (e) => e.replaceAll(RegExp(r'^[\-\*•\d\.]+\s*'), '').trim(),
                  )
                  .where((e) => e.isNotEmpty)
                  .toList();

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: items.map((item) {
              return Padding(
                padding: const EdgeInsets.only(left: 8.0, bottom: 6.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '• ',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.darkGreen,
                        fontSize: 16,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        item,
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          color: AppTheme.textDark,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        );

      case 'table':
        return _buildTableWidget(block.content);

      case 'p':
      default:
        final formattedText = _stripTags(block.content);
        if (formattedText.isEmpty) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: Text(
            formattedText,
            style: GoogleFonts.outfit(
              fontSize: 14,
              color: AppTheme.textDark,
              height: 1.5,
            ),
          ),
        );
    }
  }

  Widget _buildTableWidget(String htmlTable) {
    final trRegex = RegExp(
      r'<tr[^>]*>(.*?)</tr>',
      caseSensitive: false,
      dotAll: true,
    );
    final trMatches = trRegex.allMatches(htmlTable);
    if (trMatches.isEmpty) return const SizedBox.shrink();

    final List<List<String>> rows = [];
    for (final tr in trMatches) {
      final cellRegex = RegExp(
        r'<(td|th)[^>]*>(.*?)</\1>',
        caseSensitive: false,
        dotAll: true,
      );
      final cells = cellRegex
          .allMatches(tr.group(1)!)
          .map((c) => _stripTags(c.group(2)!))
          .toList();
      if (cells.isNotEmpty) {
        rows.add(cells);
      }
    }

    if (rows.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Table(
        border: TableBorder.all(color: Colors.grey.shade300, width: 1),
        children: rows.asMap().entries.map((entry) {
          final isHeader = entry.key == 0;
          return TableRow(
            decoration: BoxDecoration(
              color: isHeader ? const Color(0xFFF4F6F3) : Colors.white,
            ),
            children: entry.value.map((cell) {
              return Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  cell,
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: isHeader ? FontWeight.bold : FontWeight.normal,
                    color: isHeader ? AppTheme.darkGreen : AppTheme.textDark,
                  ),
                ),
              );
            }).toList(),
          );
        }).toList(),
      ),
    );
  }

  String _stripTags(String input) {
    var str = input;
    str = str.replaceAll(RegExp(r'<[^>]*>'), '');
    str = str
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'");
    return str.trim();
  }
}

class _CmsBlock {
  final String type;
  final String content;

  _CmsBlock({required this.type, required this.content});
}
