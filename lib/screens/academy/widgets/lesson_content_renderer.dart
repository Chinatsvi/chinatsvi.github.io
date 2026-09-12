import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';

import '../../../models/academy/lesson_block_model.dart';
import '../../../models/academy/quiz_model.dart';
import '../../farm_works/fertilizer_calculator.dart';
import '../../farm_works/irrigation_calculator.dart';
import '../../farm_works/profit_calculator.dart';
import '../../farm_works/break_even_calculator.dart';
import '../../farm_works/population_calculator.dart';
import '../../farm_works/spacing_calculator.dart';
import '../quiz_screen.dart';

class LessonContentRenderer extends StatelessWidget {
  final List<LessonBlockModel> blocks;
  final bool isDataSaver;
  final Function(int score)? onQuizPassed;

  const LessonContentRenderer({
    super.key,
    required this.blocks,
    this.isDataSaver = false,
    this.onQuizPassed,
  });

  @override
  Widget build(BuildContext context) {
    if (blocks.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(
          child: Text(
            'No content blocks in this lesson yet.',
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: blocks.map((block) => _buildBlock(context, block)).toList(),
    );
  }

  Widget _buildBlock(BuildContext context, LessonBlockModel block) {
    switch (block.type) {
      case LessonBlockType.text:
        return _buildTextBlock(block);
      case LessonBlockType.image:
        return _buildImageBlock(context, block);
      case LessonBlockType.video:
        return _VideoBlockWidget(block: block, isDataSaver: isDataSaver);
      case LessonBlockType.pdf:
        return _buildPdfBlock(context, block);
      case LessonBlockType.tip:
        return _buildTipBlock(block);
      case LessonBlockType.warning:
        return _buildWarningBlock(block);
      case LessonBlockType.quiz:
        return _buildQuizBlock(context, block);
      case LessonBlockType.calculator:
        return _buildCalculatorBlock(context, block);
      case LessonBlockType.link:
        return _buildLinkBlock(context, block);
    }
  }

  Widget _buildTextBlock(LessonBlockModel block) {
    final content = block.content ?? '';
    if (content.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: MarkdownBody(
        data: content,
        styleSheet: MarkdownStyleSheet(
          p: const TextStyle(fontSize: 15, height: 1.5, color: Colors.black87),
          h1: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.green),
          h2: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
          h3: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
          listBullet: const TextStyle(fontSize: 15, color: Colors.green),
          strong: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
        ),
      ),
    );
  }

  Widget _buildImageBlock(BuildContext context, LessonBlockModel block) {
    final url = block.mediaUrl ?? '';
    if (url.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: CachedNetworkImage(
              imageUrl: url,
              width: double.infinity,
              fit: BoxFit.cover,
              placeholder: (_, __) => Container(
                height: 180,
                color: Colors.grey.shade200,
                child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
              ),
              errorWidget: (_, __, ___) => Container(
                height: 140,
                color: Colors.grey.shade200,
                child: const Center(
                  child: Icon(Icons.broken_image_outlined, size: 40, color: Colors.grey),
                ),
              ),
            ),
          ),
          if (block.caption != null && block.caption!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              block.caption!,
              style: TextStyle(
                fontSize: 12,
                fontStyle: FontStyle.italic,
                color: Colors.grey[700],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPdfBlock(BuildContext context, LessonBlockModel block) {
    final url = block.mediaUrl ?? '';
    final title = block.title ?? 'Download Supporting PDF Material';

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.blue.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.picture_as_pdf, color: Colors.blue.shade800, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Colors.blue.shade900,
                  ),
                ),
                if (block.content != null && block.content!.isNotEmpty)
                  Text(
                    block.content!,
                    style: TextStyle(fontSize: 12, color: Colors.blue.shade800),
                  ),
              ],
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade700,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              if (url.isNotEmpty) {
                final uri = Uri.parse(url);
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              }
            },
            child: const Text('Open PDF', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _buildTipBlock(LessonBlockModel block) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.shade400, width: 1.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.lightbulb_outline, color: Colors.green.shade800, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  block.title ?? '💡 FARMER TIP',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Colors.green.shade900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  block.content ?? '',
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.4,
                    color: Colors.green.shade900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWarningBlock(LessonBlockModel block) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber.shade600, width: 1.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.warning_amber_rounded, color: Colors.amber.shade900, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  block.title ?? '⚠️ IMPORTANT',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Colors.amber.shade900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  block.content ?? '',
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.4,
                    color: Colors.amber.shade900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuizBlock(BuildContext context, LessonBlockModel block) {
    final quiz = block.metadata != null
        ? QuizModel.fromMap(block.metadata!)
        : QuizModel(id: block.id, title: block.title ?? 'Knowledge Check');

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.purple.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.purple.shade300, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.purple.shade100,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.quiz, color: Colors.purple.shade800, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      quiz.title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.purple.shade900,
                      ),
                    ),
                    Text(
                      '${quiz.questions.length} Questions • Pass mark: ${quiz.passPercentage}%',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.purple.shade800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            quiz.description,
            style: TextStyle(fontSize: 13, color: Colors.purple.shade900),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple.shade700,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              icon: const Icon(Icons.play_arrow, size: 20),
              label: const Text('Start Quiz', style: TextStyle(fontWeight: FontWeight.bold)),
              onPressed: () async {
                final result = await Navigator.push<int>(
                  context,
                  MaterialPageRoute(
                    builder: (_) => QuizScreen(quiz: quiz),
                  ),
                );
                if (result != null && onQuizPassed != null) {
                  onQuizPassed!(result);
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalculatorBlock(BuildContext context, LessonBlockModel block) {
    final type = (block.calculatorType ?? 'fertilizer').toLowerCase();
    final name = _getCalculatorName(type);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.teal.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.teal.shade300, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.teal.shade100,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.calculate, color: Colors.teal.shade800, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  block.title ?? 'Practical Field Tool: $name',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Colors.teal.shade900,
                  ),
                ),
              ),
            ],
          ),
          if (block.content != null && block.content!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              block.content!,
              style: TextStyle(fontSize: 13, color: Colors.teal.shade900),
            ),
          ],
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal.shade700,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              icon: const Icon(Icons.open_in_new, size: 18),
              label: Text('Open $name', style: const TextStyle(fontWeight: FontWeight.bold)),
              onPressed: () => _openCalculator(context, type),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLinkBlock(BuildContext context, LessonBlockModel block) {
    final url = block.linkUrl ?? '';
    final title = block.linkTitle ?? 'Approved Agricultural Resource';

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          side: BorderSide(color: Colors.green.shade600),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        icon: Icon(Icons.link, color: Colors.green.shade700),
        label: Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.green.shade900,
            ),
          ),
        ),
        onPressed: () async {
          if (url.isNotEmpty) {
            final uri = Uri.parse(url.startsWith('http') ? url : 'https://$url');
            if (await canLaunchUrl(uri)) {
              await launchUrl(uri, mode: LaunchMode.externalApplication);
            }
          }
        },
      ),
    );
  }

  String _getCalculatorName(String type) {
    switch (type) {
      case 'fertilizer':
        return 'Fertilizer Calculator';
      case 'irrigation':
        return 'Irrigation Calculator';
      case 'profit':
        return 'Farm Profit Calculator';
      case 'break_even':
        return 'Break-even Calculator';
      case 'population':
        return 'Plant Population Calculator';
      case 'spacing':
        return 'Spacing Calculator';
      default:
        return 'Farm Calculator';
    }
  }

  void _openCalculator(BuildContext context, String type) {
    Widget screen;
    switch (type) {
      case 'fertilizer':
        screen = const FertilizerCalculator();
        break;
      case 'irrigation':
        screen = const IrrigationCalculator();
        break;
      case 'profit':
        screen = const ProfitCalculator();
        break;
      case 'break_even':
        screen = const BreakEvenCalculator();
        break;
      case 'population':
        screen = const PopulationCalculator();
        break;
      case 'spacing':
        screen = const SpacingCalculator();
        break;
      default:
        screen = const FertilizerCalculator();
    }

    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }
}

class _VideoBlockWidget extends StatefulWidget {
  final LessonBlockModel block;
  final bool isDataSaver;

  const _VideoBlockWidget({required this.block, required this.isDataSaver});

  @override
  State<_VideoBlockWidget> createState() => _VideoBlockWidgetState();
}

class _VideoBlockWidgetState extends State<_VideoBlockWidget> {
  VideoPlayerController? _videoPlayerController;
  ChewieController? _chewieController;
  bool _isPlaying = false;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    if (!widget.isDataSaver) {
      _initVideo();
    }
  }

  Future<void> _initVideo() async {
    final url = widget.block.mediaUrl ?? '';
    if (url.isEmpty) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      _videoPlayerController = VideoPlayerController.networkUrl(Uri.parse(url));
      await _videoPlayerController!.initialize();

      _chewieController = ChewieController(
        videoPlayerController: _videoPlayerController!,
        autoPlay: false,
        looping: false,
        aspectRatio: _videoPlayerController!.value.aspectRatio > 0
            ? _videoPlayerController!.value.aspectRatio
            : 16 / 9,
        materialProgressColors: ChewieProgressColors(
          playedColor: Colors.green.shade600,
          handleColor: Colors.green.shade800,
          backgroundColor: Colors.grey.shade300,
          bufferedColor: Colors.green.shade100,
        ),
      );

      if (mounted) {
        setState(() {
          _isPlaying = true;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage =
              'Video could not be loaded. Check your internet connection.';
        });
      }
    }
  }

  @override
  void dispose() {
    _chewieController?.dispose();
    _videoPlayerController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_errorMessage != null) {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.red.shade200),
        ),
        child: Column(
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 32),
            const SizedBox(height: 6),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.red.shade800, fontSize: 13),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: _initVideo,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry Video'),
            ),
          ],
        ),
      );
    }

    if (_isPlaying && _chewieController != null) {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.black,
        ),
        clipBehavior: Clip.antiAlias,
        child: AspectRatio(
          aspectRatio: _chewieController!.aspectRatio ?? 16 / 9,
          child: Chewie(controller: _chewieController!),
        ),
      );
    }

    // Data Saver prompt or loading state
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      height: 180,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: _isLoading
            ? const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Colors.green),
                  SizedBox(height: 10),
                  Text('Loading video stream...', style: TextStyle(color: Colors.white70)),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.play_circle_fill, size: 54, color: Colors.green),
                  const SizedBox(height: 8),
                  const Text(
                    'Educational Video Lesson',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.isDataSaver
                        ? '📶 Data Saver is ON • Tap to stream'
                        : 'Tap to play video',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade700,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                    onPressed: _initVideo,
                    child: const Text('Play Video'),
                  ),
                ],
              ),
      ),
    );
  }
}
