package tirol.taler.taler_id_mobile

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Intent
import android.content.pm.ServiceInfo
import android.os.Build
import android.os.IBinder
import androidx.core.app.NotificationCompat
import androidx.core.app.ServiceCompat

/**
 * Anchors the process while an interpreter conversation ("Разговор с
 * переводом") keeps the microphone open in the background — the same role
 * [MeshForegroundService] plays for mesh calls, but with
 * `foregroundServiceType="microphone"` since interpreter rooms are plain
 * LiveKit rooms, never CallKit/telecom calls.
 */
class InterpreterForegroundService : Service() {
    companion object {
        const val CHANNEL_ID = "interpreter_fg"
        const val NOTIFICATION_ID = 9002
        const val ACTION_STOP = "tirol.taler.INTERPRETER_FG_STOP"
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onCreate() {
        super.onCreate()
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "Перевод в разговоре",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Держит микрофон активным во время разговора с переводом"
                setShowBadge(false)
            }
            getSystemService(NotificationManager::class.java)
                .createNotificationChannel(channel)
        }
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (intent?.action == ACTION_STOP) {
            stopForeground(STOP_FOREGROUND_REMOVE)
            stopSelf()
            return START_NOT_STICKY
        }

        val openApp = Intent(this, MainActivity::class.java).apply {
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP)
        }
        val contentIntent = PendingIntent.getActivity(
            this,
            NOTIFICATION_ID,
            openApp,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        val notif = NotificationCompat.Builder(this, CHANNEL_ID)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentTitle("Разговор с переводом")
            .setContentIntent(contentIntent)
            .setOngoing(true)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .build()
        try {
            // ServiceCompat ignores the type argument itself on API < 29 and
            // forwards it to the native 3-arg startForeground() from 29 on —
            // no manual SDK_INT branch needed here.
            ServiceCompat.startForeground(
                this,
                NOTIFICATION_ID,
                notif,
                ServiceInfo.FOREGROUND_SERVICE_TYPE_MICROPHONE,
            )
        } catch (e: Exception) {
            stopSelf()
            return START_NOT_STICKY
        }
        // Dart owns the call's lifecycle (InterpreterDevice/InterpreterBloc);
        // if the system kills this process, restarting the bare service
        // with no Dart side behind it would just leave an orphaned
        // notification with nothing driving it.
        return START_NOT_STICKY
    }
}
