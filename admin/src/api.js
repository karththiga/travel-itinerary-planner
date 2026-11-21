const base = (import.meta.env.VITE_API_BASE_URL || '/api').replace(/\/$/, '');

export async function request(path, { token, method = 'GET', body, signal } = {}) {
  const response = await fetch(base + path, {
    method,
    signal,
    headers: {
      ...(token && { Authorization: `Bearer ${token}` }),
      ...(body !== undefined && { 'Content-Type': 'application/json' }),
    },
    body: body === undefined ? undefined : JSON.stringify(body),
  });
  if (response.status === 204) return;
  const data = await response.json().catch(() => null);
  if (!response.ok || !data) {
    const error = new Error(data?.message || 'The API is unavailable. Please try again.');
    error.status = response.status;
    throw error;
  }
  return data;
}
