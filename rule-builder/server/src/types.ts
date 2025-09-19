export type Operator = ">" | "<" | "=" | "!=" | "contains";

export interface Condition {
  field: string;
  operator: Operator;
  value: any;
}

export interface RuleGroup {
  id: string;
  type: "AND" | "OR" | "NOT" | "XOR";
  conditions: Condition[];
  groups: RuleGroup[];
}

export interface ReturnValueSpec {
  type: "constant" | "object" | "property" | "expression";
  value: any;
}

export interface Rule {
  id: string;
  name: string;
  groups: RuleGroup[];
  successValue?: ReturnValueSpec;
  failureValue?: ReturnValueSpec;
}
