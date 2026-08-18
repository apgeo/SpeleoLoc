package ro.speosilex.speleoloc

import android.app.Activity
import android.content.ActivityNotFoundException
import android.content.Intent
import android.net.Uri
import android.provider.DocumentsContract
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileInputStream

/**
 * Storage Access Framework bridge for flows that read or write user-picked
 * shared-storage locations (archive/db export, bulk document import). The
 * folder/create-document pickers themselves carry the access grant, so no
 * runtime storage permission (and no MANAGE_EXTERNAL_STORAGE) is needed.
 */
class SafBridge(private val activity: Activity) : MethodChannel.MethodCallHandler {

    companion object {
        const val CHANNEL = "speleoloc/saf"
        private const val REQUEST_PICK_DIRECTORY = 71001
        private const val REQUEST_CREATE_DOCUMENT = 71002
    }

    private var pendingResult: MethodChannel.Result? = null
    private var pendingSourcePath: String? = null

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "pickDirectory" -> launchPicker(result, REQUEST_PICK_DIRECTORY) {
                Intent(Intent.ACTION_OPEN_DOCUMENT_TREE).addFlags(
                    Intent.FLAG_GRANT_READ_URI_PERMISSION or
                        Intent.FLAG_GRANT_PERSISTABLE_URI_PERMISSION
                )
            }
            "createDocument" -> {
                val fileName = call.argument<String>("fileName")
                val sourcePath = call.argument<String>("sourcePath")
                if (fileName == null || sourcePath == null) {
                    result.error("saf_args", "fileName and sourcePath are required", null)
                    return
                }
                pendingSourcePath = sourcePath
                launchPicker(result, REQUEST_CREATE_DOCUMENT) {
                    Intent(Intent.ACTION_CREATE_DOCUMENT).apply {
                        addCategory(Intent.CATEGORY_OPENABLE)
                        type = call.argument<String>("mimeType") ?: "application/octet-stream"
                        putExtra(Intent.EXTRA_TITLE, fileName)
                    }
                }
            }
            "listChildren" -> runInBackground(result) { listChildren(call) }
            "copyToFile" -> runInBackground(result) { copyToFile(call) }
            else -> result.notImplemented()
        }
    }

    /** Returns true when the request code belongs to this bridge. */
    fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
        if (requestCode != REQUEST_PICK_DIRECTORY && requestCode != REQUEST_CREATE_DOCUMENT) {
            return false
        }
        val result = pendingResult ?: return true
        pendingResult = null
        val uri = data?.data
        if (resultCode != Activity.RESULT_OK || uri == null) {
            pendingSourcePath = null
            result.success(null)
            return true
        }
        when (requestCode) {
            REQUEST_PICK_DIRECTORY -> {
                try {
                    activity.contentResolver.takePersistableUriPermission(
                        uri,
                        Intent.FLAG_GRANT_READ_URI_PERMISSION
                    )
                } catch (_: SecurityException) {
                    // Non-persistable provider: the grant still holds for this
                    // session, which is all the import flow needs.
                }
                result.success(
                    mapOf("treeUri" to uri.toString(), "name" to treeDisplayName(uri))
                )
            }
            REQUEST_CREATE_DOCUMENT -> {
                val sourcePath = pendingSourcePath
                pendingSourcePath = null
                if (sourcePath == null) {
                    result.error("saf_state", "No pending source path", null)
                    return true
                }
                // The archive can be large — stream it off the UI thread.
                runInBackground(result) {
                    activity.contentResolver.openOutputStream(uri, "wt")?.use { output ->
                        FileInputStream(File(sourcePath)).use { input -> input.copyTo(output) }
                    } ?: throw IllegalStateException("Cannot open output stream for $uri")
                    documentDisplayName(uri) ?: uri.lastPathSegment ?: uri.toString()
                }
            }
        }
        return true
    }

    private fun launchPicker(
        result: MethodChannel.Result,
        requestCode: Int,
        intentBuilder: () -> Intent,
    ) {
        if (pendingResult != null) {
            result.error("saf_busy", "Another SAF operation is in progress", null)
            return
        }
        pendingResult = result
        try {
            activity.startActivityForResult(intentBuilder(), requestCode)
        } catch (e: ActivityNotFoundException) {
            pendingResult = null
            pendingSourcePath = null
            result.error("saf_unavailable", e.message, null)
        }
    }

    private fun runInBackground(result: MethodChannel.Result, body: () -> Any?) {
        Thread {
            try {
                val value = body()
                activity.runOnUiThread { result.success(value) }
            } catch (e: Exception) {
                activity.runOnUiThread { result.error("saf_error", e.message, null) }
            }
        }.start()
    }

    private fun listChildren(call: MethodCall): List<Map<String, Any>> {
        val treeUri = Uri.parse(call.argument<String>("treeUri")!!)
        val parentDocId = call.argument<String>("documentId")
            ?: DocumentsContract.getTreeDocumentId(treeUri)
        val childrenUri =
            DocumentsContract.buildChildDocumentsUriUsingTree(treeUri, parentDocId)
        val entries = mutableListOf<Map<String, Any>>()
        activity.contentResolver.query(
            childrenUri,
            arrayOf(
                DocumentsContract.Document.COLUMN_DOCUMENT_ID,
                DocumentsContract.Document.COLUMN_DISPLAY_NAME,
                DocumentsContract.Document.COLUMN_MIME_TYPE,
                DocumentsContract.Document.COLUMN_SIZE,
            ),
            null,
            null,
            null,
        )?.use { cursor ->
            while (cursor.moveToNext()) {
                val mime = cursor.getString(2) ?: ""
                entries.add(
                    mapOf(
                        "documentId" to cursor.getString(0),
                        "name" to (cursor.getString(1) ?: ""),
                        "isDirectory" to (mime == DocumentsContract.Document.MIME_TYPE_DIR),
                        "size" to (if (cursor.isNull(3)) 0L else cursor.getLong(3)),
                    )
                )
            }
        }
        return entries
    }

    private fun copyToFile(call: MethodCall) {
        val treeUri = Uri.parse(call.argument<String>("treeUri")!!)
        val documentId = call.argument<String>("documentId")!!
        val destPath = call.argument<String>("destPath")!!
        val uri = DocumentsContract.buildDocumentUriUsingTree(treeUri, documentId)
        activity.contentResolver.openInputStream(uri)?.use { input ->
            File(destPath).outputStream().use { output -> input.copyTo(output) }
        } ?: throw IllegalStateException("Cannot open input stream for $documentId")
    }

    private fun treeDisplayName(treeUri: Uri): String {
        val docUri = DocumentsContract.buildDocumentUriUsingTree(
            treeUri,
            DocumentsContract.getTreeDocumentId(treeUri)
        )
        return documentDisplayName(docUri) ?: treeUri.lastPathSegment ?: treeUri.toString()
    }

    private fun documentDisplayName(uri: Uri): String? {
        activity.contentResolver.query(
            uri,
            arrayOf(DocumentsContract.Document.COLUMN_DISPLAY_NAME),
            null,
            null,
            null,
        )?.use { cursor ->
            if (cursor.moveToFirst() && !cursor.isNull(0)) return cursor.getString(0)
        }
        return null
    }
}
