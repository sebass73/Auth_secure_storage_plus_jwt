import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Secure Storage POC',
      home: LoginPage(),
    );
  }
}

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FlutterSecureStorage _secureStorage = FlutterSecureStorage();
  String? _token;

  Future<void> login(String username, String password) async {
    const String apiUrl =
        'http://10.0.2.2:3000/login'; // Cambia la URL según tu configuración

    try {
      // Realizar la solicitud POST al backend en Node.js
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'username': username,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final String token = data['token'];

        // Almacenar el JWT en Secure Storage
        await _secureStorage.write(key: 'jwt_token', value: token);
        setState(() {
          _token = token;
        });
      } else {
        print('Error: ${response.body}');
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  Future<void> loadToken() async {
    final token = await _secureStorage.read(key: 'jwt_token');
    setState(() {
      _token = token;
    });
  }

  Future<void> logout() async {
    await _secureStorage.delete(key: 'jwt_token');
    setState(() {
      _token = null;
    });
  }

  Future<void> protected() async {
    const String apiUrl =
        'http://10.0.2.2:3000/protected'; // Cambia la URL según tu configuración

    try {
      final token = await _secureStorage.read(key: 'jwt_token');
      // Asegúrate de que el token no sea nulo
      if (token == null) {
        print('No se encontró el token');
        return;
      }
      // Realizar la solicitud POST al backend en Node.js
      final response = await http.get(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token'
        }
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('Respuesta del servidor: $data');
      } else {
        print('Error: ${response.body}');
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Secure Storage POC'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _usernameController,
              decoration: InputDecoration(labelText: 'Username'),
            ),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                final username = _usernameController.text;
                final password = _passwordController.text;
                login(username, password);
              },
              child: Text('Login'),
            ),
            ElevatedButton(
              onPressed: () {
                final username = _usernameController.text;
                final password = _passwordController.text;
                protected();
              },
              child: Text('Do Request'),
            ),
            SizedBox(height: 20),
            if (_token != null)
              Column(
                children: [
                  Text('Token almacenado:'),
                  Text(_token ?? ''),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: logout,
                    child: Text('Logout'),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

}
