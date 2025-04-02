// MCP stdio Agent - TypeScript 버전

import readline from "readline";

interface MCPMessage {
  id: string;
  method: string;
  [key: string]: any;
}

interface ContextResult {
  jsonrpc: string;
  id: string;
  result?: any;
  error?: {
    code: number;
    message: string;
  };
}

// 표준 입력/출력 인터페이스 생성
const rl = readline.createInterface({
  input: process.stdin,
  output: process.stdout,
  terminal: false
});

console.log(JSON.stringify({
  jsonrpc: "2.0",
  method: "initialize",
  result: true
}));

// 메시지 핸들링
rl.on("line", (input: string) => {
  try {
    const message: MCPMessage = JSON.parse(input);
    let response: ContextResult;

    if (message.method === "getContext") {
      response = {
        jsonrpc: "2.0",
        id: message.id,
        result: {
          name: "example-context",
          description: "샘플로 생성된 컨텍스트",
          files: [
            {
              relativePath: "src/index.ts",
              content: "console.log(\"Hello from MCP agent!\");"
            }
          ]
        }
      };
    } else if (message.method === "shutdown") {
      response = {
        jsonrpc: "2.0",
        id: message.id,
        result: "bye"
      };
      console.log(JSON.stringify(response));
      process.exit(0);
    } else {
      response = {
        jsonrpc: "2.0",
        id: message.id,
        error: {
          code: -32601,
          message: "Unknown method"
        }
      };
    }

    console.log(JSON.stringify(response));
  } catch (err) {
    console.error("Invalid JSON input:", input);
  }
});
