package no.fueltracker.fuel_price_tracker

import android.Manifest
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.provider.MediaStore
import android.util.Log
import androidx.activity.result.ActivityResultLauncher
import androidx.activity.result.contract.ActivityResultContracts
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import androidx.exifinterface.media.ExifInterface
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileOutputStream

class MainActivity : FlutterFragmentActivity() {
    private val TAG = "ImageMetadataChannel"
    private val CHANNEL = "no.fueltracker/image_metadata"
    private var pendingResult: MethodChannel.Result? = null
    private lateinit var pickImageLauncher: ActivityResultLauncher<String>
    private val PERMISSION_REQUEST_CODE = 9001

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // GetContent routes through the Android Photo Picker on 13+, which
        // provides a single-step selection UI and URIs compatible with
        // setRequireOriginal for unredacted GPS access.
        pickImageLauncher = registerForActivityResult(
            ActivityResultContracts.GetContent()
        ) { uri: Uri? ->
            if (uri != null) {
                Log.d(TAG, "Image picked, URI: $uri")
                handlePickedImage(uri)
            } else {
                Log.d(TAG, "User cancelled picker")
                pendingResult?.success(null)
                pendingResult = null
            }
        }

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "pickImageWithMetadata" -> {
                    pendingResult = result
                    ensurePermissionsThenPick()
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun ensurePermissionsThenPick() {
        val perms = mutableListOf<String>()

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            if (ContextCompat.checkSelfPermission(this, Manifest.permission.READ_MEDIA_IMAGES)
                != PackageManager.PERMISSION_GRANTED
            ) {
                perms.add(Manifest.permission.READ_MEDIA_IMAGES)
            }
        }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            if (ContextCompat.checkSelfPermission(this, Manifest.permission.ACCESS_MEDIA_LOCATION)
                != PackageManager.PERMISSION_GRANTED
            ) {
                perms.add(Manifest.permission.ACCESS_MEDIA_LOCATION)
            }
        }

        if (perms.isNotEmpty()) {
            Log.d(TAG, "Requesting permissions: $perms")
            ActivityCompat.requestPermissions(this, perms.toTypedArray(), PERMISSION_REQUEST_CODE)
        } else {
            Log.d(TAG, "All permissions granted, launching picker")
            launchPicker()
        }
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == PERMISSION_REQUEST_CODE) {
            for (i in permissions.indices) {
                val granted = grantResults.getOrNull(i) == PackageManager.PERMISSION_GRANTED
                Log.d(TAG, "Permission ${permissions[i]}: granted=$granted")
            }
            launchPicker()
        }
    }

    private fun launchPicker() {
        pickImageLauncher.launch("image/*")
    }

    private fun handlePickedImage(uri: Uri) {
        try {
            val metadata = HashMap<String, Any?>()

            // Try setRequireOriginal first (works with Photo Picker URIs),
            // fall back to plain URI (for document provider URIs).
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                try {
                    val originalUri = MediaStore.setRequireOriginal(uri)
                    Log.d(TAG, "Trying original URI: $originalUri")
                    readExifFromUri(originalUri, metadata)
                    Log.d(TAG, "EXIF from original URI: lat=${metadata["latitude"]}, lng=${metadata["longitude"]}")
                } catch (e: SecurityException) {
                    Log.w(TAG, "setRequireOriginal denied, falling back to plain URI: ${e.message}")
                    readExifFromUri(uri, metadata)
                    Log.d(TAG, "EXIF from plain URI: lat=${metadata["latitude"]}, lng=${metadata["longitude"]}")
                }
            } else {
                readExifFromUri(uri, metadata)
            }

            // Copy image bytes to cache file (always from plain URI)
            val cacheFile = File(cacheDir, "picked_${System.currentTimeMillis()}.jpg")
            contentResolver.openInputStream(uri)?.use { input ->
                FileOutputStream(cacheFile).use { output ->
                    input.copyTo(output)
                }
            }

            val result = HashMap<String, Any?>()
            result["path"] = cacheFile.absolutePath
            result["latitude"] = metadata["latitude"]
            result["longitude"] = metadata["longitude"]
            result["dateTime"] = metadata["dateTime"]

            Log.d(TAG, "Returning: path=${cacheFile.absolutePath}, lat=${metadata["latitude"]}, lng=${metadata["longitude"]}, dt=${metadata["dateTime"]}")
            pendingResult?.success(result)
        } catch (e: Exception) {
            Log.e(TAG, "handlePickedImage failed", e)
            pendingResult?.error("PICK_ERROR", e.message, null)
        }
        pendingResult = null
    }

    private fun readExifFromUri(uri: Uri, metadata: HashMap<String, Any?>) {
        contentResolver.openInputStream(uri)?.use { stream ->
            val exif = ExifInterface(stream)

            val latLong = exif.latLong
            if (latLong != null) {
                metadata["latitude"] = latLong[0]
                metadata["longitude"] = latLong[1]
                Log.d(TAG, "ExifInterface.latLong: [${latLong[0]}, ${latLong[1]}]")
            } else {
                val lat = exif.getAttribute(ExifInterface.TAG_GPS_LATITUDE)
                val lng = exif.getAttribute(ExifInterface.TAG_GPS_LONGITUDE)
                Log.d(TAG, "ExifInterface.latLong is null. Raw: lat=$lat, lng=$lng")
            }

            val dateTime = exif.getAttribute(ExifInterface.TAG_DATETIME_ORIGINAL)
                ?: exif.getAttribute(ExifInterface.TAG_DATETIME)
            metadata["dateTime"] = dateTime
        }
    }
}
