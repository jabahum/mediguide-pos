"use client"

import * as React from "react"
import Link from "next/link"
import { usePathname } from "next/navigation"
import {
  Activity,
  Users,
  FileText,
  Settings,
  BarChart3,
  Pill,
  AlertTriangle,
  Calculator,
  UserCheck,
  Building2,
  TestTube,
  HeadphonesIcon
} from "lucide-react"

import {
  Collapsible,
  CollapsibleContent,
  CollapsibleTrigger,
} from "@/components/ui/collapsible"
import {
  Sidebar,
  SidebarContent,
  SidebarGroup,
  SidebarHeader,
  SidebarMenu,
  SidebarMenuButton,
  SidebarMenuItem,
  SidebarMenuSub,
  SidebarMenuSubButton,
  SidebarMenuSubItem,
  SidebarRail,
} from "@/components/ui/sidebar"
import { usePermissionContext } from "@/lib/permission-context"
import { hasBackendPermission } from "@/lib/backend-client"
import type { PermissionAction } from "@/types/permissions"

// Utility function to find if current pathname belongs to a menu item
function findActiveMenuItem(pathname: string, navItems: typeof data.navMain) {
  for (let i = 0; i < navItems.length; i++) {
    const item = navItems[i]
    
    // Check if any sub-item matches the current pathname (exact match)
    if (item.items) {
      const hasActiveChild = item.items.some(subItem => pathname === subItem.url)
      if (hasActiveChild) {
        return i
      }
      
      // Check if current pathname starts with any sub-item URL (for nested routes)
      const hasNestedActiveChild = item.items.some(subItem => {
        if (subItem.url === "/") return false // Skip root to avoid matching everything
        return pathname.startsWith(subItem.url + "/") || pathname === subItem.url
      })
      if (hasNestedActiveChild) {
        return i
      }
    }
    
    // Check if the main item URL matches (for overview pages)
    if (pathname === item.url && item.url !== "#") {
      return i
    }
    
    // Check if current pathname starts with the main item URL (for nested routes)
    if (item.url !== "#" && item.url !== "/" && pathname.startsWith(item.url + "/")) {
      return i
    }
  }
  return -1
}

type NavSubItem = {
  title: string
  url: string
  permission?: { resource: string; action: PermissionAction }
  backendPermissions?: string[]
}

type NavItem = {
  title: string
  url: string
  icon: React.ComponentType<{ className?: string }>
  permission?: { resource: string; action: PermissionAction }
  backendPermissions?: string[]
  items?: NavSubItem[]
}

// MediGuide navigation data
const data: { navMain: NavItem[] } = {
  navMain: [
    {
      title: "Dashboard",
      url: "/",
      icon: BarChart3,
      // always visible to all dashboard roles
    },
    {
      title: "Clinical Guidelines",
      url: "#",
      icon: FileText,
      permission: { resource: "content", action: "read:any" },
      items: [
        { title: "All Guidelines", url: "/guidelines" },
        { title: "Create Guideline", url: "/guidelines/create", permission: { resource: "content", action: "create:any" } },
        { title: "Index", url: "/guidelines/index" },
        { title: "Categories", url: "/guidelines/categories" },
        { title: "Tags", url: "/guidelines/tags" },
        { title: "Abbreviations", url: "/guidelines/abbreviations" },
      ],
    },
    {
      title: "Pages",
      url: "#",
      icon: FileText,
      permission: { resource: "content", action: "read:any" },
      items: [
        { title: "All Pages", url: "/pages" },
        { title: "Create Page", url: "/pages/create", permission: { resource: "content", action: "create:any" } },
      ],
    },
    {
      title: "Lab Test Menu",
      url: "/lab-test-menu",
      icon: TestTube,
      permission: { resource: "content", action: "read:any" },
    },
    {
      title: "Drug Index",
      url: "#",
      icon: Pill,
      permission: { resource: "content", action: "read:any" },
      items: [
        { title: "All Drugs", url: "/drugs" },
        { title: "Categories", url: "/drugs/categories" },
        { title: "Tags", url: "/drugs/tags" },
      ],
    },
    {
      title: "Emergency Protocols",
      url: "#",
      icon: AlertTriangle,
      permission: { resource: "content", action: "read:any" },
      items: [
        { title: "All Protocols", url: "/emergency-protocols" },
        { title: "Resuscitation", url: "/emergency-protocols/resuscitation" },
        { title: "Trauma", url: "/emergency-protocols/trauma" },
      ],
    },
    {
      title: "Outbreak Management",
      url: "#",
      icon: Activity,
      backendPermissions: ["outbreak.read", "situation_report.read"],
      items: [
        { title: "Outbreaks", url: "/outbreaks", backendPermissions: ["outbreak.read"] },
        { title: "Situation Reports", url: "/situation-reports", backendPermissions: ["situation_report.read"] },
        { title: "Outbreak Resources", url: "/outbreaks/resources", backendPermissions: ["outbreak.read"] },
        { title: "Publication Review", url: "/outbreaks/review", backendPermissions: ["outbreak.review", "outbreak.publish", "situation_report.review", "situation_report.publish"] },
      ],
    },
    {
      title: "Decision Tools",
      url: "#",
      icon: Calculator,
      permission: { resource: "content", action: "read:any" },
      items: [
        { title: "All Tools", url: "/decision-tools" },
        { title: "Calculators", url: "/decision-tools/calculators" },
        { title: "Checklists", url: "/decision-tools/checklists" },
      ],
    },
    {
      title: "User Management",
      url: "#",
      icon: Users,
      permission: { resource: "users", action: "read:any" },
      items: [
        { title: "All Users", url: "/users" },
        { title: "Roles & Permissions", url: "/users/roles", permission: { resource: "roles", action: "read:any" } },
      ],
    },
    {
      title: "Consultant Management",
      url: "#",
      icon: UserCheck,
      permission: { resource: "content", action: "read:any" },
      items: [
        { title: "All Consultants", url: "/consultants" },
        { title: "Add Consultant", url: "/consultants/create", permission: { resource: "content", action: "create:any" } },
        { title: "Verified Consultants", url: "/consultants?filter=verified" },
        { title: "Pending Approval", url: "/consultants?filter=pending" },
      ],
    },
    {
      title: "Health Facilities",
      url: "#",
      icon: Building2,
      permission: { resource: "content", action: "read:any" },
      items: [
        { title: "All Facilities", url: "/health-facilities" },
        { title: "Add Facility", url: "/health-facilities/create", permission: { resource: "content", action: "create:any" } },
        { title: "Regions", url: "/health-facilities/regions" },
        { title: "Health Sub-Regions", url: "/health-facilities/health-sub-regions" },
        { title: "Districts", url: "/health-facilities/districts" },
        { title: "Counties", url: "/health-facilities/counties" },
        { title: "Health Sub-Districts", url: "/health-facilities/health-sub-districts" },
        { title: "Subcounties", url: "/health-facilities/subcounties" },
        { title: "Parishes", url: "/health-facilities/parishes" },
        { title: "Ownership Types", url: "/health-facilities/ownership-types" },
        { title: "Authorities", url: "/health-facilities/authorities" },
        { title: "Facility Levels", url: "/health-facilities/facility-levels" },
      ],
    },
    {
      title: "Support",
      url: "#",
      icon: HeadphonesIcon,
      permission: { resource: "content", action: "read:any" },
      items: [
        { title: "Support Tickets", url: "/support" },
        { title: "Documentation", url: "/support/documentation" },
        { title: "FAQs", url: "/support/faqs" },
      ],
    },
    {
      title: "Settings",
      url: "#",
      icon: Settings,
      items: [
        { title: "Notifications", url: "/settings/notifications", backendPermissions: ["notification.publish", "notification.template.read", "notification.campaign.read", "firebase.status.read"] },
        { title: "Firebase", url: "/settings/firebase", backendPermissions: ["firebase.status.read", "firebase.push.test", "firebase.config.manage"] },
        { title: "Backup", url: "/settings/backup", permission: { resource: "system_settings", action: "read:any" } },
      ],
    },
  ],
}

export function AppSidebar({ ...props }: React.ComponentProps<typeof Sidebar>) {
  const pathname = usePathname()
  const { hasPermission, loading } = usePermissionContext()

  const visibleNav = React.useMemo<NavItem[]>(() => {
    if (loading) return []
    return data.navMain
      .filter(item =>
        (!item.permission || hasPermission(item.permission.resource, item.permission.action)) &&
        (!item.backendPermissions || item.backendPermissions.some(hasBackendPermission)),
      )
      .map(item => ({
        ...item,
        items: item.items?.filter(sub =>
          (!sub.permission || hasPermission(sub.permission.resource, sub.permission.action)) &&
          (!sub.backendPermissions || sub.backendPermissions.some(hasBackendPermission)),
        ),
      }))
      .filter(item => item.url !== "#" || !item.items || item.items.length > 0)
  }, [loading, hasPermission])

  // Find which menu item should be active/open based on current pathname
  const activeMenuIndex = findActiveMenuItem(pathname, visibleNav)
  
  // State to track which menu items are open
  const [openItems, setOpenItems] = React.useState<Set<number>>(() => {
    const initialOpen = new Set<number>()
    
    // Always open the dashboard (index 0) by default
    initialOpen.add(0)
    
    // Open the menu item that contains the active route
    if (activeMenuIndex !== -1) {
      initialOpen.add(activeMenuIndex)
    }
    
    return initialOpen
  })
  
  // Update open items when pathname changes
  React.useEffect(() => {
    if (activeMenuIndex !== -1) {
      setOpenItems(prev => new Set(prev).add(activeMenuIndex))
    }
  }, [activeMenuIndex])
  
  // Handle toggle of menu items
  const toggleMenuItem = React.useCallback((index: number) => {
    setOpenItems(prev => {
      const newSet = new Set(prev)
      if (newSet.has(index)) {
        newSet.delete(index)
      } else {
        newSet.add(index)
      }
      return newSet
    })
  }, [])

  return (
    <Sidebar {...props}>
      <SidebarHeader>
        <SidebarMenu>
          <SidebarMenuItem>
            <SidebarMenuButton size="lg" asChild>
              <Link href="/">
                <div className="bg-sidebar-primary text-sidebar-primary-foreground flex aspect-square size-8 items-center justify-center rounded-lg">
                  <Activity className="size-4" />
                </div>
                <div className="flex flex-col gap-0.5 leading-none">
                  <span className="font-medium">MediGuide</span>
                  <span className="">Dashboard</span>
                </div>
              </Link>
            </SidebarMenuButton>
          </SidebarMenuItem>
        </SidebarMenu>
      </SidebarHeader>
      <SidebarContent>
        <SidebarGroup>
          <SidebarMenu>
            {visibleNav.map((item, index) => {
              // If item has no subitems and a direct URL, render as direct link
              if (!item.items?.length && item.url !== "#") {
                return (
                  <SidebarMenuItem key={item.title}>
                    <SidebarMenuButton asChild isActive={pathname === item.url}>
                      <Link href={item.url}>
                        <item.icon className="mr-2 size-4" />
                        {item.title}
                      </Link>
                    </SidebarMenuButton>
                  </SidebarMenuItem>
                )
              }

              // Render as collapsible for items with subitems
              return (
                <Collapsible
                  key={item.title}
                  open={openItems.has(index)}
                  onOpenChange={() => toggleMenuItem(index)}
                  className="group/collapsible"
                >
                  <SidebarMenuItem>
                    <CollapsibleTrigger asChild>
                      <SidebarMenuButton>
                        <item.icon className="mr-2 size-4" />
                        {item.title}
                      </SidebarMenuButton>
                    </CollapsibleTrigger>
                    {item.items?.length ? (
                      <CollapsibleContent>
                        <SidebarMenuSub>
                          {item.items.map((subItem) => (
                            <SidebarMenuSubItem key={subItem.title}>
                              <SidebarMenuSubButton
                                asChild
                                isActive={pathname === subItem.url}
                              >
                                <Link href={subItem.url}>{subItem.title}</Link>
                              </SidebarMenuSubButton>
                            </SidebarMenuSubItem>
                          ))}
                        </SidebarMenuSub>
                      </CollapsibleContent>
                    ) : null}
                  </SidebarMenuItem>
                </Collapsible>
              )
            })}
          </SidebarMenu>
        </SidebarGroup>
      </SidebarContent>
      <SidebarRail />
    </Sidebar>
  )
}
