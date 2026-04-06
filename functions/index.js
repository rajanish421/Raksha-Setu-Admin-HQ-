const functions = require("firebase-functions");
const admin = require("firebase-admin");
admin.initializeApp();

exports.createAdminAccount = functions.https.onCall(async (data, context) => {
  // Check authentication
  if (!context.auth) {
    throw new functions.https.HttpsError("unauthenticated", "Login required.");
  }

  const requesterId = context.auth.uid;
  const requesterDoc = await admin.firestore().collection("users").doc(requesterId).get();

  if (!requesterDoc.exists || requesterDoc.data().role !== "superAdmin") {
    throw new functions.https.HttpsError("permission-denied", "Only Super Admins can create admins.");
  }

  try {
    const { name, phone, serviceNumber, password } = data;

    const email = `${serviceNumber.trim()}@defence.app`;

    // Create Firebase Auth user
    const newUser = await admin.auth().createUser({
      email,
      password,
      displayName: name,
    });

    // Add Firestore document
    await admin.firestore().collection("users").doc(newUser.uid).set({
      userId: newUser.uid,
      fullName: name,
      serviceNumber,
      phone,
      role: "admin",
      status: "active",
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    // Log this action
    await admin.firestore().collection("logs").add({
      action: "create_admin",
      performedBy: requesterId,
      createdAdminId: newUser.uid,
      timestamp: admin.firestore.FieldValue.serverTimestamp()
    });

    return {
      success: true,
      message: "Admin account created successfully",
      uid: newUser.uid,
      email
    };

  } catch (err) {
    throw new functions.https.HttpsError("internal", err.message);
  }
});
