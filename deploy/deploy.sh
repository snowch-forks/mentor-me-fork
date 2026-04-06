#!/usr/bin/env bash
set -euo pipefail

#
# MentorMe - Deploy to Google Cloud Run with IAP
#
# Prerequisites (one-time setup - see SETUP.md):
#   1. GCP project created with billing enabled
#   2. gcloud CLI installed and authenticated
#   3. Claude API key stored in Secret Manager
#   4. IAP configured with your Google accounts
#
# Usage:
#   ./deploy/deploy.sh                    # Deploy with defaults
#   ./deploy/deploy.sh --project my-proj  # Specify project
#   ./deploy/deploy.sh --region us-east1  # Specify region
#

# --- Configuration ---
PROJECT_ID="${GCP_PROJECT:-}"
REGION="${GCP_REGION:-us-central1}"
SERVICE_NAME="mentorme"
SECRET_NAME="claude-api-key"

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --project) PROJECT_ID="$2"; shift 2 ;;
    --region) REGION="$2"; shift 2 ;;
    --service) SERVICE_NAME="$2"; shift 2 ;;
    *) echo "Unknown option: $1"; exit 1 ;;
  esac
done

# Validate project
if [[ -z "$PROJECT_ID" ]]; then
  PROJECT_ID=$(gcloud config get-value project 2>/dev/null || true)
  if [[ -z "$PROJECT_ID" ]]; then
    echo "ERROR: No GCP project set."
    echo "Run: gcloud config set project YOUR_PROJECT_ID"
    echo "Or:  ./deploy.sh --project YOUR_PROJECT_ID"
    exit 1
  fi
fi

echo "========================================"
echo " MentorMe Cloud Run Deployment"
echo "========================================"
echo " Project:  $PROJECT_ID"
echo " Region:   $REGION"
echo " Service:  $SERVICE_NAME"
echo "========================================"

# --- Enable required APIs ---
echo ""
echo ">>> Enabling required GCP APIs..."
gcloud services enable \
  run.googleapis.com \
  cloudbuild.googleapis.com \
  secretmanager.googleapis.com \
  iap.googleapis.com \
  --project="$PROJECT_ID" \
  --quiet

# --- Verify secret exists ---
echo ""
echo ">>> Checking for Claude API key in Secret Manager..."
if ! gcloud secrets describe "$SECRET_NAME" --project="$PROJECT_ID" &>/dev/null; then
  echo ""
  echo "ERROR: Secret '$SECRET_NAME' not found in Secret Manager."
  echo ""
  echo "Create it with:"
  echo "  echo -n 'sk-ant-your-key-here' | gcloud secrets create $SECRET_NAME --data-file=- --project=$PROJECT_ID"
  echo ""
  exit 1
fi
echo "    Secret '$SECRET_NAME' found."

# --- Build and deploy ---
echo ""
echo ">>> Building container with Cloud Build..."
echo "    (This takes 5-10 minutes on first deploy)"

# Build using Cloud Build (no local Docker needed)
gcloud builds submit \
  --tag "gcr.io/$PROJECT_ID/$SERVICE_NAME" \
  --project="$PROJECT_ID" \
  --timeout=1200s \
  .

echo ""
echo ">>> Deploying to Cloud Run..."

# Get the compute service account for secret access
PROJECT_NUMBER=$(gcloud projects describe "$PROJECT_ID" --format='value(projectNumber)')
SA_EMAIL="${PROJECT_NUMBER}-compute@developer.gserviceaccount.com"

# Grant secret access to the service account
gcloud secrets add-iam-policy-binding "$SECRET_NAME" \
  --member="serviceAccount:$SA_EMAIL" \
  --role="roles/secretmanager.secretAccessor" \
  --project="$PROJECT_ID" \
  --quiet

# Deploy to Cloud Run
gcloud run deploy "$SERVICE_NAME" \
  --image "gcr.io/$PROJECT_ID/$SERVICE_NAME" \
  --region "$REGION" \
  --project "$PROJECT_ID" \
  --platform managed \
  --port 8080 \
  --memory 512Mi \
  --cpu 1 \
  --min-instances 0 \
  --max-instances 2 \
  --set-secrets "CLAUDE_API_KEY=${SECRET_NAME}:latest" \
  --no-allow-unauthenticated \
  --quiet

# Get the service URL
SERVICE_URL=$(gcloud run services describe "$SERVICE_NAME" \
  --region="$REGION" \
  --project="$PROJECT_ID" \
  --format='value(status.url)')

echo ""
echo "========================================"
echo " Deployment complete!"
echo "========================================"
echo ""
echo " Service URL: $SERVICE_URL"
echo ""
echo " IMPORTANT: The service is NOT publicly accessible."
echo " You need to configure IAP to allow your Google accounts."
echo " See deploy/SETUP.md for IAP configuration steps."
echo ""
echo " After IAP is configured, access your app at:"
echo "   $SERVICE_URL"
echo ""
