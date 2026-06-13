import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

/// True when [Firebase.initializeApp] has completed successfully.
bool isFirebaseAppInitialized() {
  try {
    return Firebase.apps.isNotEmpty;
  } catch (_) {
    return false;
  }
}

/// Firestore handle only after Firebase app exists; null when offline / not inited.
FirebaseFirestore? firestoreOrNull() {
  if (!isFirebaseAppInitialized()) return null;
  try {
    return FirebaseFirestore.instance;
  } catch (_) {
    return null;
  }
}
