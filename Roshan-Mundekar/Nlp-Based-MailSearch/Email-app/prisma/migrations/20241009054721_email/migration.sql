/*
  Warnings:

  - Added the required column `accountName` to the `Email` table without a default value. This is not possible if the table is not empty.

*/
-- AlterTable
ALTER TABLE "Email" ADD COLUMN     "accountName" TEXT NOT NULL;
