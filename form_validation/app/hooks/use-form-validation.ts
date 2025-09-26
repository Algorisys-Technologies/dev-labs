import { useState } from "react";
import type { FieldConfig } from "../validations/config";
import { validateFields } from "../validations/validate";

export function useFormValidation(fieldConfigs: FieldConfig[]) {
  const initialValues = fieldConfigs.reduce<Record<string, string>>(
    (acc, f) => ({ ...acc, [f.name]: "" }),
    {}
  );

  const [values, setValues] = useState(initialValues);
  const [errors, setErrors] = useState<Record<string, string>>({});

  const handleChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const { name, value } = e.target;
    const newValues = { ...values, [name]: value };
    setValues(newValues);

    // validate field immediately
    const newErrors = validateFields(newValues, fieldConfigs);
    setErrors(newErrors);
  };

  const validateAll = (): boolean => {
    const newErrors = validateFields(values, fieldConfigs);
    setErrors(newErrors);
    return Object.keys(newErrors).length === 0;
  };

  return { values, errors, handleChange, validateAll, setErrors };
}
