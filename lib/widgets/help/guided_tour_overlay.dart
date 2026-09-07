// NAKHL & NAHL — Interactive Guided Tour Overlay (Level 4 Education)
// Complies with Master Directive Section 21

import 'package:flutter/material.dart';

class TourStepItem {
  final String title;
  final String description;
  final Alignment alignment;

  const TourStepItem({
    required this.title,
    required this.description,
    this.alignment = Alignment.center,
  });
}

class GuidedTourOverlay extends StatefulWidget {
  final List<TourStepItem> steps;
  final VoidCallback onFinish;

  const GuidedTourOverlay({
    super.key,
    required this.steps,
    required this.onFinish,
  });

  static void start(BuildContext context, List<TourStepItem> steps, {VoidCallback? onFinish}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black54,
      builder: (ctx) => GuidedTourOverlay(
        steps: steps,
        onFinish: onFinish ?? () => Navigator.of(ctx).pop(),
      ),
    );
  }

  @override
  State<GuidedTourOverlay> createState() => _GuidedTourOverlayState();
}

class _GuidedTourOverlayState extends State<GuidedTourOverlay> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    if (widget.steps.isEmpty) return const SizedBox.shrink();
    final step = widget.steps[_currentIndex];

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Dismiss on outer tap (optional, or force button tap)
          Align(
            alignment: step.alignment,
            child: Container(
              margin: const EdgeInsets.all(32),
              padding: const EdgeInsets.all(24),
              constraints: const BoxConstraints(maxWidth: 480),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(color: Colors.black45, blurRadius: 24, offset: Offset(0, 10)),
                ],
                border: Border.all(color: const Color(0xFF10B981).withOpacity(0.5), width: 1.5),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${_currentIndex + 1} / ${widget.steps.length}',
                          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: widget.onFinish,
                        child: const Text('Turu Atla', style: TextStyle(color: Colors.white70)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    step.title,
                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    step.description,
                    style: TextStyle(color: Colors.grey.shade300, fontSize: 14, height: 1.45),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (_currentIndex > 0)
                        OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: Colors.white38),
                          ),
                          onPressed: () => setState(() => _currentIndex--),
                          child: const Text('Geri'),
                        )
                      else
                        const SizedBox.shrink(),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981),
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () {
                          if (_currentIndex < widget.steps.length - 1) {
                            setState(() => _currentIndex++);
                          } else {
                            widget.onFinish();
                          }
                        },
                        child: Text(_currentIndex < widget.steps.length - 1 ? 'İleri' : 'Turu Bitir'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
