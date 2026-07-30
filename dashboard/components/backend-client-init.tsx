"use client"

import { useEffect } from "react"
import { createBackendClient } from "@/lib/backend-client"

export function BackendClientInit() {
  useEffect(() => {
    createBackendClient()
  }, [])

  return null
}
