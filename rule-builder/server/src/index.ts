import express from "express";
import cors from "cors";
import bodyParser from "body-parser";
import { ruleStore, evaluateRule } from "./ruleStore";
import { Rule } from "./types";

const app = express();
app.use(cors());
app.use(bodyParser.json());

app.post("/rules", (req, res) => {
  const rule: Rule = req.body;
  ruleStore.save(rule);
  res.json(rule);
});

app.get("/rules", (_, res) => {
  res.json(ruleStore.list());
});

app.post("/rules/:id/evaluate", (req, res) => {
  const rule = ruleStore.get(req.params.id);
  if (!rule) return res.status(404).send("Rule not found");
  const result = evaluateRule(rule, req.body);
  res.json({ result });
});

app.listen(4000, () => console.log("Server running on http://localhost:4000"));


// import express from "express";
// import cors from "cors";
// import bodyParser from "body-parser";
// import { saveRule, listRules, getRule, evaluateRule } from "./ruleStore";

// const app = express();
// app.use(cors());
// app.use(bodyParser.json());

// app.get("/api/rules", async (req, res) => {
//   const rules = await listRules();
//   res.json(rules);
// });

// app.get("/api/rules/:id", async (req, res) => {
//   const r = await getRule(req.params.id);
//   if (!r) return res.status(404).json({ error: "not found" });
//   res.json(r);
// });

// app.post("/api/rules", async (req, res) => {
//   // body: { name, rule }
//   const { name, rule } = req.body;
//   if (!name || !rule) return res.status(400).json({ error: "name & rule required" });
//   const saved = await saveRule(name, rule);
//   res.json(saved);
// });

// app.post("/api/evaluate", async (req, res) => {
//   // body: { ruleId, rule (optional), dataset }
//   const { ruleId, rule, dataset } = req.body;
//   try {
//     const { result, detail } = await evaluateRule(ruleId, rule, dataset);
//     res.json({ result, detail });
//   } catch (e:any) {
//     res.status(500).json({ error: String(e?.message || e) });
//   }
// });

// const PORT = process.env.PORT || 4000;
// app.listen(PORT, () => {
//   console.log(`Rule-builder server listening on http://localhost:${PORT}`);
// });
