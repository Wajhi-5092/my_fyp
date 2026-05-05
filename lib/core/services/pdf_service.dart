import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/pdf.dart' as pw;
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';

class PdfService {
  static Future<Uint8List> generateLecturePdfBytes({
    required String title,
    String? courseCode,
    String? instructor,
    required String transcript,
    required String date,
  }) async {
    final pdf = pw.Document();
    final cleanCourseCode = (courseCode ?? "").trim();
    final cleanInstructor = (instructor ?? "").trim();
    final cleanTitle = title.replaceAll('*', '').trim();

    // Fonts
    pw.Font font;
    pw.Font fontBold;

    try {
      font = await PdfGoogleFonts.poppinsRegular().timeout(
        const Duration(seconds: 3),
      );
      fontBold = await PdfGoogleFonts.poppinsBold().timeout(
        const Duration(seconds: 3),
      );
    } catch (e) {
      debugPrint("Font loading failed, using fallback: $e");
      font = pw.Font.helvetica();
      fontBold = pw.Font.helveticaBold();
    }

    // Process transcript to handle headings, bullets, and paragraphs
    final List<pw.Widget> transcriptWidgets = [];
    final transcriptLines = transcript.split('\n');

    for (var line in transcriptLines) {
      String trimmedLine = line.trim();
      if (trimmedLine.isEmpty) continue;

      // 1. Handle Bullet Points
      if (trimmedLine.startsWith('- ') ||
          trimmedLine.startsWith('• ') ||
          (trimmedLine.startsWith('* ') && !trimmedLine.endsWith('*'))) {
        final content = trimmedLine.substring(2).trim().replaceAll('**', '');
        transcriptWidgets.add(
          pw.Padding(
            padding: const pw.EdgeInsets.only(left: 10, bottom: 6),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Padding(
                  padding: const pw.EdgeInsets.only(top: 4, right: 8),
                  child: pw.Container(
                    width: 4,
                    height: 4,
                    decoration: const pw.BoxDecoration(
                      color: PdfColors.blue700,
                      shape: pw.BoxShape.circle,
                    ),
                  ),
                ),
                pw.Expanded(
                  child: pw.Text(
                    content,
                    style: pw.TextStyle(
                      font: font,
                      fontSize: 11.5,
                      lineSpacing: 3,
                    ),
                    textAlign: pw.TextAlign.justify,
                  ),
                ),
              ],
            ),
          ),
        );
        continue;
      }

      // 2. Handle Headings
      int headingLevel = 0;
      if (trimmedLine.startsWith('###')) {
        headingLevel = 3;
      } else if (trimmedLine.startsWith('##')) {
        headingLevel = 2;
      } else if (trimmedLine.startsWith('#')) {
        headingLevel = 1;
      }

      bool looksLikeHeading =
          headingLevel > 0 ||
          (trimmedLine.length < 60 &&
              trimmedLine.toUpperCase() == trimmedLine &&
              trimmedLine.length > 4);

      if (looksLikeHeading) {
        final headingText = trimmedLine
            .replaceAll('#', '')
            .trim()
            .replaceAll('**', '');
        double fontSize = 15;
        pw.PdfColor color = PdfColors.blue800;
        double topPadding = 18;

        if (headingLevel == 2) {
          fontSize = 13.5;
          color = PdfColors.blue700;
          topPadding = 14;
        } else if (headingLevel == 3) {
          fontSize = 12;
          color = PdfColors.grey800;
          topPadding = 12;
        }

        transcriptWidgets.add(
          pw.Padding(
            padding: pw.EdgeInsets.only(top: topPadding, bottom: 8),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  headingText,
                  style: pw.TextStyle(
                    font: fontBold,
                    fontSize: fontSize,
                    color: color,
                  ),
                ),
                if (headingLevel <= 1) ...[
                  pw.SizedBox(height: 2),
                  pw.Container(
                    height: 1.5,
                    width: 35,
                    color: PdfColors.blue300,
                  ),
                ],
              ],
            ),
          ),
        );
      } else {
        // 3. Handle Regular Paragraphs with Bold support
        transcriptWidgets.add(_buildRichParagraph(trimmedLine, font, fontBold));
      }
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        footer: (pw.Context context) {
          return pw.Container(
            alignment: pw.Alignment.centerRight,
            margin: const pw.EdgeInsets.only(top: 20),
            child: pw.Text(
              'Page ${context.pageNumber} of ${context.pagesCount} • VoiceNoteX',
              style: pw.TextStyle(
                font: font,
                fontSize: 9,
                color: PdfColors.grey500,
              ),
            ),
          );
        },
        build: (pw.Context context) {
          return [
            /// ================= HEADER =================
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        cleanTitle,
                        style: pw.TextStyle(
                          font: fontBold,
                          fontSize: 24,
                          color: PdfColors.blue900,
                        ),
                      ),
                      pw.SizedBox(height: 8),
                      pw.Text(
                        date,
                        style: pw.TextStyle(
                          font: font,
                          fontSize: 10,
                          color: PdfColors.grey700,
                        ),
                      ),
                      if (cleanCourseCode.isNotEmpty ||
                          cleanInstructor.isNotEmpty) ...[
                        pw.SizedBox(height: 6),
                        pw.Row(
                          children: [
                            if (cleanCourseCode.isNotEmpty)
                              pw.Text(
                                "Course: $cleanCourseCode",
                                style: pw.TextStyle(
                                  font: fontBold,
                                  fontSize: 10,
                                  color: PdfColors.grey800,
                                ),
                              ),
                            if (cleanCourseCode.isNotEmpty &&
                                cleanInstructor.isNotEmpty)
                              pw.Text(
                                "  |  ",
                                style: pw.TextStyle(
                                  font: font,
                                  fontSize: 10,
                                  color: PdfColors.grey400,
                                ),
                              ),
                            if (cleanInstructor.isNotEmpty)
                              pw.Text(
                                "Instructor: $cleanInstructor",
                                style: pw.TextStyle(
                                  font: fontBold,
                                  fontSize: 10,
                                  color: PdfColors.grey800,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                pw.SizedBox(width: 20),
                pw.PdfLogo(),
              ],
            ),

            pw.SizedBox(height: 12),
            pw.Divider(thickness: 1.5, color: PdfColors.blue800),
            pw.SizedBox(height: 16),

            /// ================= TRANSCRIPT SECTION TITLE =================
            pw.Text(
              "LECTURE TRANSCRIPT",
              style: pw.TextStyle(
                font: fontBold,
                fontSize: 12,
                color: PdfColors.grey600,
                letterSpacing: 1.2,
              ),
            ),
            pw.SizedBox(height: 10),

            /// ================= TRANSCRIPT CONTENT =================
            ...transcriptWidgets,

            /// ================= FOOTER CONTENT (Only on last page) =================
            pw.SizedBox(height: 20),
            pw.Divider(color: PdfColors.grey300),
            pw.SizedBox(height: 8),
            pw.Center(
              child: pw.Text(
                "AI Generated Lecture Notes • End of Document",
                style: pw.TextStyle(
                  font: font,
                  fontSize: 8,
                  color: PdfColors.grey400,
                ),
              ),
            ),
          ];
        },
      ),
    );

    return pdf.save();
  }

  static Future<String> savePdfBytesToDownloads(
    Uint8List pdfBytes, {
    String fileName = "lecture_notes.pdf",
  }) async {
    final safeFileName = fileName.endsWith(".pdf") ? fileName : "$fileName.pdf";

    if (kIsWeb || Platform.isAndroid) {
      await Printing.sharePdf(bytes: pdfBytes, filename: safeFileName);
      return "Shared via system sheet: $safeFileName";
    }

    final tempDir = await getTemporaryDirectory();
    final tempFile = File("${tempDir.path}/$safeFileName");
    await tempFile.writeAsBytes(pdfBytes);

    final docDir = await getApplicationDocumentsDirectory();
    final finalFile = File("${docDir.path}/$safeFileName");

    final savedFile = await tempFile.copy(finalFile.path);
    return savedFile.path;
  }

  static pw.Widget _buildRichParagraph(
    String text,
    pw.Font font,
    pw.Font fontBold,
  ) {
    final List<pw.InlineSpan> spans = [];
    final RegExp regex = RegExp(r'\*\*(.*?)\*\*');
    int lastMatchEnd = 0;

    for (final Match match in regex.allMatches(text)) {
      if (match.start > lastMatchEnd) {
        spans.add(
          pw.TextSpan(
            text: text.substring(lastMatchEnd, match.start),
            style: pw.TextStyle(
              font: font,
              fontSize: 11.5,
              color: PdfColors.black,
            ),
          ),
        );
      }
      spans.add(
        pw.TextSpan(
          text: match.group(1),
          style: pw.TextStyle(
            font: fontBold,
            fontSize: 11.5,
            color: PdfColors.black,
          ),
        ),
      );
      lastMatchEnd = match.end;
    }

    if (lastMatchEnd < text.length) {
      spans.add(
        pw.TextSpan(
          text: text.substring(lastMatchEnd),
          style: pw.TextStyle(
            font: font,
            fontSize: 11.5,
            color: PdfColors.black,
          ),
        ),
      );
    }

    // If no bold tags were found, return a simple paragraph
    if (!regex.hasMatch(text)) {
      return pw.Paragraph(
        text: text,
        style: pw.TextStyle(
          font: font,
          fontSize: 11.5,
          lineSpacing: 3,
          color: PdfColors.black,
        ),
        textAlign: pw.TextAlign.justify,
        margin: const pw.EdgeInsets.only(bottom: 10),
      );
    }

    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 10),
      child: pw.RichText(
        text: pw.TextSpan(children: spans, style: pw.TextStyle(lineSpacing: 3)),
        textAlign: pw.TextAlign.justify,
      ),
    );
  }
}
