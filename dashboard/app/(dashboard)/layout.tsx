"use client"

import * as React from "react"
import Link from "next/link"
import { useRouter } from "next/navigation"
import { AppSidebar } from "@/components/app-sidebar"
import {
  Breadcrumb,
  BreadcrumbItem,
  BreadcrumbLink,
  BreadcrumbList,
  BreadcrumbPage,
  BreadcrumbSeparator,
} from "@/components/ui/breadcrumb"
import { Separator } from "@/components/ui/separator"
import {
  SidebarInset,
  SidebarProvider,
  SidebarTrigger,
} from "@/components/ui/sidebar"
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuLabel,
  DropdownMenuSeparator,
  DropdownMenuTrigger,
} from "@/components/ui/dropdown-menu"
import { Button } from "@/components/ui/button"
import { Avatar, AvatarFallback, AvatarImage } from "@/components/ui/avatar"
import { Bell, User, Settings, LogOut } from "lucide-react"
import AuthGuard from "@/components/auth-guard"
import { logout, getUserRole, getCurrentUser, getBackendClient } from "@/lib/backend-client"
import { ThemeToggle } from "@/components/theme-toggle"
import { showToast } from "@/lib/toast"
import { PermissionProvider, usePermissionContext } from "@/lib/permission-context"
import { UsersResponse } from "@/types/backend-types"

export default function DashboardLayout({
  children,
}: {
  children: React.ReactNode
}) {
  const router = useRouter()
  const userRole = getUserRole() ?? undefined
  const [currentUser, setCurrentUser] = React.useState<UsersResponse | null>(null)

  React.useEffect(() => {
    const authUser = getCurrentUser()
    if (!authUser?.id) return
    getBackendClient().resource("users").getOne(authUser.id)
      .then(u => setCurrentUser(u as UsersResponse))
      .catch(() => {})
  }, [])

  const initials = currentUser?.name
    ? currentUser.name.split(" ").map(n => n[0]).join("").toUpperCase().slice(0, 2)
    : "?"

  const avatarSrc = currentUser?.avatar
    ? getBackendClient().files.getURL(currentUser, currentUser.avatar as string)
    : ""

  const handleLogout = async () => {
    try {
      await logout()
      showToast.success("Logged out", "You have been successfully logged out")
      router.push("/login")
    } catch (error) {
      showToast.error("Logout failed", "There was an error logging you out")
      console.error("Logout error:", error)
    }
  }

  return (
    <AuthGuard>
      <PermissionProvider userRole={userRole}>
      <SidebarProvider>
        <AppSidebar />
        <SidebarInset>
          <header className="sticky top-0 z-40 flex h-16 shrink-0 items-center gap-2 border-b bg-background px-4">
            <SidebarTrigger className="-ml-1" />
            <Separator
              orientation="vertical"
              className="mr-2 data-[orientation=vertical]:h-4"
            />
            <Breadcrumb>
              <BreadcrumbList>
                <BreadcrumbItem className="hidden md:block">
                  <BreadcrumbLink asChild>
                    <Link href="/">MediGuide Dashboard</Link>
                  </BreadcrumbLink>
                </BreadcrumbItem>
                <BreadcrumbSeparator className="hidden md:block" />
                <BreadcrumbItem>
                  <BreadcrumbPage>Overview</BreadcrumbPage>
                </BreadcrumbItem>
              </BreadcrumbList>
            </Breadcrumb>
            
            <div className="ml-auto flex items-center gap-2">
              <HeaderNotificationButton />
              <ThemeToggle />
              <DropdownMenu>
                <DropdownMenuTrigger asChild>
                  <Button variant="outline" size="icon" className="overflow-hidden rounded-full">
                    <Avatar>
                      <AvatarImage src={avatarSrc} alt={currentUser?.name ?? "User"} />
                      <AvatarFallback>{initials}</AvatarFallback>
                    </Avatar>
                  </Button>
                </DropdownMenuTrigger>
                <DropdownMenuContent align="end">
                  <DropdownMenuLabel>My Account</DropdownMenuLabel>
                  <DropdownMenuSeparator />
                  <DropdownMenuItem onClick={() => router.push("/profile")}>
                    <User className="mr-2 h-4 w-4" />
                    Profile
                  </DropdownMenuItem>
                  <DropdownMenuItem onClick={() => router.push("/settings")}>
                    <Settings className="mr-2 h-4 w-4" />
                    Settings
                  </DropdownMenuItem>
                  <DropdownMenuSeparator />
                  <DropdownMenuItem onClick={handleLogout}>
                    <LogOut className="mr-2 h-4 w-4" />
                    Logout
                  </DropdownMenuItem>
                </DropdownMenuContent>
              </DropdownMenu>
            </div>
          </header>
          <div className="flex flex-1 flex-col gap-4 p-4 min-w-0 overflow-x-hidden">
            {children}
          </div>
        </SidebarInset>
      </SidebarProvider>
      </PermissionProvider>
    </AuthGuard>
  )
}

function HeaderNotificationButton() {
  const { hasPermission, loading } = usePermissionContext()

  if (loading || !hasPermission("system_settings", "read:any")) {
    return null
  }

  return (
    <Button variant="outline" size="icon" asChild>
      <Link href="/notifications" aria-label="Notifications">
        <Bell className="h-4 w-4" />
      </Link>
    </Button>
  )
}
