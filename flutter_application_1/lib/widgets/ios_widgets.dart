import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../theme/ios_theme.dart';
import 'dart:ui';

/// 🍎 iOS-Style Button with Haptic Feedback
class IOSButton extends StatefulWidget {
  final String text;
  final VoidCallback onPressed;
  final Color? color;
  final IconData? icon;
  final bool isLarge;
  final bool isLoading;

  const IOSButton({
    Key? key,
    required this.text,
    required this.onPressed,
    this.color,
    this.icon,
    this.isLarge = false,
    this.isLoading = false,
  }) : super(key: key);

  @override
  State<IOSButton> createState() => _IOSButtonState();
}

class _IOSButtonState extends State<IOSButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: IOSTheme.quickDuration,
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.94).animate(
      CurvedAnimation(parent: _controller, curve: IOSTheme.iosCurve),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onPressed();
      },
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          height: widget.isLarge ? 56 : 48,
          padding: EdgeInsets.symmetric(
            horizontal: widget.isLarge ? 24 : 20,
          ),
          decoration: IOSTheme.iosButton(
            color: widget.color ?? IOSTheme.iosBlue,
            borderRadius: widget.isLarge ? 14 : 12,
          ),
          child: Center(
            child: widget.isLoading
                ? const CupertinoActivityIndicator(
                    color: Colors.white,
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (widget.icon != null) ...[
                        Icon(
                          widget.icon,
                          color: Colors.white,
                          size: widget.isLarge ? 22 : 18,
                        ),
                        const SizedBox(width: 8),
                      ],
                      Text(
                        widget.text,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: widget.isLarge ? 17 : 16,
                          fontWeight: IOSTheme.semibold,
                          letterSpacing: -0.408,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

/// 🔲 iOS Card with Frosted Glass Effect
class IOSCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final VoidCallback? onTap;
  final bool isFrosted;

  const IOSCard({
    Key? key,
    required this.child,
    this.padding,
    this.onTap,
    this.isFrosted = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final content = Container(
      padding: padding ?? const EdgeInsets.all(IOSTheme.spacing16),
      decoration: isFrosted
          ? IOSTheme.frostedGlass()
          : IOSTheme.iosCard(),
      child: child,
    );

    if (onTap != null) {
      return IOSTapEffect(
        onTap: onTap!,
        child: content,
      );
    }

    return content;
  }
}

/// 🎯 iOS Tap Effect (Scale Down)
class IOSTapEffect extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  final double scaleDown;

  const IOSTapEffect({
    Key? key,
    required this.child,
    required this.onTap,
    this.scaleDown = 0.96,
  }) : super(key: key);

  @override
  State<IOSTapEffect> createState() => _IOSTapEffectState();
}

class _IOSTapEffectState extends State<IOSTapEffect>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: IOSTheme.quickDuration,
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: widget.scaleDown).animate(
      CurvedAnimation(parent: _controller, curve: IOSTheme.iosCurve),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap();
      },
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: widget.child,
      ),
    );
  }
}

/// ✨ iOS Fade-In Animation
class IOSFadeIn extends StatefulWidget {
  final Widget child;
  final Duration delay;

  const IOSFadeIn({
    Key? key,
    required this.child,
    this.delay = Duration.zero,
  }) : super(key: key);

  @override
  State<IOSFadeIn> createState() => _IOSFadeInState();
}

class _IOSFadeInState extends State<IOSFadeIn>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: IOSTheme.standardDuration,
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: IOSTheme.iosCurve),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _controller, curve: IOSTheme.iosCurve),
    );

    Future.delayed(widget.delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: widget.child,
      ),
    );
  }
}

/// 🎨 iOS Avatar with Border
class IOSAvatar extends StatelessWidget {
  final String name;
  final Color color;
  final double size;

  const IOSAvatar({
    Key? key,
    required this.name,
    required this.color,
    this.size = 56,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        shape: BoxShape.circle,
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Center(
        child: Text(
          name[0].toUpperCase(),
          style: TextStyle(
            color: color,
            fontSize: size * 0.4,
            fontWeight: IOSTheme.semibold,
          ),
        ),
      ),
    );
  }
}

/// 🔔 iOS Badge
class IOSBadge extends StatelessWidget {
  final String text;
  final Color? color;

  const IOSBadge({
    Key? key,
    required this.text,
    this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: (color ?? IOSTheme.iosBlue).withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: (color ?? IOSTheme.iosBlue).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color ?? IOSTheme.iosBlue,
          fontSize: 12,
          fontWeight: IOSTheme.semibold,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

/// 📱 iOS Navigation Bar Button
class IOSNavButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final Color? color;

  const IOSNavButton({
    Key? key,
    required this.icon,
    required this.onPressed,
    this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return IOSTapEffect(
      scaleDown: 0.9,
      onTap: onPressed,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: (color ?? IOSTheme.iosBlue).withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          color: color ?? IOSTheme.iosBlue,
          size: 20,
        ),
      ),
    );
  }
}

/// 🌟 iOS Loading Spinner
class IOSLoading extends StatelessWidget {
  final double size;
  final Color? color;

  const IOSLoading({
    Key? key,
    this.size = 24,
    this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CupertinoActivityIndicator(
        color: color ?? IOSTheme.iosGray,
        radius: size / 2,
      ),
    );
  }
}

/// 🎭 iOS Blur Background
class IOSBlurBackground extends StatelessWidget {
  final Widget child;
  final double blur;

  const IOSBlurBackground({
    Key? key,
    required this.child,
    this.blur = 20,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          decoration: BoxDecoration(
            color: IOSTheme.iosBlurLight.withOpacity(0.7),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withOpacity(0.2),
              width: 0.5,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}

/// 🎯 iOS Segmented Control Style Toggle
class IOSSegment extends StatelessWidget {
  final List<String> segments;
  final int selectedIndex;
  final Function(int) onChanged;

  const IOSSegment({
    Key? key,
    required this.segments,
    required this.selectedIndex,
    required this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: IOSTheme.iosGray6,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: List.generate(segments.length, (index) {
          final isSelected = index == selectedIndex;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(index),
              child: AnimatedContainer(
                duration: IOSTheme.quickDuration,
                curve: IOSTheme.iosCurve,
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Text(
                  segments[index],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: IOSTheme.medium,
                    color: isSelected ? IOSTheme.iosLabel : IOSTheme.iosGray,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
