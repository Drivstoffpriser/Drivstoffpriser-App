/// Configuration for external API keys.
/// flutter run --dart-define=ANTHROPIC_API_KEY=sk-...
/// The Anthropic API key can be provided via:
/// - `--dart-define=ANTHROPIC_API_KEY=sk-...` at build time
/// - Calling [AnthropicConfig.setApiKey] at runtime (e.g. from settings)
class AnthropicConfig {
  AnthropicConfig._();

  static const _envKey =
      String.fromEnvironment('ANTHROPIC_API_KEY', defaultValue: '');

  static String _runtimeKey = '';

  /// Set the API key at runtime (overrides the build-time value).
  static void setApiKey(String key) => _runtimeKey = key;

  /// The active API key (runtime override takes precedence).
  static String get apiKey =>
      _runtimeKey.isNotEmpty ? _runtimeKey : _envKey;

  /// Whether a usable API key is configured.
  static bool get hasApiKey => apiKey.isNotEmpty;

  /// The model to use for vision requests (cheapest Claude model).
  static const String model = 'claude-haiku-4-5-20251001';

  /// Max tokens for the response (price JSON is tiny).
  static const int maxTokens = 256;
}
