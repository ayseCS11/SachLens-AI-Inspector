/// What a signal means beyond its numbers.
enum SignalRole {
  /// An ordinary finding.
  normal,

  /// Real evidence in favour of the document (for example, links that use
  /// the official domain of the named university).
  positiveEvidence,

  /// The text looks like a social media post, where clean wording proves little.
  socialMedia,

  /// The text could not be read clearly, so the other checks are unreliable.
  unreadable,
}

/// One finding produced by a single check.
///
/// suspicion: 0.0 means no concern, 1.0 means strong concern.
/// weight: how much this finding matters when combined with others.
/// reason: plain words shown to the user.
/// role: lets the verdict logic treat special findings correctly without
/// comparing names.
class Signal {
  final String name;
  final double suspicion;
  final double weight;
  final String reason;
  final SignalRole role;

  const Signal({
    required this.name,
    required this.suspicion,
    required this.weight,
    required this.reason,
    this.role = SignalRole.normal,
  });
}