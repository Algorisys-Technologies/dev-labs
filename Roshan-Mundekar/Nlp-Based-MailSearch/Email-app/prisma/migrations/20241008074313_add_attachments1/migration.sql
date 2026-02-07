/*
  Warnings:

  - You are about to drop the `Attachment` table. If the table is not empty, all the data it contains will be lost.

*/
-- DropForeignKey
ALTER TABLE "Attachment" DROP CONSTRAINT "Attachment_emailId_fkey";

-- AlterTable
ALTER TABLE "Email" ADD COLUMN     "attachments" TEXT[];

-- DropTable
DROP TABLE "Attachment";
