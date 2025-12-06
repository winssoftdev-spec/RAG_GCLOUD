# PowerShell Script to Deploy to Google Artifact Registry
$REGION = "us-central1"
$REPO_NAME = "rag-repo"
$IMAGE_NAME = "sql-backend"
$TAG = "latest"

# 1. Get Project ID
Write-Host "Getting Project ID..."
$PROJECT_ID = gcloud config get-value project
if (-not $PROJECT_ID) {
    Write-Error "Could not get Default Project ID from gcloud config. Please run 'gcloud config set project <PROJECT_ID>'."
    exit 1
}
Write-Host "Project ID: $PROJECT_ID"

$FULL_IMAGE_PATH = "$REGION-docker.pkg.dev/$PROJECT_ID/$REPO_NAME/$IMAGE_NAME`:$TAG"

# 2. Create Repository (Ignore error if exists)
Write-Host "Ensuring Artifact Registry Repository exists..."
try {
    gcloud artifacts repositories create $REPO_NAME --repository-format=docker --location=$REGION --description="Docker repository for RAG Backend" 2>$null
} catch {
    Write-Host "Repository might already exist. Continuing..."
}

# 3. Configure Docker Auth
Write-Host "Configuring Docker Authentication..."
gcloud auth configure-docker "$REGION-docker.pkg.dev" --quiet

# 4. Build Image
Write-Host "Building Docker Image..."
docker build -t $FULL_IMAGE_PATH .

# 5. Push Image
if ($?) {
    Write-Host "Pushing Image to Artifact Registry..."
    docker push $FULL_IMAGE_PATH
    
    if ($?) {
        Write-Host "----------------------------------------------------------"
        Write-Host "SUCCESS: Image deployed to $FULL_IMAGE_PATH"
        Write-Host "You can now restart your GCE instances to pick up the new image."
        Write-Host "----------------------------------------------------------"
    } else {
        Write-Error "Failed to push image."
    }
} else {
    Write-Error "Failed to build image."
}
