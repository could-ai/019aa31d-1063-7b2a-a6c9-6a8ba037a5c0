import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:screenshot/screenshot.dart';
import 'package:gallery_saver/gallery_saver.dart';

void main() {
  runApp(const UrduGraphixApp());
}

class UrduGraphixApp extends StatelessWidget {
  const UrduGraphixApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Urdu Graphix',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      // Set locale to RTL for Urdu support
      builder: (context, child) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: child!,
        );
      },
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // State variables
  File? _backgroundImage;
  final TextEditingController _textController = TextEditingController();
  double _fontSize = 32.0;
  Color _textColor = Colors.black;
  final List<TextItem> _textItems = [];
  
  // Screenshot controller to capture the poster
  final ScreenshotController _screenshotController = ScreenshotController();
  final ImagePicker _picker = ImagePicker();

  // Predefined font sizes matching the HTML example
  final List<double> _fontSizes = [24, 32, 40, 48, 56, 64, 72];

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  // Pick background image
  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _backgroundImage = File(image.path);
      });
    }
  }

  // Add text to canvas
  void _addText() {
    if (_textController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('براہ کرم اردو میں کچھ لکھیں! (Please write something)')),
      );
      return;
    }

    setState(() {
      _textItems.add(TextItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        text: _textController.text,
        fontSize: _fontSize,
        color: _textColor,
        offset: const Offset(100, 100), // Default position
      ));
      _textController.clear();
    });
  }

  // Clear canvas
  void _clearCanvas() {
    setState(() {
      _backgroundImage = null;
      _textItems.clear();
      _textController.clear();
    });
  }

  // Save image
  Future<void> _saveImage() async {
    try {
      // Check permissions on mobile
      if (Platform.isAndroid || Platform.isIOS) {
        var status = await Permission.storage.status;
        if (!status.isGranted) {
          await Permission.storage.request();
        }
      }

      final Uint8List? imageBytes = await _screenshotController.capture();
      
      if (imageBytes != null) {
        final directory = await getTemporaryDirectory();
        final path = '${directory.path}/urdu_graphix_${DateTime.now().millisecondsSinceEpoch}.png';
        final file = File(path);
        await file.writeAsBytes(imageBytes);

        // Save to gallery
        await GallerySaver.saveImage(path, albumName: 'UrduGraphix');

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تصویر محفوظ کر لی گئی ہے (Image Saved)')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving image: $e')),
        );
      }
    }
  }

  // Update text position
  void _updateTextPosition(String id, Offset newOffset) {
    setState(() {
      final index = _textItems.indexWhere((item) => item.id == id);
      if (index != -1) {
        _textItems[index] = _textItems[index].copyWith(offset: newOffset);
      }
    });
  }

  // Delete text item
  void _deleteTextItem(String id) {
    setState(() {
      _textItems.removeWhere((item) => item.id == id);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Urdu Graphix - اردو گرافکس'),
        centerTitle: true,
        backgroundColor: Colors.grey[100],
      ),
      body: Column(
        children: [
          // Tools Section
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Column(
              children: [
                // Input Row
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _textController,
                        textDirection: TextDirection.rtl,
                        decoration: const InputDecoration(
                          hintText: 'یہاں اردو میں لکھیں (Write Urdu here)',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        style: GoogleFonts.notoNastaliqUrdu(),
                      ),
                    ),
                    const SizedBox(width: 10),
                    IconButton(
                      onPressed: _pickImage,
                      icon: const Icon(Icons.image),
                      tooltip: 'بیک گراؤنڈ (Background)',
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.blue.shade50,
                        foregroundColor: Colors.blue,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                
                // Controls Row
                Row(
                  children: [
                    const Text('سائز: '),
                    DropdownButton<double>(
                      value: _fontSize,
                      items: _fontSizes.map((s) => DropdownMenuItem(
                        value: s,
                        child: Text(s.toInt().toString()),
                      )).toList(),
                      onChanged: (v) => setState(() => _fontSize = v!),
                    ),
                    const SizedBox(width: 16),
                    const Text('رنگ: '),
                    GestureDetector(
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('رنگ منتخب کریں'),
                            content: SingleChildScrollView(
                              child: ColorPicker(
                                pickerColor: _textColor,
                                onColorChanged: (color) => setState(() => _textColor = color),
                              ),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(),
                                child: const Text('OK'),
                              ),
                            ],
                          ),
                        );
                      },
                      child: Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: _textColor,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.grey),
                        ),
                      ),
                    ),
                    const Spacer(),
                    ElevatedButton.icon(
                      onPressed: _addText,
                      icon: const Icon(Icons.add),
                      label: const Text('شامل کریں'),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Canvas Area
          Expanded(
            child: Container(
              color: const Color(0xFFF8F9FA), // Light grey background like HTML
              child: Center(
                child: SingleChildScrollView(
                  child: Screenshot(
                    controller: _screenshotController,
                    child: Container(
                      width: 350, // Fixed width for poster feel
                      height: 350, // Fixed height
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: Colors.grey.shade400, width: 2, style: BorderStyle.solid),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            spreadRadius: 2,
                          )
                        ],
                      ),
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          // Background Image
                          if (_backgroundImage != null)
                            Positioned.fill(
                              child: Image.file(
                                _backgroundImage!,
                                fit: BoxFit.cover,
                              ),
                            ),
                          
                          // Placeholder text if empty
                          if (_backgroundImage == null && _textItems.isEmpty)
                            Center(
                              child: Text(
                                'تصویر یا ٹیکسٹ شامل کریں\n(Add Image or Text)',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.grey.shade400),
                              ),
                            ),

                          // Text Items
                          ..._textItems.map((item) => Positioned(
                            left: item.offset.dx,
                            top: item.offset.dy,
                            child: GestureDetector(
                              onPanUpdate: (details) {
                                // Calculate new position relative to parent
                                // We need to ensure it stays somewhat within bounds if desired, 
                                // but for now free movement is fine.
                                final newOffset = Offset(
                                  item.offset.dx + details.delta.dx * -1, // Invert X for RTL drag feel if needed, but usually standard drag is better. 
                                  // Actually standard drag:
                                  // In RTL, dx might be inverted depending on Directionality. 
                                  // Let's test standard first.
                                );
                                
                                // Standard drag logic works best regardless of RTL usually
                                _updateTextPosition(item.id, item.offset + details.delta);
                              },
                              onLongPress: () {
                                // Show delete option
                                showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('حذف کریں؟ (Delete?)'),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: const Text('نہیں'),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          _deleteTextItem(item.id);
                                          Navigator.pop(context);
                                        },
                                        child: const Text('ہاں', style: TextStyle(color: Colors.red)),
                                      ),
                                    ],
                                  ),
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.blue.withOpacity(0.3), width: 1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  item.text,
                                  style: GoogleFonts.notoNastaliqUrdu(
                                    fontSize: item.fontSize,
                                    color: item.color,
                                    height: 1.5, // Better line height for Urdu
                                  ),
                                ),
                              ),
                            ),
                          )),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Bottom Action Bar
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: _clearCanvas,
                  icon: const Icon(Icons.refresh),
                  label: const Text('نیا پوسٹر'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey,
                    foregroundColor: Colors.white,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _saveImage,
                  icon: const Icon(Icons.download),
                  label: const Text('ڈاؤن لوڈ کریں'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Model class for Text Items
class TextItem {
  final String id;
  final String text;
  final double fontSize;
  final Color color;
  final Offset offset;

  TextItem({
    required this.id,
    required this.text,
    required this.fontSize,
    required this.color,
    required this.offset,
  });

  TextItem copyWith({
    String? id,
    String? text,
    double? fontSize,
    Color? color,
    Offset? offset,
  }) {
    return TextItem(
      id: id ?? this.id,
      text: text ?? this.text,
      fontSize: fontSize ?? this.fontSize,
      color: color ?? this.color,
      offset: offset ?? this.offset,
    );
  }
}
