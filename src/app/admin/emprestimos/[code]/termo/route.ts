import { redirect } from "next/navigation";
import { getAdminLoanTermFile } from "../../../../../lib/loans/admin-server";

type RouteContext = {
  params: Promise<{ code: string }>;
};

export async function GET(_request: Request, context: RouteContext) {
  const { code } = await context.params;
  const result = await getAdminLoanTermFile(code);

  if (result.kind === "unauthenticated") redirect("/admin/entrar");

  if (result.kind !== "ready") {
    return new Response("Termo não encontrado.", {
      status: 404,
      headers: { "content-type": "text/plain; charset=utf-8" },
    });
  }

  return new Response(result.bytes, {
    status: 200,
    headers: {
      "content-type": "application/pdf",
      "content-disposition": `attachment; filename="${result.fileName}"`,
      "cache-control": "private, no-store",
    },
  });
}
