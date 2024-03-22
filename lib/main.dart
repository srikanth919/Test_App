import 'package:flutter/material.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: DeviceInfoWidget(),
    );
  }
}

class DeviceInfoWidget extends StatefulWidget {
  @override
  _DeviceInfoWidgetState createState() => _DeviceInfoWidgetState();
}

class _DeviceInfoWidgetState extends State<DeviceInfoWidget> {
  String? _deviceId = '';
  String? _key = ''; // State variable to store the key value

  @override
  void initState() {
    super.initState();
    _getDeviceId();
  }

  Future<void> _getDeviceId() async {
    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    if (Platform.isAndroid) {
      AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
      setState(() {
        _deviceId = androidInfo.androidId; // Use androidId as device ID
      });
    } else if (Platform.isIOS) {
      IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
      setState(() {
        _deviceId = iosInfo.identifierForVendor; // Use identifierForVendor as device ID
      });
    }
    fetchData(); // Call fetchData after getting device ID
  }

  Future<void> fetchData() async {
    // Define the API endpoint
    String apiUrl = 'https://stagegallery.rinx.com/mobileapp/fetch_playlist_task/';
    //String apiUrl = 'https://stagegallery.rinx.com/mobileapp/generate_key_task/';

    // Encode the device ID to JSON
    Map<String, dynamic> requestBody = {'device_id': _deviceId};

    // Convert the JSON parameters to a query strin
    // Append the query string to the API URL

    try {
      // Make the API request
      final response = await http.post(
        Uri.parse('https://stagegallery.rinx.com/mobileapp/generate_key_task/'),
        headers: {
          'Content-Type': 'application/json', // Set the content type
        },
        body: jsonEncode(requestBody), // Encode the request body to JSON
      );

      if (response.statusCode == 200) {
        // API call successful, handle response data
        Map<String, dynamic> responseBody = jsonDecode(response.body);
        String key = responseBody['key'];
        setState(() {
          _key = key; // Update the state variable
        });
        print(response.body);
        print('Key: $_key');
        // Make the API request to fetch data with key as path parameter
        final playlistResponse = await http.get(
          Uri.parse('$apiUrl$_key'),
        );

        print(playlistResponse);

        if (playlistResponse.statusCode == 200) {
          // API call successful, handle response data
          Map<String, dynamic> playlistData = jsonDecode(playlistResponse.body);
          // Process the playlist data as needed
          print('Playlist data: $playlistData');
        } else {
          // API call failed, handle error
          print('Failed to fetch playlist data: ${playlistResponse.statusCode}');
        }

      } else {
        // API call failed, handle error
        print('Failed to fetch data: ${response.statusCode}');
      }
    } catch (error) {
      // Handle any errors that occur during the API request
      print('Error fetching data: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(' Demo App'),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Key: $_key', // Display the key value
              style: TextStyle(fontSize: 50),

            ),
          ],
        ),
      ),
    );
  }
  }







