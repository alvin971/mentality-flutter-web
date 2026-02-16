import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../domain/balance_generator.dart';
import 'token_widget.dart';

/// Widget pour afficher une balance (équation)
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
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.grey.shade300, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Plateau du haut (représentation visuelle)
          _buildBalancePlate(),

          SizedBox(height: 12.h),

          // Équation mathématique
          _buildEquation(),
        ],
      ),
    );
  }

  Widget _buildBalancePlate() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Côté gauche
        Expanded(
          child: Container(
            height: 80.h,
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8.r),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Center(
              child: _buildTokenList(
                showQuestion && questionTokens != null
                    ? questionTokens!
                    : balance.leftSide,
              ),
            ),
          ),
        ),

        // Pivot central
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 8.w),
          child: Icon(
            Icons.balance,
            size: 32.sp,
            color: Colors.grey.shade700,
          ),
        ),

        // Côté droit
        Expanded(
          child: Container(
            height: 80.h,
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(8.r),
              border: Border.all(color: Colors.green.shade200),
            ),
            child: Center(
              child: balance.rightSide.isEmpty && showQuestion
                  ? Text(
                      '?',
                      style: TextStyle(
                        fontSize: 36.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade600,
                      ),
                    )
                  : _buildTokenList(balance.rightSide),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEquation() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Côté gauche
        _buildTokenList(
          showQuestion && questionTokens != null
              ? questionTokens!
              : balance.leftSide,
          small: true,
        ),

        // Signe égal
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 8.w),
          child: Text(
            '=',
            style: TextStyle(
              fontSize: 24.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),

        // Côté droit
        if (balance.rightSide.isEmpty && showQuestion)
          Text(
            '?',
            style: TextStyle(
              fontSize: 24.sp,
              fontWeight: FontWeight.bold,
              color: Colors.orange,
            ),
          )
        else
          _buildTokenList(balance.rightSide, small: true),
      ],
    );
  }

  Widget _buildTokenList(List<Token> tokens, {bool small = false}) {
    if (tokens.isEmpty) {
      return const SizedBox.shrink();
    }

    return Flexible(
      child: Wrap(
        spacing: small ? 4.w : 8.w,
        runSpacing: small ? 4.h : 8.h,
        alignment: WrapAlignment.center,
        children: tokens.map((token) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              TokenWidget(
                token: token,
                size: small ? 24 : 32,
              ),
              if (tokens.indexOf(token) < tokens.length - 1)
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4.w),
                  child: Text(
                    '+',
                    style: TextStyle(
                      fontSize: small ? 16.sp : 20.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          );
        }).toList(),
      ),
    );
  }
}
