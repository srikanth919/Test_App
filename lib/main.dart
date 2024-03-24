import 'package:flutter/material.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:webview_flutter/webview_flutter.dart';
import 'dart:async';

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
  List<String>? mediaUrls; // List to store media URLs
  String? _key = ''; // State variable to store the key value

  @override
  void initState() {
    super.initState();
    _getDeviceId();
    fetchData(); // Call fetchData after getting device ID
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
        _deviceId =
            iosInfo.identifierForVendor; // Use identifierForVendor as device ID
      });
    }
    fetchData(); // Call fetchData after getting device ID
  }

  Future<void> fetchData() async {
    // Define the API endpoints
    String keyUrl =
        'https://stagegallery.rinx.com/mobileapp/generate_key_task/';
    String playlistUrl =
        'https://stagegallery.rinx.com/mobileapp/fetch_playlist_task/';

    // Encode the device ID to JSON
    Map<String, dynamic> requestBody = {'device_id': _deviceId};

    try {
      // Make the API request to generate key
      final response = await http.post(
        Uri.parse('$keyUrl'),
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

        // Make the API request to fetch data with key as path parameter
        final playlistResponse = await http.get(
          Uri.parse('$playlistUrl$_key/'),
        );

        if (playlistResponse.statusCode == 200) {
          // API call successful, handle response data
          Map<String, dynamic> playlistData = jsonDecode(playlistResponse.body);
          List<dynamic> mediaIds = playlistData['media_ids'];
          List<String> urls = [];
          mediaIds.forEach((media) {
            if (media['file'] != null) {
              urls.add(media['file']); // Add file URL to the list
            }
          });
          setState(() {
            mediaUrls = urls; // Update the state variable with media URLs
          });
          _navigateToSecondPage(); // Navigate to second page
        } else {
          // API call failed, handle error
          print(
              'Failed to fetch playlist data: ${playlistResponse.statusCode}');
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

  void _navigateToSecondPage() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SecondPage(gen_key: _key, mediaUrls: mediaUrls),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Rinx App',
          style: TextStyle(fontSize: 30, color: Colors.black),
        ),
        centerTitle: false,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Key: $_key', // Display the key value
              style: TextStyle(fontSize: 40),
            ),
          ],
        ),
      ),
    );
  }
}

class SecondPage extends StatefulWidget {
  final String? gen_key;
  final List<String>? mediaUrls;

  const SecondPage({Key? key, this.gen_key, this.mediaUrls}) : super(key: key);

  @override
  _SecondPageState createState() => _SecondPageState();
}

class _SecondPageState extends State<SecondPage> {
  int _currentIndex = 0;
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _startDisplayingMedia();
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  void _startDisplayingMedia() {
    _timer = Timer.periodic(Duration(seconds: 10), (timer) {
      if (_currentIndex < widget.mediaUrls!.length - 1) {
        setState(() {
          _currentIndex++;
        });
      } else {
        _timer.cancel();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (widget.mediaUrls != null && widget.mediaUrls!.isNotEmpty)
              if (widget.mediaUrls![_currentIndex].endsWith('.mp4'))
                Container(
                  height: 300,
                  child: WebView(
                    initialUrl: widget.mediaUrls![_currentIndex],
                    javascriptMode: JavascriptMode.unrestricted,
                  ),
                )
              else
                Column(
                  children: [
                    Image.network(
                      widget.mediaUrls![_currentIndex],
                      width: MediaQuery.of(context).size.width,
                      height: MediaQuery.of(context).size.height,
                    ),
                  ],
                ),
          ],
        ),
      ),
    );
  }
}
