/*
  Warnings:

  - Made the column `subject` on table `Email` required. This step will fail if there are existing NULL values in that column.
  - Made the column `bodyText` on table `Email` required. This step will fail if there are existing NULL values in that column.

*/
-- AlterTable
ALTER TABLE "Email" ALTER COLUMN "subject" SET NOT NULL,
ALTER COLUMN "bodyText" SET NOT NULL;
