import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/models/complete_test_session.dart';

/// Page de résultats du test complet WAIS-IV
class CompleteTestResultsPage extends StatelessWidget {
  final CompleteTestSession session;

  const CompleteTestResultsPage({Key? key, required this.session}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Résultats du Test Complet',
          style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.primary,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(24.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // En-tête avec félicitations
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(24.w),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.success, AppColors.success.withOpacity(0.7)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16.r),
                ),
                child: Column(
                  children: [
                    Icon(Icons.emoji_events, size: 64.sp, color: Colors.white),
                    SizedBox(height: 16.h),
                    Text(
                      'Test Complet Terminé !',
                      style: TextStyle(
                        fontSize: 28.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      'Félicitations pour avoir complété tous les subtests',
                      style: TextStyle(fontSize: 16.sp, color: Colors.white.withOpacity(0.9)),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              SizedBox(height: 24.h),

              // Informations de session
              _buildSectionTitle('Informations de la Session'),
              _buildInfoRow('Date', _formatDate(session.startTime)),
              _buildInfoRow('Durée totale', _formatDuration(session.totalDuration)),
              _buildInfoRow('Tests complétés', '${session.completedTestsCount} / ${session.totalTests}'),

              SizedBox(height: 24.h),

              // Scores par indice
              _buildSectionTitle('Indice de Compréhension Verbale (ICV)'),
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

              _buildSectionTitle('Indice de Raisonnement Perceptif (IRP)'),
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

              _buildSectionTitle('Indice de Mémoire de Travail (IMT)'),
              _buildScoreCard(
                color: AppColors.indexWMI,
                tests: [
                  ('Mémoire des Chiffres', session.digitSpanScore),
                  ('Arithmétique', session.arithmeticScore),
                ],
                totalScore: session.imtRawScore,
              ),

              SizedBox(height: 16.h),

              _buildSectionTitle('Indice de Vitesse de Traitement (IVT)'),
              _buildScoreCard(
                color: AppColors.indexPSI,
                tests: [
                  ('Code', session.codingScore),
                  ('Recherche de Symboles', session.symbolSearchScore),
                ],
                totalScore: session.ivtRawScore,
              ),

              SizedBox(height: 24.h),

              // Tests supplémentaires
              if (session.pictureSpanScore != null || session.figureWeightsScore != null) ...[
                _buildSectionTitle('Tests Supplémentaires'),
                if (session.pictureSpanScore != null)
                  _buildScoreRow('Mémoire des Images', session.pictureSpanScore!),
                if (session.figureWeightsScore != null)
                  _buildScoreRow('Balances', session.figureWeightsScore!),
                SizedBox(height: 24.h),
              ],

              // Score total et QI estimé
              if (session.estimatedIQ != null) ...[
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(24.w),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.primary, AppColors.primary.withOpacity(0.7)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16.r),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'QI Total Estimé',
                        style: TextStyle(
                          fontSize: 20.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 16.h),
                      Text(
                        '${session.estimatedIQ}',
                        style: TextStyle(
                          fontSize: 72.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        _getIQInterpretation(session.estimatedIQ!),
                        style: TextStyle(
                          fontSize: 16.sp,
                          color: Colors.white.withOpacity(0.9),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 16.h),
                Container(
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
                          'Note: Ce score est une estimation simplifiée. Pour une évaluation clinique précise, consultez un psychologue qualifié.',
                          style: TextStyle(fontSize: 14.sp, color: AppColors.grey600),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              SizedBox(height: 32.h),

              // Boutons d'action
              SizedBox(
                width: double.infinity,
                height: 56.h,
                child: ElevatedButton.icon(
                  onPressed: () {
                    // TODO: Implémenter l'exportation PDF
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Fonctionnalité d\'exportation à venir')),
                    );
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
                  onPressed: () {
                    Navigator.popUntil(context, (route) => route.isFirst);
                  },
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
          ),
        ),
      ),
    );
  }

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
          Text(
            label,
            style: TextStyle(fontSize: 16.sp, color: AppColors.grey600),
          ),
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
          // Scores individuels
          ...tests.map((test) => _buildScoreRow(test.$1, test.$2)),
          Divider(height: 24.h, color: color.withOpacity(0.3)),
          // Score total
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Score Total',
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
          Text(
            testName,
            style: TextStyle(fontSize: 16.sp, color: AppColors.grey600),
          ),
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

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} à ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  String _formatDuration(Duration? duration) {
    if (duration == null) return 'N/A';
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours}h ${minutes}min ${seconds}s';
    } else if (minutes > 0) {
      return '${minutes}min ${seconds}s';
    } else {
      return '${seconds}s';
    }
  }

  String _getIQInterpretation(int iq) {
    if (iq >= 130) return 'Très supérieur';
    if (iq >= 120) return 'Supérieur';
    if (iq >= 110) return 'Moyen supérieur';
    if (iq >= 90) return 'Moyen';
    if (iq >= 80) return 'Moyen inférieur';
    if (iq >= 70) return 'Limite';
    return 'Très faible';
  }
}
