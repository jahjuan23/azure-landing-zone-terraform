# ADR 03 — Identity: managed identities, report-only-first Conditional Access, PIM

**Status:** Accepted (managed identity deployed; CA and PIM designed, gated on licensing) · **AZ-305 domain:** Identity, governance and monitoring

## Context

Workloads need to authenticate to Azure services, and administrators need privileged access. Conditional Access (Entra ID P1) and Privileged Identity Management (Entra ID P2) are not ARM resources, so the `azurerm` provider cannot manage them, and a personal subscription usually has neither licence.

## Decision

1. **Workloads** use a **user-assigned managed identity**. No client secrets or connection strings are stored anywhere.
2. **Conditional Access** policies are written as `azuread` Terraform (template in `modules/identity/main.tf`) and deployed in **report-only** mode first.
3. **Privileged roles** are **eligible** through PIM, never permanently assigned.

## Options considered for workload identity

| | User-assigned MI (chosen) | System-assigned MI | Service principal + secret |
|---|---|---|---|
| Lifecycle | Independent of the app | Deleted with the app | Manual |
| Reuse | Shareable across resources | One resource only | Shareable |
| Secret to rotate | None | None | Yes |
| Pre-grant roles before app exists | Yes | No | Yes |

User-assigned was chosen because roles can be granted before the app exists and the identity survives redeployments.

## Target Conditional Access set

| Policy | Target | Control |
|---|---|---|
| CA001 | Admin roles | Require MFA |
| CA002 | All users | Require MFA |
| CA003 | All users | Block legacy authentication |
| CA004 | Microsoft Azure Management app | Require MFA |

Every policy excludes two break-glass accounts and starts in report-only; it is enforced only after reviewing sign-in logs for impact.

## PIM design

- No standing Owner or User Access Administrator assignments.
- Eligible assignments, activated for up to 8 hours, requiring MFA and a justification; Owner activation requires approval.
- Quarterly access reviews on eligible assignments.

## Exam note

"Minimise standing privilege" → PIM eligible assignments. "Authenticate an app to Azure without storing credentials" → managed identity.
