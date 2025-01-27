package ir.r3r.river_player

import androidx.annotation.NonNull
import ir.r3r.river_player.PipAction
import io.flutter.plugin.common.MethodChannel
import io.flutter.embedding.engine.FlutterEngine


open class PipCallbackHelper {
  private val CHANNEL = "better_player.pip_mode"
  private lateinit var channel: MethodChannel

  fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
    channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
  }

  fun setChannel(channel: MethodChannel) {
    this.channel = channel
  }

  fun onPictureInPictureModeChanged(active: Boolean) {
    if (active) {
      channel.invokeMethod("onPipEntered", null)
    } else {
      channel.invokeMethod("onPipExited", null)
    }
  }

  fun onPipAction(action: PipAction) {
    channel.invokeMethod("onPipAction", action.name.lowercase())
  }
}