import 'package:flutter/material.dart';

import 'scoring.dart';

String verdictLabel(Verdict v) {
  switch (v) {
    case Verdict.suspicious:
      return 'Suspicious';
    case Verdict.likelyAuthentic:
      return 'Likely authentic';
    case Verdict.noWarningSigns:
      return 'No warning signs found';
    case Verdict.cannotDetermine:
      return 'Cannot determine';
  }
}

Color verdictColor(Verdict v) {
  switch (v) {
    case Verdict.suspicious:
      return Colors.red.shade700;
    case Verdict.likelyAuthentic:
      return Colors.green.shade700;
    case Verdict.noWarningSigns:
      return Colors.lightGreen.shade800;
    case Verdict.cannotDetermine:
      return Colors.amber.shade800;
  }
}

IconData verdictIcon(Verdict v) {
  switch (v) {
    case Verdict.suspicious:
      return Icons.warning_amber_rounded;
    case Verdict.likelyAuthentic:
      return Icons.verified;
    case Verdict.noWarningSigns:
      return Icons.fact_check_outlined;
    case Verdict.cannotDetermine:
      return Icons.help_outline;
  }
}