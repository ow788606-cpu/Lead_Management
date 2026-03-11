import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';

class HtmlRenderer extends StatelessWidget {
  final String htmlContent;

  const HtmlRenderer({
    super.key,
    required this.htmlContent,
  });

  @override
  Widget build(BuildContext context) {
    return Html(
      data: htmlContent,
      style: {
        "body": Style(
          margin: Margins.zero,
          padding: HtmlPaddings.zero,
          fontSize: FontSize(14),
          fontFamily: 'Inter',
          color: Colors.black87,
        ),
        "h1": Style(
          fontSize: FontSize(24),
          fontWeight: FontWeight.bold,
          fontFamily: 'Inter',
          margin: Margins.zero,
        ),
        "h2": Style(
          fontSize: FontSize(20),
          fontWeight: FontWeight.bold,
          fontFamily: 'Inter',
          margin: Margins.zero,
        ),
        "h3": Style(
          fontSize: FontSize(18),
          fontWeight: FontWeight.w600,
          fontFamily: 'Inter',
          margin: Margins.zero,
        ),
        "strong": Style(
          fontWeight: FontWeight.bold,
        ),
        "em": Style(
          fontStyle: FontStyle.italic,
        ),
        "u": Style(
          textDecoration: TextDecoration.underline,
        ),
        "ul": Style(
          margin: Margins(left: Margin(16)),
          padding: HtmlPaddings.zero,
        ),
        "ol": Style(
          margin: Margins(left: Margin(16)),
          padding: HtmlPaddings.zero,
        ),
        "li": Style(
          fontSize: FontSize(14),
          fontFamily: 'Inter',
        ),
      },
    );
  }
}
