package com.fitforge.fitforge

import io.flutter.embedding.android.FlutterFragmentActivity

// Health Connect exige une FragmentActivity pour la demande d'autorisation
// (l'API Activity Result d'AndroidX repose sur une FragmentActivity).
class MainActivity : FlutterFragmentActivity()
