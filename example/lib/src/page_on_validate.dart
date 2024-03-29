import 'package:flutter/material.dart';
import 'package:form_floating_action_button/form_floating_action_button.dart';

class PageOnValidate extends StatefulWidget {
  const PageOnValidate({
    super.key,
  });

  @override
  State createState() => _PageOnValidateState();
}

class _PageOnValidateState extends State<PageOnValidate> {
  bool _loading = false;
  bool _validateSuccess = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('On Validate'),
      ),
      body: Material(
        child: ListView(
          children: <Widget>[
            ListTile(
              onTap: () {
                setState(() => _validateSuccess = !_validateSuccess);
              },
              title: const Text('Validation Successful'),
              trailing: IgnorePointer(
                child: Switch(
                  value: _validateSuccess,
                  onChanged: (_) {},
                ),
              ),
            )
          ],
        ),
      ),
      floatingActionButton: FormFloatingActionButton(
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
        onValidate: () {
          return Future.value(_validateSuccess);
        },
      ),
    );
  }
}
