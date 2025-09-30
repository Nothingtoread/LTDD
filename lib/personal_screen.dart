import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:url_launcher/url_launcher.dart";
import "package:youtube_player_flutter/youtube_player_flutter.dart";

class PersonalScreen extends StatefulWidget {
  const PersonalScreen({super.key});

  @override
  State<PersonalScreen> createState() => _PersonalScreenState();
}

class _PersonalScreenState extends State<PersonalScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _youtubeController = TextEditingController();
  YoutubePlayerController? _youtubePlayerController;
  bool _isYoutubePlayerReady = false;

  @override
  void initState() {
    super.initState();
    _youtubeController.text = "https://www.youtube.com/watch?v=dQw4w9WgXcQ"; // Default video
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _youtubeController.dispose();
    _youtubePlayerController?.dispose();
    super.dispose();
  }

  /// Launch phone dialer with the entered phone number
  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri phoneUri = Uri(scheme: "tel", path: phoneNumber);
    try {
      if (await canLaunchUrl(phoneUri)) {
        await launchUrl(phoneUri);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Cannot make phone call"),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Initialize YouTube player with the provided URL
  void _initializeYoutubePlayer(String url) {
    final String? videoId = YoutubePlayer.convertUrlToId(url);
    if (videoId != null) {
      _youtubePlayerController?.dispose();
      _youtubePlayerController = YoutubePlayerController(
        initialVideoId: videoId,
        flags: const YoutubePlayerFlags(
          autoPlay: false,
          mute: false,
          isLive: false,
        ),
      );
      setState(() {
        _isYoutubePlayerReady = true;
      });
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Invalid YouTube URL"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Cá nhân"),
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            // Phone Call Section
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Row(
                      children: <Widget>[
                        Icon(Icons.phone, color: Color(0xFF3F51B5)),
                        SizedBox(width: 8),
                        Text(
                          "Gọi điện thoại",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: "Nhập số điện thoại",
                        hintText: "Ví dụ: 0123456789",
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.phone),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () {
                          final String phoneNumber = _phoneController.text.trim();
                          if (phoneNumber.isNotEmpty) {
                            _makePhoneCall(phoneNumber);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Vui lòng nhập số điện thoại"),
                                backgroundColor: Colors.orange,
                              ),
                            );
                          }
                        },
                        icon: const Icon(Icons.call),
                        label: const Text("Gọi ngay"),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            // YouTube Player Section
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Row(
                      children: <Widget>[
                        Icon(Icons.play_circle, color: Color(0xFF3F51B5)),
                        SizedBox(width: 8),
                        Text(
                          "Xem YouTube",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _youtubeController,
                      decoration: const InputDecoration(
                        labelText: "Nhập URL YouTube",
                        hintText: "https://www.youtube.com/watch?v=...",
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.link),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              final String url = _youtubeController.text.trim();
                              if (url.isNotEmpty) {
                                _initializeYoutubePlayer(url);
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text("Vui lòng nhập URL YouTube"),
                                    backgroundColor: Colors.orange,
                                  ),
                                );
                              }
                            },
                            icon: const Icon(Icons.play_arrow),
                            label: const Text("Tải video"),
                          ),
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton.icon(
                          onPressed: () {
                            _youtubeController.clear();
                            _youtubePlayerController?.dispose();
                            setState(() {
                              _isYoutubePlayerReady = false;
                            });
                          },
                          icon: const Icon(Icons.clear),
                          label: const Text("Xóa"),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            // YouTube Player Display
            if (_isYoutubePlayerReady && _youtubePlayerController != null)
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const Text(
                        "Video Player",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      YoutubePlayer(
                        controller: _youtubePlayerController!,
                        showVideoProgressIndicator: true,
                        progressIndicatorColor: const Color(0xFF3F51B5),
                        onReady: () {
                          // Player is ready
                        },
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
