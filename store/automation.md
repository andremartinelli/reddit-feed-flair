# Automatic publishing

Publishing a GitHub Release with tag `v<version>` (for example `v1.3.1`) runs two workflows, one per store. They run independently: if one fails, the other still publishes. Pre-releases are skipped. Each store still reviews every version.

## Chrome Web Store

`.github/workflows/publish.yml`:

1. checks that the tag matches `version` in `manifest.json`;
2. checks the syntax of `content.js` and the JSON files;
3. builds the ZIP with `build.sh`;
4. gets a short-lived Google token through Workload Identity Federation (no key is stored in GitHub);
5. uploads the ZIP to the Chrome Web Store (API v2) and submits it for review. It goes live automatically once Google approves it.

To check that the setup still works without publishing anything: **Actions › Publish to Chrome Web Store › Run workflow**. It only reads the item's status in the store.

### One-time setup

Requirements: 2-Step Verification on the Google account that owns the Chrome Web Store item, and a recent `gcloud` CLI (`gcloud components update`; version 410 crashes on the workload identity commands).

Current setup (2026-11-23): project `feed-flair-cws-57237`, service account `cws-publisher@feed-flair-cws-57237.iam.gserviceaccount.com`, in the Google account that owns the store item.

#### 1. Google Cloud: project, service account and GitHub federation

```sh
PROJECT_ID=feed-flair-cws-$RANDOM   # must be globally unique
REPO=andremartinelli/reddit-feed-flair

gcloud projects create "$PROJECT_ID"
gcloud services enable chromewebstore.googleapis.com iamcredentials.googleapis.com sts.googleapis.com iam.googleapis.com --project "$PROJECT_ID"
gcloud iam service-accounts create cws-publisher --display-name="Chrome Web Store publisher" --project "$PROJECT_ID"

# Right after creating the project, IAM can answer "permission denied" for a minute or two: wait and retry.
gcloud iam workload-identity-pools create github --location=global --display-name="GitHub" --project "$PROJECT_ID"
gcloud iam workload-identity-pools providers create-oidc reddit-feed-flair --project "$PROJECT_ID" \
  --location=global --workload-identity-pool=github \
  --issuer-uri="https://token.actions.githubusercontent.com" \
  --attribute-mapping="google.subject=assertion.sub,attribute.repository=assertion.repository" \
  --attribute-condition="assertion.repository=='$REPO'"

PROJECT_NUMBER=$(gcloud projects describe "$PROJECT_ID" --format='value(projectNumber)')
gcloud iam service-accounts add-iam-policy-binding "cws-publisher@$PROJECT_ID.iam.gserviceaccount.com" \
  --project "$PROJECT_ID" --role=roles/iam.workloadIdentityUser \
  --member="principalSet://iam.googleapis.com/projects/$PROJECT_NUMBER/locations/global/workloadIdentityPools/github/attribute.repository/$REPO"

echo "GCP_SERVICE_ACCOUNT=cws-publisher@$PROJECT_ID.iam.gserviceaccount.com"
echo "GCP_WORKLOAD_IDENTITY_PROVIDER=projects/$PROJECT_NUMBER/locations/global/workloadIdentityPools/github/providers/reddit-feed-flair"
```

Only workflows from this repository can use the service account.

#### 2. Chrome Web Store dashboard

1. **Account** page: add the service account email (`cws-publisher@...`) in the service account field and save.
2. Copy the **publisher ID** (Publisher › Settings) and the **item ID** (the 32-letter ID on the item's Package tab).

#### 3. GitHub repository variables

None of these are secrets.

```sh
gh variable set GCP_SERVICE_ACCOUNT --body "cws-publisher@<project-id>.iam.gserviceaccount.com"
gh variable set GCP_WORKLOAD_IDENTITY_PROVIDER --body "projects/<project-number>/locations/global/workloadIdentityPools/github/providers/reddit-feed-flair"
gh variable set CWS_PUBLISHER_ID --body "<publisher-id>"
gh variable set CWS_ITEM_ID --body "<item-id>"
```

## Firefox Add-ons

`.github/workflows/publish-firefox.yml`:

1. checks that the tag matches `version` in `manifest.json`;
2. checks the syntax of `content.js` and the JSON files;
3. builds the ZIP with `build.sh` (the same package as the Chrome Web Store);
4. runs `scripts/amo-publish.sh`, which uploads the ZIP to Firefox Add-ons (API v5), waits for the automatic validation and submits it as a new version for Firefox desktop. The release text becomes the version's release notes, and `store/amo-approval-notes.txt` becomes the notes for Mozilla reviewers. It goes live once Mozilla approves it.

Firefox Add-ons has no keyless login like Google's, so the workflow uses an API key stored as secrets of the GitHub environment `amo`. The environment only accepts `main` and `v*` tags, so a workflow running on any other branch, such as the ones Claude Code sessions push, can't read the key. That matters because the key works for the whole Firefox Add-ons account, not only this add-on.

To check that the setup works without publishing anything: **Actions › Publish to Firefox Add-ons › Run workflow** on `main`. It only reads the add-on's status.

### One-time setup

1. **API key.** In the [Add-on Developer Hub](https://addons.mozilla.org/developers/addon/api/key/) (Tools › Manage API Keys), generate new credentials. Keep the page open: you need the **JWT issuer** (looks like `user:12345:67`) and the **JWT secret**.
2. **Environment.** On GitHub: the repository's **Settings › Environments › New environment**, name `amo`.
3. **Who can use it.** In the `amo` environment, under **Deployment branches and tags**, choose **Selected branches and tags** and add two rules: branch `main` and tag `v*`.
4. **Secrets.** In the same environment, under **Environment secrets**, add `AMO_JWT_ISSUER` (the JWT issuer) and `AMO_JWT_SECRET` (the JWT secret). From a terminal, `gh secret set AMO_JWT_ISSUER --env amo` and `gh secret set AMO_JWT_SECRET --env amo` ask for each value without showing it.
5. **Test.** Once the workflow is on `main`, run **Actions › Publish to Firefox Add-ons › Run workflow**. A working setup prints the add-on's `guid`, `status` and latest version. `401` means a wrong issuer or secret.

If the key leaks, revoke it on the same Developer Hub page and repeat steps 1 and 4.

## Releasing

1. Raise `version` in `manifest.json`, commit and push.
2. Create the release with a short note for users: `gh release create v<version> --notes "Fixes flair colors in dark mode."` (or on GitHub: Releases › Draft a new release). The note becomes the release notes on Firefox Add-ons, so avoid `--generate-notes`, which writes a list of pull requests.
3. Follow both runs in the repository's **Actions** tab.

If a run fails, the error is in the failed step's log. The manual fallback is still `./build.sh` plus an upload in that store's dashboard, with the same version: the other store may already have it.
