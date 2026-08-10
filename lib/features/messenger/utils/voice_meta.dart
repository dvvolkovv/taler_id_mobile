import '../domain/entities/message_entity.dart';

/// Достаёт дорожку из метаданных сообщения.
///
/// Метаданные приходят как сырая карта: сервер их санитайзит на приёме, но по
/// дороге через кэш и сокет типы теряются — число может приехать целым, а
/// список — списком `dynamic`. Поэтому разбираем защитно и на любой мусор
/// отвечаем пустой дорожкой: плеер тогда покажет запасной узор.
List<double> waveformOf(MessageEntity m) {
  final raw = m.metadata?['waveform'];
  if (raw is! List) return const [];
  final out = <double>[];
  for (final v in raw) {
    if (v is num && v.isFinite) out.add(v.toDouble().clamp(0.0, 1.0));
  }
  return out;
}

/// Расшифровка голосового, если её уже делали.
String? transcriptOf(MessageEntity m) {
  final raw = m.metadata?['transcript'];
  return raw is String ? raw : null;
}
