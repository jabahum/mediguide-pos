'use client'

import { useState, useEffect, useCallback } from "react"
import { useRouter } from "next/navigation"
import { usePermissionContext } from "@/lib/permission-context"
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Label } from "@/components/ui/label"
import { Badge } from "@/components/ui/badge"
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs"
import { Dialog, DialogContent, DialogDescription, DialogHeader, DialogTitle, DialogTrigger } from "@/components/ui/dialog"
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select"
import { Textarea } from "@/components/ui/textarea"
import { Switch } from "@/components/ui/switch"
import { Alert, AlertDescription } from "@/components/ui/alert"
import { Separator } from "@/components/ui/separator"
import { PageHeader } from "@/components/ui/page-header"
import {
  Bell,
  Send,
  Mail,
  Smartphone,
  MessageCircle,
  Users,
  Settings,
  Plus,
  Filter,
  Calendar,
  Clock,
  CheckCircle,
  AlertTriangle,
  Target,
  Zap,
  Eye,
  Edit,
  Copy,
  Trash2,
  Play,
  Pause,
  BarChart3,
  TrendingUp,
  RefreshCw,
  Loader2
} from "lucide-react"
import { showToast } from "@/lib/toast"
import { backendClient } from "@/lib/backend-client"
import { Collections } from "@/types/backend-types"
import type {
  NotificationTemplatesResponse,
  NotificationCampaignsResponse,
  NotificationTemplatesTypeOptions,
  NotificationTemplatesStatusOptions,
  NotificationTemplatesCategoryOptions,
  NotificationCampaignsTypeOptions,
  NotificationCampaignsStatusOptions
} from "@/types/backend-types"

export default function NotificationsPage() {
  const router = useRouter()
  const { hasPermission, loading: permLoading } = usePermissionContext()
  const [testMode, setTestMode] = useState(false)
  const [templates, setTemplates] = useState<NotificationTemplatesResponse[]>([])
  const [campaigns, setCampaigns] = useState<NotificationCampaignsResponse[]>([])
  const [stats, setStats] = useState({
    totalSent: 0,
    deliveryRate: 0,
    openRate: 0,
    activeTemplates: 0
  })
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    if (permLoading) return
    if (!hasPermission("system_settings", "read:any")) {
      router.replace("/")
    }
  }, [permLoading, hasPermission, router])

  const fetchData = useCallback(async () => {
    try {
      const [templatesResult, campaignsResult] = await Promise.all([
        backendClient.collection(Collections.NotificationTemplates).getList(1, 50),
        backendClient.collection(Collections.NotificationCampaigns).getList(1, 50)
      ])

      setTemplates(templatesResult.items as NotificationTemplatesResponse[])
      setCampaigns(campaignsResult.items as NotificationCampaignsResponse[])

      // Calculate stats
      const totalSent = templatesResult.items.reduce((sum, t) => sum + (t.sent_count || 0), 0)
      const totalOpened = templatesResult.items.reduce((sum, t) => sum + (t.opened_count || 0), 0)
      const totalDelivered = campaignsResult.items.reduce((sum, c) => sum + (c.metrics_delivered || 0), 0)
      const activeTemplates = templatesResult.items.filter(t => t.status === "active").length

      const deliveryRate = totalSent > 0 ? (totalDelivered / totalSent) * 100 : 0
      const openRate = totalSent > 0 ? (totalOpened / totalSent) * 100 : 0

      setStats({
        totalSent,
        deliveryRate: parseFloat(deliveryRate.toFixed(1)),
        openRate: parseFloat(openRate.toFixed(1)),
        activeTemplates
      })
    } catch (error) {
      console.error("Failed to fetch notification data:", error)
      showToast.error("Error", "Failed to load notification data")
    } finally {
      setLoading(false)
    }
  }, [])

  useEffect(() => {
    fetchData()
  }, [fetchData])

  const getStatusBadge = (status: NotificationTemplatesStatusOptions | NotificationCampaignsStatusOptions | string) => {
    switch (status) {
      case "active":
        return <Badge variant="default" className="bg-green-500"><CheckCircle className="w-3 h-3 mr-1" />Active</Badge>
      case "inactive":
        return <Badge variant="secondary">Inactive</Badge>
      case "draft":
        return <Badge variant="outline">Draft</Badge>
      case "scheduled":
        return <Badge variant="outline"><Clock className="w-3 h-3 mr-1" />Scheduled</Badge>
      case "running":
        return <Badge variant="default" className="bg-blue-500"><Play className="w-3 h-3 mr-1" />Running</Badge>
      case "completed":
        return <Badge variant="default" className="bg-green-500"><CheckCircle className="w-3 h-3 mr-1" />Completed</Badge>
      case "paused":
        return <Badge variant="secondary"><Pause className="w-3 h-3 mr-1" />Paused</Badge>
      default:
        return <Badge variant="outline">{status}</Badge>
    }
  }

  const getTypeBadge = (type: NotificationTemplatesTypeOptions | NotificationCampaignsTypeOptions | string) => {
    switch (type) {
      case "push":
        return <Badge variant="default"><Bell className="w-3 h-3 mr-1" />Push</Badge>
      case "email":
        return <Badge variant="secondary"><Mail className="w-3 h-3 mr-1" />Email</Badge>
      case "sms":
        return <Badge variant="outline"><Smartphone className="w-3 h-3 mr-1" />SMS</Badge>
      case "in-app":
        return <Badge variant="outline"><MessageCircle className="w-3 h-3 mr-1" />In-App</Badge>
      case "emergency":
        return <Badge variant="destructive"><AlertTriangle className="w-3 h-3 mr-1" />Emergency</Badge>
      case "update":
        return <Badge variant="default"><RefreshCw className="w-3 h-3 mr-1" />Update</Badge>
      case "reminder":
        return <Badge variant="secondary"><Clock className="w-3 h-3 mr-1" />Reminder</Badge>
      case "marketing":
        return <Badge variant="outline"><Target className="w-3 h-3 mr-1" />Marketing</Badge>
      default:
        return <Badge variant="outline">{type}</Badge>
    }
  }

  const handleSendTest = (templateId: string) => {
    showToast.loading("Sending test notification...")
    setTimeout(() => {
      showToast.success("Test sent", `Test notification for template ${templateId} sent successfully`)
    }, 2000)
  }

  const handleToggleTemplate = async (templateId: string, currentStatus: string) => {
    const newStatus = currentStatus === "active" ? "inactive" : "active"
    try {
      await backendClient.collection(Collections.NotificationTemplates).update(templateId, { status: newStatus })
      showToast.success(
        newStatus === "active" ? "Template activated" : "Template deactivated",
        `Notification template has been ${newStatus === "active" ? 'activated' : 'deactivated'}`
      )
      fetchData()
    } catch (error) {
      showToast.error("Error", "Failed to update template status")
    }
  }

  const handleCampaignAction = async (campaignId: string, action: string) => {
    try {
      let newStatus = "running"
      if (action === "pause") newStatus = "paused"
      if (action === "resume") newStatus = "running"
      if (action === "stop") newStatus = "completed"

      await backendClient.collection(Collections.NotificationCampaigns).update(campaignId, { status: newStatus })
      showToast.success(`Campaign ${action}ed`, `Campaign has been ${action}ed`)
      fetchData()
    } catch (error) {
      showToast.error("Error", `Failed to ${action} campaign`)
    }
  }

  if (loading) {
    return (
      <div className="space-y-6">
        <PageHeader
          title="Notification Management"
          description="Manage push notifications, emails, and communication campaigns"
        />
        <div className="flex items-center justify-center h-64">
          <Loader2 className="h-8 w-8 animate-spin" />
        </div>
      </div>
    )
  }

  return (
    <div className="space-y-6">
      <PageHeader
        title="Notification Management"
        description="Manage push notifications, emails, and communication campaigns"
      />

      <div className="flex flex-wrap items-center gap-3">
        <div className="flex items-center gap-2">
          <Label htmlFor="test-mode" className="text-sm">Test Mode</Label>
          <Switch id="test-mode" checked={testMode} onCheckedChange={setTestMode} />
        </div>
        <Button variant="outline">
          <Settings className="mr-2 h-4 w-4" />
          Settings
        </Button>
        <Dialog>
          <DialogTrigger asChild>
            <Button>
              <Plus className="mr-2 h-4 w-4" />
              New Campaign
            </Button>
          </DialogTrigger>
          <DialogContent className="sm:max-w-[500px]">
            <DialogHeader>
              <DialogTitle>Create Campaign</DialogTitle>
              <DialogDescription>
                Set up a new notification campaign
              </DialogDescription>
            </DialogHeader>
            <div className="grid gap-4 py-4">
              <div className="grid gap-2">
                <Label htmlFor="campaign-name">Campaign Name</Label>
                <Input id="campaign-name" placeholder="e.g., Monthly Health Update" />
              </div>
              <div className="grid gap-2">
                <Label htmlFor="campaign-type">Campaign Type</Label>
                <Select>
                  <SelectTrigger>
                    <SelectValue placeholder="Select type" />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="emergency">Emergency</SelectItem>
                    <SelectItem value="update">Update</SelectItem>
                    <SelectItem value="reminder">Reminder</SelectItem>
                    <SelectItem value="marketing">Marketing</SelectItem>
                  </SelectContent>
                </Select>
              </div>
              <div className="grid gap-2">
                <Label>Notification Channels</Label>
                <div className="flex flex-wrap gap-2">
                  <div className="flex items-center space-x-2">
                    <Switch id="push" defaultChecked />
                    <Label htmlFor="push" className="text-sm">Push</Label>
                  </div>
                  <div className="flex items-center space-x-2">
                    <Switch id="email" />
                    <Label htmlFor="email" className="text-sm">Email</Label>
                  </div>
                  <div className="flex items-center space-x-2">
                    <Switch id="sms" />
                    <Label htmlFor="sms" className="text-sm">SMS</Label>
                  </div>
                </div>
              </div>
              <div className="grid gap-2">
                <Label htmlFor="campaign-message">Message</Label>
                <Textarea id="campaign-message" placeholder="Enter your message..." />
              </div>
              <div className="grid gap-2">
                <Label htmlFor="campaign-schedule">Schedule</Label>
                <Input id="campaign-schedule" type="datetime-local" />
              </div>
            </div>
            <div className="flex justify-end space-x-2">
              <Button variant="outline">Cancel</Button>
              <Button>Create Campaign</Button>
            </div>
          </DialogContent>
        </Dialog>
      </div>

      {testMode && (
        <Alert>
          <Zap className="h-4 w-4" />
          <AlertDescription>
            Test Mode is enabled. All notifications will be sent to test recipients only.
          </AlertDescription>
        </Alert>
      )}

      {/* Overview Stats */}
      <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-4">
        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 backendClient-2">
            <CardTitle className="text-sm font-medium">Total Sent</CardTitle>
            <Send className="h-4 w-4 text-blue-500" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">{stats.totalSent.toLocaleString()}</div>
            <p className="text-xs text-muted-foreground">
              All time
            </p>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 backendClient-2">
            <CardTitle className="text-sm font-medium">Delivery Rate</CardTitle>
            <CheckCircle className="h-4 w-4 text-green-500" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">{stats.deliveryRate}%</div>
            <p className="text-xs text-muted-foreground">
              Based on campaign metrics
            </p>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 backendClient-2">
            <CardTitle className="text-sm font-medium">Open Rate</CardTitle>
            <Eye className="h-4 w-4 text-orange-500" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">{stats.openRate}%</div>
            <p className="text-xs text-muted-foreground">
              Template open rate
            </p>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 backendClient-2">
            <CardTitle className="text-sm font-medium">Active Templates</CardTitle>
            <Bell className="h-4 w-4 text-purple-500" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">{stats.activeTemplates}</div>
            <p className="text-xs text-muted-foreground">
              {campaigns.filter(c => c.status === "running").length} campaigns running
            </p>
          </CardContent>
        </Card>
      </div>

      <Tabs defaultValue="templates" className="space-y-4">
        <TabsList>
          <TabsTrigger value="templates">Templates</TabsTrigger>
          <TabsTrigger value="campaigns">Campaigns</TabsTrigger>
          <TabsTrigger value="analytics">Analytics</TabsTrigger>
          <TabsTrigger value="channels">Channels</TabsTrigger>
        </TabsList>

        <TabsContent value="templates" className="space-y-4">
          <Card>
            <CardHeader>
              <div className="flex items-center justify-between">
                <div>
                  <CardTitle>Notification Templates</CardTitle>
                  <CardDescription>Manage reusable notification templates</CardDescription>
                </div>
                <div className="flex space-x-2">
                  <Button variant="outline" size="sm">
                    <Filter className="mr-2 h-4 w-4" />
                    Filter
                  </Button>
                  <Dialog>
                    <DialogTrigger asChild>
                      <Button size="sm">
                        <Plus className="mr-2 h-4 w-4" />
                        New Template
                      </Button>
                    </DialogTrigger>
                    <DialogContent className="sm:max-w-[600px]">
                      <DialogHeader>
                        <DialogTitle>Create Template</DialogTitle>
                        <DialogDescription>
                          Create a new notification template
                        </DialogDescription>
                      </DialogHeader>
                      <div className="grid gap-4 py-4">
                        <div className="grid gap-2">
                          <Label htmlFor="template-name">Template Name</Label>
                          <Input id="template-name" placeholder="e.g., New Guideline Alert" />
                        </div>
                        <div className="grid grid-cols-2 gap-4">
                          <div className="grid gap-2">
                            <Label htmlFor="template-type">Type</Label>
                            <Select>
                              <SelectTrigger>
                                <SelectValue placeholder="Select type" />
                              </SelectTrigger>
                              <SelectContent>
                                <SelectItem value="push">Push</SelectItem>
                                <SelectItem value="email">Email</SelectItem>
                                <SelectItem value="sms">SMS</SelectItem>
                                <SelectItem value="in-app">In-App</SelectItem>
                              </SelectContent>
                            </Select>
                          </div>
                          <div className="grid gap-2">
                            <Label htmlFor="template-category">Category</Label>
                            <Select>
                              <SelectTrigger>
                                <SelectValue placeholder="Select category" />
                              </SelectTrigger>
                              <SelectContent>
                                <SelectItem value="Content Updates">Content Updates</SelectItem>
                                <SelectItem value="Emergency">Emergency</SelectItem>
                                <SelectItem value="Training">Training</SelectItem>
                                <SelectItem value="System">System</SelectItem>
                                <SelectItem value="Marketing">Marketing</SelectItem>
                              </SelectContent>
                            </Select>
                          </div>
                        </div>
                        <div className="grid gap-2">
                          <Label htmlFor="template-subject">Subject</Label>
                          <Input id="template-subject" placeholder="Notification subject line" />
                        </div>
                        <div className="grid gap-2">
                          <Label htmlFor="template-content">Content</Label>
                          <Textarea id="template-content" placeholder="Enter template content... Use {{variable}} for dynamic content" />
                        </div>
                        <div className="grid gap-2">
                          <Label htmlFor="template-audience">Target Audience</Label>
                          <Input id="template-audience" placeholder="e.g., All Users, Doctors, Nurses" />
                        </div>
                      </div>
                      <div className="flex justify-end space-x-2">
                        <Button variant="outline">Cancel</Button>
                        <Button>Create Template</Button>
                      </div>
                    </DialogContent>
                  </Dialog>
                </div>
              </div>
            </CardHeader>
            <CardContent>
              <div className="space-y-4">
                {templates.length === 0 ? (
                  <div className="text-center py-8">
                    <p className="text-muted-foreground">No notification templates found</p>
                    <Button variant="outline" className="mt-4">Create Template</Button>
                  </div>
                ) : (
                  templates.map((template) => (
                    <div key={template.id} className="flex items-center justify-between p-4 border rounded-lg hover:bg-muted/50 transition-colors">
                      <div className="flex items-start space-x-4">
                        <div className="mt-1">
                          {template.type === "push" && <Bell className="h-5 w-5 text-blue-500" />}
                          {template.type === "email" && <Mail className="h-5 w-5 text-green-500" />}
                          {template.type === "sms" && <Smartphone className="h-5 w-5 text-purple-500" />}
                          {template.type === "in-app" && <MessageCircle className="h-5 w-5 text-orange-500" />}
                        </div>
                        <div className="space-y-1">
                          <div className="flex items-center space-x-2">
                            <h4 className="font-semibold">{template.name}</h4>
                            {getTypeBadge(template.type)}
                            {getStatusBadge(template.status)}
                            <Badge variant="outline">{template.category}</Badge>
                          </div>
                          <p className="text-sm text-muted-foreground">{template.subject}</p>
                          <p className="text-xs text-muted-foreground">
                            Audience: {template.audience}
                          </p>
                          {template.sent_count ? (
                            <div className="flex items-center space-x-3 text-xs text-muted-foreground">
                              <span>Sent: {template.sent_count.toLocaleString()}</span>
                              {template.opened_count ? <span>Opened: {template.opened_count.toLocaleString()}</span> : null}
                              {template.clicked_count ? <span>Clicked: {template.clicked_count.toLocaleString()}</span> : null}
                            </div>
                          ) : null}
                          {template.last_sent ? (
                            <p className="text-xs text-muted-foreground">
                              Last sent: {new Date(template.last_sent).toLocaleString()}
                            </p>
                          ) : (
                            <p className="text-xs text-muted-foreground italic">Never sent</p>
                          )}
                        </div>
                      </div>
                      <div className="flex items-center space-x-2">
                        <Button
                          variant="ghost"
                          size="sm"
                          onClick={() => handleSendTest(template.id)}
                        >
                          <Zap className="h-4 w-4 mr-1" />
                          Test
                        </Button>
                        <Switch
                          checked={template.status === "active"}
                          onCheckedChange={() => handleToggleTemplate(template.id, template.status)}
                        />
                        <Button variant="ghost" size="icon">
                          <Edit className="h-4 w-4" />
                        </Button>
                        <Button variant="ghost" size="icon">
                          <Copy className="h-4 w-4" />
                        </Button>
                        <Button variant="ghost" size="icon">
                          <Trash2 className="h-4 w-4" />
                        </Button>
                      </div>
                    </div>
                  ))
                )}
              </div>
            </CardContent>
          </Card>
        </TabsContent>

        <TabsContent value="campaigns" className="space-y-4">
          <Card>
            <CardHeader>
              <div className="flex items-center justify-between">
                <div>
                  <CardTitle>Active Campaigns</CardTitle>
                  <CardDescription>Manage notification campaigns and broadcasts</CardDescription>
                </div>
                <Button size="sm">
                  <Plus className="mr-2 h-4 w-4" />
                  New Campaign
                </Button>
              </div>
            </CardHeader>
            <CardContent>
              <div className="space-y-4">
                {campaigns.length === 0 ? (
                  <div className="text-center py-8">
                    <p className="text-muted-foreground">No campaigns found</p>
                    <Button variant="outline" className="mt-4">Create Campaign</Button>
                  </div>
                ) : (
                  campaigns.map((campaign) => (
                    <div key={campaign.id} className="p-4 border rounded-lg hover:bg-muted/50 transition-colors">
                      <div className="flex items-start justify-between">
                        <div className="space-y-1 flex-1">
                          <div className="flex items-center space-x-2">
                            <h4 className="font-semibold">{campaign.name}</h4>
                            {getTypeBadge(campaign.type)}
                            {getStatusBadge(campaign.status)}
                          </div>
                          <div className="flex items-center space-x-4 text-sm text-muted-foreground">
                            <span className="flex items-center">
                              <Users className="w-4 h-4 mr-1" />
                              {campaign.audience_total?.toLocaleString() || 0} recipients
                            </span>
                            <span className="flex items-center">
                              <Bell className="w-4 h-4 mr-1" />
                              {(campaign.channels as string[])?.join(", ") || "N/A"}
                            </span>
                            <span className="flex items-center">
                              <Calendar className="w-4 h-4 mr-1" />
                              {campaign.schedule_start ? new Date(campaign.schedule_start).toLocaleDateString() : "Not scheduled"}
                            </span>
                          </div>
                          <div className="mt-3 grid grid-cols-4 gap-4 p-3 bg-muted rounded-lg">
                            <div className="text-center">
                              <div className="text-lg font-bold">{campaign.metrics_sent?.toLocaleString() || 0}</div>
                              <div className="text-xs text-muted-foreground">Sent</div>
                            </div>
                            <div className="text-center">
                              <div className="text-lg font-bold">{campaign.metrics_delivered?.toLocaleString() || 0}</div>
                              <div className="text-xs text-muted-foreground">Delivered</div>
                            </div>
                            <div className="text-center">
                              <div className="text-lg font-bold">{campaign.metrics_opened?.toLocaleString() || 0}</div>
                              <div className="text-xs text-muted-foreground">Opened</div>
                            </div>
                            <div className="text-center">
                              <div className="text-lg font-bold">{campaign.metrics_clicked?.toLocaleString() || 0}</div>
                              <div className="text-xs text-muted-foreground">Clicked</div>
                            </div>
                          </div>
                        </div>
                        <div className="flex items-center space-x-2 ml-4">
                          {campaign.status === "running" && (
                            <Button
                              variant="outline"
                              size="sm"
                              onClick={() => handleCampaignAction(campaign.id, "pause")}
                            >
                              <Pause className="h-4 w-4 mr-1" />
                              Pause
                            </Button>
                          )}
                          {campaign.status === "paused" && (
                            <Button
                              variant="outline"
                              size="sm"
                              onClick={() => handleCampaignAction(campaign.id, "resume")}
                            >
                              <Play className="h-4 w-4 mr-1" />
                              Resume
                            </Button>
                          )}
                          {(campaign.status === "running" || campaign.status === "paused") && (
                            <Button
                              variant="outline"
                              size="sm"
                              onClick={() => handleCampaignAction(campaign.id, "stop")}
                            >
                              Stop
                            </Button>
                          )}
                          <Button variant="ghost" size="icon">
                            <BarChart3 className="h-4 w-4" />
                          </Button>
                          <Button variant="ghost" size="icon">
                            <Edit className="h-4 w-4" />
                          </Button>
                          <Button variant="ghost" size="icon">
                            <Trash2 className="h-4 w-4" />
                          </Button>
                        </div>
                      </div>
                    </div>
                  ))
                )}
              </div>
            </CardContent>
          </Card>
        </TabsContent>

        <TabsContent value="analytics" className="space-y-4">
          <Card>
            <CardHeader>
              <CardTitle>Notification Analytics</CardTitle>
              <CardDescription>Track performance metrics and user engagement</CardDescription>
            </CardHeader>
            <CardContent>
              <div className="space-y-6">
                <div className="grid gap-4 md:grid-cols-3">
                  <Card>
                    <CardHeader className="flex flex-row items-center justify-between space-y-0 backendClient-2">
                      <CardTitle className="text-sm font-medium">Delivery Trends</CardTitle>
                      <TrendingUp className="h-4 w-4 text-muted-foreground" />
                    </CardHeader>
                    <CardContent>
                      <div className="text-2xl font-bold">{stats.deliveryRate}%</div>
                      <p className="text-xs text-muted-foreground">Avg. delivery rate</p>
                    </CardContent>
                  </Card>
                  <Card>
                    <CardHeader className="flex flex-row items-center justify-between space-y-0 backendClient-2">
                      <CardTitle className="text-sm font-medium">Engagement</CardTitle>
                      <Eye className="h-4 w-4 text-muted-foreground" />
                    </CardHeader>
                    <CardContent>
                      <div className="text-2xl font-bold">{stats.openRate}%</div>
                      <p className="text-xs text-muted-foreground">Avg. open rate</p>
                    </CardContent>
                  </Card>
                  <Card>
                    <CardHeader className="flex flex-row items-center justify-between space-y-0 backendClient-2">
                      <CardTitle className="text-sm font-medium">Total Reach</CardTitle>
                      <Users className="h-4 w-4 text-muted-foreground" />
                    </CardHeader>
                    <CardContent>
                      <div className="text-2xl font-bold">{stats.totalSent.toLocaleString()}</div>
                      <p className="text-xs text-muted-foreground">Notifications sent</p>
                    </CardContent>
                  </Card>
                </div>
                <div className="h-[300px] flex items-center justify-center border rounded-lg bg-muted/50">
                  <div className="text-center">
                    <BarChart3 className="h-12 w-12 mx-auto mb-4 text-muted-foreground" />
                    <p className="text-muted-foreground">Analytics dashboard coming soon</p>
                  </div>
                </div>
              </div>
            </CardContent>
          </Card>
        </TabsContent>

        <TabsContent value="channels" className="space-y-4">
          <Card>
            <CardHeader>
              <CardTitle>Channel Configuration</CardTitle>
              <CardDescription>Configure notification channels and providers</CardDescription>
            </CardHeader>
            <CardContent>
              <div className="space-y-4">
                <div className="flex items-center justify-between p-4 border rounded-lg">
                  <div className="flex items-center space-x-4">
                    <Bell className="h-8 w-8 text-blue-500" />
                    <div>
                      <h4 className="font-semibold">Push Notifications</h4>
                      <p className="text-sm text-muted-foreground">Firebase Cloud Messaging</p>
                    </div>
                  </div>
                  <div className="flex items-center space-x-2">
                    <Badge variant="default" className="bg-green-500">Active</Badge>
                    <Button variant="outline" size="sm">Configure</Button>
                  </div>
                </div>
                <div className="flex items-center justify-between p-4 border rounded-lg">
                  <div className="flex items-center space-x-4">
                    <Mail className="h-8 w-8 text-green-500" />
                    <div>
                      <h4 className="font-semibold">Email</h4>
                      <p className="text-sm text-muted-foreground">SendGrid / SMTP</p>
                    </div>
                  </div>
                  <div className="flex items-center space-x-2">
                    <Badge variant="default" className="bg-green-500">Active</Badge>
                    <Button variant="outline" size="sm">Configure</Button>
                  </div>
                </div>
                <div className="flex items-center justify-between p-4 border rounded-lg">
                  <div className="flex items-center space-x-4">
                    <Smartphone className="h-8 w-8 text-purple-500" />
                    <div>
                      <h4 className="font-semibold">SMS</h4>
                      <p className="text-sm text-muted-foreground">Twilio / Africa&apos;s Talking</p>
                    </div>
                  </div>
                  <div className="flex items-center space-x-2">
                    <Badge variant="secondary">Setup Required</Badge>
                    <Button variant="outline" size="sm">Configure</Button>
                  </div>
                </div>
                <div className="flex items-center justify-between p-4 border rounded-lg">
                  <div className="flex items-center space-x-4">
                    <MessageCircle className="h-8 w-8 text-orange-500" />
                    <div>
                      <h4 className="font-semibold">In-App</h4>
                      <p className="text-sm text-muted-foreground">Native notifications</p>
                    </div>
                  </div>
                  <div className="flex items-center space-x-2">
                    <Badge variant="default" className="bg-green-500">Active</Badge>
                    <Button variant="outline" size="sm">Configure</Button>
                  </div>
                </div>
              </div>
            </CardContent>
          </Card>
        </TabsContent>
      </Tabs>
    </div>
  )
}
