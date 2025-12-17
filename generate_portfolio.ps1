<#
generate_portfolio.ps1
- Looks for `YVR Portfolio.docx` in the script folder
- Extracts the document text and tries to find a Name line
- Generates `portfolio_generated.html` combining the provided DOB and qualification
Usage:
  Open PowerShell in the Day2 folder and run:
    .\generate_portfolio.ps1
#>

$ErrorActionPreference = 'Stop'
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$docxPath = Join-Path $scriptDir 'YVR Portfolio.docx'

if (-not (Test-Path $docxPath)) {
    Write-Error "Could not find 'YVR Portfolio.docx' in $scriptDir. Place the file there and re-run."
    exit 1
}

$temp = Join-Path $env:TEMP ([Guid]::NewGuid().ToString())
New-Item -ItemType Directory -Path $temp | Out-Null

try {
    Expand-Archive -LiteralPath $docxPath -DestinationPath $temp -Force | Out-Null
    $docXmlPath = Join-Path $temp 'word\document.xml'
    if (-not (Test-Path $docXmlPath)) { throw "document.xml not found inside docx" }

    [xml]$xml = Get-Content -Path $docXmlPath -Raw
    $ns = New-Object System.Xml.XmlNamespaceManager($xml.NameTable)
    $ns.AddNamespace('w','http://schemas.openxmlformats.org/wordprocessingml/2006/main')
    $nodes = $xml.SelectNodes('//w:t', $ns)
    $textLines = ($nodes | ForEach-Object { $_.'#text' }) -join "`n"

    # Try to find a Name line like "Name: John Doe" or "Name - John Doe"
    $nameMatch = ($textLines -split "`n") | Where-Object { $_ -match '(?i)^\s*Name\b' } | Select-Object -First 1
    if ($nameMatch) {
        # extract after colon or dash if present
        if ($nameMatch -match '[:\-]\s*(.+)$') { $name = $Matches[1].Trim() } else { $name = $nameMatch -replace '(?i)^\s*Name\b',''; $name = $name.Trim('-: ') }
    } else {
        # fallback: try to find first non-empty line that looks like a name
        $firstLine = ($textLines -split "`n") | Where-Object { $_.Trim() -ne '' } | Select-Object -First 1
        $name = $firstLine
    }

    if (-not $name) { $name = '[Name not found in docx]' }

    # Prepare HTML-escaped other details
    $escaped = [System.Web.HttpUtility]::HtmlEncode($textLines)
    $escaped = $escaped -replace "\r?\n","<br>`n"

    $outputPath = Join-Path $scriptDir 'portfolio_generated.html'

    $html = @"
<!DOCTYPE html>
<html lang=\"en\">
<head>
  <meta charset=\"utf-8\">
  <meta name=\"viewport\" content=\"width=device-width,initial-scale=1\">
  <title>Portfolio (Generated)</title>
  <style>
    body { font-family: Arial, Helvetica, sans-serif; max-width:800px; margin:30px auto; padding:20px; color:#333; }
    h1 { text-align:center; }
    .field { margin:12px 0; font-size:18px; }
    .label { font-weight:700; display:inline-block; width:220px; }
    .value { display:inline-block; }
    .details { background:#f7f7f7; padding:12px; border-radius:6px; }
  </style>
</head>
<body>
  <h1>Portfolio</h1>
  <div class=\"field\"><span class=\"label\">Name:</span><span class=\"value\">$name</span></div>
  <div class=\"field\"><span class=\"label\">Date of Birth:</span><span class=\"value\">15 August 1970</span></div>
  <div class=\"field\"><span class=\"label\">Educational Qualification:</span><span class=\"value\">M.Tech</span></div>
  <h2>Additional Details (from YVR Portfolio.docx)</h2>
  <div class=\"details\">$escaped</div>
</body>
</html>
"@

    Set-Content -Path $outputPath -Value $html -Encoding UTF8
    Write-Host "Generated portfolio at: $outputPath"
}
finally {
    Remove-Item -Recurse -Force $temp -ErrorAction SilentlyContinue
}
