# Remember-Me-AI: AI Meta Server + PWA + Web Push

This guide captures a complete starter structure for a "soulful AI chat" app with:

- Node.js/Express backend
- React frontend
- PWA install support
- Web Push notifications (VAPID)

> Tailored for the Remember-Me-AK concept: https://github.com/merchantmoh-debug/Remember-Me-AK

## Project file tree

```text
Remember-Me-AI/
│
├── backend/
│   ├── server.js
│   └── package.json
│
├── frontend/
│   ├── public/
│   │   ├── manifest.json
│   │   ├── service-worker.js
│   │   └── icons/
│   │        ├── icon-192x192.png
│   │        └── icon-512x512.png
│   ├── src/
│   │   ├── App.js
│   │   ├── index.js
│   │   └── push.js
│   └── package.json
│
└── README.md
```

## 1) `backend/server.js`

```js
const express = require('express');
const bodyParser = require('body-parser');
const webpush = require('web-push');

const vapidKeys = {
  publicKey: 'YOUR_VAPID_PUBLIC_KEY',
  privateKey: 'YOUR_VAPID_PRIVATE_KEY',
};

webpush.setVapidDetails(
  'mailto:youremail@example.com',
  vapidKeys.publicKey,
  vapidKeys.privateKey
);

const subscriptions = [];

const app = express();
app.use(bodyParser.json());

// User subscribes for push
app.post('/api/subscribe', (req, res) => {
  subscriptions.push(req.body);
  res.status(201).json({});
});

// Send notification with AI guidance
app.post('/api/notify', async (req, res) => {
  const { title, body, url } = req.body;
  const payload = JSON.stringify({ title, body, url });

  for (const sub of subscriptions) {
    try {
      await webpush.sendNotification(sub, payload);
    } catch (err) {
      console.error(err);
    }
  }

  res.status(201).json({});
});

// Basic AI chat endpoint (simulate response)
app.post('/api/chat', async (req, res) => {
  const { message } = req.body;
  const responseText = message
    ? 'Your soulful AI guidance.'
    : 'Please share what is on your mind.';

  // Optionally send push
  const payload = JSON.stringify({
    title: 'AI Guidance',
    body: responseText,
    url: '/',
  });

  for (const sub of subscriptions) {
    try {
      await webpush.sendNotification(sub, payload);
    } catch (err) {
      console.error(err);
    }
  }

  res.json({ response: responseText });
});

app.listen(9000, () => {
  console.log('Backend running on http://localhost:9000');
});
```

## 2) `frontend/public/manifest.json`

```json
{
  "short_name": "RememberMeAI",
  "name": "Remember-Me-AI Purpose Chat",
  "icons": [
    { "src": "icons/icon-192x192.png", "sizes": "192x192", "type": "image/png" },
    { "src": "icons/icon-512x512.png", "sizes": "512x512", "type": "image/png" }
  ],
  "start_url": ".",
  "display": "standalone",
  "background_color": "#faf5e4",
  "theme_color": "#ffe066",
  "description": "Soulful AI guidance for humanity"
}
```

## 3) `frontend/public/service-worker.js`

```js
self.addEventListener('push', event => {
  const data = event.data.json();
  self.registration.showNotification(data.title, {
    body: data.body,
    icon: '/icons/icon-192x192.png',
    data: data.url,
  });
});

self.addEventListener('notificationclick', event => {
  event.notification.close();
  clients.openWindow(event.notification.data);
});
```

## 4) `frontend/src/push.js`

```js
export async function subscribeUser(vapidPublicKey) {
  if ('serviceWorker' in navigator && 'PushManager' in window) {
    const registration = await navigator.serviceWorker.ready;
    const subscription = await registration.pushManager.subscribe({
      userVisibleOnly: true,
      applicationServerKey: urlBase64ToUint8Array(vapidPublicKey),
    });

    await fetch('/api/subscribe', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(subscription),
    });

    return subscription;
  }

  return null;
}

function urlBase64ToUint8Array(base64String) {
  const padding = '='.repeat((4 - (base64String.length % 4)) % 4);
  const base64 = (base64String + padding)
    .replace(/-/g, '+')
    .replace(/_/g, '/');

  const rawData = window.atob(base64);
  return Uint8Array.from([...rawData].map(char => char.charCodeAt(0)));
}
```

## 5) `frontend/src/App.js`

```js
import React, { useEffect } from 'react';
import { subscribeUser } from './push';

function App() {
  const VAPID_PUBLIC_KEY = 'YOUR_VAPID_PUBLIC_KEY';

  useEffect(() => {
    subscribeUser(VAPID_PUBLIC_KEY);
  }, []);

  return (
    <div>
      <h1>Remember-Me-AI Chat</h1>
      <p>Soulful, purpose-driven AI guidance at your fingertips.</p>
      {/* Add chat UI, message sending (calls /api/chat), etc. here */}
    </div>
  );
}

export default App;
```

## 6) `frontend/src/index.js`

```js
import React from 'react';
import ReactDOM from 'react-dom';
import App from './App';

if ('serviceWorker' in navigator) {
  window.addEventListener('load', () => {
    navigator.serviceWorker.register('/service-worker.js');
  });
}

ReactDOM.render(<App />, document.getElementById('root'));
```

## 7) `frontend/public/icons/`

Add `icon-192x192.png` and `icon-512x512.png` in this folder.

## 8) README template

```md
# Remember-Me-AI

Purpose-driven, soulful AI chat as a PWA, with Web Push notifications.

## How to run

### Backend
1. `cd backend`
2. `npm install`
3. Set your VAPID public/private keys in `server.js`
4. `node server.js`

### Frontend
1. `cd frontend`
2. `npm install`
3. `npm run build`
4. Serve frontend (for example: `npx serve -s build`, Netlify, or Vercel)

## Features
- Installable PWA
- Web Push notifications with VAPID keys
- Soulful chat and real-time guidance
```

## Deployment best practices

1. Host backend on Node.js hosting (Render, Railway, Fly.io, etc.).
2. Host frontend on a static host (Netlify, Vercel, Cloudflare Pages, etc.).
3. Use HTTPS in all environments.
4. Ask explicit consent before enabling notifications.
5. Prioritize accessibility (contrast, semantics, keyboard support).
6. Document AI behavior and limitations transparently.
7. Add feedback loops for continuous product improvement.
