package com.drilemoz.uaivozes

import android.app.Activity
import android.os.Bundle
import android.speech.tts.TextToSpeech
import android.speech.tts.UtteranceProgressListener
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import java.util.Locale

/** Reproducao pelo TTS do sistema, sem ElevenLabs e sem permissoes extras. */
class AndroidSpeechBridge(private val activity: Activity, messenger: BinaryMessenger) {
    private val channel = MethodChannel(messenger, "com.drilemoz.uaivozes/android_speech")
    private var engine: TextToSpeech? = null
    private var initializing = false
    private var pending: MethodChannel.Result? = null
    private var pendingText = ""
    private var pendingLanguage = "pt-BR"
    private var counter = 0L

    init {
        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "speak" -> {
                    val text = call.argument<String>("text")?.trim() ?: ""
                    val language = call.argument<String>("language") ?: "pt-BR"
                    if (text.isEmpty() || text.length > 3500) {
                        result.error("TEXT_LENGTH", "Use um texto de ate 3500 caracteres para leitura Android.", null)
                    } else if (initializing || pending != null) {
                        result.error("BUSY", "A voz do Android ainda esta inicializando.", null)
                    } else if (engine != null) {
                        play(text, language, result)
                    } else {
                        pending = result
                        pendingText = text
                        pendingLanguage = language
                        initializing = true
                        try {
                            engine = TextToSpeech(activity.applicationContext) { status ->
                                activity.runOnUiThread {
                                    initializing = false
                                    val callback = pending
                                    pending = null
                                    if (callback != null) {
                                        if (status == TextToSpeech.SUCCESS && engine != null) {
                                            play(pendingText, pendingLanguage, callback)
                                        } else {
                                            callback.error("TTS_UNAVAILABLE", "Nao foi possivel iniciar a voz do Android.", null)
                                        }
                                    }
                                }
                            }
                        } catch (_: Exception) {
                            initializing = false
                            pending = null
                            result.error("TTS_UNAVAILABLE", "Mecanismo de voz do Android indisponivel.", null)
                        }
                    }
                }
                "stop" -> {
                    engine?.stop()
                    pending?.error("CANCELLED", "Leitura cancelada.", null)
                    pending = null
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun play(text: String, language: String, result: MethodChannel.Result) {
        val tts = engine ?: run {
            result.error("TTS_UNAVAILABLE", "Voz do sistema nao inicializada.", null)
            return
        }
        try {
            val locale = Locale.forLanguageTag(language)
            val supported = tts.setLanguage(locale)
            if (supported == TextToSpeech.LANG_MISSING_DATA || supported == TextToSpeech.LANG_NOT_SUPPORTED) {
                result.error("LANGUAGE_UNAVAILABLE", "Instale uma voz para este idioma nas configuracoes de sintese do Android.", null)
                return
            }
            tts.setOnUtteranceProgressListener(object : UtteranceProgressListener() {
                override fun onStart(utteranceId: String?) {}
                override fun onDone(utteranceId: String?) = event("done")
                @Deprecated("Compatibilidade com mecanismos TTS antigos")
                override fun onError(utteranceId: String?) = event("failure")
                override fun onError(utteranceId: String?, errorCode: Int) = event("failure")
                override fun onStop(utteranceId: String?, interrupted: Boolean) = event("stopped")
            })
            counter++
            val queued = tts.speak(text, TextToSpeech.QUEUE_FLUSH, Bundle(), "uai-local-$counter")
            if (queued == TextToSpeech.SUCCESS) result.success(true)
            else result.error("TTS_FAILED", "O mecanismo de voz recusou a leitura.", null)
        } catch (_: Exception) {
            result.error("TTS_FAILED", "Erro ao solicitar a leitura Android.", null)
        }
    }

    private fun event(name: String) {
        activity.runOnUiThread { channel.invokeMethod(name, null) }
    }

    fun close() {
        channel.setMethodCallHandler(null)
        pending?.error("CANCELLED", "Leitura encerrada.", null)
        pending = null
        engine?.stop()
        engine?.shutdown()
        engine = null
    }
}
