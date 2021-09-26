import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' as v;

/// A special FAB that has functionality that supports [Form] interactions.  For
/// example, if the [Form] validation failed, the FAB has a shake animation with
/// transitions to an error state and back.  If the [Form] validation was
/// successful, the FAB has a loading state.
///
/// To disable the FAB, set the [onSubmit] to `null`.  If [onSubmit] is a valid
/// callback then the FAB follows a specific sequence of events when pressed.
/// First, it will attempt to call [onValidate].  If [onValidate] is `null`,
/// this will search for a [Form] on the widget tree and call the [validate]
/// method in that form widget.  If either return [false], indicating an error
/// is present, the FAB will transition to an error state and back.  If the
/// [onValidate] or [Form.validate] returns [true] (or [onValidate] there is no
/// [onValidate] or [Form]), then the FAB will call [onSubmit].
///
/// If the submit is asynchronous, the FAB supports setting the [loading] to
/// [true], which triggers a loading state that informs the user that a loading
/// action is being performed and the FAB will ignore all further press events.
///
/// An optional [controller] may be sent in to listen for the error transition
/// states as well as optionally firing both the pressed and error events to the
/// FAB.
class FormFloatingActionButton extends StatefulWidget {
  FormFloatingActionButton({
    this.color,
    this.controller,
    this.duration = const Duration(milliseconds: 500),
    this.errorColor = Colors.red,
    this.errorIcon = Icons.close,
    this.icon = Icons.arrow_forward,
    Key? key,
    this.loading = false,
    this.onSubmit,
    this.onValidate,
  })  : assert(duration.inMilliseconds > 0),
        super(key: key);

  /// Background color of the FAB for the default / steady state.  If not set
  /// this will default to the accent color of the current [Theme].
  final Color? color;

  /// Optional controller to be able to listen for error state events as well as
  /// firing pressed and error events directly.
  final FormFloatingActionButtonController? controller;

  /// Duration for the error transition.
  final Duration duration;

  /// Background color of the FAB when in an error state.
  final Color errorColor;

  /// Icon to display when the FAB is in an error state.
  final IconData errorIcon;

  /// Icon to display when the FAB is in the default / steady state.
  final IconData icon;

  /// Set to [true] if the FAB should ignore all further pressed events and
  /// should display a loading indicator.  Both [false] or `null` will be
  /// treated the same.
  final bool loading;

  /// Set to a `null` value to disable pressed events for the FAB.  Set to a
  /// valid callback function to be called when the FAB is pressed and
  /// validation is successful.
  ///
  /// If [loading] is set to [true], this value will be ignored.
  final VoidCallback? onSubmit;

  /// Set to a `null` value to disable validation and treat all pressed events
  /// as if they passed validation.  Set to a callback to perform validation on
  /// pressed events before calling [onSubmit].
  ///
  /// A return value of [true] states that validation was successful.  A return
  /// value of [faluse] states that an error was detected by the validation
  /// function and that [onSubmit] must not be called.
  final ValueGetter<Future<bool>>? onValidate;

  @override
  _FormFloatingActionButtonState createState() =>
      _FormFloatingActionButtonState();
}

class _FormFloatingActionButtonState extends State<FormFloatingActionButton>
    with SingleTickerProviderStateMixin {
  final StreamController<double> _animationStreamController =
      StreamController<double>.broadcast();
  final Key _keyError = UniqueKey();
  final Key _keyLoading = UniqueKey();
  final Key _keyStandard = UniqueKey();
  final List<StreamSubscription> _subscriptions = [];

  AnimationController? _controller;
  Color? _fabColor;
  late FormFloatingActionButtonController _formFabController;

  @override
  void initState() {
    super.initState();

    _formFabController =
        widget.controller ?? FormFloatingActionButtonController();

    _subscriptions.add(_formFabController.addPressedListener((_) {
      if (widget.loading != true && widget.onSubmit != null) {
        _buttonPressed(context);
      }
    }));

    _subscriptions.add(_formFabController.addErrorListener((_) {
      _controller!.reset();
      _controller!.forward();
      _formFabController.state = FormFloatingActionButtonErrorState.START;
    }));

    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..addListener(() => _animationStreamController.add(_controller!.value));

    _controller!.addStatusListener((status) {
      if (AnimationStatus.completed == status) {
        _formFabController.state = FormFloatingActionButtonErrorState.COMPLETE;
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    _fabColor = widget.color ?? Theme.of(context).colorScheme.secondary;

    Animation startColor = ColorTween(
      begin: widget.color,
      end: widget.errorColor,
    ).animate(
      CurvedAnimation(
        parent: _controller!,
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
        parent: _controller!,
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
    _subscriptions.forEach((stream) => stream.cancel());

    super.dispose();
  }

  Future<void> _buttonPressed(BuildContext context) async {
    var valid = true;
    if (widget.onValidate != null) {
      valid = await widget.onValidate!();
    } else {
      var formState = Form.of(context);
      if (formState != null) {
        valid = formState.validate();
      }
    }

    if (valid == true) {
      widget.onSubmit!();
    } else {
      _formFabController.fireError();
    }
  }

  /// Logic here originated in the answer by [peopletookallthegoodnames] which
  /// can be viewed here:
  ///
  /// https://stackoverflow.com/questions/49609296/flipping-and-shaking-of-tile-animation-using-flutter-dart
  v.Vector3 _getTranslation() {
    var progress = _controller?.value ?? 0;
    var offset = sin(progress * pi * 5);

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
        _controller!.value == 0 ||
        _controller!.value == 1) {
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
    var switchDuration =
        Duration(milliseconds: widget.duration.inMilliseconds ~/ 5);

    return StreamBuilder<double>(
      initialData: 0.0,
      stream: _animationStreamController.stream,
      builder: (context, snapshot) {
        return Transform(
          transform: Matrix4.translation(_getTranslation()),
          child: FloatingActionButton(
            backgroundColor: _fabColor,
            onPressed: widget.loading == true || widget.onSubmit == null
                ? null
                : () => _buttonPressed(context),
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

  /// Adds a listener for when an error is triggered within the FAB.  This can
  /// be used by outer widgets to be notified that the FAB failed validation.
  StreamSubscription<bool> addErrorListener(
      void Function(bool event) listener) {
    return _errorController.stream.listen(listener);
  }

  /// Adds an error state listener for the FAB.  This can be used to detect when
  /// the FAB begins the error animation as well as when it completes the error
  /// transition.
  ///
  /// A potential use case could be that a wrapping widget may want to disable
  /// inputs during the error animation and only re-enable the form fields once
  /// the animation is complete.
  StreamSubscription<FormFloatingActionButtonErrorState> addErrorStateListener(
      void Function(FormFloatingActionButtonErrorState event) listener) {
    return _errorStateController.stream.listen(listener);
  }

  /// Adds a listener for when the pressed events happen within the FAB.  This
  /// is used internally by the FAB.  It's not recommended that external widgets
  /// add these listeners as these will be fired regardless of validation
  /// status.
  StreamSubscription<bool> addPressedListener(
      void Function(bool event) listener) {
    return _pressedController.stream.listen(listener);
  }

  /// Disposes the controller and frees up all associated resources.  This
  /// should be called in the [dispose] function for the owing [State] object.
  void dispose() {
    _errorController.close();
    _errorStateController.close();
    _pressedController.close();
  }

  /// Fires an error to the FAB.  This will trigger the error transition and
  /// shaking.  This should be called from places like a [Form] validation or
  /// [TextFormField] via [onFieldSubmitted] or other submit-esque function
  /// within your widget.
  void fireError() {
    _errorController.add(true);
  }

  /// Fires the pressed state for the FAB.  This will trigger the FAB to act as
  /// if the user had pressed the button via the UI.  The full validation cycle
  /// will be executed and if validation passes, the [onSubmit] will ultimately
  /// be called.
  void firePressed() {
    _pressedController.add(true);
  }
}

enum FormFloatingActionButtonErrorState {
  COMPLETE,
  START,
}
