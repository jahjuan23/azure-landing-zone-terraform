# ADR 01 — Governance: policy at management-group scope, built-in definitions

**Status:** Accepted · **AZ-305 domain:** Identity, governance and monitoring

## Context

Guardrails (approved regions, mandatory tags, security baselines) can be assigned at four scopes: management group, subscription, resource group, or resource. Definitions can be Microsoft built-ins or custom.

## Decision

Assign **built-in** policy definitions at the **Landing Zones management group**. Place the lab subscription under **Corp**, a child of Landing Zones, so it inherits them.

## Options considered

| Scope | Pros | Cons |
|---|---|---|
| **Management group (chosen)** | Every current and future subscription beneath inherits it; set once | Wide blast radius if wrong |
| Subscription | Narrower blast radius | Must be re-applied to every new subscription; drift between subscriptions |
| Resource group | Very targeted | Unmanageable at scale; easy to bypass by creating a new RG |

## Rationale

- **Inheritance is the point.** A requirement that is true for all workloads belongs at the highest scope where it is universally true. Here that is Landing Zones: platform resources may legitimately need other regions (for example global services), so the guardrail is not at the tenant root.
- **Built-in over custom.** Allowed locations and required tags have Microsoft-maintained built-ins with stable GUIDs. Custom definitions add maintenance with no benefit here.
- **Two location policies, not one.** *Allowed locations* does not evaluate resource groups; *Allowed locations for resource groups* is a separate built-in. Assigning only the first leaves a gap.
- **Deny vs Audit.** Region and tag rules are Deny (cheap to comply with, expensive to clean up later). The storage HTTPS rule is Audit to show the difference: it reports without blocking.

## Consequences

- A lab with one subscription has platform and workload resources side by side under Corp. In an enterprise design, Management, Connectivity and Identity would each be their own subscription under Platform, and each workload its own subscription under Corp or Online. The hierarchy is already shaped for that.
- Policy assignments take up to about 30 minutes to be enforced after creation, and compliance results appear after the next evaluation cycle (`az policy state trigger-scan` forces one).
- A new Deny policy should start as Audit (or `enforce = false`), be reviewed in the compliance view, then be promoted.

## Exam note

"At which scope should you assign this policy?" — pick the highest scope at which the requirement applies to everything beneath it.
