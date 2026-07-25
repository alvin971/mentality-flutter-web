import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'dart:math' as math;
import '../../../../../core/l10n/l10n_ext.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/kepler_colors.dart';

/// Widget d'exercice des Cubes (Block Design)
///
/// Mesure la capacité d'analyse visuospatiale à travers la reconstruction
/// de patterns avec des cubes bicolores (rouge/blanc)
class CubesExerciseWidget extends StatefulWidget {
  final int gridSize; // 2 pour 2x2, 3 pour 3x3
  final List<List<CubeFace>> targetPattern;
  final Function(bool isCorrect, int timeSeconds) onComplete;
  final int? timeLimitSeconds;

  const CubesExerciseWidget({
    super.key,
    required this.gridSize,
    required this.targetPattern,
    required this.onComplete,
    this.timeLimitSeconds,
  });

  @override
  State<CubesExerciseWidget> createState() => _CubesExerciseWidgetState();
}

class _CubesExerciseWidgetState extends State<CubesExerciseWidget> {
  late List<List<CubeFace>> userGrid;
  late DateTime startTime;
  int elapsedSeconds = 0;
  bool isCompleted = false;

  @override
  void initState() {
    super.initState();
    startTime = DateTime.now();
    _initializeUserGrid();
    _startTimer();
  }

  void _initializeUserGrid() {
    userGrid = List.generate(
      widget.gridSize,
      (_) => List.generate(
        widget.gridSize,
        (_) => CubeFace.whiteSolid,
      ),
    );
  }

  void _startTimer() {
    Future.delayed(const Duration(seconds: 1), () {
      if (!isCompleted && mounted) {
        setState(() {
          elapsedSeconds = DateTime.now().difference(startTime).inSeconds;
        });

        // Vérifier la limite de temps
        if (widget.timeLimitSeconds != null && elapsedSeconds >= widget.timeLimitSeconds!) {
          _submitAnswer();
        } else {
          _startTimer();
        }
      }
    });
  }

  void _toggleCube(int row, int col) {
    if (isCompleted) return;

    setState(() {
      // Cycle à travers les 6 types de faces (2 solid + 4 diagonales)
      final currentFace = userGrid[row][col];
      switch (currentFace) {
        case CubeFace.whiteSolid:
          userGrid[row][col] = CubeFace.redSolid;
          break;
        case CubeFace.redSolid:
          userGrid[row][col] = CubeFace.diagonalRedWhite_0;
          break;
        case CubeFace.diagonalRedWhite_0:
        case CubeFace.diagonalRedWhite:
          userGrid[row][col] = CubeFace.diagonalRedWhite_90;
          break;
        case CubeFace.diagonalRedWhite_90:
          userGrid[row][col] = CubeFace.diagonalRedWhite_180;
          break;
        case CubeFace.diagonalRedWhite_180:
        case CubeFace.diagonalWhiteRed:
          userGrid[row][col] = CubeFace.diagonalRedWhite_270;
          break;
        case CubeFace.diagonalRedWhite_270:
          userGrid[row][col] = CubeFace.whiteSolid;
          break;
      }
    });
  }

  bool _checkAnswer() {
    for (int i = 0; i < widget.gridSize; i++) {
      for (int j = 0; j < widget.gridSize; j++) {
        if (userGrid[i][j] != widget.targetPattern[i][j]) {
          return false;
        }
      }
    }
    return true;
  }

  void _submitAnswer() {
    if (isCompleted) return;

    setState(() {
      isCompleted = true;
    });

    final isCorrect = _checkAnswer();
    final finalTime = DateTime.now().difference(startTime).inSeconds;

    widget.onComplete(isCorrect, finalTime);
  }

  void _resetGrid() {
    setState(() {
      _initializeUserGrid();
      isCompleted = false;
      startTime = DateTime.now();
      elapsedSeconds = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final remainingTime = widget.timeLimitSeconds != null
        ? widget.timeLimitSeconds! - elapsedSeconds
        : null;

    return Column(
      children: [
        // Timer et instructions
        _buildHeader(context, remainingTime),
        SizedBox(height: 12.h),

        // Pattern cible — partage la hauteur restante avec la grille
        // utilisateur ; chaque grille est réduite si l'écran est petit.
        Expanded(child: _buildTargetPattern(context)),
        SizedBox(height: 12.h),

        // Grille utilisateur
        Expanded(child: _buildUserGrid(context)),
        SizedBox(height: 12.h),

        // Boutons d'action — toujours visibles en bas
        _buildActionButtons(context),
      ],
    );
  }

  Widget _buildHeader(BuildContext context, int? remainingTime) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: KeplerColors.of(context).primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.timer_outlined,
                    color: KeplerColors.of(context).primary,
                    size: 20.sp,
                  ),
                  SizedBox(width: 6.w),
                  Text(
                    _formatTime(elapsedSeconds),
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                      color: KeplerColors.of(context).primary,
                    ),
                  ),
                ],
              ),
              if (remainingTime != null) ...[
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: remainingTime < 10
                        ? AppColors.error.withValues(alpha: 0.2)
                        : AppColors.success.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Text(
                    context.l10n.cubesRemaining(_formatTime(remainingTime)),
                    style: TextStyle(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w600,
                      color: remainingTime < 10 ? AppColors.error : AppColors.success,
                    ),
                  ),
                ),
              ],
            ],
          ),
          SizedBox(height: 6.h),
          Text(
            context.l10n.cubesReproduceInstruction,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12.sp,
              color: AppColors.grey700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTargetPattern(BuildContext context) {
    return _buildGridSection(
      label: context.l10n.cubesPatternToReproduce,
      grid: widget.targetPattern,
      isTarget: true,
    );
  }

  Widget _buildUserGrid(BuildContext context) {
    return _buildGridSection(
      label: context.l10n.cubesYourAnswer,
      grid: userGrid,
      isTarget: false,
    );
  }

  /// Section label + grille : la grille est réduite (FittedBox) pour tenir
  /// dans la hauteur allouée — aucun scroll nécessaire, quel que soit l'écran.
  Widget _buildGridSection({
    required String label,
    required List<List<CubeFace>> grid,
    required bool isTarget,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
            color: AppColors.grey900,
          ),
        ),
        SizedBox(height: 6.h),
        Expanded(
          child: Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: _buildGrid(grid, isTarget: isTarget),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGrid(List<List<CubeFace>> grid, {required bool isTarget}) {
    final cubeSize = widget.gridSize == 2 ? 80.0 : 60.0;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4.r),
        border: Border.all(color: AppColors.grey800, width: 3),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(4, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(2.r),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(widget.gridSize, (row) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(widget.gridSize, (col) {
                return GestureDetector(
                  onTap: isTarget || isCompleted
                      ? null
                      : () => _toggleCube(row, col),
                  child: SizedBox(
                    width: cubeSize.w,
                    height: cubeSize.w,
                    child: _buildCubeFace(grid[row][col]),
                  ),
                );
              }),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildCubeFace(CubeFace face) {
    return CustomPaint(
      painter: CubeFacePainter(face),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: isCompleted ? null : _resetGrid,
            icon: const Icon(Icons.refresh),
            label: Text(context.l10n.cubesReset),
            style: OutlinedButton.styleFrom(
              padding: EdgeInsets.symmetric(vertical: 16.h),
              side: BorderSide(color: AppColors.grey400),
            ),
          ),
        ),
        SizedBox(width: 16.w),
        Expanded(
          flex: 2,
          child: ElevatedButton.icon(
            onPressed: isCompleted ? null : _submitAnswer,
            icon: const Icon(Icons.check),
            label: Text(context.l10n.commonValidate),
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(vertical: 16.h),
            ),
          ),
        ),
      ],
    );
  }

  String _formatTime(int seconds) {
    final mins = seconds ~/ 60;
    final secs = seconds % 60;
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }
}

/// Types de faces de cubes avec 4 rotations pour les diagonales
enum CubeFace {
  whiteSolid, // Blanc uni
  redSolid, // Rouge uni

  // Diagonales rouge/blanc (4 orientations - rotation de 90°)
  diagonalRedWhite_0,   // Rouge: haut-gauche | Blanc: bas-droite (↘)
  diagonalRedWhite_90,  // Rouge: haut-droite | Blanc: bas-gauche (↙)
  diagonalRedWhite_180, // Rouge: bas-droite | Blanc: haut-gauche (↖)
  diagonalRedWhite_270, // Rouge: bas-gauche | Blanc: haut-droite (↗)

  // Alias pour compatibilité
  diagonalRedWhite,   // = diagonalRedWhite_0
  diagonalWhiteRed,   // = diagonalRedWhite_180
}

/// Painter pour dessiner les faces de cubes
class CubeFacePainter extends CustomPainter {
  final CubeFace face;

  CubeFacePainter(this.face);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    switch (face) {
      case CubeFace.whiteSolid:
        paint.color = Colors.white;
        canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
        break;

      case CubeFace.redSolid:
        paint.color = Colors.red;
        canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
        break;

      // Rotation 0° : Rouge haut-gauche → bas-droite blanc (↘)
      case CubeFace.diagonalRedWhite_0:
      case CubeFace.diagonalRedWhite:
        _drawDiagonal0(canvas, size, paint);
        break;

      // Rotation 90° : Rouge haut-droite → bas-gauche blanc (↙)
      case CubeFace.diagonalRedWhite_90:
        _drawDiagonal90(canvas, size, paint);
        break;

      // Rotation 180° : Blanc haut-gauche → bas-droite rouge (↖)
      case CubeFace.diagonalRedWhite_180:
      case CubeFace.diagonalWhiteRed:
        _drawDiagonal180(canvas, size, paint);
        break;

      // Rotation 270° : Blanc haut-droite → bas-gauche rouge (↗)
      case CubeFace.diagonalRedWhite_270:
        _drawDiagonal270(canvas, size, paint);
        break;
    }
  }

  /// Diagonale 0° : Rouge haut-gauche (↘)
  void _drawDiagonal0(Canvas canvas, Size size, Paint paint) {
    // Triangle rouge en haut-gauche
    final redPath = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(0, size.height)
      ..close();
    paint.color = Colors.red;
    canvas.drawPath(redPath, paint);

    // Triangle blanc en bas-droite
    final whitePath = Path()
      ..moveTo(size.width, 0)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    paint.color = Colors.white;
    canvas.drawPath(whitePath, paint);
  }

  /// Diagonale 90° : Rouge haut-droite (↙)
  void _drawDiagonal90(Canvas canvas, Size size, Paint paint) {
    // Triangle rouge en haut-droite
    final redPath = Path()
      ..moveTo(size.width, 0)
      ..lineTo(size.width, size.height)
      ..lineTo(0, 0)
      ..close();
    paint.color = Colors.red;
    canvas.drawPath(redPath, paint);

    // Triangle blanc en bas-gauche
    final whitePath = Path()
      ..moveTo(0, 0)
      ..lineTo(0, size.height)
      ..lineTo(size.width, size.height)
      ..close();
    paint.color = Colors.white;
    canvas.drawPath(whitePath, paint);
  }

  /// Diagonale 180° : Blanc haut-gauche (↖)
  void _drawDiagonal180(Canvas canvas, Size size, Paint paint) {
    // Triangle blanc en haut-gauche
    final whitePath = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(0, size.height)
      ..close();
    paint.color = Colors.white;
    canvas.drawPath(whitePath, paint);

    // Triangle rouge en bas-droite
    final redPath = Path()
      ..moveTo(size.width, 0)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    paint.color = Colors.red;
    canvas.drawPath(redPath, paint);
  }

  /// Diagonale 270° : Blanc haut-droite (↗)
  void _drawDiagonal270(Canvas canvas, Size size, Paint paint) {
    // Triangle blanc en haut-droite
    final whitePath = Path()
      ..moveTo(size.width, 0)
      ..lineTo(size.width, size.height)
      ..lineTo(0, 0)
      ..close();
    paint.color = Colors.white;
    canvas.drawPath(whitePath, paint);

    // Triangle rouge en bas-gauche
    final redPath = Path()
      ..moveTo(0, 0)
      ..lineTo(0, size.height)
      ..lineTo(size.width, size.height)
      ..close();
    paint.color = Colors.red;
    canvas.drawPath(redPath, paint);
  }

  @override
  bool shouldRepaint(CubeFacePainter oldDelegate) => oldDelegate.face != face;
}
