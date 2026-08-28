import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../../../core/models/complete_test_session.dart';
import '../../../scoring/domain/entities/iq_score.dart';
import '../../../../core/l10n/l10n_ext.dart';

/// Service de génération et d'impression du rapport PDF.
///
/// Utilise les packages `pdf` + `printing` pour générer un document
/// imprimable / téléchargeable directement dans le navigateur.
class PdfReportService {
  const PdfReportService();

  /// Génère et affiche/télécharge le PDF de résultats.
  Future<void> generateAndPrint({
    required CompleteTestSession session,
    required IQScore? iqScore,
    required int? ageInMonths,
  }) async {
    final doc = pw.Document();

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (pw.Context ctx) => [
          _buildHeader(),
          pw.SizedBox(height: 20),
          _buildSessionInfo(session, ageInMonths),
          pw.SizedBox(height: 20),
          if (iqScore != null) ...[
            _buildFSIQSection(iqScore),
            pw.SizedBox(height: 20),
            _buildIndexTable(iqScore),
            pw.SizedBox(height: 20),
            _buildSubtestTable(session),
          ],
          pw.SizedBox(height: 20),
          _buildDisclaimer(),
        ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (_) async => doc.save(),
      name: '${appL10n.pdfFilenameBase}_${_dateString()}.pdf',
    );
  }

  pw.Widget _buildHeader() {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('MENTAL E.T.',
                    style: pw.TextStyle(
                        fontSize: 28,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.indigo700)),
                pw.Text(appL10n.ctPdfSubtitle,
                    style: const pw.TextStyle(
                        fontSize: 12, color: PdfColors.grey700)),
              ],
            ),
            pw.Text(_dateString(),
                style:
                    const pw.TextStyle(fontSize: 11, color: PdfColors.grey600)),
          ],
        ),
        pw.Divider(color: PdfColors.indigo700, thickness: 2),
      ],
    );
  }

  pw.Widget _buildSessionInfo(
      CompleteTestSession session, int? ageInMonths) {
    final duration = session.totalDuration;
    final age = ageInMonths != null
        ? appL10n.ctAgeYears(ageInMonths ~/ 12)
        : appL10n.ctPdfNotProvided;
    final dur = duration != null
        ? appL10n.ctPdfDurationMinSec(
            duration.inMinutes, duration.inSeconds % 60)
        : appL10n.commonNotAvailable;

    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColors.indigo50,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Row(
        children: [
          _infoItem(appL10n.ctPdfAge, age),
          pw.SizedBox(width: 40),
          _infoItem(appL10n.ctPdfDuration, dur),
          pw.SizedBox(width: 40),
          _infoItem(appL10n.ctPdfDate, _dateString()),
        ],
      ),
    );
  }

  pw.Widget _infoItem(String label, String value) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(label,
            style: pw.TextStyle(
                fontSize: 9,
                color: PdfColors.grey600,
                fontWeight: pw.FontWeight.bold)),
        pw.Text(value,
            style: pw.TextStyle(
                fontSize: 12, fontWeight: pw.FontWeight.bold)),
      ],
    );
  }

  pw.Widget _buildFSIQSection(IQScore iqScore) {
    final ci = iqScore.fsiqCI;
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: PdfColors.indigo700,
        borderRadius: pw.BorderRadius.circular(12),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(appL10n.ctPdfFsiqLabel,
                  style: pw.TextStyle(
                      fontSize: 11,
                      color: PdfColors.white,
                      fontWeight: pw.FontWeight.bold)),
              pw.Text('${iqScore.fsiq}',
                  style: pw.TextStyle(
                      fontSize: 48,
                      color: PdfColors.white,
                      fontWeight: pw.FontWeight.bold)),
              pw.Text(iqScore.fsiqClassification,
                  style: pw.TextStyle(
                      fontSize: 14, color: PdfColors.white)),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(appL10n.ctPdfConfidenceInterval95,
                  style: pw.TextStyle(
                      fontSize: 9, color: PdfColors.white)),
              pw.Text('${ci.lowerBound} — ${ci.upperBound}',
                  style: pw.TextStyle(
                      fontSize: 13,
                      color: PdfColors.white,
                      fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 8),
              pw.Text(appL10n.ctPdfPercentile,
                  style: pw.TextStyle(
                      fontSize: 9, color: PdfColors.white)),
              pw.Text(appL10n.ctPercentileValue(iqScore.fsiqPercentile),
                  style: pw.TextStyle(
                      fontSize: 20,
                      color: PdfColors.white,
                      fontWeight: pw.FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _buildIndexTable(IQScore iqScore) {
    final rows = <(String, String, int?)>[
      ('VCI', appL10n.ctPdfIndexVci, iqScore.vci),
      ('VSI', appL10n.ctPdfIndexVsi, iqScore.vsi),
      ('FRI', appL10n.ctPdfIndexFri, iqScore.fri),
      ('WMI', appL10n.ctPdfIndexWmi, iqScore.wmi),
      ('PSI', appL10n.ctPdfIndexPsi, iqScore.psi),
    ];

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(appL10n.ctPdfIndexProfileHeader,
            style: pw.TextStyle(
                fontSize: 12,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.grey900)),
        pw.SizedBox(height: 8),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
          columnWidths: {
            0: const pw.FlexColumnWidth(5),
            1: const pw.FlexColumnWidth(2),
            2: const pw.FlexColumnWidth(3),
          },
          children: [
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.grey100),
              children: [
                _tableHeader(appL10n.ctPdfColIndex),
                _tableHeader(appL10n.ctPdfColScore),
                _tableHeader(appL10n.ctPdfColClassification),
              ],
            ),
            ...rows.map((r) {
              final score = r.$3;
              final key = r.$1;
              final classif = score != null
                  ? (iqScore.classifications[key] ?? '')
                  : appL10n.commonNotAvailable;
              return pw.TableRow(children: [
                _tableCell(r.$2),
                _tableCell(score != null ? '$score' : appL10n.commonNotAvailable, centered: true),
                _tableCell(classif),
              ]);
            }),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildSubtestTable(CompleteTestSession session) {
    final subtests = [
      ('${appL10n.ctTestCubes} (BD)', session.cubesScore),
      ('${appL10n.ctTestSimilarities} (SI)', session.similaritiesScore),
      ('${appL10n.ctTestDigitSpan} (DS)', session.digitSpanScore),
      ('${appL10n.ctTestMatrices} (MR)', session.matricesScore),
      ('${appL10n.ctTestVocabulary} (VO)', session.vocabularyScore),
      ('${appL10n.ctTestArithmetic} (AR)', session.arithmeticScore),
      ('${appL10n.ctTestSymbolSearch} (SS)', session.symbolSearchScore),
      ('${appL10n.ctTestVisualPuzzles} (VP)', session.visualPuzzlesScore),
      ('${appL10n.ctTestInformation} (IN)', session.informationScore),
      ('${appL10n.ctTestCoding} (CD)', session.codingScore),
      ('${appL10n.ctTestPictureSpan} (PS)', session.pictureSpanScore),
      ('${appL10n.ctTestFigureWeights} (FW)', session.figureWeightsScore),
    ];

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(appL10n.ctPdfRawScoresHeader,
            style: pw.TextStyle(
                fontSize: 12,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.grey900)),
        pw.SizedBox(height: 8),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
          columnWidths: {
            0: const pw.FlexColumnWidth(4),
            1: const pw.FlexColumnWidth(2),
          },
          children: [
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.grey100),
              children: [
                _tableHeader(appL10n.ctPdfColSubtest),
                _tableHeader(appL10n.ctPdfColRawScore),
              ],
            ),
            ...subtests.map((s) => pw.TableRow(children: [
                  _tableCell(s.$1),
                  _tableCell(
                    s.$2 != null ? '${s.$2}' : appL10n.commonNotAvailable,
                    centered: true,
                  ),
                ])),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildDisclaimer() {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColors.orange50,
        border: pw.Border.all(color: PdfColors.orange300),
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Text(
        appL10n.ctPdfDisclaimer,
        style: const pw.TextStyle(fontSize: 8, color: PdfColors.orange900),
      ),
    );
  }

  pw.Widget _tableHeader(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(text,
          style: pw.TextStyle(
              fontSize: 9,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.grey800)),
    );
  }

  pw.Widget _tableCell(String text, {bool centered = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(text,
          textAlign:
              centered ? pw.TextAlign.center : pw.TextAlign.left,
          style: const pw.TextStyle(fontSize: 9)),
    );
  }

  String _dateString() {
    final now = DateTime.now();
    return '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';
  }
}
