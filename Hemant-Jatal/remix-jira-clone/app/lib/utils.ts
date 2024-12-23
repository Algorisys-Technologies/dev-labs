import { clsx, type ClassValue } from "clsx";
import { twMerge } from "tailwind-merge";

export function cn(...inputs: ClassValue[]) {
  return twMerge(clsx(inputs));
}

export function validateInput(error) {
  // Convert ZodError into an object with field-specific error messages
  const errorMessages = error.errors.reduce(
    (acc: Record<string, string>, err) => {
      acc[err.path[0]] = err.message;
      return acc;
    },
    {}
  );

  return { success: false, errors: errorMessages };
}
