function resetEmailConfigured() {
  return Boolean(process.env.RESEND_API_KEY && process.env.PASSWORD_RESET_FROM);
}

async function sendPasswordReset(email, code) {
  const response = await fetch('https://api.resend.com/emails', {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${process.env.RESEND_API_KEY}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      from: process.env.PASSWORD_RESET_FROM,
      to: [email],
      subject: 'Reset your ExploreLanka password',
      text: `Enter this code on the ExploreLanka password reset screen:\n\n${code}\n\nThe code expires in 15 minutes. If you did not request it, ignore this email.`,
    }),
    signal: AbortSignal.timeout(10_000),
  });
  if (!response.ok) throw new Error('Email delivery failed.');
}

module.exports = { resetEmailConfigured, sendPasswordReset };
