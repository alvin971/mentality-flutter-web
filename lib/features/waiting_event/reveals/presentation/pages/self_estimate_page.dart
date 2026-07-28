// L'auto-estimation du QI — la toute première chose du jour 1.
//
// Elle passe AVANT la révélation verbale, et ce n'est pas une question de mise
// en scène : une estimation donnée après avoir vu un premier indice n'est plus
// une croyance, c'est un calcul à partir du chiffre qu'on vient de lire. Le
// hub garantit cet ordre ; cet écran garantit qu'on ne repose jamais la
// question (voir `SelfEstimateStore`).
//
// Deux gestes possibles, aucun obligatoire : donner un nombre, ou refuser. Le
// refus est enregistré comme tel — sans lui, la question reviendrait à chaque
// ouverture de la journée jusqu'à ce que la personne réponde n'importe quoi.
// Fermer l'écran sans choisir n'enregistre rien : la question reste entière.

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../../core/l10n/l10n_ext.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/theme/kepler_colors.dart';
import '../../../../../core/widgets/kepler_button.dart';
import '../../../../../core/widgets/kepler_card.dart';
import '../../../../../core/widgets/kepler_scaffold.dart';
import '../../data/self_estimate_store.dart';

class SelfEstimatePage extends StatefulWidget {
  const SelfEstimatePage({super.key, this.store = const SelfEstimateStore()});

  final SelfEstimateStore store;

  @override
  State<SelfEstimatePage> createState() => _SelfEstimatePageState();
}

class _SelfEstimatePageState extends State<SelfEstimatePage> {
  static const int _depart = 100;

  int _valeur = _depart;

  /// Tant que rien n'a bougé, le bouton reste inerte : c'est le même verrou
  /// anti-saut que le moteur de questionnaire. Sans lui, la valeur de départ
  /// partirait comme une réponse que personne n'a donnée.
  bool _touche = false;

  /// Verrou de ré-entrance. L'écriture ouvre une box Hive chiffrée — plusieurs
  /// centaines de millisecondes au premier accès — pendant lesquelles les deux
  /// boutons restent tactiles. Sans ce verrou, un second appui lance un second
  /// `_valider` dont le `pop()` retire la route SUIVANTE : le hub disparaît de
  /// la pile, et la révélation s'affiche par-dessus l'écran de déblocage.
  bool _enCours = false;

  Future<void> _valider(int? valeur) async {
    if (_enCours) return;
    setState(() => _enCours = true);
    final enregistre = await widget.store.record(valeur);
    if (!mounted) return;
    // On renvoie ce qui s'est VRAIMENT passé. Si rien n'a pu être écrit, la
    // journée ne doit pas enchaîner sur sa révélation : la question se
    // reposerait ensuite, et sa réponse serait alors ancrée.
    Navigator.of(context).pop(enregistre);
  }

  void _bouger(int delta) {
    final cible = (_valeur + delta)
        .clamp(SelfEstimateStore.minValue, SelfEstimateStore.maxValue);
    if (cible == _valeur && _touche) return;
    setState(() {
      _valeur = cible;
      _touche = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = KeplerColors.of(context);

    return KeplerScaffold(
      eyebrow: l10n.weRvSelfEyebrow,
      title: l10n.weRvSelfTitle,
      bottomBar: SafeArea(
        minimum: EdgeInsets.fromLTRB(20.w, 0, 20.w, 12.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            KeplerButton(
              label: l10n.weRvSelfConfirm,
              expand: true,
              onPressed: (_touche && !_enCours) ? () => _valider(_valeur) : null,
            ),
            // Écart généreux : en dessous se trouve un refus DÉFINITIF (la
            // question ne sera plus jamais posée). Deux cibles collées, dont
            // l'une est irréversible, se touchent l'une pour l'autre.
            SizedBox(height: 12.h),
            KeplerButton(
              label: l10n.weRvSelfDecline,
              variant: KeplerButtonVariant.ghost,
              expand: true,
              onPressed: _enCours ? null : () => _valider(null),
            ),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 16.h),
          Text(l10n.weRvSelfBody, style: AppText.of(context).body()),
          SizedBox(height: 24.h),
          KeplerCard(
            surface: true,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _PasAPas(
                      icone: Icons.remove,
                      etiquette: l10n.weRvSelfDecrease,
                      onPressed: () => _bouger(-1),
                    ),
                    Text(
                      '$_valeur',
                      style: AppText.of(context).monoScore(
                        size: 44.sp,
                        color: _touche ? null : colors.textTertiary,
                      ),
                    ),
                    _PasAPas(
                      icone: Icons.add,
                      etiquette: l10n.weRvSelfIncrease,
                      onPressed: () => _bouger(1),
                    ),
                  ],
                ),
                Slider(
                  value: _valeur.toDouble(),
                  min: SelfEstimateStore.minValue.toDouble(),
                  max: SelfEstimateStore.maxValue.toDouble(),
                  divisions:
                      SelfEstimateStore.maxValue - SelfEstimateStore.minValue,
                  // Sans cela, un lecteur d'écran annonce la POSITION du
                  // curseur en pourcentage (« 44 % ») — un nombre qui ne veut
                  // rien dire ici, et exactement le genre de pourcentage
                  // inventé que les règles de formulation proscrivent.
                  label: '$_valeur',
                  semanticFormatterCallback: (v) => '${v.round()}',
                  activeColor: colors.primary,
                  inactiveColor: colors.border,
                  onChanged: (v) => setState(() {
                    _valeur = v.round();
                    _touche = true;
                  }),
                ),
                Text(
                  _touche ? l10n.weRvSelfAverage : l10n.weRvSelfHint,
                  style: AppText.of(context)
                      .bodySmall(color: colors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PasAPas extends StatelessWidget {
  const _PasAPas({
    required this.icone,
    required this.etiquette,
    required this.onPressed,
  });

  final IconData icone;
  final String etiquette;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => IconButton(
        onPressed: onPressed,
        tooltip: etiquette,
        icon: Icon(icone, size: 22.sp),
        color: KeplerColors.of(context).primary,
      );
}
