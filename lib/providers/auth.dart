



import 'package:punch/constants/enums/auth_mode.dart';
import 'package:punch/constants/enums/sign_up_modes.dart';
import 'package:punch/models/models_shelf.dart';

import 'package:punch/utils/validators.dart';
import 'package:async/async.dart';
import 'package:flutter/material.dart';


/// It is called on auth mode changes,
/// triggered by [Auth.switchAuth] method.
typedef AuthModeChangeCallback = void Function(AuthMode authMode);

/// [Auth] is the provider for auth related data, functions.
class Auth extends ChangeNotifier {
  /// Manages the state related to the authentication modes.
   Auth({
   GlobalKey<FormState> ?formKey,
  
    this.onAuthModeChange,
    this.validateName = true,
    this.validateEmail = true,
    this.validatePassword = true,
    this.validateCheckbox = true,
    this.showPasswordVisibility = true,
    this.checkboxCallback,
    bool hasPrivacyPolicy = false,
    ValidatorModel? nameValidator,
    ValidatorModel? emailValidator,
    ValidatorModel? passwordValidator,
    TextEditingController? nameController,
    TextEditingController? emailController,
    TextEditingController? passwordController,
    TextEditingController? confirmPasswordController,
    AuthMode? initialMode,
   VoidCallback? onLogin,
    SignupCallback? onSignup,
    ForgotPasswordCallback? onForgotPassword,
    SignUpModes? signUpMode,
  })  : _formKey = formKey!,
        _signUpMode = signUpMode ?? SignUpModes.both,
        _nameController = nameController ?? TextEditingController(text: ''),
        _emailController = emailController ?? TextEditingController(text: ''),
        _passwordController =
            passwordController!,
        _confirmPasswordController =
            confirmPasswordController ?? TextEditingController(text: ''),
        _nameValidator = nameValidator,
        _emailValidator = emailValidator,
        _passwordValidator = passwordValidator,
        _hasPrivacyPolicy = hasPrivacyPolicy {
    _onLogin = onLogin! ;
    _onSignup = onSignup ?? _defaultSignupFunc;
    _onForgotPassword = onForgotPassword ?? _defaultForgotPassFunc;
    _mode = initialMode ?? AuthMode.login;
    _initialMode = initialMode ?? AuthMode.login;
  }

  /// Default login, signup and forgot password functions to be
  
  Future<String?> _defaultSignupFunc(SignUpData a) async => null;
  Future<String?> _defaultForgotPassFunc(String e) async => null;

  /// checkboxCallback
  ValueChanged<bool?>? checkboxCallback;

  /// Callback to use auth mode changes.
  final AuthModeChangeCallback? onAuthModeChange;

 late final VoidCallback _onLogin;

  /// Function to be called on login action.
  //VoidCallback get onLogin => _onLogin;

  late final SignupCallback _onSignup;

  /// Function to be called on signup action.
  SignupCallback get onSignup => _onSignup;

  late final ForgotPasswordCallback _onForgotPassword;

  /// Function to be called on click to forgot password text.
  ForgotPasswordCallback get onForgotPassword => _onForgotPassword;

  bool _checkedPrivacyBox = false;
  bool _showCheckboxError = false;
  final bool _hasPrivacyPolicy;

  late AuthMode _mode;
  late AuthMode _initialMode;

  /// Current authentication mode of the screen.
  AuthMode get mode => _mode;

  /// Uses [AuthMode] enum's values.
  void notifySetMode(AuthMode value) {
    if (value.index != mode.index) {
      _mode = value;
      notifyListeners();
    }
  }

  /// Returns whether the current [_mode] is login or signup mode.
  bool get isLogin => _mode == AuthMode.login;

  /// Returns whether the current [_mode] is login or signup mode.
  bool get isSignup => _mode == AuthMode.signup;

  /// Switches the authentication mode and notify the listeners.
  AuthMode switchAuth() {
    notifySetMode(isLogin ? AuthMode.signup : AuthMode.login);
    onAuthModeChange?.call(mode);
    return mode;
  }

  bool _isReverse = true;

  /// Indicates whether the screen animation is reverse mode.
  bool get isReverse => _isReverse;

  /// Indicates whether the box is checked.
  bool get checkedPrivacyBox => _checkedPrivacyBox;

  /// Indicates whether to show checkbox error.
  bool get showCheckboxError => _showCheckboxError;

  /// Combination of isReverse and initial mode values.
  bool get isAnimatedLogin => !_isReverse ^ (_initialMode == AuthMode.login);

  /// Username in the text controller.
  String? _username;
String? get username => _username;
  /// Email user entered in the text controller.
  String? _email;
String? get email => _email;
  /// Password text in the text controller.
  String? _password;
String? get password => _password;
  /// Confirm password text in the text controller.
  String? confirmPassword;



  /// Sets the username.
  // ignore: use_setters_to_change_properties
  
  void setUsername({required String newUsername}) {
    _username = newUsername;
    notifyListeners();
  }

  /// Sets the email.
  // ignore: use_setters_to_change_properties
  

  void setEmail({required String newEmail}) {
    _email = newEmail;
    notifyListeners();
  }
  /// Sets the password.
  // ignore: use_setters_to_change_properties
 
  void setPassword({required String newPassword}) {
    _password = newPassword ;
    notifyListeners();
  }

  /// Sets the checkbox.
  void setCheckedPrivacyPolicy({bool? newValue}) {
    checkboxCallback?.call(newValue);
    if (newValue == null || newValue == _checkedPrivacyBox) return;
    _checkedPrivacyBox = newValue;
    notifyListeners();
  }

  /// Sets whether to show checkbox error.
  void setShowCheckboxError({bool? newValue}) {
    if (newValue == null || newValue == _showCheckboxError) return;
    _showCheckboxError = newValue;
    notifyListeners();
  }

  /// Sets the confirm password.
  // ignore: use_setters_to_change_properties
  void setConfirmPassword(String? newConfirmPassword) =>
      confirmPassword = newConfirmPassword;

  /// Sets the confirm password.
  void setIsReverse({required bool newValue}) {
    if (newValue != _isReverse) {
      _isReverse = newValue;
      notifyListeners();
    }
  }

  /// Cancelable operation for auth operations.
  CancelableOperation<dynamic>? cancelableOperation;

  final TextEditingController _nameController;
  final TextEditingController _emailController;
  final TextEditingController _passwordController;
  final TextEditingController _confirmPasswordController;

  /// Custom input validator for name field.
  final ValidatorModel? _nameValidator;

  /// Custom input validator for email field.
  final ValidatorModel? _emailValidator;

  /// Custom input validator for password field.
  final ValidatorModel? _passwordValidator;

  /// Indicates whether the name field should be validated.
  final bool validateName;

  /// Indicates whether the email field should be validated.
  final bool validateEmail;

  /// Indicates whether the password fields should be validated.
  final bool validatePassword;

  /// Indicates whether the checkbox should be validated.
  final bool validateCheckbox;

  /// Indicates whether the user can show the password text without obscuring.
  final bool showPasswordVisibility;

  final SignUpModes _signUpMode;

  /// Sets the email value.
  void setEmailValue(String? value) =>
      _emailController.value = TextEditingValue(text: value ?? '');

  /// Sets the password value.
  void setPasswordValue(String? value) =>
      _passwordController.value = TextEditingValue(text: value ?? '');

  /// Sets the username value.
  void setUsernameValue(String? value) =>
      _nameController.value = TextEditingValue(text: value ?? '');

  /// Sets the confirm password value.
  void setConfirmPasswordValue(String? value) =>
      _confirmPasswordController.value = TextEditingValue(text: value ?? '');

  /// Optional TextEditingController for name input field.
  TextEditingController get nameController => _nameController;

  /// Optional TextEditingController for email input field.
  TextEditingController get emailController => _emailController;

  /// Optional TextEditingController for password input field.
  TextEditingController get passwordController => _passwordController;

  /// Optional TextEditingController for confirm password input field.
  TextEditingController get confirmPasswordController =>
      _confirmPasswordController;

  /// Enum to determine which text form fields should be displayed in addition
  /// to the email and password fields: Name / Confirm Password / Both
  SignUpModes get signUpMode => _signUpMode;

  final GlobalKey<FormState> _formKey;

  /// The form key that will be assigned to the form.
  GlobalKey<FormState> get formKey => _formKey;

 

  /// Any login or signup action.
  
  
 
  

  Future<String?> _signupResult() async {
    final signupData = SignUpData(
      name: _nameController.text,
      email: _emailController.text,
      password: _passwordController.text,
      confirmPassword: _confirmPasswordController.text,
    );
    if (validateCheckbox && _hasPrivacyPolicy) {
      if (!_checkedPrivacyBox) {
        setShowCheckboxError(newValue: true);
        return 'Please agree to the Privacy Policy and Terms & Conditions';
      } else {
        setShowCheckboxError(newValue: false);
      }
    }
    return onSignup(signupData);
  }

  /// Name validator.
  FormFieldValidator<String?>? get nameValidator => validateName
      ? (_nameValidator?.customValidator ??
          Validators(validator: _nameValidator).name)
      : null;

  /// Email validator.
  FormFieldValidator<String?>? get emailValidator => validateEmail
      ? (_emailValidator?.customValidator ??
          Validators(validator: _emailValidator).email)
      : null;

  /// Password validator.
  FormFieldValidator<String?>? get passwordValidator => validatePassword
      ? (_passwordValidator?.customValidator ??
          Validators(
            validator: _passwordValidator ??
                const ValidatorModel(
                  checkLowerCase: true,
                  checkUpperCase: true,
                  checkNumber: true,
                  checkSpace: true,
                ),
          ).password)
      : null;
}
