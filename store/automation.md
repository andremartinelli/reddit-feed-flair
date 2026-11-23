# Automatic publishing

Publishing a GitHub Release with tag `v<version>` (for example `v1.3.1`) runs `.github/workflows/publish.yml`, which:

1. checks that the tag matches `version` in `manifest.json`;
2. checks the syntax of `content.js` and the JSON files;
3. builds the ZIP with `build.sh`;
4. gets a short-lived Google token through Workload Identity Federation (no key is stored in GitHub);
5. uploads the ZIP to the Chrome Web Store (API v2) and submits it for review. It goes live automatically once Google approves it.

Pre-releases are skipped. The Chrome Web Store review still applies to every version.

## One-time setup

Requirements: 2-Step Verification on the Google account that owns the Chrome Web Store item, and the `gcloud` CLI.

### 1. Google Cloud: project, service account and GitHub federation

```sh
PROJECT_ID=feed-flair-cws-$RANDOM   # must be globally unique
REPO=andremartinelli/reddit-feed-flair

gcloud projects create "$PROJECT_ID"
gcloud config set project "$PROJECT_ID"
gcloud services enable chromewebstore.googleapis.com iamcredentials.googleapis.com sts.googleapis.com iam.googleapis.com
gcloud iam service-accounts create cws-publisher --display-name="Chrome Web Store publisher"

gcloud iam workload-identity-pools create github --location=global --display-name="GitHub"
gcloud iam workload-identity-pools providers create-oidc reddit-feed-flair \
  --location=global --workload-identity-pool=github \
  --issuer-uri="https://token.actions.githubusercontent.com" \
  --attribute-mapping="google.subject=assertion.sub,attribute.repository=assertion.repository" \
  --attribute-condition="assertion.repository=='$REPO'"

PROJECT_NUMBER=$(gcloud projects describe "$PROJECT_ID" --format='value(projectNumber)')
gcloud iam service-accounts add-iam-policy-binding "cws-publisher@$PROJECT_ID.iam.gserviceaccount.com" \
  --role=roles/iam.workloadIdentityUser \
  --member="principalSet://iam.googleapis.com/projects/$PROJECT_NUMBER/locations/global/workloadIdentityPools/github/attribute.repository/$REPO"

echo "GCP_SERVICE_ACCOUNT=cws-publisher@$PROJECT_ID.iam.gserviceaccount.com"
echo "GCP_WORKLOAD_IDENTITY_PROVIDER=projects/$PROJECT_NUMBER/locations/global/workloadIdentityPools/github/providers/reddit-feed-flair"
```

Only workflows from this repository can use the service account.

### 2. Chrome Web Store dashboard

1. **Account** page: add the service account email (`cws-publisher@...`) in the service account field and save.
2. Copy the **publisher ID** (Publisher › Settings) and the **item ID** (the 32-letter ID on the item's Package tab).

### 3. GitHub repository variables

None of these are secrets.

```sh
gh variable set GCP_SERVICE_ACCOUNT --body "cws-publisher@<project-id>.iam.gserviceaccount.com"
gh variable set GCP_WORKLOAD_IDENTITY_PROVIDER --body "projects/<project-number>/locations/global/workloadIdentityPools/github/providers/reddit-feed-flair"
gh variable set CWS_PUBLISHER_ID --body "<publisher-id>"
gh variable set CWS_ITEM_ID --body "<item-id>"
```

## Releasing

1. Raise `version` in `manifest.json`, commit and push.
2. Create the release: `gh release create v<version> --generate-notes` (or on GitHub: Releases › Draft a new release).
3. Follow the run in the repository's **Actions** tab.

If the run fails, the error is in the failed step's log. The manual fallback is still `./build.sh` plus an upload in the dashboard.
