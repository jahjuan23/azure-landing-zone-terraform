# Lab guide: deploy the landing zone from a Mac

Takes about 2–3 hours the first time, most of it one-time setup. Running cost is well under $1 per day while deployed. Everything is torn down at the end.

Commands go in **Terminal** (zsh). Lines starting with `#` are comments; don't paste those.

---

## Part 1 — Azure account (15 min)

1. Go to **azure.microsoft.com/free** and choose the free account. Sign in with a Microsoft account (or create one) and complete phone and card verification. The card is for identity; the free account does not charge you unless you choose to upgrade.
2. When the portal opens (portal.azure.com), you have one **subscription** and one **Entra ID tenant** ("Default Directory"). That is everything this lab needs.
3. Turn on MFA for your account if you haven't: **account.microsoft.com → Security**. You are about to become the administrator of a whole tenant.

## Part 2 — Tools (20 min)

Install Homebrew if `brew --version` doesn't work:

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
# On Apple Silicon, run the two "Next steps" lines it prints, then open a new Terminal window.
```

Install everything else:

```bash
brew install azure-cli git
brew tap hashicorp/tap
brew install hashicorp/tap/terraform
brew install --cask visual-studio-code
```

Check:

```bash
az version
terraform version   # 1.7 or newer
git --version
```

In VS Code, install the **HashiCorp Terraform** extension. Then press Cmd+Shift+P, run **Shell Command: Install 'code' command in PATH**.

## Part 3 — Sign in and collect your IDs (5 min)

```bash
az login
az account show --query "{subscription:id, tenant:tenantId, name:name}" -o table
```

Keep that window open; you'll paste the subscription and tenant IDs shortly. Save them into shell variables for the next steps:

```bash
SUB_ID=$(az account show --query id -o tsv)
TENANT_ID=$(az account show --query tenantId -o tsv)
echo $SUB_ID $TENANT_ID
```

## Part 4 — Management group permissions (10 min, one-time)

Management groups sit above subscriptions, so you need rights at the **tenant root**. Being the subscription owner is not enough.

1. **Activate management groups.** Portal → search **Management groups** → if you see **Start using management groups**, click it (creating and then deleting a test group is fine). Afterwards you should see **Tenant Root Group**.
2. **Elevate your access once.** Portal → **Microsoft Entra ID** → **Properties** → **Access management for Azure resources** → **Yes** → **Save**.
3. **Give yourself Owner on the tenant root group:**

   ```bash
   ME=$(az ad signed-in-user show --query id -o tsv)
   az role assignment create \
     --assignee-object-id "$ME" --assignee-principal-type User \
     --role Owner \
     --scope "/providers/Microsoft.Management/managementGroups/$TENANT_ID"
   ```

4. Optional but good practice: set the step 2 toggle back to **No**. The Owner assignment you just made is what Terraform needs.
5. Wait about 5 minutes for the role to propagate, then check:

   ```bash
   az account management-group list -o table
   ```

## Part 5 — Get the code and configure it (10 min)

```bash
mkdir -p ~/projects && cd ~/projects
unzip ~/Downloads/az-landing-zone.zip
cd az-landing-zone
code .
```

Create your variables file:

```bash
cd environments/prod
cp terraform.tfvars.example terraform.tfvars
curl -s https://ifconfig.me; echo    # your public IP
```

Open `terraform.tfvars` in VS Code and set:

| Setting | Value |
|---|---|
| `subscription_id` | `$SUB_ID` from Part 3 |
| `tenant_id` | `$TENANT_ID` from Part 3 |
| `org_prefix` | your initials, lowercase, e.g. `jj` |
| `allowed_public_ips` | `["<your IP>/32"]` |
| `budget_contact_email` | your email |
| `tags.owner` | your initials |

`terraform.tfvars` is gitignored, so these values never reach GitHub.

## Part 6 — Plan (10 min)

```bash
terraform init
terraform fmt -check -recursive ../..
terraform validate
terraform test          # offline plan against a mock provider: 3 passed
terraform plan -out tfplan
```

Read the plan before applying. You should see **43 resources to add**: 8 management groups, 1 subscription association, 6 policy assignments, 5 resource groups, 2 VNets, 5 subnets, 2 peerings, an NSG and its subnet association, a private DNS zone with 2 links, a Log Analytics workspace, a budget, a managed identity, an App Service plan and app, a private endpoint, and 3 diagnostic settings.

## Part 7 — Apply (10–15 min)

```bash
terraform apply tfplan
```

When it finishes, Terraform prints outputs including `app_url` and `app_private_ip`. Keep them.

## Part 8 — Prove it works (45 min)

This is the part that turns "I deployed a template" into "I can explain and verify a landing zone". Screenshot each result.

### 8.1 Governance: the hierarchy

```bash
az account management-group show --name jj-landingzones --expand --recurse -o jsonc
```

(Use your own prefix.) Portal → Management groups shows the tree with your subscription under **Corp**.

### 8.2 Governance: policy actually blocks things

Policy enforcement can take up to 30 minutes after assignment. If these succeed instead of failing, wait and retry (then delete what got created).

```bash
# Wrong region → denied by "Allowed locations for resource groups"
az group create -n rg-policy-test-region -l westus \
  --tags owner=jj costCenter=lab environment=test

# Missing tags → denied by "Require 'owner' tag on resource groups"
az group create -n rg-policy-test-tags -l eastus2
```

Both should fail with `RequestDisallowedByPolicy` and the custom message you wrote in `modules/policy/main.tf`. Then check compliance:

```bash
az policy state trigger-scan --no-wait
# after ~10 min:
az policy state summarize --management-group jj-landingzones -o table
```

### 8.3 Networking: peering and private DNS

```bash
az network vnet peering list -g rg-jj-prod-hub --vnet-name vnet-jj-prod-hub \
  --query "[].{name:name, state:peeringState}" -o table
# expect: Connected

az network private-dns record-set a list -g rg-jj-prod-hub \
  -z privatelink.azurewebsites.net --query "[].{name:name, ip:aRecords[0].ipv4Address}" -o table
# expect: your app name → 10.1.0.x (matches app_private_ip)
```

See how public DNS points into the private link zone:

```bash
APP=$(terraform output -raw app_url | sed 's#https://##')
nslookup $APP
# expect a CNAME chain through <app>.privatelink.azurewebsites.net
```

### 8.4 Workload: access control

```bash
curl -s -o /dev/null -w "%{http_code}\n" $(terraform output -raw app_url)
# from your allow-listed IP: 200
```

Then open **Cloud Shell** in the portal (it has a different public IP) and run the same curl: expect **403**. That's the deny-by-default access restriction working.

### 8.5 Monitoring: logs in the central workspace

Wait 10–15 minutes after hitting the app, then Portal → Log Analytics workspaces → `log-jj-prod-central` → **Logs**:

```kusto
AppServiceHTTPLogs
| where TimeGenerated > ago(1h)
| project TimeGenerated, CIp, CsMethod, CsUriStem, ScStatus
| order by TimeGenerated desc
```

You should see your requests with status 200. The blocked Cloud Shell attempt is recorded separately, by the access-restriction layer:

```kusto
AppServiceIPSecAuditLogs
| where TimeGenerated > ago(1h)
| project TimeGenerated, CIp, Result, Details
```

### 8.6 Cost

Portal → **Cost Management → Budgets** shows `budget-jj-prod`. Costs take up to a day to appear.

### Screenshots worth keeping

1. Management group tree with the subscription under Corp
2. The `RequestDisallowedByPolicy` error in Terminal
3. Policy compliance view
4. Peering showing Connected, and the private DNS A record
5. The KQL results: allowed requests, and the blocked one in the IPSec audit log
6. The resource groups list, all tagged

## Part 9 — Put it on GitHub (15 min)

```bash
cd ~/projects/az-landing-zone
git init -b main
git add .
git status        # confirm terraform.tfvars and *.tfstate are NOT listed
git commit -m "Azure landing zone in Terraform"
```

Create an empty public repo named `azure-landing-zone-terraform` on github.com (no README), then:

```bash
git remote add origin https://github.com/<your-username>/azure-landing-zone-terraform.git
git push -u origin main
```

The **Actions** tab will run fmt, validate, tflint and checkov. Add a `docs/images/` folder with your screenshots and link them from the README.

## Part 10 — Tear down (10 min)

```bash
cd ~/projects/az-landing-zone/environments/prod
terraform destroy
```

Check nothing is left:

```bash
az group list --query "[?starts_with(name, 'rg-jj')].name" -o table   # expect empty
az account management-group list -o table                            # only Tenant Root Group
```

Rebuilding later is just Part 6 and 7 again.

---

## Troubleshooting

| Error | Cause | Fix |
|---|---|---|
| `AuthorizationFailed` on `managementGroups/...` | Owner at root not assigned or not propagated | Redo Part 4 step 3, wait 5–10 min, run `az login` again |
| `RequestDisallowedByPolicy` during **your own** apply | `location` not in `allowed_locations`, or `tags` missing a required key | Fix `terraform.tfvars`; the `check` block warns about missing tags at plan time |
| App Service `quota` / `Operation cannot be completed without additional quota` | New subscriptions sometimes have zero App Service quota in a region | Change `location` to another allowed region (e.g. `centralus`), or request quota in the portal |
| Budget creation fails | Some offer types don't support budgets through the API | Set `enable_budget = false` and create one in the portal |
| `MissingSubscriptionRegistration` | Resource provider not registered yet on a new subscription | Wait and re-run apply; or `az provider register --namespace Microsoft.Web` (or the namespace named) |
| `terraform destroy` hangs on a management group | Subscription still moving back to root | Wait a minute and run `terraform destroy` again |
| Name conflict on the web app | App names are global | Change `org_prefix` |

## Level up (optional next labs)

- **Firewall and forced tunnelling:** uncomment Azure Firewall in `modules/networking/main.tf`, add a route table sending `0.0.0.0/0` from the spoke to it, prove egress goes through it, then destroy (it bills about $1.25/hour).
- **Remote state:** create a storage account for state, uncomment the backend block in `versions.tf`, run `terraform init -migrate-state`.
- **Second landing zone:** add an Online spoke with Front Door in front of a public app, and compare it to the private Corp app.
- **CI deploys:** add a GitHub Actions job that runs `terraform plan` using OpenID Connect federation to a managed identity (no secrets in GitHub).
