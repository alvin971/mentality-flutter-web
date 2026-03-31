import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/models/complete_test_session.dart';
import '../../../../services/session_history_service.dart';
import '../../../scoring/domain/entities/iq_score.dart';
import '../../../scoring/domain/services/scoring_service.dart';
import '../../domain/services/pdf_report_service.dart';

/// Page de résultats du test complet WAIS-IV
class CompleteTestResultsPage extends StatefulWidget {
  final CompleteTestSession session;
  final int? ageInMonths;

  const CompleteTestResultsPage({
    super.key,
    required this.session,
    this.ageInMonths,
  });

  @override
  State<CompleteTestResultsPage> createState() =>
      _CompleteTestResultsPageState();
}

class _CompleteTestResultsPageState extends State<CompleteTestResultsPage> {
  late final IQScore? _iqScore;

  @override
  void initState() {
    super.initState();
    // Try-catch : un score manquant ou hors-table ne doit pas faire crasher
    // silencieusement la page (qui resterait grise en production).
    try {
      _iqScore = widget.ageInMonths != null
          ? const ScoringService().computeScore(widget.session, widget.ageInMonths!)
          : null;
    } catch (_) {
      _iqScore = null;
    }
    _saveToHistory();
  }

  Future<void> _saveToHistory() async {
    if (_iqScore == null) return;
    final entry = SessionHistoryEntry(
      id: const Uuid().v4(),
      date: widget.session.startTime,
      ageInMonths: widget.ageInMonths!,
      fsiq: _iqScore!.fsiq,
      vci: _iqScore!.vci,
      vsi: _iqScore!.vsi,
      fri: _iqScore!.fri,
      wmi: _iqScore!.wmi,
      psi: _iqScore!.psi,
      classification: _iqScore!.fsiqClassification,
    );
    await SessionHistoryService.instance.saveEntry(entry);
  }

  CompleteTestSession get session => widget.session;
  int? get ageInMonths => widget.ageInMonths;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Résultats',
          style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w600),
        ),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(24.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              SizedBox(height: 24.h),
              _buildSessionInfo(),
              SizedBox(height: 24.h),

              if (_iqScore != null) ...[
                _buildFSIQCard(context, _iqScore),
                SizedBox(height: 24.h),
                _buildIndexProfile(_iqScore),
                SizedBox(height: 24.h),
                _buildSubtestDetails(_iqScore),
                SizedBox(height: 24.h),
                _buildStrengthsWeaknesses(_iqScore),
              ] else ...[
                _buildRawScoresFallback(),
                SizedBox(height: 16.h),
                _buildNoScoreNotice(),
              ],

              SizedBox(height: 32.h),
              _buildActions(context),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // EN-TÊTE
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'PROFIL COGNITIF',
          style: TextStyle(
            fontSize: 11.sp,
            fontWeight: FontWeight.w500,
            letterSpacing: 1.8,
            color: AppColors.textTertiary,
          ),
        ),
        SizedBox(height: 8.h),
        RichText(
          text: TextSpan(
            style: TextStyle(
              fontSize: 24.sp,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              height: 1.2,
            ),
            children: const [
              TextSpan(text: 'Une carte complète de votre\n'),
              TextSpan(
                text: 'intelligence.',
                style: TextStyle(
                  color: AppColors.secondary,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 6.h),
        Text(
          'Bien au-delà d\'un simple score QI.',
          style: TextStyle(fontSize: 14.sp, color: AppColors.textSecondary),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // INFORMATIONS DE SESSION
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildSessionInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Informations de la Session'),
        _buildInfoRow('Date', _formatDate(session.startTime)),
        _buildInfoRow('Durée totale', _formatDuration(session.totalDuration)),
        _buildInfoRow(
            'Tests complétés', '${session.completedTestsCount} / ${session.totalTests}'),
        if (ageInMonths != null)
          _buildInfoRow('Âge du patient', '${(ageInMonths! / 12).floor()} ans'),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // CARTE QI TOTAL
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildFSIQCard(BuildContext context, IQScore iq) {
    final percentile = iq.percentiles['FSIQ'] ?? 50;
    final classification = iq.classifications['FSIQ'] ?? '';
    // Position du score sur l'axe 40-160
    final progress = ((iq.fsiq - 40) / 120).clamp(0.0, 1.0);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        color: const Color(0xFF0B1F17),
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'QI estimé global',
            style: TextStyle(
              fontSize: 13.sp,
              color: Colors.white60,
              fontWeight: FontWeight.w400,
            ),
          ),
          SizedBox(height: 8.h),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '${iq.fsiq}',
                style: TextStyle(
                  fontSize: 56.sp,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  height: 1,
                ),
              ),
              SizedBox(width: 12.w),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    classification,
                    style: TextStyle(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w600,
                      color: AppColors.secondary,
                    ),
                  ),
                  Text(
                    '${percentile}e percentile',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: Colors.white54,
                    ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 20.h),
          // Barre gradient rouge → vert avec indicateur
          Stack(
            clipBehavior: Clip.none,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(4.r),
                child: Container(
                  height: 6.h,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Color(0xFFDC2626),
                        Color(0xFFF59E0B),
                        Color(0xFF10B981),
                        Color(0xFF3B82F6),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                left: (progress * 1).clamp(0.0, 1.0) *
                    (MediaQuery.sizeOf(context).width - 48.w - 12.w),
                top: -5.h,
                child: Container(
                  width: 16.w,
                  height: 16.w,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: const Color(0xFF10B981), width: 2),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 10.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('40', style: TextStyle(fontSize: 11.sp, color: Colors.white38)),
              Text('100', style: TextStyle(fontSize: 11.sp, color: Colors.white38)),
              Text('160', style: TextStyle(fontSize: 11.sp, color: Colors.white38)),
            ],
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // PROFIL DES INDICES (barres)
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildIndexProfile(IQScore iq) {
    final indices = [
      ('ICV', 'Compréhension verbale', iq.vci, AppColors.secondary),
      ('IRP', 'Raisonnement perceptif', iq.vsi, AppColors.secondary),
      ('IMT', 'Mémoire de travail', iq.wmi, AppColors.secondary),
      ('IVT', 'Vitesse de traitement', iq.psi, AppColors.secondary),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: indices.map((entry) {
        final code = entry.$1;
        final label = entry.$2;
        final score = entry.$3;
        final color = entry.$4;
        if (score == null) return const SizedBox.shrink();

        final percentile = iq.percentiles[code] ?? 50;
        final barWidth = ((score - 40) / 120).clamp(0.0, 1.0);

        return Container(
          margin: EdgeInsets.only(bottom: 12.h),
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(14.r),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(6.r),
                      border: Border.all(
                          color: AppColors.primary.withOpacity(0.4)),
                    ),
                    child: Text(
                      code,
                      style: TextStyle(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w700,
                        color: AppColors.secondary,
                      ),
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  Text(
                    '$score',
                    style: TextStyle(
                      fontSize: 20.sp,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 10.h),
              ClipRRect(
                borderRadius: BorderRadius.circular(4.r),
                child: LinearProgressIndicator(
                  value: barWidth,
                  backgroundColor: AppColors.grey200,
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                  minHeight: 4.h,
                ),
              ),
              SizedBox(height: 6.h),
              Text(
                '${percentile}e percentile',
                style:
                    TextStyle(fontSize: 12.sp, color: AppColors.textTertiary),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // NOTES STANDARDISÉES PAR SOUS-TEST
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildSubtestDetails(IQScore iq) {
    final groups = [
      (
        'Compréhension Verbale',
        AppColors.indexVCI,
        [
          ('Similitudes', 'SI', session.similaritiesScore),
          ('Vocabulaire', 'VO', session.vocabularyScore),
          ('Information', 'IN', session.informationScore),
        ]
      ),
      (
        'Visuo-Spatial',
        AppColors.indexVSI,
        [
          ('Cubes', 'BD', session.cubesScore),
          ('Puzzles Visuels', 'VP', session.visualPuzzlesScore),
        ]
      ),
      (
        'Raisonnement Fluide',
        AppColors.indexFRI,
        [
          ('Matrices', 'MR', session.matricesScore),
          ('Balances', 'FW', session.figureWeightsScore),
        ]
      ),
      (
        'Mémoire de Travail',
        AppColors.indexWMI,
        [
          ('Mémoire des Chiffres', 'DS', session.digitSpanScore),
          ('Arithmétique', 'AR', session.arithmeticScore),
          ('Mémoire des Images', 'PM', session.pictureSpanScore),
        ]
      ),
      (
        'Vitesse de Traitement',
        AppColors.indexPSI,
        [
          ('Code', 'CD', session.codingScore),
          ('Recherche de Symboles', 'SS', session.symbolSearchScore),
        ]
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Notes Standardisées par Sous-test'),
        ...groups.map((group) {
          final title = group.$1;
          final color = group.$2;
          final subtests = group.$3;

          return Container(
            margin: EdgeInsets.only(bottom: 12.h),
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: color.withOpacity(0.3), width: 2),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                SizedBox(height: 10.h),
                ...subtests.map((s) {
                  final name = s.$1;
                  final code = s.$2;
                  final rawScore = s.$3;
                  if (rawScore == null) return const SizedBox.shrink();

                  final scaledScore = iq.percentiles[code]; // note standardisée
                  final classif = iq.classifications[code] ?? '';

                  return Padding(
                    padding: EdgeInsets.symmetric(vertical: 5.h),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: Text(
                            name,
                            style: TextStyle(
                              fontSize: 14.sp,
                              color: AppColors.grey700,
                            ),
                          ),
                        ),
                        Text(
                          'Brut : $rawScore',
                          style: TextStyle(
                            fontSize: 13.sp,
                            color: AppColors.grey500,
                          ),
                        ),
                        SizedBox(width: 16.w),
                        Container(
                          width: 36.w,
                          height: 36.w,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            '${scaledScore ?? '-'}',
                            style: TextStyle(
                              fontSize: 15.sp,
                              fontWeight: FontWeight.bold,
                              color: color,
                            ),
                          ),
                        ),
                        SizedBox(width: 10.w),
                        Expanded(
                          flex: 2,
                          child: Text(
                            classif,
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: AppColors.grey500,
                            ),
                            textAlign: TextAlign.right,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          );
        }),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // FORCES ET FAIBLESSES
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildStrengthsWeaknesses(IQScore iq) {
    final strengths = iq.strengths;
    final weaknesses = iq.weaknesses;
    final isHomogeneous = iq.isHomogeneousProfile;

    final indexLabels = {
      'VCI': 'Compréhension Verbale',
      'VSI': 'Visuo-Spatial',
      'FRI': 'Raisonnement Fluide',
      'WMI': 'Mémoire de Travail',
      'PSI': 'Vitesse de Traitement',
    };

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.grey200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Profil Cognitif',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: AppColors.grey900,
            ),
          ),
          SizedBox(height: 12.h),
          Text(
            isHomogeneous
                ? 'Profil homogène — les indices sont cohérents entre eux (écart max : ${iq.maxIndexDiscrepancy} pts)'
                : 'Profil hétérogène — disparités notables entre indices (écart max : ${iq.maxIndexDiscrepancy} pts)',
            style: TextStyle(fontSize: 14.sp, color: AppColors.grey600),
          ),
          if (strengths.isNotEmpty) ...[
            SizedBox(height: 16.h),
            _buildProfileTag(
              label: 'Forces relatives',
              items: strengths.map((c) => indexLabels[c] ?? c).toList(),
              color: AppColors.success,
              icon: Icons.trending_up,
            ),
          ],
          if (weaknesses.isNotEmpty) ...[
            SizedBox(height: 12.h),
            _buildProfileTag(
              label: 'Points de vigilance',
              items: weaknesses.map((c) => indexLabels[c] ?? c).toList(),
              color: AppColors.warning,
              icon: Icons.trending_down,
            ),
          ],
          SizedBox(height: 16.h),
          Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: AppColors.warning.withOpacity(0.08),
              borderRadius: BorderRadius.circular(8.r),
              border: Border.all(color: AppColors.warning.withOpacity(0.3)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, color: AppColors.warning, size: 20.sp),
                SizedBox(width: 10.w),
                Expanded(
                  child: Text(
                    'Ces résultats sont indicatifs. Pour une évaluation clinique officielle, consultez un neuropsychologue ou psychologue qualifié.',
                    style: TextStyle(fontSize: 13.sp, color: AppColors.grey600),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileTag({
    required String label,
    required List<String> items,
    required Color color,
    required IconData icon,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 18.sp),
        SizedBox(width: 8.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              SizedBox(height: 4.h),
              Wrap(
                spacing: 8.w,
                children: items
                    .map(
                      (item) => Chip(
                        label: Text(item, style: TextStyle(fontSize: 13.sp)),
                        backgroundColor: color.withOpacity(0.12),
                        labelStyle: TextStyle(color: color),
                        visualDensity: VisualDensity.compact,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    )
                    .toList(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // FALLBACK : SCORES BRUTS (si pas d'âge renseigné)
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildRawScoresFallback() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Indice de Compréhension Verbale'),
        _buildScoreCard(
          color: AppColors.indexVCI,
          tests: [
            ('Similitudes', session.similaritiesScore),
            ('Vocabulaire', session.vocabularyScore),
            ('Information', session.informationScore),
          ],
          totalScore: session.icvRawScore,
        ),
        SizedBox(height: 16.h),
        _buildSectionTitle('Indice Visuo-Spatial / Raisonnement Perceptif'),
        _buildScoreCard(
          color: AppColors.indexFRI,
          tests: [
            ('Cubes', session.cubesScore),
            ('Matrices', session.matricesScore),
            ('Puzzles Visuels', session.visualPuzzlesScore),
          ],
          totalScore: session.irpRawScore,
        ),
        SizedBox(height: 16.h),
        _buildSectionTitle('Indice de Mémoire de Travail'),
        _buildScoreCard(
          color: AppColors.indexWMI,
          tests: [
            ('Mémoire des Chiffres', session.digitSpanScore),
            ('Arithmétique', session.arithmeticScore),
          ],
          totalScore: session.imtRawScore,
        ),
        SizedBox(height: 16.h),
        _buildSectionTitle('Indice de Vitesse de Traitement'),
        _buildScoreCard(
          color: AppColors.indexPSI,
          tests: [
            ('Code', session.codingScore),
            ('Recherche de Symboles', session.symbolSearchScore),
          ],
          totalScore: session.ivtRawScore,
        ),
        if (session.pictureSpanScore != null || session.figureWeightsScore != null) ...[
          SizedBox(height: 16.h),
          _buildSectionTitle('Tests Supplémentaires'),
          if (session.pictureSpanScore != null)
            _buildScoreRow('Mémoire des Images', session.pictureSpanScore!),
          if (session.figureWeightsScore != null)
            _buildScoreRow('Balances', session.figureWeightsScore!),
        ],
      ],
    );
  }

  Widget _buildNoScoreNotice() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.warning.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.warning.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: AppColors.warning, size: 24.sp),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              'L\'âge n\'a pas été renseigné. Seuls les scores bruts sont affichés. '
              'Pour obtenir le QI standardisé avec percentiles et intervalles de confiance, '
              'relancez le test en renseignant l\'âge du patient.',
              style: TextStyle(fontSize: 14.sp, color: AppColors.grey600),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // BOUTONS D'ACTION
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildActions(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 56.h,
          child: ElevatedButton.icon(
            onPressed: () async {
              try {
                await const PdfReportService().generateAndPrint(
                  session: session,
                  iqScore: _iqScore,
                  ageInMonths: ageInMonths,
                );
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Erreur PDF : $e')),
                  );
                }
              }
            },
            icon: Icon(Icons.picture_as_pdf, size: 24.sp),
            label: Text('Exporter en PDF', style: TextStyle(fontSize: 18.sp)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
            ),
          ),
        ),
        SizedBox(height: 16.h),
        SizedBox(
          width: double.infinity,
          height: 56.h,
          child: OutlinedButton.icon(
            onPressed: () => Navigator.popUntil(context, (route) => route.isFirst),
            icon: Icon(Icons.home, size: 24.sp),
            label: Text('Retour à l\'Accueil', style: TextStyle(fontSize: 18.sp)),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: AppColors.primary),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // WIDGETS UTILITAIRES
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 20.sp,
          fontWeight: FontWeight.bold,
          color: AppColors.grey900,
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 16.sp, color: AppColors.grey600)),
          Text(
            value,
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: AppColors.grey900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreCard({
    required Color color,
    required List<(String, int?)> tests,
    required int? totalScore,
  }) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: color.withOpacity(0.3), width: 2),
      ),
      child: Column(
        children: [
          ...tests.map((test) => _buildScoreRow(test.$1, test.$2)),
          Divider(height: 24.h, color: color.withOpacity(0.3)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Score Brut Total',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Text(
                  totalScore?.toString() ?? 'N/A',
                  style: TextStyle(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildScoreRow(String testName, int? score) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(testName, style: TextStyle(fontSize: 16.sp, color: AppColors.grey600)),
          Text(
            score?.toString() ?? 'N/A',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: AppColors.grey900,
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // HELPERS
  // ─────────────────────────────────────────────────────────────────────────

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} '
        'à ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  String _formatDuration(Duration? duration) {
    if (duration == null) return 'N/A';
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    if (hours > 0) return '${hours}h ${minutes}min ${seconds}s';
    if (minutes > 0) return '${minutes}min ${seconds}s';
    return '${seconds}s';
  }

  String _ordinal(int n) {
    if (n == 1) return 'er';
    return 'e';
  }
}
