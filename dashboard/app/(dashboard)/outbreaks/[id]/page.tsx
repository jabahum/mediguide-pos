import { OutbreakEditor } from "../outbreak-editor"

export default async function OutbreakWorkspacePage({ params }: { params: Promise<{ id: string }> }) {
  const { id } = await params
  return <OutbreakEditor id={id} />
}
