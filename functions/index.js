const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp();

exports.deleteOldPhotos = functions.pubsub.schedule('every 60 minutes').onRun(async (context) => {
  console.log('Delete Old Photos Function Started');
  const firestore = admin.firestore();
  const now = Date.now();
  const fiveMinutesMillis = 24 * 60 * 60 * 1000;

  const usersSnapshot = await firestore.collection('users').get();
  usersSnapshot.forEach(async (userDoc) => {
    console.log(`Processing user: ${userDoc.id}`);
    const photosSnapshot = await userDoc.ref.collection('photos').get();
    photosSnapshot.forEach(async (photoDoc) => {
      const photoData = photoDoc.data();
      const photoTime = new Date(photoData.uploaded._seconds * 1000);
      const timeDifference = now - photoTime.getTime();
      console.log(`Photo FileName: ${photoData.fileName}, Uploaded: ${photoTime}, Time Difference: ${timeDifference}`);

      if (timeDifference > fiveMinutesMillis) {
        const fileName = photoData.fileName; // Use the fileName field directly
        const photoRef = admin.storage().bucket().file(`user_images/${userDoc.id}/${fileName}`);
        
        try {
          await photoRef.delete();
          console.log(`Deleted photo from Storage: ${fileName}`);
          await photoDoc.ref.delete();
          console.log(`Deleted Firestore document for: ${fileName}`);
        } catch (error) {
          console.error('Error deleting photo:', error);
        }
      } else {
        console.log(`Photo not old enough for deletion: ${photoData.fileName}`);
      }
    });
  });

  console.log('Delete Old Photos Function Completed');
});







