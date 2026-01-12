# Deploy helper for adaptive-quiz Edge Function
# Usage: powershell -ExecutionPolicy Bypass -File .\scripts\deploy_adaptive_quiz.ps1
# Runs: checks supabase CLI, deploys function, shows recent logs, and performs a curl test.

function Abort($msg){ Write-Host "ERROR: $msg" -ForegroundColor Red; exit 1 }

Write-Host "1) Checking for supabase CLI..." -ForegroundColor Cyan
if (-not (Get-Command supabase -ErrorAction SilentlyContinue)) {
  Write-Host "supabase CLI not found. Please install it first." -ForegroundColor Yellow
  Write-Host "  npm install -g supabase" -ForegroundColor Green
  Write-Host "Or use winget/choco on Windows if you prefer." -ForegroundColor Green
  Abort "Install supabase CLI and re-run this script."
}

Write-Host "2) Ensure you're logged into supabase (interactive)..." -ForegroundColor Cyan
Write-Host "If not logged in, run: supabase login" -ForegroundColor Yellow

# Optional: check projects
try {
  Write-Host "Listing Supabase projects (to verify connection)..." -ForegroundColor Cyan
  supabase projects list
} catch {
  Write-Host "Warning: Couldn't list projects. Ensure supabase CLI is configured." -ForegroundColor Yellow
}

Write-Host "\n3) Deploying adaptive-quiz function..." -ForegroundColor Cyan
$deployExit = & supabase functions deploy adaptive-quiz
if ($LASTEXITCODE -ne 0) {
  Write-Host "Deploy command failed. Output:" -ForegroundColor Red
  Write-Host $deployExit
  Abort "Deploy failed. Check supabase CLI output above." 
}
Write-Host "Deploy completed. Output:" -ForegroundColor Green
Write-Host $deployExit

Write-Host "\n4) Fetching recent logs for adaptive-quiz..." -ForegroundColor Cyan
try {
  supabase functions logs adaptive-quiz --limit 100
} catch {
  Write-Host "Could not fetch logs (CLI may not be authenticated or function not deployed yet)." -ForegroundColor Yellow
}

Write-Host "\n5) Simple curl test (if function URL is public):" -ForegroundColor Cyan
$funcUrl = "https://gohrxehnreohljgsxlig.supabase.co/functions/v1/adaptive-quiz"
Write-Host "POST $funcUrl -d '{"level":"A1.1","topic":"Artikel"}'" -ForegroundColor Green
try {
  $response = curl -s -X POST $funcUrl -H "Content-Type: application/json" -d '{"level":"A1.1","topic":"Artikel"}'
  Write-Host "Response:" -ForegroundColor Green
  Write-Host $response
} catch {
  Write-Host "Curl test failed; ensure network access and that function is deployed." -ForegroundColor Yellow
}

Write-Host "\nDone. If you see 200 + JSON like {quizId, questions} the function is working." -ForegroundColor Magenta
Write-Host "If you encounter errors, paste the deploy output and logs here and I will help debug." -ForegroundColor Magenta