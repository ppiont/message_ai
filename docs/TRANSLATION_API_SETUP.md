# Translation API Setup Guide

This guide walks through setting up Google Cloud Translation API with Secret Manager for secure API key storage.

## Prerequisites

- Firebase project with Cloud Functions enabled
- Google Cloud Console access
- `gcloud` CLI installed and configured

## Step 1: Enable Required APIs

Enable the Translation API and Secret Manager API in your Google Cloud project:

```bash
# Enable Translation API
gcloud services enable translate.googleapis.com

# Enable Secret Manager API
gcloud services enable secretmanager.googleapis.com
```

Or enable via Google Cloud Console:
1. Go to https://console.cloud.google.com/
2. Navigate to "APIs & Services" > "Library"
3. Search for and enable:
   - "Cloud Translation API"
   - "Secret Manager API"

## Step 2: Get Translation API Key

**Option A: Use Application Default Credentials (Recommended)**

Cloud Functions automatically have access to Translation API through the default service account. No API key needed!

**Option B: Create an API Key (if needed for testing)**

1. Go to https://console.cloud.google.com/apis/credentials
2. Click "Create Credentials" > "API Key"
3. Copy the API key
4. Click "Restrict Key" and limit to "Cloud Translation API"

## Step 3: Store API Key in Secret Manager (Optional)

If using an API key (Option B above), store it securely:

```bash
# Create a secret
echo -n "YOUR_API_KEY_HERE" | gcloud secrets create translation-api-key \
    --data-file=- \
    --replication-policy="automatic"

# Grant access to Cloud Functions service account
PROJECT_ID=$(gcloud config get-value project)
PROJECT_NUMBER=$(gcloud projects describe $PROJECT_ID --format="value(projectNumber)")
SERVICE_ACCOUNT="${PROJECT_NUMBER}-compute@developer.gserviceaccount.com"

gcloud secrets add-iam-policy-binding translation-api-key \
    --member="serviceAccount:${SERVICE_ACCOUNT}" \
    --role="roles/secretmanager.secretAccessor"
```

## Step 4: Configure Environment Variables (if using Secret Manager)

Update your Cloud Function deployment to use the secret:

```bash
cd functions
firebase deploy --only functions:translate_message \
    --set-env-vars TRANSLATION_API_KEY_SECRET=translation-api-key
```

## Step 5: Verify Setup

Test the translation function:

```bash
# Using Firebase CLI
firebase functions:shell

# In the shell:
translate_message({data: {text: "Hello", target_language: "es"}})
```

Or test via Flutter app after deploying.

## Cost Considerations

**Translation API Pricing** (as of 2024):
- $20 per 1 million characters
- First 500,000 characters free per month

**Cache Strategy**:
- Our implementation includes Firestore caching (Subtask 124.3)
- Target: 70% cache hit rate
- Expected cost: ~$6/month for 1M translations (with 70% cache hits)

**Rate Limiting**:
- 100 requests per hour per user (Subtask 124.4)
- Prevents abuse and controls costs

## Security Best Practices

1. **Use Application Default Credentials**: No need to manage API keys
2. **If using API keys**: Store in Secret Manager, never commit to code
3. **Rate Limiting**: Implemented in Subtask 124.4
4. **Input Validation**: Already implemented in translate_message function
5. **Firebase App Check**: Will be added in Task 137

## Troubleshooting

### "Permission denied" errors

Ensure the Cloud Functions service account has the required permissions:

```bash
# Grant Translation API access
gcloud projects add-iam-policy-binding YOUR_PROJECT_ID \
    --member="serviceAccount:${SERVICE_ACCOUNT}" \
    --role="roles/cloudtranslate.user"
```

### "API not enabled" errors

Make sure both APIs are enabled:

```bash
gcloud services list --enabled | grep -E "translate|secretmanager"
```

### High costs

- Check cache hit rate in Cloud Functions logs
- Verify rate limiting is working
- Monitor usage in Google Cloud Console > Translation API > Metrics

## Next Steps

- ✅ Subtask 124.1: Python Cloud Function implemented
- → Subtask 124.2: Secret Manager setup (you are here)
- → Subtask 124.3: Translation caching (reduces costs by 70%)
- → Subtask 124.4: Rate limiting (100/hour per user)

After completing setup, proceed to implement caching in Subtask 124.3.
