# Uai Vozes v0.06 · 0.1.0-alpha.6+6 (versionCode 6)

- Trava compartilhada entre telas e confirmação para impedir duas gerações TTS simultâneas.
- Salvamento de áudio mais resistente a interrupções: MP3 escrito antes do índice, journal de recuperação, catálogo atômico com backup e migração da biblioteca da v0.05.
- Player com tratamento de falhas assíncronas; falha em abrir o áudio não oculta o MP3 já salvo.
- Diagnóstico com persistência serializada, sem registrar chaves API ou textos enviados.
- GitHub Actions recusa criar um release APK com assinatura temporária: os quatro Secrets são obrigatórios.
- Testes novos de migração, recuperação, exclusão e bloqueio de geração; sem novas dependências Flutter.

APK previsto: `Uai-Vozes-v0.06.apk` (artifact separado do ZIP, com checksum SHA-256). Build Android real ainda pendente.
