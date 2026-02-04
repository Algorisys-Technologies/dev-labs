/*
  Warnings:

  - You are about to alter the column `email` on the `account` table. The data in that column could be lost. The data in that column will be cast from `Text` to `VarChar(255)`.
  - You are about to drop the column `createdAt` on the `enron_emaildataset` table. All the data in the column will be lost.

*/
-- AlterTable
ALTER TABLE "account" ALTER COLUMN "email" DROP NOT NULL,
ALTER COLUMN "email" SET DATA TYPE VARCHAR(255);

-- AlterTable
ALTER TABLE "enron_emaildataset" DROP COLUMN "createdAt",
ADD COLUMN     "createdat" TIMESTAMP(6) DEFAULT CURRENT_TIMESTAMP,
ALTER COLUMN "date" SET DATA TYPE TIMESTAMP(6),
ALTER COLUMN "status" DROP NOT NULL;

-- CreateTable
CREATE TABLE "body_embedding_data" (
    "id" INTEGER,
    "body_embeddings_bin" BYTEA
);

-- CreateTable
CREATE TABLE "subject_embedding_data" (
    "id" INTEGER,
    "subject_embeddings_bin" BYTEA
);

-- AddForeignKey
ALTER TABLE "body_embedding_data" ADD CONSTRAINT "body_embedding_data_id_fkey" FOREIGN KEY ("id") REFERENCES "enron_emaildataset"("id") ON DELETE CASCADE ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE "subject_embedding_data" ADD CONSTRAINT "subject_embedding_data_id_fkey" FOREIGN KEY ("id") REFERENCES "enron_emaildataset"("id") ON DELETE CASCADE ON UPDATE NO ACTION;
