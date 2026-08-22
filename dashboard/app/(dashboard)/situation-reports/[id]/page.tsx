import { SituationReportEditor } from "../situation-report-editor"
export default async function SituationReportPage({ params }: { params: Promise<{ id: string }> }) { const { id } = await params; return <SituationReportEditor id={id} /> }
