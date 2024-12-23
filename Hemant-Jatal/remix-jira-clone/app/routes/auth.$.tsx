import { ActionFunctionArgs } from "@remix-run/node";
import { gitHubAuthenticator, googleAuthenticator } from "~/lib/oAuth.server";

export async function loader({ params, request }: ActionFunctionArgs) {
  const value = params["*"];
  switch (value) {
    case "github": {
      return gitHubAuthenticator.authenticate("github", request, {
        successRedirect: "/",
        failureRedirect: "/sign-in",
      });
    }
    case "github/callback": {
      return gitHubAuthenticator.authenticate("github", request, {
        successRedirect: "/",
        failureRedirect: "/sign-in",
      });
    }
    case "google": {
      return googleAuthenticator.authenticate("google", request, {
        successRedirect: "/",
        failureRedirect: "/sign-in",
      });
    }
    case "google/callback": {
      return googleAuthenticator.authenticate("google", request, {
        successRedirect: "/",
        failureRedirect: "/sign-in",
      });
    }
  }
}
