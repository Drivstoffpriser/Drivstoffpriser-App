package no.fueltracker.fuel_price_tracker

import android.Manifest
import android.app.Activity
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.provider.MediaStore
import android.util.Log
import androidx.activity.result.ActivityResultLauncher
import androidx.activity.result.contract.ActivityResultContract
import androidx.activity.result.contract.ActivityResultContracts
import androidx.core.content.ContextCompat
import androidx.exifinterface.media.ExifInterface
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileOutputStream

/**
 * ACTION_PICK opens the default gallery directly (no app-chooser dialog)
 * and returns a MediaStore URI that supports setRequireOriginal for GPS.
 */
class PickImageFromGallery : ActivityResultContract<Unit, Uri?>() {
    override fun createIntent(context: Context, input: Unit): Intent {
        return Intent(Intent.ACTION_PICK, MediaStore.Images.Media.EXTERNAL_CONTENT_URI)
    }

    override fun parseResult(resultCode: Int, intent: Intent?): Uri? {
        return if (resultCode == Activity.RESULT_OK) intent?.data else null
    }
}

class MainActivity : FlutterFragmentActivity() {
    private val TAG = "ImageMetadataChannel"
    private val CHANNEL = "no.fueltracker/image_metadata"
    private var pendingResult: MethodChannel.Result? = null
    private lateinit var pickImageLauncher: ActivityResultLauncher<Unit>
    private lateinit var permissionLauncher: ActivityResultLauncher<String>

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // ACTION_PICK opens the gallery directly — no app-chooser popup.
        // Returned MediaStore URIs support setRequireOriginal for GPS.
        pickImageLauncher = registerForActivityResult(
            PickImageFromGallery()
        ) { uri: Uri? ->
            if (uri != null) {
                Log.d(TAG, "Image picked, URI: $uri")
                processPickedImage(uri)
            } else {
                Log.d(TAG, "User cancelled picker")
                pendingResult?.success(null)
                pendingResult = null
            }
        }

        // Request ACCESS_MEDIA_LOCATION before the picker so the user
        // sees at most one permission dialog, then the picker opens
        // immediately.  On subsequent uses the permission is already
        // granted and the picker launches with no interruption.
        permissionLauncher = registerForActivityResult(
            ActivityResultContracts.RequestPermission()
        ) { granted ->
            Log.d(TAG, "ACCESS_MEDIA_LOCATION granted=$granted")
            // Launch picker regardless — GPS will just be null if denied.
            pickImageLauncher.launch(Unit)
        }

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "pickImageWithMetadata" -> {
                    pendingResult = result
                    ensurePermissionThenPick()
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun ensurePermissionThenPick() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q &&
            ContextCompat.checkSelfPermission(this, Manifest.permission.ACCESS_MEDIA_LOCATION)
            != PackageManager.PERMISSION_GRANTED
        ) {
            Log.d(TAG, "Requesting ACCESS_MEDIA_LOCATION before picker")
            permissionLauncher.launch(Manifest.permission.ACCESS_MEDIA_LOCATION)
        } else {
            Log.d(TAG, "Permission already granted, launching picker")
            pickImageLauncher.launch(Unit)
        }
    }

    private fun processPickedImage(uri: Uri) {
        try {
            val metadata = HashMap<String, Any?>()

            // Try setRequireOriginal first for unredacted GPS,
            // fall back to plain URI if denied or unsupported.
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                try {
                    val originalUri = MediaStore.setRequireOriginal(uri)
                    Log.d(TAG, "Trying original URI: $originalUri")
                    readExifFromUri(originalUri, metadata)
                    Log.d(TAG, "EXIF from original URI: lat=${metadata["latitude"]}, lng=${metadata["longitude"]}")
                } catch (e: Exception) {
                    Log.w(TAG, "setRequireOriginal failed, falling back to plain URI: ${e.message}")
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
            Log.e(TAG, "processPickedImage failed", e)
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
