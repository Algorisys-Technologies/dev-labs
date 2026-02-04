/*
  Warnings:

  - You are about to drop the `Email` table. If the table is not empty, all the data it contains will be lost.

*/
-- DropTable
DROP TABLE "Email";

-- CreateTable
CREATE TABLE "EnronEmailDataset" (
    "id" SERIAL NOT NULL,
    "from" VARCHAR(100),
    "to" TEXT,
    "date" TIMESTAMP(3),
    "subject" TEXT,
    "body_text" TEXT,
    "status" VARCHAR(50) NOT NULL DEFAULT 'unseen',
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "emailid" INTEGER,
    "attachments" JSONB,

    CONSTRAINT "EnronEmailDataset_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "SubjectEmbeddingData" (
    "id" INTEGER NOT NULL,
    "subject_embeddings_bin" BYTEA,

    CONSTRAINT "SubjectEmbeddingData_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "BodyEmbeddingData" (
    "id" INTEGER NOT NULL,
    "body_embeddings_bin" BYTEA,

    CONSTRAINT "BodyEmbeddingData_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "EnronEmailDataset_subject_date_to_from_body_text_key" ON "EnronEmailDataset"("subject", "date", "to", "from", "body_text");

-- AddForeignKey
ALTER TABLE "SubjectEmbeddingData" ADD CONSTRAINT "SubjectEmbeddingData_id_fkey" FOREIGN KEY ("id") REFERENCES "EnronEmailDataset"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "BodyEmbeddingData" ADD CONSTRAINT "BodyEmbeddingData_id_fkey" FOREIGN KEY ("id") REFERENCES "EnronEmailDataset"("id") ON DELETE CASCADE ON UPDATE CASCADE;
