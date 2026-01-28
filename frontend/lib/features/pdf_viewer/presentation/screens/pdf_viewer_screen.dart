/// PDF Viewer Screen with Deep Link to Page
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';

/// PDF Viewer Screen that opens a specific page (deep link).
/// Uses Syncfusion PDF Viewer for PDF rendering.
class PdfViewerScreen extends ConsumerStatefulWidget {
  final int documentId;
  final int initialPage;

  const PdfViewerScreen({
    super.key,
    required this.documentId,
    this.initialPage = 1,
  });

  @override
  ConsumerState<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends ConsumerState<PdfViewerScreen> {
  // In a real implementation, you would load the PDF from the backend
  // using the documentId and then jump to the initialPage.
  
  // For Syncfusion PDF Viewer:
  // late PdfViewerController _pdfViewerController;
  // 
  // @override
  // void initState() {
  //   super.initState();
  //   _pdfViewerController = PdfViewerController();
  //   
  //   // Jump to specific page after PDF loads
  //   WidgetsBinding.instance.addPostFrameCallback((_) {
  //     _pdfViewerController.jumpToPage(widget.initialPage);
  //   });
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Doküman #${widget.documentId}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.zoom_in),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.zoom_out),
            onPressed: () {},
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Placeholder UI - Replace with actual PDF viewer
            Container(
              width: 300,
              height: 400,
              decoration: BoxDecoration(
                color: AppTheme.darkCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.darkBorder),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.picture_as_pdf,
                    size: 80,
                    color: AppTheme.primaryColor,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'PDF Görüntüleyici',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Sayfa ${widget.initialPage}',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Deep Link Aktif ✓',
                      style: TextStyle(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.symmetric(horizontal: 24),
              decoration: BoxDecoration(
                color: AppTheme.darkSurface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.info_outline,
                    color: AppTheme.textMuted,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Gerçek uygulamada, bu ekran Syncfusion PDF Viewer veya benzeri bir kütüphane ile PDF\'i gösterir ve otomatik olarak sayfa ${widget.initialPage}\'e scroll eder.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.textMuted,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      
      // Bottom navigation for page controls
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.darkCard,
          border: Border(
            top: BorderSide(color: AppTheme.darkBorder),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left),
              onPressed: () {
                // Previous page
              },
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.darkSurface,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Sayfa ${widget.initialPage}',
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right),
              onPressed: () {
                // Next page
              },
            ),
          ],
        ),
      ),
    );
  }
}

/*
IMPLEMENTATION NOTE:
To enable full PDF viewing with deep linking, install syncfusion_flutter_pdfviewer
and replace the placeholder above with:

```dart
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

class _PdfViewerScreenState extends ConsumerState<PdfViewerScreen> {
  late PdfViewerController _pdfViewerController;
  
  @override
  void initState() {
    super.initState();
    _pdfViewerController = PdfViewerController();
  }
  
  @override
  Widget build(BuildContext context) {
    // Fetch PDF URL from API based on widget.documentId
    final pdfUrl = 'https://your-api.com/documents/${widget.documentId}/file';
    
    return Scaffold(
      appBar: AppBar(title: Text('Document')),
      body: SfPdfViewer.network(
        pdfUrl,
        controller: _pdfViewerController,
        onDocumentLoaded: (details) {
          // Jump to specific page after loading
          _pdfViewerController.jumpToPage(widget.initialPage);
        },
      ),
    );
  }
}
```
*/
