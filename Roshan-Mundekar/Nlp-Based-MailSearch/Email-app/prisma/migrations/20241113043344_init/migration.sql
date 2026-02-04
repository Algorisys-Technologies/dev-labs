/*
  Warnings:

  - You are about to drop the `Account` table. If the table is not empty, all the data it contains will be lost.
  - You are about to drop the `BodyEmbeddingData` table. If the table is not empty, all the data it contains will be lost.
  - You are about to drop the `EnronEmailDataset` table. If the table is not empty, all the data it contains will be lost.
  - You are about to drop the `SubjectEmbeddingData` table. If the table is not empty, all the data it contains will be lost.

*/
-- DropForeignKey
ALTER TABLE "BodyEmbeddingData" DROP CONSTRAINT "BodyEmbeddingData_id_fkey";

-- DropForeignKey
ALTER TABLE "SubjectEmbeddingData" DROP CONSTRAINT "SubjectEmbeddingData_id_fkey";

-- DropTable
DROP TABLE "Account";

-- DropTable
DROP TABLE "BodyEmbeddingData";

-- DropTable
DROP TABLE "EnronEmailDataset";

-- DropTable
DROP TABLE "SubjectEmbeddingData";

-- CreateTable
CREATE TABLE "account" (
    "id" SERIAL NOT NULL,
    "email" TEXT NOT NULL,

    CONSTRAINT "account_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "account_email_key" ON "account"("email");
