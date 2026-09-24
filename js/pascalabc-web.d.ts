export interface PascalABCDiagnostic {
  line: number;
  column: number;
  severity: "error" | "warning";
  code: string;
  message: string;
}

export interface PascalABCInitOptions {
  workerUrl?: string | URL;
  baseUrl?: string | URL;
  initTimeout?: number;
}

export interface PascalABCRunOptions {
  stdin?: string;
  /** Maximum program execution time; compilation is governed separately. */
  timeout?: number;
  compileTimeout?: number;
}

export interface PascalABCCanvasOptions {
  onOpen?: (details: { renderer: "canvas2d"; width: number; height: number; title: string }) => void;
  onTitle?: (title: string) => void;
}

export class CanvasGraphicsRenderer {
  constructor(canvas: HTMLCanvasElement, options?: PascalABCCanvasOptions);
  readonly canvas: HTMLCanvasElement;
  handle(envelope: unknown): void;
  clear(): void;
}

export interface PascalABCCheckOptions {
  timeout?: number;
  trimTrailingWhitespace?: boolean;
  normalizeNewlines?: boolean;
  ignoreTrailingNewline?: boolean;
}

export interface PascalABCTest {
  input: string;
  expected: string;
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
  artifactId?: string;
  assemblyBytes?: number;
}

export interface PascalABCTestResult extends PascalABCTest {
  actual: string;
  stderr: string;
  exitCode: number;
  passed: boolean;
}

export interface PascalABCCheckResult {
  success: boolean;
  passed: number;
  failed: number;
  tests: PascalABCTestResult[];
  compileTime: number;
  diagnostics: PascalABCDiagnostic[];
  timedOut?: boolean;
}

export class PascalABCTimeoutError extends Error {
  readonly timeout: number;
}

export class PascalABCClient {
  version: string | null;
  init(options?: PascalABCInitOptions): Promise<this>;
  compile(code: string, options?: { timeout?: number }): Promise<PascalABCResult>;
  run(code: string, options?: PascalABCRunOptions): Promise<PascalABCResult>;
  check(code: string, tests: PascalABCTest[], options?: PascalABCCheckOptions): Promise<PascalABCCheckResult>;
  attachCanvas(canvas: HTMLCanvasElement, options?: PascalABCCanvasOptions): CanvasGraphicsRenderer;
  detachCanvas(): CanvasGraphicsRenderer | null;
  stop(): void;
}

export const PascalABC: PascalABCClient;
