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
  lightPT?: PascalABCLightPTOptions;
}

export interface PascalABCLightPTOptions {
  tasks: string;
  taskName?: string;
}

export interface PascalABCLightPTResult {
  checked: boolean;
  taskName: string;
  status: "NotUnderControl" | "Solved" | "IOError" | "BadSolution" | "PartialSolution" | "InitialTask" | "BadInitialTask" | "InitialTaskPT4" | "ErrFix" | "Demo";
  passed: boolean;
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
  lightPT?: PascalABCLightPTResult;
}

// The zero-dependency JavaScript build is the package entry point. These
// declarations document its public surface without requiring TypeScript at runtime.
export { BrowserGraphicsRenderer, CanvasGraphicsRenderer, WebGLGraphicsRenderer, PascalABC, PascalABCClient, PascalABCTimeoutError } from "./pascalabc-web.js";
