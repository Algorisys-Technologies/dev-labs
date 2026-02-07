import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

export async function truncateEmails() {
  try {
    // Execute raw SQL to truncate the Email table
    await prisma.$executeRaw`TRUNCATE TABLE "Email" RESTART IDENTITY CASCADE`;
    console.log('Email table truncated successfully.');
  } catch (error) {
    console.error('Error truncating Email table:', error);
  } finally {
    await prisma.$disconnect(); // Always disconnect from the database after operations
  }
}
