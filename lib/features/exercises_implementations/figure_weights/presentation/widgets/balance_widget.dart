import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../domain/balance_generator.dart';
import 'token_widget.dart';
import '../../../../../core/theme/kepler_colors.dart';

/// Widget pour afficher une balance (équation visuelle + équation textuelle).
///
/// Layout : 2 plateaux colorés + pivot central, puis l'équation mathématique
/// en dessous. Le widget est theme-aware (light/dark).
class BalanceWidget extends StatelessWidget {
  final Balance balance;
  final bool showQuestion;
  final List<Token>? questionTokens;

  const BalanceWidget({
    super.key,
    required this.balance,
    this.showQuestion = false,
    this.questionTokens,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: EdgeInsets.all(10.w),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: cs.outlineVariant, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildBalancePlate(context),
          SizedBox(height: 8.h),
          _buildEquation(context),
        ],
      ),
    );
  }

  Widget _buildBalancePlate(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final leftTokens = showQuestion && questionTokens != null
        ? questionTokens!
        : balance.leftSide;
    final rightTokens = balance.rightSide;
    final rightAsQuestion = balance.rightSide.isEmpty && showQuestion;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: _plate(
            context,
            tone: AppColors.indexFRI,
            tokens: leftTokens,
            showQuestionMark: false,
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 8.w),
          child: Icon(
            Icons.balance,
            size: 32.sp,
            color: cs.onSurfaceVariant,
          ),
        ),
        Expanded(
          child: _plate(
            context,
            tone: AppColors.indexWMI,
            tokens: rightTokens,
            showQuestionMark: rightAsQuestion,
          ),
        ),
      ],
    );
  }

  Widget _plate(
    BuildContext context, {
    required Color tone,
    required List<Token> tokens,
    required bool showQuestionMark,
  }) {
    return Container(
      constraints: BoxConstraints(minHeight: 80.h),
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: tone.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: tone.withValues(alpha: 0.4)),
      ),
      child: Center(
        child: showQuestionMark
            ? Text(
                '?',
                style: TextStyle(
                  fontSize: 36.sp,
                  fontWeight: FontWeight.bold,
                  color: KeplerColors.of(context).warning,
                ),
              )
            : _buildTokenList(context, tokens),
      ),
    );
  }

  Widget _buildEquation(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Flexible(
          child: _buildTokenList(
            context,
            showQuestion && questionTokens != null
                ? questionTokens!
                : balance.leftSide,
            small: true,
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 8.w),
          child: Text(
            '=',
            style: TextStyle(
              fontSize: 24.sp,
              fontWeight: FontWeight.bold,
              color: cs.onSurface,
            ),
          ),
        ),
        if (balance.rightSide.isEmpty && showQuestion)
          Text(
            '?',
            style: TextStyle(
              fontSize: 24.sp,
              fontWeight: FontWeight.bold,
              color: KeplerColors.of(context).warning,
            ),
          )
        else
          Flexible(
            child: _buildTokenList(context, balance.rightSide, small: true),
          ),
      ],
    );
  }

  /// Liste de tokens séparés par des `+`. Retourne un `Wrap` brut (sans
  /// `Flexible`) — c'est au call site de wrapper en `Flexible` si placé dans
  /// une `Row`/`Column`.
  Widget _buildTokenList(BuildContext context, List<Token> tokens,
      {bool small = false}) {
    if (tokens.isEmpty) return const SizedBox.shrink();
    final cs = Theme.of(context).colorScheme;
    return Wrap(
      spacing: small ? 4.w : 8.w,
      runSpacing: small ? 4.h : 8.h,
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        for (var i = 0; i < tokens.length; i++) ...[
          TokenWidget(token: tokens[i], size: small ? 24 : 32),
          if (i < tokens.length - 1)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 4.w),
              child: Text(
                '+',
                style: TextStyle(
                  fontSize: small ? 16.sp : 20.sp,
                  fontWeight: FontWeight.bold,
                  color: cs.onSurface,
                ),
              ),
            ),
        ],
      ],
    );
  }
}
