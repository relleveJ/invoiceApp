<#
PowerShell helper to test PDF endpoints for this project.

Usage:
  .\scripts\test_pdf_endpoints.ps1 -BaseUrl http://localhost:8000 -Username myuser -Password mypass

What it does:
- Fetches CSRF token from the login page
- Logs in and preserves cookies
- Requests /pdf-status/ (diagnostic)
- Posts a small preview JSON to /invoices/preview/?format=pdf to check PDF response

Notes:
- The script requires the dev server to be running at `-BaseUrl` and a valid user account.
#>

param(
    [string]$BaseUrl = 'http://localhost:8000',
    [string]$Username = '',
    [string]$Password = ''
)

if (-not $Username -or -not $Password) {
    Write-Host "Usage: .\scripts\test_pdf_endpoints.ps1 -BaseUrl http://localhost:8000 -Username USER -Password PASS"
    exit 1
}

$cookieJar = "$PSScriptRoot\cookies.txt"
if (Test-Path $cookieJar) { Remove-Item $cookieJar -ErrorAction SilentlyContinue }

Write-Host "Fetching login page to obtain CSRF token..."
$loginPage = Invoke-WebRequest -Uri (Join-Path $BaseUrl '/') -UseBasicParsing -SessionVariable session -ErrorAction Stop

# Try to obtain the CSRF token from cookies (Django sets csrftoken cookie) or hidden input
$csrf = $null
if ($session.Cookies.GetCookies($BaseUrl).Count -gt 0) {
    foreach ($c in $session.Cookies.GetCookies($BaseUrl)) {
        if ($c.Name -eq 'csrftoken') { $csrf = $c.Value; break }
    }
}
if (-not $csrf) {
    try { $csrf = ($loginPage.Content -match 'name="csrfmiddlewaretoken" value="([^"]+)"' | Out-Null; $Matches[1]) } catch { }
}

if (-not $csrf) { Write-Warning "Could not locate CSRF token; login POST may fail." }

Write-Host "Logging in as $Username..."
$loginUrl = (Join-Path $BaseUrl 'login/')
$form = @{ 'username' = $Username; 'password' = $Password; 'csrfmiddlewaretoken' = $csrf }

$loginResp = Invoke-WebRequest -Uri $loginUrl -Method Post -Body $form -WebSession $session -UseBasicParsing -ErrorAction SilentlyContinue
if ($loginResp.StatusCode -ge 400) {
    Write-Warning "Login request returned status $($loginResp.StatusCode). Verify credentials and that server is running." 
}

Write-Host "Saving session cookies to $cookieJar (curl-compatible)"
# Convert .NET CookieContainer to a simple curl-compatible cookie file
$sb = New-Object System.Text.StringBuilder
foreach ($c in $session.Cookies.GetCookies($BaseUrl)) {
    $sb.AppendLine("#HttpOnly_$($c.Domain)`tTRUE`t/`t$($c.Secure.ToString().ToUpper())`t$($c.Expires.ToUniversalTime().ToString('R'))`t$($c.Name)`t$($c.Value)") | Out-Null
}
[System.IO.File]::WriteAllText($cookieJar, $sb.ToString())

Write-Host "Requesting diagnostic /pdf-status/"
try {
    $status = Invoke-WebRequest -Uri (Join-Path $BaseUrl 'pdf-status/') -UseBasicParsing -WebSession $session -ErrorAction Stop
    Write-Host "pdf-status response:`n$status.Content`n"
} catch {
    Write-Warning "Failed to GET /pdf-status/ - $_"
}

Write-Host "Posting a small preview JSON to /invoices/preview/?format=pdf to check PDF response..."
$previewUrl = (Join-Path $BaseUrl 'invoices/preview/?format=pdf')

$sample = @{
    invoice_number = 'TEST-123'
    invoice_date = (Get-Date -Format yyyy-MM-dd)
    due_date = (Get-Date).AddDays(30).ToString('yyyy-MM-dd')
    client = @{ name = 'Test Client'; email = 'client@example.com' }
    items = @(@{ description='Test item'; quantity=1; unit_price=10.00 })
    template = '1'
} | ConvertTo-Json -Depth 6

try {
    $resp = Invoke-WebRequest -Uri $previewUrl -Method Post -Body $sample -ContentType 'application/json' -WebSession $session -UseBasicParsing -ErrorAction Stop -Headers @{ 'Accept' = 'application/pdf' }
    $ct = $resp.Headers['Content-Type']
    Write-Host "Response Content-Type: $ct"
    if ($ct -and $ct -like 'application/pdf*') {
        $out = "$PSScriptRoot\preview_output.pdf"
        [System.IO.File]::WriteAllBytes($out, $resp.RawContent)
        Write-Host "Saved PDF to $out"
    } else {
        Write-Warning "Server did not return a PDF. Response length: $($resp.RawContent.Length)"
        $htmlOut = "$PSScriptRoot\preview_fallback.html"
        [System.IO.File]::WriteAllText($htmlOut, $resp.Content)
        Write-Host "Saved fallback HTML to $htmlOut"
    }
} catch {
    Write-Warning "Preview POST failed: $_"
}

Write-Host "Done. If the script saved a PDF, open it to verify. If not, check server logs and ensure the Python package `reportlab` is installed or that an alternative backend (wkhtmltopdf) is available." 

# For users who prefer curl, here are equivalent commands (replace USER/PASS and URL):
<#
curl -c cookies.txt "http://localhost:8000/" -o login.html
# extract csrf value from login.html and then:
curl -b cookies.txt -c cookies.txt -d "username=USER&password=PASS&csrfmiddlewaretoken=TOKEN" -X POST http://localhost:8000/login/
curl -b cookies.txt http://localhost:8000/pdf-status/
curl -b cookies.txt -H "Accept: application/pdf" -H "Content-Type: application/json" --data '{"invoice_number":"T","invoice_date":"2026-01-01","due_date":"2026-02-01","client":{"name":"X"},"items":[{"description":"x","quantity":1,"unit_price":10}]}' "http://localhost:8000/invoices/preview/?format=pdf" --output preview.pdf
#>
