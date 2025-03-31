# run-cmd-mcp.ps1 - 실전 보강 버전

$logFile = "mcp_log.txt"

function Write-Log($msg) {
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Add-Content -Path $logFile -Value "[$timestamp] $msg"
}

function Write-JsonRpcResponse($id, $result, $isError=$false) {
    if ($isError) {
        $response = @{
            jsonrpc = "2.0"
            id = $id
            error = $result
        } | ConvertTo-Json -Compress
    } else {
        $response = @{
            jsonrpc = "2.0"
            id = $id
            result = $result
        } | ConvertTo-Json -Compress
    }

    $bytes = [System.Text.Encoding]::UTF8.GetByteCount($response)
    Write-Output "Content-Length: $bytes"
    Write-Output "Content-Type: application/json"
    Write-Output ""
    Write-Output $response
}

while ($true) {
    # 1. 헤더 읽기
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

        try {
            $request = $jsonString | ConvertFrom-Json
        } catch {
            Write-Log "JSON 파싱 실패: $jsonString"
            continue
        }

        $method = $request.method
        $id = $request.id
        Write-Log "메서드 수신: $method"

        if ($method -eq "list_tools") {
            $tool = @{
                name = "run_cmd"
                description = "Windows 명령어(cmd)에서 dir, mkdir 등의 명령을 실행하고 출력 결과를 반환합니다."
                input_schema = @{
                    type = "object"
                    properties = @{
                        command = @{
                            type = "string"
                            description = "실행할 Windows 명령어 문자열 (예: dir, echo hello, git status, etc.)"
                        }
                    }
                    required = @("command")
                }
            }
            Write-JsonRpcResponse $id @{ tools = @($tool) }

        } elseif ($method -eq "run_cmd") {
            if (-not $request.params -or -not $request.params.command) {
                $errorResponse = @{
                    code = -32602
                    message = "Missing required parameter: command"
                }
                Write-JsonRpcResponse $id $errorResponse $true
                continue
            }

            $cmd = $request.params.command
            Write-Log "명령 실행 요청: $cmd"

            try {
                $startInfo = New-Object System.Diagnostics.ProcessStartInfo
                $startInfo.FileName = "cmd.exe"
                $startInfo.Arguments = "/c $cmd"
                $startInfo.RedirectStandardOutput = $true
                $startInfo.RedirectStandardError = $true
                $startInfo.UseShellExecute = $false
                $startInfo.CreateNoWindow = $true

                $process = New-Object System.Diagnostics.Process
                $process.StartInfo = $startInfo
                $process.Start() | Out-Null

                if (-not $process.WaitForExit(5000)) {
                    $process.Kill()
                    $output = "⏱ 실행 시간이 초과되었습니다 (5초 제한)"
                } else {
                    $output = $process.StandardOutput.ReadToEnd() + $process.StandardError.ReadToEnd()
                }

                if ($output.Length -gt 3000) {
                    $output = $output.Substring(0, 3000) + "`n... (출력 생략됨)"
                }

            } catch {
                $output = "명령 실행 중 오류 발생: $_"
            }

            Write-JsonRpcResponse $id $output
        } else {
            $errorResponse = @{
                code = -32601
                message = "Unknown method: $method"
            }
            Write-JsonRpcResponse $id $errorResponse $true
        }
    }
}
