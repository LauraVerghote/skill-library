# Customer demo script

## Before the meeting

1. Confirm the deployed Skill Library URL opens through Microsoft Entra sign-in.
2. Confirm API Center shows three linked skill assets from `.github/skills`.
3. Confirm the Foundry project lists the same skills with immutable versions.
4. Confirm the `northstar-skills` toolbox is published and its MCP endpoint is connected to GitHub Copilot.
5. Assign yourself Skill Reader, Skill Author, and Skill Runner app roles.

## 12-minute walkthrough

### 1. Frame the solution (1 minute)

Say: "There is one source of truth in Git, but three purposeful surfaces. API Center is the governed catalog, Foundry is the agent execution and MCP distribution plane, and this small application gives business users a controlled editing and Synthetix API experience."

Show the architecture in the repository README.

### 2. Business authoring and lifecycle (3 minutes)

Open the Skill Library. Select **Customer response**, edit one instruction, and choose **Save draft**.

Say: "A draft remains visible to authorized authors but cannot be run. The author identity and timestamp are recorded."

Choose **Publish** and point out the incremented immutable version. Run:

```powershell
./scripts/Test-Local.ps1 -BaseUrl https://<skill-library-host>
```

Explain that the production implementation should turn publish into an approved pull request or durable workflow rather than container-local state.

### 3. Entra authorization (2 minutes)

Show `catalog.json`: read, write, and run each accept app-role values or Entra group object IDs. Show the 403 test in `Test-Local.ps1`.

Say: "API Center controls who can discover catalog entries. This API separately controls who can read, edit, or invoke each skill. Those controls solve different problems and should not be conflated."

### 4. API Center and Git (2 minutes)

Open **API-center-skills > Inventory > Assets** and filter to skills. Open one linked asset and show its Git source URL, lifecycle, assessment, and allowed tools.

Say: "API Center periodically synchronizes the repository. It is the searchable inventory and governance boundary, including which APIs and MCP servers a skill is allowed to use."

### 5. Foundry and Synthetix (2 minutes)

In Foundry, open **Build > Tools > Skills**. Show immutable versions and the default version. Then open **Browse skills**, choose registry `API-center-skills`, and show the catalog view.

Call `POST /api/skills/customer-response/run` from Synthetix or an API client. Point out the selected skill ID and version in the response envelope.

### 6. Coding tools (2 minutes)

Open the repository in GitHub Copilot and ask: "Use the secure-code-review skill to review this change." Then show the `northstar-skills` MCP toolbox connection.

Say: "Repository skills follow the team automatically through Git. The Foundry toolbox gives MCP-compatible clients a centrally published option. Genie Code support must be validated against its current MCP Resources and Agent Skills support; the repository remains usable even where that integration is absent."

## Honest limitations to state

- API Center private skill catalogs, Foundry Skills API, and toolbox skill discovery are preview features without an SLA.
- API Center is not a runtime and does not natively implement per-skill read/write/run permissions.
- The sample editor uses ephemeral container storage; production authoring should use pull requests or a durable store with approvals.
- Git sync setup is currently a portal workflow and requires a repository URL; this local workspace started without a Git remote.
- Role assignments can take up to 24 hours to appear in Foundry catalog discovery.