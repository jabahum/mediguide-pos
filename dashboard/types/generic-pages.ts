/**
 * Extended types for Generic Pages functionality
 * Builds on top of legacy collection API generated types
 */

import type { GenericPagesRecord, GenericPagesResponse } from "@/types/backend-types"

// Content structure for the JSON field
export interface GenericPageContent {
  title: string
  content: string  // HTML from WYSIWYG editor
}

export interface GenericPageContentCollection {
  [key: string]: GenericPageContent
}

// Typed version of GenericPagesRecord with proper content typing
// Content can be null when page is first created
export type TypedGenericPagesRecord = GenericPagesRecord<GenericPageContentCollection | null>
export type TypedGenericPagesResponse = GenericPagesResponse<GenericPageContentCollection | null>

// Dialog Props Types
export interface GenericPageInfoDialogProps {
  pageKey: string
  currentTitle: string
  currentDescription?: string
  open: boolean
  onOpenChange: (open: boolean) => void
  onSuccess: () => void
}

export interface GenericContentDialogProps {
  pageKey: string
  contentKey?: string
  mode: 'add' | 'edit'
  existingContent?: GenericPageContent
  open: boolean
  onOpenChange: (open: boolean) => void
  onSuccess: () => void
}


// Form data types
export interface GenericPageInfoFormData {
  title: string
  description?: string
}

export interface GenericContentFormData {
  title: string
  content: string
}