import { getBackendClient } from "@/lib/backend-client"
import type { DocumentationResponse } from "@/types/backend-types"
import type { ModelsDocumentation } from "@/types/generated/backend-openapi"
import { DocumentationStatusOptions } from "@/types/backend-types"

export interface CreateDocumentationData { title: string; description?: string; content: string; category?: string; tags?: string; status?: DocumentationStatusOptions }
export type UpdateDocumentationData = Partial<CreateDocumentationData>
interface Page<T>{items:T[];page:number;per_page:number;total_items:number;total_pages:number}
type Wire = ModelsDocumentation
const client=()=>getBackendClient()
const normalize=(v:Wire):DocumentationResponse=>({...v,created:v.created_at||"",updated:v.updated_at||""} as unknown as DocumentationResponse)

export class DocumentationService {
  private static async list(query:Record<string,unknown>={}) { const result=await client().send<Page<Wire>>("/api/v2/documentation",{query:{page:1,per_page:100,sort:"created_at",order:"desc",...query}});return result.items.map(normalize) }
  static async loadPage(query:{page:number;perPage:number;search:string}){const result=await client().send<Page<Wire>>("/api/v2/documentation",{query:{page:query.page,per_page:query.perPage,search:query.search||undefined,sort:"updated_at",order:"desc"}});return{items:result.items.map(normalize),page:result.page,perPage:result.per_page,totalItems:result.total_items,totalPages:result.total_pages}}
  static getAll(options?:{sort?:string;filter?:string;expand?:string;page?:number;perPage?:number}) { return this.list({page:options?.page,per_page:options?.perPage}) }
  static async getById(id:string):Promise<DocumentationResponse|null>{try{return normalize(await client().send<Wire>(`/api/v2/documentation/${id}`))}catch{return null}}
  static async create(data:CreateDocumentationData){return normalize(await client().send<Wire>("/api/v2/documentation",{method:"POST",body:JSON.stringify({...data,status:data.status||DocumentationStatusOptions.draft})}))}
  static async update(id:string,data:UpdateDocumentationData){const current=await this.getById(id);if(!current)throw new Error("Documentation not found");return normalize(await client().send<Wire>(`/api/v2/documentation/${id}`,{method:"PATCH",body:JSON.stringify({title:current.title,description:current.description,content:current.content,category:current.category,tags:current.tags,status:current.status,...data})}))}
  static async delete(id:string){await client().send<void>(`/api/v2/documentation/${id}`,{method:"DELETE"});return true}
  static search(search:string,options?:{category?:string;status?:string;limit?:number}){return this.list({search,category:options?.category,status:options?.status,per_page:options?.limit})}
  static getByCategory(category:string){return this.list({category})}
  static getByStatus(status:DocumentationStatusOptions){return this.list({status})}
  static async getCategories(){return [...new Set((await this.list()).map(v=>v.category).filter(Boolean))].sort() as string[]}
  static async getTags(){return [...new Set((await this.list()).flatMap(v=>(v.tags||"").split(",").map(x=>x.trim())).filter(Boolean))].sort()}
  static async bulkUpdateStatus(ids:string[],status:DocumentationStatusOptions){await Promise.all(ids.map(id=>this.update(id,{status})))}
  static async bulkDelete(ids:string[]){await Promise.all(ids.map(id=>this.delete(id)))}
}
