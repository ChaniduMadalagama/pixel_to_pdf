import 'package:flutter/material.dart';
import 'package:pixel_to_pdf/pixel_to_pdf.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pixel to PDF Example',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: const Color(0xFF7C6AF6),
        scaffoldBackgroundColor: const Color(0xFF13131A),
        useMaterial3: true,
      ),
      home: const ExampleHome(),
    );
  }
}

class ExampleHome extends StatefulWidget {
  const ExampleHome({super.key});

  @override
  State<ExampleHome> createState() => _ExampleHomeState();
}

class _ExampleHomeState extends State<ExampleHome> {
  final List<AttachmentResult> _attachments = [];

  Future<void> _openPicker() async {
    final results = await PixelToPdf.show(
      context,
      config: const AttachmentConfig(
        features: [
          AttachmentFeature.scanDoc,
          AttachmentFeature.takePhoto,
          AttachmentFeature.fromGallery,
          AttachmentFeature.fromFiles,
        ],
        uiStyle: AttachmentUIStyle.bottomSheet,
      ),
    );

    if (results != null && results.isNotEmpty) {
      setState(() {
        _attachments.addAll(results);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pixel to PDF'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _attachments.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.cloud_upload_outlined,
                    size: 80,
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No attachments yet',
                    style: TextStyle(color: Colors.white38),
                  ),
                ],
              ),
            )
          : GridView.builder(
              padding: const EdgeInsets.all(20),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1,
              ),
              itemCount: _attachments.length,
              itemBuilder: (context, index) {
                final result = _attachments[index];
                // Using the package's built-in thumbnail widget
                return AttachmentThumbnailWidget(
                  result: result,
                  onDelete: () {
                    setState(() {
                      _attachments.removeAt(index);
                    });
                  },
                  onTap: () {
                    // Using the package's built-in viewer
                    // AttachmentViewer.show(context, result);
                  },
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openPicker,
        backgroundColor: const Color(0xFF7C6AF6),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Add Attachment', style: TextStyle(color: Colors.white)),
      ),
    );
  }
}
