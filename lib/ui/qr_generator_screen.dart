import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb; // Pendeteksi Web
import 'package:path_provider/path_provider.dart';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:pretty_qr_code/pretty_qr_code.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:permission_handler/permission_handler.dart';

// Color
const Color kPrimaryColor = Color(0xFF20B2AA);
const Color kAccentColor = Color(0xFF28E1D7);
const Color kBackgroundColor = Color(0xFFF0F4F8);
const Color kErrorColor = Color(0xFFFF3B30);
const double kDefaultPadding = 20.0;

const List<Color> qrPresets = [
  Colors.white,
  Color(0xFFE3F2FD),
  Color(0xFFF1F8E9),
  Color(0xFFFFF3E0),
  Color(0xFFF3E5F5),
  Color(0xFFFCE4EC),
  Color(0xFFE0F7FA),
  Color(0xFFE8EAF6),
  Color(0xFFF9FBE7),
];

class QrGeneratorScreen extends StatefulWidget {
  const QrGeneratorScreen({super.key});
  @override
  State<QrGeneratorScreen> createState() => _QrGeneratorScreenState();
}

class _QrGeneratorScreenState extends State<QrGeneratorScreen> {
  final ScreenshotController _screenshotController = ScreenshotController();
  final TextEditingController _textController = TextEditingController();

  String? _qrData;
  Color _qrColor = Colors.white;
  double _opacity = 1.0;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  // --- LOGIC FUNCTIONS ---
  Future<void> _shareQrCode() async {
    if (_qrData == null || _qrData!.isEmpty) return;
    _showLoading();
    try {
      final imageBytes = await _screenshotController.capture(
        pixelRatio: MediaQuery.of(context).devicePixelRatio,
      );
      if (mounted) Navigator.pop(context);
      if (imageBytes != null) {
        await Share.shareXFiles([
          XFile.fromData(
            imageBytes,
            name: 'qr_code.png',
            mimeType: 'image/png',
          ),
        ], text: 'QR Code for: $_qrData\nMade with QRID by Rifai Gusnian');
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      _showErrorSnackBar("Failed to share QR Code");
    }
  }

  Future<void> _saveToGallery() async {
    if (_qrData == null || _qrData!.isEmpty) return;
    _showLoading();
    try {
      final imageBytes = await _screenshotController.capture(
        pixelRatio: 3.0,
      );
      
      if (imageBytes != null) {
        final result = await ImageGallerySaver.saveImage(
          imageBytes,
          name: "QRID_${DateTime.now().millisecondsSinceEpoch}",
        );
        
        if (mounted) Navigator.pop(context); // Close loading

        if (result['isSuccess'] == true || result != null) {
           if (mounted) {
             ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Success! QR Code saved to Gallery'),
                backgroundColor: Colors.green,
                behavior: SnackBarBehavior.floating,
              ),
            );
           }
        } else {
           _showErrorSnackBar("Failed to save to Gallery");
        }
      } else {
          if (mounted) Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      _showErrorSnackBar("Error saving: $e");
    }
  }

  void _pickCustomColor() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Custom Color & Opacity",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  fontFamily: 'SF Pro',
                ),
              ),
              const SizedBox(height: 24),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children:
                    [
                          Colors.red,
                          Colors.pink,
                          Colors.purple,
                          Colors.blue,
                          Colors.green,
                          Colors.yellow,
                          Colors.black,
                        ]
                        .map(
                          (c) => GestureDetector(
                            onTap: () => setState(
                              () => _qrColor = c.withOpacity(_opacity),
                            ),
                            child: Container(
                              width: 45,
                              height: 45,
                              decoration: BoxDecoration(
                                color: c,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 3,
                                ),
                              ),
                            ),
                          ),
                        )
                        .toList(),
              ),
              const SizedBox(height: 32),
              Slider(
                value: _opacity,
                activeColor: kPrimaryColor,
                onChanged: (val) {
                  setModalState(() => _opacity = val);
                  setState(() => _qrColor = _qrColor.withOpacity(val));
                },
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimaryColor,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(100),
                  ),
                ),
                child: const Text(
                  "Apply Color",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLoading() => showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) =>
        const Center(child: CircularProgressIndicator(color: kPrimaryColor)),
  );

  void _showErrorSnackBar(String message) =>
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: kErrorColor,
          behavior: SnackBarBehavior.floating,
        ),
      );

  @override
  Widget build(BuildContext context) {
    bool isDataValid = _qrData != null && _qrData!.isNotEmpty;

    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        title: const Text(
          'Create New QR',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontFamily: 'SF Pro',
            fontSize: 18,
          ),
        ),
        backgroundColor: kBackgroundColor,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.black,
            size: 18,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: kDefaultPadding),
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              height: 80,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [kPrimaryColor, kAccentColor],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: kPrimaryColor.withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Center(
                child: Text(
                  "Let's make your QR Code!",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 17,
                    fontFamily: 'SF Pro',
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 30,
                    offset: const Offset(0, 15),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Screenshot(
                    controller: _screenshotController,
                    child: Container(
                      width: 180,
                      height: 180,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: _qrColor,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: Colors.grey.shade100,
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: _qrData == null || _qrData!.isEmpty
                            ? const Icon(
                                Icons.qr_code_2_rounded,
                                size: 60,
                                color: Color(0xFFEEEEEE),
                              )
                            : PrettyQrView.data(
                                data: _qrData!,
                                decoration: const PrettyQrDecoration(
                                  shape: PrettyQrSmoothSymbol(),
                                ),
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Customize Background',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey,
                      fontFamily: 'SF Pro',
                    ),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      ...qrPresets.map(
                        (color) => GestureDetector(
                          onTap: () => setState(
                            () => _qrColor = color.withOpacity(_opacity),
                          ),
                          child: Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: _qrColor.withOpacity(1.0) == color
                                    ? kPrimaryColor
                                    : Colors.grey.shade200,
                                width: _qrColor.withOpacity(1.0) == color
                                    ? 3
                                    : 1,
                              ),
                            ),
                            child: _qrColor.withOpacity(1.0) == color
                                ? const Icon(
                                    Icons.check_rounded,
                                    color: kPrimaryColor,
                                    size: 20,
                                  )
                                : null,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: _pickCustomColor,
                        child: Container(
                          width: 38,
                          height: 38,
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [kPrimaryColor, kAccentColor],
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.add_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            FocusScope(
              child: Focus(
                onFocusChange: (hasFocus) => setState(() {}),
                child: Builder(
                  builder: (context) {
                    final bool isFocused = Focus.of(context).hasFocus;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(100),
                        gradient: isFocused
                            ? const LinearGradient(
                                colors: [kPrimaryColor, kAccentColor],
                              )
                            : const LinearGradient(
                                colors: [
                                  Colors.transparent,
                                  Colors.transparent,
                                ],
                              ),
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: TextField(
                          controller: _textController,
                          style: const TextStyle(
                            fontFamily: 'SF Pro',
                            fontSize: 14,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Enter text or link here',
                            prefixIcon: Icon(
                              Icons.bolt_rounded,
                              color: isFocused ? kPrimaryColor : Colors.grey,
                            ),
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(100),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 16,
                              horizontal: 20,
                            ),
                          ),
                          onChanged: (value) => setState(
                            () => _qrData = value.trim().isEmpty
                                ? null
                                : value.trim(),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: isDataValid
                          ? const LinearGradient(
                              colors: [kPrimaryColor, kAccentColor],
                            )
                          : null,
                      color: isDataValid ? null : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: ElevatedButton.icon(
                      onPressed: isDataValid ? _shareQrCode : null,
                      icon: const Icon(
                        Icons.share_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                      label: const Text(
                        'Share',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(100),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    height: 56,
                    decoration: BoxDecoration(
                      color: isDataValid ? Colors.white : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(100),
                      boxShadow: isDataValid
                          ? [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                              ),
                            ]
                          : null,
                    ),
                    child: isDataValid
                        ? ShaderMask(
                            shaderCallback: (Rect bounds) =>
                                const LinearGradient(
                                  colors: [kPrimaryColor, kAccentColor],
                                ).createShader(bounds),
                            child: ElevatedButton.icon(
                              onPressed: _saveToGallery,
                              icon: const Icon(
                                Icons.save_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
                              label: const Text(
                                'Save',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Colors.white,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(100),
                                ),
                              ),
                            ),
                          )
                        : const Center(
                            child: Text(
                              "Save",
                              style: TextStyle(
                                color: Colors.grey,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: () => setState(() {
                  _textController.clear();
                  _qrData = null;
                  _qrColor = Colors.white;
                }),
                icon: const Icon(
                  Icons.refresh_rounded,
                  color: Colors.white,
                  size: 20,
                ),
                label: const Text(
                  'Reset All Settings',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: kErrorColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(100),
                  ),
                  elevation: 0,
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
