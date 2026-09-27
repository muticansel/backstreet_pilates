import 'package:flutter/material.dart';

Future<void> showDemoFeedback(BuildContext context, {required bool isSignup}) {
  return showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Your form is ready'),
      content: Text(isSignup
          ? 'The signup details passed the form checks. This preview does not create an account.'
          : 'The login details passed the form checks. This preview does not sign you in.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Keep exploring'),
        )
      ],
    ),
  );
}
