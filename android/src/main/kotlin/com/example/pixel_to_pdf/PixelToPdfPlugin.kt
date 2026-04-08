package com.example.pixel_to_pdf

import android.Manifest
import android.app.Activity
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.provider.MediaStore
import androidx.annotation.NonNull
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import androidx.core.content.FileProvider
import com.google.mlkit.vision.documentscanner.GmsDocumentScannerOptions
import com.google.mlkit.vision.documentscanner.GmsDocumentScannerOptions.RESULT_FORMAT_JPEG
import com.google.mlkit.vision.documentscanner.GmsDocumentScannerOptions.SCANNER_MODE_FULL
import com.google.mlkit.vision.documentscanner.GmsDocumentScanning
import com.google.mlkit.vision.documentscanner.GmsDocumentScanningResult
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry
import java.io.File
import java.io.FileOutputStream
import java.io.InputStream
import java.util.UUID

class PixelToPdfPlugin : FlutterPlugin, MethodCallHandler, ActivityAware, 
    PluginRegistry.ActivityResultListener, PluginRegistry.RequestPermissionsResultListener {
    private lateinit var channel: MethodChannel
    private var activity: Activity? = null
    private var pendingResult: Result? = null
    private var currentCameraImagePath: String? = null

    private val REQ_CODE_SCAN = 1001
    private val REQ_CODE_TAKE_IMAGE = 1002
    private val REQ_CODE_PICK_IMAGE = 1003
    private val REQ_CODE_PICK_MULTI_IMAGE = 1004
    private val REQ_CODE_PICK_FILE = 1005
    private val REQ_CODE_PERMISSION_CAMERA = 1006

    override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "pixel_to_pdf/scanner")
        channel.setMethodCallHandler(this)
    }

    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }

    override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
        if (activity == null) {
            result.error("NO_ACTIVITY", "Activity is null", null)
            return
        }
        pendingResult = result

        when (call.method) {
            "scanDocument" -> startScan()
            "takeImage" -> startCamera()
            "pickImage" -> startPicker(false)
            "pickMultiImage" -> startPicker(true)
            "pickFile" -> startFilePicker()
            else -> result.notImplemented()
        }
    }

    private fun startScan() {
        val options = GmsDocumentScannerOptions.Builder()
            .setScannerMode(SCANNER_MODE_FULL)
            .setResultFormats(RESULT_FORMAT_JPEG)
            .setGalleryImportAllowed(true)
            .build()

        val scanner = GmsDocumentScanning.getClient(options)
        activity?.let {
            scanner.getStartScanIntent(it)
                .addOnSuccessListener { intentSender ->
                    it.startIntentSenderForResult(intentSender, REQ_CODE_SCAN, null, 0, 0, 0)
                }
                .addOnFailureListener { e ->
                    pendingResult?.error("SCAN_ERROR", e.message, null)
                    pendingResult = null
                }
        }
    }

    private fun startCamera() {
        val currentActivity = activity ?: return
        
        // 1. Check for CAMERA permission
        if (ContextCompat.checkSelfPermission(currentActivity, Manifest.permission.CAMERA) != PackageManager.PERMISSION_GRANTED) {
            ActivityCompat.requestPermissions(currentActivity, arrayOf(Manifest.permission.CAMERA), REQ_CODE_PERMISSION_CAMERA)
            return
        }

        // 2. Permission is granted, proceed with camera launch
        try {
            val intent = Intent(MediaStore.ACTION_IMAGE_CAPTURE)
            val context = currentActivity.applicationContext
            
            val photoFile = File.createTempFile(
                "IMG_${System.currentTimeMillis()}",
                ".jpg",
                context.cacheDir
            )
            currentCameraImagePath = photoFile.absolutePath

            val photoURI: Uri = FileProvider.getUriForFile(
                context,
                context.packageName + ".pixel_to_pdf.fileprovider",
                photoFile
            )
            intent.putExtra(MediaStore.EXTRA_OUTPUT, photoURI)
            intent.addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_GRANT_WRITE_URI_PERMISSION)
            currentActivity.startActivityForResult(intent, REQ_CODE_TAKE_IMAGE)
        } catch (e: Exception) {
            // Handle launch failures (e.g. ActivityNotFoundException or early SecurityException)
            pendingResult?.error("CAMERA_LAUNCH_FAILED", e.message, null)
            pendingResult = null
        }
    }

    override fun onRequestPermissionsResult(requestCode: Int, permissions: Array<out String>, grantResults: IntArray): Boolean {
        if (requestCode == REQ_CODE_PERMISSION_CAMERA) {
            if (grantResults.isNotEmpty() && grantResults[0] == PackageManager.PERMISSION_GRANTED) {
                startCamera()
            } else {
                pendingResult?.error("PERMISSION_DENIED", "Camera permission is required", null)
                pendingResult = null
            }
            return true
        }
        return false
    }

    private fun startPicker(isMulti: Boolean) {
        val intent = Intent(Intent.ACTION_PICK, MediaStore.Images.Media.EXTERNAL_CONTENT_URI)
        if (isMulti) {
            intent.putExtra(Intent.EXTRA_ALLOW_MULTIPLE, true)
        }
        activity?.startActivityForResult(intent, if (isMulti) REQ_CODE_PICK_MULTI_IMAGE else REQ_CODE_PICK_IMAGE)
    }

    private fun startFilePicker() {
        val intent = Intent(Intent.ACTION_GET_CONTENT)
        intent.type = "*/*"
        activity?.startActivityForResult(intent, REQ_CODE_PICK_FILE)
    }

    private fun copyUriToCache(context: Context, uri: Uri): String? {
        val scheme = uri.scheme
        if (scheme != "content") {
            return uri.path
        }
        return try {
            val inputStream: InputStream? = context.contentResolver.openInputStream(uri)
            val tempFile = File(context.cacheDir, "copied_${UUID.randomUUID()}.tmp")
            val outputStream = FileOutputStream(tempFile)
            inputStream?.copyTo(outputStream)
            inputStream?.close()
            outputStream.close()
            tempFile.absolutePath
        } catch (e: Exception) {
            null
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
        // CRITICAL BUG FIX: Only intercept OUR request codes, otherwise we break other plugins like image_cropper!!!
        if (requestCode != REQ_CODE_SCAN && requestCode != REQ_CODE_TAKE_IMAGE && 
            requestCode != REQ_CODE_PICK_IMAGE && requestCode != REQ_CODE_PICK_MULTI_IMAGE && 
            requestCode != REQ_CODE_PICK_FILE) {
            return false
        }

        if (resultCode != Activity.RESULT_OK) {
            pendingResult?.success(null)
            pendingResult = null
            return true
        }

        val context = activity?.applicationContext
        if (context == null) {
            pendingResult?.success(null)
            pendingResult = null
            return true
        }

        when (requestCode) {
            REQ_CODE_SCAN -> {
                val result = GmsDocumentScanningResult.fromActivityResultIntent(data)
                result?.pages?.let { pages ->
                    val paths = pages.map { copyUriToCache(context, it.imageUri) ?: it.imageUri.toString() }
                    pendingResult?.success(paths)
                } ?: pendingResult?.success(null)
            }
            REQ_CODE_TAKE_IMAGE -> {
                pendingResult?.success(currentCameraImagePath)
                currentCameraImagePath = null
            }
            REQ_CODE_PICK_IMAGE, REQ_CODE_PICK_FILE -> {
                data?.data?.let { uri ->
                    val path = copyUriToCache(context, uri)
                    pendingResult?.success(path)
                } ?: pendingResult?.success(null)
            }
            REQ_CODE_PICK_MULTI_IMAGE -> {
                val paths = mutableListOf<String>()
                data?.clipData?.let { clip ->
                    for (i in 0 until clip.itemCount) {
                        copyUriToCache(context, clip.getItemAt(i).uri)?.let { paths.add(it) }
                    }
                } ?: data?.data?.let { uri ->
                    copyUriToCache(context, uri)?.let { paths.add(it) }
                }
                pendingResult?.success(paths)
            }
        }
        pendingResult = null
        return true
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
        binding.addActivityResultListener(this)
        binding.addRequestPermissionsResultListener(this)
    }

    override fun onDetachedFromActivityForConfigChanges() {
        activity = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activity = binding.activity
        binding.addActivityResultListener(this)
        binding.addRequestPermissionsResultListener(this)
    }

    override fun onDetachedFromActivity() {
        activity = null
    }
}
