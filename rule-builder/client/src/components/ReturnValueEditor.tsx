import { ReturnValueSpec } from "../types";

interface Props {
  value?: ReturnValueSpec;
  onChange: (val: ReturnValueSpec) => void;
}

export default function ReturnValueEditor({ value, onChange }: Props) {
  return (
    <div className="border p-2 rounded">
      <select
        value={value?.type ?? "constant"}
        onChange={(e) =>
          onChange({ type: e.target.value as any, value: "" })
        }
        className="border px-2 py-1 rounded mr-2"
      >
        <option value="constant">Constant</option>
        <option value="object">Object</option>
        <option value="property">Object Property</option>
        <option value="expression">Expression</option>
      </select>
      <input
        className="border px-2 py-1 rounded w-64"
        placeholder="Enter value"
        value={value?.value ?? ""}
        onChange={(e) =>
          onChange({ type: value?.type ?? "constant", value: e.target.value })
        }
      />
    </div>
  );
}
