import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/privacy_provider.dart';

class PrivacyText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  final String maskText;

  const PrivacyText(
    this.text, {
    super.key,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.maskText = '•••••',
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<PrivacyProvider>(
      builder: (context, privacyProvider, child) {
        final shouldHide = privacyProvider.shouldHideValues;
        
        return Text(
          shouldHide ? maskText : text,
          style: style,
          textAlign: textAlign,
          maxLines: maxLines,
          overflow: overflow,
        );
      },
    );
  }
}

class MaskedMoneyText extends StatelessWidget {
  final String amount;
  final String currency;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;

  const MaskedMoneyText({
    super.key,
    required this.amount,
    required this.currency,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<PrivacyProvider>(
      builder: (context, privacyProvider, child) {
        final shouldHide = privacyProvider.shouldHideValues;
        
        // Always return a Text widget with the appropriate content
        final displayText = shouldHide ? '$currency ••••••' : amount;
        
        return Text(
          displayText,
          style: style,
          textAlign: textAlign,
          maxLines: maxLines,
          overflow: overflow,
        );
      },
    );
  }
}

class PrivacyRevealButton extends StatelessWidget {
  final Widget child;

  const PrivacyRevealButton({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<PrivacyProvider>(
      builder: (context, privacyProvider, child) {
        if (!privacyProvider.isPrivacyModeEnabled) {
          return this.child;
        }

        return Stack(
          children: [
            this.child,
            if (privacyProvider.shouldHideValues)
              Positioned(
                top: 8,
                right: 8,
                child: GestureDetector(
                  onTapDown: (_) => privacyProvider.temporarilyReveal(),
                  onTapUp: (_) => privacyProvider.hideValues(),
                  onTapCancel: () => privacyProvider.hideValues(),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(
                      Icons.visibility,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}