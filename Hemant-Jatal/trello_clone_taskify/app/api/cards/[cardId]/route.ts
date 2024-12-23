import { auth } from "@clerk/nextjs/server";
import { NextResponse } from "next/server";
import { db } from "@/lib/db";

export async function GET(
  req: Request,
  { params }: { params: { cardId: string } }
) {
  try {
    const { userId, orgId } = auth();

    if (!userId || !orgId) {
      return new NextResponse("Unauthorized", { status: 401 });
    }

    const card = await db.card.findFirst({
      where: {
        id: params.cardId,
        list: {
          board: {
            orgId, // Filter on orgId
          },
        },
      },
      include: {
        list: {
          select: {
            title: true, // Include list title
          },
        },
      },
    });

    if (!card) {
      return new NextResponse("Card not found", { status: 404 });
    }

    return NextResponse.json(card);
  } catch (error) {
    console.error("Error fetching card:", error); // Error logging
    return new NextResponse("Internal Error", { status: 500 });
  }
}
