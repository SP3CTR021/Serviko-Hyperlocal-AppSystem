import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/user_model.dart';
import 'mysql_service.dart';

class AuthService extends ChangeNotifier {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  FirebaseAuth get _auth => FirebaseAuth.instance;
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;
  final GoogleSignIn? _googleSignIn = kIsWeb
      ? null
      : GoogleSignIn(
          serverClientId:
              '217372431910-0nq7rf05a3o6aahqr9sf25si3feq9nsu.apps.googleusercontent.com',
        );

  UserModel? _currentUser;
  bool _isLoading = false;

  UserModel? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;
  bool get isLoading => _isLoading;

  bool get isWorker => _currentUser?.isWorker ?? false;
  bool get isCustomer => _currentUser?.isCustomer ?? false;

  User? get firebaseUser {
    try {
      return _auth.currentUser;
    } catch (_) {
      return null;
    }
  }

  Stream<User?> get userStream {
    try {
      return _auth.authStateChanges();
    } catch (_) {
      return const Stream.empty();
    }
  }

  void initialize() {
    _currentUser = null;
    notifyListeners();
  }

  // GOOGLE SIGN IN
  Future<User?> signInWithGoogle({String role = 'customer'}) async {
    _isLoading = true;
    notifyListeners();

    try {
      User? user;
      if (kIsWeb) {
        GoogleAuthProvider googleProvider = GoogleAuthProvider();
        UserCredential userCredential = await _auth.signInWithPopup(googleProvider);
        user = userCredential.user;
      } else {
        final googleUser = await _googleSignIn?.signIn();
        if (googleUser == null) {
          _isLoading = false;
          notifyListeners();
          return null;
        }

        final googleAuth = await googleUser.authentication;
        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );
        user = (await _auth.signInWithCredential(credential)).user;
      }

      if (user != null) {
        UserModel? loadedUser;
        try {
          final doc = await _firestore.collection('users').doc(user.uid).get();
          if (doc.exists && doc.data() != null) {
            loadedUser = UserModel.fromMap(doc.data()!);
          } else {
            final displayName = user.displayName ?? (user.email?.split('@').first ?? 'Google User');
            final newUser = UserModel(
              id: user.uid.hashCode,
              uid: user.uid,
              name: displayName.split(' ').first,
              fullName: displayName,
              email: user.email ?? '',
              role: role,
              phoneNumber: user.phoneNumber,
              profilePhotoUrl: user.photoURL,
              memberSince: DateTime.now(),
            );
            await _firestore.collection('users').doc(user.uid).set(newUser.toMap(), SetOptions(merge: true));
            loadedUser = newUser;
          }
        } catch (e) {
          debugPrint('[AuthService] Firestore sync note: $e');
        }

        final displayName = user.displayName ?? (user.email?.split('@').first ?? 'Google User');
        _currentUser = loadedUser ?? UserModel(
          id: user.uid.hashCode,
          uid: user.uid,
          name: displayName.split(' ').first,
          fullName: displayName,
          email: user.email ?? '',
          role: role,
          phoneNumber: user.phoneNumber,
          profilePhotoUrl: user.photoURL,
        );
      }
      _isLoading = false;
      notifyListeners();
      return user;
    } catch (e) {
      debugPrint('[AuthService] Google Sign-In note: $e');
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  // EMAIL/PASSWORD REGISTER
  Future<User?> registerWithEmail(String email, String password) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential.user;
    } catch (e) {
      debugPrint('[AuthService] Registration Error: $e');
      return null;
    }
  }

  // EMAIL/PASSWORD LOGIN
  Future<User?> signInWithEmail(String email, String password) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential.user;
    } catch (e) {
      debugPrint('[AuthService] Login Error: $e');
      return null;
    }
  }

  // FORGOT PASSWORD
  Future<String?> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return null; // null = success
    } catch (e) {
      debugPrint('[AuthService] Reset Password Error: $e');
      return e.toString();
    }
  }

  // FULL SERVIKO LOGIN
  Future<bool> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    // 1. Try Firebase Authentication
    try {
      final userCred = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      if (userCred.user != null) {
        UserModel? loadedUser;
        try {
          final doc = await _firestore.collection('users').doc(userCred.user!.uid).get();
          if (doc.exists && doc.data() != null) {
            loadedUser = UserModel.fromMap(doc.data()!);
          }
        } catch (e) {
          debugPrint('[AuthService] Firestore user load note: $e');
        }

        final displayName = userCred.user!.displayName ?? email.split('@').first;
        _currentUser = loadedUser ?? UserModel(
          id: userCred.user!.uid.hashCode,
          uid: userCred.user!.uid,
          name: displayName.split(' ').first,
          fullName: displayName,
          email: email,
          role: email.contains('worker') ? 'worker' : 'customer',
        );

        // Ensure user document exists in Firestore (with merge)
        try {
          await _firestore.collection('users').doc(userCred.user!.uid).set(
            _currentUser!.toMap(),
            SetOptions(merge: true),
          );
        } catch (e) {
          debugPrint('[AuthService] Firestore user ensure note: $e');
        }

        _isLoading = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint('[AuthService] Firebase login note: $e');
    }

    // 2. Fallback to MySQL Service / Demo Data
    try {
      final user = await MySqlService().login(email, password);
      if (user != null) {
        _currentUser = user;
        _isLoading = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint('[AuthService] MySql login error: $e');
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  // FULL SERVIKO REGISTER
  Future<bool> register({
    required String fullName,
    required String email,
    required String password,
    required String role,
    String? phoneNumber,
    String? city,
    String? barangay,
    String? skill,
  }) async {
    _isLoading = true;
    notifyListeners();

    // 1. Try Firebase Auth + Firestore registration
    try {
      final fbCred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      if (fbCred.user != null) {
        await fbCred.user!.updateDisplayName(fullName);
        try {
          await fbCred.user!.sendEmailVerification();
        } catch (_) {}

        final newUser = UserModel(
          id: fbCred.user!.uid.hashCode,
          uid: fbCred.user!.uid,
          name: fullName.split(' ').first,
          fullName: fullName,
          email: email,
          role: role,
          phoneNumber: phoneNumber,
          city: city,
          barangay: barangay,
          skill: skill,
          memberSince: DateTime.now(),
        );

        try {
          await _firestore.collection('users').doc(fbCred.user!.uid).set(
            newUser.toMap(),
            SetOptions(merge: true),
          );
        } catch (e) {
          debugPrint('[AuthService] Firestore user write note: $e');
        }

        _currentUser = newUser;
        _isLoading = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint('[AuthService] Firebase register note: $e');
    }

    // 2. Fallback to MySQL Service
    try {
      final user = await MySqlService().register(
        fullName: fullName,
        email: email,
        password: password,
        role: role,
        phoneNumber: phoneNumber,
        city: city,
        barangay: barangay,
        skill: skill,
      );
      _currentUser = user;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('[AuthService] Register error: $e');
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  // UPDATE PROFILE PHOTO (Firestore + Firebase Auth + Local State)
  Future<void> updateProfilePhoto(String url) async {
    if (_currentUser != null) {
      _currentUser = _currentUser!.copyWith(profilePhotoUrl: url);
      notifyListeners();
    }

    // 1. Update Firebase Auth user photoURL
    try {
      final fb = firebaseUser;
      if (fb != null) {
        await fb.updatePhotoURL(url);
      }
    } catch (e) {
      debugPrint('[AuthService] Firebase updatePhotoURL note: $e');
    }

    final dataToMerge = _currentUser != null
        ? _currentUser!.toMap()
        : <String, dynamic>{'profile_photo_url': url};

    // 2. Set/merge Firestore user doc under Firebase UID
    final fbUid = firebaseUser?.uid ?? _currentUser?.uid;
    if (fbUid != null && fbUid.isNotEmpty) {
      try {
        await _firestore
            .collection('users')
            .doc(fbUid)
            .set(dataToMerge, SetOptions(merge: true));
      } catch (e) {
        debugPrint('[AuthService] Firestore updatePhoto (uid) note: $e');
      }
    }

    // 3. Set/merge Firestore user doc under numeric ID
    if (_currentUser != null) {
      try {
        await _firestore
            .collection('users')
            .doc(_currentUser!.id.toString())
            .set(dataToMerge, SetOptions(merge: true));
      } catch (e) {
        debugPrint('[AuthService] Firestore updatePhoto (numeric id) note: $e');
      }

      // 4. If worker, also update workers collection if worker doc exists
      try {
        final workerDoc = await _firestore
            .collection('workers')
            .doc(_currentUser!.id.toString())
            .get();
        if (workerDoc.exists) {
          await _firestore
              .collection('workers')
              .doc(_currentUser!.id.toString())
              .set({'user': dataToMerge}, SetOptions(merge: true));
        }
      } catch (e) {
        debugPrint('[AuthService] Firestore update worker photo note: $e');
      }
    }
  }

  void updateProfilePhotoUrl(String url) {
    updateProfilePhoto(url);
  }

  // SUBMIT PROFILE VERIFICATION & ID
  Future<bool> submitVerification({
    required String idType,
    required String idNumber,
    String? idPhotoUrl,
    String? phoneNumber,
    String? city,
    String? barangay,
    String? profilePhotoUrl,
  }) async {
    if (_currentUser == null) return false;

    final updated = _currentUser!.copyWith(
      idType: idType,
      idNumber: idNumber,
      idPhotoUrl: idPhotoUrl ?? _currentUser!.idPhotoUrl,
      phoneNumber: (phoneNumber != null && phoneNumber.isNotEmpty) ? phoneNumber : _currentUser!.phoneNumber,
      city: (city != null && city.isNotEmpty) ? city : _currentUser!.city,
      barangay: (barangay != null && barangay.isNotEmpty) ? barangay : _currentUser!.barangay,
      profilePhotoUrl: (profilePhotoUrl != null && profilePhotoUrl.isNotEmpty) ? profilePhotoUrl : _currentUser!.profilePhotoUrl,
      isVerified: true,
      verifiedAt: DateTime.now(),
    );

    _currentUser = updated;
    notifyListeners();

    final data = updated.toMap();

    // 1. Update Firestore under UID
    final fbUid = firebaseUser?.uid ?? updated.uid;
    if (fbUid != null && fbUid.isNotEmpty) {
      try {
        await _firestore.collection('users').doc(fbUid).set(data, SetOptions(merge: true));
      } catch (e) {
        debugPrint('[AuthService] Firestore submitVerification (uid) note: $e');
      }
    }

    // 2. Update Firestore under numeric id
    try {
      await _firestore.collection('users').doc(updated.id.toString()).set(data, SetOptions(merge: true));
    } catch (e) {
      debugPrint('[AuthService] Firestore submitVerification (numeric id) note: $e');
    }

    // 3. If worker, update workers collection
    if (updated.isWorker) {
      try {
        final workerDoc = await _firestore.collection('workers').doc(updated.id.toString()).get();
        if (workerDoc.exists) {
          await _firestore.collection('workers').doc(updated.id.toString()).set({
            'user': data,
          }, SetOptions(merge: true));
        }
      } catch (_) {}
    }

    return true;
  }

  void switchDemoRole(String role) {
    if (_currentUser != null) {
      _currentUser = _currentUser!.copyWith(role: role);
      try {
        _firestore.collection('users').doc(_currentUser!.id.toString()).set(
          {'role': role},
          SetOptions(merge: true),
        );
        if (firebaseUser != null) {
          _firestore.collection('users').doc(firebaseUser!.uid).set(
            {'role': role},
            SetOptions(merge: true),
          );
        }
      } catch (_) {}
    } else {
      _currentUser = UserModel(
        id: 1,
        name: role == 'worker' ? 'Worker' : 'User',
        fullName: role == 'worker' ? 'Worker Account' : 'Customer Account',
        email: 'test@serviko.com',
        role: role,
        memberSince: DateTime.now(),
      );
    }
    notifyListeners();
  }

  // SIGN OUT
  Future<void> signOut() async {
    await logout();
  }

  Future<void> logout() async {
    try {
      if (!kIsWeb) {
        await _googleSignIn?.signOut();
      }
      await _auth.signOut();
    } catch (e) {
      debugPrint('[AuthService] Sign out note: $e');
    }
    _currentUser = null;
    notifyListeners();
  }
}
