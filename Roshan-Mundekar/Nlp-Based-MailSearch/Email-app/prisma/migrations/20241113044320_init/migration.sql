-- CreateTable
CREATE TABLE "enron_emaildataset" (
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

    CONSTRAINT "enron_emaildataset_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "enron_emaildataset_subject_date_to_from_body_text_key" ON "enron_emaildataset"("subject", "date", "to", "from", "body_text");
