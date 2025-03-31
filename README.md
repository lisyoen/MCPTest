# MCPTest
MCP Test for Continue

## 🛠 MCP 등록 예시 (PowerShell 기반 run-cmd MCP)

이 MCP 서버는 표준 입력/출력을 통해 LLM 요청을 받아 Windows 명령어(cmd)를 실행하고, 결과를 응답합니다.

### 📂 config.json 등록 예시 (Continue 기준)

```json
{
  "experimental": {
    "modelContextProtocolServers": [
      {
        "transport": {
          "type": "stdio",
          "command": "powershell",
          "args": [
            "-ExecutionPolicy", "Bypass",
            "-File", "C:\\path\\to\\run-cmd-mcp.ps1"
          ]
        }
      }
    ]
  }
}
