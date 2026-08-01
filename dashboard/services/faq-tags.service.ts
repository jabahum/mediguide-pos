import { getBackendClient } from "@/lib/backend-client"
import { FaqService } from "@/services/faq.service"
import type { FaqTagsResponse } from "@/types/backend-types"
import type { ModelsFAQTag } from "@/types/generated/backend-openapi"
import type { BulkOperationResult, FaqServiceResponse, FaqTagCreateData, FaqTagUpdateData, FaqTagWithStats } from "@/types/faq"

interface Page<T>{items:T[];page:number;per_page:number;total_items:number;total_pages:number}
type Wire = ModelsFAQTag
const client=()=>getBackendClient()
const normalize=(v:Wire):FaqTagsResponse=>({...v,created:v.created_at||"",updated:v.updated_at||""} as unknown as FaqTagsResponse)

export class FaqTagsService {
  private static async list(query:Record<string,unknown>={}){return client().send<Page<Wire>>("/api/v2/faq-tags",{query:{page:1,per_page:100,sort:"name",order:"asc",...query}})}
  static async loadPage(query:{page:number;perPage:number;search:string}){const r=await this.list({page:query.page,per_page:query.perPage,search:query.search||undefined});return{items:r.items.map(normalize),page:r.page,perPage:r.per_page,totalItems:r.total_items,totalPages:r.total_pages}}
  static async createTag(data:FaqTagCreateData):Promise<FaqServiceResponse<FaqTagsResponse>>{try{const record=await client().send<Wire>("/api/v2/faq-tags",{method:"POST",body:JSON.stringify({is_active:true,sort_order:0,color:"primary",...data,slug:data.slug||this.generateSlug(data.name)})});return{success:true,data:normalize(record),message:"Tag created successfully"}}catch{return{success:false,error:"Failed to create tag"}}}
  static async getTag(id:string):Promise<FaqServiceResponse<FaqTagsResponse>>{try{return{success:true,data:normalize(await client().send<Wire>(`/api/v2/faq-tags/${id}`))}}catch{return{success:false,error:"Failed to fetch tag"}}}
  static async updateTag(id:string,data:FaqTagUpdateData):Promise<FaqServiceResponse<FaqTagsResponse>>{try{const current=await this.getTag(id);if(!current.data)return{success:false,error:"Tag not found"};const record=await client().send<Wire>(`/api/v2/faq-tags/${id}`,{method:"PATCH",body:JSON.stringify({name:current.data.name,description:current.data.description,color:current.data.color,icon:current.data.icon,is_active:current.data.is_active,sort_order:current.data.sort_order,...data,slug:data.slug||(data.name?this.generateSlug(data.name):current.data.slug)})});return{success:true,data:normalize(record),message:"Tag updated successfully"}}catch{return{success:false,error:"Failed to update tag"}}}
  static async deleteTag(id:string,force=false):Promise<FaqServiceResponse<void>>{try{if(force)await this.removeTagFromAllFaqs(id);await client().send<void>(`/api/v2/faq-tags/${id}`,{method:"DELETE"});return{success:true,message:"Tag deleted successfully"}}catch{return{success:false,error:"Cannot delete a tag that is still used by FAQs"}}}
  static async getTagWithStats(id:string):Promise<FaqServiceResponse<FaqTagWithStats>>{const r=await this.getTag(id);return r.data?{success:true,data:{...r.data,faq_count:r.data.usage_count}}:r}
  static async getTagsByIds(ids:string[]):Promise<FaqServiceResponse<FaqTagsResponse[]>>{try{const r=await this.list({per_page:100});return{success:true,data:r.items.filter(v=>v.id&&ids.includes(v.id)).map(normalize)}}catch{return{success:false,error:"Failed to get tags",data:[]}}}
  static async getTagSuggestions(query:string,limit=10):Promise<FaqServiceResponse<FaqTagsResponse[]>>{try{const r=await this.list({search:query,is_active:true,per_page:limit,sort:"usage_count",order:"desc"});return{success:true,data:r.items.map(normalize)}}catch{return{success:false,error:"Failed to get suggestions",data:[]}}}
  static async getPopularTags(limit=20):Promise<FaqServiceResponse<FaqTagsResponse[]>>{const r=await this.list({is_active:true,per_page:limit,sort:"usage_count",order:"desc"});return{success:true,data:r.items.filter(v=>(v.usage_count||0)>0).map(normalize)}}
  static async bulkUpdateStatus(ids:string[],active:boolean):Promise<FaqServiceResponse<BulkOperationResult>>{return this.bulk(ids,id=>this.updateTag(id,{is_active:active}))}
  static async mergeTags(sourceIds:string[],targetId:string):Promise<FaqServiceResponse<BulkOperationResult>>{for(const source of sourceIds){const faqs=await FaqService.list({tag_id:source,per_page:100});for(const faq of faqs.items){if(faq.id)await FaqService.updateFaq(faq.id,{tags:[...new Set((faq.tags||[]).filter(v=>v!==source).concat(targetId))]})}await this.deleteTag(source)}await this.recalculateUsageCounts();return{success:true,data:{success_count:sourceIds.length,error_count:0}}}
  static async recalculateUsageCounts():Promise<FaqServiceResponse<{updated:number}>>{try{await client().send("/api/v2/faq-tags/recalculate-usage",{method:"POST"});return{success:true,data:{updated:1},message:"Usage counts recalculated"}}catch{return{success:false,error:"Failed to recalculate usage counts"}}}
  private static async removeTagFromAllFaqs(id:string){const r=await FaqService.list({tag_id:id,per_page:100});await Promise.all(r.items.filter(f=>f.id).map(f=>FaqService.updateFaq(f.id!,{tags:(f.tags||[]).filter(v=>v!==id)})))}
  private static async bulk(ids:string[],op:(id:string)=>Promise<unknown>):Promise<FaqServiceResponse<BulkOperationResult>>{const r=await Promise.allSettled(ids.map(op));const errors=r.flatMap((v,i)=>v.status==="rejected"?[{id:ids[i],error:String(v.reason)}]:[]);return{success:true,data:{success_count:ids.length-errors.length,error_count:errors.length,errors:errors.length?errors:undefined}}}
  private static generateSlug(name:string){return name.toLowerCase().replace(/[^\w\s-]/g,"").replace(/\s+/g,"-").replace(/-+/g,"-").trim()}
}
