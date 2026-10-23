import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreService {
  FirestoreService._();

  static final FirestoreService instance = FirestoreService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? _activeSessionId;

  User get _currentUser {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception('No authenticated user.');
    }

    return user;
  }

  String get _currentUserId => _currentUser.uid;

  /// The session currently used by monitoring.
  String? get activeSessionId => _activeSessionId;

  // ═════════════════════════════════════════════════════════════
  // Account
  // accounts/{accountId}
  //
  // Fields:
  // accountId
  // fullName
  // email
  // childName
  // childDateOfBirth
  // childGender
  // deviceId
  // ═════════════════════════════════════════════════════════════

  CollectionReference<Map<String, dynamic>> get _accounts =>
      _firestore.collection('accounts');

  DocumentReference<Map<String, dynamic>> get _currentAccount =>
      _accounts.doc(_currentUserId);

  Future<void> createAccount({
    required String displayName,
    required String email,
  }) async {
    final user = _currentUser;

    await _accounts.doc(user.uid).set({
      'accountId': user.uid,
      'fullName': displayName,
      'email': email,
      'childName': null,
      'childDateOfBirth': null,
      'childGender': null,
      'deviceId': null,
    });
  }

  /// Keeps the Firestore email in sync with the Firebase Auth email
  /// (the Auth email changes only after the user verifies a new address).
  Future<void> syncEmailFromAuth() async {
    final user = _auth.currentUser;

    if (user == null) return;

    await user.reload();

    final authEmail = _auth.currentUser?.email;

    if (authEmail == null || authEmail.isEmpty) return;

    final snapshot = await _currentAccount.get();

    if (snapshot.data()?['email'] != authEmail) {
      await _currentAccount.update({'email': authEmail});
    }
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> watchAccount() {
    return _currentAccount.snapshots();
  }

  Future<void> updateAccountProfile({
    String? fullName,
    String? email,
    String? childName,
    DateTime? childDateOfBirth,
    String? childGender,
  }) async {
    final updates = <String, dynamic>{};

    if (fullName != null) {
      updates['fullName'] = fullName;
    }

    if (email != null) {
      updates['email'] = email;
    }

    if (childName != null) {
      updates['childName'] = childName;
    }

    if (childDateOfBirth != null) {
      updates['childDateOfBirth'] =
          Timestamp.fromDate(childDateOfBirth);
    }

    if (childGender != null) {
      updates['childGender'] = childGender;
    }

    if (updates.isEmpty) {
      return;
    }

    await _currentAccount.update(updates);
  }

  Future<void> updateDeviceId({
    required String deviceId,
  }) async {
    await _currentAccount.update({
      'deviceId': deviceId,
    });
  }

  // ═════════════════════════════════════════════════════════════
  // GrowthRecord
  // accounts/{accountId}/growthRecords/{recordId}
  // ═════════════════════════════════════════════════════════════

  CollectionReference<Map<String, dynamic>> get _growthRecords =>
      _currentAccount.collection('growthRecords');

  Future<String> createGrowthRecord({
    required double height,
    required double weight,
    required double headCircumference,
  }) async {
    final document = _growthRecords.doc();

    await document.set({
      'recordId': document.id,
      'height': height,
      'weight': weight,
      'headCircumference': headCircumference,
      'createdAt': FieldValue.serverTimestamp(),
    });

    return document.id;
  }

  Future<void> updateGrowthRecord({
    required String recordId,
    required double height,
    required double weight,
    required double headCircumference,
  }) async {
    await _growthRecords.doc(recordId).update({
      'height': height,
      'weight': weight,
      'headCircumference': headCircumference,
    });
  }

  Stream<QuerySnapshot<Map<String, dynamic>>>
      watchGrowthRecords() {
    return _growthRecords.snapshots();
  }

  // ═════════════════════════════════════════════════════════════
  // Reminder
  // accounts/{accountId}/reminders/{reminderId}
  //
  // Fields:
  // reminderId
  // title
  // description (optional)
  // dateTime
  // type
  // status
  // ═════════════════════════════════════════════════════════════

  CollectionReference<Map<String, dynamic>> get _reminders =>
      _currentAccount.collection('reminders');

  Future<String> createReminder({
    required String title,
    String? description,
    required DateTime dateTime,
    required String type,
    required String status,
  }) async {
    final document = _reminders.doc();

    final data = <String, dynamic>{
      'reminderId': document.id,
      'title': title,
      'dateTime': Timestamp.fromDate(dateTime),
      'type': type,
      'status': status,
    };

    final trimmedDescription = description?.trim();

    if (trimmedDescription != null &&
        trimmedDescription.isNotEmpty) {
      data['description'] = trimmedDescription;
    }

    await document.set(data);

    return document.id;
  }

  Future<void> updateReminder({
    required String reminderId,
    required String title,
    String? description,
    required DateTime dateTime,
    required String type,
    required String status,
  }) async {
    final trimmedDescription = description?.trim();

    await _reminders.doc(reminderId).update({
      'title': title,
      'description':
          trimmedDescription != null &&
                  trimmedDescription.isNotEmpty
              ? trimmedDescription
              : FieldValue.delete(),
      'dateTime': Timestamp.fromDate(dateTime),
      'type': type,
      'status': status,
    });
  }

  Future<void> deleteReminder({
    required String reminderId,
  }) async {
    await _reminders.doc(reminderId).delete();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> watchReminders() {
    return _reminders.snapshots();
  }

  // ═════════════════════════════════════════════════════════════
  // Session
  // accounts/{accountId}/sessions/{sessionId}
  // ═════════════════════════════════════════════════════════════

  CollectionReference<Map<String, dynamic>> get _sessions =>
      _currentAccount.collection('sessions');

  Future<String> startSession() async {
    final document = _sessions.doc();

    await document.set({
      'sessionId': document.id,
      'startTime': FieldValue.serverTimestamp(),
      'status': 'active',
      'endTime': null,
    });

    _activeSessionId = document.id;

    return document.id;
  }

  Future<void> endSession({
    required String sessionId,
  }) async {
    await _sessions.doc(sessionId).update({
      'status': 'completed',
      'endTime': FieldValue.serverTimestamp(),
    });

    if (_activeSessionId == sessionId) {
      _activeSessionId = null;
    }
  }

  Future<void> updateSessionStatus({
    required String sessionId,
    required String status,
  }) async {
    await _sessions.doc(sessionId).update({
      'status': status,
    });
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> watchSessions() {
    return _sessions.snapshots();
  }

  // ═════════════════════════════════════════════════════════════
  // CryData — Weak Entity
  // accounts/{accountId}/sessions/{sessionId}/cryData/{autoId}
  // ═════════════════════════════════════════════════════════════

  CollectionReference<Map<String, dynamic>> _cryData(
    String sessionId,
  ) {
    return _sessions
        .doc(sessionId)
        .collection('cryData');
  }

  Future<String> createCryData({
    required String sessionId,
    required String cause,
    required double confidence,
  }) async {
    final document = _cryData(sessionId).doc();

    await document.set({
      'cause': cause,
      'confidence': confidence,
      'timestamp': FieldValue.serverTimestamp(),
    });

    return document.id;
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> watchCryData({
    required String sessionId,
  }) {
    return _cryData(sessionId).snapshots();
  }

  // ═════════════════════════════════════════════════════════════
  // EnvironmentData — Weak Entity
  // accounts/{accountId}/sessions/{sessionId}/environmentData/{autoId}
  // ═════════════════════════════════════════════════════════════

  CollectionReference<Map<String, dynamic>> _environmentData(
    String sessionId,
  ) {
    return _sessions
        .doc(sessionId)
        .collection('environmentData');
  }

  Future<String> createEnvironmentData({
    required String sessionId,
    required double temperature,
    required double humidity,
  }) async {
    final document = _environmentData(sessionId).doc();

    await document.set({
      'temperature': temperature,
      'humidity': humidity,
      'timestamp': FieldValue.serverTimestamp(),
    });

    return document.id;
  }

  Stream<QuerySnapshot<Map<String, dynamic>>>
      watchEnvironmentData({
    required String sessionId,
  }) {
    return _environmentData(sessionId).snapshots();
  }
}