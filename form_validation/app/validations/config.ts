import { required, email, minLength, isNumber, pattern, type ValidationRule } from "./rules";

export type FieldConfig = {
  name: string;
  label: string;
  validations: ValidationRule[];
};

export const formFields: FieldConfig[] = [
  { name: "name", label: "Name", validations: [required] },
  { name: "email", label: "Email", validations: [required, pattern(/^[^\s@]+@[^\s@]+\.[^\s@]+$/)] },
  { name: "password", label: "Password", validations: [required, minLength(6)] },
  { name: "age", label: "Age", validations: [required, isNumber] },
  {
    name: "confirmPassword",
    label: "Confirm Password",
    validations: [required], // password match handled separately
  },
];
