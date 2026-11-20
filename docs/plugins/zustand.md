# Zustand plugin

Shows the **live state of your Zustand stores** while the app runs in iOS Simulator. Every registered store (`auth`, `cart`, `settings`, …) is a row in the table and updates as soon as its state changes.

> Using the `persist` middleware? The saved state is also visible in the **AsyncStorage** or **MMKV** plugin, with no setup.

## Setup

### 1. Register your stores in development

Zustand stores have no global registry, so list the ones you want to see. The names you choose become the row names:

```ts
// stores/index.ts
import { useAuthStore } from "./auth";
import { useCartStore } from "./cart";

if (__DEV__) {
  // Lets Storage Explorer find the stores. Dev builds only.
  globalThis.__STORAGE_EXPLORER_ZUSTAND__ = {
    auth: useAuthStore,
    cart: useCartStore,
  };
}
```

Prefer registering each store in its own file? Merge into the same object:

```ts
// stores/auth.ts
export const useAuthStore = create<AuthState>()((set) => ({ … }));

if (__DEV__) {
  globalThis.__STORAGE_EXPLORER_ZUSTAND__ = {
    ...globalThis.__STORAGE_EXPLORER_ZUSTAND__,
    auth: useAuthStore,
  };
}
```

In TypeScript, declare the global once, e.g. in `global.d.ts`:

```ts
declare global {
  var __STORAGE_EXPLORER_ZUSTAND__: Record<string, unknown> | undefined;
}

export {};
```

Works with hooks from `create` and with vanilla stores from `createStore`, including stores with middleware (`persist`, `immer`, `devtools`, …). Stores registered later, e.g. in lazily loaded screens, are picked up automatically.

### 2. Turn on the plugin

Open **Settings → Plugins** in Storage Explorer and enable **Zustand**.

## What you see

- One row per store, in registration order.
- Actions (functions in the state) are left out, so only data is shown.
- `Map` and `Set` values are shown as objects and arrays.

## How it works

1. Storage Explorer asks Metro which apps are connected (`http://localhost:8081/json/list`) and picks the app selected in the panel.
2. It connects to the app's Hermes runtime over the Chrome DevTools Protocol, the same channel React Native DevTools uses. The Redux plugin shares this connection.
3. It subscribes to every registered store and counts changes. The state is read again only when a store actually changed.
4. After a JS reload (⌘R, Fast Refresh) the subscriptions are restored automatically.

Nothing is installed in your app, and nothing is sent anywhere outside your Mac.

## Troubleshooting

| Message | What to do |
| --- | --- |
| *Metro isn't running on localhost:8081* | Start Metro: `npx react-native start` or `npx expo start`. |
| *… isn't connected to Metro* | Make sure it's a debug build using Hermes (Expo Go or a development build) and that it's running in Simulator. |
| *No Zustand stores found* | Check that the setup code above runs (import the file that registers the stores), then reload JS (⌘R). |
| *The app didn't respond* | The app may be paused at a breakpoint. Resume it. |
| *The connection to the app was closed* / data stops updating | Another debugger may be attached. See the conflict note below. |

> **Debuggers.** Storage Explorer uses the same debugging channel as React Native DevTools. Recent React Native versions (and Expo Go) let several debuggers stay connected at once, so DevTools can stay open. On older versions only one may stay connected, so opening one can disconnect the other: if the Zustand section stops updating, close the other debugger, or turn the plugin off while you use it.

## Limitations

- Works with Expo Go, development builds and bare React Native apps running with Metro.
- Read-only for now: changing the state from Storage Explorer is planned.
- Only registered stores are shown.
- Metro is expected on port `8081`; a different port can be set in **Settings → Plugins → Metro Port**.
- The app appears in the app picker only if it also has AsyncStorage or MMKV data.
