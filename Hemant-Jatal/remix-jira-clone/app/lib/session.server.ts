import { createCookieSessionStorage } from "@remix-run/node";

export const sessionStorage = createCookieSessionStorage({
  cookie: {
    name: "_session",
    httpOnly: true,
    sameSite: "lax",
    path: "/",
    secrets: ["secret"],
    secure: process.env.NODE_ENV == "production",
  },
});

export const { getSession, commitSession, destroySession } = sessionStorage;
