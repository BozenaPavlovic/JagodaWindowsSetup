function Invoke-UiRefresh {

    try {
        if ("System.Windows.Forms.Application" -as [type]) {
            [System.Windows.Forms.Application]::DoEvents()
        }
    } catch {}
}

function Wait-ProcessWithUiRefresh {

    param(
        [System.Diagnostics.Process]$Process,
        [int]$TimeoutMs = 300000
    )

    $waited = 0

    while (-not $Process.WaitForExit(1000)) {

        Invoke-UiRefresh

        $waited += 1000

        if ($waited -ge $TimeoutMs) {
            try { $Process.Kill() } catch {}
            return $false
        }
    }

    return $true
}