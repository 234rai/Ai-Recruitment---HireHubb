import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class GoogleAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Updated GoogleSignIn configuration to force account selection
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    signInOption: SignInOption.standard, // Force account selection
    scopes: [
      'email',
      'profile',
    ],
  );

  // Sign in with Google - UPDATED to force account selection
  Future<UserCredential?> signInWithGoogle() async {
    try {
      // First, sign out to clear any cached account
      await _googleSignIn.signOut();

      // Trigger the authentication flow - this will now always show account selection
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      // If user cancels the sign-in
      if (googleUser == null) {
        return null;
      }

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth =
      await googleUser.authentication;

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google credential
      return await _auth.signInWithCredential(credential);
    } catch (e) {
      print('Error signing in with Google: $e');
      rethrow;
    }
  }

  // Sign out - NO CHANGES NEEDED
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  // Get current user - NO CHANGES NEEDED
  User? getCurrentUser() {
    return _auth.currentUser;
  }
}