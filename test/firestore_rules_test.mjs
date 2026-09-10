// Run: firebase emulators:exec --only firestore --project demo-college-rules "node test/firestore_rules_test.mjs"
import assert from 'node:assert/strict';
import { initializeApp, deleteApp } from 'firebase/app';
import { getFirestore, connectFirestoreEmulator, doc, getDoc, getDocs,
  collection, query, where, setDoc, updateDoc, deleteDoc, writeBatch,
  deleteField, Timestamp, Bytes, setLogLevel } from 'firebase/firestore';

const projectId = 'demo-college-rules';
const host = process.env.FIRESTORE_EMULATOR_HOST;
assert.ok(host && /^(127\.0\.0\.1|localhost):\d+$/.test(host), 'Local emulator required');
setLogLevel('silent');
const apps = [];
let passed = 0;
function client(uid) {
  const app = initializeApp({ projectId, apiKey: 'demo' }, uid ?? 'anonymous');
  apps.push(app);
  const db = getFirestore(app);
  const [hostname, port] = host.split(':');
  connectFirestoreEmulator(db, hostname, Number(port), uid ? { mockUserToken: { sub: uid } } : {});
  return db;
}
async function seed(path, data) {
  const fields = Object.fromEntries(Object.entries(data).map(([key, value]) =>
    [key, { stringValue: value }]));
  const response = await fetch(`http://${host}/v1/projects/${projectId}/databases/(default)/documents/${path}`, {
    method: 'PATCH', headers: { Authorization: 'Bearer owner', 'Content-Type': 'application/json' },
    body: JSON.stringify({ fields }),
  });
  assert.ok(response.ok, await response.text());
}
async function allowed(label, action) { await action(); passed++; console.log(`PASS ${label}`); }
async function denied(label, action) {
  await assert.rejects(action, error => error.code === 'permission-denied', label);
  passed++; console.log(`PASS ${label}`);
}
try {
  const clear = await fetch(`http://${host}/emulator/v1/projects/${projectId}/databases/(default)/documents`, { method: 'DELETE' });
  assert.ok(clear.ok);
  for (const [uid, role, collegeId, status] of [
    ['admin', 'admin', '', 'approved'], ['a', 'college', 'A', 'approved'],
    ['b', 'college', 'B', 'approved'], ['pending', 'college', 'A', 'pending'],
    ['deo', 'deo', '', 'approved'], ['diet', 'diet', '', 'approved'],
    ['school', 'school', '', 'approved'],
  ]) await seed(`users/${uid}`, { uid, role, collegeId, status, districtId: 'D', schoolId: 'S' });
  await seed('students/a', { collegeId: 'A', districtId: 'D', finalSchoolId: 'S', name: 'Original', status: 'created' });
  await seed('students/b', { collegeId: 'B', districtId: 'E', finalSchoolId: 'T', name: 'Other', status: 'created' });
  await seed('correction_requests/existing-b', { collegeId: 'B', studentId: 'b', status: 'pending' });
  await seed('users/no-status', { role: 'college', collegeId: 'A' });
  await seed('users/no-college', { role: 'college', status: 'approved' });
  await seed('users/no-uid', { role: 'college', status: 'approved', collegeId: 'A' });
  await seed('users/spaces', { role: 'college', status: 'approved', collegeId: ' A ' });
  await seed('students/document-id', { collegeId: 'A', studentId: 'legacy-number', registrationId: 'registration-number', status: 'created' });
  const a = client('a'), b = client('b'), admin = client('admin'), anon = client(), pending = client('pending');
  const deo = client('deo'), diet = client('diet'), school = client('school'), newcomer = client('new');
  for (const uid of ['no-status', 'no-college', 'spaces', 'no-profile']) {
    const invalid = client(uid);
    await allowed(`${uid}: own profile read`, () => getDoc(doc(invalid, `users/${uid}`)));
    await denied(`${uid}: canonical student query denied`, () => getDocs(query(collection(invalid, 'students'), where('collegeId', '==', 'A'))));
    await denied(`${uid}: canonical request query denied`, () => getDocs(query(collection(invalid, 'correction_requests'), where('collegeId', '==', 'A'))));
  }
  const noUid = client('no-uid');
  await allowed('legacy profile without uid uses authenticated document ID', () => getDocs(query(collection(noUid, 'students'), where('collegeId', '==', 'A'))));
  await allowed('own profile', () => getDoc(doc(a, 'users/a')));
  await denied('other profile', () => getDoc(doc(a, 'users/b')));
  await denied('self promotion', () => updateDoc(doc(a, 'users/a'), { role: 'admin' }));
  await denied('tenant reassignment', () => updateDoc(doc(a, 'users/a'), { collegeId: 'B' }));
  await allowed('pending registration', () => setDoc(doc(newcomer, 'users/new'), { uid: 'new', role: 'college', collegeId: 'A', status: 'pending' }));
  await denied('self approval', () => updateDoc(doc(newcomer, 'users/new'), { status: 'approved' }));
  await denied('anonymous student read', () => getDoc(doc(anon, 'students/a')));
  await denied('pending student read', () => getDoc(doc(pending, 'students/a')));
  await allowed('own student', () => getDoc(doc(a, 'students/a')));
  await denied('other student', () => getDoc(doc(a, 'students/b')));
  await allowed('college-filtered query', () => getDocs(query(collection(a, 'students'), where('collegeId', '==', 'A'))));
  await denied('unfiltered student query', () => getDocs(collection(a, 'students')));
  await denied('alias query', () => getDocs(query(collection(a, 'students'), where('collegeId', 'in', ['A', 'Legacy A']))));
  await denied('student name edit', () => updateDoc(doc(a, 'students/a'), { name: 'Tampered' }));
  await denied('college student creation', () => setDoc(doc(a, 'students/new'), { collegeId: 'A' }));
  await denied('college student deletion', () => deleteDoc(doc(a, 'students/a')));
  await allowed('district student query', () => getDocs(query(collection(deo, 'students'), where('districtId', '==', 'D'))));
  await allowed('diet student read', () => getDoc(doc(diet, 'students/a')));
  await allowed('school student query', () => getDocs(query(collection(school, 'students'), where('finalSchoolId', '==', 'S'))));
  await denied('school other student', () => getDoc(doc(school, 'students/b')));
  const request = (id, extra = {}) => ({ requestId: id, studentId: 'a', collegeId: 'A', requestedBy: 'a', status: 'pending', ...extra });
  await denied('stored student number is not a document path', () => setDoc(doc(a, 'correction_requests/wrong-path'), request('wrong-path', { studentId: 'legacy-number' })));
  await allowed('full submission uses actual document ID despite different stored identifiers', async () => {
    const now = Timestamp.now();
    const batch = writeBatch(a);
    batch.set(doc(a, 'correction_requests/canonical-path'), request('canonical-path', {
      studentId: 'document-id', registrationId: 'registration-number', districtId: 'D',
      studentName: 'Student', fatherName: 'Father', motherName: 'Mother',
      nameCorrectionEnglish: 'Corrected', namePunjabi: '',
      fatherNameCorrectionEnglish: '', fatherNamePunjabi: '',
      motherNameCorrectionEnglish: '', motherNamePunjabi: '',
      certificateFileName: 'certificate.pdf', certificateMimeType: 'application/pdf',
      certificatePdf: Bytes.fromUint8Array(new Uint8Array([37, 80, 68, 70])), createdAt: now, updatedAt: now,
    }));
    batch.update(doc(a, 'students/document-id'), {
      correctionRequestId: 'canonical-path', correctionRequestStatus: 'pending',
      correctionRequestedAt: now, correctionRejectedAt: deleteField(),
      correctionRejectedRemarks: deleteField(), correctionApprovedAt: deleteField(), updatedAt: now,
    });
    await batch.commit();
  });
  await denied('missing request link', () => updateDoc(doc(a, 'students/a'), { correctionRequestStatus: 'pending' }));
  await denied('cross-college request', () => setDoc(doc(a, 'correction_requests/cross'), request('cross', { collegeId: 'B' })));
  await denied('foreign student with own collegeId', () => setDoc(doc(a, 'correction_requests/foreign'), request('foreign', { studentId: 'b' })));
  await denied('pre-approved request', () => setDoc(doc(a, 'correction_requests/approved'), request('approved', { status: 'approved' })));
  await denied('forged requester', () => setDoc(doc(a, 'correction_requests/forged'), request('forged', { requestedBy: 'admin' })));
  await denied('injected review fields', () => setDoc(doc(a, 'correction_requests/review'), request('review', { reviewedBy: 'admin' })));
  await denied('unlinked student marker', () => updateDoc(doc(a, 'students/a'), { correctionRequestId: 'missing', correctionRequestStatus: 'pending' }));
  await allowed('atomic correction submission', async () => {
    const batch = writeBatch(a);
    batch.set(doc(a, 'correction_requests/request-a'), request('request-a'));
    batch.update(doc(a, 'students/a'), { correctionRequestId: 'request-a', correctionRequestStatus: 'pending', correctionRequestedAt: Timestamp.now(), correctionRejectedAt: deleteField(), correctionRejectedRemarks: deleteField(), correctionApprovedAt: deleteField(), updatedAt: Timestamp.now() });
    await batch.commit();
  });
  await allowed('own correction query', () => getDocs(query(collection(a, 'correction_requests'), where('collegeId', '==', 'A'))));
  await denied('all correction query', () => getDocs(collection(a, 'correction_requests')));
  await denied('other correction read', () => getDoc(doc(b, 'correction_requests/request-a')));
  for (const status of ['approved', 'rejected']) {
    await denied(`college cannot set ${status}`, () => updateDoc(doc(a, 'correction_requests/request-a'), { status }));
    await denied(`college cannot mark student ${status}`, () => updateDoc(doc(a, 'students/a'), { correctionRequestStatus: status }));
  }
  await denied('college cannot delete request', () => deleteDoc(doc(a, 'correction_requests/request-a')));
  await allowed('admin reads all students', () => getDocs(collection(admin, 'students')));
  await allowed('admin reads all requests', () => getDocs(collection(admin, 'correction_requests')));
  await allowed('admin creates request', () => setDoc(doc(admin, 'correction_requests/admin-created'), request('admin-created')));
  await allowed('admin deletes request', () => deleteDoc(doc(admin, 'correction_requests/admin-created')));
  await allowed('admin review transaction', async () => {
    const batch = writeBatch(admin);
    batch.update(doc(admin, 'correction_requests/request-a'), { status: 'approved' });
    batch.update(doc(admin, 'students/a'), { name: 'Corrected', correctionRequestStatus: 'approved' });
    await batch.commit();
  });
  await allowed('admin student create', () => setDoc(doc(admin, 'students/new'), { collegeId: 'B' }));
  await allowed('admin student delete', () => deleteDoc(doc(admin, 'students/new')));
  await allowed('registration directory query', () => getDocs(collection(anon, 'colleges')));
  await denied('unknown collection', () => getDocs(collection(a, 'private')));
  console.log(`All ${passed} security checks passed.`);
} finally {
  await Promise.all(apps.map(deleteApp));
}
