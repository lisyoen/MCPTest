# run-cmd-mcp.ps1

# 무한 루프로 JSON-RPC 요청을 계속 받음
while ($true) {
    $header = ""
    while ($true) {
        $line = [Console]::In.ReadLine()
        if ($line -eq "") { break }
        $header += "$line`n"
    }

    if ($header -match "Content-Length:\s*(\d+)") {
        $length = [int]$Matches[1]
        $buffer = New-Object System.Char[] $length
        [Console]::In.Read($buffer, 0, $length) | Out-Null
        $jsonString = -join $buffer
        $request = $null

        try {
            $request = $jsonString | ConvertFrom-Json
        } catch {
            continue
        }

        # 명령어 실행
        $command = $request.params.command
        try {
            $output = cmd.exe /c $command 2>&1
        } catch {
            $output = $_.Exception.Message
        }

        # JSON-RPC 응답 구성
        $response = @{
            jsonrpc = "2.0"
            id = $request.id
            result = $output
        } | ConvertTo-Json -Compress

        $bytes = [System.Text.Encoding]::UTF8.GetByteCount($response)
        Write-Output "Content-Length: $bytes"
        Write-Output ""
        Write-Output $response
    }
}
