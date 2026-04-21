package com.example.attendance_app2026

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Context
import android.content.Intent
import android.net.ConnectivityManager
import android.net.TetheringManager
import android.net.wifi.WifiConfiguration
import android.net.wifi.WifiManager
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.provider.Settings
import androidx.core.content.ContextCompat
import android.util.Log
import java.io.*
import java.lang.reflect.Method
import java.net.ServerSocket
import java.net.Socket
import java.util.concurrent.ExecutorService
import java.util.concurrent.Executors

class HotspotService : Service() {
    private val TAG = "HotspotService"
    private var wifiManager: WifiManager? = null
    private var serverSocket: ServerSocket? = null
    private var executor: ExecutorService? = null
    private var isRunning = false

    companion object {
        const val NOTIFICATION_ID = 1
        const val CHANNEL_ID = "HotspotChannel"
        const val ACTION_START = "START_HOTSPOT"
        const val ACTION_STOP = "STOP_HOTSPOT"
        const val PORT = 8080
        const val HOST = "0.0.0.0"
    }

    override fun onCreate() {
        super.onCreate()
        wifiManager = applicationContext.getSystemService(Context.WIFI_SERVICE) as WifiManager
        createNotificationChannel()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_START -> startHotspot(intent.getStringExtra("ssid"), intent.getStringExtra("password"))
            ACTION_STOP -> stopHotspot()
        }
        return START_STICKY
    }

    private fun startHotspot(ssid: String?, password: String?) {
        if (isRunning) return

        val actualSsid = ssid ?: "Attendance"
        val actualPass = password ?: "12345678"

        enableHotspot(actualSsid, actualPass)
        startHttpServer(actualSsid)

        val notification = Notification.Builder(this, CHANNEL_ID)
            .setContentTitle("Hotspot Active - $actualSsid")
            .setContentText("Pass: $actualPass | Portal: http://192.168.43.1:$PORT")
            .setSmallIcon(android.R.drawable.ic_dialog_info)
            .build()
        startForeground(NOTIFICATION_ID, notification)
        isRunning = true
    }

    private fun startHttpServer(sessionId: String) {
        executor = Executors.newFixedThreadPool(10)
        try {
            serverSocket = ServerSocket(PORT, 50, java.net.InetAddress.getByName(HOST))
            Log.d(TAG, "Server started on $HOST:$PORT")
        } catch (e: IOException) {
            Log.e(TAG, "Could not start server", e)
            return
        }

        Thread {
            while (isRunning) {
                try {
                    val clientSocket = serverSocket!!.accept()
                    executor!!.execute(HttpHandler(clientSocket, sessionId))
                } catch (e: IOException) {
                    if (isRunning) Log.e(TAG, "Accept failed", e)
                }
            }
        }.start()
    }

    private fun stopHotspot() {
        isRunning = false
        disableHotspot()
        executor?.shutdownNow()
        serverSocket?.close()
        stopForeground(true)
        stopSelf()
    }

    override fun onDestroy() {
        stopHotspot()
        super.onDestroy()
    }

    private fun enableHotspot(ssid: String, password: String) {
        Log.d(TAG, "Attempting to enable hotspot: SSID=$ssid PASS=$password")

        try {
            // Priority 1: Reflection (works on most devices)
            val config = WifiConfiguration().apply {
                SSID = "\"$ssid\""
                preSharedKey = "\"$password\""
                allowedKeyManagement.set(4) // WPA2_PSK
            }
            val method: Method = wifiManager!!.javaClass.getDeclaredMethod("setWifiApEnabled", WifiConfiguration::class.java, Boolean::class.javaPrimitiveType)
            method.isAccessible = true
            val result = method.invoke(wifiManager, config, true) as Boolean
            Log.d(TAG, "Reflection setWifiApEnabled result: $result")
            if (result) {
                return
            }
        } catch (e: Exception) {
            Log.w(TAG, "Reflection failed", e)
        }

        try {
            // Priority 2: TetheringManager (Android 10+)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                val tm = getSystemService(Context.TETHERING_SERVICE) as TetheringManager
                val handler = Handler(Looper.getMainLooper())
                val callback = object : TetheringManager.StartTetheringCallback() {
                    override fun onTetheringStarted() {
                        Log.d(TAG, "Tethering started successfully")
                    }
                    override fun onTetheringFailed(reason: Int) {
                        Log.w(TAG, "Tethering failed with reason: $reason")
                    }
                }
                val request = TetheringManager.TetheringRequest.Builder()
                    .setNetworkType(TetheringManager.TETHERING_WIFI)
                    .build()
                val executor = ContextCompat.getMainExecutor(this)
                tm.startTethering(request, executor, callback)
                Log.d(TAG, "TetheringManager started")
                return
            }
        } catch (e: Exception) {
            Log.w(TAG, "TetheringManager failed", e)
        }

        // Fallback: Open hotspot settings
        Log.w(TAG, "All auto methods failed, opening hotspot settings")
        val intent = Intent(Settings.Panel.ACTION_WIFI_TETHER)
        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        startActivity(intent)
    }

    private fun disableHotspot() {
        Log.d(TAG, "Disabling hotspot")

        try {
            // Reflection disable
            val method: Method = wifiManager!!.javaClass.getDeclaredMethod("setWifiApEnabled", WifiConfiguration::class.java, Boolean::class.javaPrimitiveType)
            method.isAccessible = true
            method.invoke(wifiManager, null, false)
            Log.d(TAG, "Reflection disabled hotspot")
        } catch (e: Exception) {
            Log.w(TAG, "Reflection disable failed", e)
        }

        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                val tm = getSystemService(Context.TETHERING_SERVICE) as TetheringManager
                val mainExecutor = ContextCompat.getMainExecutor(this)
                val callback = object : TetheringManager.StopTetheringCallback() {
                    override fun onTetheringStopped() {
                        Log.d(TAG, "Tethering stopped")
                    }
                    override fun onTetheringFailed(error: Int) {
                        Log.w(TAG, "Stop tethering failed: $error")
                    }
                }
                val request = TetheringManager.TetheringRequest.Builder()
                    .setNetworkType(TetheringManager.TETHERING_WIFI)
                    .build()
                tm.stopTethering(request, mainExecutor, callback)
            }
        } catch (e: Exception) {
            Log.w(TAG, "TetheringManager stop failed", e)
        }
    }

    override fun onBind(intent: Intent?): IBinder? = null

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "Hotspot Service",
                NotificationManager.IMPORTANCE_LOW
            )
            val manager = getSystemService(NotificationManager::class.java)
            manager.createNotificationChannel(channel)
        }
    }

    private inner class HttpHandler(private val socket: Socket, private val sessionId: String) : Runnable {
        override fun run() {
            try {
                val input = socket.getInputStream()
                val output = socket.getOutputStream()
                val request = readRequest(input)
                val response = handleRequest(request, sessionId)
                output.write(response.toByteArray())
                output.flush()
            } catch (e: Exception) {
                Log.e(TAG, "Handler error", e)
            } finally {
                socket.close()
            }
        }

        private fun readRequest(input: InputStream): String {
            val reader = BufferedReader(InputStreamReader(input))
            val request = StringBuilder()
            var line = reader.readLine()
            while (line != null && line.isNotEmpty()) {
                request.append(line).append("\r\n")
                line = reader.readLine()
            }
            request.append("\r\n")
            return request.toString()
        }

        private fun handleRequest(request: String, sessionId: String): String {
            Log.d(TAG, "Request: $request")
            val lines = request.lines()
            val firstLine = lines[0]
            val path = firstLine.split(" ")[1]

            return when {
                path == "/" || path.startsWith("/favicon") -> {
                    val html = getCaptiveHtml(sessionId)
                    "HTTP/1.1 200 OK\r\nContent-Type: text/html\r\n\r\n$html"
                }
                path.startsWith("/register") -> {
                    val params = parseQuery(path.substringAfter("?"))
                    saveRegistration(params, sessionId)
                    "HTTP/1.1 200 OK\r\nContent-Type: text/html\r\n\r\n<!DOCTYPE html><html><body><h1>Registration Success!</h1></body></html>"
                }
                else -> "HTTP/1.1 404 Not Found\r\n\r\nNot Found"
            }
        }

        private fun parseQuery(query: String): Map<String, String> {
            val params = mutableMapOf<String, String>()
            query.split("&").forEach { pair ->
                val parts = pair.split("=")
                if (parts.size == 2) {
                    params[parts[0]] = java.net.URLDecoder.decode(parts[1], "UTF-8")
                }
            }
            return params
        }

        private fun saveRegistration(params: Map<String, String>, sessionId: String) {
            val file = File(filesDir, "pending_registrations_$sessionId.json")
            file.appendText("${params.toJson()}\n")
            Log.d(TAG, "Saved registration: $params")
        }

        private fun getCaptiveHtml(sessionId: String): String {
            return """
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Student Portal - $sessionId</title>
    <script src="https://cdn.tailwindcss.com"></script>
</head>
<body class="flex items-center justify-center min-h-screen bg-gray-50">
    <div class="bg-white p-8 rounded-2xl shadow-lg border max-w-md w-full mx-4">
        <div class="text-center mb-8">
            <h1 class="text-3xl font-bold text-gray-900 mb-2">Student Portal</h1>
            <p class="text-gray-600">Session: $sessionId</p>
        </div>
        <form action="/register?sessionId=$sessionId" method="POST" id="regForm" class="space-y-4">
            <div>
                <label class="block text-sm font-semibold text-gray-900 mb-2">Full Name</label>
                <input type="text" name="full_name" required class="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500">
            </div>
            <div>
                <label class="block text-sm font-semibold text-gray-900 mb-2">Email</label>
                <input type="email" name="email" required class="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500">
            </div>
            <div>
                <label class="block text-sm font-semibold text-gray-900 mb-2">Matricule</label>
                <input type="text" name="matricule" required class="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500">
            </div>
            <button type="submit" class="w-full bg-blue-600 text-white py-3 px-4 rounded-lg hover:bg-blue-700 font-semibold transition">
                Register Attendance
            </button>
        </form>
    </div>
</body>
</html>
            """.trimIndent()
        }
    }

    private fun Any.toJson(): String = toString()
}
