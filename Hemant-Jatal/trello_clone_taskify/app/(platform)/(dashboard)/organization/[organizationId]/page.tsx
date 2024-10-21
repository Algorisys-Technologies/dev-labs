import { Suspense } from "react";

import { Separator } from "@/components/ui/separator";

import { BoardList } from "./_components/board-list";

const OrganizationIdPage = async () => {
  return (
    <div className="w-full mb-20">
      <Separator className="my-4" />
      <div className="px-2 md:px-4">
        <Suspense fallback={<BoardList.Skeleton />}>
          <BoardList />
        </Suspense>
      </div>
    </div>
  );
};

export default OrganizationIdPage;
