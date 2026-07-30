"use client";

import * as React from "react";
import { Badge } from "@/components/ui/badge";
import { DataTableColumnHeader } from "@/components/ui/datatable-column-header";
import { ExtendedColumnDef } from "@/types/data-table";
import { DecisionToolWithRelations } from "./types";
import { getAppFileLabel } from "./app-file";

import {
  CalculatorsTypeOptions,
  CalculatorsStatusOptions,
} from "@/types/backend-types";
import { Calculator, Brain, CheckSquare } from "lucide-react";

/**
 * Get icon component for decision tool type
 */
const getTypeIcon = (type: CalculatorsTypeOptions) => {
  switch (type) {
    case CalculatorsTypeOptions.calculator:
      return <Calculator className="h-4 w-4" />;
    case CalculatorsTypeOptions.decision_tool:
      return <Brain className="h-4 w-4" />;
    case CalculatorsTypeOptions.checklist:
      return <CheckSquare className="h-4 w-4" />;
    default:
      return <Calculator className="h-4 w-4" />;
  }
};

/**
 * Get badge variant for status
 */
const getStatusVariant = (status: CalculatorsStatusOptions) => {
  switch (status) {
    case CalculatorsStatusOptions.active:
      return "default";
    case CalculatorsStatusOptions.draft:
      return "secondary";
    case CalculatorsStatusOptions.archived:
      return "destructive";
    default:
      return "secondary";
  }
};

/**
 * Get badge variant for type
 */
const getTypeVariant = (type: CalculatorsTypeOptions) => {
  switch (type) {
    case CalculatorsTypeOptions.calculator:
      return "default";
    case CalculatorsTypeOptions.decision_tool:
      return "secondary";
    case CalculatorsTypeOptions.checklist:
      return "outline";
    default:
      return "secondary";
  }
};

export const columns: ExtendedColumnDef<DecisionToolWithRelations>[] = [
  // ESSENTIAL COLUMNS (Always Visible)
  {
    accessorKey: "name",
    header: ({ column }) => (
      <DataTableColumnHeader
        column={column}
        title="Tool Name"
        canSort={true}
        canFilter={true}
        filterType="text"
      />
    ),
    cell: ({ row }) => {
      const name = row.getValue("name") as string;
      const type = row.original.type;
      const icon = row.original.icon;

      return (
        <div className="flex items-center gap-2 font-medium">
          {icon ? <span className="text-lg">{icon}</span> : getTypeIcon(type)}
          <span>{name}</span>
        </div>
      );
    },
  },
  {
    accessorKey: "type",
    header: ({ column }) => (
      <DataTableColumnHeader
        column={column}
        title="Type"
        canSort={true}
        canFilter={true}
        filterType="select"
        filterOptions={[
          { label: "Calculator", value: "calculator" },
          { label: "Decision Tool", value: "decision_tool" },
          { label: "Checklist", value: "checklist" },
        ]}
      />
    ),
    cell: ({ row }) => {
      const type = row.getValue("type") as CalculatorsTypeOptions;
      const displayType =
        type === CalculatorsTypeOptions.decision_tool
          ? "Decision Tool"
          : type.charAt(0).toUpperCase() + type.slice(1);

      return (
        <Badge
          variant={
            getTypeVariant(type) as
              | "default"
              | "secondary"
              | "destructive"
              | "outline"
          }
        >
          {displayType}
        </Badge>
      );
    },
  },
  {
    accessorKey: "status",
    header: ({ column }) => (
      <DataTableColumnHeader
        column={column}
        title="Status"
        canSort={true}
        canFilter={true}
        filterType="select"
        filterOptions={[
          { label: "Active", value: "active" },
          { label: "Draft", value: "draft" },
          { label: "Archived", value: "archived" },
        ]}
      />
    ),
    cell: ({ row }) => {
      const status = row.getValue("status") as CalculatorsStatusOptions;
      const displayStatus = status.charAt(0).toUpperCase() + status.slice(1);

      return (
        <Badge
          variant={
            getStatusVariant(status) as
              | "default"
              | "secondary"
              | "destructive"
              | "outline"
          }
        >
          {displayStatus}
        </Badge>
      );
    },
  },
  {
    accessorKey: "description",
    header: ({ column }) => (
      <DataTableColumnHeader
        column={column}
        title="Description"
        canSort={false}
        canFilter={true}
        filterType="text"
      />
    ),
    cell: ({ row }) => {
      const description = row.getValue("description") as string;
      return description ? (
        <div className="max-w-xs truncate text-sm" title={description}>
          {description}
        </div>
      ) : (
        <span className="text-muted-foreground">—</span>
      );
    },
  },

  // ADDITIONAL INFORMATION (Hidden by default)
  {
    accessorKey: "version",
    defaultVisible: false,
    header: ({ column }) => (
      <DataTableColumnHeader
        column={column}
        title="Version"
        canSort={true}
        canFilter={true}
        filterType="text"
      />
    ),
    cell: ({ row }) => {
      const version = row.getValue("version") as string;
      return version ? (
        <Badge variant="outline" className="font-mono text-xs">
          v{version}
        </Badge>
      ) : (
        <span className="text-muted-foreground">—</span>
      );
    },
  },
  {
    accessorKey: "appFile",
    defaultVisible: false,
    header: ({ column }) => (
      <DataTableColumnHeader
        column={column}
        title="App File"
        canSort={false}
        canFilter={true}
        filterType="text"
      />
    ),
    cell: ({ row }) => {
      const appFile = getAppFileLabel(row.getValue("appFile"));
      return appFile ? (
        <div className="max-w-xs truncate font-mono text-xs" title={appFile}>
          {appFile}
        </div>
      ) : (
        <span className="text-muted-foreground">—</span>
      );
    },
  },

  // VISUAL PROPERTIES (Hidden by default)
  {
    accessorKey: "color",
    defaultVisible: false,
    header: ({ column }) => (
      <DataTableColumnHeader column={column} title="Color" canSort={false} />
    ),
    cell: ({ row }) => {
      const color = row.getValue("color") as string;
      return color ? (
        <div className="flex items-center gap-2">
          <div
            className="w-4 h-4 rounded border"
            style={{ backgroundColor: color }}
            title={color}
          />
          <span className="text-xs font-mono">{color}</span>
        </div>
      ) : (
        <span className="text-muted-foreground">—</span>
      );
    },
  },
  {
    accessorKey: "backgroundColor",
    defaultVisible: false,
    header: ({ column }) => (
      <DataTableColumnHeader
        column={column}
        title="Background Color"
        canSort={false}
      />
    ),
    cell: ({ row }) => {
      const bgColor = row.getValue("backgroundColor") as string;
      return bgColor ? (
        <div className="flex items-center gap-2">
          <div
            className="w-4 h-4 rounded border"
            style={{ backgroundColor: bgColor }}
            title={bgColor}
          />
          <span className="text-xs font-mono">{bgColor}</span>
        </div>
      ) : (
        <span className="text-muted-foreground">—</span>
      );
    },
  },

  // RELATIONS (Hidden by default)
  {
    id: "addedBy",
    header: ({ column }) => (
      <DataTableColumnHeader column={column} title="Added By" canSort={false} />
    ),
    accessorFn: (row) => {
      const addedBy = row.expand?.addedBy;
      if (Array.isArray(addedBy) && addedBy.length > 0) {
        return addedBy.map((user) => user.name || user.email).join(", ");
      }
      return "";
    },
    cell: ({ row }) => {
      const addedBy = row.original.expand?.addedBy;
      if (Array.isArray(addedBy) && addedBy.length > 0) {
        const names = addedBy.map((user) => user.name || user.email);
        if (names.length === 1) {
          return <span className="text-sm">{names[0]}</span>;
        } else {
          return (
            <span className="text-sm" title={names.join(", ")}>
              {names[0]} +{names.length - 1}
            </span>
          );
        }
      }
      return <span className="text-muted-foreground">—</span>;
    },
    defaultVisible: false,
  },

  // TIMESTAMPS (Hidden by default)
  {
    accessorKey: "created",
    defaultVisible: false,
    header: ({ column }) => (
      <DataTableColumnHeader
        column={column}
        title="Created"
        canSort={true}
        canFilter={true}
        filterType="dateRange"
      />
    ),
    cell: ({ row }) => {
      const date = row.getValue("created") as string;
      return date ? (
        <span className="text-xs text-muted-foreground">
          {new Date(date).toLocaleDateString()}
        </span>
      ) : (
        <span className="text-muted-foreground">—</span>
      );
    },
  },
  {
    accessorKey: "updated",
    defaultVisible: false,
    header: ({ column }) => (
      <DataTableColumnHeader
        column={column}
        title="Last Updated"
        canSort={true}
        canFilter={true}
        filterType="dateRange"
      />
    ),
    cell: ({ row }) => {
      const date = row.getValue("updated") as string;
      return date ? (
        <span className="text-xs text-muted-foreground">
          {new Date(date).toLocaleDateString()}
        </span>
      ) : (
        <span className="text-muted-foreground">—</span>
      );
    },
  },
];

// Re-export the type for use in other files
export type { DecisionToolWithRelations };
