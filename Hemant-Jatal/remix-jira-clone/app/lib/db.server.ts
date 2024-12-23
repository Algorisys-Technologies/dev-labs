import { PrismaClient } from "@prisma/client";

let db: PrismaClient;

try {
  db = new PrismaClient();
  db.$connect();
} catch (error) {
  console.error(error);
}

process.on("beforeExit", async () => {
  await db.$disconnect();
});

export { db };
