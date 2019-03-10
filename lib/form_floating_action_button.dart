library form_floating_action_button;

import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' as v;

class FormFloatingActionButton extends StatefulWidget {
  FormFloatingActionButton({
    this.color,
    FormFloatingActionButtonController controller,
    this.duration = const Duration(milliseconds: 500),
    this.errorColor = Colors.red,
    this.errorIcon = Icons.close,
    this.icon = Icons.arrow_forward,
    this.isExtended = false,
    Key key,
    this.loading = false,
    this.onSubmit,
    this.onValidate,
  })  : assert(duration != null),
        assert(duration.inMilliseconds > 0),
        assert(errorColor != null),
        assert(errorIcon != null),
        assert(icon != null),
        this.controller = controller,
        super(key: key);

  final Color color;
  final FormFloatingActionButtonController controller;
  final Duration duration;
  final Color errorColor;
  final IconData errorIcon;
  final IconData icon;
  final bool isExtended;
  final bool loading;
  final VoidCallback onSubmit;
  final ValueGetter<Future<bool>> onValidate;

  @override
  _FormFloatingActionButtonState createState() =>
      _FormFloatingActionButtonState();
}

class _FormFloatingActionButtonState extends State<FormFloatingActionButton>
    with SingleTickerProviderStateMixin {
  final List<StreamSubscription> _subscriptions = [];
  StreamController<double> _animationStreamController =
      StreamController<double>.broadcast();
  AnimationController _controller;
  FormFloatingActionButtonController _formFabController;
  Color _fabColor;
  Key _keyError = UniqueKey();
  Key _keyLoading = UniqueKey();
  Key _keyStandard = UniqueKey();

  @override
  void initState() {
    super.initState();

    _formFabController =
        widget.controller ?? FormFloatingActionButtonController();

    _subscriptions.add(_formFabController.addPressedListener((_) {
      if (widget.loading != true && widget.onSubmit != null) {
        _buttonPressed();
      }
    }));

    _subscriptions.add(_formFabController.addErrorListener((_) {
      _controller.reset();
      _controller.forward();
      _formFabController.state = FormFloatingActionButtonErrorState.START;
    }));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    _fabColor = widget.color ?? Theme.of(context).accentColor;
    _controller?.dispose();

    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..addListener(() => _animationStreamController.add(_controller.value));

    _controller.addStatusListener((status) {
      if (AnimationStatus.completed == status) {
        _formFabController.state = FormFloatingActionButtonErrorState.COMPLETE;
      }
    });

    Animation startColor = ColorTween(
      begin: widget.color,
      end: widget.errorColor,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Interval(0.0, 0.2),
      ),
    );
    startColor.addListener(() {
      _fabColor = startColor.value;
    });

    Animation endColor = ColorTween(
      begin: widget.errorColor,
      end: widget.color,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Interval(0.8, 1.0),
      ),
    );
    endColor.addListener(() {
      _fabColor = endColor.value;
    });
  }

  @override
  void dispose() {
    _animationStreamController.close();
    _controller?.dispose();
    _subscriptions?.forEach((stream) => stream.cancel());

    super.dispose();
  }

  Future<void> _buttonPressed() async {
    bool valid = true;
    if (widget.onValidate != null) {
      valid = await widget.onValidate();
    }

    if (valid == true) {
      widget.onSubmit();
    } else {
      _formFabController.fireError();
    }
  }

  /// Logic here originated in the answer by [peopletookallthegoodnames] which
  /// can be viewed here:
  ///
  /// https://stackoverflow.com/questions/49609296/flipping-and-shaking-of-tile-animation-using-flutter-dart
  v.Vector3 _getTranslation() {
    double progress = _controller?.value ?? 0;
    double offset = sin(progress * pi * 5);

    offset *= 12;
    return v.Vector3(offset, 0.0, 0.0);
  }

  Widget _buildButtonChild(BuildContext context) {
    Widget child;
    if (widget.loading == true) {
      child = CircularProgressIndicator(
        key: _keyLoading,
        strokeWidth: 2.0,
        valueColor: AlwaysStoppedAnimation(Colors.white),
      );
    } else if (_controller == null ||
        _controller.value == 0 ||
        _controller.value == 1) {
      child = Icon(
        widget.icon,
        key: _keyStandard,
      );
    } else {
      child = Icon(
        widget.errorIcon,
        key: _keyError,
      );
    }
    return child;
  }

  @override
  Widget build(BuildContext context) {
    Duration switchDuration =
        Duration(milliseconds: widget.duration.inMilliseconds ~/ 5);

    return StreamBuilder<double>(
      initialData: 0.0,
      stream: _animationStreamController.stream,
      builder: (context, snapshot) {
        return Transform(
          transform: Matrix4.translation(_getTranslation()),
          child: FloatingActionButton(
            backgroundColor: _fabColor,
            isExtended: widget.isExtended,
            onPressed: widget.loading == true || widget.onSubmit == null
                ? null
                : () => _buttonPressed(),
            child: AnimatedSwitcher(
              duration: switchDuration,
              child: _buildButtonChild(context),
            ),
          ),
        );
      },
    );
  }
}

class FormFloatingActionButtonController {
  final StreamController<bool> _errorController =
      StreamController<bool>.broadcast();
  final StreamController<FormFloatingActionButtonErrorState>
      _errorStateController =
      StreamController<FormFloatingActionButtonErrorState>.broadcast();
  final StreamController<bool> _pressedController =
      StreamController<bool>.broadcast();

  set state(FormFloatingActionButtonErrorState state) {
    _errorStateController.add(state);
  }

  StreamSubscription<bool> addErrorListener(void listener(bool event)) {
    return _errorController.stream.listen(listener);
  }

  StreamSubscription<FormFloatingActionButtonErrorState> addErrorStateListener(
      void listener(FormFloatingActionButtonErrorState event)) {
    return _errorStateController.stream.listen(listener);
  }

  StreamSubscription<bool> addPressedListener(void listener(bool event)) {
    return _pressedController.stream.listen(listener);
  }

  void dispose() {
    _errorController.close();
    _errorStateController.close();
    _pressedController.close();
  }

  void fireError() {
    _errorController.add(true);
  }

  void firePressed() {
    _pressedController.add(true);
  }
}

enum FormFloatingActionButtonErrorState {
  COMPLETE,
  START,
}
