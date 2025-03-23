import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:paged_datatable/paged_datatable.dart';
import 'package:provider/provider.dart';
import 'package:punch/models/myModels/userModel.dart';
import 'package:punch/models/myModels/userRecordModel.dart';
import 'dart:html' as html;
import 'package:punch/models/myModels/web_socket_manager.dart';
import 'package:punch/providers/auth.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:punch/src/const.dart';
import 'package:punch/src/routes.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthProvider with ChangeNotifier {
  SharedPreferences? prefs;
  final _storage = const FlutterSecureStorage();
  User? _user;

  bool _isRowsSelected = false; // Default value
  bool get isRowsSelected => _isRowsSelected;
  bool _loading = false; // Default value

  bool get loading => _loading;
  set loading(bool value) {
    _loading = value;
    notifyListeners();
  }
  
  String? _query;
  String? get query => _query;

  void setQuery(String? newQuery) {
    if (_query != newQuery) {
      _query = newQuery;
      notifyListeners();
    }
  }


  late WebSocketManager _webSocketManager;

  bool _isEditing = false;
  bool get isEditing => _isEditing;

  bool _updateLoading = false;
  bool get updateloading => _updateLoading;

  set isEditing(bool newValue) {
    _isEditing = newValue;
    notifyListeners();
  }

  String? _token;
  bool _isLoadingAuth = false; // Add loading state

  bool get isAuthenticated => _token != null;
  bool get isLoadingAuth => _isLoadingAuth;

  Future<void> _initializeAuth() async {
    prefs = await SharedPreferences.getInstance();
    _isLoadingAuth = true;

    _token = await _storage.read(key: 'auth_token');

    // Retrieve user if exists
    final userJson = prefs?.getString('user');
    if (userJson != null) {
      _user = User.fromJson(jsonDecode(userJson));
    }

    _isLoadingAuth = false;
    print("done");
    notifyListeners();
  }

  late WebSocketManager _userRecordManager;
  setBoolValue(bool newValue) {
    _isRowsSelected = newValue;
    notifyListeners();
  }

  List<User> _users = [];
  late WebSocketChannel channel;
  List<User> get users => _users;
  Map<int, List<UserRecord>> userRecordsMap = {};

  bool _validateEmail = false;
  bool _validatePassword = false;

  bool _textButtonLoading = false;
  bool get textButtonLoading => _textButtonLoading;

  void setTextButtonLoading(bool value) {
    if (_textButtonLoading != value) {
      _textButtonLoading = value;

      notifyListeners();
    }
  }

  bool get validateEmail => _validateEmail;
  bool get validatePassword => _validatePassword;

  void setValidationStatus(
      {required bool email, required bool password, required bool loading}) {
    if (_textButtonLoading != loading) {
      _textButtonLoading = loading;
    }
    _validateEmail = email;
    _validatePassword = password;
    notifyListeners();
  }

  String? _errorMessage;
  String? get errorMessage => _errorMessage;
  void setErrorMessage(String errorMessage) {
    _errorMessage = errorMessage;
    notifyListeners();
  }

  final tableController = PagedDataTableController<String, User>();

  AuthProvider() {
    _initializeAuth();
    _initialize();
    //channel = WebSocketChannel.connect(Uri.parse(Const.authChannel));

    _initializeWebSocket();
  }

  void _initializeWebSocket() {
    _webSocketManager = WebSocketManager(
      Const.authChannel,
      _handleWebSocketMessage,
      _reconnectWebSocket,
    );
    _webSocketManager.connect();

    _userRecordManager = WebSocketManager(
      Const.userRecordChannel,
      _handleUserRecordWebSocketMessage,
      _reconnectUserRecordWebSocket,
    );
    _userRecordManager.connect();
  }

  void _reconnectWebSocket() {}

  void _reconnectUserRecordWebSocket() {}

  void _handleWebSocketMessage(dynamic message) async {
    final type = message['type'];
    final data = message['data'];

    switch (type) {
      case 'ADD':
        final newUser = User.fromJson(data);
        if (newUser != null) {
          _users.add(newUser);
          tableController.insert(newUser);
          tableController.refresh();
          notifyListeners();
        } else {}
        break;

      case 'UPDATE':
        try {
          final index = _users.indexWhere((a) => a.id == data['_id']);
          if (index != -1) {
            _users[index] = User.fromJson(data);
            tableController.refresh();
            tableController.replace(index, _users[index]);

            notifyListeners();
          }
        } catch (e) {}
        break;

      case 'DELETE':
        final idToDelete = data;
        final userToRemove = _users.firstWhere(
          (a) => a.id == idToDelete,
          orElse: () {
            throw Exception('User not found for id: $idToDelete');
          },
        );
        if (userToRemove != null) {
          _users.remove(userToRemove);

          tableController.removeRow(userToRemove);
          tableController.refresh();
        } else {}
        notifyListeners();
        break;
    }
  }

  void _handleUserRecordWebSocketMessage(dynamic message) async {
    final type = message['type'];
    final data = message['data'];

    switch (type) {
      case 'ADD':
        final newRecord = UserRecord.fromJson(data);
        _addUserRecord(newRecord);
        notifyListeners();
        break;

      case 'DELETE':
        _deleteUserRecord(int.tryParse(data));
        notifyListeners();
        break;
    }
  }

  void _deleteUserRecord(int? staffNo) {
    if (userRecordsMap.containsKey(staffNo)) {
      // Remove all records associated with the staffNo
      userRecordsMap.remove(staffNo);
    } else {}
    notifyListeners();
  }

  void _addUserRecord(UserRecord userRecord) {
    if (userRecord.staffNo != null) {
      if (!userRecordsMap.containsKey(userRecord.staffNo!)) {
        userRecordsMap[userRecord.staffNo!] = [];
      }
      userRecordsMap[userRecord.staffNo!]!.add(userRecord);
    }
    notifyListeners();
  }

  Future<void> _initialize() async {
    _checkToken();
    fetchUsers();
    fetchUsersRecord(); // Temporarily comment out to isolate
  }

  Future<void> fetchUsers() async {
    try {
      final response = await http.get(Uri.parse(Const.userUrl));
      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);
        _users = data.map((json) => User.fromJson(json)).toList();
        notifyListeners();
      } else {
        throw Exception('Failed to load users');
      }
    } catch (error) {
      // Optionally rethrow or handle the error
      throw error;
    }
  }

// Fetch user records and store them in the map
  Future<void> fetchUsersRecord() async {
    try {
      final response = await http.get(Uri.parse(Const.userRecordUrl));
      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);

        userRecordsMap.clear();

        for (var json in data) {
          final userRecord = UserRecord.fromJson(json);
          if (userRecord.staffNo != null) {
            userRecordsMap
                .putIfAbsent(userRecord.staffNo!, () => [])
                .add(userRecord);
          }
        }

        notifyListeners();
      } else {
        throw Exception('Failed to load user records: ${response.body}');
      }
    } catch (error) {
      throw error;
    }
  }

  List<UserRecord>? getUserRecordsByStaffNo(int? staffNo) {
    return userRecordsMap[staffNo];
  }

  void addOrUpdateUserRecord(UserRecord userRecord) {
    if (userRecord.staffNo != null) {
      userRecordsMap.putIfAbsent(userRecord.staffNo!, () => []).add(userRecord);
      notifyListeners();
    }
  }

  User? get user => _user;
  void setUser(User user) {
    _user = user;
    notifyListeners();
  }

  Future<void> saveToken(String token) async {
    await _storage.write(key: 'auth_token', value: token);
    _token = token;
    notifyListeners();
  }

  Future<String?> getToken() async {
    _token = await _storage.read(key: 'auth_token');
    return _token;
  }

  Future<void> removeToken() async {
    await _storage.delete(key: 'auth_token');
    _token = null;
    notifyListeners();
  }

  Future<void> _checkToken() async {
    final tk = await _storage.read(key: 'auth_token');
    if (tk == null) {
      return;
    }

    final response = await http.post(
      Uri.parse(Const.validateTokenUrl),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'token': _token}),
    );

    if (response.statusCode != 200) {
      return;
    }

    final data = json.decode(response.body);

    if (data['isValid']) {
      final userJson = data['user'];
      _user = User.fromJson(userJson);
    }
  }

  Future<void> action({
    required BuildContext context,
    required GlobalKey<FormState> formKey,
  }) async {
    final loginFormProvider = Provider.of<Auth>(context, listen: false);
    prefs = await SharedPreferences.getInstance();
    final loginUrl = Uri.parse(Const.authUrl);

    setValidationStatus(email: true, password: true, loading: true);
    FocusManager.instance.primaryFocus?.unfocus();

    try {
      // ✅ Validate form before sending request
      if (!formKey.currentState!.validate()) {
        throw Exception("Validation failed");
      }

      final response = await http
          .post(
        loginUrl,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': loginFormProvider.email,
          'password': loginFormProvider.password,
        }),
      )
          .timeout(const Duration(seconds: 30), onTimeout: () {
        throw Exception("Login request timed out");
      });

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final user = User.fromJson(responseData['user']);
        final token = responseData['token'];
        context.go(AppRoutePath.anniversary);
        await saveToken(token);
        await prefs?.setString('user', jsonEncode(user.toJson()));
        _user = user;
        await _storeUserRecord(_user!);
        notifyListeners();
      } else {
        // ✅ Handle server error responses properly
        final errorResponse = jsonDecode(response.body);
        throw Exception(errorResponse['message'] ?? "Login failed");
      }
    } catch (error) {
      print("Login Error: $error");
      Fluttertoast.showToast(
        msg: error.toString(),
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    } finally {
      formKey.currentState?.reset();
      setValidationStatus(email: false, password: false, loading: false);
    }
  }

  Future<void> _storeUserRecord(User user) async {
    final userRecordUrl = Uri.parse(Const.userRecordUrl);
    final computerName = await getDeviceName();

    if (user.id == null) {
      return;
    }

    final userRecord = UserRecord(
      staffNo: user.staffNo,
      loginDateTime: DateTime.now().toUtc(),
      computerName: computerName,
    );

    try {
      final response = await http.post(
        userRecordUrl,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${user.token}',
        },
        body: jsonEncode(userRecord.toJson()),
      );

      if (response.statusCode != 201) {
        throw Exception('Failed to store user record');
      } else {}
    } catch (error) {}
  }

  Future<void> logout(BuildContext context) async {
    Navigator.of(context).pop();
    if (GoRouter.of(context).canPop()) {
      Navigator.of(context).pop();
    }
    await Future.delayed(const Duration(milliseconds: 500));
    _user = null;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove('user');
    await removeToken();
    notifyListeners();

    // Clear cookies if on web
    if (kIsWeb) {
      clearCookies();
      clearLocalStorage();
      html.window.location.reload();
    }
  }

  void clearLocalStorage() {
    html.window.localStorage.clear();
  }

  void clearCookies() {
    final cookies = html.document.cookie?.split(';') ?? [];
    for (final cookie in cookies) {
      final eqPos = cookie.indexOf('=');
      final name = eqPos > 0 ? cookie.substring(0, eqPos) : cookie;
      html.document.cookie = '$name=;expires=Thu, 01 Jan 1970 00:00:00 GMT';
    }
  }

  Future<String> getDeviceName() async {
    final deviceInfo = DeviceInfoPlugin();
    final webInfo = await deviceInfo.webBrowserInfo;

    // Get IP address using an external API
    String ipAddress = 'Unknown';
    try {
      final response =
          await http.get(Uri.parse('https://api.ipify.org?format=json'));
      if (response.statusCode == 200) {
        ipAddress = jsonDecode(response.body)['ip'];
      }
    } catch (e) {
      // Handle errors or exceptions
    }

    return '''
    Browser: ${webInfo.browserName.name}
    Platform: ${webInfo.platform}
    IP Address: $ipAddress
  ''';
  }

  Future<bool> updateUser(User user, BuildContext context) async {
    _updateLoading = true;
    notifyListeners();
    try {
      final response = await http.patch(
        Uri.parse('${Const.userUrl}/${user.id}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(user.toJson()),
      );
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User updated successfully!')),
        );

        return true;
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update user ')),
        );
        return false;
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update user ')),
      );

      return false;
    } finally {
      _updateLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteSelectedUsers(
      BuildContext context, List<User> selectedUsers) async {
    try {
      for (var user in selectedUsers) {
        deleteUser(context, user);
      }

      notifyListeners();
    } catch (error) {
      print(error.toString());
    }
  }

  Future<void> deleteUser(BuildContext context, User duser) async {
    try {
      final userResponse =
          await http.delete(Uri.parse('${Const.userUrl}/${duser.id}'));
      final userRecordResponse = await http
          .delete(Uri.parse('${Const.userRecordUrl}/${duser.staffNo}'));

      if (userResponse.statusCode == 200 &&
          userRecordResponse.statusCode == 200) {
        if (GoRouter.of(context).canPop()) {
       Future.delayed(Duration.zero, () {
            GoRouter.of(context).pop();
          });
        }
        if (context.mounted) {
          // ✅ Prevents accessing a disposed widget
          Fluttertoast.showToast(
            msg: "User deleted successfully",
            toastLength: Toast.LENGTH_LONG,
            gravity: ToastGravity.BOTTOM,
            backgroundColor: Colors.green,
            textColor: Colors.white,
          );
        }
      } else {
        throw Exception(
            'Failed to delete user: ${userResponse.body}, ${userRecordResponse.body}');
      }
    } catch (error) {
      debugPrint("Error deleting user: $error");
      if (context.mounted) {
        Fluttertoast.showToast(
          msg: 'Error deleting user: $error',
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.red,
          textColor: Colors.white,
        );
      }
    }
  }

  UserRole? _selectedUserRole;
  UserRole? get selectedUserRole => _selectedUserRole;
  set selectedUserRole(UserRole? value) {
    _selectedUserRole = value;
    notifyListeners();
  }

  Future<void> addUser(
    User user,
    List<TextEditingController> controllers,
  ) async {
    try {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        loading = true;
      });
      final response = await http.post(
        Uri.parse(Const.userUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(user.toJson()),
      );

      if (response.statusCode == 201) {
        Fluttertoast.showToast(
          msg: "User added successfully!",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.green,
          textColor: Colors.white,
        );

        for (var controller in controllers) {
          controller.clear();
        }

        SchedulerBinding.instance.addPostFrameCallback((_) {
          selectedUserRole = null;
        });
      } else {
        throw Exception(response.body);
      }
    } catch (error) {
      Fluttertoast.showToast(
        msg: error.toString(),
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    } finally {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        loading = false;
      });
    }
  }
}
