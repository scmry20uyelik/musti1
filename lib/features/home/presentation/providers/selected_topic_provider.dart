import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'selected_topic_provider.freezed.dart';

/// State model for selected topic
@freezed
class SelectedTopic with _$SelectedTopic {
  const factory SelectedTopic({
    required String level,
    required String topicTitle,
  }) = _SelectedTopic;
}

/// Provider for managing selected topic state
/// Varsayılan olarak "Genel Almanca Sohbet" seçili
final selectedTopicProvider = StateProvider<SelectedTopic?>(
  (ref) =>
      const SelectedTopic(level: 'Genel', topicTitle: 'Genel Almanca Sohbet'),
);
