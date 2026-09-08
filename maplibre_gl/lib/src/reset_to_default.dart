part of '../maplibre_gl.dart';

/// Sentinel type used by [resetToDefault].
class _ResetToDefault {
  const _ResetToDefault();

  @override
  String toString() => 'resetToDefault';
}

/// Pass this as a property's value in a `*LayerProperties` constructor to
/// explicitly reset that MapLibre style property back to its style-spec
/// default.
///
/// Omitting a property entirely (its default `null` constructor value)
/// means "leave this property untouched" — it will NOT be sent to the
/// platform side at all.
///
/// Example:
/// ```dart
/// // Resets 'text-field' back to its style-spec default, while leaving
/// // every other symbol layer property untouched.
/// await controller.setLayerProperties(
///   layerId,
///   const SymbolLayerProperties(textField: resetToDefault),
/// );
/// ```
const resetToDefault = _ResetToDefault();
