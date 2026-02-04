/*
  Warnings:

  - You are about to drop the column `attachments` on the `Email` table. All the data in the column will be lost.
  - You are about to drop the column `createdAt` on the `Email` table. All the data in the column will be lost.
  - Made the column `subject` on table `Email` required. This step will fail if there are existing NULL values in that column.
  - Made the column `bodyText` on table `Email` required. This step will fail if there are existing NULL values in that column.

*/
-- AlterTable
ALTER TABLE "Email" DROP COLUMN "attachments",
DROP COLUMN "createdAt",
ADD COLUMN     "bodyHtml" TEXT,
ALTER COLUMN "subject" SET NOT NULL,
ALTER COLUMN "bodyText" SET NOT NULL;

-- CreateTable
CREATE TABLE "Attachment" (
    "id" SERIAL NOT NULL,
    "emailId" INTEGER NOT NULL,
    "filename" TEXT NOT NULL,
    "partID" TEXT NOT NULL,

    CONSTRAINT "Attachment_pkey" PRIMARY KEY ("id")
);

-- AddForeignKey
ALTER TABLE "Attachment" ADD CONSTRAINT "Attachment_emailId_fkey" FOREIGN KEY ("emailId") REFERENCES "Email"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
