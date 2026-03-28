/*
* A crowdsourced platform for real-time fuel price monitoring in Norway
* Copyright (C) 2026  Tsotne Karchava & Contributors
*
* This program is free software: you can redistribute it and/or modify
* it under the terms of the GNU General Public License as published by
* the Free Software Foundation, either version 3 of the License, or
* (at your option) any later version.
*
* This program is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
* GNU General Public License for more details.
*
* You should have received a copy of the GNU General Public License
* along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/

/// Configuration for external API keys.
/// flutter run --dart-define=ANTHROPIC_API_KEY=sk-...
/// The Anthropic API key can be provided via:
/// - `--dart-define=ANTHROPIC_API_KEY=sk-...` at build time
/// - Calling [AnthropicConfig.setApiKey] at runtime (e.g. from settings)
class AnthropicConfig {
  AnthropicConfig._();

  static const _envKey = String.fromEnvironment(
    'ANTHROPIC_API_KEY',
    defaultValue: '',
  );

  static String _runtimeKey = '';

  /// Set the API key at runtime (overrides the build-time value).
  static void setApiKey(String key) => _runtimeKey = key;

  /// The active API key (runtime override takes precedence).
  static String get apiKey => _runtimeKey.isNotEmpty ? _runtimeKey : _envKey;

  /// Whether a usable API key is configured.
  static bool get hasApiKey => apiKey.isNotEmpty;

  /// The model to use for vision requests (cheapest Claude model).
  static const String model = 'claude-haiku-4-5-20251001';

  /// Max tokens for the response (price JSON is tiny).
  static const int maxTokens = 256;
}
