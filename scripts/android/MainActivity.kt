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
    private var pending: MethodChannel.Result? = null
    private var exportContent: String? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
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
                "exportKey" -> {
                    val content = call.argument<String>("content")
                    if (content.isNullOrEmpty() || content.length > 8192) {
                        result.error("INVALID", "Conteúdo de exportação inválido.", null)
                        return@setMethodCallHandler
                    }
                    pending = result
                    exportContent = content
                    try {
                        val intent = Intent(Intent.ACTION_CREATE_DOCUMENT).apply {
                            addCategory(Intent.CATEGORY_OPENABLE)
                            type = "text/plain"
                            putExtra(Intent.EXTRA_TITLE, "Uai-Vozes-chave-API.txt")
                        }
                        startActivityForResult(intent, exportRequest)
                    } catch (error: Exception) { fail("EXPORT", error) }
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun fail(kind: String, error: Exception) {
        // Não devolver mensagens nativas contendo caminho ou conteúdo sensível.
        pending?.error(kind, "Não foi possível acessar o documento selecionado.", null)
        pending = null
        exportContent = null
    }

    @Deprecated("Usado pelo seletor de documentos SAF com FlutterActivity")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode != importRequest && requestCode != importTextRequest && requestCode != exportRequest) return
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
            pending = null
        }
    }
}
