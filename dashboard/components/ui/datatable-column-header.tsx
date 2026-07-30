"use client"

import * as React from "react"
import { Column } from "@tanstack/react-table"
import { ArrowUpDown, ArrowUp, ArrowDown, EyeOff, Filter, X } from "lucide-react"

import { cn } from "@/lib/utils"
import { Button } from "@/components/ui/button"
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuSeparator,
  DropdownMenuTrigger,
} from "@/components/ui/dropdown-menu"
import { Input } from "@/components/ui/input"
import {
  Popover,
  PopoverContent,
  PopoverTrigger,
} from "@/components/ui/popover"
// import { Badge } from "@/components/ui/badge"
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select"
import { Checkbox } from "@/components/ui/checkbox"
import { FilterOption, FilterType, DateRangeFilterValue, RangeFilterValue } from "@/types/data-table"

interface DataTableColumnHeaderComponentProps<TData, TValue>
  extends React.HTMLAttributes<HTMLDivElement> {
  column: Column<TData, TValue>
  title: string
  canSort?: boolean
  canFilter?: boolean
  filterType?: FilterType
  filterOptions?: FilterOption[]
  filterPlaceholder?: string
  relationField?: string // For relation fields, specify the legacy collection API field path (e.g., "drug_class.name")
}

export function DataTableColumnHeader<TData, TValue>({
  column,
  title,
  canSort = true,
  canFilter = false,
  filterType = 'text',
  filterOptions = [],
  filterPlaceholder = 'Filter...',
  relationField,
  className,
}: DataTableColumnHeaderComponentProps<TData, TValue>) {
  const [isFilterOpen, setIsFilterOpen] = React.useState(false)
  const [filterValue, setFilterValue] = React.useState<string>(
    (column.getFilterValue() as string) || ''
  )
  const [tempFilterValue, setTempFilterValue] = React.useState<string>(filterValue)

  const sortedState = column.getIsSorted()
  const isFiltered = column.getIsFiltered()


  const handleClearSort = React.useCallback(() => {
    column.clearSorting()
  }, [column])

  const handleHideColumn = React.useCallback(() => {
    column.toggleVisibility(false)
  }, [column])

  const applyFilter = React.useCallback((value: string) => {
    // If this is a relation field, store the relation path with the filter value
    if (relationField && value) {
      const filterData = {
        value,
        relationField,
        type: 'relation'
      }
      column.setFilterValue(JSON.stringify(filterData))
    } else {
      column.setFilterValue(value || undefined)
    }
    setFilterValue(value)
    setIsFilterOpen(false)
  }, [column, relationField])

  const handleTextFilterSubmit = React.useCallback(() => {
    applyFilter(tempFilterValue)
  }, [applyFilter, tempFilterValue])

  const handleSelectFilterChange = React.useCallback((value: string) => {
    // Treat "__all__" as clearing the filter
    applyFilter(value === '__all__' ? '' : value)
  }, [applyFilter])

  const handleBooleanFilterChange = React.useCallback((checked: boolean) => {
    applyFilter(checked.toString())
  }, [applyFilter])

  const clearFilter = React.useCallback(() => {
    applyFilter('')
    setTempFilterValue('')
  }, [applyFilter])

  const renderFilterContent = () => {
    switch (filterType) {
      case 'text':
        return (
          <div className="space-y-2">
            <Input
              placeholder={filterPlaceholder}
              value={tempFilterValue}
              onChange={(e) => setTempFilterValue(e.target.value)}
              onKeyDown={(e) => {
                if (e.key === 'Enter') {
                  handleTextFilterSubmit()
                }
              }}
              className="h-8"
            />
            <div className="flex justify-between">
              <Button
                variant="outline"
                size="sm"
                onClick={clearFilter}
                disabled={!tempFilterValue}
              >
                Clear
              </Button>
              <Button
                size="sm"
                onClick={handleTextFilterSubmit}
              >
                Apply
              </Button>
            </div>
          </div>
        )

      case 'select':
        return (
          <div className="space-y-2">
            <Select
              value={filterValue === '' ? '__all__' : filterValue}
              onValueChange={handleSelectFilterChange}
            >
              <SelectTrigger className="h-8 w-full">
                <SelectValue placeholder={filterPlaceholder} />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="__all__">All</SelectItem>
                {filterOptions.map((option) => (
                  <SelectItem key={option.value} value={option.value}>
                    {option.label}
                  </SelectItem>
                ))}
              </SelectContent>
            </Select>
            {filterValue && (
              <Button
                variant="outline"
                size="sm"
                onClick={clearFilter}
                className="w-full"
              >
                Clear Filter
              </Button>
            )}
          </div>
        )

      case 'boolean':
        return (
          <div className="space-y-2">
            <div className="flex items-center space-x-2">
              <Checkbox
                id="boolean-filter"
                checked={filterValue === 'true'}
                onCheckedChange={handleBooleanFilterChange}
              />
              <label htmlFor="boolean-filter" className="text-sm">
                {filterPlaceholder || 'Filter by true'}
              </label>
            </div>
            {filterValue && (
              <Button
                variant="outline"
                size="sm"
                onClick={clearFilter}
                className="w-full"
              >
                Clear Filter
              </Button>
            )}
          </div>
        )

      case 'number':
        return (
          <div className="space-y-2">
            <Input
              type="number"
              placeholder={filterPlaceholder}
              value={tempFilterValue}
              onChange={(e) => setTempFilterValue(e.target.value)}
              onKeyDown={(e) => {
                if (e.key === 'Enter') {
                  handleTextFilterSubmit()
                }
              }}
              className="h-8"
            />
            <div className="flex justify-between">
              <Button
                variant="outline"
                size="sm"
                onClick={clearFilter}
                disabled={!tempFilterValue}
              >
                Clear
              </Button>
              <Button
                size="sm"
                onClick={handleTextFilterSubmit}
              >
                Apply
              </Button>
            </div>
          </div>
        )

      case 'date':
        return (
          <div className="space-y-2">
            <Input
              type="date"
              value={tempFilterValue}
              onChange={(e) => setTempFilterValue(e.target.value)}
              className="h-8"
            />
            <div className="flex justify-between">
              <Button
                variant="outline"
                size="sm"
                onClick={clearFilter}
                disabled={!tempFilterValue}
              >
                Clear
              </Button>
              <Button
                size="sm"
                onClick={handleTextFilterSubmit}
              >
                Apply
              </Button>
            </div>
          </div>
        )

      case 'dateRange':
        const dateRangeValue = (filterValue ? JSON.parse(filterValue) : { start: '', end: '' }) as DateRangeFilterValue
        return (
          <div className="space-y-3">
            <div className="text-sm font-medium">Date Range</div>
            <div className="space-y-2">
              <div>
                <label className="text-xs text-muted-foreground">Start Date</label>
                <Input
                  type="date"
                  value={dateRangeValue.start || ''}
                  onChange={(e) => {
                    const newValue = { ...dateRangeValue, start: e.target.value, type: 'dateRange' as const }
                    setTempFilterValue(JSON.stringify(newValue))
                  }}
                  className="h-8"
                />
              </div>
              <div>
                <label className="text-xs text-muted-foreground">End Date</label>
                <Input
                  type="date"
                  value={dateRangeValue.end || ''}
                  onChange={(e) => {
                    const newValue = { ...dateRangeValue, end: e.target.value, type: 'dateRange' as const }
                    setTempFilterValue(JSON.stringify(newValue))
                  }}
                  className="h-8"
                />
              </div>
            </div>
            <div className="text-xs text-muted-foreground">Or select a preset:</div>
            <Select
              value={dateRangeValue.preset || ''}
              onValueChange={(preset) => {
                let newValue: DateRangeFilterValue
                const now = new Date()
                
                switch (preset) {
                  case 'today':
                    const today = now.toISOString().split('T')[0]
                    newValue = { type: 'dateRange', start: today, end: today, preset: 'today' }
                    break
                  case 'thisWeek':
                    const startOfWeek = new Date(now.setDate(now.getDate() - now.getDay())).toISOString().split('T')[0]
                    const endOfWeek = new Date(now.setDate(now.getDate() + 6)).toISOString().split('T')[0]
                    newValue = { type: 'dateRange', start: startOfWeek, end: endOfWeek, preset: 'thisWeek' }
                    break
                  case 'thisMonth':
                    const startOfMonth = new Date(now.getFullYear(), now.getMonth(), 1).toISOString().split('T')[0]
                    const endOfMonth = new Date(now.getFullYear(), now.getMonth() + 1, 0).toISOString().split('T')[0]
                    newValue = { type: 'dateRange', start: startOfMonth, end: endOfMonth, preset: 'thisMonth' }
                    break
                  default:
                    newValue = { type: 'dateRange', preset: preset as DateRangeFilterValue['preset'] }
                }
                
                const newTempValue = JSON.stringify(newValue)
                setTempFilterValue(newTempValue)
                applyFilter(newTempValue)
              }}
            >
              <SelectTrigger className="h-8 w-full">
                <SelectValue placeholder="Select preset" />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="today">Today</SelectItem>
                <SelectItem value="thisWeek">This Week</SelectItem>
                <SelectItem value="thisMonth">This Month</SelectItem>
                <SelectItem value="thisYear">This Year</SelectItem>
              </SelectContent>
            </Select>
            <div className="flex justify-between">
              <Button
                variant="outline"
                size="sm"
                onClick={() => {
                  const emptyValue = JSON.stringify({ type: 'dateRange', start: '', end: '' })
                  setTempFilterValue(emptyValue)
                  clearFilter()
                }}
              >
                Clear
              </Button>
              <Button
                size="sm"
                onClick={() => applyFilter(tempFilterValue)}
                disabled={!tempFilterValue || tempFilterValue === JSON.stringify({ type: 'dateRange', start: '', end: '' })}
              >
                Apply
              </Button>
            </div>
          </div>
        )

      case 'numberRange':
        const numberRangeValue = (filterValue ? JSON.parse(filterValue) : { min: '', max: '' }) as RangeFilterValue
        return (
          <div className="space-y-3">
            <div className="text-sm font-medium">Number Range</div>
            <div className="space-y-2">
              <div>
                <label className="text-xs text-muted-foreground">Min</label>
                <Input
                  type="number"
                  placeholder="Minimum value"
                  value={numberRangeValue.min || ''}
                  onChange={(e) => {
                    const newValue = { ...numberRangeValue, min: e.target.value, type: 'range' as const }
                    setTempFilterValue(JSON.stringify(newValue))
                  }}
                  className="h-8"
                />
              </div>
              <div>
                <label className="text-xs text-muted-foreground">Max</label>
                <Input
                  type="number"
                  placeholder="Maximum value"
                  value={numberRangeValue.max || ''}
                  onChange={(e) => {
                    const newValue = { ...numberRangeValue, max: e.target.value, type: 'range' as const }
                    setTempFilterValue(JSON.stringify(newValue))
                  }}
                  className="h-8"
                />
              </div>
            </div>
            <div className="flex justify-between">
              <Button
                variant="outline"
                size="sm"
                onClick={() => {
                  const emptyValue = JSON.stringify({ type: 'range', min: '', max: '' })
                  setTempFilterValue(emptyValue)
                  clearFilter()
                }}
              >
                Clear
              </Button>
              <Button
                size="sm"
                onClick={() => applyFilter(tempFilterValue)}
                disabled={!tempFilterValue || tempFilterValue === JSON.stringify({ type: 'range', min: '', max: '' })}
              >
                Apply
              </Button>
            </div>
          </div>
        )

      case 'json':
        const jsonValue = (filterValue ? JSON.parse(filterValue) : { path: '', value: '' })
        return (
          <div className="space-y-3">
            <div className="text-sm font-medium">JSON Field Filter</div>
            <div className="space-y-2">
              <div>
                <label className="text-xs text-muted-foreground">JSON Path</label>
                <Input
                  placeholder="e.g., user.name or settings.theme"
                  value={jsonValue.path || ''}
                  onChange={(e) => {
                    const newValue = { ...jsonValue, path: e.target.value, type: 'json' as const }
                    setTempFilterValue(JSON.stringify(newValue))
                  }}
                  className="h-8"
                />
              </div>
              <div>
                <label className="text-xs text-muted-foreground">Value</label>
                <Input
                  placeholder="Filter value"
                  value={jsonValue.value || ''}
                  onChange={(e) => {
                    const newValue = { ...jsonValue, value: e.target.value, type: 'json' as const }
                    setTempFilterValue(JSON.stringify(newValue))
                  }}
                  className="h-8"
                />
              </div>
            </div>
            <div className="flex justify-between">
              <Button
                variant="outline"
                size="sm"
                onClick={() => {
                  const emptyValue = JSON.stringify({ type: 'json', path: '', value: '' })
                  setTempFilterValue(emptyValue)
                  clearFilter()
                }}
              >
                Clear
              </Button>
              <Button
                size="sm"
                onClick={() => applyFilter(tempFilterValue)}
                disabled={!tempFilterValue || !jsonValue.path || !jsonValue.value}
              >
                Apply
              </Button>
            </div>
          </div>
        )

      default:
        return null
    }
  }

  if (!canSort && !canFilter) {
    return (
      <div className={cn("flex items-center space-x-2", className)}>
        <span className="font-medium">{title}</span>
      </div>
    )
  }

  return (
    <div className={cn("flex items-center space-x-2", className)}>
      <DropdownMenu>
        <DropdownMenuTrigger asChild>
          <Button
            variant="ghost"
            size="sm"
            className="h-8 data-[state=open]:bg-accent"
          >
            <span className="font-medium">{title}</span>
            {sortedState === 'desc' ? (
              <ArrowDown className="ml-2 h-4 w-4" />
            ) : sortedState === 'asc' ? (
              <ArrowUp className="ml-2 h-4 w-4" />
            ) : canSort ? (
              <ArrowUpDown className="ml-2 h-4 w-4" />
            ) : null}
          </Button>
        </DropdownMenuTrigger>
        <DropdownMenuContent align="start">
          {canSort && (
            <>
              <DropdownMenuItem onClick={() => column.toggleSorting(false)}>
                <ArrowUp className="mr-2 h-3.5 w-3.5 text-muted-foreground/70" />
                Asc
              </DropdownMenuItem>
              <DropdownMenuItem onClick={() => column.toggleSorting(true)}>
                <ArrowDown className="mr-2 h-3.5 w-3.5 text-muted-foreground/70" />
                Desc
              </DropdownMenuItem>
              {sortedState && (
                <DropdownMenuItem onClick={handleClearSort}>
                  <X className="mr-2 h-3.5 w-3.5 text-muted-foreground/70" />
                  Clear Sort
                </DropdownMenuItem>
              )}
              {canFilter && <DropdownMenuSeparator />}
            </>
          )}
          <DropdownMenuItem onClick={handleHideColumn}>
            <EyeOff className="mr-2 h-3.5 w-3.5 text-muted-foreground/70" />
            Hide Column
          </DropdownMenuItem>
        </DropdownMenuContent>
      </DropdownMenu>

      {canFilter && (
        <Popover open={isFilterOpen} onOpenChange={setIsFilterOpen}>
          <PopoverTrigger asChild>
            <Button
              variant="ghost"
              size="sm"
              className={cn(
                "h-8 w-8 p-0",
                isFiltered && "bg-accent text-accent-foreground"
              )}
            >
              <Filter className="h-4 w-4" />
            </Button>
          </PopoverTrigger>
          <PopoverContent className="w-[200px] p-3" align="start">
            {renderFilterContent()}
          </PopoverContent>
        </Popover>
      )}

    </div>
  )
}