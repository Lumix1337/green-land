// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:html' as html;
import 'dart:ui_web' as ui_web;
import 'package:flutter/material.dart';
import '../models/actuator_model.dart';
import '../models/telemetry_model.dart';

class DigitalTwinEmbed extends StatefulWidget {
  final TelemetryModel telemetry;
  final ActuatorModel actuators;
  final bool isOffline;
  final String nativeHint;
  final String languageCode;

  const DigitalTwinEmbed({
    super.key,
    required this.telemetry,
    required this.actuators,
    required this.isOffline,
    required this.nativeHint,
    this.languageCode = 'en',
  });

  @override
  State<DigitalTwinEmbed> createState() => _DigitalTwinEmbedState();
}

class _DigitalTwinEmbedState extends State<DigitalTwinEmbed> {
  static int _viewCounter = 0;
  late final String _viewType;
  html.IFrameElement? _iframe;

  @override
  void initState() {
    super.initState();
    _viewCounter += 1;
    _viewType = 'greenland-3d-twin-$_viewCounter';

    final iframe = html.IFrameElement()
      ..src = 'viewer_3d/index.html?embedded=1&lang=${widget.languageCode}'
      ..style.border = 'none'
      ..style.width = '100%'
      ..style.height = '100%'
      ..allow = 'fullscreen';

    iframe.onLoad.listen((_) => _postStateToViewer());
    _iframe = iframe;

    ui_web.platformViewRegistry.registerViewFactory(
      _viewType,
      (int viewId) => iframe,
    );
  }

  @override
  void didUpdateWidget(covariant DigitalTwinEmbed oldWidget) {
    super.didUpdateWidget(oldWidget);
    _postStateToViewer();
  }

  void _postStateToViewer() {
    final win = _iframe?.contentWindow;
    if (win == null) return;
    final t = widget.telemetry;
    final a = widget.actuators;
    win.postMessage({
      'type': 'greenland_state',
      'online': !widget.isOffline,
      'language': widget.languageCode,
      'telemetry': {
        'air_temp': t.airTemp,
        'air_humidity': t.airHumidity,
        'soil_moisture': t.soilMoisture,
        'light_level': t.lightLevel,
        'is_overheated': t.isOverheated(),
        'is_drought': t.isDrought(),
        'is_optimal': t.isOptimal,
      },
      'actuators': {
        'irrigation': a.irrigation,
        'ventilation': a.ventilation,
        'heater': a.heater,
        'lighting': a.lighting,
      },
    }, '*');
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: HtmlElementView(viewType: _viewType),
    );
  }
}
