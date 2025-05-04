// Conditional imports for File and html
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:video_player/video_player.dart';

void main() {
  runApp(const MyWebsite());
}

class MyWebsite extends StatelessWidget {
  const MyWebsite({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'My Website',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 4;

  final List<String> _menuItems = [
    'History',
    'Uploaded Files',
    'Captured Files',
    'Saved Transcript',
    'Live'
  ];

  final List<IconData> _menuIcons = [
    Icons.history,
    Icons.upload_file,
    Icons.camera_alt,
    Icons.description,
    Icons.live_tv
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Website'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.deepPurple,
              ),
              child: Center(
                child: Text(
                  'Menu',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                  ),
                ),
              ),
            ),
            ...List.generate(_menuItems.length, (index) {
              return ListTile(
                leading: Icon(
                  _menuIcons[index],
                  color: _selectedIndex == index ? Colors.deepPurple : Colors.grey,
                ),
                title: Text(
                  _menuItems[index],
                  style: TextStyle(
                    color: _selectedIndex == index ? Colors.deepPurple : Colors.black,
                    fontWeight: _selectedIndex == index ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                selected: _selectedIndex == index,
                onTap: () {
                  setState(() {
                    _selectedIndex = index;
                  });
                  Navigator.pop(context);
                },
              );
            }),
          ],
        ),
      ),
      body: _selectedIndex == 4 ? const LivePage() : _buildDefaultContent(),
    );
  }

  Widget _buildDefaultContent() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _menuIcons[_selectedIndex],
            size: 64,
            color: Colors.deepPurple,
          ),
          const SizedBox(height: 16),
          Text(
            _menuItems[_selectedIndex],
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Content will be displayed here',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}

class LivePage extends StatefulWidget {
  const LivePage({super.key});

  @override
  State<LivePage> createState() => _LivePageState();
}

class _LivePageState extends State<LivePage> {
  VideoPlayerController? _videoPlayerController;
  bool _isVideoUploaded = false;
  String? _videoPath;
  String? _webVideoUrl;
  bool _showTextWindow = false;

  @override
  void dispose() {
    _videoPlayerController?.dispose();
    if (kIsWeb && _webVideoUrl != null) {
      html.Url.revokeObjectUrl(_webVideoUrl!);
    }
    super.dispose();
  }

  Future<void> _pickVideo() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.video,
        allowMultiple: false,
        withData: true, // Needed for web
      );

      if (result != null) {
        setState(() {
          _showTextWindow = false;
        });
        if (kIsWeb) {
          final bytes = result.files.single.bytes;
          if (bytes != null) {
            final blob = html.Blob([bytes], 'video/mp4');
            final url = html.Url.createObjectUrlFromBlob(blob);
            setState(() {
              _webVideoUrl = url;
              _isVideoUploaded = true;
            });
            _videoPlayerController = VideoPlayerController.network(url)
              ..initialize().then((_) {
                setState(() {});
                _videoPlayerController?.play();
              });
          }
        } else {
          setState(() {
            _videoPath = result.files.single.path;
            _isVideoUploaded = true;
          });
          _videoPlayerController = VideoPlayerController.file(File(_videoPath!))
            ..initialize().then((_) {
              setState(() {});
              _videoPlayerController?.play();
            });
        }
        // Show the text window after 4 seconds
        Future.delayed(const Duration(seconds: 4), () {
          if (mounted) {
            setState(() {
              _showTextWindow = true;
            });
          }
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking video: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            'assets/logo.png',
            height: 200,
            width: 200,
            fit: BoxFit.contain,
          ),
          const SizedBox(height: 50),
          if (!_isVideoUploaded) ...[
            ElevatedButton.icon(
              onPressed: _pickVideo,
              icon: const Icon(Icons.upload_file),
              label: const Text('Upload Video'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                textStyle: const TextStyle(fontSize: 18),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                // Handle live capture
              },
              icon: const Icon(Icons.camera_alt),
              label: const Text('Live Capture'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                textStyle: const TextStyle(fontSize: 18),
              ),
            ),
          ] else ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 400,
                  height: 300,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: _videoPlayerController?.value.isInitialized ?? false
                      ? AspectRatio(
                          aspectRatio: _videoPlayerController!.value.aspectRatio,
                          child: VideoPlayer(_videoPlayerController!),
                        )
                      : const Center(child: CircularProgressIndicator()),
                ),
                if (_showTextWindow) ...[
                  const SizedBox(width: 24),
                  Container(
                    width: 400,
                    height: 300,
                    decoration: BoxDecoration(
                      color: Color(0xFFF5F5F5),
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.all(24),
                    child: const Center(
                      child: Text(
                        'some random text',
                        style: TextStyle(fontSize: 18, color: Colors.black87),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: Icon(
                    _videoPlayerController?.value.isPlaying ?? false
                        ? Icons.pause
                        : Icons.play_arrow,
                  ),
                  onPressed: () {
                    setState(() {
                      if (_videoPlayerController?.value.isPlaying ?? false) {
                        _videoPlayerController?.pause();
                      } else {
                        _videoPlayerController?.play();
                      }
                    });
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: () {
                    setState(() {
                      _videoPlayerController?.seekTo(Duration.zero);
                      _videoPlayerController?.play();
                    });
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    setState(() {
                      _videoPlayerController?.dispose();
                      _videoPlayerController = null;
                      _isVideoUploaded = false;
                      _videoPath = null;
                    });
                  },
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
