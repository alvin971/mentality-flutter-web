# 📁 Structure du Projet Mentality

```
mentality/
├── lib/
│   ├── main.dart
│   │
│   ├── core/
│   │   ├── constants/
│   │   │   ├── app_constants.dart
│   │   │   ├── psychometric_constants.dart
│   │   │   ├── irt_parameters.dart
│   │   │   ├── age_norms.dart
│   │   │   └── route_constants.dart
│   │   │
│   │   ├── config/
│   │   │   ├── app_config.dart
│   │   │   ├── theme_config.dart
│   │   │   ├── di_config.dart
│   │   │   └── firebase_config.dart
│   │   │
│   │   ├── error/
│   │   │   ├── exceptions.dart
│   │   │   ├── failures.dart
│   │   │   └── error_handler.dart
│   │   │
│   │   ├── network/
│   │   │   ├── network_info.dart
│   │   │   └── api_client.dart
│   │   │
│   │   ├── utils/
│   │   │   ├── validators.dart
│   │   │   ├── logger.dart
│   │   │   ├── encryption_util.dart
│   │   │   ├── date_util.dart
│   │   │   └── math_util.dart
│   │   │
│   │   ├── extensions/
│   │   │   ├── context_extension.dart
│   │   │   ├── num_extension.dart
│   │   │   ├── string_extension.dart
│   │   │   └── date_extension.dart
│   │   │
│   │   └── theme/
│   │       ├── app_theme.dart
│   │       ├── app_colors.dart
│   │       ├── app_text_styles.dart
│   │       └── app_dimensions.dart
│   │
│   ├── features/
│   │   │
│   │   ├── onboarding/
│   │   │   ├── data/
│   │   │   │   ├── datasources/
│   │   │   │   ├── models/
│   │   │   │   └── repositories/
│   │   │   ├── domain/
│   │   │   │   ├── entities/
│   │   │   │   ├── repositories/
│   │   │   │   └── usecases/
│   │   │   └── presentation/
│   │   │       ├── bloc/
│   │   │       ├── pages/
│   │   │       └── widgets/
│   │   │
│   │   ├── authentication/
│   │   │   ├── data/
│   │   │   │   ├── datasources/
│   │   │   │   │   ├── auth_local_datasource.dart
│   │   │   │   │   └── auth_remote_datasource.dart
│   │   │   │   ├── models/
│   │   │   │   │   └── user_model.dart
│   │   │   │   └── repositories/
│   │   │   │       └── auth_repository_impl.dart
│   │   │   ├── domain/
│   │   │   │   ├── entities/
│   │   │   │   │   └── user.dart
│   │   │   │   ├── repositories/
│   │   │   │   │   └── auth_repository.dart
│   │   │   │   └── usecases/
│   │   │   │       ├── login.dart
│   │   │   │       ├── register.dart
│   │   │   │       └── logout.dart
│   │   │   └── presentation/
│   │   │       ├── bloc/
│   │   │       │   ├── auth_bloc.dart
│   │   │       │   ├── auth_event.dart
│   │   │       │   └── auth_state.dart
│   │   │       ├── pages/
│   │   │       │   ├── login_page.dart
│   │   │       │   └── register_page.dart
│   │   │       └── widgets/
│   │   │           └── auth_form_field.dart
│   │   │
│   │   ├── profile/
│   │   │   ├── data/
│   │   │   │   ├── datasources/
│   │   │   │   │   └── profile_local_datasource.dart
│   │   │   │   ├── models/
│   │   │   │   │   ├── user_profile_model.dart
│   │   │   │   │   └── demographic_data_model.dart
│   │   │   │   └── repositories/
│   │   │   │       └── profile_repository_impl.dart
│   │   │   ├── domain/
│   │   │   │   ├── entities/
│   │   │   │   │   ├── user_profile.dart
│   │   │   │   │   └── demographic_data.dart
│   │   │   │   ├── repositories/
│   │   │   │   │   └── profile_repository.dart
│   │   │   │   └── usecases/
│   │   │   │       ├── get_profile.dart
│   │   │   │       ├── update_profile.dart
│   │   │   │       └── calculate_age_group.dart
│   │   │   └── presentation/
│   │   │       ├── bloc/
│   │   │       ├── pages/
│   │   │       │   ├── profile_setup_page.dart
│   │   │       │   └── profile_detail_page.dart
│   │   │       └── widgets/
│   │   │           └── age_selector_widget.dart
│   │   │
│   │   ├── assessment/
│   │   │   ├── data/
│   │   │   │   ├── datasources/
│   │   │   │   │   ├── assessment_local_datasource.dart
│   │   │   │   │   └── assessment_remote_datasource.dart
│   │   │   │   ├── models/
│   │   │   │   │   ├── assessment_session_model.dart
│   │   │   │   │   ├── test_config_model.dart
│   │   │   │   │   └── response_model.dart
│   │   │   │   └── repositories/
│   │   │   │       └── assessment_repository_impl.dart
│   │   │   ├── domain/
│   │   │   │   ├── entities/
│   │   │   │   │   ├── assessment_session.dart
│   │   │   │   │   ├── test_config.dart
│   │   │   │   │   └── user_response.dart
│   │   │   │   ├── repositories/
│   │   │   │   │   └── assessment_repository.dart
│   │   │   │   └── usecases/
│   │   │   │       ├── start_assessment.dart
│   │   │   │       ├── pause_assessment.dart
│   │   │   │       ├── resume_assessment.dart
│   │   │   │       └── complete_assessment.dart
│   │   │   └── presentation/
│   │   │       ├── bloc/
│   │   │       │   ├── assessment_bloc.dart
│   │   │       │   ├── assessment_event.dart
│   │   │       │   └── assessment_state.dart
│   │   │       ├── pages/
│   │   │       │   ├── assessment_home_page.dart
│   │   │       │   ├── assessment_instructions_page.dart
│   │   │       │   └── assessment_session_page.dart
│   │   │       └── widgets/
│   │   │           ├── progress_indicator_widget.dart
│   │   │           └── timer_widget.dart
│   │   │
│   │   ├── exercises/
│   │   │   ├── data/
│   │   │   │   ├── datasources/
│   │   │   │   │   ├── item_bank_datasource.dart
│   │   │   │   │   └── exercise_cache_datasource.dart
│   │   │   │   ├── models/
│   │   │   │   │   ├── exercise_item_model.dart
│   │   │   │   │   ├── stimulus_model.dart
│   │   │   │   │   └── distractor_model.dart
│   │   │   │   └── repositories/
│   │   │   │       └── exercise_repository_impl.dart
│   │   │   ├── domain/
│   │   │   │   ├── entities/
│   │   │   │   │   ├── exercise_item.dart
│   │   │   │   │   ├── stimulus.dart
│   │   │   │   │   ├── exercise_type.dart
│   │   │   │   │   └── difficulty_level.dart
│   │   │   │   ├── repositories/
│   │   │   │   │   └── exercise_repository.dart
│   │   │   │   └── usecases/
│   │   │   │       ├── get_next_item.dart
│   │   │   │       ├── submit_response.dart
│   │   │   │       └── validate_response.dart
│   │   │   └── presentation/
│   │   │       ├── bloc/
│   │   │       │   ├── exercise_bloc.dart
│   │   │       │   ├── exercise_event.dart
│   │   │       │   └── exercise_state.dart
│   │   │       ├── pages/
│   │   │       │   └── exercise_container_page.dart
│   │   │       └── widgets/
│   │   │           ├── base_exercise_widget.dart
│   │   │           └── exercise_factory.dart
│   │   │
│   │   ├── exercises_implementations/
│   │   │   ├── matrices/
│   │   │   │   ├── data/
│   │   │   │   ├── domain/
│   │   │   │   │   ├── entities/
│   │   │   │   │   │   ├── matrix_pattern.dart
│   │   │   │   │   │   ├── matrix_rule.dart
│   │   │   │   │   │   └── matrix_config.dart
│   │   │   │   │   └── usecases/
│   │   │   │   │       └── generate_matrix_item.dart
│   │   │   │   └── presentation/
│   │   │   │       └── widgets/
│   │   │   │           ├── matrix_exercise_widget.dart
│   │   │   │           ├── matrix_grid_widget.dart
│   │   │   │           └── matrix_options_widget.dart
│   │   │   │
│   │   │   ├── balances/
│   │   │   │   ├── domain/
│   │   │   │   │   ├── entities/
│   │   │   │   │   │   └── balance_equation.dart
│   │   │   │   │   └── usecases/
│   │   │   │   │       └── generate_balance_item.dart
│   │   │   │   └── presentation/
│   │   │   │       └── widgets/
│   │   │   │           ├── balance_exercise_widget.dart
│   │   │   │           └── balance_visual_widget.dart
│   │   │   │
│   │   │   ├── visual_puzzles/
│   │   │   │   ├── domain/
│   │   │   │   │   ├── entities/
│   │   │   │   │   │   └── puzzle_piece.dart
│   │   │   │   │   └── usecases/
│   │   │   │   │       └── generate_puzzle_item.dart
│   │   │   │   └── presentation/
│   │   │   │       └── widgets/
│   │   │   │           ├── puzzle_exercise_widget.dart
│   │   │   │           └── puzzle_piece_widget.dart
│   │   │   │
│   │   │   ├── block_design/
│   │   │   │   ├── domain/
│   │   │   │   │   ├── entities/
│   │   │   │   │   │   ├── cube_pattern.dart
│   │   │   │   │   │   └── cube.dart
│   │   │   │   │   └── usecases/
│   │   │   │   │       └── validate_cube_arrangement.dart
│   │   │   │   └── presentation/
│   │   │   │       └── widgets/
│   │   │   │           ├── cube_exercise_widget.dart
│   │   │   │           ├── cube_3d_widget.dart
│   │   │   │           └── cube_grid_widget.dart
│   │   │   │
│   │   │   ├── coding/
│   │   │   │   ├── domain/
│   │   │   │   │   └── entities/
│   │   │   │   │       └── symbol_mapping.dart
│   │   │   │   └── presentation/
│   │   │   │       └── widgets/
│   │   │   │           ├── coding_exercise_widget.dart
│   │   │   │           └── symbol_keyboard_widget.dart
│   │   │   │
│   │   │   ├── digit_span/
│   │   │   │   ├── domain/
│   │   │   │   │   ├── entities/
│   │   │   │   │   │   └── digit_sequence.dart
│   │   │   │   │   └── usecases/
│   │   │   │   │       └── generate_digit_sequence.dart
│   │   │   │   └── presentation/
│   │   │   │       └── widgets/
│   │   │   │           ├── digit_span_exercise_widget.dart
│   │   │   │           └── digit_input_widget.dart
│   │   │   │
│   │   │   ├── vocabulary/
│   │   │   │   ├── domain/
│   │   │   │   │   └── entities/
│   │   │   │   │       └── vocabulary_item.dart
│   │   │   │   └── presentation/
│   │   │   │       └── widgets/
│   │   │   │           ├── vocabulary_receptive_widget.dart
│   │   │   │           └── vocabulary_expressive_widget.dart
│   │   │   │
│   │   │   ├── similarities/
│   │   │   │   ├── domain/
│   │   │   │   │   └── entities/
│   │   │   │   │       └── similarity_pair.dart
│   │   │   │   └── presentation/
│   │   │   │       └── widgets/
│   │   │   │           └── similarities_exercise_widget.dart
│   │   │   │
│   │   │   ├── picture_memory/
│   │   │   │   ├── domain/
│   │   │   │   │   └── entities/
│   │   │   │   │       └── memory_sequence.dart
│   │   │   │   └── presentation/
│   │   │   │       └── widgets/
│   │   │   │           └── picture_memory_widget.dart
│   │   │   │
│   │   │   ├── symbol_search/
│   │   │   │   └── presentation/
│   │   │   │       └── widgets/
│   │   │   │           └── symbol_search_widget.dart
│   │   │   │
│   │   │   └── cancellation/
│   │   │       └── presentation/
│   │   │           └── widgets/
│   │   │               └── cancellation_widget.dart
│   │   │
│   │   ├── adaptive_testing/
│   │   │   ├── data/
│   │   │   │   ├── datasources/
│   │   │   │   │   └── irt_parameters_datasource.dart
│   │   │   │   ├── models/
│   │   │   │   │   ├── irt_item_model.dart
│   │   │   │   │   └── theta_estimate_model.dart
│   │   │   │   └── repositories/
│   │   │   │       └── cat_repository_impl.dart
│   │   │   ├── domain/
│   │   │   │   ├── entities/
│   │   │   │   │   ├── irt_item.dart
│   │   │   │   │   ├── theta_estimate.dart
│   │   │   │   │   └── stopping_criterion.dart
│   │   │   │   ├── repositories/
│   │   │   │   │   └── cat_repository.dart
│   │   │   │   └── usecases/
│   │   │   │       ├── select_next_item.dart
│   │   │   │       ├── estimate_ability.dart
│   │   │   │       ├── calculate_information.dart
│   │   │   │       └── check_stopping_criterion.dart
│   │   │   └── presentation/
│   │   │       └── bloc/
│   │   │           ├── cat_bloc.dart
│   │   │           ├── cat_event.dart
│   │   │           └── cat_state.dart
│   │   │
│   │   ├── scoring/
│   │   │   ├── data/
│   │   │   │   ├── datasources/
│   │   │   │   │   ├── norms_datasource.dart
│   │   │   │   │   └── scoring_tables_datasource.dart
│   │   │   │   ├── models/
│   │   │   │   │   ├── raw_score_model.dart
│   │   │   │   │   ├── scaled_score_model.dart
│   │   │   │   │   └── composite_score_model.dart
│   │   │   │   └── repositories/
│   │   │   │       └── scoring_repository_impl.dart
│   │   │   ├── domain/
│   │   │   │   ├── entities/
│   │   │   │   │   ├── raw_score.dart
│   │   │   │   │   ├── scaled_score.dart
│   │   │   │   │   ├── composite_score.dart
│   │   │   │   │   ├── iq_score.dart
│   │   │   │   │   └── confidence_interval.dart
│   │   │   │   ├── repositories/
│   │   │   │   │   └── scoring_repository.dart
│   │   │   │   └── usecases/
│   │   │   │       ├── calculate_raw_score.dart
│   │   │   │       ├── convert_to_scaled_score.dart
│   │   │   │       ├── calculate_composite_scores.dart
│   │   │   │       ├── calculate_iq.dart
│   │   │   │       └── calculate_confidence_interval.dart
│   │   │   └── presentation/
│   │   │       └── bloc/
│   │   │           ├── scoring_bloc.dart
│   │   │           ├── scoring_event.dart
│   │   │           └── scoring_state.dart
│   │   │
│   │   ├── results/
│   │   │   ├── data/
│   │   │   │   ├── datasources/
│   │   │   │   │   └── results_local_datasource.dart
│   │   │   │   ├── models/
│   │   │   │   │   ├── test_result_model.dart
│   │   │   │   │   └── index_score_model.dart
│   │   │   │   └── repositories/
│   │   │   │       └── results_repository_impl.dart
│   │   │   ├── domain/
│   │   │   │   ├── entities/
│   │   │   │   │   ├── test_result.dart
│   │   │   │   │   ├── index_score.dart
│   │   │   │   │   ├── subtest_score.dart
│   │   │   │   │   └── interpretation.dart
│   │   │   │   ├── repositories/
│   │   │   │   │   └── results_repository.dart
│   │   │   │   └── usecases/
│   │   │   │       ├── get_results.dart
│   │   │   │       ├── generate_interpretation.dart
│   │   │   │       └── export_results_pdf.dart
│   │   │   └── presentation/
│   │   │       ├── bloc/
│   │   │       │   ├── results_bloc.dart
│   │   │       │   ├── results_event.dart
│   │   │       │   └── results_state.dart
│   │   │       ├── pages/
│   │   │       │   ├── results_overview_page.dart
│   │   │       │   ├── detailed_results_page.dart
│   │   │       │   └── history_page.dart
│   │   │       └── widgets/
│   │   │           ├── score_card_widget.dart
│   │   │           ├── index_chart_widget.dart
│   │   │           ├── percentile_widget.dart
│   │   │           └── interpretation_widget.dart
│   │   │
│   │   ├── ai_generator/
│   │   │   ├── data/
│   │   │   │   ├── datasources/
│   │   │   │   │   ├── ai_remote_datasource.dart
│   │   │   │   │   └── item_cache_datasource.dart
│   │   │   │   ├── models/
│   │   │   │   │   ├── generation_request_model.dart
│   │   │   │   │   └── generated_item_model.dart
│   │   │   │   └── repositories/
│   │   │   │       └── ai_generator_repository_impl.dart
│   │   │   ├── domain/
│   │   │   │   ├── entities/
│   │   │   │   │   ├── generation_parameters.dart
│   │   │   │   │   ├── generated_item.dart
│   │   │   │   │   └── item_validation.dart
│   │   │   │   ├── repositories/
│   │   │   │   │   └── ai_generator_repository.dart
│   │   │   │   └── usecases/
│   │   │   │       ├── generate_matrix_item.dart
│   │   │   │       ├── generate_balance_item.dart
│   │   │   │       ├── generate_puzzle_item.dart
│   │   │   │       ├── validate_generated_item.dart
│   │   │   │       └── calibrate_item_difficulty.dart
│   │   │   └── presentation/
│   │   │       └── bloc/
│   │   │           ├── ai_generator_bloc.dart
│   │   │           ├── ai_generator_event.dart
│   │   │           └── ai_generator_state.dart
│   │   │
│   │   ├── settings/
│   │   │   ├── data/
│   │   │   │   ├── datasources/
│   │   │   │   │   └── settings_local_datasource.dart
│   │   │   │   ├── models/
│   │   │   │   │   └── app_settings_model.dart
│   │   │   │   └── repositories/
│   │   │   │       └── settings_repository_impl.dart
│   │   │   ├── domain/
│   │   │   │   ├── entities/
│   │   │   │   │   └── app_settings.dart
│   │   │   │   ├── repositories/
│   │   │   │   │   └── settings_repository.dart
│   │   │   │   └── usecases/
│   │   │   │       ├── get_settings.dart
│   │   │   │       └── update_settings.dart
│   │   │   └── presentation/
│   │   │       ├── bloc/
│   │   │       ├── pages/
│   │   │       │   └── settings_page.dart
│   │   │       └── widgets/
│   │   │
│   │   └── gdpr/
│   │       ├── data/
│   │       │   ├── datasources/
│   │       │   │   └── consent_datasource.dart
│   │       │   ├── models/
│   │       │   │   └── consent_model.dart
│   │       │   └── repositories/
│   │       │       └── gdpr_repository_impl.dart
│   │       ├── domain/
│   │       │   ├── entities/
│   │       │   │   └── consent.dart
│   │       │   ├── repositories/
│   │       │   │   └── gdpr_repository.dart
│   │       │   └── usecases/
│   │       │       ├── request_consent.dart
│   │       │       ├── export_user_data.dart
│   │       │       └── delete_user_data.dart
│   │       └── presentation/
│   │           ├── bloc/
│   │           ├── pages/
│   │           │   ├── consent_page.dart
│   │           │   └── data_management_page.dart
│   │           └── widgets/
│   │
│   └── shared/
│       ├── widgets/
│       │   ├── custom_button.dart
│       │   ├── custom_text_field.dart
│       │   ├── loading_indicator.dart
│       │   ├── error_widget.dart
│       │   ├── age_appropriate_ui/
│       │   │   ├── preschool_ui_wrapper.dart
│       │   │   ├── child_ui_wrapper.dart
│       │   │   └── adult_ui_wrapper.dart
│       │   └── animations/
│       │       ├── confetti_animation.dart
│       │       ├── transition_animation.dart
│       │       └── feedback_animation.dart
│       │
│       └── models/
│           └── common_models.dart
│
├── assets/
│   ├── images/
│   │   ├── exercises/
│   │   │   ├── matrices/
│   │   │   ├── puzzles/
│   │   │   ├── vocabulary/
│   │   │   └── memory/
│   │   ├── icons/
│   │   ├── avatars/
│   │   └── icon/
│   │       └── app_icon.png
│   │
│   ├── animations/
│   │   ├── lottie/
│   │   │   ├── success.json
│   │   │   ├── loading.json
│   │   │   └── celebration.json
│   │   └── rive/
│   │
│   ├── audio/
│   │   ├── instructions/
│   │   ├── feedback/
│   │   │   ├── correct.mp3
│   │   │   └── encouragement.mp3
│   │   └── tts_cache/
│   │
│   ├── fonts/
│   │   ├── Poppins-Regular.ttf
│   │   ├── Poppins-Medium.ttf
│   │   ├── Poppins-SemiBold.ttf
│   │   ├── Poppins-Bold.ttf
│   │   ├── Roboto-Regular.ttf
│   │   ├── Roboto-Medium.ttf
│   │   └── Roboto-Bold.ttf
│   │
│   └── data/
│       ├── norms/
│       │   ├── norms_enfant.json
│       │   ├── norms_adolescent.json
│       │   └── norms_adulte.json
│       ├── items/
│       │   ├── matrices_bank.json
│       │   ├── vocabulary_bank.json
│       │   └── irt_parameters.json
│       └── scoring_tables/
│           ├── raw_to_scaled.json
│           └── composite_conversion.json
│
├── test/
│   ├── unit/
│   │   ├── core/
│   │   ├── features/
│   │   │   ├── adaptive_testing/
│   │   │   │   └── usecases/
│   │   │   │       └── estimate_ability_test.dart
│   │   │   ├── scoring/
│   │   │   │   └── usecases/
│   │   │   │       └── calculate_iq_test.dart
│   │   │   └── exercises/
│   │   └── shared/
│   │
│   ├── widget/
│   │   └── exercises/
│   │       └── matrix_exercise_widget_test.dart
│   │
│   └── integration/
│       └── assessment_flow_test.dart
│
├── integration_test/
│   └── app_test.dart
│
├── android/
├── ios/
├── web/
├── windows/
├── linux/
├── macos/
│
├── .gitignore
├── analysis_options.yaml
├── pubspec.yaml
├── README.md
└── ARCHITECTURE.md
```

## 📊 Statistiques de Structure

- **Total Features**: 13 domaines fonctionnels
- **Total Layers**: 3 (Data, Domain, Presentation) par feature
- **Types d'exercices**: 12 implémentations distinctes
- **Packages externes**: 60+ dépendances
- **Architecture**: Clean Architecture + BLoC
- **Pattern**: Repository + Use Cases
