import { Suspense } from "react";
import {
  EquipmentDetail,
  PublicAvailabilityLoading,
} from "../../_components/public-equipment";

type PageParameters = {
  params: Promise<{ code: string }>;
};

export default function EquipmentPage({ params }: PageParameters) {
  return (
    <Suspense fallback={<PublicAvailabilityLoading />}>
      <ResolvedEquipmentPage params={params} />
    </Suspense>
  );
}

async function ResolvedEquipmentPage({ params }: PageParameters) {
  const { code } = await params;
  return <EquipmentDetail key={code} code={code} />;
}
