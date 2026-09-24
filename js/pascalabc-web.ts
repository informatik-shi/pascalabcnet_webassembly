export interface PascalABCDiagnostic {
  line: number;
  column: number;
  severity: "error" | "warning";
  code: string;
  message: string;
}

export interface PascalABCRunOptions {
  stdin?: string;
  timeout?: number;
  compileTimeout?: number;
}

export interface PascalABCTest {
  input: string;
  expected: string;
}

export interface PascalABCComparisonOptions {
  timeout?: number;
  trimTrailingWhitespace?: boolean;
  normalizeNewlines?: boolean;
  ignoreTrailingNewline?: boolean;
}

export interface PascalABCResult {
  success: boolean;
  stdout: string;
  stderr: string;
  exitCode: number;
  compileTime: number;
  executionTime: number;
  diagnostics: PascalABCDiagnostic[];
  timedOut?: boolean;
}

// The zero-dependency JavaScript build is the package entry point. These
// declarations document its public surface without requiring TypeScript at runtime.
export { BrowserGraphicsRenderer, CanvasGraphicsRenderer, WebGLGraphicsRenderer, PascalABC, PascalABCClient, PascalABCTimeoutError } from "./pascalabc-web.js";
