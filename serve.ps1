param(
    [int]$Port = 8000
)

$ErrorActionPreference = 'Stop'
$root = $PSScriptRoot

function Wait-BeforeClose {
    Write-Host ""
    Read-Host "Press Enter to close this window"
}

try {
    $listener = New-Object System.Net.HttpListener
    $listener.Prefixes.Add("http://localhost:$Port/")

    try {
        $listener.Start()
    }
    catch [System.Net.HttpListenerException] {
        Write-Host "ERROR: Could not start the server on port $Port." -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Red

        if ($_.Exception.ErrorCode -eq 5) {
            Write-Host ""
            Write-Host "This is a permissions problem, common on managed/corporate PCs." -ForegroundColor Yellow
            Write-Host "Fix (one-time, needs admin): open PowerShell as Administrator and run:" -ForegroundColor Yellow
            Write-Host "  netsh http add urlacl url=http://localhost:$Port/ user=$env:USERDOMAIN\$env:USERNAME" -ForegroundColor White
            Write-Host "After that you can run serve.bat normally, no admin needed." -ForegroundColor Yellow
        }
        elseif ($_.Exception.Message -match "already in use|address already") {
            Write-Host ""
            Write-Host "Port $Port is already in use. Try a different port, e.g.:" -ForegroundColor Yellow
            Write-Host "  serve.bat 8080" -ForegroundColor White
        }

        Wait-BeforeClose
        exit 1
    }

    Write-Host "Serving '$root' at http://localhost:$Port/ (Ctrl+C to stop)" -ForegroundColor Green

    $mimeTypes = @{
        ".html" = "text/html"
        ".htm"  = "text/html"
        ".js"   = "application/javascript"
        ".mjs"  = "application/javascript"
        ".wasm" = "application/wasm"
        ".css"  = "text/css"
        ".json" = "application/json"
        ".png"  = "image/png"
        ".jpg"  = "image/jpeg"
        ".jpeg" = "image/jpeg"
        ".gif"  = "image/gif"
        ".svg"  = "image/svg+xml"
        ".ico"  = "image/x-icon"
        ".txt"  = "text/plain"
        ".data" = "application/octet-stream"
    }

    try {
        while ($listener.IsListening) {
            $context = $listener.GetContext()
            $request = $context.Request
            $response = $context.Response

            $localPath = $request.Url.LocalPath
            if ($localPath -eq "/") { $localPath = "/index.html" }

            $filePath = Join-Path $root ($localPath.TrimStart("/") -replace "/", [IO.Path]::DirectorySeparatorChar)

            if (Test-Path $filePath -PathType Leaf) {
                $ext = [IO.Path]::GetExtension($filePath).ToLower()
                $contentType = $mimeTypes[$ext]
                if (-not $contentType) { $contentType = "application/octet-stream" }

                $bytes = [IO.File]::ReadAllBytes($filePath)
                $response.ContentType = $contentType
                $response.ContentLength64 = $bytes.Length
                $response.StatusCode = 200
                $response.OutputStream.Write($bytes, 0, $bytes.Length)
            } else {
                $response.StatusCode = 404
                $notFoundBytes = [Text.Encoding]::UTF8.GetBytes("404 Not Found: $localPath")
                $response.ContentLength64 = $notFoundBytes.Length
                $response.OutputStream.Write($notFoundBytes, 0, $notFoundBytes.Length)
            }

            $response.OutputStream.Close()
            Write-Host "$($request.HttpMethod) $localPath -> $($response.StatusCode)"
        }
    }
    finally {
        if ($listener.IsListening) { $listener.Stop() }
        $listener.Close()
    }
}
catch {
    Write-Host ""
    Write-Host "The server stopped because of an unexpected error:" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    Write-Host $_.InvocationInfo.PositionMessage -ForegroundColor DarkGray
    Wait-BeforeClose
    exit 1
}
