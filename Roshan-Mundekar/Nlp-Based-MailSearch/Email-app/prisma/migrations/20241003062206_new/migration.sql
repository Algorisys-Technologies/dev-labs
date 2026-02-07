/*
  Warnings:

  - You are about to drop the column `accountId` on the `Email` table. All the data in the column will be lost.
  - You are about to drop the `EmailAccount` table. If the table is not empty, all the data it contains will be lost.

*/
-- DropForeignKey
ALTER TABLE "Email" DROP CONSTRAINT "Email_accountId_fkey";

-- AlterTable
ALTER TABLE "Email" DROP COLUMN "accountId";

-- DropTable
DROP TABLE "EmailAccount";
