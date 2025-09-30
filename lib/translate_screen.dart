import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:google_mlkit_translation/google_mlkit_translation.dart";
import "package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart";
import "package:image_picker/image_picker.dart";
import "package:speech_to_text/speech_to_text.dart";
import "package:speech_to_text/speech_recognition_result.dart";

class TranslateScreen extends StatefulWidget {
  const TranslateScreen({super.key});

  @override
  State<TranslateScreen> createState() => _TranslateScreenState();
}

class _TranslateScreenState extends State<TranslateScreen> {
  final TextEditingController _textController = TextEditingController();
  final TextEditingController _translatedController = TextEditingController();
  final SpeechToText _speechToText = SpeechToText();
  
  OnDeviceTranslator? _translator;
  bool _isTranslating = false;
  bool _speechEnabled = false;
  bool _isListening = false;
  String _recognizedText = "";
  String _selectedSourceLanguage = "vi";
  String _selectedTargetLanguage = "en";
  
  final List<Map<String, String>> _languages = [
    {"code": "vi", "name": "Tiếng Việt"},
    {"code": "en", "name": "English"},
    {"code": "ja", "name": "日本語"},
    {"code": "ko", "name": "한국어"},
    {"code": "zh", "name": "中文"},
    {"code": "fr", "name": "Français"},
    {"code": "de", "name": "Deutsch"},
    {"code": "es", "name": "Español"},
  ];

  @override
  void initState() {
    super.initState();
    _initSpeech();
    _initTranslator();
  }

  @override
  void dispose() {
    _textController.dispose();
    _translatedController.dispose();
    _translator?.close();
    super.dispose();
  }

  /// Initialize speech recognition
  Future<void> _initSpeech() async {
    _speechEnabled = await _speechToText.initialize();
    setState(() {});
  }

  /// Initialize translator
  Future<void> _initTranslator() async {
    try {
      _translator = OnDeviceTranslator(
        sourceLanguage: _getTranslateLanguage(_selectedSourceLanguage),
        targetLanguage: _getTranslateLanguage(_selectedTargetLanguage),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Lỗi khởi tạo translator: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Get TranslateLanguage from language code
  TranslateLanguage _getTranslateLanguage(String languageCode) {
    switch (languageCode) {
      case "vi":
        return TranslateLanguage.vietnamese;
      case "en":
        return TranslateLanguage.english;
      case "ja":
        return TranslateLanguage.japanese;
      case "ko":
        return TranslateLanguage.korean;
      case "zh":
        return TranslateLanguage.chinese;
      case "fr":
        return TranslateLanguage.french;
      case "de":
        return TranslateLanguage.german;
      case "es":
        return TranslateLanguage.spanish;
      default:
        return TranslateLanguage.english;
    }
  }

  /// Translate text
  Future<void> _translateText(String text) async {
    if (text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Vui lòng nhập văn bản cần dịch"),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isTranslating = true;
    });

    try {
      if (_translator == null) {
        await _initTranslator();
      }
      
      final String translatedText = await _translator!.translateText(text);
      setState(() {
        _translatedController.text = translatedText;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Lỗi dịch thuật: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isTranslating = false;
      });
    }
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
      _recognizedText = result.recognizedWords;
      _textController.text = _recognizedText;
    });
  }

  /// Pick image from camera or gallery
  Future<void> _pickImage(ImageSource source) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: source);
      
      if (image != null) {
        await _extractTextFromImage(image.path);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Lỗi chọn ảnh: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Extract text from image using ML Kit
  Future<void> _extractTextFromImage(String imagePath) async {
    setState(() {
      _isTranslating = true;
    });

    try {
      final InputImage inputImage = InputImage.fromFilePath(imagePath);
      final TextRecognizer textRecognizer = TextRecognizer();
      
      final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);
      
      String extractedText = "";
      for (TextBlock block in recognizedText.blocks) {
        for (TextLine line in block.lines) {
          extractedText += "${line.text}\n";
        }
      }
      
      setState(() {
        _textController.text = extractedText.trim();
      });
      
      // Auto-translate the extracted text
      if (extractedText.trim().isNotEmpty) {
        await _translateText(extractedText.trim());
      }
      
      textRecognizer.close();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Lỗi nhận dạng văn bản: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isTranslating = false;
      });
    }
  }

  /// Swap source and target languages
  void _swapLanguages() {
    setState(() {
      final String temp = _selectedSourceLanguage;
      _selectedSourceLanguage = _selectedTargetLanguage;
      _selectedTargetLanguage = temp;
    });
    _initTranslator();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Dịch thuật"),
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
            // Language Selection
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
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF3F51B5).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.translate, color: Color(0xFF3F51B5), size: 24),
                        ),
                        const SizedBox(width: 16),
                        const Expanded(
                          child: Text(
                            "Chọn ngôn ngữ",
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
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            decoration: BoxDecoration(
                              border: Border.all(color: const Color(0xFF3F51B5).withOpacity(0.3)),
                              borderRadius: BorderRadius.circular(12),
                              color: const Color(0xFFF8F9FF),
                            ),
                            child: DropdownButton<String>(
                              value: _selectedSourceLanguage,
                              isExpanded: true,
                              underline: const SizedBox(),
                              style: const TextStyle(color: Color(0xFF2C3E50), fontWeight: FontWeight.w500),
                              items: _languages.map((Map<String, String> language) {
                                return DropdownMenuItem<String>(
                                  value: language["code"]!,
                                  child: Text(language["name"]!),
                                );
                              }).toList(),
                              onChanged: (String? newValue) {
                                if (newValue != null) {
                                  setState(() {
                                    _selectedSourceLanguage = newValue;
                                  });
                                  _initTranslator();
                                }
                              },
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF3F51B5).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: IconButton(
                            onPressed: _swapLanguages,
                            icon: const Icon(Icons.swap_horiz, color: Color(0xFF3F51B5)),
                            tooltip: "Đổi ngôn ngữ",
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            decoration: BoxDecoration(
                              border: Border.all(color: const Color(0xFF3F51B5).withOpacity(0.3)),
                              borderRadius: BorderRadius.circular(12),
                              color: const Color(0xFFF8F9FF),
                            ),
                            child: DropdownButton<String>(
                              value: _selectedTargetLanguage,
                              isExpanded: true,
                              underline: const SizedBox(),
                              style: const TextStyle(color: Color(0xFF2C3E50), fontWeight: FontWeight.w500),
                              items: _languages.map((Map<String, String> language) {
                                return DropdownMenuItem<String>(
                                  value: language["code"]!,
                                  child: Text(language["name"]!),
                                );
                              }).toList(),
                              onChanged: (String? newValue) {
                                if (newValue != null) {
                                  setState(() {
                                    _selectedTargetLanguage = newValue;
                                  });
                                  _initTranslator();
                                }
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            // Text Input Section
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
                          child: const Icon(Icons.edit, color: Color(0xFF3F51B5), size: 24),
                        ),
                        const SizedBox(width: 16),
                        const Expanded(
                          child: Text(
                            "Nhập văn bản cần dịch",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2C3E50),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _textController,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        hintText: "Nhập văn bản cần dịch...",
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: _isTranslating ? null : () => _translateText(_textController.text),
                            icon: _isTranslating 
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.translate),
                            label: Text(_isTranslating ? "Đang dịch..." : "Dịch văn bản"),
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (_speechEnabled)
                          OutlinedButton.icon(
                            onPressed: _isListening ? _stopListening : _startListening,
                            icon: Icon(_isListening ? Icons.stop : Icons.mic),
                            label: Text(_isListening ? "Dừng" : "Nói"),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: _isListening ? Colors.red : const Color(0xFF3F51B5),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Image Translation Section
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Text(
                      "Dịch từ ảnh",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      "Chụp ảnh hoặc chọn từ thư viện để nhận dạng và dịch văn bản",
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _pickImage(ImageSource.camera),
                            icon: const Icon(Icons.camera_alt),
                            label: const Text("Chụp ảnh"),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _pickImage(ImageSource.gallery),
                            icon: const Icon(Icons.photo_library),
                            label: const Text("Chọn ảnh"),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Translation Result
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Text(
                      "Kết quả dịch thuật",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _translatedController,
                      maxLines: 4,
                      readOnly: true,
                      decoration: const InputDecoration(
                        hintText: "Kết quả dịch thuật sẽ hiển thị ở đây...",
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (_translatedController.text.isNotEmpty)
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                // Copy to clipboard
                                Clipboard.setData(ClipboardData(text: _translatedController.text));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text("Đã sao chép vào clipboard"),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              },
                              icon: const Icon(Icons.copy),
                              label: const Text("Sao chép"),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                setState(() {
                                  _translatedController.clear();
                                });
                              },
                              icon: const Icon(Icons.clear),
                              label: const Text("Xóa"),
                            ),
                          ),
                        ],
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
