export interface ServiceStatusComponent {
  key: string;
  label: string;
  status: "operational" | "delayed" | "degraded" | string;
  lastSeenAt?: string;
}

export interface ServiceStatus {
  status: "operational" | "delayed" | "degraded" | string;
  checkedAt: string;
  components: ServiceStatusComponent[];
  message: string;
  latestKafkaMessageAt?: string;
  kafkaMessageLagSeconds?: number;
  kafkaMessagesProcessedLast24h: number;
}

export interface JourneySharePosition {
  description: string;
  progress: number;
  currentStopName?: string;
  upcomingStopName?: string;
}

export interface JourneyShareLeg {
  legIndex: number;
  originName: string;
  originCrs: string;
  destinationName: string;
  destinationCrs: string;
  status: string;
  statusText: string;
  scheduledDeparture: string;
  scheduledArrival: string;
  expectedDeparture?: string;
  expectedArrival?: string;
}

export interface PublicJourneyShare {
  shareId: string;
  kind: "direct" | "itinerary" | string;
  routeTitle: string;
  status: string;
  statusText: string;
  originName: string;
  originCrs: string;
  destinationName: string;
  destinationCrs: string;
  scheduledDeparture: string;
  scheduledArrival: string;
  expectedDeparture?: string;
  expectedArrival?: string;
  currentPosition?: JourneySharePosition;
  legs?: JourneyShareLeg[];
  disruptions?: string[];
  refreshedAt: string;
  expiresAt: string;
  appUrl: string;
  appStoreUrl?: string;
}
