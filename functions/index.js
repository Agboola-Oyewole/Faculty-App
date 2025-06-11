const { onSchedule } = require("firebase-functions/v2/scheduler");
const { onDocumentCreated, onDocumentWritten } = require("firebase-functions/v2/firestore");
const { onRequest } = require("firebase-functions/v2/https");
const axios = require("axios");
const { DateTime } = require("luxon");
const cors = require("cors")({ origin: true });
const admin = require("firebase-admin");
const { google } = require("googleapis");

admin.initializeApp();

// ✅ GOOGLE SHEETS API SETUP
const SCOPES = ["https://www.googleapis.com/auth/spreadsheets", "https://www.googleapis.com/auth/drive"];
const auth = new google.auth.GoogleAuth({
  keyFile: "service-account.json", // 🔹 Replace with your actual JSON key file
  scopes: SCOPES,
});
const sheets = google.sheets({ version: "v4", auth });
const drive = google.drive({ version: "v3", auth });

const MAPS_API_KEY = "API_KEY";

exports.getRoute = onRequest((req, res) => {
  cors(req, res, async () => {
    const authHeader = req.headers.authorization;

    if (!authHeader || !authHeader.startsWith("Bearer ")) {
      return res.status(401).json({ error: "Missing or invalid token" });
    }

    const idToken = authHeader.split("Bearer ")[1];

    try {
      const decodedToken = await admin.auth().verifyIdToken(idToken);
      console.log("✅ User authenticated:", decodedToken.uid);
    } catch (error) {
      console.error("❌ Token verification failed:", error);
      return res.status(403).json({ error: "Unauthorized" });
    }

    const { startLat, startLng, endLat, endLng } = req.query;

    if (!startLat || !startLng || !endLat || !endLng) {
      return res.status(400).json({ error: "Missing required coordinates" });
    }

    const url = `https://maps.googleapis.com/maps/api/directions/json?origin=${startLat},${startLng}&destination=${endLat},${endLng}&key=${MAPS_API_KEY}`;

    try {
      const response = await axios.get(url);
      const data = response.data;

      if (data.status !== "OK") {
        return res.status(400).json({ error: data.status });
      }

      const encodedPolyline = data.routes[0].overview_polyline.points;
      res.json({ polyline: encodedPolyline });
    } catch (error) {
      console.error("❌ Error fetching directions:", error.message);
      res.status(500).json({ error: "Failed to fetch directions" });
    }
  });
});

// ✅ FIXED PUSH NOTIFICATIONS
exports.sendScheduledNotifications = onSchedule("every 5 minutes", async () => {
  const db = admin.firestore();
  const currentTime = Date.now(); // Current time in milliseconds
  const usersSnapshot = await db.collection("schedules").get();

  for (const userDoc of usersSnapshot.docs) {
    const userData = userDoc.data();
    const userId = userData.userId;
    const fcmToken = await getUserFcmToken(userId);
    if (!fcmToken) continue;

    const today = new Intl.DateTimeFormat("en-US", { weekday: "long" }).format(new Date());
    const eventsForToday = userData.schedule[today] || [];

    for (const event of eventsForToday) {
      if (!event.startTime) continue;

      const eventStartTime = event.startTime.toDate(); // Convert Firestore Timestamp to Date
      const eventStartMillis = eventStartTime.getTime();
      const notificationTimeMillis = eventStartMillis - 5 * 60 * 1000; // 5 minutes before event

      if (currentTime >= notificationTimeMillis && currentTime < eventStartMillis) {
        await sendNotification(fcmToken, event.name, eventStartTime);
      }
    }
  }
});

// Get user's FCM token
async function getUserFcmToken(userId) {
  const userDoc = await admin.firestore().collection("users").doc(userId).get();
  return userDoc.exists ? userDoc.data().fcmToken : null;
}

// Send notification
async function sendNotification(token, eventName, startTime) {
  const formattedTime = DateTime.fromJSDate(startTime, { zone: "Africa/Lagos" }).toFormat("hh:mm a");
  const payload = {
    notification: {
      title: "FES Connect Hub",
      body: `Your Course ${eventName} Lecture starts at ${formattedTime}. Get ready!`,
    },
    token: token,
    data: {
      type: "schedule",
    },
  };

  try {
    await admin.messaging().send(payload);
    console.log(`✅ Notification sent for "${eventName}" at ${formattedTime}`);
  } catch (error) {
    console.error("❌ Error sending notification:", error);

    // Handle expired token error
    if (error.code === "messaging/registration-token-not-registered") {
      console.log(`⚠️ Expired token detected. Removing from Firestore: ${token}`);

      const usersRef = admin.firestore().collection("users");
      const querySnapshot = await usersRef.where("fcmToken", "==", token).get();

      // Use for...of to await async function calls properly
      for (const doc of querySnapshot.docs) {
        await doc.ref.update({ fcmToken: admin.firestore.FieldValue.delete() });
        console.log(`✅ Removed expired token from user: ${doc.id}`);
      }
    }
  }
}

// ✅ CREATE A GOOGLE SHEET FOR CLASS ATTENDANCE
exports.createClassSheet = onDocumentCreated("attendance/{classId}", async (event) => {
  const snap = event.data;
  if (!snap) return;
  const classId = event.params.classId;
  const classData = snap.data();

  try {
    const response = await sheets.spreadsheets.create({
      requestBody: {
        properties: { title: `Class - ${classData.metadata.courseCode}` },
        sheets: [{ properties: { title: "Attendance" } }],
      },
    });

    const spreadsheetId = response.data.spreadsheetId;
    const sheetUrl = `https://docs.google.com/spreadsheets/d/${spreadsheetId}/edit`;

    console.log(`✅ Created Google Sheet for ${classData.metadata.courseCode}: ${sheetUrl}`);

    await drive.permissions.create({
      fileId: spreadsheetId,
      requestBody: {
        role: "reader",
        type: "anyone",
      },
    });

    await admin.firestore().collection("attendance").doc(classId).update({
      "metadata.sheetId": spreadsheetId,
      "metadata.sheetUrl": sheetUrl,
    });

    await sheets.spreadsheets.values.update({
      spreadsheetId,
      range: "Attendance!A1:F1",
      valueInputOption: "RAW",
      requestBody: {
        values: [["Name", "Matric No", "Timestamp", "Status", "Department"]],
      },
    });

    console.log("✅ Sheet initialized with headers.");
  } catch (error) {
    console.error("❌ Error creating Google Sheet:", error);
  }
});

// ✅ SYNC STUDENT ATTENDANCE TO THE CLASS'S GOOGLE SHEET
exports.syncAttendanceToSheet = onDocumentWritten("attendance/{classId}/students/{studentId}", async (event) => {
  const snap = event.data;
  if (!snap) return;
  const { classId, studentId } = event.params;
  const studentData = snap.after ? snap.after.data() : null;

  if (!studentData) return null;

  try {
    const classDoc = await admin.firestore().collection("attendance").doc(classId).get();
    const classData = classDoc.data();
    if (!classData || !classData.metadata.sheetId) {
      console.error("❌ No Sheet ID found for class.");
      return null;
    }

    const spreadsheetId = classData.metadata.sheetId;

    const options = {
      day: 'numeric',
      month: 'long',
      year: 'numeric',
      hour: 'numeric',
      minute: '2-digit',
      hour12: true,
    };

    const formattedDate = new Date().toLocaleString('en-US', options);
    // e.g., "14 March 2025, 12:00 AM"

    const values = [
      [studentData.name, studentData.matric_no, formattedDate, studentData.status, studentData.department],
    ];


    await sheets.spreadsheets.values.append({
      spreadsheetId,
      range: "Attendance!A:F",
      valueInputOption: "RAW",
      insertDataOption: "INSERT_ROWS",
      requestBody: { values },
    });

    await sheets.spreadsheets.batchUpdate({
      spreadsheetId,
      requestBody: {
        requests: [
          {
            sortRange: {
              range: {
                sheetId: 0, // Assuming the first (Attendance) sheet is at index 0
                startRowIndex: 1, // Skip headers
                startColumnIndex: 0,
                endColumnIndex: 5,
              },
              sortSpecs: [
                {
                  dimensionIndex: 1, // Matric No column (B = index 1)
                  sortOrder: "ASCENDING",
                },
              ],
            },
          },
        ],
      },
    });


    console.log(`✅ Attendance synced for ${studentData.name}.`);
  } catch (error) {
    console.error("❌ Error syncing attendance:", error);
  }

  return null;
});

exports.sendClassNotification = onDocumentCreated('attendance/{classId}', async (event) => {
  const snap = event.data;  // Access document snapshot from event
  const classData = snap.data();
  const department = classData.metadata.department;
  const level = classData.metadata.level;
  const code = classData.metadata.courseCode;

  // Get all users who match the department and level
  const usersSnapshot = await admin.firestore()
    .collection('users')
    .where('department', '==', department)
    .where('level', '==', level)
    .get();

  if (usersSnapshot.empty) {
    console.log('No users found for this department and level');
    return null;
  }

  // Prepare the notification message
  const message = {
    notification: {
      title: 'Attendance Started!',
      body: `Lecture attendance for ${code} has started. Please check in.`,
    },
    tokens: [],
    "data": {
        "type": "attendance"
     }
  };

  // Add FCM tokens of matching users
  usersSnapshot.forEach((doc) => {
    const user = doc.data();
    if (user.fcmToken) {
      message.tokens.push(user.fcmToken);
    }
  });

  // Send the notification
  try {
  console.log('Messages', message);
    const response = await admin.messaging().sendEachForMulticast(message);
    console.log(`${response.successCount} notifications sent successfully`);
    return null;
  } catch (error) {
    console.log('Error sending notifications:', error);
    return null;
  }
});
