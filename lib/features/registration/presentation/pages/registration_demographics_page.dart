import 'dart:async';

import 'package:country_code_picker/country_code_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/kepler_button.dart';
import '../../../../core/widgets/kepler_card.dart';
import '../../../../core/widgets/kepler_scaffold.dart';
import '../../data/datasources/registration_remote_datasource.dart';
import '../../data/repositories/registration_repository.dart';
import '../../domain/entities/registration_form.dart';
import '../bloc/registration_bloc.dart';
import 'registration_success_page.dart';

class RegistrationDemographicsPage extends StatefulWidget {
  const RegistrationDemographicsPage({super.key});

  @override
  State<RegistrationDemographicsPage> createState() =>
      _RegistrationDemographicsPageState();
}

class _RegistrationDemographicsPageState
    extends State<RegistrationDemographicsPage> {
  final _postalController = TextEditingController();
  Sex? _sex;
  AgeBucket? _ageBucket;
  String _countryCode = 'FR';
  List<PostalCodeSuggestion> _suggestions = [];
  Timer? _debounce;

  late final RegistrationRepository _repo = RegistrationRepository();

  @override
  void dispose() {
    _postalController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onPostalChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () async {
      if (value.trim().isEmpty) {
        setState(() => _suggestions = []);
        return;
      }
      try {
        final results = await _repo.searchPostalCodes(
            countryCode: _countryCode, query: value.trim());
        if (mounted) setState(() => _suggestions = results);
      } catch (_) {
        if (mounted) setState(() => _suggestions = []);
      }
    });
  }

  bool get _isValid =>
      _sex != null &&
      _ageBucket != null &&
      _postalController.text.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<RegistrationBloc, RegistrationState>(
      listenWhen: (a, b) => a.step != b.step,
      listener: (context, state) {
        if (state.step == RegistrationStep.success) {
          Navigator.of(context).pushReplacement(MaterialPageRoute(
              builder: (_) => const RegistrationSuccessPage()));
        }
      },
      builder: (context, state) {
        return KeplerScaffold(
          title: 'Vos données démographiques',
          eyebrow: 'ÉTAPE 3 / 4',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 12.h),
              Text(
                'Ces informations seront chiffrées dans votre token. '
                'Aucune valeur exacte n\'est stockée (ni âge précis, '
                'ni adresse précise).',
                style: AppText.body(),
              ),
              SizedBox(height: 24.h),
              _sectionLabel('SEXE'),
              SizedBox(height: 8.h),
              KeplerCard(
                child: Column(
                  children: Sex.values
                      .map((s) => RadioListTile<Sex>(
                            value: s,
                            groupValue: _sex,
                            title: Text(s.label, style: AppText.bodyStrong()),
                            activeColor: AppColors.primary,
                            onChanged: (v) => setState(() => _sex = v),
                          ))
                      .toList(),
                ),
              ),
              SizedBox(height: 20.h),
              _sectionLabel('TRANCHE D\'ÂGE'),
              SizedBox(height: 8.h),
              KeplerCard(
                child: Wrap(
                  spacing: 8.w,
                  runSpacing: 8.h,
                  children: AgeBucket.values
                      .map((a) => ChoiceChip(
                            label: Text(a.label),
                            selected: _ageBucket == a,
                            selectedColor:
                                AppColors.primary.withValues(alpha: 0.2),
                            onSelected: (sel) =>
                                setState(() => _ageBucket = sel ? a : null),
                          ))
                      .toList(),
                ),
              ),
              SizedBox(height: 20.h),
              _sectionLabel('PAYS ET CODE POSTAL'),
              SizedBox(height: 8.h),
              KeplerCard(
                child: Row(
                  children: [
                    CountryCodePicker(
                      initialSelection: 'FR',
                      favorite: const ['FR', 'BE', 'CH', 'US', 'GB'],
                      showFlag: true,
                      showOnlyCountryWhenClosed: true,
                      onChanged: (c) => setState(() {
                        _countryCode = c.code ?? 'FR';
                        _suggestions = [];
                      }),
                    ),
                    Expanded(
                      child: TextField(
                        controller: _postalController,
                        decoration: const InputDecoration(
                          hintText: 'Code postal',
                          border: InputBorder.none,
                        ),
                        onChanged: _onPostalChanged,
                      ),
                    ),
                  ],
                ),
              ),
              if (_suggestions.isNotEmpty) ...[
                SizedBox(height: 8.h),
                KeplerCard(
                  child: Column(
                    children: _suggestions.map((s) {
                      return ListTile(
                        dense: true,
                        title: Text('${s.postalCode} — ${s.placeName}',
                            style: AppText.bodyStrong()),
                        subtitle: s.admin1 != null
                            ? Text(s.admin1!, style: AppText.bodySmall())
                            : null,
                        onTap: () {
                          setState(() {
                            _postalController.text = s.postalCode;
                            _suggestions = [];
                          });
                          FocusScope.of(context).unfocus();
                        },
                      );
                    }).toList(),
                  ),
                ),
              ],
              if (state.errorMessage != null) ...[
                SizedBox(height: 16.h),
                Text(state.errorMessage!,
                    style: AppText.bodySmall(color: AppColors.error)),
              ],
              SizedBox(height: 24.h),
              KeplerButton(
                label: state.busy
                    ? 'Génération du token…'
                    : 'Générer mon token',
                expand: true,
                onPressed: (!_isValid || state.busy)
                    ? null
                    : () {
                        context
                            .read<RegistrationBloc>()
                            .add(SubmitDemographics(
                              sex: _sex!,
                              ageBucket: _ageBucket!,
                              countryCode: _countryCode,
                              postalCode: _postalController.text.trim(),
                            ));
                      },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _sectionLabel(String label) => Text(
        label,
        style: AppText.monoLabel(color: AppColors.primary),
      );
}
