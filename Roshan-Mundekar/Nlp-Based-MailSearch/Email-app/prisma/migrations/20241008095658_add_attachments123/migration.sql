/*
  Warnings:

  - You are about to drop the column `bodyHtml` on the `Email` table. All the data in the column will be lost.
  - You are about to drop the `Attachment` table. If the table is not empty, all the data it contains will be lost.

*/
-- DropForeignKey
ALTER TABLE "Attachment" DROP CONSTRAINT "Attachment_emailId_fkey";

-- AlterTable
ALTER TABLE "Email" DROP COLUMN "bodyHtml",
ADD COLUMN     "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
ALTER COLUMN "subject" DROP NOT NULL,
ALTER COLUMN "bodyText" DROP NOT NULL;

-- DropTable
DROP TABLE "Attachment";
