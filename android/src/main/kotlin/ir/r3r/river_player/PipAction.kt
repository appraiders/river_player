package ir.r3r.river_player

import android.app.PendingIntent
import android.app.RemoteAction
import android.content.Context
import android.content.Intent
import android.graphics.drawable.Icon
import android.os.Build
import androidx.annotation.RequiresApi
import ir.r3r.river_player.Constants.EXTRA_ACTION_TYPE
import ir.r3r.river_player.Constants.SIMPLE_PIP_ACTION
import ir.r3r.river_player.R

enum class PipAction(
    private val icon: Int,
    private val title: Int,
    private val description: Int,
    private val afterAction: String? = null,
) {
    PLAY(R.drawable.play, R.string.pip_action_play, R.string.pip_action_play_description, "PAUSE"),
    PAUSE(R.drawable.pause, R.string.pip_action_pause, R.string.pip_action_pause_description, "PLAY"),
    NEXT(R.drawable.next, R.string.pip_action_next, R.string.pip_action_next_description),
    PREVIOUS(R.drawable.previous, R.string.pip_action_previous, R.string.pip_action_previous_description),
    FORWARD(R.drawable.forward, R.string.pip_action_forward, R.string.pip_action_forward_description),
    BACKWARD(R.drawable.backward, R.string.pip_action_backward, R.string.pip_action_backward_description);

    @RequiresApi(Build.VERSION_CODES.O)
    fun toRemoteAction(context: Context) : RemoteAction = RemoteAction(
        Icon.createWithResource(context, icon),
        context.getString(title),
        context.getString(description),
        PendingIntent.getBroadcast(
            context, ordinal,
            Intent(SIMPLE_PIP_ACTION).putExtra(EXTRA_ACTION_TYPE, name),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
    )

    fun afterAction() : PipAction? {
        return afterAction?.let {
            valueOf(it)
        }
    }
}