import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'signup_form_controller.g.dart';

class SignupState {
  final int currentStep;
  final Map<String, dynamic> formData;

  SignupState({this.currentStep = 0, this.formData = const {}});

  SignupState copyWith({int? currentStep, Map<String, dynamic>? formData}) {
    return SignupState(
      currentStep: currentStep ?? this.currentStep,
      formData: formData ?? this.formData,
    );
  }
}

@riverpod
class SignupFormController extends _$SignupFormController {
  @override
  SignupState build() {
    return SignupState();
  }

  void nextStep() {
    if (state.currentStep < 2) {
      state = state.copyWith(currentStep: state.currentStep + 1);
    }
  }

  void previousStep() {
    if (state.currentStep > 0) {
      state = state.copyWith(currentStep: state.currentStep - 1);
    }
  }

  void updateData(Map<String, dynamic> newData) {
    state = state.copyWith(formData: {...state.formData, ...newData});
  }
}
