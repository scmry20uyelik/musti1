$b = @{ level='A1.1'; topic='Artikel' } | ConvertTo-Json
try {
  $r = Invoke-RestMethod -Uri 'https://gohrxehnreohljgsxlig.supabase.co/functions/v1/adaptive-quiz' -Method Post -ContentType 'application/json' -Body $b -ErrorAction Stop
  Write-Output ($r | ConvertTo-Json -Depth 5)
} catch {
  if ($_.Exception.Response -ne $null) {
    $sr = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
    Write-Output $sr.ReadToEnd()
  } else {
    Write-Output ($_ | Out-String)
  }
}