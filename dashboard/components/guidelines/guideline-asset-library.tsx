"use client"
/* eslint-disable @next/next/no-img-element -- asset URLs are short-lived signed URLs with dynamic hosts */

import * as React from "react"
import { ImagePlus, Pencil, RefreshCw, Trash2 } from "lucide-react"

import { Alert, AlertDescription, AlertTitle } from "@/components/ui/alert"
import { Badge } from "@/components/ui/badge"
import { Button } from "@/components/ui/button"
import { Dialog, DialogContent, DialogDescription, DialogFooter, DialogHeader, DialogTitle } from "@/components/ui/dialog"
import { Input } from "@/components/ui/input"
import { Label } from "@/components/ui/label"
import { ScrollArea } from "@/components/ui/scroll-area"
import { GuidelineAsset, GuidelineAssetMetadata, GuidelineAssetsService } from "@/services/guideline-assets.service"
import { showToast } from "@/lib/toast"

interface GuidelineAssetLibraryProps {
  open: boolean
  versionId: string
  editable: boolean
  onOpenChange: (open: boolean) => void
  onInsert: (asset: GuidelineAsset) => void
  onAssetsChange: (assets: GuidelineAsset[]) => void
  onReplaceReference: (oldReference: string, replacement: GuidelineAsset) => void
}

const emptyMetadata: GuidelineAssetMetadata = { alternative_text: "", caption: "", source: "", attribution: "", license: "", clinically_sensitive: false }

export function GuidelineAssetLibrary({ open, versionId, editable, onOpenChange, onInsert, onAssetsChange, onReplaceReference }: GuidelineAssetLibraryProps) {
  const [assets, setAssets] = React.useState<GuidelineAsset[]>([])
  const [broken, setBroken] = React.useState<string[]>([])
  const [loading, setLoading] = React.useState(false)
  const [pendingFile, setPendingFile] = React.useState<File | null>(null)
  const [replacing, setReplacing] = React.useState<GuidelineAsset | null>(null)
  const [editing, setEditing] = React.useState<GuidelineAsset | null>(null)
  const [metadata, setMetadata] = React.useState<GuidelineAssetMetadata>(emptyMetadata)
  const inputRef = React.useRef<HTMLInputElement>(null)

  const load = React.useCallback(async () => {
    setLoading(true)
    try { const result = await GuidelineAssetsService.list(versionId); setAssets(result.items); setBroken(result.broken_references); onAssetsChange(result.items) }
    catch (error) { showToast.error("Assets unavailable", error instanceof Error ? error.message : "Could not load guideline assets") }
    finally { setLoading(false) }
  }, [onAssetsChange, versionId])
  React.useEffect(() => { if (open) void load() }, [load, open])

  const choose = (file: File, replacement?: GuidelineAsset | null) => {
    if (!/^image\/(png|jpeg|gif|webp)$/u.test(file.type) || file.name.toLowerCase().endsWith(".svg")) { showToast.error("Unsupported image", "Use PNG, JPEG, GIF or WebP. SVG files are rejected."); return }
    if (file.size > 10 * 1024 * 1024) { showToast.error("Image too large", "Guideline images may not exceed 10 MB."); return }
    const target = replacement === undefined ? replacing : replacement
    setPendingFile(file); setReplacing(target || null); setMetadata(target ? metadataFrom(target) : emptyMetadata)
  }
  const upload = async () => {
    if (!pendingFile) return
    try {
      const created = await GuidelineAssetsService.upload(versionId, pendingFile, metadata)
      if (replacing) onReplaceReference(replacing.reference, created)
      await load(); setPendingFile(null); setReplacing(null)
      showToast.success(replacing ? "Replacement uploaded" : "Image uploaded", replacing ? "The Markdown reference was updated; the old asset remains available until explicitly removed." : "The image is ready to insert.")
    } catch (error) { showToast.error("Upload failed", error instanceof Error ? error.message : "Could not upload image") }
  }
  const saveMetadata = async () => {
    if (!editing) return
    try { await GuidelineAssetsService.update(versionId, editing.id, metadata); setEditing(null); await load(); showToast.success("Asset updated", "Metadata changes require review before publication.") }
    catch (error) { showToast.error("Update failed", error instanceof Error ? error.message : "Could not update asset") }
  }
  const remove = async (asset: GuidelineAsset) => {
    if (asset.referenced || !window.confirm(`Remove ${asset.original_filename}? The stored object is retained for immutable historical revisions.`)) return
    try { await GuidelineAssetsService.remove(versionId, asset.id); await load(); showToast.success("Asset removed", "The asset is no longer available to this draft.") }
    catch (error) { showToast.error("Removal failed", error instanceof Error ? error.message : "Could not remove asset") }
  }

  return <>
    <Dialog open={open} onOpenChange={onOpenChange}><DialogContent className="max-w-5xl"><DialogHeader><DialogTitle>Guideline asset library</DialogTitle><DialogDescription>Images are private, version-scoped and served through short-lived links. Object-storage keys are never exposed.</DialogDescription></DialogHeader>
      {broken.length > 0 && <Alert variant="destructive"><AlertTitle>Broken image references</AlertTitle><AlertDescription>{broken.map((id) => <code key={id} className="mr-2">{id}</code>)}</AlertDescription></Alert>}
      {editable && <div tabIndex={0} className="rounded-lg border-2 border-dashed p-6 text-center" onDragOver={(event) => event.preventDefault()} onDrop={(event) => { event.preventDefault(); const file = event.dataTransfer.files[0]; if (file) choose(file, null) }} onPaste={(event) => { const item = [...event.clipboardData.items].find((value) => value.type.startsWith("image/")); const file = item?.getAsFile(); if (file) choose(new File([file], `clipboard-${Date.now()}.png`, { type: file.type }), null) }}><ImagePlus className="mx-auto h-7 w-7" /><p className="mt-2 text-sm">Drop or paste an image here, or choose a file.</p><Button className="mt-3" variant="outline" onClick={() => { setReplacing(null); inputRef.current?.click() }}>Choose image</Button><input ref={inputRef} className="hidden" type="file" accept="image/png,image/jpeg,image/gif,image/webp" onChange={(event) => { const file = event.target.files?.[0]; if (file) choose(file); event.target.value = "" }} /></div>}
      <ScrollArea className="max-h-[55vh]"><div className="grid gap-3 pr-3 sm:grid-cols-2">{loading && <p className="text-sm text-muted-foreground">Loading assets…</p>}{assets.map((asset) => <article key={asset.id} className="overflow-hidden rounded-lg border"><div className="aspect-video bg-muted"><img className="h-full w-full object-contain" src={asset.url} alt={asset.alternative_text || "Unlabelled guideline asset"} /></div><div className="space-y-2 p-3"><div className="flex flex-wrap gap-2"><Badge variant="outline">{asset.review_status}</Badge><Badge variant={asset.referenced ? "secondary" : "destructive"}>{asset.referenced ? "Used" : "Unused"}</Badge>{asset.clinically_sensitive && <Badge>Clinical review</Badge>}</div><p className="truncate font-medium">{asset.original_filename}</p><p className="text-xs text-muted-foreground">{asset.alternative_text || "Missing alternative text"} · {(asset.size_bytes / 1024).toFixed(1)} KB</p><div className="flex flex-wrap gap-2"><Button size="sm" disabled={!editable || !asset.alternative_text.trim()} title={!asset.alternative_text.trim() ? "Add alternative text before inserting this image" : undefined} onClick={() => onInsert(asset)}>Insert</Button>{editable && <><Button size="sm" variant="outline" onClick={() => { setEditing(asset); setMetadata(metadataFrom(asset)) }}><Pencil className="mr-1 h-3 w-3" />Metadata</Button><Button size="sm" variant="outline" onClick={() => { setReplacing(asset); inputRef.current?.click() }}><RefreshCw className="mr-1 h-3 w-3" />Replace</Button><Button size="sm" variant="ghost" disabled={asset.referenced} title={asset.referenced ? "Remove the Markdown reference first" : "Remove unused asset"} onClick={() => void remove(asset)}><Trash2 className="h-3 w-3" /></Button></>}</div></div></article>)}</div></ScrollArea>
    </DialogContent></Dialog>
    <Dialog open={Boolean(pendingFile)} onOpenChange={(value) => { if (!value) { setPendingFile(null); setReplacing(null) } }}><DialogContent><DialogHeader><DialogTitle>{replacing ? "Upload replacement image" : "Upload guideline image"}</DialogTitle><DialogDescription>Alternative text is required. Clinically sensitive figures require reviewer approval.</DialogDescription></DialogHeader><AssetMetadataFields metadata={metadata} setMetadata={setMetadata} /><DialogFooter><Button variant="outline" onClick={() => setPendingFile(null)}>Cancel</Button><Button disabled={!metadata.alternative_text?.trim()} onClick={() => void upload()}>Upload</Button></DialogFooter></DialogContent></Dialog>
    <Dialog open={Boolean(editing)} onOpenChange={(value) => { if (!value) setEditing(null) }}><DialogContent><DialogHeader><DialogTitle>Edit asset metadata</DialogTitle><DialogDescription>The underlying file and immutable checksum are unchanged.</DialogDescription></DialogHeader><AssetMetadataFields metadata={metadata} setMetadata={setMetadata} /><DialogFooter><Button variant="outline" onClick={() => setEditing(null)}>Cancel</Button><Button onClick={() => void saveMetadata()}>Save metadata</Button></DialogFooter></DialogContent></Dialog>
  </>
}

function AssetMetadataFields({ metadata, setMetadata }: { metadata: GuidelineAssetMetadata; setMetadata: (value: GuidelineAssetMetadata) => void }) { return <div className="space-y-3"><div><Label htmlFor="asset-alt">Alternative text (required)</Label><Input id="asset-alt" required value={metadata.alternative_text || ""} onChange={(event) => setMetadata({ ...metadata, alternative_text: event.target.value })} /></div><div><Label htmlFor="asset-caption">Caption</Label><Input id="asset-caption" value={metadata.caption || ""} onChange={(event) => setMetadata({ ...metadata, caption: event.target.value })} /></div><div><Label htmlFor="asset-source">Source</Label><Input id="asset-source" value={metadata.source || ""} onChange={(event) => setMetadata({ ...metadata, source: event.target.value })} /></div><div className="grid gap-3 sm:grid-cols-2"><div><Label htmlFor="asset-attribution">Attribution</Label><Input id="asset-attribution" value={metadata.attribution || ""} onChange={(event) => setMetadata({ ...metadata, attribution: event.target.value })} /></div><div><Label htmlFor="asset-license">License or copyright</Label><Input id="asset-license" value={metadata.license || ""} onChange={(event) => setMetadata({ ...metadata, license: event.target.value })} /></div></div><div><Label htmlFor="asset-number">Figure number</Label><Input id="asset-number" type="number" min={1} value={metadata.figure_number || ""} onChange={(event) => setMetadata({ ...metadata, figure_number: event.target.value ? Number(event.target.value) : null })} /></div><label className="flex gap-2 text-sm"><input type="checkbox" checked={metadata.clinically_sensitive || false} onChange={(event) => setMetadata({ ...metadata, clinically_sensitive: event.target.checked })} />Clinically sensitive figure</label></div> }
function metadataFrom(asset: GuidelineAsset): GuidelineAssetMetadata { return { alternative_text: asset.alternative_text, caption: asset.caption, source: asset.source, attribution: asset.attribution, license: asset.license, figure_number: asset.figure_number, clinically_sensitive: asset.clinically_sensitive } }
