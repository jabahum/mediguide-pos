"use client"

import { useRouter } from "next/navigation"
import { Bell, Database, ArrowRight } from "lucide-react"

import { PageHeader } from "@/components/ui/page-header"
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card"

type SettingSection = {
  title: string
  description: string
  icon: React.ComponentType<{ className?: string }>
  href: string
}

const sections: SettingSection[] = [
  {
    title: "Notifications",
    description: "Manage in-app notices and inspect notification channel configuration",
    icon: Bell,
    href: "/settings/notifications",
  },
  {
    title: "Backup & Recovery",
    description: "Manage data backups, restore points, and recovery options",
    icon: Database,
    href: "/settings/backup",
  },
]

export default function SettingsPage() {
  const router = useRouter()

  return (
    <div className="space-y-6">
      <PageHeader
        title="Settings"
        description="Manage system configuration and preferences"
      />

      <div className="grid gap-4 md:grid-cols-2">
        {sections.map((section) => {
          const Icon = section.icon
          return (
            <Card
              key={section.href}
              className="cursor-pointer hover:shadow-md transition-shadow"
              onClick={() => router.push(section.href)}
            >
              <CardHeader>
                <div className="flex items-start justify-between">
                  <div className="flex items-center space-x-3">
                    <div className="rounded-md bg-primary/10 p-2 text-primary">
                      <Icon className="h-5 w-5" />
                    </div>
                    <CardTitle>{section.title}</CardTitle>
                  </div>
                  <ArrowRight className="h-4 w-4 text-muted-foreground" />
                </div>
              </CardHeader>
              <CardContent>
                <CardDescription>{section.description}</CardDescription>
              </CardContent>
            </Card>
          )
        })}
      </div>
    </div>
  )
}
