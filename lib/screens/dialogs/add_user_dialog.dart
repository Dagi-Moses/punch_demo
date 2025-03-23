import 'package:flutter/material.dart';

import 'package:provider/provider.dart';
import 'package:punch/src/color_constants.dart';
import 'package:punch/models/myModels/userModel.dart';
import 'package:punch/providers/authProvider.dart';

class AddUserPage extends StatefulWidget {
  const AddUserPage({super.key});

  @override
  State<AddUserPage> createState() => _AddUserPageState();
}

class _AddUserPageState extends State<AddUserPage> {
  final TextEditingController userNameController = TextEditingController();
  final TextEditingController passWordController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController staffNoController = TextEditingController();
  final TextEditingController loginDateTimeController = TextEditingController();
  final TextEditingController computerNameController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    userNameController.dispose();
    passWordController.dispose();
    lastNameController.dispose();
    firstNameController.dispose();
    staffNoController.dispose();
    loginDateTimeController.dispose();
    computerNameController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: punchRed,
        foregroundColor: Colors.white,
        elevation: 4,
        title: const Text('Add User'),
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 800),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTextField(
                      controller: userNameController,
                      label: "Username",
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a username';
                        }
                        return null;
                      },
                    ),
                    DropdownButtonFormField<UserRole>(
                      value: authProvider.selectedUserRole,
                      onChanged: (UserRole? newValue) {
                        authProvider.selectedUserRole = newValue!;
                      },
                      items: UserRole.values.map((UserRole type) {
                        return DropdownMenuItem<UserRole>(
                          value: type,
                          child: Text(type.name),
                        );
                      }).toList(),
                      decoration: InputDecoration(
                        labelText: "User Role",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    _buildTextField(
                      controller: firstNameController,
                      label: "First Name",
                    ),
                    _buildTextField(
                      controller: lastNameController,
                      label: "Last Name",
                    ),
                    _buildTextField(
                      controller: passWordController,
                      label: "Password",
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a password';
                        }
                        return null;
                      },
                    ),
                    _buildTextField(
                      controller: staffNoController,
                      label: "Staff No",
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return null;
                        }
                        final digitRegex = RegExp(r'^[0-9]+$');
                        if (!digitRegex.hasMatch(value)) {
                          return 'Staff number must be only digits';
                        }
                        return null; // Return
                      },
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(50),
        ),
        onPressed: authProvider.loading
            ? null
            : () async {
                if (_formKey.currentState!.validate()) {
                  final newUser = User(
                    username: userNameController.text,
                    loginId: authProvider.selectedUserRole,
                    firstName: firstNameController.text,
                    lastName: lastNameController.text,
                    password: passWordController.text,
                    staffNo: int.tryParse(staffNoController.text),
                  );
                  authProvider.addUser(
                    newUser,
                    [
                      userNameController,
                      firstNameController,
                      lastNameController,
                      passWordController,
                      staffNoController,
                    ],
                  );
                }
              },
        child: authProvider.loading
            ? const CircularProgressIndicator(color: Colors.white)
            : const Icon(Icons.add),
      ),
    );
  }
}

Widget _buildTextField({
  required TextEditingController controller,
  required String label,
  TextInputType keyboardType = TextInputType.text,
  bool enabled = true,
  String? Function(String?)? validator,
}) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 8.0),
    child: TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      keyboardType: keyboardType,
      enabled: enabled,
      validator: validator,
    ),
  );
}
