import { backendClient } from "@/lib/backend-client"

export async function getCalculatorContent(id: string): Promise<string> {
  return backendClient.send<string>(`/api/v2/calculators/${id}/content`, {
    responseType: "text",
  })
}
