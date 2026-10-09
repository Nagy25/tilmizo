importScripts("https://www.gstatic.com/firebasejs/10.7.1/firebase-app-compat.js");
importScripts("https://www.gstatic.com/firebasejs/10.7.1/firebase-messaging-compat.js");

firebase.initializeApp({
  apiKey: "AIzaSyBMMv2Du2eDbOjRSMhi8hKHqL2M1gMcW-c",
  authDomain: "telmizo-25dff.firebaseapp.com",
  projectId: "telmizo-25dff",
  storageBucket: "telmizo-25dff.firebasestorage.app",
  messagingSenderId: "541147574009",
  appId: "1:541147574009:web:341cdca95845b08d4e3c28",
  measurementId: "G-53N3QYCPR7"
});

// The dispatch function sends FCM notification payloads. The SDK displays
// them in the background; a second showNotification call would duplicate them.
firebase.messaging();
