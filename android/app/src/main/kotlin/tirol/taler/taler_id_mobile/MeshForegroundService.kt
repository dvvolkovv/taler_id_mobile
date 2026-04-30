package tirol.taler.taler_id_mobile

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Intent
import android.content.pm.ServiceInfo
import android.os.Build
import android.os.IBinder
import androidx.core.app.NotificationCompat

class MeshForegroundService : Service() {
    companion object {
        const val CHANNEL_ID = "mesh_fg_anchor"
        const val NOTIFICATION_ID = 9001
        const val ACTION_STOP = "tirol.taler.MESH_FG_STOP"
        const val EXTRA_PEER_COUNT = "peer_count"
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onCreate() {
        super.onCreate()
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "Mesh-сеть в фоне",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Поддерживает приём mesh-звонков когда телефон не активен"
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
        val peerCount = intent?.getIntExtra(EXTRA_PEER_COUNT, 0) ?: 0
        val text = if (peerCount > 0) "📡 $peerCount рядом" else "📡 Mesh активна"
        val notif = NotificationCompat.Builder(this, CHANNEL_ID)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentTitle("Mesh-сеть")
            .setContentText(text)
            .setOngoing(true)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .build()
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
                startForeground(
                    NOTIFICATION_ID,
                    notif,
                    ServiceInfo.FOREGROUND_SERVICE_TYPE_PHONE_CALL
                )
            } else {
                startForeground(NOTIFICATION_ID, notif)
            }
        } catch (e: Exception) {
            stopSelf()
            return START_NOT_STICKY
        }
        return START_STICKY
    }
}
