import 'package:flutter/material.dart';

/// Lets timer/quick safety code show feedback without a route [BuildContext]
/// (e.g. platform messages, auth cleanup).
final GlobalKey<ScaffoldMessengerState> wishprScaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();
