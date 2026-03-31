import 'package:flutter/material.dart';

/// Responsive design utility class with media queries
class ResponsiveHelper {
  // Breakpoints for different screen sizes
  static const double mobileMaxWidth = 600;
  static const double tabletMinWidth = 601;
  static const double tabletMaxWidth = 1024;
  static const double desktopMinWidth = 1025;

  /// Get screen size category (mobile, tablet, desktop)
  static ScreenSize getScreenSize(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    if (width <= mobileMaxWidth) {
      return ScreenSize.mobile;
    } else if (width <= tabletMaxWidth) {
      return ScreenSize.tablet;
    } else {
      return ScreenSize.desktop;
    }
  }

  /// Check if device is in portrait mode
  static bool isPortrait(BuildContext context) {
    return MediaQuery.of(context).orientation == Orientation.portrait;
  }

  /// Check if device is in landscape mode
  static bool isLandscape(BuildContext context) {
    return MediaQuery.of(context).orientation == Orientation.landscape;
  }

  /// Get device width
  static double getWidth(BuildContext context) {
    return MediaQuery.of(context).size.width;
  }

  /// Get device height
  static double getHeight(BuildContext context) {
    return MediaQuery.of(context).size.height;
  }

  /// Get padding based on screen size
  static EdgeInsets getPadding(BuildContext context) {
    final size = getScreenSize(context);
    switch (size) {
      case ScreenSize.mobile:
        return const EdgeInsets.all(16);
      case ScreenSize.tablet:
        return const EdgeInsets.all(24);
      case ScreenSize.desktop:
        return const EdgeInsets.all(32);
    }
  }

  /// Get font size based on screen size
  static double getFontSize(BuildContext context,
      {double mobile = 14, double tablet = 16, double desktop = 18}) {
    final size = getScreenSize(context);
    switch (size) {
      case ScreenSize.mobile:
        return mobile;
      case ScreenSize.tablet:
        return tablet;
      case ScreenSize.desktop:
        return desktop;
    }
  }

  /// Get grid columns based on screen size
  static int getGridColumns(BuildContext context) {
    final size = getScreenSize(context);
    switch (size) {
      case ScreenSize.mobile:
        return 1;
      case ScreenSize.tablet:
        return 2;
      case ScreenSize.desktop:
        return 3;
    }
  }

  /// Get max width for content (useful for limiting content on large screens)
  static double getMaxContentWidth(BuildContext context) {
    final width = getWidth(context);
    final size = getScreenSize(context);

    switch (size) {
      case ScreenSize.mobile:
        return width;
      case ScreenSize.tablet:
        return width * 0.9;
      case ScreenSize.desktop:
        return 1200;
    }
  }

  /// Get horizontal spacing based on screen size
  static double getHorizontalSpacing(BuildContext context) {
    final size = getScreenSize(context);
    switch (size) {
      case ScreenSize.mobile:
        return 8;
      case ScreenSize.tablet:
        return 12;
      case ScreenSize.desktop:
        return 16;
    }
  }

  /// Get vertical spacing based on screen size
  static double getVerticalSpacing(BuildContext context) {
    final size = getScreenSize(context);
    switch (size) {
      case ScreenSize.mobile:
        return 12;
      case ScreenSize.tablet:
        return 16;
      case ScreenSize.desktop:
        return 20;
    }
  }

  /// Get icon size based on screen size
  static double getIconSize(BuildContext context,
      {double mobile = 24, double tablet = 28, double desktop = 32}) {
    final size = getScreenSize(context);
    switch (size) {
      case ScreenSize.mobile:
        return mobile;
      case ScreenSize.tablet:
        return tablet;
      case ScreenSize.desktop:
        return desktop;
    }
  }

  /// Get border radius based on screen size
  static BorderRadius getBorderRadius(BuildContext context) {
    final size = getScreenSize(context);
    switch (size) {
      case ScreenSize.mobile:
        return BorderRadius.circular(8);
      case ScreenSize.tablet:
        return BorderRadius.circular(10);
      case ScreenSize.desktop:
        return BorderRadius.circular(12);
    }
  }
}

/// Enum for screen size categories
enum ScreenSize { mobile, tablet, desktop }

/// Layout builder for responsive design
class ResponsiveLayout extends StatelessWidget {
  final Widget mobileLayout;
  final Widget? tabletLayout;
  final Widget? desktopLayout;

  const ResponsiveLayout({
    super.key,
    required this.mobileLayout,
    this.tabletLayout,
    this.desktopLayout,
  });

  @override
  Widget build(BuildContext context) {
    final screenSize = ResponsiveHelper.getScreenSize(context);

    switch (screenSize) {
      case ScreenSize.mobile:
        return mobileLayout;
      case ScreenSize.tablet:
        return tabletLayout ?? mobileLayout;
      case ScreenSize.desktop:
        return desktopLayout ?? tabletLayout ?? mobileLayout;
    }
  }
}
