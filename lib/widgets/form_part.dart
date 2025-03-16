part of '../../animated_login.dart';

class _WebForm extends StatefulWidget {
  /// Form part of the login screen.
  const _WebForm({
    required this.animationController,
    this.privacyPolicyChild,
    Key? key,
    required this.formKey,
    required this.password,
    required this.email,
  }) : super(key: key);

  /// Main animation controller for the transition animation.
  final AnimationController animationController;
  final GlobalKey<FormState> formKey;
  final String password;
  final String email;

  /// Privacy policy child widget
  final Widget? privacyPolicyChild;

  @override
  __WebFormState createState() => __WebFormState();
}

class __WebFormState extends State<_WebForm> {
  /// Custom LoginTheme data, colors and styles on the screen.
  late LoginTheme loginTheme;

  /// Custom LoginTexts data, texts on the screen.
  late LoginTexts loginTexts;

  /// It is for giving responsive size values.
  late DynamicSize dynamicSize;

  /// Its aim is to take, manage, change auth data with the state.
  late Auth auth;

  /// Theme is created as a variable to call it from different code pieces.
  late ThemeData theme;

  /// Transition animation that will change the location of the form part.
  late Animation<double> transitionAnimation;

  /// Animation that will change the location of the components of form.
  late final Animation<double> offsetAnimation;

  late bool _isLandscape;
  late bool _isAnimatedLogin;

  @override
  void initState() {
    super.initState();

    /// Initializes the appearance and disappearance animations
    /// from outside to the screen for the form LoginComponents.
    offsetAnimation = AnimationHelper(
      animationController: widget.animationController,
      animationCurve: context.read<LoginTheme>().animationCurve,
    ).tweenSequenceAnimation(80, 10);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final auth = context.read<Auth>();
    auth
      ..setEmailValue(auth.email)
      ..setPasswordValue(auth.password)
      ..setUsernameValue(auth.username)
      ..setConfirmPasswordValue(auth.confirmPassword);
  }

  @override
  Widget build(BuildContext context) {
    dynamicSize = DynamicSize(context);
    loginTheme = context.watch<LoginTheme>();
    _isLandscape = loginTheme.isLandscape;
    _isAnimatedLogin =
        context.select<Auth, bool>((Auth auth) => auth.isAnimatedLogin);
    loginTexts = context.read<LoginTexts>();
    theme = Theme.of(context);
    auth = context.read<Auth>();
    _initializeAnimations();
    return _webView;
  }

  Widget get _webView => AnimatedBuilder(
        animation: transitionAnimation,
        child: _webViewChild,
        builder: (BuildContext context, Widget? child) => Transform.translate(
          offset: Offset(dynamicSize.width * transitionAnimation.value, 0),
          child: child,
        ),
      );

  Widget get _webViewChild => Container(
        width: dynamicSize.width * context.read<LoginTheme>().formWidthRatio,
        height: dynamicSize.height * 100,
        color: Colors.white,
        child: AnimatedBuilder(
          animation: offsetAnimation,
          child: _formColumn,
          builder: (BuildContext context, Widget? child) => Transform.translate(
            offset: Offset(dynamicSize.width * offsetAnimation.value, 0),
            child: child,
          ),
        ),
      );

  Widget get _formColumn {
    final items = <Widget>[];
    for (final component in loginTheme.animatedComponentOrder) {
      items.addAll(_orderedComponent(
        component.component,
      ));
    }
    return Column(mainAxisAlignment: MainAxisAlignment.center, children: items);
  }

  List<Widget> _orderedComponent(
    LoginComponents component,
  ) {
    switch (component) {
      case LoginComponents.formTitle:
        return <Widget>[if (_isLandscape) const _FormTitle()];

      case LoginComponents.form:
        return <Widget>[
          _Form(
            formKey: widget.formKey,
            password: widget.password,
            email: widget.email,
          )
        ];
      case LoginComponents.policyCheckbox:
        return <Widget>[
          if (!_isAnimatedLogin)
            widget.privacyPolicyChild ?? const _PolicyCheckboxRow()
        ];
     
      case LoginComponents.actionButton:
        return <Widget>[
          _ActionButton(
            formKey: widget.formKey,
          )
        ];
      case LoginComponents.title:
      case LoginComponents.description:
      case LoginComponents.logo:
        // case LoginComponents.notHaveAnAccount:
        //  case LoginComponents.changeActionButton:
        return <Widget>[Container()];
    }
  }

  void _initializeAnimations() {
    /// Initializes the transition animation from welcome part's width ratio
    /// to 0 with custom animation curve and animation controller.
    transitionAnimation = _isLandscape
        ? Tween<double>(begin: 100 - loginTheme.formWidthRatio, end: 0).animate(
            CurvedAnimation(
              parent: widget.animationController,
              curve: loginTheme.animationCurve,
            ),
          )
        : AnimationHelper(
            animationController: widget.animationController,
            animationCurve: loginTheme.animationCurve,
          ).tweenSequenceAnimation(120, 20);
  }
}

class _PolicyCheckboxRow extends StatelessWidget {
  const _PolicyCheckboxRow({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final loginTheme = context.watch<LoginTheme>();
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            _checkbox,
            Flexible(child: _checkboxText(context, loginTheme)),
          ],
        ),
        _errorText(loginTheme),
      ],
    );
  }

  Widget _errorText(LoginTheme loginTheme) => Selector<Auth, bool>(
        selector: (_, Auth authModel) {
          return authModel.showCheckboxError;
        },
        builder: (BuildContext context, bool showError, __) => Visibility(
          visible: showError,
          child: Padding(
            padding:
                EdgeInsets.only(top: DynamicSize(context).responsiveSize * 2.5),
            child: BaseText(
              context.read<LoginTexts>().checkboxError,
              style: TextStyles(context)
                  .errorTextStyle()
                  .merge(loginTheme.errorTextStyle),
            ),
          ),
        ),
      );

  Widget _checkboxText(BuildContext context, LoginTheme loginTheme) {
    final loginTexts = context.read<LoginTexts>();
    return RichText(
      text: TextSpan(
        style:
            loginTheme.privacyPolicyStyle ?? DefaultTextStyle.of(context).style,
        children: <InlineSpan>[
          TextSpan(text: loginTexts.agreementText),
          TextSpan(
            text: loginTexts.privacyPolicyText,
            style: loginTheme.privacyPolicyLinkStyle ??
                const TextStyle(
                  color: Colors.blue,
                  decoration: TextDecoration.underline,
                ),
            recognizer: TapGestureRecognizer()
              ..onTap = () => _launchUrl(loginTexts.privacyPolicyLink),
          ),
          const TextSpan(text: ' and '),
          TextSpan(
            text: loginTexts.termsConditionsText,
            style: loginTheme.privacyPolicyLinkStyle ??
                const TextStyle(
                  color: Colors.blue,
                  decoration: TextDecoration.underline,
                ),
            recognizer: TapGestureRecognizer()
              ..onTap = () => _launchUrl(loginTexts.termsConditionsLink),
          ),
        ],
      ),
    );
  }

  Widget get _checkbox => Selector<Auth, bool>(
        selector: (_, Auth authModel) => authModel.checkedPrivacyBox,
        builder: (BuildContext context, bool checked, __) {
          final loginTheme = context.watch<LoginTheme>();
          final authModel = context.read<Auth>();
          final activeColor =
              loginTheme.privacyPolicyLinkStyle?.color ?? Colors.white;
          final isLandscape = loginTheme.isLandscape;
          return Checkbox(
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            value: checked,
            onChanged: (bool? newVal) =>
                authModel.setCheckedPrivacyPolicy(newValue: newVal),
            checkColor: loginTheme.checkColor ??
                (checked
                    ? (isLandscape ? Colors.white : loginTheme.backgroundColor)
                    : activeColor),
            side: BorderSide(
              color: loginTheme.borderColor ?? activeColor,
              width: 1.5,
            ),
            fillColor: MaterialStateProperty.all<Color>(
              loginTheme.fillColor ?? activeColor,
            ),
          );
        },
      );

  Future<void> _launchUrl(String url) async {
    if (!await launchUrl(Uri.parse(url))) {
      throw Exception('Could not launch $url');
    }
  }
}

class _ActionButton extends StatelessWidget {
  final GlobalKey<FormState> formKey;

  const _ActionButton({
    Key? key,
    required this.formKey,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final loginTheme = context.watch<LoginTheme>();
    final loginTexts = context.read<LoginTexts>();
    final provider = Provider.of<AuthProvider>(context);
    // final isAnimatedLogin =
    //     context.select<Auth, bool>((Auth auth) => auth.isAnimatedLogin);
    final isLandscape = loginTheme.isLandscape;
    return Padding(
      padding: loginTheme.actionButtonPadding ??
          EdgeInsets.symmetric(vertical: _customSpace(context, isLandscape)),
      child: RoundedButton(
        buttonText: loginTexts.login,
        onPressed: () async {
          await provider.action(
            context: context,
            formKey: formKey,
          );
          provider.setTextButtonLoading(false);
        },
        backgroundColor: isLandscape ? Colors.red.shade700 : Colors.white,
        buttonStyle: loginTheme.actionButtonStyle,
      ),
    );
  }

  double _customSpace(BuildContext context, bool isLandscape) {
    var factor = 2;
    if (isLandscape) {
      factor = 3;
    }
    return DynamicSize(context).height * factor;
  }
}

class _FormTitle extends StatelessWidget {
  const _FormTitle({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final loginTexts = context.read<LoginTexts>();
    final loginTheme = context.watch<LoginTheme>();
    return Padding(
      padding: loginTheme.formTitlePadding ?? EdgeInsets.only(bottom: 50),
      child: BaseText(
        loginTexts.loginFormTitle,
        style: TextStyles(context)
            .titleStyle(color: loginTheme.isLandscape ? punchRed : Colors.white)
            .merge(loginTheme.formTitleStyle),
      ),
    );
  }
}

class _Form extends StatefulWidget {
  final GlobalKey<FormState> formKey;
  final String password;
  final String email;
  const _Form(
      {Key? key,
      required this.formKey,
      required this.password,
      required this.email})
      : super(key: key);

  @override
  State<_Form> createState() => _FormState();
}

class _FormState extends State<_Form> {
  final FocusNode _confirmPasswordFocus = FocusNode();

  late Auth auth;

  @override
  void dispose() {
    _confirmPasswordFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    auth = context.read<Auth>();
    final loginTheme = context.watch<LoginTheme>();
    final dynamicSize = DynamicSize(context);
    return Padding(
      padding: loginTheme.formPadding ??
          EdgeInsets.symmetric(vertical: dynamicSize.height * 2),
      child: Form(
        key: auth.formKey,
        child: Wrap(
          direction: Axis.vertical,
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: context.read<LoginTheme>().formElementsSpacing ??
              dynamicSize.height * (loginTheme.isLandscape ? 2.2 : 1.2),
          children: _formElements(auth, loginTheme),
        ),
      ),
    );
  }

  List<Widget> _formElements(Auth auth, LoginTheme loginTheme) {
    final loginTexts = context.read<LoginTexts>();
    final isAnimatedLogin =
        context.select<Auth, bool>((Auth auth) => auth.isAnimatedLogin);
    final authProvider = context.read<AuthProvider>();
    return <Widget>[
      if (!isAnimatedLogin && auth.signUpMode != SignUpModes.confirmPassword)
        CustomTextFormField(
          controller: auth.nameController,
          hintText: loginTexts.nameHint,
          prefixIcon: Icons.person_outline,
          prefixWidget: loginTheme.nameIcon,
          validator: auth.nameValidator,
          
          textInputAction: TextInputAction.next,
          onChanged: (value) {
            auth.setUsername(newUsername: value!);
          },
          autofillHints: const <String>[
            AutofillHints.username,
            AutofillHints.newUsername,
            AutofillHints.name,
          ],
          textInputType: TextInputType.name,
        ),
      CustomTextFormField(
        controller: auth.emailController,
        hintText: auth.isSignup
            ? loginTexts.signupEmailHint
            : loginTexts.loginEmailHint,
        prefixIcon: Icons.email_outlined,
        prefixWidget: loginTheme.emailIcon,
        validator: auth.emailValidator,
        textInputAction: TextInputAction.next,
        onChanged: (value) {
          auth.setEmail(newEmail: value!);
        },
        autofillHints: const <String>[AutofillHints.email],
        textInputType: TextInputType.emailAddress,
      ),
      ObscuredTextFormField(
        controller: auth.passwordController,
        hintText: auth.isSignup
            ? loginTexts.signupPasswordHint
            : loginTexts.loginPasswordHint,
        prefixIcon: Icons.password_outlined,
        showPasswordVisibility: auth.showPasswordVisibility,
        textInputAction:
            auth.isSignup ? TextInputAction.next : TextInputAction.done,
        onFieldSubmitted: (_) {
            authProvider.action(
            context: context,
            formKey: widget.formKey,
          ) ;},
        onChanged: (value) {
          auth.setPassword(newPassword: value!);
        },
        validator: auth.passwordValidator,
      ),
      if (!isAnimatedLogin && auth.signUpMode != SignUpModes.name)
        ObscuredTextFormField(
          controller: auth.confirmPasswordController,
          hintText: loginTexts.confirmPasswordHint,
          prefixIcon: Icons.password_outlined,
          showPasswordVisibility: auth.showPasswordVisibility,
          onFieldSubmitted: (_) {
            authProvider;
          },
          focusNode: _confirmPasswordFocus,
          onChanged: auth.setConfirmPassword,
          validator: auth.passwordValidator,
        ),
    ];
  }
}

