import { Rule } from "../types";

interface Props {
  rule: Rule;
}

function renderGroup(group: any): string {
  const conds = group.conditions.map(
    (c: any) => `${c.field} ${c.operator} ${c.value}`
  );
  const subs = group.groups.map(renderGroup);
  const all = [...conds, ...subs];
  return "(" + all.join(` ${group.type} `) + ")";
}

export default function RulePreview({ rule }: Props) {
  return (
    <div className="bg-gray-100 p-4 rounded">
      <p className="font-bold">Rule Preview:</p>
      {rule.groups.length > 0 && (
        <p className="text-sm text-gray-800">{renderGroup(rule.groups[0])}</p>
      )}
      <div className="mt-2">
        {rule.successValue && (
          <p className="text-green-700 text-sm">
            On Success → {rule.successValue.type}: {JSON.stringify(rule.successValue.value)}
          </p>
        )}
        {rule.failureValue && (
          <p className="text-red-700 text-sm">
            On Failure → {rule.failureValue.type}: {JSON.stringify(rule.failureValue.value)}
          </p>
        )}
      </div>
    </div>
  );
}
