import 'dart:math';

import 'package:river_player/river_player.dart';

class BetterPlayerPiPActions {
  final void Function(BetterPlayerController controller)? onPause;
  final void Function(BetterPlayerController controller)? onPrevious;
  final void Function(BetterPlayerController controller)? onNext;
  final void Function(BetterPlayerController controller)? onBackward;
  final void Function(BetterPlayerController controller)? onForward;

  BetterPlayerPiPActions({
    this.onPause,
    this.onPrevious,
    this.onNext,
    this.onBackward,
    this.onForward,
  });

  static final void Function(BetterPlayerController controller) defaultPlayPause = ((controller) {
    controller.isPlaying() == true
        ? controller.videoPlayerController?.pause()
        : controller.videoPlayerController?.play();
  });

  static final void Function(BetterPlayerController controller) defaultBackward = ((controller) {
    final latestValue = controller.videoPlayerController?.value;
    if (latestValue != null) {
      final beginning = const Duration().inMilliseconds;
      final skip = (latestValue.position -
              Duration(
                milliseconds: controller.betterPlayerControlsConfiguration.backwardSkipTimeInMilliseconds,
              ))
          .inMilliseconds;
      controller.seekTo(Duration(milliseconds: max(skip, beginning)));
    }
  });

  static final void Function(BetterPlayerController controller) defaultForward = ((controller) {
    final latestValue = controller.videoPlayerController?.value;
    if (latestValue != null) {
      final end = latestValue.duration!.inMilliseconds;
      final skip = (latestValue.position +
              Duration(
                milliseconds: controller.betterPlayerControlsConfiguration.forwardSkipTimeInMilliseconds,
              ))
          .inMilliseconds;
      controller.seekTo(Duration(milliseconds: min(skip, end)));
    }
  });
}