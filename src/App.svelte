<script lang="ts">
  import { onDestroy, onMount } from "svelte";
  import { ApiClient } from "./lib/api/client";
  import type { PublicJourneyShare, ServiceStatus } from "./lib/types/api";

  type Route = { name: "status" } | { name: "share"; shareID: string } | { name: "not-found" };

  const runtimeConfig = typeof window !== "undefined" ? window.__RIGHTTRAIN_CONFIG__ : undefined;
  const api = new ApiClient(runtimeConfig?.apiBaseUrl || import.meta.env.VITE_API_BASE_URL || "http://localhost:8080");
  const appStoreUrl = runtimeConfig?.appStoreUrl || "";

  let route: Route = currentRoute();
  let status: ServiceStatus | null = null;
  let share: PublicJourneyShare | null = null;
  let loading = true;
  let error = "";
  let copied = false;
  let refreshTimer: ReturnType<typeof setInterval> | null = null;

  function currentRoute(): Route {
    if (typeof window === "undefined") {
      return { name: "status" };
    }
    const path = window.location.pathname.replace(/\/+$/, "") || "/";
    const shareMatch = path.match(/^\/j\/([^/]+)$/);
    if (shareMatch) {
      return { name: "share", shareID: decodeURIComponent(shareMatch[1]) };
    }
    if (path === "/" || path === "/status") {
      return { name: "status" };
    }
    return { name: "not-found" };
  }

  async function load() {
    loading = true;
    error = "";
    copied = false;
    try {
      if (route.name === "share") {
        share = await api.getJourneyShare(route.shareID);
      } else if (route.name === "status") {
        status = await api.getServiceStatus();
      }
    } catch (caught) {
      error = (caught as Error).message;
    } finally {
      loading = false;
    }
  }

  async function refreshStatus() {
    if (route.name !== "status") {
      return;
    }
    try {
      status = await api.getServiceStatus();
      error = "";
    } catch (caught) {
      error = (caught as Error).message;
    }
  }

  function routeChanged() {
    route = currentRoute();
    void load();
  }

  async function shareJourney() {
    if (!share) {
      return;
    }
    const url = shareUrl();
    if (navigator.share) {
      await navigator.share({
        title: `RightTrain: ${share.routeTitle}`,
        text: `${share.statusText} · ${share.routeTitle}`,
        url
      });
      return;
    }
    await copyShareLink();
  }

  async function copyShareLink() {
    const url = shareUrl();
    await navigator.clipboard?.writeText(url);
    copied = true;
    setTimeout(() => {
      copied = false;
    }, 2200);
  }

  function shareUrl() {
    return typeof window === "undefined" ? "" : window.location.href;
  }

  function serviceState(item?: ServiceStatus | null): "live" | "delayed" | "degraded" {
    if (!item) {
      return "delayed";
    }
    if (item.kafkaMessageLagSeconds != null) {
      if (item.kafkaMessageLagSeconds <= 120) {
        return "live";
      }
      if (item.kafkaMessageLagSeconds <= 900) {
        return "delayed";
      }
      return "degraded";
    }
    if (item.latestKafkaMessageAt) {
      return "live";
    }
    if (item.status === "operational") {
      return "live";
    }
    if (item.status === "delayed") {
      return "delayed";
    }
    return "degraded";
  }

  function statusStateLabel(item?: ServiceStatus | null): string {
    const state = serviceState(item);
    if (state === "live") {
      return "Live";
    }
    if (state === "delayed") {
      return "Delayed";
    }
    return "Degraded";
  }

  function statusHeadline(item?: ServiceStatus | null): string {
    const state = serviceState(item);
    if (state === "live") {
      return "RightTrain is live";
    }
    if (state === "delayed") {
      return "Rail updates are delayed";
    }
    return "RightTrain is degraded";
  }

  function statusSummary(item?: ServiceStatus | null): string {
    const state = serviceState(item);
    if (state === "live") {
      return "Live rail updates are flowing normally.";
    }
    if (state === "delayed") {
      return "Some rail updates are arriving later than expected.";
    }
    return "RightTrain is reachable, but some live rail data may be delayed or unavailable.";
  }

  function lagText(seconds?: number, latestMessageAt?: string): string {
    if (seconds == null || Number.isNaN(seconds)) {
      if (latestMessageAt) {
        return "Under 1m";
      }
      return "No live messages yet";
    }
    if (seconds < 60) {
      return `${Math.round(seconds)}s`;
    }
    if (seconds < 3600) {
      return `${Math.round(seconds / 60)}m`;
    }
    return `${Math.round(seconds / 3600)}h`;
  }

  function numberText(value?: number): string {
    return new Intl.NumberFormat("en-GB").format(value || 0);
  }

  function progressPercent(value?: number): string {
    return `${Math.max(0, Math.min(100, Math.round((value || 0) * 100)))}%`;
  }

  function formatRailDateTime(value?: string): string {
    if (!value) {
      return "TBC";
    }
    const date = new Date(value);
    if (Number.isNaN(date.getTime())) {
      return value;
    }
    return new Intl.DateTimeFormat("en-GB", {
      day: "2-digit",
      month: "short",
      hour: "2-digit",
      minute: "2-digit"
    }).format(date);
  }

  function primaryTimingLabel(item: PublicJourneyShare): string {
    const departure = item.expectedDeparture || item.scheduledDeparture;
    const arrival = item.expectedArrival || item.scheduledArrival;
    return `${formatRailDateTime(departure)} to ${formatRailDateTime(arrival)}`;
  }

  function installUrl(item: PublicJourneyShare | null): string {
    return item?.appStoreUrl || appStoreUrl;
  }

  onMount(() => {
    void load();
    window.addEventListener("popstate", routeChanged);
    refreshTimer = setInterval(() => void refreshStatus(), 60000);
  });

  onDestroy(() => {
    window.removeEventListener("popstate", routeChanged);
    if (refreshTimer) {
      clearInterval(refreshTimer);
    }
  });
</script>

<svelte:head>
  <title>{route.name === "share" && share ? `${share.routeTitle} · RightTrain` : "RightTrain Status"}</title>
  <meta name="description" content="RightTrain live rail status and shareable journey updates." />
</svelte:head>

<main class:share-surface={route.name === "share"} class:status-surface={route.name === "status"}>
  {#if route.name === "status"}
    <section class="status-shell public-status" aria-label="RightTrain service status">
      <header class="status-topbar">
        <div class="brand-row">
          <img src="/icons/righttrain-icon-60.png" alt="" />
          <span>RightTrain</span>
        </div>
        <span>status.righttrain.app</span>
      </header>

      {#if loading}
        <div class="loading-panel">Checking live rail data.</div>
      {:else if error}
        <div class="loading-panel danger">{error}</div>
      {:else if status}
        <section class="status-band {serviceState(status)}">
          <div>
            <span class="state-chip"><span aria-hidden="true"></span>{statusStateLabel(status)}</span>
            <h1>{statusHeadline(status)}</h1>
            <p>{statusSummary(status)}</p>
          </div>
          <button type="button" on:click={() => void refreshStatus()}>Refresh</button>
        </section>

        <section class="status-table" aria-label="Live ingest summary">
          <article>
            <span>Rail feed lag</span>
            <strong>{lagText(status.kafkaMessageLagSeconds, status.latestKafkaMessageAt)}</strong>
            <p>{status.latestKafkaMessageAt ? `Latest message ${formatRailDateTime(status.latestKafkaMessageAt)}` : "Waiting for the first live message."}</p>
          </article>
          {#if status.kafkaMessagesProcessedLast24h !== undefined}
            <article>
              <span>Processed in 24 hours</span>
              <strong>{numberText(status.kafkaMessagesProcessedLast24h)}</strong>
              <p>Darwin rail updates processed by RightTrain.</p>
            </article>
          {/if}
        </section>

        <footer class="status-meta">
          <span>Last checked</span>
          <strong>{formatRailDateTime(status.checkedAt)}</strong>
          <span>Current state</span>
          <strong>{statusStateLabel(status)}</strong>
        </footer>
      {/if}
    </section>
  {:else if route.name === "share"}
    <section class="journey-shell" aria-label="Shared RightTrain journey">
      {#if loading}
        <div class="loading-panel">Loading journey.</div>
      {:else if error}
        <div class="loading-panel danger">
          <strong>This journey link is not available.</strong>
          <span>{error}</span>
        </div>
      {:else if share}
        <header class="journey-hero">
          <div class="brand-row compact">
            <img src="/icons/righttrain-icon-60.png" alt="" />
            <span>RightTrain</span>
          </div>
          <p class="eyebrow">Shared journey</p>
          <h1>{share.routeTitle}</h1>
          <p>{share.statusText} · {primaryTimingLabel(share)}</p>
        </header>

        <section class="journey-summary">
          <div class="route-endpoint">
            <span>{share.originCrs}</span>
            <strong>{share.originName}</strong>
            <small>{formatRailDateTime(share.expectedDeparture || share.scheduledDeparture)}</small>
          </div>
          <div class="route-line" aria-hidden="true"><span></span></div>
          <div class="route-endpoint end">
            <span>{share.destinationCrs}</span>
            <strong>{share.destinationName}</strong>
            <small>{formatRailDateTime(share.expectedArrival || share.scheduledArrival)}</small>
          </div>
        </section>

        <section class="live-panel">
          <div>
            <span>Current rail position</span>
            <strong>{share.currentPosition?.description || "Train location is not reported yet"}</strong>
            {#if share.currentPosition?.upcomingStopName}
              <p>Next stop: {share.currentPosition.upcomingStopName}</p>
            {:else}
              <p>Updated from RightTrain rail data.</p>
            {/if}
          </div>
          <div class="progress" aria-label="Journey progress">
            <span style={`width: ${progressPercent(share.currentPosition?.progress)}`}></span>
          </div>
        </section>

        {#if share.disruptions?.length}
          <section class="disruptions" aria-label="Journey disruption notes">
            {#each share.disruptions as disruption}
              <p>{disruption}</p>
            {/each}
          </section>
        {/if}

        {#if share.legs?.length && share.legs.length > 1}
          <section class="legs" aria-label="Journey legs">
            <h2>Journey legs</h2>
            {#each share.legs as leg}
              <div>
                <span>{leg.originCrs} to {leg.destinationCrs}</span>
                <strong>{leg.originName} → {leg.destinationName}</strong>
                <small>{leg.statusText} · {formatRailDateTime(leg.expectedDeparture || leg.scheduledDeparture)}</small>
              </div>
            {/each}
          </section>
        {/if}

        <section class="cta-row" aria-label="Journey actions">
          <a class="primary" href={share.appUrl}>Open in RightTrain</a>
          {#if installUrl(share)}
            <a class="secondary" href={installUrl(share)}>Install RightTrain</a>
          {/if}
          <button type="button" class="secondary" on:click={shareJourney}>{copied ? "Copied" : "Share"}</button>
        </section>

        <footer class="status-foot">
          <span>Refreshed {formatRailDateTime(share.refreshedAt)}</span>
          <span>Link expires {formatRailDateTime(share.expiresAt)}</span>
        </footer>
      {/if}
    </section>
  {:else}
    <section class="status-shell">
      <div class="loading-panel danger">
        <strong>Page not found.</strong>
        <a href="/">View RightTrain status</a>
      </div>
    </section>
  {/if}
</main>
