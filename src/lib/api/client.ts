import type { PublicJourneyShare, ServiceStatus } from "../types/api";

function trimTrailingSlash(value: string): string {
  return value.endsWith("/") ? value.slice(0, -1) : value;
}

export class ApiClient {
  readonly baseURL: string;

  constructor(baseURL: string) {
    this.baseURL = trimTrailingSlash(baseURL || "http://localhost:8080");
  }

  private buildURL(path: string): string {
    return `${this.baseURL}${path.startsWith("/") ? path : `/${path}`}`;
  }

  private async request<T>(path: string, init?: RequestInit): Promise<T> {
    const response = await fetch(this.buildURL(path), {
      credentials: "include",
      ...init,
      headers: {
        Accept: "application/json",
        ...(init?.headers || {})
      }
    });

    if (!response.ok) {
      const body = await response.text();
      throw new Error(body || `HTTP ${response.status}`);
    }

    return (await response.json()) as T;
  }

  async getServiceStatus(): Promise<ServiceStatus> {
    return this.request<ServiceStatus>("/v1/status");
  }

  async getJourneyShare(shareID: string): Promise<PublicJourneyShare> {
    return this.request<PublicJourneyShare>(`/v1/journey-shares/${encodeURIComponent(shareID)}`);
  }
}
