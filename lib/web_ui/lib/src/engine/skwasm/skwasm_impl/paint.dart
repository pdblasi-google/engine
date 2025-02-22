// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ffi';

import 'package:ui/src/engine.dart';
import 'package:ui/src/engine/skwasm/skwasm_impl.dart';
import 'package:ui/ui.dart' as ui;

class SkwasmPaint implements ui.Paint {
  factory SkwasmPaint() {
    return SkwasmPaint._fromHandle(paintCreate());
  }

  SkwasmPaint._fromHandle(this._handle);
  PaintHandle _handle;

  PaintHandle get handle => _handle;

  ui.BlendMode _cachedBlendMode = ui.BlendMode.srcOver;

  SkwasmShader? _shader;
  ui.ImageFilter? _imageFilter;

  EngineColorFilter? _colorFilter;

  ui.MaskFilter? _maskFilter;

  bool _invertColors = false;

  static final SkwasmColorFilter _invertColorFilter = SkwasmColorFilter.fromEngineColorFilter(
    const EngineColorFilter.matrix(<double>[
      -1.0, 0, 0, 1.0, 0, // row
      0, -1.0, 0, 1.0, 0, // row
      0, 0, -1.0, 1.0, 0, // row
      1.0, 1.0, 1.0, 1.0, 0
    ])
  );

  @override
  ui.BlendMode get blendMode {
    return _cachedBlendMode;
  }

  @override
  set blendMode(ui.BlendMode blendMode) {
    if (_cachedBlendMode != blendMode) {
      _cachedBlendMode = blendMode;
      paintSetBlendMode(_handle, blendMode.index);
    }
  }

  @override
  ui.PaintingStyle get style => ui.PaintingStyle.values[paintGetStyle(_handle)];

  @override
  set style(ui.PaintingStyle style) => paintSetStyle(_handle, style.index);

  @override
  double get strokeWidth => paintGetStrokeWidth(_handle);

  @override
  set strokeWidth(double width) => paintSetStrokeWidth(_handle, width);

  @override
  ui.StrokeCap get strokeCap => ui.StrokeCap.values[paintGetStrokeCap(_handle)];

  @override
  set strokeCap(ui.StrokeCap cap) => paintSetStrokeCap(_handle, cap.index);

  @override
  ui.StrokeJoin get strokeJoin => ui.StrokeJoin.values[paintGetStrokeJoin(_handle)];

  @override
  set strokeJoin(ui.StrokeJoin join) => paintSetStrokeJoin(_handle, join.index);

  @override
  bool get isAntiAlias => paintGetAntiAlias(_handle);

  @override
  set isAntiAlias(bool value) => paintSetAntiAlias(_handle, value);

  @override
  ui.Color get color => ui.Color(paintGetColorInt(_handle));

  @override
  set color(ui.Color color) => paintSetColorInt(_handle, color.value);

  @override
  double get strokeMiterLimit => paintGetMiterLimit(_handle);

  @override
  set strokeMiterLimit(double limit) => paintSetMiterLimit(_handle, limit);

  @override
  ui.Shader? get shader => _shader;

  @override
  set shader(ui.Shader? uiShader) {
    final SkwasmShader? skwasmShader = uiShader as SkwasmShader?;
    _shader = skwasmShader;
    final ShaderHandle shaderHandle =
      skwasmShader != null ? skwasmShader.handle : nullptr;
    paintSetShader(_handle, shaderHandle);
  }

  @override
  ui.FilterQuality filterQuality = ui.FilterQuality.none;

  @override
  ui.ImageFilter? get imageFilter => _imageFilter;

  @override
  set imageFilter(ui.ImageFilter? filter) {
    _imageFilter = filter;

    final SkwasmImageFilter? nativeImageFilter = filter != null
      ? SkwasmImageFilter.fromUiFilter(filter)
      : null;
    paintSetImageFilter(handle, nativeImageFilter != null ? nativeImageFilter.handle : nullptr);
  }

  @override
  ui.ColorFilter? get colorFilter => _colorFilter;

  void _setEffectiveColorFilter() {
    final SkwasmColorFilter? nativeFilter = _colorFilter != null
      ? SkwasmColorFilter.fromEngineColorFilter(_colorFilter!) : null;
    if (_invertColors) {
      if (nativeFilter != null) {
        final SkwasmColorFilter composedFilter = SkwasmColorFilter.composed(_invertColorFilter, nativeFilter);
        nativeFilter.dispose();
        paintSetColorFilter(handle, composedFilter.handle);
        composedFilter.dispose();
      } else {
        paintSetColorFilter(handle, _invertColorFilter.handle);
      }
    } else if (nativeFilter != null) {
      paintSetColorFilter(handle, nativeFilter.handle);
      nativeFilter.dispose();
    } else {
      paintSetColorFilter(handle, nullptr);
    }
  }

  @override
  set colorFilter(ui.ColorFilter? filter) {
    _colorFilter = filter as EngineColorFilter?;
    _setEffectiveColorFilter();
  }

  @override
  ui.MaskFilter? get maskFilter => _maskFilter;

  @override
  set maskFilter(ui.MaskFilter? filter) {
    _maskFilter = filter;
    if (filter == null) {
      paintSetMaskFilter(handle, nullptr);
    } else {
      final SkwasmMaskFilter nativeFilter = SkwasmMaskFilter.fromUiMaskFilter(filter);
      paintSetMaskFilter(handle, nativeFilter.handle);
      nativeFilter.dispose();
    }
  }

  @override
  bool get invertColors => _invertColors;

  @override
  set invertColors(bool invertColors) {
    if (_invertColors == invertColors) {
      return;
    }
    _invertColors = invertColors;
    _setEffectiveColorFilter();
  }
}
