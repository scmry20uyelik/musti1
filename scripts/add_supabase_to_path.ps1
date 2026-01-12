$old = [Environment]::GetEnvironmentVariable('PATH','User')
$dir = "$env:LOCALAPPDATA\supabase"
if ($old -notlike "*$dir*") {
  [Environment]::SetEnvironmentVariable('PATH', "$old;$dir", 'User')
}
$env:PATH = $env:PATH + ";$dir"
Write-Host "User PATH updated with $dir"
Write-Host $env:PATH