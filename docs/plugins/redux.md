# Redux plugin

Shows the **live state of your Redux store** while the app runs in iOS Simulator. Every top-level slice (`auth`, `user`, `settings`, …) is a row in the table and updates as soon as an action changes it.

> Looking for the state saved to disk? That's the **Redux Persist** plugin: it needs no setup.

## Setup

### 1. Expose the store in development

Add one line where you create the store:

```ts
// store.ts
import { configureStore } from "@reduxjs/toolkit";

export const store = configureStore({ reducer: rootReducer });

if (__DEV__) {
  // Lets Storage Explorer find the store. Dev builds only.
  globalThis.__STORAGE_EXPLORER_STORE__ = store;
}
```

In TypeScript, declare the global once, e.g. in `global.d.ts`:

```ts
declare global {
  var __STORAGE_EXPLORER_STORE__: unknown;
}

export {};
```

The line works with Redux Toolkit and plain Redux (`createStore`). It runs only in development, so release builds are not affected.

### 2. Turn on the plugin

Open **Settings → Plugins** in Storage Explorer and enable **Redux**.

## How it works

1. Storage Explorer asks Metro which apps are connected (`http://localhost:8081/json/list`) and picks the app selected in the panel.
2. It connects to the app's Hermes runtime over the Chrome DevTools Protocol, the same channel React Native DevTools uses. The Zustand plugin shares this connection.
3. It subscribes to the store and counts changes. The state is read again only when the store actually changed, so large stores don't slow the app down.
4. After a JS reload (⌘R, Fast Refresh) the connection is restored automatically.

Nothing is installed in your app, and nothing is sent anywhere outside your Mac.

## Troubleshooting

| Message | What to do |
| --- | --- |
| *Metro isn't running on localhost:8081* | Start Metro: `npx react-native start` or `npx expo start`. |
| *… isn't connected to Metro* | Make sure it's a debug build using Hermes (Expo Go or a development build) and that it's running in Simulator. |
| *No Redux store found* | Check that the setup line above runs before the app renders, then reload JS (⌘R). |
| *The app didn't respond* | The app may be paused at a breakpoint. Resume it. |
| *The connection to the app was closed* / data stops updating | Another debugger may be attached. See the conflict note below. |

> **Debuggers.** Storage Explorer uses the same debugging channel as React Native DevTools, the Chrome debugger and Redux DevTools setups that connect through it. Recent React Native versions (and Expo Go) let several debuggers stay connected at once. On older versions only one may stay connected, so opening one can disconnect the other: if the Redux section stops updating, close the other debugger, or turn the Redux plugin off while you use it.

## Limitations

- Read-only for now: dispatching actions and an action log are planned.
- On older React Native versions, may conflict with React Native DevTools, the Chrome debugger or Redux DevTools attached through it.
- Metro is expected on port `8081`; a different port can be set in **Settings → Plugins → Metro Port**.
- The app appears in the app picker only if it also has AsyncStorage or MMKV data.
