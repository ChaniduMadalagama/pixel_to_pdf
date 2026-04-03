package com.example.attachment_studio

import android.app.Activity
import android.content.Intent
import android.net.Uri
import android.provider.MediaStore
import androidx.annotation.NonNull
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

class AttachmentStudioPlugin : FlutterPlugin, MethodCallHandler, ActivityAware, PluginRegistry.ActivityResultListener {
    private lateinit var channel: MethodChannel
    private var activity: Activity? = null
    private var pendingResult: Result? = null

    private val REQ_CODE_SCAN = 1001
    private val REQ_CODE_TAKE_IMAGE = 1002
    private val REQ_CODE_PICK_IMAGE = 1003
    private val REQ_CODE_PICK_MULTI_IMAGE = 1004
    private val REQ_CODE_PICK_FILE = 1005

    override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "attachment_studio/scanner")
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

    // ── Document Scanner ───────────────────────────────────────────────────

    private fun startScan() {
        val options = GmsDocumentScannerOptions.Builder()
            .setScannerMode(SCANNER_MODE_FULL)
            .setResultFormat(RESULT_FORMAT_JPEG)
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

    // ── Camera ─────────────────────────────────────────────────────────────

    private fun startCamera() {
        val intent = Intent(MediaStore.ACTION_IMAGE_CAPTURE)
        activity?.startActivityForResult(intent, REQ_CODE_TAKE_IMAGE)
    }

    // ── Picker ─────────────────────────────────────────────────────────────

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

    // ── Activity Results ────────────────────────────────────────────────────

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
        if (resultCode != Activity.RESULT_OK) {
            pendingResult?.success(null)
            pendingResult = null
            return true
        }

        when (requestCode) {
            REQ_CODE_SCAN -> {
                val result = GmsDocumentScanningResult.fromActivityResultIntent(data)
                result?.pages?.let { pages ->
                    val paths = pages.map { it.imageUri.toString() }
                    pendingResult?.success(paths)
                } ?: pendingResult?.success(null)
            }
            REQ_CODE_TAKE_IMAGE, REQ_CODE_PICK_IMAGE, REQ_CODE_PICK_FILE -> {
                val uri = data?.data
                pendingResult?.success(uri?.toString())
            }
            REQ_CODE_PICK_MULTI_IMAGE -> {
                val paths = mutableListOf<String>()
                data?.clipData?.let { clip ->
                    for (i in 0 until clip.itemCount) {
                        paths.add(clip.getItemAt(i).uri.toString())
                    }
                } ?: data?.data?.let { paths.add(it.toString()) }
                pendingResult?.success(paths)
            }
            else -> return false
        }
        pendingResult = null
        return true
    }

    // ── Activity Lifecycle ──────────────────────────────────────────────────

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
        binding.addActivityResultListener(this)
    }

    override fun onDetachedFromActivityForConfigChanges() {
        activity = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activity = binding.activity
        binding.addActivityResultListener(this)
    }

    override fun onDetachedFromActivity() {
        activity = null
    }
}
