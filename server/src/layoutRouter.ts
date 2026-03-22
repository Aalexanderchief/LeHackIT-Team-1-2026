type LayoutName = "default" | "eldenring";

export function resolveLayoutForProcess(processName: string): LayoutName {
  const normalized = processName.trim().toLowerCase();

  if (normalized === "eldenring.exe") {
    return "eldenring";
  }

  return "default";
}
