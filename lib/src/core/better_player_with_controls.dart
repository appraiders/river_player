import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:river_player/river_player.dart';
import 'package:river_player/src/configuration/better_player_controller_event.dart';
import 'package:river_player/src/controls/better_player_cupertino_controls.dart';
import 'package:river_player/src/controls/better_player_material_controls.dart';
import 'package:river_player/src/core/better_player_utils.dart';
import 'package:river_player/src/subtitles/better_player_subtitles_drawer.dart';
import 'package:river_player/src/video_player/video_player.dart';

class BetterPlayerWithControls extends StatefulWidget {
  final BetterPlayerController? controller;

  const BetterPlayerWithControls({Key? key, this.controller}) : super(key: key);

  @override
  _BetterPlayerWithControlsState createState() => _BetterPlayerWithControlsState();
}

class _BetterPlayerWithControlsState extends State<BetterPlayerWithControls> {
  BetterPlayerSubtitlesConfiguration get subtitlesConfiguration =>
      widget.controller!.betterPlayerConfiguration.subtitlesConfiguration;

  BetterPlayerControlsConfiguration get controlsConfiguration => widget.controller!.betterPlayerControlsConfiguration;

  final StreamController<bool> playerVisibilityStreamController = StreamController();

  bool _initialized = false;

  StreamSubscription? _controllerEventSubscription;

  // current zoom value is used to calculate paddings
  // default value is set to not use notch area
  ValueNotifier<double> zoomListener = ValueNotifier(.0);

  // previous scale value is used to calculate difference
  // default value is 1 because this is initial value of ScaleUpdateDetails on change
  ValueNotifier<double> scaleListener = ValueNotifier(1);

  @override
  void initState() {
    playerVisibilityStreamController.add(true);
    _controllerEventSubscription = widget.controller!.controllerEventStream.listen(_onControllerChanged);
    super.initState();
  }

  @override
  void didUpdateWidget(BetterPlayerWithControls oldWidget) {
    if (oldWidget.controller != widget.controller) {
      _controllerEventSubscription?.cancel();
      _controllerEventSubscription = widget.controller!.controllerEventStream.listen(_onControllerChanged);
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  void dispose() {
    playerVisibilityStreamController.close();
    _controllerEventSubscription?.cancel();
    zoomListener.dispose();
    scaleListener.dispose();
    super.dispose();
  }

  void _onControllerChanged(BetterPlayerControllerEvent event) {
    setState(() {
      if (!_initialized) {
        _initialized = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final BetterPlayerController betterPlayerController = BetterPlayerController.of(context);

    double? aspectRatio;
    if (betterPlayerController.isFullScreen) {
      if (betterPlayerController.betterPlayerConfiguration.autoDetectFullscreenDeviceOrientation ||
          betterPlayerController.betterPlayerConfiguration.autoDetectFullscreenAspectRatio) {
        aspectRatio = betterPlayerController.videoPlayerController?.value.aspectRatio ?? 1.0;
      } else {
        aspectRatio = betterPlayerController.betterPlayerConfiguration.fullScreenAspectRatio ??
            BetterPlayerUtils.calculateAspectRatio(context);
      }
    } else {
      aspectRatio = betterPlayerController.getAspectRatio();
    }

    aspectRatio ??= 16 / 9;
    final bool isPinchToZoomEnabled = betterPlayerController.betterPlayerConfiguration.enablePinchToZoom;
    final innerContainer = Container(
      width: double.infinity,
      color: betterPlayerController.betterPlayerConfiguration.controlsConfiguration.backgroundColor,
      child: GestureDetector(
        onScaleUpdate: !isPinchToZoomEnabled
            ? null
            : (details) {
                // calculating difference between new scale and previous value
                // when zooming out, a factor of 2 is used so that the zoom value can be reduced to 0
                // when zooming in, a factor of 2 is used to uniformly change the zoom value
                double diff = (details.scale - scaleListener.value) * 2;

                // checking current zoom for maximum and minimum value
                // minimum value is 0 - video not showing on notch area
                // maximum value is 1 - video showing on notch area
                if (zoomListener.value + diff > 1) {
                  zoomListener.value = 1;
                } else if (zoomListener.value + diff < 0) {
                  zoomListener.value = 0;
                } else {
                  zoomListener.value += diff;
                }
                // set current scale as scale value
                scaleListener.value = details.scale;
              },
        onScaleEnd: !isPinchToZoomEnabled
            ? null
            : (details) {
                // bringing zoom value to maximum or minimum
                if (zoomListener.value <= 0.5) {
                  zoomListener.value = 0;
                } else {
                  zoomListener.value = 1;
                }
                // set default scale value
                scaleListener.value = 1;
              },
        child: AspectRatio(
          aspectRatio: aspectRatio,
          child: _buildPlayerWithControls(betterPlayerController, context),
        ),
      ),
    );

    if (betterPlayerController.betterPlayerConfiguration.expandToFill) {
      return Center(child: innerContainer);
    } else {
      return innerContainer;
    }
  }

  Container _buildPlayerWithControls(BetterPlayerController betterPlayerController, BuildContext context) {
    final configuration = betterPlayerController.betterPlayerConfiguration;
    var rotation = configuration.rotation;

    if (!(rotation <= 360 && rotation % 90 == 0)) {
      BetterPlayerUtils.log("Invalid rotation provided. Using rotation = 0");
      rotation = 0;
    }
    if (betterPlayerController.betterPlayerDataSource == null) {
      return Container();
    }
    _initialized = true;

    final bool placeholderOnTop = betterPlayerController.betterPlayerConfiguration.placeholderOnTop;
    final bool isPinchToZoomEnabled = betterPlayerController.betterPlayerConfiguration.enablePinchToZoom;
    final betterPlayerVideoFitWidget = Transform.rotate(
      angle: rotation * pi / 180,
      child: _BetterPlayerVideoFitWidget(
        betterPlayerController,
        betterPlayerController.getFit(),
      ),
    );
    // ignore: avoid_unnecessary_containers
    return Container(
      child: Stack(
        fit: StackFit.passthrough,
        children: <Widget>[
          if (placeholderOnTop) _buildPlaceholder(betterPlayerController),
          if (isPinchToZoomEnabled)
           AnimatedBuilder(
            animation: zoomListener,
            builder: (context, child) => Padding(
              padding: EdgeInsets.zero + MediaQuery.of(context).padding * (1 - zoomListener.value),
              child: Transform.rotate(
                angle: rotation * pi / 180,
                child: _BetterPlayerVideoFitWidget(
                  betterPlayerController,
                  betterPlayerController.getFit(),
                ),
              ),
            ),
          )
          else
            betterPlayerVideoFitWidget,
          betterPlayerController.betterPlayerConfiguration.overlay ?? Container(),
          BetterPlayerSubtitlesDrawer(
            betterPlayerController: betterPlayerController,
            betterPlayerSubtitlesConfiguration: subtitlesConfiguration,
            subtitles: betterPlayerController.subtitlesLines,
            playerVisibilityStream: playerVisibilityStreamController.stream,
          ),
          if (!placeholderOnTop) _buildPlaceholder(betterPlayerController),
          _buildControls(context, betterPlayerController)
        ],
      ),
    );
  }

  Widget _buildPlaceholder(BetterPlayerController betterPlayerController) {
    return betterPlayerController.betterPlayerDataSource!.placeholder ??
        betterPlayerController.betterPlayerConfiguration.placeholder ??
        Container();
  }

  Widget _buildControls(
    BuildContext context,
    BetterPlayerController betterPlayerController,
  ) {
    if (controlsConfiguration.showControls) {
      BetterPlayerTheme? playerTheme = controlsConfiguration.playerTheme;
      if (playerTheme == null) {
        if (Platform.isAndroid) {
          playerTheme = BetterPlayerTheme.material;
        } else {
          playerTheme = BetterPlayerTheme.cupertino;
        }
      }

      if (controlsConfiguration.customControlsBuilder != null && playerTheme == BetterPlayerTheme.custom) {
        return controlsConfiguration.customControlsBuilder!(betterPlayerController, onControlsVisibilityChanged);
      } else if (playerTheme == BetterPlayerTheme.material) {
        return _buildMaterialControl();
      } else if (playerTheme == BetterPlayerTheme.cupertino) {
        return _buildCupertinoControl();
      }
    }

    return const SizedBox();
  }

  Widget _buildMaterialControl() {
    return BetterPlayerMaterialControls(
      onControlsVisibilityChanged: onControlsVisibilityChanged,
      controlsConfiguration: controlsConfiguration,
    );
  }

  Widget _buildCupertinoControl() {
    return BetterPlayerCupertinoControls(
      onControlsVisibilityChanged: onControlsVisibilityChanged,
      controlsConfiguration: controlsConfiguration,
    );
  }

  void onControlsVisibilityChanged(bool state) {
    playerVisibilityStreamController.add(state);
  }
}

///Widget used to set the proper box fit of the video. Default fit is 'fill'.
class _BetterPlayerVideoFitWidget extends StatefulWidget {
  const _BetterPlayerVideoFitWidget(
    this.betterPlayerController,
    this.boxFit, {
    Key? key,
  }) : super(key: key);

  final BetterPlayerController betterPlayerController;
  final BoxFit boxFit;

  @override
  _BetterPlayerVideoFitWidgetState createState() => _BetterPlayerVideoFitWidgetState();
}

class _BetterPlayerVideoFitWidgetState extends State<_BetterPlayerVideoFitWidget> {
  VideoPlayerController? get controller => widget.betterPlayerController.videoPlayerController;

  bool _initialized = false;

  VoidCallback? _initializedListener;

  bool _started = false;

  StreamSubscription? _controllerEventSubscription;

  @override
  void initState() {
    super.initState();
    if (!widget.betterPlayerController.betterPlayerConfiguration.showPlaceholderUntilPlay) {
      _started = true;
    } else {
      _started = widget.betterPlayerController.hasCurrentDataSourceStarted;
    }

    _initialize();
  }

  @override
  void didUpdateWidget(_BetterPlayerVideoFitWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.betterPlayerController.videoPlayerController != controller) {
      if (_initializedListener != null) {
        oldWidget.betterPlayerController.videoPlayerController!.removeListener(_initializedListener!);
      }
      _initialized = false;
      _initialize();
    }
  }

  void _initialize() {
    if (controller?.value.initialized == false) {
      _initializedListener = () {
        if (!mounted) {
          return;
        }

        if (_initialized != controller!.value.initialized) {
          _initialized = controller!.value.initialized;
          setState(() {});
        }
      };
      controller!.addListener(_initializedListener!);
    } else {
      _initialized = true;
    }

    _controllerEventSubscription = widget.betterPlayerController.controllerEventStream.listen((event) {
      if (event == BetterPlayerControllerEvent.play) {
        if (!_started) {
          setState(() {
            _started = widget.betterPlayerController.hasCurrentDataSourceStarted;
          });
        }
      }
      if (event == BetterPlayerControllerEvent.setupDataSource) {
        setState(() {
          _started = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_initialized && _started) {
      return Center(
        child: ClipRect(
          child: Container(
            width: double.infinity,
            height: double.infinity,
            child: FittedBox(
              fit: widget.boxFit,
              child: SizedBox(
                width: controller!.value.size?.width ?? 0,
                height: controller!.value.size?.height ?? 0,
                child: VideoPlayer(controller),
              ),
            ),
          ),
        ),
      );
    } else {
      return const SizedBox();
    }
  }

  @override
  void dispose() {
    if (_initializedListener != null) {
      widget.betterPlayerController.videoPlayerController!.removeListener(_initializedListener!);
    }
    _controllerEventSubscription?.cancel();
    super.dispose();
  }
}
