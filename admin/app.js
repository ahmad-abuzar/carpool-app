/* ═══════════════════════════════════════════════════
   EzRide Admin Panel — JavaScript Logic
   ═══════════════════════════════════════════════════ */

// ─── Firebase Config ──────────────────────────────
const firebaseConfig = {
    apiKey: 'AIzaSyA_CfJf6E2KZ13cbs2VJCxpaBwy2fTG4lc',
    authDomain: 'carpool-app-5abb3.firebaseapp.com',
    projectId: 'carpool-app-5abb3',
    storageBucket: 'carpool-app-5abb3.firebasestorage.app',
    messagingSenderId: '821231678050',
    appId: '1:821231678050:android:3ed22ac41da79f72fad73b',
};

firebase.initializeApp(firebaseConfig);
const db = firebase.firestore();

// ─── State ────────────────────────────────────────
let currentPage = 'dashboard';
let allUsers = [];
let allCommissions = [];
let userFilter = 'all';
let commissionTab = 'all';

// ─── Admin Credentials ───────────────────────────
const ADMIN_EMAIL = 'admin@ezride.com';
const ADMIN_PASSWORD = 'admin123';

// ─── Login ────────────────────────────────────────
function handleLogin(e) {
    e.preventDefault();
    const email = document.getElementById('login-email').value.trim();
    const password = document.getElementById('login-password').value;
    const errorEl = document.getElementById('login-error');

    if (email === ADMIN_EMAIL && password === ADMIN_PASSWORD) {
        errorEl.style.display = 'none';
        document.getElementById('login-screen').style.display = 'none';
        document.getElementById('app').style.display = 'flex';
        loadDashboard();
        loadUsers();
        loadCommissions();
    } else {
        errorEl.textContent = 'Invalid email or password';
        errorEl.style.display = 'block';
    }
}

function handleLogout() {
    document.getElementById('app').style.display = 'none';
    document.getElementById('login-screen').style.display = 'flex';
    document.getElementById('login-email').value = '';
    document.getElementById('login-password').value = '';
}

// ─── Navigation ───────────────────────────────────
function navigateTo(page) {
    currentPage = page;
    document.querySelectorAll('.page').forEach(p => p.classList.remove('active'));
    document.getElementById('page-' + page).classList.add('active');
    document.querySelectorAll('.nav-item').forEach(n => n.classList.remove('active'));
    document.querySelector(`[data-page="${page}"]`).classList.add('active');

    const titles = {
        dashboard: 'Dashboard',
        users: 'Users',
        commissions: 'Commissions',
        locked: 'Locked Profiles'
    };
    document.getElementById('page-title').textContent = titles[page] || page;

    // Load data for page
    if (page === 'dashboard') loadDashboard();
    if (page === 'users') loadUsers();
    if (page === 'commissions') loadCommissions();
    if (page === 'locked') loadLockedUsers();
}

function refreshCurrentPage() {
    navigateTo(currentPage);
    showToast('Data refreshed', 'success');
}

function toggleSidebar() {
    document.querySelector('.sidebar').classList.toggle('open');
}

// ─── Dashboard ────────────────────────────────────
async function loadDashboard() {
    try {
        // Load users
        const usersSnap = await db.collection('users').get();
        const users = usersSnap.docs.map(d => ({ id: d.id, ...d.data() }));

        const totalUsers = users.length;
        const activeRiders = users.filter(u => u.role === 'driver' || u.totalRidesAsDriver > 0).length;
        const lockedProfiles = users.filter(u => u.isProfileLocked === true).length;

        document.getElementById('stat-total-users').textContent = totalUsers;
        document.getElementById('stat-active-riders').textContent = activeRiders;
        document.getElementById('stat-locked-profiles').textContent = lockedProfiles;

        // Update locked badge
        const lockedBadge = document.getElementById('locked-count-badge');
        if (lockedProfiles > 0) {
            lockedBadge.textContent = lockedProfiles;
            lockedBadge.style.display = 'inline';
        } else {
            lockedBadge.style.display = 'none';
        }

        // Load commissions
        const commissionsSnap = await db.collection('commissions').get();
        const commissions = commissionsSnap.docs.map(d => ({ id: d.id, ...d.data() }));

        const totalPending = commissions
            .filter(c => c.status === 'pending')
            .reduce((sum, c) => sum + (c.commissionAmount || 0), 0);

        const totalCollected = commissions
            .filter(c => c.status === 'paid')
            .reduce((sum, c) => sum + (c.commissionAmount || 0), 0);

        const totalCommission = totalPending + totalCollected;

        document.getElementById('stat-total-commission').textContent = `Rs ${totalCollected.toLocaleString()}`;
        document.getElementById('overview-pending').textContent = `Rs ${totalPending.toLocaleString()}`;
        document.getElementById('overview-collected').textContent = `Rs ${totalCollected.toLocaleString()}`;

        // Progress bars
        if (totalCommission > 0) {
            document.getElementById('bar-pending').style.width = `${(totalPending / totalCommission) * 100}%`;
            document.getElementById('bar-collected').style.width = `${(totalCollected / totalCommission) * 100}%`;
        }

        // Recent commissions table
        const recent = commissions
            .sort((a, b) => toDate(b.createdAt) - toDate(a.createdAt))
            .slice(0, 8);

        renderRecentCommissions(recent);

    } catch (err) {
        console.error('Dashboard error:', err);
        showToast('Failed to load dashboard', 'error');
    }
}

function renderRecentCommissions(commissions) {
    const container = document.getElementById('recent-commissions');
    if (commissions.length === 0) {
        container.innerHTML = `
      <div class="empty-state">
        <span class="material-icons-round">receipt_long</span>
        <p>No commission records yet</p>
      </div>`;
        return;
    }

    container.innerHTML = `
    <table>
      <thead>
        <tr>
          <th>User</th>
          <th>Ride Earnings</th>
          <th>Commission</th>
          <th>Status</th>
          <th>Date</th>
        </tr>
      </thead>
      <tbody>
        ${commissions.map(c => `
          <tr>
            <td style="color: var(--text-primary); font-weight: 500;">${truncateId(c.userId)}</td>
            <td>Rs ${(c.rideEarnings || 0).toLocaleString()}</td>
            <td style="font-weight: 600; color: var(--text-primary);">Rs ${(c.commissionAmount || 0).toLocaleString()}</td>
            <td><span class="badge ${c.status === 'paid' ? 'badge-success' : 'badge-warning'}">${c.status || 'pending'}</span></td>
            <td>${formatDate(c.createdAt)}</td>
          </tr>
        `).join('')}
      </tbody>
    </table>`;
}

// ─── Users ────────────────────────────────────────
async function loadUsers() {
    try {
        const snap = await db.collection('users').get();
        allUsers = snap.docs.map(d => ({ id: d.id, ...d.data() }));
        renderUsers();
    } catch (err) {
        console.error('Users error:', err);
        showToast('Failed to load users', 'error');
    }
}

function renderUsers() {
    let filtered = [...allUsers];
    const searchTerm = (document.getElementById('user-search')?.value || '').toLowerCase();

    // Apply filter
    if (userFilter === 'locked') filtered = filtered.filter(u => u.isProfileLocked === true);
    if (userFilter === 'driver') filtered = filtered.filter(u => u.role === 'driver');
    if (userFilter === 'passenger') filtered = filtered.filter(u => u.role === 'passenger');

    // Apply search
    if (searchTerm) {
        filtered = filtered.filter(u =>
            (u.name || '').toLowerCase().includes(searchTerm) ||
            (u.email || '').toLowerCase().includes(searchTerm) ||
            (u.phone || '').toLowerCase().includes(searchTerm)
        );
    }

    const container = document.getElementById('users-list');
    if (filtered.length === 0) {
        container.innerHTML = `
      <div class="empty-state" style="grid-column: 1/-1;">
        <span class="material-icons-round">people</span>
        <p>No users found</p>
      </div>`;
        return;
    }

    container.innerHTML = filtered.map(u => {
        const initial = (u.name || '?')[0].toUpperCase();
        const bgColor = u.isProfileLocked ? 'var(--danger)' : avatarColor(u.name || '');
        const lockedClass = u.isProfileLocked ? 'locked' : '';
        const commissionOwed = u.totalCommissionOwed || 0;

        return `
      <div class="user-card ${lockedClass}" onclick="openUserDetail('${u.id}')">
        <div class="user-card-header">
          <div class="user-avatar" style="background: ${bgColor};">${initial}</div>
          <div>
            <div class="user-card-name">${u.name || 'Unknown'}</div>
            <div class="user-card-email">${u.email || u.phone || 'No contact'}</div>
          </div>
        </div>
        <div class="user-card-meta">
          <span class="badge badge-accent">${(u.role || 'passenger').toUpperCase()}</span>
          ${u.isProfileLocked ? '<span class="badge badge-danger">🔒 LOCKED</span>' : ''}
          ${commissionOwed > 0 ? `<span class="badge badge-warning">Rs ${commissionOwed.toLocaleString()} owed</span>` : ''}
        </div>
        <div class="user-card-footer">
          <span class="user-card-stat">Rides: <strong>${u.totalRidesAsDriver || 0}</strong></span>
          <span class="user-card-stat">Since payment: <strong>${u.completedRidesSinceLastPayment || 0}/4</strong></span>
        </div>
      </div>`;
    }).join('');
}

function filterUsers() { renderUsers(); }

function setUserFilter(filter, el) {
    userFilter = filter;
    document.querySelectorAll('.filter-chips .chip').forEach(c => c.classList.remove('active'));
    el.classList.add('active');
    renderUsers();
}

// ─── Commissions ──────────────────────────────────
async function loadCommissions() {
    try {
        const snap = await db.collection('commissions').get();
        allCommissions = snap.docs.map(d => ({ id: d.id, ...d.data() }));
        renderCommissions();
    } catch (err) {
        console.error('Commissions error:', err);
        showToast('Failed to load commissions', 'error');
    }
}

function renderCommissions() {
    let filtered = [...allCommissions];

    if (commissionTab === 'pending') filtered = filtered.filter(c => c.status === 'pending');
    if (commissionTab === 'paid') filtered = filtered.filter(c => c.status === 'paid');

    // Update summary
    const totalPending = allCommissions
        .filter(c => c.status === 'pending')
        .reduce((s, c) => s + (c.commissionAmount || 0), 0);
    const totalCollected = allCommissions
        .filter(c => c.status === 'paid')
        .reduce((s, c) => s + (c.commissionAmount || 0), 0);

    document.getElementById('comm-total-pending').textContent = `Rs ${totalPending.toLocaleString()}`;
    document.getElementById('comm-total-collected').textContent = `Rs ${totalCollected.toLocaleString()}`;
    document.getElementById('comm-total-records').textContent = filtered.length;

    const container = document.getElementById('commissions-list');
    if (filtered.length === 0) {
        container.innerHTML = `
      <div class="empty-state">
        <span class="material-icons-round">receipt_long</span>
        <p>No commission records found</p>
      </div>`;
        return;
    }

    // Sort by date
    filtered.sort((a, b) => toDate(b.createdAt) - toDate(a.createdAt));

    container.innerHTML = `
    <table>
      <thead>
        <tr>
          <th>User ID</th>
          <th>Ride ID</th>
          <th>Ride Earnings</th>
          <th>Commission (5%)</th>
          <th>Status</th>
          <th>Date</th>
        </tr>
      </thead>
      <tbody>
        ${filtered.map(c => `
          <tr>
            <td style="font-weight: 500; color: var(--text-primary);">${truncateId(c.userId)}</td>
            <td>${truncateId(c.rideId)}</td>
            <td>Rs ${(c.rideEarnings || 0).toLocaleString()}</td>
            <td style="font-weight: 600; color: var(--text-primary);">Rs ${(c.commissionAmount || 0).toLocaleString()}</td>
            <td><span class="badge ${c.status === 'paid' ? 'badge-success' : 'badge-warning'}">${c.status || 'pending'}</span></td>
            <td>${formatDate(c.createdAt)}</td>
          </tr>
        `).join('')}
      </tbody>
    </table>`;
}

function setCommissionTab(tab, el) {
    commissionTab = tab;
    document.querySelectorAll('.commission-tabs .tab').forEach(t => t.classList.remove('active'));
    el.classList.add('active');
    renderCommissions();
}

// ─── Locked Profiles ──────────────────────────────
async function loadLockedUsers() {
    try {
        const snap = await db.collection('users').where('isProfileLocked', '==', true).get();
        const lockedUsers = snap.docs.map(d => ({ id: d.id, ...d.data() }));

        const container = document.getElementById('locked-list');
        if (lockedUsers.length === 0) {
            container.innerHTML = `
        <div class="empty-state" style="grid-column: 1/-1;">
          <span class="material-icons-round">check_circle</span>
          <p>No locked profiles — all clear!</p>
        </div>`;
            return;
        }

        container.innerHTML = lockedUsers.map(u => {
            const initial = (u.name || '?')[0].toUpperCase();
            return `
        <div class="user-card locked" onclick="openUserDetail('${u.id}')">
          <div class="user-card-header">
            <div class="user-avatar" style="background: var(--danger);">${initial}</div>
            <div>
              <div class="user-card-name">${u.name || 'Unknown'}</div>
              <div class="user-card-email">${u.email || u.phone || 'No contact'}</div>
            </div>
          </div>
          <div class="user-card-meta">
            <span class="badge badge-danger">🔒 LOCKED</span>
            <span class="badge badge-warning">Rs ${(u.totalCommissionOwed || 0).toLocaleString()} owed</span>
          </div>
          <div class="user-card-footer">
            <span class="user-card-stat">Rides since payment: <strong>${u.completedRidesSinceLastPayment || 0}</strong></span>
            <button class="btn-success" onclick="event.stopPropagation(); unlockAndPay('${u.id}', ${u.totalCommissionOwed || 0})">
              <span class="material-icons-round" style="font-size:16px;">lock_open</span> Unlock & Pay
            </button>
          </div>
        </div>`;
        }).join('');
    } catch (err) {
        console.error('Locked users error:', err);
        showToast('Failed to load locked users', 'error');
    }
}

// ─── User Detail Modal ────────────────────────────
async function openUserDetail(userId) {
    const modal = document.getElementById('user-modal');
    modal.style.display = 'flex';
    document.getElementById('modal-body').innerHTML = '<div class="loading-spinner"><div class="spinner"></div></div>';

    try {
        // Load user
        const userDoc = await db.collection('users').doc(userId).get();
        if (!userDoc.exists) {
            document.getElementById('modal-body').innerHTML = '<p>User not found</p>';
            return;
        }
        const user = { id: userDoc.id, ...userDoc.data() };
        document.getElementById('modal-user-name').textContent = user.name || 'User Detail';

        // Load commissions
        const commSnap = await db.collection('commissions').where('userId', '==', userId).get();
        const commissions = commSnap.docs.map(d => ({ id: d.id, ...d.data() }));

        const totalEarnings = commissions.reduce((s, c) => s + (c.rideEarnings || 0), 0);
        const totalOwed = user.totalCommissionOwed || 0;
        const totalPaid = user.totalCommissionPaid || 0;
        const ridesSince = user.completedRidesSinceLastPayment || 0;
        const isLocked = user.isProfileLocked === true;

        const initial = (user.name || '?')[0].toUpperCase();
        const bgColor = isLocked ? 'var(--danger)' : avatarColor(user.name || '');

        document.getElementById('modal-body').innerHTML = `
      <div class="modal-profile">
        <div class="modal-avatar" style="background: ${bgColor};">${initial}</div>
        <div class="modal-user-info">
          <h3>${user.name || 'Unknown'}</h3>
          <p>${user.email || ''} · ${user.phone || ''}</p>
          <div class="modal-badges">
            <span class="badge badge-accent">${(user.role || 'passenger').toUpperCase()}</span>
            ${isLocked ? '<span class="badge badge-danger">🔒 LOCKED</span>' : '<span class="badge badge-success">ACTIVE</span>'}
          </div>
        </div>
      </div>

      <div class="detail-grid">
        <div class="detail-item">
          <div class="detail-label">Total Earnings</div>
          <div class="detail-value success">Rs ${totalEarnings.toLocaleString()}</div>
        </div>
        <div class="detail-item">
          <div class="detail-label">Commission Owed</div>
          <div class="detail-value ${totalOwed > 0 ? 'warning' : ''}">Rs ${totalOwed.toLocaleString()}</div>
        </div>
        <div class="detail-item">
          <div class="detail-label">Commission Paid</div>
          <div class="detail-value accent">Rs ${totalPaid.toLocaleString()}</div>
        </div>
        <div class="detail-item">
          <div class="detail-label">Rides Since Last Payment</div>
          <div class="detail-value ${ridesSince >= 4 ? 'danger' : ''}">${ridesSince} / 4</div>
        </div>
      </div>

      <div class="modal-actions">
        ${isLocked
                ? `<button class="btn-success" onclick="unlockProfile('${userId}')">
              <span class="material-icons-round" style="font-size:16px;">lock_open</span> Unlock Profile
            </button>`
                : `<button class="btn-danger" onclick="lockProfile('${userId}')">
              <span class="material-icons-round" style="font-size:16px;">lock</span> Lock Profile
            </button>`
            }
        ${totalOwed > 0
                ? `<button class="btn-warning" onclick="markCommissionPaid('${userId}', ${totalOwed})">
              <span class="material-icons-round" style="font-size:16px;">check_circle</span> Mark Rs ${totalOwed.toLocaleString()} Paid
            </button>`
                : ''
            }
      </div>

      <div class="modal-section-title">Commission History (${commissions.length})</div>
      ${commissions.length === 0
                ? '<div class="empty-state"><span class="material-icons-round">receipt_long</span><p>No records</p></div>'
                : commissions
                    .sort((a, b) => toDate(b.createdAt) - toDate(a.createdAt))
                    .map(c => `
              <div class="commission-entry">
                <div class="commission-entry-left">
                  <span class="commission-entry-earning">Ride: Rs ${(c.rideEarnings || 0).toLocaleString()}</span>
                  <span class="commission-entry-amount">Commission: Rs ${(c.commissionAmount || 0).toLocaleString()}</span>
                </div>
                <div class="commission-entry-right">
                  <span class="badge ${c.status === 'paid' ? 'badge-success' : 'badge-warning'}">${c.status || 'pending'}</span>
                  <span class="commission-entry-date">${formatDate(c.createdAt)}</span>
                </div>
              </div>
            `).join('')
            }
    `;
    } catch (err) {
        console.error('User detail error:', err);
        document.getElementById('modal-body').innerHTML = `<p style="color:var(--danger);">Error loading user: ${err.message}</p>`;
    }
}

function closeUserModal() {
    document.getElementById('user-modal').style.display = 'none';
}

// ─── Admin Actions ────────────────────────────────
async function lockProfile(userId) {
    if (!confirm('Are you sure you want to lock this profile?')) return;
    try {
        await db.collection('users').doc(userId).update({ isProfileLocked: true });
        showToast('🔒 Profile locked', 'success');
        openUserDetail(userId);
        refreshData();
    } catch (err) {
        showToast('Failed to lock profile: ' + err.message, 'error');
    }
}

async function unlockProfile(userId) {
    try {
        await db.collection('users').doc(userId).update({ isProfileLocked: false });
        showToast('✅ Profile unlocked', 'success');
        openUserDetail(userId);
        refreshData();
    } catch (err) {
        showToast('Failed to unlock profile: ' + err.message, 'error');
    }
}

async function markCommissionPaid(userId, amount) {
    if (!confirm(`Mark Rs ${amount.toLocaleString()} commission as paid?\n\nThis will unlock the profile and reset the ride counter.`)) return;

    try {
        // Mark all pending commissions as paid
        const pendingSnap = await db.collection('commissions')
            .where('userId', '==', userId)
            .where('status', '==', 'pending')
            .get();

        const batch = db.batch();
        pendingSnap.docs.forEach(doc => {
            batch.update(doc.ref, {
                status: 'paid',
                paidAt: firebase.firestore.FieldValue.serverTimestamp()
            });
        });

        // Update user
        const userRef = db.collection('users').doc(userId);
        batch.update(userRef, {
            isProfileLocked: false,
            completedRidesSinceLastPayment: 0,
            totalCommissionOwed: 0,
            totalCommissionPaid: firebase.firestore.FieldValue.increment(amount)
        });

        await batch.commit();

        showToast(`✅ Rs ${amount.toLocaleString()} commission marked as paid`, 'success');
        openUserDetail(userId);
        refreshData();
    } catch (err) {
        showToast('Failed to mark as paid: ' + err.message, 'error');
    }
}

async function unlockAndPay(userId, amount) {
    if (amount > 0) {
        await markCommissionPaid(userId, amount);
    } else {
        await unlockProfile(userId);
    }
}

function refreshData() {
    loadUsers();
    loadCommissions();
    // Update locked badge
    db.collection('users').where('isProfileLocked', '==', true).get().then(snap => {
        const count = snap.size;
        const badge = document.getElementById('locked-count-badge');
        if (count > 0) {
            badge.textContent = count;
            badge.style.display = 'inline';
        } else {
            badge.style.display = 'none';
        }
    });
}

// ─── Helpers ──────────────────────────────────────
function toDate(ts) {
    if (!ts) return new Date(0);
    if (ts.toDate) return ts.toDate();
    if (ts.seconds) return new Date(ts.seconds * 1000);
    return new Date(ts);
}

function formatDate(ts) {
    const d = toDate(ts);
    if (d.getTime() === 0) return 'N/A';
    const day = d.getDate().toString().padStart(2, '0');
    const month = (d.getMonth() + 1).toString().padStart(2, '0');
    const year = d.getFullYear();
    const hours = d.getHours().toString().padStart(2, '0');
    const minutes = d.getMinutes().toString().padStart(2, '0');
    return `${day}/${month}/${year} ${hours}:${minutes}`;
}

function truncateId(id) {
    if (!id) return 'N/A';
    return id.length > 10 ? id.substring(0, 8) + '...' : id;
}

function avatarColor(name) {
    const colors = [
        'linear-gradient(135deg, #6C63FF, #4338CA)',
        'linear-gradient(135deg, #00C9A7, #00A88A)',
        'linear-gradient(135deg, #F0A500, #D49200)',
        'linear-gradient(135deg, #FF6B6B, #D94343)',
        'linear-gradient(135deg, #4ECDC4, #36B5AC)',
        'linear-gradient(135deg, #A855F7, #7C3AED)',
        'linear-gradient(135deg, #F472B6, #DB2777)',
        'linear-gradient(135deg, #60A5FA, #3B82F6)',
    ];
    let hash = 0;
    for (let i = 0; i < name.length; i++) hash = name.charCodeAt(i) + ((hash << 5) - hash);
    return colors[Math.abs(hash) % colors.length];
}

function showToast(message, type = '') {
    const toast = document.getElementById('toast');
    toast.textContent = message;
    toast.className = 'toast' + (type ? ` ${type}` : '');
    toast.style.display = 'block';
    setTimeout(() => { toast.style.display = 'none'; }, 3000);
}

// ─── Keyboard shortcut: Escape to close modal ────
document.addEventListener('keydown', (e) => {
    if (e.key === 'Escape') closeUserModal();
});
