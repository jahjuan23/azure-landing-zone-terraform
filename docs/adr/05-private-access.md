# ADR 05 — Inbound access: private endpoint over IP restrictions or service endpoints

**Status:** Accepted · **AZ-305 domain:** Infrastructure solutions

## Context

The Corp app should be reachable from inside the corporate network (hub and spokes) without being open to the internet.

A common mistake is to assume **regional VNet integration** makes an App Service private. It does not: VNet integration only controls where the app's **outbound** calls go. Inbound requests still arrive at the public endpoint. A related mistake is allow-listing the hub's private CIDR in access restrictions; traffic from a VNet to a public endpoint arrives from a public IP, so the rule never matches. (An early version of this repo made exactly that mistake.)

## Decision

- **Private endpoint** in the spoke's `snet-private-endpoints` subnet, registered in `privatelink.azurewebsites.net` (linked to hub and spoke).
- **Public endpoint disabled** unless the operator allow-lists specific public IPs (`allowed_public_ips`), in which case every other address gets 403.
- **NSG** on the private endpoint subnet allows only HTTPS from `VirtualNetwork`; `private_endpoint_network_policies = "Enabled"` makes Azure enforce it.

## Options considered

| | Private endpoint (chosen) | Service endpoint + access restriction | IP restrictions only |
|---|---|---|---|
| Traffic path | Private IP in your VNet | Microsoft backbone, public endpoint | Public internet |
| Reachable from on-prem via VPN/ER | Yes | No | Only via public IPs |
| Can disable public endpoint | Yes | No | No |
| DNS work | Private DNS zone required | None | None |
| Cost | ~$0.01/hour + data | Free | Free |

## Consequences

- DNS is now part of the design: any VNet (or on-prem resolver) that needs the app must resolve through the private DNS zone. Linking the zone in the hub centralises this.
- With `allowed_public_ips = []` the app is fully private. Testing it then needs a client inside the network (a VM or Cloud Shell with VNet integration).

## Exam note

"Only accessible from the virtual network / on-premises" → private endpoint. "Outbound calls from the app to resources in a VNet" → VNet integration.
