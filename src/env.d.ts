/// <reference types="vite/client" />

declare global {
  interface Window {
    __RIGHTTRAIN_CONFIG__?: {
      apiBaseUrl?: string;
      publicWebBaseUrl?: string;
      appStoreUrl?: string;
    };
  }
}

export {};
