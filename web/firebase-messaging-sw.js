importScripts('https://www.gstatic.com/firebasejs/11.7.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/11.7.0/firebase-messaging-compat.js');

firebase.initializeApp({
  apiKey: "AIzaSyDbkt-G2VDagfepNysgp98vIn-DYbk3jSA",
  authDomain: "fes-connect-x.firebaseapp.com",
  projectId: "fes-connect-x",
  storageBucket: "fes-connect-x.firebasestorage.app",
  messagingSenderId: "807516873313",
  appId: "1:807516873313:web:596714936e27c18a58c020",  // ← Web appId
  measurementId: 'G-PSCCYPBFEQ',
});

const messaging = firebase.messaging();
