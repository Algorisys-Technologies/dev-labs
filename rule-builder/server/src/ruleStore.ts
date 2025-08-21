
import { Rule, RuleGroup, Condition, ReturnValueSpec } from "./types";

let rules: Rule[] = [];

// Utility: evaluate single condition
function evaluateCondition(cond: Condition, input: any): boolean {
  const left = input[cond.field];
  const right = cond.value;
  switch (cond.operator) {
    case ">": return left > right;
    case "<": return left < right;
    case "=": return left == right;
    case "!=": return left != right;
    case "contains": return (left ?? "").toString().includes(right);
    default: return false;
  }
}

// Recursive group evaluation
function evaluateGroup(group: RuleGroup, input: any): boolean {
  const condResults = group.conditions.map(c => evaluateCondition(c, input));
  const groupResults = group.groups.map(g => evaluateGroup(g, input));
  const results = [...condResults, ...groupResults];

  switch (group.type) {
    case "AND": return results.every(Boolean);
    case "OR": return results.some(Boolean);
    case "NOT": return results.length === 1 ? !results[0] : false;
    case "XOR": return results.filter(Boolean).length === 1;
    default: return false;
  }
}

// Evaluate return spec
function evaluateReturnSpec(spec: ReturnValueSpec, input: any): any {
  switch (spec.type) {
    case "constant": return spec.value;
    case "object": return { ...spec.value };
    case "property": return input[spec.value];
    case "expression": {
      try {
        // Dangerous: sandbox ideally, but kept simple here
        const fn = new Function(...Object.keys(input), `return ${spec.value}`);
        return fn(...Object.values(input));
      } catch(error) {
        console.error("Error evaluating expression:", error);
        return null;
      }
    }
    default: return null;
  }
}

// Rule evaluation (applies success/failure at top-level only)
export function evaluateRule(rule: Rule, input: any): any {
  const boolResult = evaluateGroup(rule.groups[0], input);
  if (boolResult) {
    return rule.successValue ? evaluateReturnSpec(rule.successValue, input) : true;
  } else {
    return rule.failureValue ? evaluateReturnSpec(rule.failureValue, input) : false;
  }
}

// Rule store functions
export const ruleStore = {
  save(rule: Rule) {
    if(!rules.find(r => rule.id === r.id))
      rules.push(rule);
    return rule;
  },
  list() {
    return rules;
  },
  get(id: string) {
    return rules.find(r => r.id === id);
  }
};

// import fs from "fs/promises";
// import path from "path";
// import { v4 as uuidv4 } from "uuid";
// import { evaluateReturnValue, ReturnValue } from "./ruleEngine";

// const DATA_DIR = path.join(__dirname, "..", "data");
// const RULES_FILE = path.join(DATA_DIR, "rules.json");

// type Condition = {
//   field: string;
//   op: string;
//   value: any;
//   resultIfTrue?: any;
//   resultIfFalse?: any;
// };

// type Group = {
//   id?: string;
//   type: "group";
//   logic: "AND" | "OR" | "XOR" | "NOT";
//   children: Array<Group | Condition>;
// };

// type StoredRule = {
//   id: string;
//   name: string;
//   versions: Array<{ version: number; rule: Group; createdAt: string }>;
// };

// export interface Rule {
//   id: string;
//   name: string;
//   groups: Group[];
//   successValue?: ReturnValue;   // ✅ applies at rule level
//   failureValue?: ReturnValue;
// }

// async function ensureFile(){
//   try {
//     await fs.mkdir(DATA_DIR, { recursive: true });
//     await fs.access(RULES_FILE);
//   } catch {
//     await fs.writeFile(RULES_FILE, "[]", "utf8");
//   }
// }

// async function readAll(): Promise<StoredRule[]>{
//   await ensureFile();
//   const txt = await fs.readFile(RULES_FILE, "utf8");
//   return JSON.parse(txt || "[]");
// }

// async function writeAll(all: StoredRule[]){
//   await fs.writeFile(RULES_FILE, JSON.stringify(all, null, 2), "utf8");
// }

// export async function listRules(): Promise<Pick<StoredRule,"id"|"name"|"versions">[]>{
//   const all = await readAll();
//   return all.map(r => ({ id: r.id, name: r.name, versions: r.versions }));
// }

// export async function getRule(id: string): Promise<StoredRule | null>{
//   const all = await readAll();
//   return all.find(r => r.id === id) || null;
// }

// export async function saveRule(name: string, rule: Group): Promise<StoredRule>{
//   const all = await readAll();
//   // find existing by name -> create new version
//   let s = all.find(x => x.name === name);
//   if (!s) {
//     s = { id: uuidv4(), name, versions: [] };
//     all.push(s);
//   }
//   const version = (s.versions.length ? s.versions[s.versions.length-1].version : 0) + 1;
//   s.versions.push({ version, rule, createdAt: new Date().toISOString() });
//   await writeAll(all);
//   return s;
// }

// // Evaluate engine
// function compare(a:any, op:string, b:any){
//   if (a === undefined) return false;
//   if (op === "=" || op === "==") return a == b;
//   if (op === "===") return a === b;
//   if (op === "!=" || op === "<>") return a != b;
//   if (op === "!==") return a !== b;
//   if (op === ">") return a > b;
//   if (op === ">=") return a >= b;
//   if (op === "<") return a < b;
//   if (op === "<=") return a <= b;
//   if (op === "contains") return (String(a)).includes(String(b));
//   if (op === "startsWith") return String(a).startsWith(String(b));
//   if (op === "endsWith") return String(a).endsWith(String(b));
//   if (op === "in") return Array.isArray(b) ? b.includes(a) : (String(b).split(",").map(s=>s.trim()).includes(String(a)));
//   if (op === "matches") {
//     try {
//       const re = new RegExp(b);
//       return re.test(String(a));
//     } catch {
//       return false;
//     }
//   }
//   return false;
// }

// function evalResultSpec(spec:any, context:any){
//   // spec can be:
//   // - undefined -> return undefined
//   // - { type: "const", value: ... } -> return value
//   // - { type: "expr", expr: "..." } -> evaluate JS expression with context (unsafe)
//   // - { type: "obj", value: {...} } -> return object
//   if (spec === undefined) return undefined;
//   if (typeof spec !== "object" || spec === null) return spec;
//   if (spec.type === "const") return spec.value;
//   if (spec.type === "obj") return spec.value;
//   if (spec.type === "expr") {
//     // Unsafe: evaluate expression with dataset in scope
//     const fn = new Function("data", `with (data) { return (${spec.expr}); }`);
//     return fn(context);
//   }
//   return spec;
// }

// function evaluateNode(node:any, data:any): any{
//   if (!node) return null;
//   if (node.type === "group"){
//     const logic = node.logic || "AND";
//     const childResults = node.children.map((c:any)=>evaluateNode(c, data));
//     if (logic === "AND") {
//       const ok = childResults.every(r=>r.result === true);
//       return { result: ok, detail: { logic, child: childResults } };
//     }
//     if (logic === "OR") {
//       const ok = childResults.some(r=>r.result === true);
//       return { result: ok, detail: { logic, child: childResults } };
//     }
//     if (logic === "XOR") {
//       const count = childResults.filter(r=>r.result === true).length;
//       const ok = count === 1;
//       return { result: ok, detail: { logic, child: childResults } };
//     }
//     if (logic === "NOT") {
//       // NOT expects single child
//       const ok = childResults.length === 1 ? !childResults[0].result : !childResults.every(r=>r.result);
//       return { result: ok, detail: { logic, child: childResults } };
//     }
//     return { result: false, detail: { error: "unknown logic" } };
//   } else {
//     // condition
//     const field = (node as any).field;
//     const op = (node as any).op;
//     const val = (node as any).value;
//     const left = (data && Object.prototype.hasOwnProperty.call(data, field)) ? (data as any)[field] : undefined;
//     const res = compare(left, op, val);
//     // pick resultIfTrue / resultIfFalse if provided
//     const rTrue = evalResultSpec((node as any).resultIfTrue, data);
//     const rFalse = evalResultSpec((node as any).resultIfFalse, data);
//     let out:any;
//     if (res) out = (rTrue === undefined ? true : rTrue);
//     else out = (rFalse === undefined ? false : rFalse);

//     if (rTrue) {
//       return evaluateReturnValue(node.successValue, data) ?? true;
//     } else {
//       return evaluateReturnValue(node.failureValue, data) ?? false;
//     }

//     // return { result: Boolean(res), detail: { field, op, left, value: val, output: out } };
//   }
// }

// export async function evaluateRule(ruleId?:string, ruleOverride?:any, dataset?:any){
//   let ruleObj:any = null;
//   if (ruleOverride) ruleObj = ruleOverride;
//   else if (ruleId) {
//     const r = await getRule(ruleId);
//     if (!r) throw new Error("rule id not found");
//     // use latest version
//     ruleObj = r.versions[r.versions.length-1].rule;
//   } else {
//     throw new Error("rule or ruleId required");
//   }
//   const evalRes = evaluateNode(ruleObj, dataset || {});
//   return { result: (evalRes.result ? (evalRes.detail) : evalRes.result), detail: evalRes };
// }

// // export function evaluateRule(rule: Rule, input: any) {
// //   const result = evaluateGroup(rule.groups[0], input); // top-level
// //   if (result) {
// //     return rule.successValue ? evaluateReturnSpec(rule.successValue, input) : true;
// //   } else {
// //     return rule.failureValue ? evaluateReturnSpec(rule.failureValue, input) : false;
// //   }
// // }