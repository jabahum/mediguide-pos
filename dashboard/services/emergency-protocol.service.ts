import { backendClient } from "@/lib/backend-client"
import type { EmergencyProtocolsResponse } from "@/types/backend-types"
import type { EmergencyProtocolPayload } from "@/app/(dashboard)/emergency-protocols/components/emergency-protocol-form"
import type { ModelsEmergencyProtocol, ServicesEmergencyProtocolInput } from "@/types/generated/backend-openapi"

type WireProtocol=ModelsEmergencyProtocol
interface Page<T>{items:T[];page:number;per_page:number;total_items:number;total_pages:number}
const normalize=(value:WireProtocol):EmergencyProtocolsResponse=>({...value,id:value.id||"",title:value.title||"",category:value.category||"Emergency Medicine",priority:value.priority||"medium",status:value.status||"draft",created:value.created_at||"",updated:value.updated_at||"",collectionId:"emergency_protocols",collectionName:"emergency_protocols"} as EmergencyProtocolsResponse)
export const emergencyProtocolService={
  async list(query:Record<string,unknown>={}){const result=await backendClient.send<Page<WireProtocol>>("/api/v2/emergency-protocols",{query:{page:1,per_page:50,...query}});return{...result,items:result.items.map(normalize)}},
  async get(id:string){return normalize(await backendClient.send<WireProtocol>(`/api/v2/emergency-protocols/${id}`))},
  async create(data:EmergencyProtocolPayload){return normalize(await backendClient.send<WireProtocol>("/api/v2/emergency-protocols",{method:"POST",body:JSON.stringify(data as ServicesEmergencyProtocolInput)}))},
  async update(id:string,data:EmergencyProtocolPayload|Partial<EmergencyProtocolPayload>){return normalize(await backendClient.send<WireProtocol>(`/api/v2/emergency-protocols/${id}`,{method:"PATCH",body:JSON.stringify(data as ServicesEmergencyProtocolInput)}))},
  async delete(id:string){await backendClient.send<void>(`/api/v2/emergency-protocols/${id}`,{method:"DELETE"})},
}
