"use client"

import * as React from "react"
import { useQuery } from "@tanstack/react-query"
import { Check, ChevronsUpDown } from "lucide-react"

import { cn } from "@/lib/utils"
import { getBackendClient } from "@/lib/backend-client"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import {
  Command,
  CommandEmpty,
  CommandGroup,
  CommandInput,
  CommandItem,
  CommandList,
} from "@/components/ui/command"
import {
  Popover,
  PopoverContent,
  PopoverTrigger,
} from "@/components/ui/popover"
import { FieldOption, FilterOption } from "@/types/data-table"

interface FilterValueInputProps {
  field?: FieldOption
  value: string
  onChange: (value: string, displayValue?: string) => void
  placeholder?: string
}

export function FilterValueInput({
  field,
  value,
  onChange,
  placeholder = "Enter filter value",
}: FilterValueInputProps) {
  if (!field) {
    return (
      <Input
        placeholder={placeholder}
        value={value}
        onChange={(e) => onChange(e.target.value)}
      />
    )
  }

  if (field.type === "select" && field.options?.length) {
    return (
      <StaticSelect
        options={field.options}
        value={value}
        onChange={onChange}
        placeholder={placeholder}
      />
    )
  }

  if (field.type === "select" && field.relation) {
    return (
      <RelationSelect
        field={field}
        value={value}
        onChange={onChange}
        placeholder={placeholder}
      />
    )
  }

  if (field.type === "date") {
    return (
      <Input
        type="date"
        value={value}
        onChange={(e) => onChange(e.target.value)}
      />
    )
  }

  if (field.type === "number") {
    return (
      <Input
        type="number"
        placeholder={placeholder}
        value={value}
        onChange={(e) => onChange(e.target.value)}
      />
    )
  }

  return (
    <Input
      placeholder={placeholder}
      value={value}
      onChange={(e) => onChange(e.target.value)}
    />
  )
}

function StaticSelect({
  options,
  value,
  onChange,
  placeholder,
}: {
  options: FilterOption[]
  value: string
  onChange: (value: string, displayValue?: string) => void
  placeholder: string
}) {
  const [open, setOpen] = React.useState(false)
  const selected = options.find((o) => o.value === value)

  return (
    <Popover open={open} onOpenChange={setOpen}>
      <PopoverTrigger asChild>
        <Button
          variant="outline"
          role="combobox"
          aria-expanded={open}
          className="w-full justify-between font-normal"
        >
          <span className={selected ? "" : "text-muted-foreground"}>
            {selected ? selected.label : placeholder}
          </span>
          <ChevronsUpDown className="ml-2 h-4 w-4 shrink-0 opacity-50" />
        </Button>
      </PopoverTrigger>
      <PopoverContent className="p-0 w-[--radix-popover-trigger-width]" align="start">
        <Command>
          <CommandInput placeholder="Search..." />
          <CommandList>
            <CommandEmpty>No matches.</CommandEmpty>
            <CommandGroup>
              {options.map((option) => (
                <CommandItem
                  key={option.value}
                  value={option.label}
                  onSelect={() => {
                    onChange(option.value, option.label)
                    setOpen(false)
                  }}
                >
                  <Check
                    className={cn(
                      "mr-2 h-4 w-4",
                      value === option.value ? "opacity-100" : "opacity-0"
                    )}
                  />
                  {option.label}
                </CommandItem>
              ))}
            </CommandGroup>
          </CommandList>
        </Command>
      </PopoverContent>
    </Popover>
  )
}

export interface RelationSelectConfig {
  collection?: string
  key?: string
  loadOptions?: (search: string, pageSize: number) => Promise<Array<Record<string, unknown>>>
  labelField?: string
  valueField?: string
  sort?: string
  filter?: string
  pageSize?: number
}

export function RelationCombobox({
  relation,
  value,
  onChange,
  placeholder = "Select...",
  className,
}: {
  relation: RelationSelectConfig
  value: string
  onChange: (value: string, displayValue?: string) => void
  placeholder?: string
  className?: string
}) {
  return (
    <RelationSelect
      field={{ label: "", value: "", type: "select", relation }}
      value={value}
      onChange={onChange}
      placeholder={placeholder}
      className={className}
    />
  )
}

function RelationSelect({
  field,
  value,
  onChange,
  placeholder,
  className,
}: {
  field: FieldOption
  value: string
  onChange: (value: string, displayValue?: string) => void
  placeholder: string
  className?: string
}) {
  const [open, setOpen] = React.useState(false)
  const [search, setSearch] = React.useState("")
  const [debounced, setDebounced] = React.useState("")
  const backend = React.useMemo(() => getBackendClient(), [])

  const relation = field.relation!
  const labelField = relation.labelField ?? "name"
  const valueField = relation.valueField ?? "id"
  const sort = relation.sort ?? labelField
  const pageSize = relation.pageSize ?? 50
  const relationKey = relation.key ?? relation.collection ?? "relation"

  React.useEffect(() => {
    const t = setTimeout(() => setDebounced(search.trim()), 250)
    return () => clearTimeout(t)
  }, [search])

  const escapeForFilter = (raw: string) =>
    raw.replace(/\\/g, "\\\\").replace(/"/g, '\\"')

  const listQuery = useQuery({
    enabled: open,
    queryKey: [
      "backend-filter-relation",
      relationKey,
      { labelField, valueField, sort, pageSize, debounced, base: relation.filter ?? "" },
    ],
    queryFn: async () => {
      if (relation.loadOptions) {
        return relation.loadOptions(debounced, pageSize)
      }
      if (!relation.collection) return []
      const filters: string[] = []
      if (relation.filter) filters.push(`(${relation.filter})`)
      if (debounced) filters.push(`${labelField} ~ "${escapeForFilter(debounced)}"`)
      const result = await backend.resource(relation.collection).getList(1, pageSize, {
        filter: filters.join(" && ") || undefined,
        sort,
        fields: `${valueField},${labelField}`,
      })
      return result.items as Array<Record<string, unknown>>
    },
  })

  const selectedQuery = useQuery({
    enabled: !!value,
    queryKey: ["backend-filter-relation-one", relationKey, value, labelField, valueField],
    queryFn: async () => {
      if (relation.loadOptions) {
        const items = await relation.loadOptions("", Math.max(pageSize, 200))
        return items.find((item) => String(item[valueField]) === value) ?? null
      }
      if (!relation.collection) return null
      const item = await backend
        .resource(relation.collection)
        .getOne(value, { fields: `${valueField},${labelField}` })
      return item as Record<string, unknown>
    },
  })

  const selectedLabel = React.useMemo(() => {
    if (!value) return undefined
    const fromList = listQuery.data?.find(
      (item) => String(item[valueField]) === value
    )
    const source = fromList ?? selectedQuery.data
    const label = source?.[labelField]
    return typeof label === "string" ? label : undefined
  }, [value, listQuery.data, selectedQuery.data, labelField, valueField])

  return (
    <Popover open={open} onOpenChange={setOpen}>
      <PopoverTrigger asChild>
        <Button
          variant="outline"
          role="combobox"
          aria-expanded={open}
          className={cn("w-full justify-between font-normal", className)}
        >
          <span className={selectedLabel ? "" : "text-muted-foreground"}>
            {selectedLabel ?? (value ? value : placeholder)}
          </span>
          <ChevronsUpDown className="ml-2 h-4 w-4 shrink-0 opacity-50" />
        </Button>
      </PopoverTrigger>
      <PopoverContent className="p-0 w-[--radix-popover-trigger-width]" align="start">
        <Command shouldFilter={false}>
          <CommandInput
            placeholder="Search..."
            value={search}
            onValueChange={setSearch}
          />
          <CommandList>
            <CommandEmpty>
              {listQuery.isFetching ? "Searching..." : "No matches."}
            </CommandEmpty>
            <CommandGroup>
              {(listQuery.data ?? []).map((item) => {
                const id = String(item[valueField] ?? "")
                const label = String(item[labelField] ?? id)
                return (
                  <CommandItem
                    key={id}
                    value={id}
                    onSelect={() => {
                      onChange(id, label)
                      setOpen(false)
                    }}
                  >
                    <Check
                      className={cn(
                        "mr-2 h-4 w-4",
                        value === id ? "opacity-100" : "opacity-0"
                      )}
                    />
                    {label}
                  </CommandItem>
                )
              })}
            </CommandGroup>
          </CommandList>
        </Command>
      </PopoverContent>
    </Popover>
  )
}
