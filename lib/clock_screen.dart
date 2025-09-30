import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:speech_to_text/speech_to_text.dart";
import "package:speech_to_text/speech_recognition_result.dart";

class ClockScreen extends StatefulWidget {
  const ClockScreen({super.key});

  @override
  State<ClockScreen> createState() => _ClockScreenState();
}

class _ClockScreenState extends State<ClockScreen> {
  final SpeechToText _speechToText = SpeechToText();
  bool _speechEnabled = false;
  String _lastWords = "";
  String _recognizedTime = "";
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    _initSpeech();
  }

  /// Initialize speech recognition
  Future<void> _initSpeech() async {
    _speechEnabled = await _speechToText.initialize();
    setState(() {});
  }

  /// Start listening for speech input
  Future<void> _startListening() async {
    await _speechToText.listen(onResult: _onSpeechResult);
    setState(() {
      _isListening = true;
    });
  }

  /// Stop listening for speech input
  Future<void> _stopListening() async {
    await _speechToText.stop();
    setState(() {
      _isListening = false;
    });
  }

  /// Handle speech recognition results
  void _onSpeechResult(SpeechRecognitionResult result) {
    setState(() {
      _lastWords = result.recognizedWords;
      _recognizedTime = _lastWords;
    });
  }

  /// Parse time from speech input
  TimeOfDay? _parseTimeFromSpeech(String speechText) {
    final String text = speechText.toLowerCase().trim();
    
    // Handle common time patterns
    final RegExp timePattern = RegExp(r"(\d{1,2}):(\d{2})");
    final RegExp hourMinutePattern = RegExp(r"(\d{1,2})\s+(?:giờ|hour|h)\s*(\d{1,2})?");
    final RegExp hourOnlyPattern = RegExp(r"(\d{1,2})\s+(?:giờ|hour|h)");
    
    Match? match = timePattern.firstMatch(text);
    if (match != null) {
      final int hour = int.parse(match.group(1)!);
      final int minute = int.parse(match.group(2)!);
      if (hour >= 0 && hour <= 23 && minute >= 0 && minute <= 59) {
        return TimeOfDay(hour: hour, minute: minute);
      }
    }
    
    match = hourMinutePattern.firstMatch(text);
    if (match != null) {
      final int hour = int.parse(match.group(1)!);
      final int minute = match.group(2) != null ? int.parse(match.group(2)!) : 0;
      if (hour >= 0 && hour <= 23 && minute >= 0 && minute <= 59) {
        return TimeOfDay(hour: hour, minute: minute);
      }
    }
    
    match = hourOnlyPattern.firstMatch(text);
    if (match != null) {
      final int hour = int.parse(match.group(1)!);
      if (hour >= 0 && hour <= 23) {
        return TimeOfDay(hour: hour, minute: 0);
      }
    }
    
    return null;
  }

  /// Set alarm using voice input
  Future<void> _setAlarmFromVoice() async {
    if (_recognizedTime.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Vui lòng nói thời gian báo thức"),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final TimeOfDay? parsedTime = _parseTimeFromSpeech(_recognizedTime);
    if (parsedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Không thể nhận diện thời gian từ: $_recognizedTime"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Show confirmation dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Xác nhận báo thức"),
        content: Text("Bạn muốn đặt báo thức lúc ${parsedTime.hour.toString().padLeft(2, "0")}:${parsedTime.minute.toString().padLeft(2, "0")}?"),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("Hủy"),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text("Đã đặt báo thức lúc ${parsedTime.hour.toString().padLeft(2, "0")}:${parsedTime.minute.toString().padLeft(2, "0")}"),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text("Xác nhận"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Đồng hồ"),
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            // Current Time Display
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: <Widget>[
                    const Icon(
                      Icons.access_time,
                      size: 64,
                      color: Color(0xFF3F51B5),
                    ),
                    const SizedBox(height: 16),
                    StreamBuilder<DateTime>(
                      stream: Stream.periodic(const Duration(seconds: 1), (_) => DateTime.now()),
                      builder: (context, snapshot) {
                        final DateTime now = snapshot.data ?? DateTime.now();
                        return Text(
                          "${now.hour.toString().padLeft(2, "0")}:${now.minute.toString().padLeft(2, "0")}:${now.second.toString().padLeft(2, "0")}",
                          style: const TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF3F51B5),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 8),
                    StreamBuilder<DateTime>(
                      stream: Stream.periodic(const Duration(seconds: 1), (_) => DateTime.now()),
                      builder: (context, snapshot) {
                        final DateTime now = snapshot.data ?? DateTime.now();
                        return Text(
                          "${now.day}/${now.month}/${now.year}",
                          style: const TextStyle(
                            fontSize: 18,
                            color: Colors.grey,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Voice Alarm Setting
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Row(
                      children: <Widget>[
                        Icon(Icons.mic, color: Color(0xFF3F51B5)),
                        SizedBox(width: 8),
                        Text(
                          "Đặt báo thức bằng giọng nói",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (!_speechEnabled)
                      const Text(
                        "Speech recognition không khả dụng. Vui lòng kiểm tra quyền truy cập microphone.",
                        style: TextStyle(color: Colors.red),
                      )
                    else ...[
                      const Text(
                        "Nói thời gian báo thức (ví dụ: 7 giờ 30, 14:30, 8 giờ)",
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _recognizedTime.isEmpty ? "Chưa có dữ liệu giọng nói" : _recognizedTime,
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: _isListening ? _stopListening : _startListening,
                              icon: Icon(_isListening ? Icons.stop : Icons.mic),
                              label: Text(_isListening ? "Dừng" : "Bắt đầu nghe"),
                              style: FilledButton.styleFrom(
                                backgroundColor: _isListening ? Colors.red : const Color(0xFF3F51B5),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _recognizedTime.isNotEmpty ? _setAlarmFromVoice : null,
                              icon: const Icon(Icons.alarm_add),
                              label: const Text("Đặt báo thức"),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Manual Alarm Setting
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Row(
                      children: <Widget>[
                        Icon(Icons.alarm, color: Color(0xFF3F51B5)),
                        SizedBox(width: 8),
                        Text(
                          "Đặt báo thức thủ công",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      "Sử dụng giao diện đồng hồ để đặt báo thức chính xác",
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Tính năng cài đặt báo thức chi tiết sẽ được thêm sau"),
                              backgroundColor: Colors.orange,
                            ),
                          );
                        },
                        icon: const Icon(Icons.settings),
                        label: const Text("Mở cài đặt báo thức"),
                      ),
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

