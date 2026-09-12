import { ContentHubEditor } from "../content-hub-editor";
export default async function ContentHubPage({
  params,
}: {
  params: Promise<{ id: string }>;
}) {
  const { id } = await params;
  return <ContentHubEditor id={id} />;
}
