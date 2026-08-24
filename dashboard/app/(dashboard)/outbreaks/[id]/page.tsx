import { OutbreakEditor } from "../outbreak-editor"

export default async function OutbreakWorkspacePage({ params, searchParams }: { params: Promise<{ id: string }>; searchParams: Promise<{ document?: string }> }) {
  const [{ id }, query] = await Promise.all([params, searchParams])
  return <OutbreakEditor id={id} initialDocumentId={query.document} />
}
