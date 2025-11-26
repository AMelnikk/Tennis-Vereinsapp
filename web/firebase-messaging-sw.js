importScripts('https://www.gstatic.com/firebasejs/9.22.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/9.22.0/firebase-messaging-compat.js');

firebase.initializeApp({
  apiKey: "AIzaSyCV6bEMtuX4q-s4YpHStlU3kNCMj11T4Dk",
  authDomain: "db-teg.firebaseapp.com",
  databaseURL: "https://db-teg-default-rtdb.firebaseio.com",
  projectId: "db-teg",
  storageBucket: "db-teg.firebasestorage.app",
  messagingSenderId: "1050815457795",
  appId: "1:1050815457795:web:2d0bc6f9b80793f6e37c36",
  measurementId: "G-LNJY8VGKTG"
});

const messaging = firebase.messaging();

messaging.onBackgroundMessage((payload) => {
  console.log('[firebase-messaging-sw.js] Received background message ', payload);
  self.registration.showNotification(
    payload.notification.title,
    {
      body: payload.notification.body,
      icon: '/icons/Icon-192.png'
    }
  );
});