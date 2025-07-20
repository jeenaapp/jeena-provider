import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../utils/media_validation.dart';

/// Media carousel widget for displaying images and videos
class MediaCarousel extends StatefulWidget {
  final List<MediaFile> mediaFiles;
  final bool showControls;
  final Function(int)? onRemove;
  final double? height;
  final bool isEditable;

  const MediaCarousel({
    super.key,
    required this.mediaFiles,
    this.showControls = true,
    this.onRemove,
    this.height,
    this.isEditable = false,
  });

  @override
  State<MediaCarousel> createState() => _MediaCarouselState();
}

class _MediaCarouselState extends State<MediaCarousel> {
  late PageController _pageController;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.mediaFiles.isEmpty) {
      return _buildEmptyState();
    }

    return Container(
      height: widget.height ?? 250,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.grey[100],
      ),
      child: Stack(
        children: [
          // Main carousel
          PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            itemCount: widget.mediaFiles.length,
            itemBuilder: (context, index) {
              final mediaFile = widget.mediaFiles[index];
              return _buildMediaItem(mediaFile, index);
            },
          ),

          // Page indicators
          if (widget.mediaFiles.length > 1)
            Positioned(
              bottom: 16,
              left: 0,
              right: 0,
              child: _buildPageIndicators(),
            ),

          // Navigation arrows
          if (widget.showControls && widget.mediaFiles.length > 1)
            _buildNavigationControls(),

          // Media info overlay
          if (widget.showControls)
            Positioned(
              top: 16,
              right: 16,
              child: _buildMediaInfo(),
            ),
        ],
      ),
    );
  }

  Widget _buildMediaItem(MediaFile mediaFile, int index) {
    return Container(
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            // Media content
            _buildMediaContent(mediaFile),

            // Remove button (if editable)
            if (widget.isEditable && widget.onRemove != null)
              Positioned(
                top: 8,
                left: 8,
                child: _buildRemoveButton(index),
              ),

            // Media type indicator
            Positioned(
              bottom: 8,
              left: 8,
              child: _buildMediaTypeIndicator(mediaFile),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMediaContent(MediaFile mediaFile) {
    if (mediaFile.type == 'image') {
      return GestureDetector(
        onTap: () => _showFullScreenImage(mediaFile),
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            image: DecorationImage(
              image: MemoryImage(mediaFile.bytes),
              fit: BoxFit.cover,
            ),
          ),
        ),
      );
    } else if (mediaFile.type == 'video') {
      return Container(
        width: double.infinity,
        height: double.infinity,
        color: Colors.black,
        child: Stack(
          children: [
            // Video thumbnail placeholder
            Container(
              width: double.infinity,
              height: double.infinity,
              color: Colors.grey[800],
              child: const Icon(
                Icons.video_library,
                size: 64,
                color: Colors.white,
              ),
            ),
            // Play button
            Center(
              child: GestureDetector(
                onTap: () => _showVideoPlayer(mediaFile),
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.play_arrow,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }
    
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.grey[300],
      child: const Icon(
        Icons.error,
        size: 48,
        color: Colors.grey,
      ),
    );
  }

  Widget _buildRemoveButton(int index) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        _showRemoveDialog(index);
      },
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.8),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.close,
          color: Colors.white,
          size: 20,
        ),
      ),
    );
  }

  Widget _buildMediaTypeIndicator(MediaFile mediaFile) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            mediaFile.type == 'image' ? Icons.image : Icons.videocam,
            color: Colors.white,
            size: 12,
          ),
          const SizedBox(width: 4),
          Text(
            mediaFile.formattedSize,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPageIndicators() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        widget.mediaFiles.length,
        (index) => Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _currentIndex == index
                ? Colors.white
                : Colors.white.withOpacity(0.4),
          ),
        ),
      ),
    );
  }

  Widget _buildNavigationControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Previous button
        if (_currentIndex > 0)
          Positioned(
            left: 16,
            top: 0,
            bottom: 0,
            child: Center(
              child: GestureDetector(
                onTap: () {
                  _pageController.previousPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                },
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.arrow_back_ios,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ),
          ),

        // Next button
        if (_currentIndex < widget.mediaFiles.length - 1)
          Positioned(
            right: 16,
            top: 0,
            bottom: 0,
            child: Center(
              child: GestureDetector(
                onTap: () {
                  _pageController.nextPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                },
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildMediaInfo() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.6),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        '${_currentIndex + 1} / ${widget.mediaFiles.length}',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      height: widget.height ?? 250,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.grey[100],
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.photo_library_outlined,
              size: 48,
              color: Colors.grey,
            ),
            SizedBox(height: 12),
            Text(
              'لا توجد صور أو فيديوهات',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showRemoveDialog(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text('حذف الملف'),
        content: const Text('هل أنت متأكد من حذف هذا الملف؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              widget.onRemove?.call(index);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
  }

  void _showFullScreenImage(MediaFile mediaFile) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => FullScreenImageView(mediaFile: mediaFile),
      ),
    );
  }

  void _showVideoPlayer(MediaFile mediaFile) {
    // In a real implementation, you'd use a video player plugin
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('سيتم إضافة مشغل الفيديو قريباً'),
      ),
    );
  }
}

/// Full screen image view
class FullScreenImageView extends StatelessWidget {
  final MediaFile mediaFile;

  const FullScreenImageView({
    super.key,
    required this.mediaFile,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Center(
        child: InteractiveViewer(
          child: Image.memory(
            mediaFile.bytes,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}