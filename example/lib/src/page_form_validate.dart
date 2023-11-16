import 'dart:async';

import 'package:flutter/material.dart';
import 'package:form_floating_action_button/form_floating_action_button.dart';

class PageFormValidate extends StatefulWidget {
  const PageFormValidate({
    super.key,
  });

  @override
  State createState() => _PageFormValidate();
}

class _PageFormValidate extends State<PageFormValidate> {
  final FormFloatingActionButtonController _controller =
      FormFloatingActionButtonController();
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    return Form(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Form Validate'),
        ),
        body: Material(
          child: ListView(
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Email',
                  ),
                  onFieldSubmitted: (_) {
                    _controller.firePressed();
                  },
                  validator: (value) {
                    String? error;
                    if (value?.isNotEmpty != true) {
                      error = 'Email is required';
                    } else if (value!.contains('@') != true ||
                        value.contains('.') != true) {
                      error = 'Email is not valid';
                    }

                    return error;
                  },
                ),
              ),
            ],
          ),
        ),
        floatingActionButton: FormFloatingActionButton(
          controller: _controller,
          loading: _loading,
          onSubmit: () {
            setState(() => _loading = true);
            Future.delayed(const Duration(seconds: 5)).then((_) {
              if (mounted) {
                setState(() {
                  _loading = false;
                });
              }
            });
          },
        ),
      ),
    );
  }
}
