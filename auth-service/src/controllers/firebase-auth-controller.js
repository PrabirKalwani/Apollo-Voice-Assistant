const {
  getAuth,
  createUserWithEmailAndPassword,
  signInWithEmailAndPassword,
  signOut,
  sendEmailVerification,
  sendPasswordResetEmail,
} = require("../config/firebase");
// const CryptoJS = require("crypto-js");
// const { getFirestore, doc, setDoc, updateDoc } = require("firebase/firestore");
const auth = getAuth();
// const db = getFirestore();

const SECRET_KEY = process.env.SECRET_KEY;

class FirebaseAuthController {
  // Register user (removed Firestore and decryption)
  async registerUser(req, res) {
    const { email, password } = req.body;
    if (!email || !password) {
      return res.status(422).json({
        email: "Email is required",
        password: "Password is required",
      });
    }

    try {
      // Decryption logic commented out
      // const bytes = CryptoJS.AES.decrypt(password, SECRET_KEY);
      // const decryptedPassword = bytes.toString(CryptoJS.enc.Utf8);

      const userCredential = await createUserWithEmailAndPassword(
        auth,
        email,
        password // Directly use the provided password
      );
      const user = userCredential.user;

      await sendEmailVerification(auth.currentUser);

      res.status(201).json({
        message: "Verification email sent! User created successfully!",
      });
    } catch (error) {
      console.error(error);
      const errorMessage =
        error.message || "An error occurred while registering user";
      res.status(500).json({ error: errorMessage });
    }
  }

  // Login user (removed Firestore and decryption)
  async loginUser(req, res) {
    const { email, password } = req.body;
    if (!email || !password) {
      return res.status(422).json({
        email: "Email is required",
        password: "Password is required",
      });
    }

    try {
      // Decryption logic commented out
      // const bytes = CryptoJS.AES.decrypt(password, SECRET_KEY);
      // const decryptedPassword = bytes.toString(CryptoJS.enc.Utf8);

      const userCredential = await signInWithEmailAndPassword(
        auth,
        email,
        password // Directly use the provided password
      );
      const user = userCredential.user;

      const idToken = userCredential._tokenResponse.idToken;
      if (idToken) {
        res.cookie("access_token", idToken, {
          httpOnly: true,
        });
        res
          .status(200)
          .json({ message: "User logged in successfully", userCredential });
      } else {
        res.status(500).json({ error: "Internal Server Error" });
      }
    } catch (error) {
      console.error(error);
      const errorMessage =
        error.message || "An error occurred while logging in";
      res.status(500).json({ error: errorMessage });
    }
  }

  // Logout user (removed Firestore logic)
  async logoutUser(req, res) {
    try {
      const user = auth.currentUser;
      if (!user) {
        return res
          .status(400)
          .json({ message: "No user is currently logged in" });
      }

      await signOut(auth);
      res.clearCookie("access_token");
      res.status(200).json({ message: "User logged out successfully" });
    } catch (error) {
      console.error(error);
      res.status(500).json({ error: "Internal Server Error" });
    }
  }

  // Reset password
  async resetPassword(req, res) {
    const { email } = req.body;
    if (!email) {
      return res.status(422).json({
        email: "Email is required",
      });
    }

    try {
      await sendPasswordResetEmail(auth, email);
      res
        .status(200)
        .json({ message: "Password reset email sent successfully!" });
    } catch (error) {
      console.error(error);
      res.status(500).json({ error: "Internal Server Error" });
    }
  }
}

module.exports = new FirebaseAuthController();
