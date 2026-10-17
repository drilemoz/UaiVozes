package com.drilemoz.uaivozes

import android.app.Activity
import android.content.Intent
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/** SAF nativo, sem dependência adicional para arquivos de chave. */
class MainActivity : FlutterActivity() {
    private val channelName = "com.drilemoz.uaivozes/key_transfer"
    private val importRequest = 19011
    private val importTextRequest = 19013
    private val exportRequest = 19012
    private val diagnosticRequest = 19014
    private val audioRequest = 19015
    private var pending: MethodChannel.Result? = null
    private var exportContent: String? = null
    private var exportAudioPath: String? = null
    private var androidSpeech: AndroidSpeechBridge? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        androidSpeech = AndroidSpeechBridge(this, flutterEngine.dartExecutor.binaryMessenger)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName).setMethodCallHandler { call, result ->
            if (pending != null) {
                result.error("BUSY", "O seletor de documentos já está aberto.", null)
                return@setMethodCallHandler
            }
            when (call.method) {
                "importKey", "importText" -> {
                    pending = result
                    try {
                        val intent = Intent(Intent.ACTION_OPEN_DOCUMENT).apply {
                            addCategory(Intent.CATEGORY_OPENABLE)
                            type = "text/plain"
                            putExtra(Intent.EXTRA_MIME_TYPES, arrayOf("text/plain", "application/octet-stream"))
                        }
                        startActivityForResult(intent, if (call.method == "importText") importTextRequest else importRequest)
                    } catch (error: Exception) { fail("IMPORT", error) }
                }
                "exportKey", "exportDiagnostic" -> {
                    val content = call.argument<String>("content")
                    val diagnostic = call.method == "exportDiagnostic"
                    val maxChars = if (diagnostic) 100000 else 8192
                    if (content.isNullOrEmpty() || content.length > maxChars) {
                        result.error("INVALID", "Conteúdo de exportação inválido.", null)
                        return@setMethodCallHandler
                    }
                    pending = result
                    exportContent = content
                    try {
                        val intent = Intent(Intent.ACTION_CREATE_DOCUMENT).apply {
                            addCategory(Intent.CATEGORY_OPENABLE)
                            type = "text/plain"
                            putExtra(Intent.EXTRA_TITLE, if (diagnostic)
                                "Uai-Vozes-Diagnostico.txt" else "Uai-Vozes-chave-API.txt")
                        }
                        startActivityForResult(intent, if (diagnostic) diagnosticRequest else exportRequest)
                    } catch (error: Exception) { fail("EXPORT", error) }
                }
                "exportAudio" -> {
                    // Somente arquivos dentro do armazenamento privado do app.
                    val path = call.argument<String>("path")
                    val name = call.argument<String>("name")
                    val file = try {
                        if (path.isNullOrEmpty()) null else java.io.File(path).canonicalFile
                    } catch (error: Exception) { null }
                    val base = try {
                        java.io.File(applicationInfo.dataDir).canonicalFile
                    } catch (error: Exception) { null }
                    if (file == null || base == null || !file.isFile || file.length() <= 0L ||
                        file.length() > 50L * 1024L * 1024L ||
                        !file.path.startsWith(base.path + java.io.File.separator)) {
                        result.error("INVALID", "Arquivo de áudio inválido.", null)
                        return@setMethodCallHandler
                    }
                    val safeName = (name ?: "").map { c ->
                        if (c.code < 32 || "\\/:*?\"<>|".indexOf(c) >= 0) '_' else c
                    }.joinToString("").trim()
                    pending = result
                    exportAudioPath = file.path
                    try {
                        val intent = Intent(Intent.ACTION_CREATE_DOCUMENT).apply {
                            addCategory(Intent.CATEGORY_OPENABLE)
                            type = "audio/mpeg"
                            putExtra(Intent.EXTRA_TITLE,
                                if (safeName.isEmpty()) "Uai-Vozes-audio.mp3" else safeName)
                        }
                        startActivityForResult(intent, audioRequest)
                    } catch (error: Exception) { fail("EXPORT", error) }
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun onDestroy() {
        androidSpeech?.close()
        androidSpeech = null
        super.onDestroy()
    }

    private fun fail(kind: String, error: Exception) {
        // Não devolver mensagens nativas contendo caminho ou conteúdo sensível.
        pending?.error(kind, "Não foi possível acessar o documento selecionado.", null)
        pending = null
        exportContent = null
        exportAudioPath = null
    }

    @Deprecated("Usado pelo seletor de documentos SAF com FlutterActivity")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode != importRequest && requestCode != importTextRequest && requestCode != exportRequest && requestCode != diagnosticRequest && requestCode != audioRequest) return
        val callback = pending ?: return
        try {
            if (resultCode != Activity.RESULT_OK || data?.data == null) {
                callback.success(null)
            } else if (requestCode == importRequest || requestCode == importTextRequest) {
                val uri = data.data!!
                val stream = contentResolver.openInputStream(uri)
                    ?: throw IllegalStateException("Não foi possível ler o arquivo")
                val bytes = stream.use { input ->
                    val output = java.io.ByteArrayOutputStream()
                    val buffer = ByteArray(1024)
                    while (true) {
                        val count = input.read(buffer)
                        if (count < 0) break
                        val maxBytes = if (requestCode == importTextRequest) 250000 else 8192
                        if (output.size() + count > maxBytes) throw IllegalArgumentException("Arquivo grande")
                        output.write(buffer, 0, count)
                    }
                    output.toByteArray()
                }
                callback.success(String(bytes, Charsets.UTF_8))
            } else if (requestCode == audioRequest) {
                val uri = data.data!!
                val source = java.io.File(exportAudioPath
                    ?: throw IllegalStateException("Arquivo ausente")).canonicalFile
                val base = java.io.File(applicationInfo.dataDir).canonicalFile
                if (!source.isFile || source.length() <= 0L ||
                    source.length() > 50L * 1024L * 1024L ||
                    !source.path.startsWith(base.path + java.io.File.separator)) {
                    throw IllegalStateException("Arquivo inválido para exportação")
                }
                val stream = contentResolver.openOutputStream(uri, "w")
                    ?: throw IllegalStateException("Não foi possível gravar o arquivo")
                val copied = stream.use { output ->
                    source.inputStream().use { input -> input.copyTo(output) }
                }
                if (copied <= 0L || copied != source.length()) {
                    throw IllegalStateException("Cópia incompleta")
                }
                callback.success(true)
            } else {
                val uri = data.data!!
                val stream = contentResolver.openOutputStream(uri, "w")
                    ?: throw IllegalStateException("Não foi possível gravar o arquivo")
                stream.use { it.write((exportContent ?: "").toByteArray(Charsets.UTF_8)) }
                callback.success(true)
            }
        } catch (error: Exception) {
            callback.error("DOCUMENT", "Falha ao acessar o arquivo. Tente novamente.", null)
        } finally {
            exportContent = null
            exportAudioPath = null
            pending = null
        }
    }
}
