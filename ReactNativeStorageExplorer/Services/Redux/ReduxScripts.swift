//
//  ReduxScripts.swift
//  ReactNativeStorageExplorer
//
//  Created by Emin Zeynalov on 31.03.26.
//

import Foundation

nonisolated enum ReduxScripts {
    static let install = """
    (function () {
      var g = globalThis;
      if (g.__SE_REDUX__ && g.__SE_REDUX__.store) return 'ok';
      function isStore(s) {
        return !!s && typeof s.getState === 'function' && typeof s.subscribe === 'function'
          && typeof s.dispatch === 'function';
      }
      var store = isStore(g.__STORAGE_EXPLORER_STORE__) ? g.__STORAGE_EXPLORER_STORE__ : null;
      var hook = g.__REACT_DEVTOOLS_GLOBAL_HOOK__;
      if (!store && hook && hook.renderers && typeof hook.getFiberRoots === 'function') {
        hook.renderers.forEach(function (_, rendererID) {
          if (store) return;
          hook.getFiberRoots(rendererID).forEach(function (root) {
            var stack = [root.current];
            var visited = 0;
            while (!store && stack.length && visited < 50000) {
              var fiber = stack.pop();
              visited++;
              var props = fiber.memoizedProps;
              if (props) {
                if (isStore(props.store)) store = props.store;
                else if (props.value && isStore(props.value.store)) store = props.value.store;
              }
              if (fiber.sibling) stack.push(fiber.sibling);
              if (fiber.child) stack.push(fiber.child);
            }
          });
        });
      }
      if (!store) return 'not-found';
      var bridge = { store: store, version: 1 };
      store.subscribe(function () { bridge.version++; });
      g.__SE_REDUX__ = bridge;
      return 'ok';
    })()
    """

    static let version = """
    (function () {
      var bridge = globalThis.__SE_REDUX__;
      return bridge && bridge.store ? String(bridge.version) : null;
    })()
    """

    static let state = """
    (function () {
      var bridge = globalThis.__SE_REDUX__;
      if (!bridge) return null;
      function stringify(value) {
        var seen = new WeakSet();
        var json = JSON.stringify(value, function (key, v) {
          if (typeof v === 'function') return '[Function]';
          if (typeof v === 'bigint') return v.toString();
          if (v && typeof v === 'object') {
            if (seen.has(v)) return '[Circular]';
            seen.add(v);
          }
          return v;
        });
        return json === undefined ? 'undefined' : json;
      }
      function isQueryApi(v) {
        return !!v && typeof v === 'object' && 'queries' in v && 'mutations' in v && 'config' in v;
      }
      var state = bridge.store.getState();
      if (state === null || typeof state !== 'object' || Array.isArray(state)) {
        return JSON.stringify([['state', stringify(state), 'slice']]);
      }
      return JSON.stringify(Object.keys(state).map(function (key) {
        return [key, stringify(state[key]), isQueryApi(state[key]) ? 'api' : 'slice'];
      }));
    })()
    """
}
