import { useEffect, useMemo, useState } from "react";
import { Condition, Operator, ReturnValueSpec, Rule, RuleGroup } from "../types";

// ------------------------------------
// Utilities
// ------------------------------------
const genId = () => Math.random().toString(36).slice(2, 10);

const defaultCondition = (): Condition => ({
  field: "age",
  operator: ">",
  value: 18,
});

const defaultGroup = (type: RuleGroup["type"] = "AND"): RuleGroup => ({
  id: genId(),
  type,
  conditions: [],
  groups: [],
});

// Deep clone helper to avoid state mutation bugs
const deepClone = <T,>(x: T): T => JSON.parse(JSON.stringify(x));

// Find a group by id (DFS). Returns tuple [group, parent] if found.
function findGroupById(
  root: RuleGroup,
  id: string,
  parent?: RuleGroup
): [RuleGroup, RuleGroup | undefined] | null {
  if (root.id === id) return [root, parent];
  for (const g of root.groups) {
    const found = findGroupById(g, id, root);
    if (found) return found;
  }
  return null;
}

// Replace a group node (by id) with a new node
function replaceGroup(root: RuleGroup, targetId: string, next: RuleGroup): RuleGroup {
  if (root.id === targetId) return next;
  return {
    ...root,
    groups: root.groups.map((g) => replaceGroup(g, targetId, next)),
  };
}

// Remove a group node by id (returns [newRoot, removed?])
function removeGroup(root: RuleGroup, targetId: string): [RuleGroup, boolean] {
  if (root.id === targetId) {
    // Caller must ensure not removing the top root.
    return [root, false];
  }
  const nextChildren: RuleGroup[] = [];
  let removed = false;
  for (const g of root.groups) {
    if (g.id === targetId) {
      removed = true;
      continue;
    }
    const [childNext, childRemoved] = removeGroup(g, targetId);
    removed = removed || childRemoved;
    nextChildren.push(childNext);
  }
  return [{ ...root, groups: nextChildren }, removed];
}

// Human-readable text for preview
function toHuman(group: RuleGroup): string {
  const conds = group.conditions.map((c) => {
    const v = typeof c.value === "string" ? `"${c.value}"` : c.value;
    return `${c.field} ${c.operator} ${v}`;
  });
  const subs = group.groups.map(toHuman);
  const all = [...conds, ...subs];
  if (group.type === "NOT") {
    // NOT ideally applies to a single child – display accordingly
    if (all.length === 1) return `NOT ${all[0]}`;
    return `NOT (${all.join(" AND ")})`;
  }
  return `(${all.join(` ${group.type} `)})`;
}

// Color highlighting for preview (very simple "syntax highlighting")
function highlightText(text: string) {
  // Color words that look like operators or group types
  const html = text
    .replace(/\b(AND|OR|NOT|XOR)\b/g, `<span class="text-purple-700 font-semibold">$1</span>`)
    .replace(/\b(=|!=|>|<|>=|<=|contains)\b/g, `<span class="text-blue-700 font-semibold">$1</span>`)
    .replace(/("[^"]*"|\b\d+(\.\d+)?\b)/g, `<span class="text-emerald-700">$1</span>`);
  return { __html: html };
}

// ------------------------------------
// Embedded ReturnValueEditor
// (kept local to keep this file self-contained)
// ------------------------------------
function ReturnValueEditor({
  label,
  value,
  onChange,
}: {
  label: string;
  value?: ReturnValueSpec;
  onChange: (v: ReturnValueSpec) => void;
}) {
  return (
    <div>
      <label className="block text-sm text-gray-700 mb-1">{label}</label>
      <div className="flex gap-2 items-center">
        <select
          className="border rounded px-2 py-1"
          value={value?.type ?? "constant"}
          onChange={(e) => onChange({ type: e.target.value as ReturnValueSpec["type"], value: "" })}
        >
          <option value="constant">Constant</option>
          <option value="object">Object (JSON)</option>
          <option value="property">Object Property (dot path)</option>
          <option value="expression">Expression (JS)</option>
        </select>
        <input
          className="border rounded px-2 py-1 w-72"
          placeholder="Enter value / JSON / dot.path / expression"
          value={value?.value ?? ""}
          onChange={(e) => onChange({ type: value?.type ?? "constant", value: e.target.value })}
        />
      </div>
      <p className="text-xs text-gray-500 mt-1">
        Examples — constant: <code className="font-mono">"APPROVED"</code>, object:{" "}
        <code className="font-mono">{`{"tier":"gold"}`}</code>, property:{" "}
        <code className="font-mono">user.address.city</code>, expression:{" "}
        <code className="font-mono">input.age * 2</code>
      </p>
    </div>
  );
}

// ------------------------------------
// Condition Row
// ------------------------------------
function ConditionRow({
  cond,
  onChange,
  onRemove,
}: {
  cond: Condition;
  onChange: (next: Condition) => void;
  onRemove: () => void;
}) {
  const operators: Operator[] = [">", "<", "=", "!=", "contains"];

  return (
    <div className="flex flex-wrap gap-2 items-center bg-white border rounded p-2">
      <input
        className="border rounded px-2 py-1"
        placeholder="field (e.g., age)"
        value={cond.field}
        onChange={(e) => onChange({ ...cond, field: e.target.value })}
      />
      <select
        className="border rounded px-2 py-1"
        value={cond.operator}
        onChange={(e) => onChange({ ...cond, operator: e.target.value as Operator })}
      >
        {operators.map((op) => (
          <option key={op} value={op}>
            {op}
          </option>
        ))}
      </select>
      <input
        className="border rounded px-2 py-1"
        placeholder="value (e.g., 18 or Mumbai)"
        value={cond.value}
        onChange={(e) => {
          // try to coerce to number if looks numeric
          const raw = e.target.value;
          const num = Number(raw);
          onChange({ ...cond, value: !isNaN(num) && raw.trim() !== "" ? num : raw });
        }}
      />
      <button
        className="ml-auto text-red-600 hover:underline"
        onClick={onRemove}
        title="Remove condition"
      >
        Remove
      </button>
    </div>
  );
}

// ------------------------------------
// Group Editor (recursive)
// ------------------------------------
function GroupEditor({
  root,
  group,
  onChange,
  onAddGroup,
  onAddCondition,
  onRemoveGroup,
}: {
  root: RuleGroup;
  group: RuleGroup;
  onChange: (next: RuleGroup) => void;
  onAddGroup: (parentId: string, type?: RuleGroup["type"]) => void;
  onAddCondition: (parentId: string) => void;
  onRemoveGroup: (groupId: string) => void;
}) {
  const canRemove = group.id !== root.id;

  return (
    <div className="border rounded-lg p-3 bg-gray-50">
      <div className="flex items-center gap-2 mb-3">
        <span className="text-xs uppercase text-gray-500">Group</span>
        <select
          className="border rounded px-2 py-1"
          value={group.type}
          onChange={(e) => onChange({ ...group, type: e.target.value as RuleGroup["type"] })}
        >
          <option value="AND">AND</option>
          <option value="OR">OR</option>
          <option value="NOT">NOT</option>
          <option value="XOR">XOR</option>
        </select>
        {canRemove && (
          <button
            className="ml-auto text-red-600 hover:underline"
            onClick={() => onRemoveGroup(group.id)}
          >
            Remove Group
          </button>
        )}
      </div>

      {/* Conditions */}
      <div className="space-y-2 mb-3">
        {group.conditions.map((c, idx) => (
          <ConditionRow
            key={idx}
            cond={c}
            onChange={(next) => {
              const copy = deepClone(group);
              copy.conditions[idx] = next;
              onChange(copy);
            }}
            onRemove={() => {
              const copy = deepClone(group);
              copy.conditions.splice(idx, 1);
              onChange(copy);
            }}
          />
        ))}
      </div>

      <div className="flex gap-2 mb-3">
        <button
          className="bg-blue-600 text-white px-3 py-1 rounded"
          onClick={() => onAddCondition(group.id)}
        >
          + Add Condition
        </button>
        <button
          className="bg-emerald-600 text-white px-3 py-1 rounded"
          onClick={() => onAddGroup(group.id, "AND")}
        >
          + Add Sub-Group
        </button>
      </div>

      {/* Sub-groups */}
      <div className="space-y-3">
        {group.groups.map((g) => (
          <GroupEditor
            key={g.id}
            root={root}
            group={g}
            onChange={(next) => {
              // replace child by id
              const replaced = replaceGroup(group, next.id, next);
              onChange(replaced);
            }}
            onAddGroup={onAddGroup}
            onAddCondition={onAddCondition}
            onRemoveGroup={onRemoveGroup}
          />
        ))}
      </div>
    </div>
  );
}

// ------------------------------------
// Main Rule Builder
// ------------------------------------
export default function RuleBuilder() {
  const [rule, setRule] = useState<Rule>({
    id: "rule-" + genId(),
    name: "My Rule",
    groups: [defaultGroup("AND")],
  });

  // Persisted rules list (from server)
  const [savedRules, setSavedRules] = useState<Rule[]>([]);
  const [loadingRules, setLoadingRules] = useState(false);

  // Return specs at final rule level
  const [successValue, setSuccessValue] = useState<ReturnValueSpec | undefined>();
  const [failureValue, setFailureValue] = useState<ReturnValueSpec | undefined>();

  // Test input & result
  const [testInput, setTestInput] = useState(`{"age": 25, "city": "Mumbai", "country": "India"}`);
  const [testResult, setTestResult] = useState<any>(null);
  const [errorMsg, setErrorMsg] = useState<string | null>(null);

  // Derived human text + JSON
  const humanText = useMemo(() => (rule.groups[0] ? toHuman(rule.groups[0]) : ""), [rule]);
  const ruleJson = useMemo<Rule>(() => {
    return {
      ...rule,
      successValue,
      failureValue,
    };
  }, [rule, successValue, failureValue]);

  // ------------------------------
  // Group ops
  // ------------------------------
  const updateRoot = (nextRoot: RuleGroup) => {
    setRule((r) => ({ ...r, groups: [nextRoot] }));
  };

  const onChangeGroup = (next: RuleGroup) => {
    // Replace in tree starting at root
    updateRoot(replaceGroup(rule.groups[0], next.id, next));
  };

  const onAddGroup = (parentId: string, type: RuleGroup["type"] = "AND") => {
    const root = deepClone(rule.groups[0]);
    const found = findGroupById(root, parentId);
    if (!found) return;
    const [g] = found;
    g.groups.push(defaultGroup(type));
    updateRoot(root);
  };

  const onAddCondition = (parentId: string) => {
    const root = deepClone(rule.groups[0]);
    const found = findGroupById(root, parentId);
    if (!found) return;
    const [g] = found;
    g.conditions.push(defaultCondition());
    updateRoot(root);
  };

  const onRemoveGroup = (groupId: string) => {
    // prevent deleting top root
    if (groupId === rule.groups[0].id) return;
    const [nextRoot] = removeGroup(rule.groups[0], groupId);
    updateRoot(nextRoot);
  };

  // ------------------------------
  // Server interactions
  // ------------------------------
  const saveRule = async () => {
    setErrorMsg(null);
    try {
      const resp = await fetch("http://localhost:4000/rules", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(ruleJson),
      });
      if (!resp.ok) throw new Error(await resp.text());
      const saved = (await resp.json()) as Rule;
      setRule(saved);
    } catch (e: any) {
      setErrorMsg(e.message || "Failed to save");
    }
  };

  const loadRules = async () => {
    setLoadingRules(true);
    setErrorMsg(null);
    try {
      const resp = await fetch("http://localhost:4000/rules");
      const list = (await resp.json()) as Rule[];
      setSavedRules(list);
    } catch (e: any) {
      setErrorMsg(e.message || "Failed to load rules");
    } finally {
      setLoadingRules(false);
    }
  };

  const loadRuleIntoEditor = (id: string) => {
    const r = savedRules.find((x) => x.id === id);
    if (!r) return;
    setRule({ id: r.id, name: r.name, groups: deepClone(r.groups) });
    setSuccessValue(r.successValue);
    setFailureValue(r.failureValue);
    setTestResult(null);
  };

  const testRule = async () => {
    setErrorMsg(null);
    setTestResult(null);
    try {
      const data = JSON.parse(testInput);
      const resp = await fetch(`http://localhost:4000/rules/${rule.id}/evaluate`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(data), // server expects input as body
      });
      const out = await resp.json();
      setTestResult(out.result);
    } catch (e: any) {
      setErrorMsg(e.message || "Invalid JSON or server error");
    }
  };

  // ------------------------------
  // Clipboard helpers
  // ------------------------------
  const copyJson = async () => {
    await navigator.clipboard.writeText(JSON.stringify(ruleJson, null, 2));
  };
  const copyText = async () => {
    await navigator.clipboard.writeText(humanText);
  };

  // auto load rules list once
  useEffect(() => {
    loadRules().catch(() => void 0);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  return (
    <div className="max-w-5xl mx-auto space-y-6">
      <header className="flex items-center justify-between">
        <h1 className="text-2xl font-bold">Rule Builder</h1>
        <div className="flex gap-2">
          <button className="bg-blue-600 text-white px-3 py-1 rounded" onClick={saveRule}>
            Save Rule
          </button>
          <button className="bg-gray-700 text-white px-3 py-1 rounded" onClick={loadRules}>
            Refresh List
          </button>
        </div>
      </header>

      {errorMsg && (
        <div className="bg-red-50 border border-red-200 text-red-700 px-3 py-2 rounded">
          {errorMsg}
        </div>
      )}

      {/* Rule meta */}
      <div className="bg-white border rounded p-3">
        <div className="flex flex-wrap gap-3 items-center">
          <label className="text-sm w-28">Rule ID</label>
          <input
            className="border rounded px-2 py-1 grow"
            value={rule.id}
            onChange={(e) => setRule((r) => ({ ...r, id: e.target.value }))}
          />
        </div>
        <div className="flex flex-wrap gap-3 items-center mt-2">
          <label className="text-sm w-28">Rule Name</label>
          <input
            className="border rounded px-2 py-1 grow"
            value={rule.name}
            onChange={(e) => setRule((r) => ({ ...r, name: e.target.value }))}
          />
        </div>
      </div>

      {/* Groups/Conditions editor (recursive) */}
      <div className="bg-white border rounded p-3">
        <GroupEditor
          root={rule.groups[0]}
          group={rule.groups[0]}
          onChange={onChangeGroup}
          onAddGroup={onAddGroup}
          onAddCondition={onAddCondition}
          onRemoveGroup={onRemoveGroup}
        />
      </div>

      {/* Return values at FINAL RULE LEVEL */}
      <div className="bg-white border rounded p-3">
        <h3 className="font-semibold mb-3">Return Values (applied to final boolean)</h3>
        <div className="grid md:grid-cols-2 gap-4">
          <ReturnValueEditor label="On Success" value={successValue} onChange={setSuccessValue} />
          <ReturnValueEditor label="On Failure" value={failureValue} onChange={setFailureValue} />
        </div>
        <p className="text-xs text-gray-500 mt-2">
          If left empty, the engine will return a boolean (true/false).
        </p>
      </div>

      {/* Preview + Copy */}
      <div className="bg-white border rounded p-3">
        <div className="flex items-center gap-2 mb-2">
          <h3 className="font-semibold">Live Preview</h3>
          <button className="ml-auto px-3 py-1 rounded border" onClick={copyText}>
            Copy as Text
          </button>
          <button className="px-3 py-1 rounded border" onClick={copyJson}>
            Copy as JSON
          </button>
        </div>
        <div
          className="font-mono text-sm bg-gray-50 border rounded p-3"
          dangerouslySetInnerHTML={highlightText(humanText || "(empty)")}
        />
        <details className="mt-3">
          <summary className="cursor-pointer text-sm text-gray-700">JSON</summary>
          <pre className="bg-gray-50 p-3 rounded text-sm overflow-auto">
            {JSON.stringify(ruleJson, null, 2)}
          </pre>
        </details>
      </div>

      {/* Saved rules list */}
      <div className="bg-white border rounded p-3">
        <div className="flex items-center gap-2 mb-2">
          <h3 className="font-semibold">Saved Rules</h3>
          {loadingRules && <span className="text-xs text-gray-500">loading…</span>}
        </div>
        {savedRules.length === 0 ? (
          <p className="text-sm text-gray-600">No rules saved yet.</p>
        ) : (
          <div className="overflow-auto">
            <table className="min-w-[400px] w-full text-sm">
              <thead>
                <tr className="text-left border-b">
                  <th className="py-1 pr-2">ID</th>
                  <th className="py-1 pr-2">Name</th>
                  <th className="py-1 pr-2">Actions</th>
                </tr>
              </thead>
              <tbody>
                {savedRules.map((r) => (
                  <tr key={r.id} className="border-b">
                    <td className="py-1 pr-2 font-mono">{r.id}</td>
                    <td className="py-1 pr-2">{r.name}</td>
                    <td className="py-1 pr-2">
                      <button
                        className="text-blue-700 hover:underline"
                        onClick={() => loadRuleIntoEditor(r.id)}
                      >
                        Load into Builder
                      </button>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </div>

      {/* Test runner */}
      <div className="bg-white border rounded p-3">
        <h3 className="font-semibold mb-2">Test Rule (evaluates on server)</h3>
        <div className="grid md:grid-cols-2 gap-4">
          <div>
            <label className="block text-sm mb-1">Input JSON</label>
            <textarea
              className="w-full h-40 border rounded p-2 font-mono text-sm"
              value={testInput}
              onChange={(e) => setTestInput(e.target.value)}
            />
            <div className="mt-2">
              <button className="bg-indigo-600 text-white px-3 py-1 rounded" onClick={testRule}>
                Run Test
              </button>
            </div>
          </div>
          <div>
            <label className="block text-sm mb-1">Result</label>
            <pre className="w-full h-40 border rounded p-2 bg-gray-50 overflow-auto text-sm">
              {testResult === null ? "—" : JSON.stringify(testResult, null, 2)}
            </pre>
          </div>
        </div>
      </div>
    </div>
  );
}
