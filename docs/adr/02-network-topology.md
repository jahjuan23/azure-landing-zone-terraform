# ADR 02 — Network topology: hub-spoke over Virtual WAN

**Status:** Accepted · **AZ-305 domain:** Infrastructure solutions

## Context

The landing zone needs to centralise shared network services (firewall, DNS, hybrid connectivity) while isolating workloads. Azure offers two reference topologies: customer-managed **hub-spoke** with VNet peering, and Microsoft-managed **Virtual WAN**.

## Decision

Customer-managed **hub-spoke** with VNet peering. Private DNS zones live in the hub and are linked to every VNet.

## Options considered

| | Hub-spoke (chosen) | Virtual WAN |
|---|---|---|
| Control | Full control of routing, NVAs, UDRs | Managed hub, less granular routing |
| Cost floor | Pay only for what you deploy | Standard hub has an hourly base charge |
| Transit | Spoke-to-spoke needs a firewall/NVA + UDRs | Built-in any-to-any transit |
| Best fit | One or two regions, cost-sensitive | Many regions and branches, SD-WAN, global transit |

## Rationale

- **Cost.** The whole topology (VNets, peering, DNS zone) costs almost nothing idle. The firewall is written but commented out so it can be demonstrated on demand.
- **It shows the mechanics.** Hub-spoke forces explicit decisions about peering flags (`allow_forwarded_traffic`, `allow_gateway_transit`, `use_remote_gateways`), subnet reservation (`AzureFirewallSubnet`, `GatewaySubnet`), and DNS, which Virtual WAN hides.
- **Address plan.** The hub and spoke each get a /22 split into /24s, leaving room for growth without re-addressing. Reserved subnets exist from day one.

## Consequences

- VNet peering is non-transitive: two spokes cannot talk through the hub until a firewall is deployed and route tables send traffic to it.
- `allow_gateway_transit` / `use_remote_gateways` stay off until a VPN or ExpressRoute gateway exists; enabling `use_remote_gateways` without a gateway fails.
- Revisit this decision if the design grows beyond two regions or needs many branch connections: that is where Virtual WAN earns its base cost.
