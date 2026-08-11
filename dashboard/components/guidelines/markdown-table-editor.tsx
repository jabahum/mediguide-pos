"use client"

import * as React from "react"
import { ArrowDown, ArrowLeft, ArrowRight, ArrowUp, Download, Minus, Plus, Upload } from "lucide-react"

import { Alert, AlertDescription, AlertTitle } from "@/components/ui/alert"
import { Button } from "@/components/ui/button"
import { Dialog, DialogContent, DialogDescription, DialogFooter, DialogHeader, DialogTitle } from "@/components/ui/dialog"
import { Input } from "@/components/ui/input"
import { Label } from "@/components/ui/label"
import { Textarea } from "@/components/ui/textarea"
import { emptyMarkdownTable, MarkdownTableModel, parseDelimitedTable, serializeMarkdownTable, tableToCsv, tableWarnings, type TableAlignment } from "./markdown-table"

interface MarkdownTableEditorProps {
  open: boolean
  initialTable?: MarkdownTableModel
  onOpenChange: (open: boolean) => void
  onApply: (markdown: string) => void
}

export function MarkdownTableEditor({ open, initialTable, onOpenChange, onApply }: MarkdownTableEditorProps) {
  const [table, setTable] = React.useState<MarkdownTableModel>(() => initialTable || emptyMarkdownTable())
  const [paste, setPaste] = React.useState("")
  const csvRef = React.useRef<HTMLInputElement>(null)
  React.useEffect(() => { if (open) { setTable(initialTable || emptyMarkdownTable()); setPaste("") } }, [initialTable, open])
  const warnings = tableWarnings(table)
  const updateCell = (row: number, column: number, value: string) => setTable((current) => ({ ...current, rows: current.rows.map((cells, index) => index === row ? cells.map((cell, cellIndex) => cellIndex === column ? value : cell) : cells) }))
  const updateHeader = (column: number, value: string) => setTable((current) => ({ ...current, headers: current.headers.map((header, index) => index === column ? value : header) }))
  const moveRow = (index: number, direction: -1 | 1) => setTable((current) => ({ ...current, rows: move(current.rows, index, index + direction) }))
  const moveColumn = (index: number, direction: -1 | 1) => setTable((current) => ({ ...current, headers: move(current.headers, index, index + direction), alignments: move(current.alignments, index, index + direction), rows: current.rows.map((row) => move(row, index, index + direction)) }))
  const importRows = (raw: string) => {
    const rows = parseDelimitedTable(raw)
    if (!rows.length) return
    const width = Math.max(...rows.map((row) => row.length))
    setTable((current) => ({ ...current, headers: normalize(rows[0], width), alignments: Array(width).fill("none"), rows: rows.length > 1 ? rows.slice(1).map((row) => normalize(row, width)) : [Array(width).fill("")], structuralWarnings: rows.flatMap((row, index) => row.length === width ? [] : [`Imported row ${index + 1} has ${row.length} cells; expected ${width}.`]) }))
  }
  return <Dialog open={open} onOpenChange={onOpenChange}>
    <DialogContent className="max-h-[92vh] max-w-6xl overflow-y-auto">
      <DialogHeader><DialogTitle>Visual Markdown table editor</DialogTitle><DialogDescription>Changes are written back as portable GFM Markdown. Clinical values and units are never corrected automatically.</DialogDescription></DialogHeader>
      <div className="grid gap-4 md:grid-cols-3">
        <div><Label htmlFor="table-title">Table title</Label><Input id="table-title" value={table.title} onChange={(event) => setTable({ ...table, title: event.target.value })} /></div>
        <div><Label htmlFor="table-caption">Caption</Label><Input id="table-caption" value={table.caption} onChange={(event) => setTable({ ...table, caption: event.target.value })} /></div>
        <div><Label htmlFor="table-source">Source</Label><Input id="table-source" value={table.source} onChange={(event) => setTable({ ...table, source: event.target.value })} /></div>
      </div>
      <label className="flex items-center gap-2 text-sm"><input type="checkbox" checked={table.clinicallySensitive} onChange={(event) => setTable({ ...table, clinicallySensitive: event.target.checked })} />Clinically sensitive table requiring explicit review</label>
      <div className="overflow-x-auto rounded border">
        <table className="w-full min-w-[640px] border-collapse text-sm"><thead><tr><th className="w-24 border p-2">Row</th>{table.headers.map((header, column) => <th key={column} className="min-w-40 border p-2"><Input aria-label={`Column ${column + 1} header`} value={header} onChange={(event) => updateHeader(column, event.target.value)} /><div className="mt-2 flex items-center gap-1"><select aria-label={`Column ${column + 1} alignment`} className="h-8 flex-1 rounded border bg-background px-2" value={table.alignments[column]} onChange={(event) => setTable((current) => ({ ...current, alignments: current.alignments.map((value, index) => index === column ? event.target.value as TableAlignment : value) }))}><option value="none">Default</option><option value="left">Left</option><option value="center">Center</option><option value="right">Right</option></select><IconButton label="Move column left" disabled={column === 0} onClick={() => moveColumn(column, -1)}><ArrowLeft /></IconButton><IconButton label="Move column right" disabled={column === table.headers.length - 1} onClick={() => moveColumn(column, 1)}><ArrowRight /></IconButton><IconButton label="Remove column" disabled={table.headers.length === 1} onClick={() => setTable((current) => ({ ...current, headers: remove(current.headers, column), alignments: remove(current.alignments, column), rows: current.rows.map((row) => remove(row, column)) }))}><Minus /></IconButton></div></th>)}</tr></thead>
          <tbody>{table.rows.map((row, rowIndex) => <tr key={rowIndex}><th className="border p-2"><div className="flex justify-center gap-1"><IconButton label="Move row up" disabled={rowIndex === 0} onClick={() => moveRow(rowIndex, -1)}><ArrowUp /></IconButton><IconButton label="Move row down" disabled={rowIndex === table.rows.length - 1} onClick={() => moveRow(rowIndex, 1)}><ArrowDown /></IconButton><IconButton label="Remove row" disabled={table.rows.length === 1} onClick={() => setTable((current) => ({ ...current, rows: remove(current.rows, rowIndex) }))}><Minus /></IconButton></div></th>{row.map((cell, column) => <td key={column} className="border p-2"><Textarea aria-label={`Row ${rowIndex + 1}, ${table.headers[column] || `column ${column + 1}`}`} rows={2} value={cell} onChange={(event) => updateCell(rowIndex, column, event.target.value)} /></td>)}</tr>)}</tbody></table>
      </div>
      <div className="flex flex-wrap gap-2"><Button variant="outline" onClick={() => setTable((current) => ({ ...current, rows: [...current.rows, Array(current.headers.length).fill("")] }))}><Plus className="mr-2 h-4 w-4" />Add row</Button><Button variant="outline" onClick={() => setTable((current) => ({ ...current, headers: [...current.headers, `Column ${current.headers.length + 1}`], alignments: [...current.alignments, "none"], rows: current.rows.map((row) => [...row, ""]) }))}><Plus className="mr-2 h-4 w-4" />Add column</Button><Button variant="outline" onClick={() => csvRef.current?.click()}><Upload className="mr-2 h-4 w-4" />Import CSV</Button><Button variant="outline" onClick={() => downloadCsv(table)}><Download className="mr-2 h-4 w-4" />Export CSV</Button><input ref={csvRef} className="hidden" type="file" accept=".csv,text/csv,text/tab-separated-values" onChange={async (event) => { const file = event.target.files?.[0]; if (file) importRows(await file.text()); event.target.value = "" }} /></div>
      <div><Label htmlFor="paste-table">Paste spreadsheet cells</Label><div className="flex gap-2"><Textarea id="paste-table" rows={3} value={paste} onChange={(event) => setPaste(event.target.value)} placeholder="Paste tab-separated cells or CSV" /><Button variant="outline" disabled={!paste.trim()} onClick={() => importRows(paste)}>Import</Button></div></div>
      <div><Label htmlFor="table-footnotes">Footnotes (one per line)</Label><Textarea id="table-footnotes" rows={3} value={table.footnotes.join("\n")} onChange={(event) => setTable({ ...table, footnotes: event.target.value.split("\n") })} /></div>
      {warnings.length > 0 && <Alert variant="destructive"><AlertTitle>Review table values</AlertTitle><AlertDescription><ul className="list-disc pl-5">{warnings.map((warning) => <li key={warning}>{warning}</li>)}</ul></AlertDescription></Alert>}
      <div><Label>Rendered preview</Label><div className="mt-2 overflow-x-auto rounded border p-4">{table.title && <strong>{table.title}</strong>}<table className="mt-2 w-full border-collapse text-sm"><thead><tr>{table.headers.map((header, index) => <th key={index} className="border bg-muted p-2" style={{ textAlign: alignment(table.alignments[index]) }}>{header}</th>)}</tr></thead><tbody>{table.rows.map((row, rowIndex) => <tr key={rowIndex}>{row.map((cell, index) => <td key={index} className="border p-2" style={{ textAlign: alignment(table.alignments[index]) }}>{cell}</td>)}</tr>)}</tbody></table>{table.caption && <p className="mt-2 text-sm">{table.caption}</p>}{table.source && <p className="text-xs text-muted-foreground">Source: {table.source}</p>}</div></div>
      <DialogFooter><Button variant="outline" onClick={() => onOpenChange(false)}>Cancel</Button><Button disabled={!table.headers.length} onClick={() => { onApply(serializeMarkdownTable(table)); onOpenChange(false) }}>Update Markdown source</Button></DialogFooter>
    </DialogContent>
  </Dialog>
}

function IconButton({ label, disabled, onClick, children }: { label: string; disabled?: boolean; onClick: () => void; children: React.ReactElement<{ className?: string }> }) { return <Button type="button" variant="ghost" size="icon" aria-label={label} title={label} disabled={disabled} onClick={onClick}>{React.cloneElement(children, { className: "h-3.5 w-3.5" })}</Button> }
function move<T>(items: T[], from: number, to: number) { if (to < 0 || to >= items.length || from === to) return items; const result = [...items]; const [item] = result.splice(from, 1); result.splice(to, 0, item); return result }
function remove<T>(items: T[], index: number) { return items.filter((_, itemIndex) => itemIndex !== index) }
function normalize(values: string[], width: number) { return Array.from({ length: width }, (_, index) => values[index] || "") }
function alignment(value?: TableAlignment): React.CSSProperties["textAlign"] { return value === "center" || value === "right" ? value : "left" }
function downloadCsv(table: MarkdownTableModel) { const blob = new Blob([tableToCsv(table)], { type: "text/csv;charset=utf-8" }); const url = URL.createObjectURL(blob); const anchor = document.createElement("a"); anchor.href = url; anchor.download = "guideline-table.csv"; anchor.click(); URL.revokeObjectURL(url) }
