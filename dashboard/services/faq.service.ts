import { getBackendClient } from "@/lib/backend-client"
import type { FaqsResponse, FaqsStatusOptions } from "@/types/backend-types"
import type { ModelsFAQ } from "@/types/generated/backend-openapi"
import type { FaqsWithExpanded } from "@/types/expanded"
import type { BulkOperationResult, FaqCreateData, FaqServiceResponse, FaqStatus, FaqUpdateData } from "@/types/faq"

interface Page<T>{items:T[];page:number;per_page:number;total_items:number;total_pages:number}
type Wire = ModelsFAQ
const client=()=>getBackendClient()
const normalize=(v:Wire):FaqsWithExpanded=>({...v,created:v.created_at||"",updated:v.updated_at||"",author:v.author_id||"",reviewer:v.reviewer_id||"",expand:{...(v.author_id?{author:{id:v.author_id,name:v.author_name||"",email:v.author_email||""}}:{}),...(v.reviewer_id?{reviewer:{id:v.reviewer_id,name:v.reviewer_name||"",email:v.reviewer_email||""}}:{})}} as FaqsWithExpanded)
const payload=(v:Partial<FaqCreateData>)=>({question:v.question,answer:v.answer,status:v.status,priority:v.priority,sort_order:v.sort_order,is_featured:v.is_featured,target_audience:v.target_audience,keywords:v.keywords,published_at:v.published_at,review_due:v.review_due,tags:v.tags||[],related_faqs:v.related_faqs||[],author_id:v.author,reviewer_id:v.reviewer})

export class FaqService {
  static async list(query:Record<string,unknown>={}){const r=await client().send<Page<Wire>>("/api/v2/faqs",{query:{page:1,per_page:100,...query}});return r}
  static async loadPage(query:{page:number;perPage:number;search:string}){const r=await this.list({page:query.page,per_page:query.perPage,search:query.search||undefined});return{items:r.items.map(normalize),page:r.page,perPage:r.per_page,totalItems:r.total_items,totalPages:r.total_pages}}
  static async getFaqWithRelations(id:string):Promise<FaqServiceResponse<FaqsWithExpanded>>{try{return{success:true,data:normalize(await client().send<Wire>(`/api/v2/faqs/${id}`))}}catch{return{success:false,error:"Failed to fetch FAQ"}}}
  static async createFaq(data:FaqCreateData):Promise<FaqServiceResponse<FaqsResponse>>{try{const record=await client().send<Wire>("/api/v2/faqs",{method:"POST",body:JSON.stringify(payload({status:"draft" as FaqsStatusOptions,priority:"normal",target_audience:"all",is_featured:false,sort_order:0,...data}))});return{success:true,data:normalize(record),message:"FAQ created successfully"}}catch{return{success:false,error:"Failed to create FAQ"}}}
  static async updateFaq(id:string,data:FaqUpdateData):Promise<FaqServiceResponse<FaqsResponse>>{try{const current=await this.getFaqWithRelations(id);if(!current.data)return{success:false,error:"FAQ not found"};const record=await client().send<Wire>(`/api/v2/faqs/${id}`,{method:"PATCH",body:JSON.stringify(payload({...current.data,...data}))});return{success:true,data:normalize(record),message:"FAQ updated successfully"}}catch{return{success:false,error:"Failed to update FAQ"}}}
  static async deleteFaq(id:string):Promise<FaqServiceResponse<void>>{try{await client().send<void>(`/api/v2/faqs/${id}`,{method:"DELETE"});return{success:true,message:"FAQ deleted successfully"}}catch{return{success:false,error:"Failed to delete FAQ"}}}
  static async duplicateFaq(id:string):Promise<FaqServiceResponse<FaqsResponse>>{const original=await this.getFaqWithRelations(id);if(!original.data)return{success:false,error:"Original FAQ not found"};return this.createFaq({...original.data,question:`${original.data.question} (Copy)`,status:"draft" as FaqsStatusOptions,is_featured:false,sort_order:0})}
  static async bulkUpdateStatus(ids:string[],status:FaqStatus):Promise<FaqServiceResponse<BulkOperationResult>>{return this.bulk(ids,id=>this.updateFaq(id,{status}))}
  static async bulkAssignTags(ids:string[],tagIds:string[],action:"add"|"remove"):Promise<FaqServiceResponse<BulkOperationResult>>{return this.bulk(ids,async id=>{const current=await this.getFaqWithRelations(id);if(!current.data)throw new Error("FAQ not found");const tags=action==="add"?[...new Set([...(current.data.tags||[]),...tagIds])]:(current.data.tags||[]).filter(v=>!tagIds.includes(v));return this.updateFaq(id,{tags})})}
  static async getRelatedFaqSuggestions(currentId:string,tags:string[],keywords?:string):Promise<FaqServiceResponse<FaqsResponse[]>>{try{const r=await this.list({tag_id:tags[0],search:keywords,per_page:10,status:"published"});return{success:true,data:r.items.filter(v=>v.id!==currentId).slice(0,5).map(normalize)}}catch{return{success:false,error:"Failed to get suggestions",data:[]}}}
  private static async bulk(ids:string[],operation:(id:string)=>Promise<unknown>):Promise<FaqServiceResponse<BulkOperationResult>>{const settled=await Promise.allSettled(ids.map(operation));const errors=settled.flatMap((r,i)=>r.status==="rejected"?[{id:ids[i],error:String(r.reason)}]:[]);return{success:true,data:{success_count:ids.length-errors.length,error_count:errors.length,errors:errors.length?errors:undefined}}}
}
