"use client"

import * as React from "react"
import { Plus } from "lucide-react"
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select"
import { getBackendClient } from "@/lib/backend-client"

interface SelectOptionRecord {
  id: string
  name?: string
}

interface SelectWithCreateProps {
  value?: string
  onValueChange?: (value: string) => void
  placeholder?: string
  collection: string
  onCreateClick: () => void
  disabled?: boolean
  className?: string
  refreshTrigger?: number
}

export function SelectWithCreate({
  value,
  onValueChange,
  placeholder,
  collection,
  onCreateClick,
  disabled,
  className,
  refreshTrigger
}: SelectWithCreateProps) {
  const [options, setOptions] = React.useState<SelectOptionRecord[]>([])
  const [loading, setLoading] = React.useState(true)

  const fetchOptions = React.useCallback(async () => {
    try {
      const backend = getBackendClient()
      const records = await backend.resource(collection).getFullList({
        filter: "status = 'active'",
        sort: "sort_order,name"
      })
      setOptions(records)
    } catch (error) {
      console.error(`Failed to fetch ${collection}:`, error)
      setOptions([])
    } finally {
      setLoading(false)
    }
  }, [collection])

  React.useEffect(() => {
    fetchOptions()
  }, [fetchOptions])

  // Refresh when trigger changes
  React.useEffect(() => {
    if (refreshTrigger !== undefined) {
      fetchOptions()
    }
  }, [refreshTrigger, fetchOptions])

  return (
    <div className={className}>
      <Select value={value} onValueChange={onValueChange} disabled={disabled || loading}>
        <SelectTrigger className="w-full">
          <SelectValue placeholder={loading ? "Loading..." : placeholder} />
        </SelectTrigger>
        <SelectContent>
          {options.map((option) => (
            <SelectItem key={option.id} value={option.id}>
              {option.name}
            </SelectItem>
          ))}
          {!loading && options.length === 0 && (
            <div className="px-2 py-1.5 text-sm text-muted-foreground">
              No options available
            </div>
          )}
          <div
            className="relative flex w-full cursor-pointer select-none items-center rounded-sm px-2 py-1.5 text-sm outline-none hover:bg-accent hover:text-accent-foreground focus:bg-accent focus:text-accent-foreground data-[disabled]:pointer-events-none data-[disabled]:opacity-50 border-t mt-1"
            onClick={() => {
              if (!disabled) {
                onCreateClick()
              }
            }}
          >
            <Plus className="h-4 w-4 mr-2" />
            Add New
          </div>
        </SelectContent>
      </Select>
    </div>
  )
}

// Hook to manage the select with create functionality
export function useSelectWithCreate(collection: string) {
  const [options, setOptions] = React.useState<SelectOptionRecord[]>([])
  const [loading, setLoading] = React.useState(true)

  const fetchOptions = React.useCallback(async () => {
    try {
      const backend = getBackendClient()
      const records = await backend.resource(collection).getFullList({
        filter: "status = 'active'",
        sort: "sort_order,name"
      })
      setOptions(records)
    } catch (error) {
      console.error(`Failed to fetch ${collection}:`, error)
      setOptions([])
    } finally {
      setLoading(false)
    }
  }, [collection])

  React.useEffect(() => {
    fetchOptions()
  }, [fetchOptions])

  const refresh = React.useCallback(() => {
    setLoading(true)
    fetchOptions()
  }, [fetchOptions])

  return { options, loading, refresh }
}
