import { Parser } from "expr-eval";

export interface ReturnValue {
  type: "constant" | "object" | "property" | "expression";
  value: string;
}

export function evaluateReturnValue(
  rv: ReturnValue | undefined,
  data: Record<string, any>
): any {
  if (!rv) return undefined;

  switch (rv.type) {
    case "constant":
      try {
        return JSON.parse(rv.value); // parse numbers, bools, etc
      } catch {
        return rv.value; // fallback string
      }

    case "object":
      try {
        return JSON.parse(rv.value);
      } catch {
        throw new Error("Invalid JSON object in return value");
      }

    case "property":
      return rv.value.split(".").reduce((acc, key) => acc?.[key], data);

    case "expression":
      try {
        const expr = Parser.parse(rv.value);
        return expr.evaluate(data);
      } catch (err) {
        throw new Error("Invalid expression: " + rv.value);
      }

    default:
      return undefined;
  }
}
