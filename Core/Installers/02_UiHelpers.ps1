# ==========================================
# STRAWBERRY WINDOWS - UI HELPERS
# Keeps WinForms responsive during waits.
# ==========================================

function Invoke-UiRefresh {

    try {
        if ("System.Windows.Forms.Application" -as [type]) {
            [System.Windows.Forms.Application]::DoEvents()
        }
    }
    catch {
    }
}

function Wait-ProcessWithUiRefresh {

    param(
        [System.Diagnostics.Process]$Process,
        [int]$TimeoutMs = 300000
    )

    if (-not $Process) {
        return $false
    }

    $deadline = [DateTime]::UtcNow.AddMilliseconds($TimeoutMs)

    while (-not $Process.HasExited) {

        $remaining = ($deadline - [DateTime]::UtcNow).TotalMilliseconds

        if ($remaining -le 0) {
            try { $Process.Kill() } catch {}
            return $false
        }

        $slice = [math]::Min(500, [int]$remaining)

        $completed = $Process.WaitForExit($slice)

        if ($completed) {
            return $true
        }

        Invoke-UiRefresh
    }

    return $true
}