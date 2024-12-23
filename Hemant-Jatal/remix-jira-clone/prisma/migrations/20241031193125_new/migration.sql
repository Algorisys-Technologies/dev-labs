-- CreateEnum
CREATE TYPE "Provider" AS ENUM ('google', 'github', 'form');

-- AlterTable
ALTER TABLE "User" ADD COLUMN     "provider" "Provider" NOT NULL DEFAULT 'form';
