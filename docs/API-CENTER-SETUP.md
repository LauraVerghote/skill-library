# API Center setup

Target: `API-center-skills` in resource group `generic-demos` and subscription `07122d2f-74de-4565-bd61-4d673d621fe8`.

The Git integration for skill assets is currently configured in the Azure portal:

1. Push this repository to GitHub or Azure DevOps and copy its HTTPS URL.
2. Open API Center, then **Platforms > Integrations > New integration > From Git repository**.
3. Set the repository URL to the `.github/skills` folder on the main branch.
4. Choose the Git provider. For a private repository, store a read-only PAT in Key Vault and let API Center configure its managed identity.
5. Set the skill file pattern to `**/SKILL.md`, environment title to `Northstar Git`, environment ID to `northstar-git`, environment type to `Production`, and lifecycle to `Design` for the first sync.
6. Create the integration and verify the linked assets under **Inventory > Assets**.
7. Register `api/skill-library.openapi.yaml` as an OpenAPI asset after replacing its server URL and client ID placeholders. Add that API as an allowed tool on the skills that may call it.
8. Assign **Azure API Center Data Reader** on the API Center resource to developer security groups. This is separate from Foundry project access.
9. In Foundry, open **Build > Tools > Skills > Browse skills** and filter **Registry** to `API-center-skills`.

API Center synchronizes catalog metadata and provides discovery and assessment. Git remains the authoring and review system. Foundry keeps immutable executable skill versions. The runtime API enforces per-skill read, write, and run policy.