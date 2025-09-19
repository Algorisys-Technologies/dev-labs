import * as XLSX from "xlsx";
import { useState, useRef, useEffect } from "react";


type CellMap = Record<string, string>;

// ---------------- Helpers ----------------

// Convert index → Excel letters (A, B …, Z, AA …)
const colToName = (index: number): string => {
  let name = "";
  while (index >= 0) {
    name = String.fromCharCode((index % 26) + 65) + name;
    index = Math.floor(index / 26) - 1;
  }
  return name;
};

// Convert Excel letters → index
const nameToCol = (name: string): number => {
  let result = 0;
  for (let i = 0; i < name.length; i++) {
    result = result * 26 + (name.charCodeAt(i) - 64);
  }
  return result - 1;
};

// Formula evaluator
function evalFormula(expr: string, cells: CellMap): string {
  if (!expr.startsWith("=")) return expr;
  const inner = expr.slice(1).toUpperCase();

  // // SUM(A1:AA3)
  // const sumMatch = /^SUM\(([A-Z]+)(\d+):([A-Z]+)(\d+)\)$/i.exec(inner);
  // if (sumMatch) {
  //   const [, c1, r1, c2, r2] = sumMatch;
  //   const col1 = nameToCol(c1), col2 = nameToCol(c2);
  //   const row1 = parseInt(r1) - 1, row2 = parseInt(r2) - 1;
  //   let total = 0;
  //   for (let r = row1; r <= row2; r++) {
  //     for (let c = col1; c <= col2; c++) {
  //       const key = `${r}:${c}`;
  //       const v = evalFormula(cells[key] || "0", cells);
  //       total += Number(v) || 0;
  //     }
  //   }
  //   return String(total);
  // }

  // Generic range handler (e.g. A1:AA3)
  const rangeRegex = /^([A-Z]+)(\d+):([A-Z]+)(\d+)$/;

  // Extract numbers from a range
  const getRangeValues = (c1: string, r1: string, c2: string, r2: string): number[] => {
    const col1 = nameToCol(c1), col2 = nameToCol(c2);
    const row1 = parseInt(r1) - 1, row2 = parseInt(r2) - 1;
    const values: number[] = [];
    for (let r = row1; r <= row2; r++) {
      for (let c = col1; c <= col2; c++) {
        const key = `${r}:${c}`;
        const v = evalFormula(cells[key] || "0", cells);
        values.push(Number(v) || 0);
      }
    }
    return values;
  };
  // SUM
  let match = /^SUM\((.+)\)$/i.exec(inner);
  if (match) {
    if (rangeRegex.test(match[1])) {
      const [, c1, r1, c2, r2] = rangeRegex.exec(match[1])!;
      return String(getRangeValues(c1, r1, c2, r2).reduce((a, b) => a + b, 0));
    }
  }

  // AVERAGE
  match = /^AVERAGE\((.+)\)$/i.exec(inner);
  if (match) {
    if (rangeRegex.test(match[1])) {
      const [, c1, r1, c2, r2] = rangeRegex.exec(match[1])!;
      const vals = getRangeValues(c1, r1, c2, r2);
      return vals.length ? String(vals.reduce((a, b) => a + b, 0) / vals.length) : "0";
    }
  }

  // MIN
  match = /^MIN\((.+)\)$/i.exec(inner);
  if (match) {
    if (rangeRegex.test(match[1])) {
      const [, c1, r1, c2, r2] = rangeRegex.exec(match[1])!;
      const vals = getRangeValues(c1, r1, c2, r2);
      return String(Math.min(...vals));
    }
  }

  // MAX
  match = /^MAX\((.+)\)$/i.exec(inner);
  if (match) {
    if (rangeRegex.test(match[1])) {
      const [, c1, r1, c2, r2] = rangeRegex.exec(match[1])!;
      const vals = getRangeValues(c1, r1, c2, r2);
      return String(Math.max(...vals));
    }
  }

  // COUNT
  match = /^COUNT\((.+)\)$/i.exec(inner);
  if (match) {
    if (rangeRegex.test(match[1])) {
      const [, c1, r1, c2, r2] = rangeRegex.exec(match[1])!;
      const vals = getRangeValues(c1, r1, c2, r2);
      return String(vals.filter(v => v !== 0).length);
    }
  }

  // Replace refs (A1, B2, AA3...)
  const replaced = inner.replace(/([A-Z]+)(\d+)/g, (_, col, row) => {
    const key = `${parseInt(row) - 1}:${nameToCol(col)}`;
    return evalFormula(cells[key] || "0", cells);
  });

  try {
    // eslint-disable-next-line no-new-func
    return String(Function(`"use strict"; return (${replaced})`)());
  } catch {
    return "#ERR";
  }
}

// ---------------- Component ----------------

export default function Sheet() {
  const rows = 50;
  const [cols, setCols] = useState(20);

  const [cells, setCells] = useState<CellMap>({});
  const [editing, setEditing] = useState<string | null>(null);

  // --- Undo/Redo ---
  const [history, setHistory] = useState<CellMap[]>([]);
  const [redoStack, setRedoStack] = useState<CellMap[]>([]);

  const pushHistory = (newCells: CellMap) => {
    setHistory(h => [...h, cells]);
    setRedoStack([]);
    setCells(newCells);
  };

  const undo = () => {
    if (history.length === 0) return;
    const prev = history[history.length - 1];
    setHistory(h => h.slice(0, -1));
    setRedoStack(r => [...r, cells]);
    setCells(prev);
  };

  const redo = () => {
    if (redoStack.length === 0) return;
    const next = redoStack[redoStack.length - 1];
    setRedoStack(r => r.slice(0, -1));
    setHistory(h => [...h, cells]);
    setCells(next);
  };

  // --- CSV/XLSX Import ---
  const importFile = (file: File) => {
    const reader = new FileReader();

    if (file.name.endsWith(".csv")) {
      reader.onload = e => {
        const text = e.target?.result as string;
        const lines = text.split(/\r?\n/);
        const newCells: CellMap = {};
        lines.forEach((line, r) => {
          const values = line.split(",");
          values.forEach((val, c) => {
            if (val.trim() !== "") newCells[`${r}:${c}`] = val;
          });
        });
        pushHistory(newCells);
      };
      reader.readAsText(file);
    } else if (file.name.endsWith(".xlsx")) {
      reader.onload = e => {
        const data = new Uint8Array(e.target?.result as ArrayBuffer);
        const workbook = XLSX.read(data, { type: "array" });
        const sheetName = workbook.SheetNames[0];
        const sheet = workbook.Sheets[sheetName];
        const json: string[][] = XLSX.utils.sheet_to_json(sheet, { header: 1 });

        const newCells: CellMap = {};
        json.forEach((row, r) => {
          row.forEach((val, c) => {
            if (val !== undefined && val !== null && val !== "")
              newCells[`${r}:${c}`] = String(val);
          });
        });
        pushHistory(newCells);
      };
      reader.readAsArrayBuffer(file);
    } else {
      alert("Unsupported file type. Please upload CSV or XLSX.");
    }
  };


  // --- Auto-expand columns ---
  const containerRef = useRef<HTMLDivElement>(null);
  useEffect(() => {
    const el = containerRef.current;
    if (!el) return;
    const handleScroll = () => {
      if (el.scrollLeft + el.clientWidth >= el.scrollWidth - 100) {
        setCols(c => c + 10);
      }
    };
    el.addEventListener("scroll", handleScroll);
    return () => el.removeEventListener("scroll", handleScroll);
  }, []);

  // --- CSV Export ---
  const exportCSV = () => {
    let maxRow = 0, maxCol = 0;
    Object.keys(cells).forEach(key => {
      const [r, c] = key.split(":").map(Number);
      maxRow = Math.max(maxRow, r);
      maxCol = Math.max(maxCol, c);
    });

    let lines: string[] = [];
    for (let r = 0; r <= maxRow; r++) {
      const row: string[] = [];
      for (let c = 0; c <= maxCol; c++) {
        row.push(cells[`${r}:${c}`] || "");
      }
      lines.push(row.join(","));
    }
    const blob = new Blob([lines.join("\n")], { type: "text/csv" });
    const url = URL.createObjectURL(blob);
    const a = document.createElement("a");
    a.href = url;
    a.download = "sheet.csv";
    a.click();
    URL.revokeObjectURL(url);
  };

  // --- CSV Import ---
  const importCSV = (file: File) => {
    const reader = new FileReader();
    reader.onload = e => {
      const text = e.target?.result as string;
      const lines = text.split(/\r?\n/);
      const newCells: CellMap = {};
      lines.forEach((line, r) => {
        const values = line.split(",");
        values.forEach((val, c) => {
          if (val.trim() !== "") newCells[`${r}:${c}`] = val;
        });
      });
      pushHistory(newCells);
    };
    reader.readAsText(file);
  };

  const setCell = (r: number, c: number, v: string) =>
    pushHistory({ ...cells, [`${r}:${c}`]: v });

  return (
    <div style={{ padding: 16 }}>
      <h2>Excel-like Sheet (Undo/Redo + CSV)</h2>

      {/* Toolbar */}
      <div style={{ marginBottom: 8 }}>
        <button onClick={undo} disabled={history.length === 0}>Undo</button>
        <button onClick={redo} disabled={redoStack.length === 0}>Redo</button>
        <button onClick={exportCSV}>Export CSV</button>
        <input
          type="file"
          accept=".csv,.xlsx"
          onChange={e => {
            const file = e.target.files?.[0];
            if (file) importFile(file);
          }}
        />

      </div>

      {/* Sheet */}
      <div
        ref={containerRef}
        style={{
          overflow: "auto",
          border: "1px solid #ccc",
          maxWidth: "100%",
          maxHeight: "80vh",
        }}
      >
        <table style={{ borderCollapse: "collapse" }}>
          <thead>
            <tr>
              <th />
              {Array.from({ length: cols }).map((_, c) => (
                <th
                  key={c}
                  style={{
                    border: "1px solid #ccc",
                    padding: 4,
                    minWidth: 80,
                    background: "#f9f9f9",
                  }}
                >
                  {colToName(c)}
                </th>
              ))}
            </tr>
          </thead>
          <tbody>
            {Array.from({ length: rows }).map((_, r) => (
              <tr key={r}>
                <th style={{ border: "1px solid #ccc", padding: 4, background: "#f3f3f3" }}>
                  {r + 1}
                </th>
                {Array.from({ length: cols }).map((_, c) => {
                  const key = `${r}:${c}`;
                  const raw = cells[key] || "";
                  const display = editing === key ? raw : evalFormula(raw, cells);

                  return (
                    <td
                      key={c}
                      style={{
                        border: "1px solid #ccc",
                        minWidth: 80,
                        height: 28,
                        padding: 2,
                      }}
                      onDoubleClick={() => setEditing(key)}
                    >
                      {editing === key ? (
                        <input
                          style={{ width: "100%", border: "none", outline: "none" }}
                          value={raw}
                          autoFocus
                          onChange={e => setCell(r, c, e.target.value)}
                          onBlur={() => setEditing(null)}
                          onKeyDown={e => {
                            if (e.key === "Enter") setEditing(null);
                          }}
                        />
                      ) : (
                        display
                      )}
                    </td>
                  );
                })}
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
}
