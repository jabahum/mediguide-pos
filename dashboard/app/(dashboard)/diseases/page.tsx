"use client";

import * as React from "react";
import { Archive, Pencil, Plus, Save, X } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { PageHeader } from "@/components/ui/page-header";
import { Textarea } from "@/components/ui/textarea";
import { showToast } from "@/lib/toast";
import {
  Disease,
  DiseaseAlias,
  DiseaseCode,
  diseaseService,
} from "@/services/content-hubs.service";

const empty = {
  name: "",
  slug: "",
  short_name: "",
  description: "",
  icon: "",
  color: "",
  status: "active",
  sort_order: 0,
  parent_id: "",
  aliases: [] as DiseaseAlias[],
  codes: [] as DiseaseCode[],
};

export default function DiseasesPage() {
  const [rows, setRows] = React.useState<Disease[]>([]);
  const [search, setSearch] = React.useState("");
  const [editing, setEditing] = React.useState<Disease | null>(null);
  const [editorOpen, setEditorOpen] = React.useState(false);
  const [form, setForm] = React.useState(empty);
  const [busy, setBusy] = React.useState(false);

  const load = React.useCallback(async () => {
    try {
      setRows((await diseaseService.list(search)).items || []);
    } catch (error) {
      showToast.error(
        "Diseases unavailable",
        error instanceof Error ? error.message : "Try again.",
      );
    }
  }, [search]);
  React.useEffect(() => {
    void load();
  }, [load]);

  function edit(value?: Disease) {
    setEditorOpen(true);
    setEditing(value || null);
    setForm(
      value
        ? {
            name: value.name,
            slug: value.slug,
            short_name: value.short_name || "",
            description: value.description || "",
            icon: value.icon || "",
            color: value.color || "",
            status: value.status,
            sort_order: value.sort_order || 0,
            parent_id: value.parent_id || "",
            aliases: value.aliases || [],
            codes: value.codes || [],
          }
        : empty,
    );
  }
  async function save() {
    if (!form.name.trim()) return;
    setBusy(true);
    try {
      const payload = {
        ...form,
        parent_id: form.parent_id || undefined,
        aliases: form.aliases
          .filter((value) => value.alias.trim())
          .map((value) => ({ alias: value.alias.trim() })),
        codes: form.codes
          .filter((value) => value.code_system.trim() && value.code.trim())
          .map((value) => ({
            code_system: value.code_system.trim(),
            code: value.code.trim(),
            display_name: value.display_name?.trim() || undefined,
          })),
      };
      if (editing) await diseaseService.update(editing.id, payload);
      else await diseaseService.create(payload);
      showToast.success(
        "Disease saved",
        "Names, aliases, codes and hierarchy are now available for classification.",
      );
      setEditorOpen(false);
      setEditing(null);
      setForm(empty);
      await load();
    } catch (error) {
      showToast.error("Disease not saved", actionable(error));
    } finally {
      setBusy(false);
    }
  }

  return (
    <div className="space-y-6">
      <PageHeader
        title="Diseases and clinical conditions"
        description="Canonical disease names, aliases, codes and parent-child relationships."
      />
      <div className="flex gap-2">
        <Input
          value={search}
          onChange={(event) => setSearch(event.target.value)}
          placeholder="Search names, aliases or codes"
        />
        <Button onClick={() => edit()}>
          <Plus className="mr-2 h-4 w-4" />
          New disease
        </Button>
      </div>
      <div className="grid gap-3 md:grid-cols-2 xl:grid-cols-3">
        {rows.map((row) => (
          <Card key={row.id}>
            <CardHeader className="pb-2">
              <CardTitle className="text-base">{row.name}</CardTitle>
            </CardHeader>
            <CardContent className="space-y-2 text-sm">
              <div className="text-muted-foreground">
                {row.parent_name ? `${row.parent_name} › ` : ""}
                {row.slug}
              </div>
              <div>
                {row.aliases.length} aliases · {row.codes.length} codes ·{" "}
                {row.status}
              </div>
              <div className="flex gap-2">
                <Button size="sm" variant="outline" onClick={() => edit(row)}>
                  <Pencil className="mr-2 h-3 w-3" />
                  Edit
                </Button>
                {row.status !== "archived" ? (
                  <Button
                    size="sm"
                    variant="ghost"
                    onClick={async () => {
                      if (
                        !confirm(
                          `Archive ${row.name}? Existing assignments remain readable.`,
                        )
                      )
                        return;
                      try {
                        await diseaseService.archive(row.id);
                        await load();
                        showToast.success("Disease archived");
                      } catch (error) {
                        showToast.error("Archive failed", actionable(error));
                      }
                    }}
                  >
                    <Archive className="mr-2 h-3 w-3" />
                    Archive
                  </Button>
                ) : null}
              </div>
            </CardContent>
          </Card>
        ))}
      </div>
      {editorOpen ? (
        <DiseaseEditor
          form={form}
          setForm={setForm}
          rows={rows}
          busy={busy}
          editing={editing}
          onSave={save}
          onClose={() => {
            setEditorOpen(false);
            setEditing(null);
            setForm(empty);
          }}
        />
      ) : null}
    </div>
  );
}

function DiseaseEditor({
  form,
  setForm,
  rows,
  busy,
  editing,
  onSave,
  onClose,
}: {
  form: typeof empty;
  setForm: React.Dispatch<React.SetStateAction<typeof empty>>;
  rows: Disease[];
  busy: boolean;
  editing: Disease | null;
  onSave: () => void;
  onClose: () => void;
}) {
  const set = (key: keyof typeof empty, value: unknown) =>
    setForm((current) => ({ ...current, [key]: value }));
  return (
    <Card className="border-primary">
      <CardHeader>
        <div className="flex items-center justify-between">
          <CardTitle>
            {editing ? `Edit ${editing.name}` : "Create disease"}
          </CardTitle>
          <Button variant="ghost" size="icon" onClick={onClose}>
            <X className="h-4 w-4" />
          </Button>
        </div>
      </CardHeader>
      <CardContent className="space-y-5">
        <div className="grid gap-4 md:grid-cols-2">
          <Field
            label="Canonical name"
            value={form.name}
            onChange={(value) => set("name", value)}
          />
          <Field
            label="Slug"
            value={form.slug}
            onChange={(value) => set("slug", value)}
          />
          <Field
            label="Short name"
            value={form.short_name}
            onChange={(value) => set("short_name", value)}
          />
          <div>
            <Label>Parent condition</Label>
            <select
              className="mt-2 h-10 w-full rounded-md border bg-background px-3"
              value={form.parent_id}
              onChange={(event) => set("parent_id", event.target.value)}
            >
              <option value="">Top level</option>
              {rows
                .filter(
                  (value) =>
                    value.id !== editing?.id && value.status === "active",
                )
                .map((value) => (
                  <option key={value.id} value={value.id}>
                    {value.parent_name ? `${value.parent_name} › ` : ""}
                    {value.name}
                  </option>
                ))}
            </select>
          </div>
          <Field
            label="Icon key"
            value={form.icon}
            onChange={(value) => set("icon", value)}
          />
          <Field
            label="Colour or tone"
            value={form.color}
            onChange={(value) => set("color", value)}
          />
          <div className="md:col-span-2">
            <Label>Description</Label>
            <Textarea
              className="mt-2"
              value={form.description}
              onChange={(event) => set("description", event.target.value)}
            />
          </div>
        </div>
        <ListEditor
          title="Aliases"
          add={() => set("aliases", [...form.aliases, { alias: "" }])}
        >
          {form.aliases.map((value, index) => (
            <div className="flex gap-2" key={index}>
              <Input
                aria-label={`Alias ${index + 1}`}
                value={value.alias}
                onChange={(event) =>
                  set(
                    "aliases",
                    form.aliases.map((row, position) =>
                      position === index ? { alias: event.target.value } : row,
                    ),
                  )
                }
              />
              <Button
                variant="ghost"
                onClick={() =>
                  set(
                    "aliases",
                    form.aliases.filter((_, position) => position !== index),
                  )
                }
              >
                Remove
              </Button>
            </div>
          ))}
        </ListEditor>
        <ListEditor
          title="Standard codes"
          add={() =>
            set("codes", [
              ...form.codes,
              { code_system: "", code: "", display_name: "" },
            ])
          }
        >
          {form.codes.map((value, index) => (
            <div
              className="grid gap-2 md:grid-cols-[1fr_1fr_2fr_auto]"
              key={index}
            >
              <Input
                placeholder="ICD-11"
                value={value.code_system}
                onChange={(event) =>
                  set(
                    "codes",
                    form.codes.map((row, position) =>
                      position === index
                        ? { ...row, code_system: event.target.value }
                        : row,
                    ),
                  )
                }
              />
              <Input
                placeholder="Code"
                value={value.code}
                onChange={(event) =>
                  set(
                    "codes",
                    form.codes.map((row, position) =>
                      position === index
                        ? { ...row, code: event.target.value }
                        : row,
                    ),
                  )
                }
              />
              <Input
                placeholder="Display name"
                value={value.display_name || ""}
                onChange={(event) =>
                  set(
                    "codes",
                    form.codes.map((row, position) =>
                      position === index
                        ? { ...row, display_name: event.target.value }
                        : row,
                    ),
                  )
                }
              />
              <Button
                variant="ghost"
                onClick={() =>
                  set(
                    "codes",
                    form.codes.filter((_, position) => position !== index),
                  )
                }
              >
                Remove
              </Button>
            </div>
          ))}
        </ListEditor>
        <div className="flex justify-end">
          <Button disabled={busy || !form.name.trim()} onClick={onSave}>
            <Save className="mr-2 h-4 w-4" />
            Save disease
          </Button>
        </div>
      </CardContent>
    </Card>
  );
}
function Field({
  label,
  value,
  onChange,
}: {
  label: string;
  value: string;
  onChange: (value: string) => void;
}) {
  return (
    <div>
      <Label>{label}</Label>
      <Input
        className="mt-2"
        value={value}
        onChange={(event) => onChange(event.target.value)}
      />
    </div>
  );
}
function ListEditor({
  title,
  add,
  children,
}: {
  title: string;
  add: () => void;
  children: React.ReactNode;
}) {
  return (
    <div className="space-y-2">
      <div className="flex items-center justify-between">
        <Label>{title}</Label>
        <Button size="sm" variant="outline" onClick={add}>
          <Plus className="mr-2 h-3 w-3" />
          Add
        </Button>
      </div>
      {children}
    </div>
  );
}
function actionable(value: unknown) {
  const message = value instanceof Error ? value.message : "Try again.";
  return /cycle/i.test(message)
    ? "Choose a parent outside this disease's descendants."
    : /already|conflict|duplicate/i.test(message)
      ? "That name, alias, slug or code is already assigned. Choose a unique value."
      : message;
}
