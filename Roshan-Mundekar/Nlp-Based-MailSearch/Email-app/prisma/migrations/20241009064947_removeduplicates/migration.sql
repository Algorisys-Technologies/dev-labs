/*
  Warnings:

  - A unique constraint covering the columns `[subject,date,to,from,bodyText]` on the table `Email` will be added. If there are existing duplicate values, this will fail.

*/
-- CreateIndex
CREATE UNIQUE INDEX "Email_subject_date_to_from_bodyText_key" ON "Email"("subject", "date", "to", "from", "bodyText");
