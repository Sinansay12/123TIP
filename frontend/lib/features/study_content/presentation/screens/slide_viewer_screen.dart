/// Slide Viewer Screen
/// Displays slide content page by page with navigation
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/slide_models.dart';

class SlideViewerScreen extends ConsumerStatefulWidget {
  final String department;
  final String topic;
  final int? initialPage;
  final List<Slide> slides;

  const SlideViewerScreen({
    super.key,
    required this.department,
    required this.topic,
    required this.slides,
    this.initialPage,
  });

  @override
  ConsumerState<SlideViewerScreen> createState() => _SlideViewerScreenState();
}

class _SlideViewerScreenState extends ConsumerState<SlideViewerScreen> {
  late PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _currentPage = (widget.initialPage ?? 1) - 1;
    _pageController = PageController(initialPage: _currentPage);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.topic),
        actions: [
          // Page indicator
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                '${_currentPage + 1} / ${widget.slides.length}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Professor info
          if (widget.slides.isNotEmpty && widget.slides[_currentPage].professor != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: AppTheme.darkCard,
              child: Row(
                children: [
                  const Icon(Icons.person, size: 16, color: AppTheme.textSecondary),
                  const SizedBox(width: 8),
                  Text(
                    widget.slides[_currentPage].professor!,
                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                  ),
                ],
              ),
            ),
          
          // Slide content
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              itemCount: widget.slides.length,
              onPageChanged: (index) => setState(() => _currentPage = index),
              itemBuilder: (context, index) {
                final slide = widget.slides[index];
                return _buildSlideContent(slide);
              },
            ),
          ),
          
          // Navigation bar
          _buildNavigationBar(),
        ],
      ),
    );
  }

  Widget _buildSlideContent(Slide slide) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          if (slide.title != null) ...[
            Text(
              slide.title!,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
          ],
          
          // Image
          if (slide.imageUrl != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                slide.imageUrl!,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  height: 200,
                  color: AppTheme.darkCard,
                  child: const Center(
                    child: Icon(Icons.image_not_supported, size: 48),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
          
          // Main content
          Text(
            slide.content,
            style: const TextStyle(fontSize: 16, height: 1.6),
          ),
          
          // Bullet points
          if (slide.bulletPoints != null && slide.bulletPoints!.isNotEmpty) ...[
            const SizedBox(height: 16),
            ...slide.bulletPoints!.map((point) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      point,
                      style: const TextStyle(fontSize: 15, height: 1.5),
                    ),
                  ),
                ],
              ),
            )),
          ],
        ],
      ),
    );
  }

  Widget _buildNavigationBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.darkCard,
        border: Border(
          top: BorderSide(color: AppTheme.darkBorder),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Previous button
          ElevatedButton.icon(
            onPressed: _currentPage > 0
                ? () {
                    _pageController.previousPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  }
                : null,
            icon: const Icon(Icons.arrow_back),
            label: const Text('Önceki'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.darkCard,
              foregroundColor: Colors.white,
            ),
          ),
          
          // Page dots
          Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(
              widget.slides.length > 10 ? 10 : widget.slides.length,
              (index) {
                final actualIndex = widget.slides.length > 10
                    ? ((_currentPage / widget.slides.length) * 10).round()
                    : index;
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  width: index == actualIndex ? 12 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: index == actualIndex
                        ? AppTheme.primaryColor
                        : AppTheme.textSecondary.withAlpha(100),
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              },
            ),
          ),
          
          // Next button
          ElevatedButton.icon(
            onPressed: _currentPage < widget.slides.length - 1
                ? () {
                    _pageController.nextPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  }
                : null,
            icon: const Icon(Icons.arrow_forward),
            label: const Text('Sonraki'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
            ),
          ),
        ],
      ),
    );
  }
}
