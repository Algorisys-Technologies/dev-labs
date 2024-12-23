import type { ActionFunctionArgs, MetaFunction } from "@remix-run/node";
import { Form } from "@remix-run/react";
import { loginAuthenticator } from "~/lib/auth.server";

export const meta: MetaFunction = () => {
  return [
    { title: "New Remix App" },
    { name: "description", content: "Welcome to Remix!" },
  ];
};

export async function action({ request }: ActionFunctionArgs) {
  const form = await request.formData();
  const action = form.get("action");

  switch (action) {
    case "logout": {
      return loginAuthenticator.logout(request, { redirectTo: "/sign-in" });
    }
  }
}

export default function Index() {
  return (
    <Form method="POST">
      <button
        name="action"
        value="logout"
        className="bg-red-700 text-white font-bold p-2 rounded-xl"
      >
        Signout
      </button>
    </Form>
  );
}
