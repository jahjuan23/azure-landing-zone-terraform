# ADR 04 — Compute: App Service over Container Apps and AKS

**Status:** Accepted · **AZ-305 domain:** Infrastructure solutions

## Context

The Corp landing zone needs a platform for a single web application. It must integrate with the spoke network, authenticate with the platform managed identity, and send logs to the central workspace.

## Decision

**Linux App Service** (B1 plan) with regional VNet integration for outbound traffic and a private endpoint for inbound traffic.

## Options considered

| | App Service (chosen) | Container Apps | AKS |
|---|---|---|---|
| Model | Managed PaaS | Serverless containers | Managed Kubernetes |
| Operations | Lowest | Low | Highest: upgrades, node pools, CNI |
| Scale | Manual / autoscale rules | Event-driven, scale to zero | HPA, cluster autoscaler |
| Idle cost | Plan runs continuously | Near zero with scale to zero | Node pool runs continuously |
| Best fit | One web app or API | Microservices, bursty or event-driven | Complex orchestration, portability |

## Rationale

- **Least complexity that meets requirements.** One web app does not justify owning a Kubernetes cluster.
- **B1 is the cheapest tier with the needed networking.** Free and Shared tiers support neither VNet integration nor private endpoints; the module rejects them with a validation rule.
- **Container Apps was the runner-up.** Scale to zero makes it cheaper at idle; it becomes the better choice if the workload turns event-driven or bursty.

## Consequences

- B1 has no deployment slots and no zone redundancy. Production would use Premium v3 with at least three instances across availability zones.
- Revisit triggers: event-driven or bursty load → Container Apps; many services needing orchestration or service mesh → AKS.

## Exam note

Default to the least operationally complex compute that meets the stated requirements. Choosing AKS for a single web app is usually the wrong answer.
