// User photos are stored as Blobs in IndexedDB (localStorage is too small for images).
const DB_NAME = "gym-workout";
const STORE = "photos";

let dbPromise;

function open() {
  dbPromise ??= new Promise((resolve, reject) => {
    const request = indexedDB.open(DB_NAME, 1);
    request.onupgradeneeded = () => request.result.createObjectStore(STORE);
    request.onsuccess = () => resolve(request.result);
    request.onerror = () => reject(request.error);
  });
  return dbPromise;
}

async function run(mode, action) {
  const db = await open();
  return new Promise((resolve, reject) => {
    const tx = db.transaction(STORE, mode);
    const request = action(tx.objectStore(STORE));
    tx.oncomplete = () => resolve(request.result);
    tx.onerror = () => reject(tx.error);
  });
}

export async function savePhoto(blob) {
  const id = crypto.randomUUID();
  await run("readwrite", (store) => store.put(blob, id));
  return id;
}

export function loadPhoto(id) {
  return run("readonly", (store) => store.get(id));
}

export function deletePhoto(id) {
  return run("readwrite", (store) => store.delete(id));
}

// Downscale camera photos so storage stays small and rendering stays fast.
export async function resizeImage(file, maxSize = 1200) {
  const bitmap = await createImageBitmap(file);
  const scale = Math.min(1, maxSize / Math.max(bitmap.width, bitmap.height));
  const canvas = document.createElement("canvas");
  canvas.width = Math.round(bitmap.width * scale);
  canvas.height = Math.round(bitmap.height * scale);
  canvas.getContext("2d").drawImage(bitmap, 0, 0, canvas.width, canvas.height);
  bitmap.close?.();
  return new Promise((resolve) => canvas.toBlob(resolve, "image/jpeg", 0.82));
}
