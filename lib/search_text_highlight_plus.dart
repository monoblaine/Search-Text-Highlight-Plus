library search_text_highlight_plus;

import 'package:flutter/material.dart';
import 'package:search_text_highlight_plus/data/highlight_span.dart';

/// A controller for managing and highlighting text within a [TextField] or [TextFormField].
class HighlightTextController extends TextEditingController {
  /// The scroll controller used to scroll to highlighted text.
  final ScrollController? scrollController;

  /// The background color of the currently selected highlighted text.
  final Color selectedTextBackgroundColor;

  /// The text style for normal (non-highlighted) text.
  final TextStyle? normalTextStyle;

  /// The text style for the currently selected highlighted text.
  final TextStyle? selectedHighlightedTextStyle;

  /// The text style for highlighted text.
  final TextStyle? highlightedTextStyle;

  /// The background color of highlighted text.
  final Color highlightTextBackgroundColor;

  /// Whether the search term matching is case sensitive.
  final bool caseSensitive;

  int _currentIndex = -1;

  /// A notifier for the list of highlight spans.
  final ValueNotifier<List<HighlightSpan>> _highlightsNotifier =
      ValueNotifier([]);

  ValueNotifier<List<HighlightSpan>> get highlightsNotifier =>
      _highlightsNotifier;

  /// Gets the current index of the highlighted text.
  int get currentIndex => _currentIndex;

  /// Gets the total number of highlights.
  int get totalHighlights => _highlightsNotifier.value.length;

  /// Creates a [HighlightTextController] with the given parameters.
  HighlightTextController({
    super.text,
    this.scrollController,
    this.selectedTextBackgroundColor = Colors.lightBlue,
    this.highlightTextBackgroundColor = Colors.yellow,
    this.selectedHighlightedTextStyle,
    this.highlightedTextStyle,
    this.normalTextStyle,
    this.caseSensitive = false,
  });

  /// Highlights the search term in the text.
  void highlightSearchTerm(String searchTerm) {
    if (searchTerm.isEmpty) {
      _clearHighlights();
      _currentIndex = -1;
      return;
    }

    setHighlights(searchTerm: searchTerm, currentIndex: _currentIndex);

    final lastIndex = _highlightsNotifier.value.length - 1;
    if (lastIndex < 0) {
      return;
    }
    if (_currentIndex == -1) {
      _highlightAtIndex(0);
    } else if (_currentIndex > lastIndex) {
      // Hopefully pick the nearest possible match
      _highlightAtIndex(lastIndex);
    }
  }

  /// Sets the highlights based on the search term.
  void setHighlights({required String searchTerm, required int currentIndex}) {
    List<HighlightSpan> newHighlights = [];
    String fullText = text;

    String pattern = RegExp.escape(searchTerm);
    List<RegExpMatch> matches = RegExp(pattern, caseSensitive: caseSensitive)
        .allMatches(fullText)
        .toList();

    for (int i = 0; i < matches.length; i++) {
      RegExpMatch match = matches[i];
      newHighlights.add(
        HighlightSpan(
          start: match.start,
          end: match.end,
          color: i == currentIndex
              ? selectedTextBackgroundColor
              : highlightTextBackgroundColor,
          textStyle: i == currentIndex
              ? selectedHighlightedTextStyle
              : highlightedTextStyle,
        ),
      );
    }

    _highlightsNotifier.value = newHighlights;
  }

  /// Updates the highlight color for the current index.
  void updateHighlightColor(int currentIndex) {
    List<HighlightSpan> updatedHighlights = [];
    for (int i = 0; i < _highlightsNotifier.value.length; i++) {
      updatedHighlights.add(
        HighlightSpan(
            start: _highlightsNotifier.value[i].start,
            end: _highlightsNotifier.value[i].end,
            color: i == currentIndex
                ? selectedTextBackgroundColor
                : highlightTextBackgroundColor,
            textStyle: i == currentIndex
                ? selectedHighlightedTextStyle
                : highlightedTextStyle),
      );
    }
    _highlightsNotifier.value = updatedHighlights;
  }

  /// Highlights the next occurrence of the search term.
  void highlightNext() => _maybeHighlightAtIndex(_currentIndex + 1);

  /// Highlights the previous occurrence of the search term.
  void highlightPrevious() => _maybeHighlightAtIndex(_currentIndex - 1);

  void _maybeHighlightAtIndex(int index) {
    final hasMatches = _highlightsNotifier.value.isNotEmpty;
    if (!hasMatches) {
      _currentIndex = -1;
      return;
    }
    _highlightAtIndex(index);
  }

  void _highlightAtIndex(int index) {
    final length = _highlightsNotifier.value.length;
    _currentIndex = (index + length) % length;
    updateHighlightColor(_currentIndex);
    // Scroll to the current highlight.
    if (scrollController == null) {
      return;
    }
    final spanStartIx = _highlightsNotifier.value[_currentIndex].start;
    scrollController!.animateTo(
      (spanStartIx / text.length) * scrollController!.position.maxScrollExtent,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  /// Clears all highlights.
  void _clearHighlights() {
    _highlightsNotifier.value = [];
  }

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    List<TextSpan> children = [];
    String fullText = value.text;
    List<HighlightSpan> highlights = _highlightsNotifier.value;

    if (highlights.isEmpty) {
      children.add(TextSpan(text: fullText));
    } else {
      int lastMatchEnd = 0;
      for (HighlightSpan highlight in highlights) {
        if (lastMatchEnd < highlight.start) {
          children.add(
            TextSpan(
              text: fullText.substring(
                lastMatchEnd,
                highlight.start,
              ),
              style: normalTextStyle,
            ),
          );
        }
        children.add(
          TextSpan(
            text: fullText.substring(highlight.start, highlight.end),
            style: highlight.textStyle
                    ?.copyWith(backgroundColor: highlight.color) ??
                TextStyle(backgroundColor: highlight.color),
          ),
        );
        lastMatchEnd = highlight.end;
      }
      if (lastMatchEnd < fullText.length) {
        children.add(
          TextSpan(
            text: fullText.substring(lastMatchEnd),
            style: normalTextStyle,
          ),
        );
      }
    }

    return TextSpan(style: style, children: children);
  }
}
