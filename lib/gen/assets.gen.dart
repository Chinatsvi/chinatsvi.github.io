// dart format width=80

/// GENERATED CODE - DO NOT MODIFY BY HAND
/// *****************************************************
///  FlutterGen
/// *****************************************************

// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: deprecated_member_use,directives_ordering,implicit_dynamic_list_literal,unnecessary_import

import 'package:flutter/widgets.dart';

class $AssetsIconGen {
  const $AssetsIconGen();

  /// File path: assets/icon/agri_base_icon.png
  AssetGenImage get agriBaseIcon =>
      const AssetGenImage('assets/icon/agri_base_icon.png');

  /// File path: assets/icon/cattle.png
  AssetGenImage get cattle => const AssetGenImage('assets/icon/cattle.png');

  /// File path: assets/icon/chinatsvi.png
  AssetGenImage get chinatsvi =>
      const AssetGenImage('assets/icon/chinatsvi.png');

  /// File path: assets/icon/field_cctv.png
  AssetGenImage get fieldCctv =>
      const AssetGenImage('assets/icon/field_cctv.png');

  /// File path: assets/icon/huku.png
  AssetGenImage get huku => const AssetGenImage('assets/icon/huku.png');

  /// File path: assets/icon/livestock.png
  AssetGenImage get livestock =>
      const AssetGenImage('assets/icon/livestock.png');

  /// File path: assets/icon/verification_tick.png
  AssetGenImage get verificationTick =>
      const AssetGenImage('assets/icon/verification_tick.png');

  /// List of all assets
  List<AssetGenImage> get values => [
    agriBaseIcon,
    cattle,
    chinatsvi,
    fieldCctv,
    huku,
    livestock,
    verificationTick,
  ];
}

class $AssetsImagesGen {
  const $AssetsImagesGen();

  /// File path: assets/images/chinatsvi.png
  AssetGenImage get chinatsvi =>
      const AssetGenImage('assets/images/chinatsvi.png');

  /// File path: assets/images/chinatsvi_cover.jpg
  AssetGenImage get chinatsviCover =>
      const AssetGenImage('assets/images/chinatsvi_cover.jpg');

  /// File path: assets/images/default_avatar.png
  AssetGenImage get defaultAvatar =>
      const AssetGenImage('assets/images/default_avatar.png');

  /// File path: assets/images/dorcas.jpg
  AssetGenImage get dorcas => const AssetGenImage('assets/images/dorcas.jpg');

  /// File path: assets/images/dorcas_cover.jpg
  AssetGenImage get dorcasCover =>
      const AssetGenImage('assets/images/dorcas_cover.jpg');

  /// File path: assets/images/farmer_cover.jpg
  AssetGenImage get farmerCover =>
      const AssetGenImage('assets/images/farmer_cover.jpg');

  /// File path: assets/images/logo.png
  AssetGenImage get logo => const AssetGenImage('assets/images/logo.png');

  /// List of all assets
  List<AssetGenImage> get values => [
    chinatsvi,
    chinatsviCover,
    defaultAvatar,
    dorcas,
    dorcasCover,
    farmerCover,
    logo,
  ];
}

class $AssetsVideosGen {
  const $AssetsVideosGen();

  /// File path: assets/videos/intro.mp4
  String get intro => 'assets/videos/intro.mp4';

  /// List of all assets
  List<String> get values => [intro];
}

class Assets {
  const Assets._();

  static const String aEnv = '.env';
  static const $AssetsIconGen icon = $AssetsIconGen();
  static const $AssetsImagesGen images = $AssetsImagesGen();
  static const $AssetsVideosGen videos = $AssetsVideosGen();

  /// List of all assets
  static List<String> get values => [aEnv];
}

class AssetGenImage {
  const AssetGenImage(
    this._assetName, {
    this.size,
    this.flavors = const {},
    this.animation,
  });

  final String _assetName;

  final Size? size;
  final Set<String> flavors;
  final AssetGenImageAnimation? animation;

  Image image({
    Key? key,
    AssetBundle? bundle,
    ImageFrameBuilder? frameBuilder,
    ImageErrorWidgetBuilder? errorBuilder,
    String? semanticLabel,
    bool excludeFromSemantics = false,
    double? scale,
    double? width,
    double? height,
    Color? color,
    Animation<double>? opacity,
    BlendMode? colorBlendMode,
    BoxFit? fit,
    AlignmentGeometry alignment = Alignment.center,
    ImageRepeat repeat = ImageRepeat.noRepeat,
    Rect? centerSlice,
    bool matchTextDirection = false,
    bool gaplessPlayback = true,
    bool isAntiAlias = false,
    String? package,
    FilterQuality filterQuality = FilterQuality.medium,
    int? cacheWidth,
    int? cacheHeight,
  }) {
    return Image.asset(
      _assetName,
      key: key,
      bundle: bundle,
      frameBuilder: frameBuilder,
      errorBuilder: errorBuilder,
      semanticLabel: semanticLabel,
      excludeFromSemantics: excludeFromSemantics,
      scale: scale,
      width: width,
      height: height,
      color: color,
      opacity: opacity,
      colorBlendMode: colorBlendMode,
      fit: fit,
      alignment: alignment,
      repeat: repeat,
      centerSlice: centerSlice,
      matchTextDirection: matchTextDirection,
      gaplessPlayback: gaplessPlayback,
      isAntiAlias: isAntiAlias,
      package: package,
      filterQuality: filterQuality,
      cacheWidth: cacheWidth,
      cacheHeight: cacheHeight,
    );
  }

  ImageProvider provider({AssetBundle? bundle, String? package}) {
    return AssetImage(_assetName, bundle: bundle, package: package);
  }

  String get path => _assetName;

  String get keyName => _assetName;
}

class AssetGenImageAnimation {
  const AssetGenImageAnimation({
    required this.isAnimation,
    required this.duration,
    required this.frames,
  });

  final bool isAnimation;
  final Duration duration;
  final int frames;
}
