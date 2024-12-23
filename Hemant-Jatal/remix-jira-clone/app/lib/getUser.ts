import { getSession } from "~/lib/session.server";

export const getUser = async (request: Request) => {
  const session = await getSession(request.headers.get("Cookie"));
  return session.data;
};
