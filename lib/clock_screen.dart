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
        backgroundColor: const Color(0xFF3F51B5),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF3F51B5),
              Color(0xFF7986CB),
              Color(0xFFE8EAF6),
            ],
            stops: [0.0, 0.3, 1.0],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
            // Current Time Display
            Container(
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: const LinearGradient(
                  colors: [Colors.white, Color(0xFFF8F9FF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: <Widget>[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF3F51B5).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(50),
                      ),
                      child: const Icon(
                        Icons.access_time,
                        size: 48,
                        color: Color(0xFF3F51B5),
                      ),
                    ),
                    const SizedBox(height: 24),
                    StreamBuilder<DateTime>(
                      stream: Stream.periodic(const Duration(seconds: 1), (_) => DateTime.now()),
                      builder: (context, snapshot) {
                        final DateTime now = snapshot.data ?? DateTime.now();
                        return Text(
                          "${now.hour.toString().padLeft(2, "0")}:${now.minute.toString().padLeft(2, "0")}:${now.second.toString().padLeft(2, "0")}",
                          style: const TextStyle(
                            fontSize: 56,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF3F51B5),
                            letterSpacing: 2,
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    StreamBuilder<DateTime>(
                      stream: Stream.periodic(const Duration(seconds: 1), (_) => DateTime.now()),
                      builder: (context, snapshot) {
                        final DateTime now = snapshot.data ?? DateTime.now();
                        return Text(
                          "${now.day}/${now.month}/${now.year}",
                          style: const TextStyle(
                            fontSize: 20,
                            color: Colors.grey,
                            fontWeight: FontWeight.w500,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            // Voice Alarm Setting
            Container(
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF3F51B5).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.mic, color: Color(0xFF3F51B5), size: 24),
                        ),
                        const SizedBox(width: 16),
                        const Expanded(
                          child: Text(
                            "Đặt báo thức bằng giọng nói",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2C3E50),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    if (!_speechEnabled)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.red.withOpacity(0.3)),
                        ),
                        child: const Row(
                          children: <Widget>[
                            Icon(Icons.error_outline, color: Colors.red, size: 20),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                "Speech recognition không khả dụng. Vui lòng kiểm tra quyền truy cập microphone.",
                                style: TextStyle(color: Colors.red, fontSize: 14),
                              ),
                            ),
                          ],
                        ),
                      )
                    else ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF3F51B5).withOpacity(0.05),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          "Nói thời gian báo thức (ví dụ: 7 giờ 30, 14:30, 8 giờ)",
                          style: TextStyle(fontSize: 15, color: Color(0xFF2C3E50), fontWeight: FontWeight.w500),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border.all(color: const Color(0xFF3F51B5).withOpacity(0.3)),
                          borderRadius: BorderRadius.circular(12),
                          color: const Color(0xFFF8F9FF),
                        ),
                        child: Text(
                          _recognizedTime.isEmpty ? "Chưa có dữ liệu giọng nói" : _recognizedTime,
                          style: TextStyle(
                            fontSize: 16,
                            color: _recognizedTime.isEmpty ? Colors.grey : const Color(0xFF2C3E50),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: Container(
                              height: 50,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                gradient: LinearGradient(
                                  colors: _isListening 
                                    ? [Colors.red, Colors.red.shade700]
                                    : [const Color(0xFF3F51B5), const Color(0xFF5C6BC0)],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: (_isListening ? Colors.red : const Color(0xFF3F51B5)).withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: ElevatedButton.icon(
                                onPressed: _isListening ? _stopListening : _startListening,
                                icon: Icon(_isListening ? Icons.stop : Icons.mic, color: Colors.white),
                                label: Text(
                                  _isListening ? "Dừng" : "Bắt đầu nghe",
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Container(
                              height: 50,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFF3F51B5), width: 2),
                              ),
                              child: OutlinedButton.icon(
                                onPressed: _recognizedTime.isNotEmpty ? _setAlarmFromVoice : null,
                                icon: const Icon(Icons.alarm_add, color: Color(0xFF3F51B5)),
                                label: const Text(
                                  "Đặt báo thức",
                                  style: TextStyle(color: Color(0xFF3F51B5), fontWeight: FontWeight.bold),
                                ),
                                style: OutlinedButton.styleFrom(
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
            // Manual Alarm Setting
            Container(
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF3F51B5).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.alarm, color: Color(0xFF3F51B5), size: 24),
                        ),
                        const SizedBox(width: 16),
                        const Expanded(
                          child: Text(
                            "Đặt báo thức thủ công",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2C3E50),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF3F51B5).withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        "Sử dụng giao diện đồng hồ để đặt báo thức chính xác",
                        style: TextStyle(fontSize: 15, color: Color(0xFF2C3E50), fontWeight: FontWeight.w500),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      height: 50,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        gradient: const LinearGradient(
                          colors: [Color(0xFF3F51B5), Color(0xFF5C6BC0)],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF3F51B5).withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ElevatedButton.icon(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Tính năng cài đặt báo thức chi tiết sẽ được thêm sau"),
                              backgroundColor: Colors.orange,
                            ),
                          );
                        },
                        icon: const Icon(Icons.settings, color: Colors.white),
                        label: const Text(
                          "Mở cài đặt báo thức",
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            ],
          ),
        ),
      ),
    );
  }
}

