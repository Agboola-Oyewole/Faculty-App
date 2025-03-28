const { onSchedule } = require("firebase-functions/v2/scheduler");
const { onDocumentCreated, onDocumentWritten } = require("firebase-functions/v2/firestore");
const { DateTime } = require("luxon");
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

// ✅ EXISTING PUSH NOTIFICATIONS
exports.sendScheduledNotifications = onSchedule("every 5 minutes", async () => {
  const db = admin.firestore();
  const currentTime = admin.firestore.Timestamp.now();
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

      const eventStartTime = event.startTime;
      const notificationTime = admin.firestore.Timestamp.fromDate(
        new Date(eventStartTime.toDate().getTime() - 5 * 60000)
      );

      if (currentTime.seconds >= notificationTime.seconds &&
          currentTime.seconds < eventStartTime.seconds) {
        await sendNotification(fcmToken, event.name, event.startTime.toDate());
      }
    }
  }
});

async function getUserFcmToken(userId) {
  const userDoc = await admin.firestore().collection("users").doc(userId).get();
  return userDoc.exists ? userDoc.data().fcmToken : null;
}

async function sendNotification(token, eventName, startTime) {
  const formattedTime = DateTime.fromJSDate(startTime, { zone: "Africa/Lagos" }).toFormat("hh:mm a");
  const payload = {
    notification: {
      title: "Upcoming Lecture 🚀",
      body: `Your Course ${eventName} Lecture starts at ${formattedTime}. Get ready!`,
    },
    token: token,
  };

  try {
    await admin.messaging().send(payload);
    console.log(`✅ Notification sent for "${eventName}" at ${formattedTime}`);
  } catch (error) {
    console.error("❌ Error sending notification:", error);
  }
}

// ✅ CREATE A GOOGLE SHEET FOR CLASS ATTENDANCE
exports.createClassSheet = onDocumentCreated("attendance/{classId}", async (event) => {
  const snap = event.data;
  if (!snap) return;
  const classId = event.params.classId;
  const classData = snap.data();

  try {
    // Create a new Google Sheet
    const response = await sheets.spreadsheets.create({
      requestBody: {
        properties: { title: `Class - ${classData.metadata.courseCode}` },
        sheets: [{ properties: { title: "Attendance" } }],
      },
    });

    const spreadsheetId = response.data.spreadsheetId;
    const sheetUrl = `https://docs.google.com/spreadsheets/d/${spreadsheetId}/edit`;

    console.log(`✅ Created Google Sheet for ${classData.metadata.courseCode}: ${sheetUrl}`);

    // Make the sheet public (readable by everyone)
    await drive.permissions.create({
      fileId: spreadsheetId,
      requestBody: {
        role: "reader",
        type: "anyone",
      },
    });

    // Store the Sheet ID & URL inside Firestore
    await admin.firestore().collection("attendance").doc(classId).update({
      "metadata.sheetId": spreadsheetId,
      "metadata.sheetUrl": sheetUrl, // 🔹 Now storing the URL
    });

    // Initialize the sheet with headers
    await sheets.spreadsheets.values.update({
      spreadsheetId,
      range: "Attendance!A1:F1",
      valueInputOption: "RAW",
      requestBody: {
        values: [["Class ID", "Name", "Matric No", "Timestamp", "Status"]],
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

  if (!studentData) return null; // If document was deleted, do nothing

  try {
    // Fetch class metadata to get the Sheet ID
    const classDoc = await admin.firestore().collection("attendance").doc(classId).get();
    const classData = classDoc.data();
    if (!classData || !classData.metadata.sheetId) {
      console.error("❌ No Sheet ID found for class.");
      return null;
    }

    const spreadsheetId = classData.metadata.sheetId;

    // Append student attendance to the correct sheet
    const values = [
      [classId, studentData.name, studentData.matric_no, new Date().toISOString(), studentData.status],
    ];

    await sheets.spreadsheets.values.append({
      spreadsheetId,
      range: "Attendance!A:F",
      valueInputOption: "RAW",
      insertDataOption: "INSERT_ROWS",
      requestBody: { values },
    });

    console.log(`✅ Attendance synced for ${studentData.name}.`);
  } catch (error) {
    console.error("❌ Error syncing attendance:", error);
  }

  return null;
});
