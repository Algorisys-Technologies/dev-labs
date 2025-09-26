import { Form, useActionData } from "react-router-dom";
import { useFormValidation } from "../hooks/use-form-validation";
import { formFields } from "../validations/config";
import { validateFields } from "../validations/validate";
import FormField from "../components/form-field";

export async function action({ request }: { request: Request }) {
  const formData = await request.formData();
  const values = Object.fromEntries(formData) as Record<string, string>;

  const errors = validateFields(values, formFields);

  // server-only rule
  if (values.email === "taken@example.com") {
    errors.email = "Email is already registered (server check)";
  }

  if (Object.keys(errors).length > 0) {
    return { ok: false, errors };
  }

  return { ok: true };
}

export default function FormPage() {
  const { values, errors, handleChange, validateAll, setErrors } =
    useFormValidation(formFields);

  const actionData = useActionData() as { ok: boolean; errors?: any } | undefined;

  // set server errors
  if (actionData?.errors) {
    setErrors(actionData.errors);
  }

  return (
    <div className="max-w-md mx-auto p-6">
      <h1 className="text-2xl font-bold mb-6">Dynamic Form</h1>
      <Form
        method="post"
        replace
        onSubmit={(e) => {
          if (!validateAll()) e.preventDefault();
        }}
        noValidate
      >
        {formFields.map((field) => (
          <FormField
            key={field.name}
            label={field.label}
            name={field.name}
            value={values[field.name] || ""}
            error={errors[field.name]}
            onChange={handleChange}
            type={field.name.toLowerCase().includes("password") ? "password" : "text"}
          />
        ))}

        <button
          type="submit"
          className="bg-blue-600 text-white py-2 px-4 rounded"
        >
          Submit
        </button>
      </Form>

      {actionData?.ok && (
        <p className="mt-4 text-green-600">Form submitted successfully!</p>
      )}
    </div>
  );
}
