import type { FieldConfig } from "./config";

export function validateFields(
  values: Record<string, string>,
  fieldConfigs: FieldConfig[]
): Record<string, string> {
  const errors: Record<string, string> = {};

  for (const field of fieldConfigs) {
    const value = values[field.name] || "";
    for (const rule of field.validations) {
      if (!rule.rule(value, values)) {
        errors[field.name] = `${field.label}: ${rule.message}`;
        break; // stop at first error for this field
      }
    }
  }

  // ✅ Cross-field validation
  if (values.password && values.confirmPassword && values.password !== values.confirmPassword) {
    errors.confirmPassword = "Confirm Password must match Password";
  }

  return errors;
}
