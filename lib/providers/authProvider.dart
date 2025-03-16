import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:fluttertoast/fluttertoast.dart';
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
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class AuthProvider with ChangeNotifier {
 
  User? _user;
  final StreamController<User?> _userController =
      StreamController<User?>.broadcast();
  Stream<User?> get userStream => _userController.stream;
  bool _isRowsSelected = false; // Default value
  bool get isRowsSelected => _isRowsSelected;
  bool _loading = false; // Default value

  bool get loading => _loading;
  late WebSocketManager _webSocketManager;

  bool _isEditing = false;
  bool get isEditing => _isEditing;

  bool _updateLoading = false;
  bool get updateloading => _updateLoading;

  set isEditing(bool newValue) {
    _isEditing = newValue;
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
    setTextButtonLoading(loading);
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
    _initialize();
    channel = WebSocketChannel.connect(
        Uri.parse(Const.authChannel));

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

  void _reconnectWebSocket() {
    print("reconnected");
  }

  void _reconnectUserRecordWebSocket() {
    print("reconnected user Record");
  }

  void _handleWebSocketMessage(dynamic message) async {
    final type = message['type'];
    final data = message['data'];

    switch (type) {
      case 'ADD':
        print('Received ADD event with data: $data');
        final newUser = User.fromJson(data);
        if (newUser != null) {
          print('Parsed new user: $newUser');
          _users.add(newUser);
          tableController.insert(newUser);
          tableController.refresh();
          print('socket added new User');
          notifyListeners();
        } else {
          print('Failed to parse user from data');
        }
        break;

      case 'UPDATE':
        try {
          final index = _users.indexWhere((a) => a.id == data['_id']);
          print(data);
          if (index != -1) {
            print("hmm");
            _users[index] = User.fromJson(data);
            tableController.refresh();
            tableController.replace(index, _users[index]);

            print('socket updated client');
            notifyListeners();
          }
        } catch (e) {
          print(e);
        }
        break;

      case 'DELETE':
        print('Received DELETE message: $data');
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
          print('socket removed User');
        } else {
          print('User not found for id: $idToDelete');
        }
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
      print('Deleted all UserRecords for staffNo $staffNo');
    } else {
      print('No records found for staffNo $staffNo to delete');
    }
    notifyListeners();
  }

  void _addUserRecord(UserRecord userRecord) {
    if (userRecord.staffNo != null) {
      if (!userRecordsMap.containsKey(userRecord.staffNo!)) {
        userRecordsMap[userRecord.staffNo!] = [];
      }
      userRecordsMap[userRecord.staffNo!]!.add(userRecord);
      print('Added new UserRecord for staffNo ${userRecord.staffNo}');
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

        // Clear the existing map to prevent old data from lingering
        userRecordsMap.clear();

        // Populate the map with the fetched data
        for (var json in data) {
          final userRecord = UserRecord.fromJson(json);
          if (userRecord.staffNo != null) {
            userRecordsMap
                .putIfAbsent(userRecord.staffNo!, () => [])
                .add(userRecord);
          }
        }
        print("userRecord " + userRecordsMap.length.toString());
        // Notify listeners about the change
        notifyListeners();
      } else {
        print(response.body);
        throw Exception('Failed to load user records: ${response.body}');
      }
    } catch (error) {
      print('Error fetching user Record: $error');
      throw error;
    }
  }

// Method to retrieve all records for a particular user
  List<UserRecord>? getUserRecordsByStaffNo(int? staffNo) {
    return userRecordsMap[staffNo];
  }

// Optional: Method to add or update a UserRecord
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

  Future<void> _checkToken() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    String? token = preferences.getString('token');

    if (token == null) {
      _updateUserController(null);
      return;
    }

    final response = await http.post(
      Uri.parse(Const.validateTokenUrl),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'token': token}),
    );

    if (response.statusCode != 200) {
      _updateUserController(null);
      return;
    }

    final data = json.decode(response.body);

    if (data['isValid']) {
      final userJson = data['user'];
      _user = User.fromJson(userJson);
      _updateUserController(_user);
    } else {
      _updateUserController(null);
    }
  }

  void _updateUserController(User? user) {
    _userController.add(user);
    notifyListeners();
  }

  Future<void> action({
    required BuildContext context,
    required GlobalKey<FormState> formKey,
  }) async {
    setTextButtonLoading(true);

    setValidationStatus(email: true, password: true, loading: true);
    FocusManager.instance.primaryFocus?.unfocus();
    try {
      if (formKey.currentState!.validate()) {
        await _loginResult(context: context, formKey: formKey);
      }
    } catch (e) {
      setTextButtonLoading(false);
    } finally {
      setValidationStatus(email: false, password: false, loading: false);
    }
  }

  Future<void> _loginResult({
    required BuildContext context,
    required GlobalKey<FormState> formKey,
  }) async {
    final loginFormProvider = Provider.of<Auth>(context, listen: false);
    final prefs = await SharedPreferences.getInstance();
    final loginUrl = Uri.parse(Const.authUrl);

    try {
      final response = await http.post(
        loginUrl,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'username': loginFormProvider.email,
          'password': loginFormProvider.password,
        }),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final user = User.fromJson(responseData['user']);
        final token = responseData['token'];

        await prefs.setString('token', token);
        await prefs.setString('user', jsonEncode(user.toJson()));
        _user = user;
        _userController.add(_user);

        // Store or update the user record
        await _storeUserRecord(_user!);

        notifyListeners();
      } else {
        _handleLoginError(response);
      }
    } catch (error) {
      _handleLoginException(error);
    } finally {
      formKey.currentState!.reset();
      setTextButtonLoading(false);
    }
  }

  Future<void> _storeUserRecord(User user) async {
    final userRecordUrl = Uri.parse(Const.userRecordUrl);
    final computerName = await getDeviceName();

    // Check if the recordId was correctly parsed
    if (user.id == null) {
      print('Error: null user id.');
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
      } else {
        print('User record stored successfully: ${response.body}');
      }
    } catch (error) {
      print('Error storing user record: $error');
    }
  }

  void _handleLoginError(http.Response response) {
    final responseData = jsonDecode(response.body);
    _errorMessage = 'Failed to sign in';
    _user = null;
    final errorMessage = responseData['message'] ?? 'Unknown error';
    Fluttertoast.showToast(
      msg: errorMessage,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      timeInSecForIosWeb: 1,
      backgroundColor: Colors.black54,
      textColor: Colors.white,
      fontSize: 16.0,
    );
  }

  void _handleLoginException(dynamic error) {
    _errorMessage = 'An error occurred';
    _user = null;
    Fluttertoast.showToast(
      msg: 'An error occurred. Please try again later.',
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.BOTTOM,
      timeInSecForIosWeb: 1,
      backgroundColor: Colors.black54,
      textColor: Colors.white,
      fontSize: 16.0,
    );
    _textButtonLoading = false;
    notifyListeners();
  }

  Future<void> logout(BuildContext context) async {
    Navigator.of(context).pop();
    if (Navigator.canPop(context)) {
      Navigator.of(context).pop();
    }
    await Future.delayed(const Duration(milliseconds: 500));
    _user = null;
    _userController.add(null);
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('user');
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
      print('Failed to get IP address: $e');
    }

    return '''
    Browser: ${webInfo.browserName.name}
    Platform: ${webInfo.platform}
    IP Address: $ipAddress
  ''';
  }

  Future<void> addUser(
    User user,
    List<TextEditingController> controllers,
    void Function() clearSelectedType,
  ) async {
    try {
      _loading = true;
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

        // Clear all controllers
        for (var controller in controllers) {
          controller.clear();
        }
        clearSelectedType();
        notifyListeners();
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
      _loading = false;
    }
  }

  Future<bool> updateUser(
      User user,  BuildContext context) async {
        _updateLoading = true;
         notifyListeners();
    try {
      print("updating" + user.toJson().toString());
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
        print('Failed to update anniversary: ${response.body}');
        return false;
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update user ')),
      );
      print('Error updating user: $error');

      return false;
    }finally{
       _updateLoading = false;
       notifyListeners();
    }
  }

  Future<void> deleteSelectedUsers(
      BuildContext context, List<User> selectedUsers) async {
    try {
      print("selectedClients ${selectedUsers.length.toString()}");
      // Iterate over the selected clients
      for (var user in selectedUsers) {
        // Await the deletion of the client
        deleteUser(context, user);
      }

      // Notify listeners after all deletions are completed
      notifyListeners();
    } catch (error) {
      print('Error deleting selected clients and their extras: $error');
    }
  }

  Future<void> deleteUser(BuildContext context, User duser) async {
    try {
      // Delete the user
      final userResponse = await http.delete(Uri.parse('${Const.userUrl}l/${duser.id}'));
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
      if (userResponse.statusCode == 200) {
        // Show success message for user deletion
        Fluttertoast.showToast(
          msg: "User deleted successfully",
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.green,
          textColor: Colors.white,
        );

        // Attempt to delete associated user records (if present)
        final userRecordResponse =
            http.delete(Uri.parse('${Const.userRecordUrl}/${duser.staffNo}'));

        notifyListeners();
      } else {
        // Log the error body and response status code
        print(
            'Error deleting user: Status ${userResponse.statusCode}, Body: ${userResponse.body}');
        throw Exception('Failed to delete user: ${userResponse.body}');
      }
    } catch (error) {
      // Show error message if any exception occurs
      Fluttertoast.showToast(
        msg: 'Error deleting user: $error',
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
      print('Error deleting user: $error');
      throw error;
    }
  }
}
