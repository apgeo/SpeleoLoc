import 'package:flutter/material.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/utils/localization.dart';

/// Text controllers for the details of one user. The owner disposes them.
class UserDetailsControllers {
  UserDetailsControllers({User? initial})
    : username = TextEditingController(text: initial?.username ?? ''),
      firstName = TextEditingController(text: initial?.firstName ?? ''),
      lastName = TextEditingController(text: initial?.lastName ?? ''),
      details = TextEditingController(text: initial?.details ?? '');

  final TextEditingController username;
  final TextEditingController firstName;
  final TextEditingController lastName;
  final TextEditingController details;

  String get usernameValue => username.text.trim();
  String? get firstNameValue => _optional(firstName);
  String? get lastNameValue => _optional(lastName);
  String? get detailsValue => _optional(details);

  static String? _optional(TextEditingController c) =>
      c.text.trim().isEmpty ? null : c.text.trim();

  void dispose() {
    username.dispose();
    firstName.dispose();
    lastName.dispose();
    details.dispose();
  }
}

/// The fields describing a user, shared by the users settings dialog and the
/// page that asks who is using the app.
class UserDetailsFields extends StatelessWidget {
  const UserDetailsFields({
    super.key,
    required this.controllers,
    this.usernameError,
  });

  final UserDetailsControllers controllers;
  final String? usernameError;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TextField(
          controller: controllers.username,
          decoration: InputDecoration(
            labelText: LocServ.inst.t('username'),
            errorText: usernameError,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controllers.firstName,
          decoration: InputDecoration(labelText: LocServ.inst.t('first_name')),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controllers.lastName,
          decoration: InputDecoration(labelText: LocServ.inst.t('last_name')),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controllers.details,
          decoration: InputDecoration(labelText: LocServ.inst.t('details')),
          maxLines: 3,
        ),
      ],
    );
  }
}
