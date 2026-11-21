import React from 'react';

const attractionFields = [
  ['name', 'Name', 160], ['category', 'Category', 160],
  ['location', 'Location', 160], ['district', 'District', 160],
  ['latitude', 'Latitude', -90, 90], ['longitude', 'Longitude', -180, 180],
  ['openingTime', 'Opening time', 80], ['closingTime', 'Closing time', 80],
  ['estimatedVisitDuration', 'Visit duration (minutes)', 0],
  ['entryFee', 'Entry fee (LKR)', 0], ['popularityScore', 'Popularity score', 0],
];

export function AttractionForm({ record, onSubmit, busy, error }) {
  function submit(event) {
    event.preventDefault();
    const values = new FormData(event.currentTarget);
    const fields = {};
    for (const [key, , limit] of attractionFields) {
      const value = values.get(key).trim();
      fields[key] = value === '' ? null : limit <= 0 ? Number(value) : value;
    }
    fields.description = values.get('description').trim() || null;
    fields.environment = values.get('environment') || null;
    fields.aliases = values.get('aliases').split(',').map((value) => value.trim()).filter(Boolean);
    const admission = values.get('freeAdmission');
    fields.freeAdmission = admission === '' ? null : admission === 'true';
    onSubmit(fields);
  }

  return (
    <form onSubmit={submit}>
      <fieldset disabled={busy}>
        <div className="fields">
          {attractionFields.map(([key, label, limit, max], index) => (
            <label key={key}>{label}
              <input name={key} defaultValue={record?.[key] ?? ''} required={index < 6}
                type={limit <= 0 ? 'number' : 'text'} maxLength={limit > 0 ? limit : undefined}
                min={limit <= 0 ? limit : undefined} max={max} step="any" />
            </label>
          ))}
          <label>Environment
            <select name="environment" defaultValue={record?.environment ?? ''}>
              <option value="">Unspecified</option>
              {['Indoor', 'Outdoor', 'Both'].map((value) => <option key={value}>{value}</option>)}
            </select>
          </label>
          <label>Free admission
            <select name="freeAdmission" defaultValue={record?.freeAdmission?.toString() ?? ''}>
              <option value="">Unspecified</option><option value="true">Confirmed free</option>
              <option value="false">Not free</option>
            </select>
          </label>
          <label>Aliases, separated by commas
            <input name="aliases" defaultValue={record?.aliases?.join(', ') ?? ''} />
          </label>
          <label className="wide">Description
            <textarea name="description" rows="3" maxLength={4000} defaultValue={record?.description ?? ''} />
          </label>
        </div>
        {error && <p role="alert" className="error">{error}</p>}
        <button className="primary">{busy ? 'Saving…' : 'Save attraction'}</button>
      </fieldset>
    </form>
  );
}

export function BookingForm({ attractions, onSubmit, busy, error }) {
  const active = attractions.filter((attraction) => !attraction.archived);
  function submit(event) {
    event.preventDefault();
    const fields = Object.fromEntries(new FormData(event.currentTarget));
    onSubmit({ ...fields, partySize: Number(fields.partySize) });
  }

  return (
    <form onSubmit={submit}>
      <fieldset disabled={busy || !active.length}>
        <div className="fields">
          <label>Guest name<input name="guestName" required maxLength={120} /></label>
          <label>Guest email<input name="guestEmail" type="email" required maxLength={254} /></label>
          <label>Attraction
            <select name="attraction" defaultValue="" required>
              <option value="" disabled>Select an attraction</option>
              {active.map((place) => <option key={place._id} value={place._id}>{place.name} · {place.district}</option>)}
            </select>
          </label>
          <label>Visit date<input name="visitDate" type="date" required /></label>
          <label>Party size<input name="partySize" type="number" min="1" max="1000" defaultValue="1" required /></label>
        </div>
        {error && <p role="alert" className="error">{error}</p>}
        <button className="primary">{busy ? 'Saving…' : 'Create booking'}</button>
      </fieldset>
      {!active.length && <p role="status">Add or restore an attraction before creating a booking.</p>}
    </form>
  );
}
