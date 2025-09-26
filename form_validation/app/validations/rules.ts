export type ValidationRule = {
  rule: (value: string, values?: Record<string, string>) => boolean;
  message: string;
};

export const required: ValidationRule = {
  rule: (v) => v.trim().length > 0,
  message: "This field is required",
};

export const email: ValidationRule = {
  rule: (v) => /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(v),
  message: "Invalid email address",
};

export const minLength = (len: number): ValidationRule => ({
  rule: (v) => v.length >= len,
  message: `Must be at least ${len} characters`,
});

export const isNumber: ValidationRule = {
  rule: (v) => !isNaN(Number(v)),
  message: "Must be a number",
};

export const pattern = (patt: RegExp): ValidationRule => ({
  rule: (v) => patt.test(v),
  message: `Invalid data format`,
});
