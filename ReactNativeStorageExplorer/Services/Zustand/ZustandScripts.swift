//
//  ZustandScripts.swift
//  ReactNativeStorageExplorer
//
//  Created by Emin Zeynalov on 20.11.26.
//

import Foundation

nonisolated enum ZustandScripts {
    static let install = """
    (function () {
      var g = globalThis;
      var registry = g.__STORAGE_EXPLORER_ZUSTAND__;
      function isStore(s) {
        return !!s && typeof s.getState === 'function' && typeof s.subscribe === 'function';
      }
      var old = g.__SE_ZUSTAND__;
      if (old) old.unsubscribers.forEach(function (unsubscribe) { unsubscribe(); });
      g.__SE_ZUSTAND__ = null;
      if (!registry || typeof registry !== 'object') return 'not-found';
      var names = Object.keys(registry).filter(function (name) { return isStore(registry[name]); });
      if (!names.length) return 'not-found';
      var bridge = {
        session: Math.random().toString(36).slice(2),
        version: 1,
        registry: registry,
        names: names,
        unsubscribers: []
      };
      names.forEach(function (name) {
        bridge.unsubscribers.push(registry[name].subscribe(function () { bridge.version++; }));
      });
      g.__SE_ZUSTAND__ = bridge;
      return 'ok';
    })()
    """

    static let version = """
    (function () {
      var g = globalThis;
      var bridge = g.__SE_ZUSTAND__;
      var registry = g.__STORAGE_EXPLORER_ZUSTAND__;
      if (!bridge || bridge.registry !== registry || !registry) return null;
      if (Object.keys(registry).join('|') !== bridge.names.join('|')) return null;
      return bridge.session + ':' + bridge.version;
    })()
    """

    static let state = """
    (function () {
      var bridge = globalThis.__SE_ZUSTAND__;
      if (!bridge) return null;
      function stringify(value) {
        var ancestors = [];
        var json = JSON.stringify(value, function (key, v) {
          if (typeof v === 'function') return undefined;
          if (typeof v === 'bigint') return v.toString();
          if (v instanceof Map) v = Object.fromEntries(v);
          else if (v instanceof Set) v = Array.from(v);
          if (v && typeof v === 'object') {
            var index = ancestors.indexOf(this);
            ancestors.length = index + 1;
            if (ancestors.indexOf(v) !== -1) return '[Circular]';
            ancestors.push(v);
          }
          return v;
        });
        return json === undefined ? 'undefined' : json;
      }
      return JSON.stringify(bridge.names.map(function (name) {
        return [name, stringify(bridge.registry[name].getState())];
      }));
    })()
    """
}
