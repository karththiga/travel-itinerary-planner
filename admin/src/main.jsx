import React, { useEffect, useState } from 'react';
import { createRoot } from 'react-dom/client';
import { request } from './api';
import { AttractionForm, BookingForm } from './Forms';
import './styles.css';

const bookingStatuses = ['pending', 'confirmed', 'completed', 'cancelled'];

function Brand() {
  return <div className="brand"><span aria-hidden="true">EL</span><div>ExploreLanka<small>Platform admin</small></div></div>;
}

function Login({ onSignIn, notice }) {
  const [error, setError] = useState('');
  const [busy, setBusy] = useState(false);

  async function submit(event) {
    event.preventDefault();
    setBusy(true);
    setError('');
    const body = Object.fromEntries(new FormData(event.currentTarget));
    let token;
    try {
      ({ token } = await request('/auth/login', { method: 'POST', body }));
      const { user } = await request('/admin/session', { token });
      onSignIn({ token, user });
    } catch (failure) {
      if (token) request('/auth/logout', { token, method: 'POST' }).catch(() => {});
      setError(failure.message);
    } finally {
      setBusy(false);
    }
  }

  return (
    <main className="login">
      <section className="login-card">
        <Brand />
        <h1>Admin sign in</h1>
        {notice && <p role="status">{notice}</p>}
        <form onSubmit={submit}>
          <fieldset disabled={busy}>
            <label>Email<input name="email" type="email" autoComplete="username" required /></label>
            <label>Password<input name="password" type="password" autoComplete="current-password" required /></label>
            {error && <p className="error" role="alert">{error}</p>}
            <button className="primary">{busy ? 'Signing in…' : 'Sign in'}</button>
          </fieldset>
        </form>
      </section>
    </main>
  );
}

function AttractionTable({ rows, onEdit, onVisibility, busy }) {
  return (
    <table>
      <thead><tr><th>Attraction</th><th>Category</th><th>District</th><th>Visibility</th><th>Actions</th></tr></thead>
      <tbody>{rows.map((place) => (
        <tr key={place._id}>
          <td><strong>{place.name}</strong><small>{place.location}</small></td>
          <td>{place.category}</td><td>{place.district}</td>
          <td><span className={`badge ${place.archived ? 'archived' : 'active'}`}>{place.archived ? 'Archived' : 'Active'}</span></td>
          <td><div className="actions">
            <button disabled={busy} onClick={() => onEdit(place)}>Edit</button>
            <button disabled={busy} onClick={() => onVisibility(place)}>{place.archived ? 'Restore' : 'Archive'}</button>
          </div></td>
        </tr>
      ))}</tbody>
    </table>
  );
}

function BookingTable({ rows, onStatus, busy }) {
  return (
    <table>
      <thead><tr><th>Guest</th><th>Attraction</th><th>Visit date</th><th>Party size</th><th>Status</th></tr></thead>
      <tbody>{rows.map((booking) => (
        <tr key={booking._id}>
          <td><strong>{booking.guestName}</strong><small>{booking.guestEmail}</small></td>
          <td>{booking.attractionName}</td>
          <td><time dateTime={booking.visitDate}>{booking.visitDate}</time></td>
          <td>{booking.partySize}</td>
          <td><select className={`booking-status ${booking.status}`} value={booking.status} disabled={busy}
            aria-label={`Status for ${booking.guestName}, ${booking.attractionName}, ${booking.visitDate}`}
            onChange={(event) => onStatus(booking, event.target.value)}>
            {bookingStatuses.map((status) => <option key={status} value={status}>{status}</option>)}
          </select></td>
        </tr>
      ))}</tbody>
    </table>
  );
}

function Dashboard({ session, onEnd }) {
  const [section, setSection] = useState('attractions');
  const [records, setRecords] = useState(null);
  const [search, setSearch] = useState('');
  const [filter, setFilter] = useState('all');
  const [editor, setEditor] = useState(null);
  const [loadError, setLoadError] = useState('');
  const [error, setError] = useState('');
  const [notice, setNotice] = useState('');
  const [busy, setBusy] = useState(false);
  const [revision, setRevision] = useState(0);
  const isCatalog = section === 'attractions';
  const isLoaded = records?.section === section;
  const attractions = records?.attractions ?? [];
  const source = isLoaded ? records[section] : [];
  const filters = isCatalog ? ['active', 'archived'] : bookingStatuses;
  const rows = source.filter((row) => {
    const status = isCatalog ? (row.archived ? 'archived' : 'active') : row.status;
    const fields = isCatalog
      ? [row.name, row.location, row.district, row.category, ...(row.aliases ?? [])]
      : [row.guestName, row.guestEmail, row.attractionName, row.visitDate];
    return (filter === 'all' || filter === status) &&
      fields.some((value) => value?.toLowerCase().includes(search.trim().toLowerCase()));
  });

  useEffect(() => {
    const controller = new AbortController();
    const options = { token: session.token, signal: controller.signal };
    Promise.all([
      request('/admin/attractions', options),
      section === 'bookings' ? request('/admin/bookings', options) : {},
    ]).then(([catalog, bookings]) => {
      if (!controller.signal.aborted) setRecords({ section, ...catalog, ...bookings });
    }).catch((failure) => {
      if (controller.signal.aborted) return;
      if ([401, 403].includes(failure.status)) onEnd(failure.message);
      else setLoadError(failure.message);
    });
    return () => controller.abort();
  }, [session, section, revision, onEnd]);

  function navigate(next) {
    if (next === section) return;
    setSection(next);
    setRecords(null);
    setEditor(null);
    setSearch('');
    setFilter('all');
    setError('');
    setLoadError('');
    setNotice('');
  }

  async function mutate(path, method, body, message) {
    setBusy(true);
    setError('');
    setNotice('');
    try {
      const result = await request(path, { method, body, token: session.token });
      const saved = result[isCatalog ? 'attraction' : 'booking'];
      setRecords((current) => {
        const items = current[section];
        const updated = items.some((item) => item._id === saved._id)
          ? items.map((item) => item._id === saved._id ? saved : item)
          : [...items, saved];
        updated.sort(isCatalog
          ? (a, b) => a.name.localeCompare(b.name)
          : (a, b) => b.visitDate.localeCompare(a.visitDate) || b._id.localeCompare(a._id));
        return { ...current, [section]: updated };
      });
      setEditor(null);
      setNotice(message);
    } catch (failure) {
      if ([401, 403].includes(failure.status)) onEnd(failure.message);
      else setError(failure.message);
    } finally {
      setBusy(false);
    }
  }

  async function logout() {
    setBusy(true);
    setError('');
    try {
      await request('/auth/logout', { method: 'POST', token: session.token });
      onEnd('');
    } catch (failure) {
      setError(failure.message);
    } finally {
      setBusy(false);
    }
  }

  const title = isCatalog ? 'Attractions' : 'Bookings';
  return (
    <div className="layout">
      <aside>
        <Brand />
        <nav aria-label="Administration">
          <button disabled={busy} aria-current={isCatalog ? 'page' : undefined} onClick={() => navigate('attractions')}>Attractions</button>
          <button disabled={busy} aria-current={!isCatalog ? 'page' : undefined} onClick={() => navigate('bookings')}>Bookings</button>
        </nav>
        <div className="account"><small>{session.user.email}</small><button disabled={busy} onClick={logout}>Sign out</button></div>
      </aside>
      <main className="workspace">
        <header className="heading">
          <h1>{title}</h1>
          <button className="primary" disabled={!isLoaded || busy || Boolean(editor)}
            onClick={() => { setEditor({}); setError(''); setNotice(''); }}>
            {isCatalog ? 'Add attraction' : 'New booking'}
          </button>
        </header>
        {notice && <p className="notice" role="status">{notice}</p>}
        {!editor && error && <p className="error" role="alert">{error}</p>}
        {editor && (
          <section className="panel editor">
            <header className="heading"><h2>{isCatalog ? (editor._id ? 'Edit attraction' : 'Add attraction') : 'New booking'}</h2>
              <button disabled={busy} onClick={() => { setEditor(null); setError(''); }}>Cancel</button>
            </header>
            {isCatalog
              ? <AttractionForm record={editor} busy={busy} error={error} onSubmit={(fields) => mutate(
                editor._id ? `/admin/attractions/${editor._id}` : '/admin/attractions',
                editor._id ? 'PUT' : 'POST', fields, 'Attraction saved.',
              )} />
              : <BookingForm attractions={attractions} busy={busy} error={error}
                onSubmit={(fields) => mutate('/admin/bookings', 'POST', fields, 'Booking created.')} />}
          </section>
        )}
        <section className="panel" aria-label={title}>
          <div className="toolbar">
            <label>Search {title.toLowerCase()}<input type="search" value={search} onChange={(event) => setSearch(event.target.value)} /></label>
            <label>{isCatalog ? 'Visibility' : 'Status'}
              <select value={filter} onChange={(event) => setFilter(event.target.value)}>
                <option value="all">All</option>
                {filters.map((value) => <option key={value} value={value}>{value}</option>)}
              </select>
            </label>
            {isLoaded && <p>{rows.length} of {source.length} {title.toLowerCase()}</p>}
          </div>
          {loadError ? <div className="empty"><p role="alert" className="error">{loadError}</p>
            <button onClick={() => { setLoadError(''); setRevision((value) => value + 1); }}>Retry</button></div>
            : !isLoaded ? <p className="empty" role="status">Loading {title.toLowerCase()}…</p>
              : !rows.length ? <p className="empty">{source.length ? 'No matching records.' : `No ${title.toLowerCase()} yet.`}</p>
                : <div className="table-scroll">{isCatalog
                  ? <AttractionTable rows={rows} busy={busy || Boolean(editor)}
                    onEdit={(place) => { setEditor(place); setError(''); setNotice(''); }}
                    onVisibility={(place) => mutate(`/admin/attractions/${place._id}/visibility`, 'PATCH',
                      { archived: !place.archived }, place.archived ? 'Attraction restored.' : 'Attraction archived.')} />
                  : <BookingTable rows={rows} busy={busy || Boolean(editor)}
                    onStatus={(booking, status) => mutate(`/admin/bookings/${booking._id}/status`, 'PATCH',
                      { status }, 'Booking status updated.')} />}
                </div>}
        </section>
      </main>
    </div>
  );
}

function App() {
  const [session, setSession] = useState(null);
  const [notice, setNotice] = useState('');
  const endSession = React.useCallback((message) => {
    setSession(null);
    setNotice(message);
  }, []);
  return session ? <Dashboard session={session} onEnd={endSession} /> : <Login notice={notice} onSignIn={setSession} />;
}

createRoot(document.getElementById('root')).render(<App />);
