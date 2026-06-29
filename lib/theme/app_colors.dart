import 'package:flutter/material.dart';

// Clarivo color tokens — imported by screens and widgets.

const Color kBackground  = Color(0xFF030D1C);
const Color kCard        = Color(0xFF071C33);
const Color kAccent      = Color(0xFF42D6B5);
const Color kPositive    = Color(0xFF42D6B5);
const Color kNegative    = Color(0xFFE66A73);
const Color kWarning     = Color(0xFFF0B429);
const Color kTextMain    = Color(0xFFFFFFFF);
const Color kTextSec     = Color(0xFFBCC9D6);
const Color kTextMuted   = Color(0xFFAABBC9);
const Color kBorder      = Color(0xFF2A3B4F);
const Color kNavInactive = Color(0xFF7E8998);

// Gradient stops shared by every screen background.
const List<Color> kBgGradientColors = [
  Color(0xFF030D1C),
  Color(0xFF0A2240),
  Color(0xFF06101D),
];
const List<double> kBgGradientStops = [0.0, 0.5, 1.0];

// Hero / balance card gradient.
const List<Color> kCardGradientColors = [
  Color(0xFF0C2148),
  Color(0xFF0C2148),
  Color(0xFF1E4C8F),
];
